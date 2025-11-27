# frozen_string_literal: true

require_relative "base_rule_processor"
require_relative "property_rules/inline_or_by_reference_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Adds property elements to class types
        # Implements property encoding within sequences
        # Based on ShapeChange's addProperty() logic (XsdDocument.java lines 2016-2430)
        class PropertyElementProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-prop-encode-properties"

          def initialize(rule_checker, config)
            super
            @inline_processor = PropertyRules::InlineOrByReferenceProcessor.new(
              rule_checker,
              config
            )
          end

          protected

          def apply_rule(uml_class, context)
            sequence = context[:sequence_or_choice]
            return unless sequence

            # Process each property/attribute
            attributes = uml_class.attributes || []

            if ENV["VERBOSE"] && attributes.any?
              puts "  PropertyElementProcessor: #{uml_class.name} has #{attributes.size} attributes"
            end

            attributes.each do |attribute|
              add_property_element(attribute, context)
            end
          end

          private

          def add_property_element(attribute, context)
            xsd_doc = context[:xsd_document]
            sequence = context[:sequence_or_choice]

            # Skip cross-package properties (properties whose type is in a different package)
            if is_cross_package_property?(attribute, context)
              if ENV["VERBOSE"]
                type_package = find_type_package(attribute.type, context)
                puts "    - SKIPPED cross-package attribute: #{attribute.name} (type from #{type_package})"
              end
              return
            end

            # Determine property name first
            prop_name = determine_property_name(attribute, context)

            if ENV["VERBOSE"]
              puts "    - Processing attribute: #{attribute.name} → #{prop_name}"
            end

            # Run InlineOrByReferenceProcessor to determine encoding strategy
            # This sets context[:embed_property_type] and context[:encoding_mode]
            @inline_processor.process(attribute, context)

            # Create property element
            prop_element = xsd_doc.create_element("element")
            prop_element["name"] = prop_name

            # Check if we should embed an anonymous property type
            if context[:embed_property_type]
              # Generate anonymous property type inline
              create_anonymous_property_type(
                prop_element,
                attribute,
                context
              )

              if ENV["VERBOSE"]
                mode = context[:encoding_mode] || "standard"
                puts "      Using anonymous type (#{mode})"
              end
            else
              # Use standard PropertyType reference
              xsd_type = resolve_property_type(attribute, context)

              # Skip if we couldn't resolve the type
              unless xsd_type
                if ENV["VERBOSE"]
                  puts "      SKIPPED: Could not resolve type for #{attribute.name}"
                end
                return
              end

              prop_element["type"] = xsd_type

              if ENV["VERBOSE"]
                puts "      Using type: #{xsd_type}"
              end
            end

            # Add multiplicity
            add_multiplicity(prop_element, attribute)

            # Add to sequence
            sequence.add_child(prop_element)
          end

          # Create anonymous property type inline within the property element
          # Based on addAnonymousPropertyType() in XsdDocument.java lines 3963-4252
          def create_anonymous_property_type(prop_element, attribute, context)
            xsd_doc = context[:xsd_document]
            encoding_mode = context[:encoding_mode] || "standard"

            if ENV["VERBOSE"]
              puts "      Creating anonymous type (mode: #{encoding_mode})"
            end

            # Create nested complexType
            complex_type = xsd_doc.create_element("complexType")
            prop_element.add_child(complex_type)

            # Decide structure based on encoding mode
            case encoding_mode
            when "byreference"
              # Pattern A: By-reference only (GML ReferenceType)
              create_byreference_type(complex_type, attribute, context, xsd_doc)
            when "inline"
              # Pattern B: Inline only (no xlink attributes)
              create_inline_type(complex_type, attribute, context, xsd_doc)
            else
              # Pattern C: Standard/both (sequence with AssociationAttributeGroup)
              create_standard_type(complex_type, attribute, context, xsd_doc)
            end
          end

          # Create by-reference anonymous type
          # Uses gml:ReferenceType base with possible extensions
          def create_byreference_type(complex_type, attribute, context, xsd_doc)
            # Check if we need extensions (nilReason, metadata, qualifiers)
            needs_extension = needs_nil_reason?(attribute) ||
                              has_metadata?(attribute, context) ||
                              has_qualifiers?(attribute)

            if needs_extension
              # Extend gml:ReferenceType with additional attributes
              complex_content = xsd_doc.create_element("complexContent")
              complex_type.add_child(complex_content)

              extension = xsd_doc.create_element("extension")
              extension["base"] = "gml:ReferenceType"
              complex_content.add_child(extension)

              # Add nilReason if needed
              if needs_nil_reason?(attribute)
                add_nil_reason_attribute(extension, context, xsd_doc)
              end

              # Add metadata if needed
              if has_metadata?(attribute, context)
                add_metadata_attribute(extension, xsd_doc)
              end

              # TODO: Add qualifiers support here if needed
            else
              # Simple by-reference: just use gml:ReferenceType directly
              # Actually, we need to set it on prop_element, not create anonymous
              # Let's use simpler approach - just reference the type
              complex_type.parent.add_previous_sibling_text("")
              complex_type.remove
              prop_element = complex_type.parent
              prop_element["type"] = "gml:ReferenceType"
            end
          end

          # Create inline anonymous type
          # No xlink attributes, just sequence with element ref
          def create_inline_type(complex_type, attribute, context, xsd_doc)
            # Create sequence with minOccurs="0"
            sequence = xsd_doc.create_element("sequence")
            sequence["minOccurs"] = "0"
            complex_type.add_child(sequence)

            # Add element reference to target type
            target_ref = resolve_target_element_ref(attribute, context)
            if target_ref
              element_ref = xsd_doc.create_element("element")
              element_ref["ref"] = target_ref
              sequence.add_child(element_ref)
            end

            # Add nilReason if needed (rare for inline)
            if needs_nil_reason?(attribute)
              add_nil_reason_attribute(complex_type, context, xsd_doc)
            end

            # Add metadata if needed
            if has_metadata?(attribute, context)
              add_metadata_attribute(complex_type, xsd_doc)
            end
          end

          # Create standard anonymous type
          # Sequence with element ref + AssociationAttributeGroup + OwnershipAttributeGroup
          def create_standard_type(complex_type, attribute, context, xsd_doc)
            # Create sequence with minOccurs="0"
            sequence = xsd_doc.create_element("sequence")
            sequence["minOccurs"] = "0"
            complex_type.add_child(sequence)

            # Add element reference
            target_ref = resolve_target_element_ref(attribute, context)
            if target_ref
              element_ref = xsd_doc.create_element("element")
              element_ref["ref"] = target_ref
              sequence.add_child(element_ref)
            end

            # Determine if we need association attributes (only if type has identity)
            value_class = get_value_class(attribute, context)
            if value_class && class_has_identity?(value_class)
              # Add AssociationAttributeGroup
              attr_group = xsd_doc.create_element("attributeGroup")
              attr_group["ref"] = "gml:AssociationAttributeGroup"
              complex_type.add_child(attr_group)

              # Add OwnershipAttributeGroup for GML 3.2
              gml_ns = context[:gml_namespace] || "http://www.opengis.net/gml/3.2"
              if gml_ns == "http://www.opengis.net/gml/3.2"
                ownership_group = xsd_doc.create_element("attributeGroup")
                ownership_group["ref"] = "gml:OwnershipAttributeGroup"
                complex_type.add_child(ownership_group)
              end
            end

            # Add nilReason if needed
            if needs_nil_reason?(attribute)
              add_nil_reason_attribute(complex_type, context, xsd_doc)
            end

            # Add metadata if needed
            if has_metadata?(attribute, context)
              add_metadata_attribute(complex_type, xsd_doc)
            end
          end

          def resolve_property_type(attribute, context)
            type_name = attribute.type
            return nil unless type_name

            # Check if it's a mapped type (like CharacterString -> xs:string)
            map_entry = config.find_type_mapping(type_name)
            return map_entry.xml_type if map_entry

            # It's a class reference - use PropertyType pattern
            # Find the package where this type is defined
            type_package_prefix = find_type_package_prefix(type_name, context)
            "#{type_package_prefix}:#{type_name}PropertyType"
          end

          def determine_property_name(attribute, context)
            type_name = attribute.type
            return attribute.name unless type_name

            # Find which package defines this type
            type_package = find_type_package(type_name, context)
            current_package = context[:package_name]

            # If type is from different package, prefix property name with source package abbreviation
            if type_package && current_package && type_package != current_package
              type_prefix = find_package_prefix(type_package, context)
              "#{type_prefix}#{attribute.name}"
            else
              attribute.name
            end
          end

          def find_type_package_prefix(type_name, context)
            type_package = find_type_package(type_name, context)
            return context[:prefix] unless type_package

            find_package_prefix(type_package, context) || context[:prefix]
          end

          def find_type_package(type_name, context)
            # Search UML repository for class definition
            uml_repo = context[:uml_repository]
            return nil unless uml_repo

            # Try to find all packages
            all_packages = if uml_repo.respond_to?(:all_packages)
                             uml_repo.all_packages
                           else
                             # Fallback: get from config
                             config.package_infos.map(&:package_name).compact
                           end

            # Search each package for the type
            all_packages.each do |pkg|
              pkg_name = pkg.respond_to?(:name) ? pkg.name : pkg.to_s
              classes = begin
                uml_repo.classes_in_package(pkg_name)
              rescue StandardError
                []
              end
              return pkg_name if classes.any? { |c| c.name == type_name }
            end

            nil
          end

          def find_package_prefix(package_name, _context)
            # Look up in config's package_infos
            pkg_info = config.package_infos.find do |pi|
              pi.package_name&.strip == package_name&.strip
            end
            pkg_info&.nsabr&.strip
          end

          def add_multiplicity(element, attribute)
            # Get multiplicity from attribute's cardinality
            cardinality = attribute.cardinality
            return unless cardinality

            min = cardinality.min&.to_i || 1
            max = cardinality.max || "1"

            # Set minOccurs (only if different from default 1)
            element["minOccurs"] = min.to_s unless min == 1

            # Set maxOccurs (only if different from default 1)
            if ["*", "-1"].include?(max)
              element["maxOccurs"] = "unbounded"
            elsif max.to_i > 1
              element["maxOccurs"] = max.to_s
            end
          end

          # Resolve target element reference for property
          def resolve_target_element_ref(attribute, context)
            type_name = attribute.type
            return nil unless type_name

            # Find the package where this type is defined
            type_package_prefix = find_type_package_prefix(type_name, context)
            "#{type_package_prefix}:#{type_name}"
          end

          # Get value class from attribute type
          def get_value_class(attribute, context)
            type_name = attribute.type
            return nil unless type_name

            # Try to find in UML repository
            uml_repo = context[:uml_repository]
            return nil unless uml_repo

            # Search for class by name
            if uml_repo.respond_to?(:find_class)
              begin
                return uml_repo.find_class(type_name)
              rescue StandardError
                nil
              end
            end

            nil
          end

          # Check if class has identity (Feature, Object, Mixin)
          def class_has_identity?(uml_class)
            return false unless uml_class.respond_to?(:stereotype)

            stereotypes = Array(uml_class.stereotype).map(&:to_s).map(&:downcase)

            stereotypes.include?("featuretype") ||
              stereotypes.include?("objecttype") ||
              stereotypes.include?("mixin")
          end

          # Check if property needs nilReason attribute
          def needs_nil_reason?(attribute)
            nil_reason = if attribute.respond_to?(:nil_reason_allowed?)
                           attribute.nil_reason_allowed?
                         else
                           false
                         end

            voidable = if attribute.respond_to?(:voidable?)
                         attribute.voidable?
                       else
                         false
                       end

            nil_reason || voidable
          end

          # Check if property has metadata
          def has_metadata?(attribute, _context)
            return false unless attribute.respond_to?(:property_metadata?)

            attribute.property_metadata?
          rescue StandardError
            false
          end

          # Check if property has qualifiers
          def has_qualifiers?(attribute)
            return false unless attribute.respond_to?(:qualifiers)

            qualifiers = attribute.qualifiers
            qualifiers && !qualifiers.empty?
          rescue StandardError
            false
          end

          # Add nilReason attribute to element
          def add_nil_reason_attribute(parent, context, xsd_doc)
            gml_ns = context[:gml_namespace] || "http://www.opengis.net/gml/3.2"
            nil_reason_type = if gml_ns == "http://www.opengis.net/gml/3.2"
                                "gml:NilReasonType"
                              else
                                "gml:NullType"
                              end

            attribute = xsd_doc.create_element("attribute")
            attribute["name"] = "nilReason"
            attribute["type"] = nil_reason_type
            parent.add_child(attribute)
          end

          # Add metadata attribute to element
          def add_metadata_attribute(parent, xsd_doc)
            attribute = xsd_doc.create_element("attribute")
            attribute["name"] = "metadata"
            attribute["type"] = "anyURI"
            parent.add_child(attribute)
          end

          # Check if a property references a type from a different package
          # Cross-package properties should be excluded from XSD generation
          def is_cross_package_property?(attribute, context)
            type_name = attribute.type
            return false unless type_name

            # Get the package where the type is defined
            type_package = find_type_package(type_name, context)
            current_package = context[:package_name]

            # Skip if type is from a different package
            type_package && current_package && type_package != current_package
          end
        end
      end
    end
  end
end
