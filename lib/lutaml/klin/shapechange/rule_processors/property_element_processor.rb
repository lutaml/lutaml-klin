# frozen_string_literal: true

require_relative "base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Adds property elements to class types
        # Implements property encoding within sequences
        # Based on ShapeChange's addProperty() logic (XsdDocument.java lines 2016-2430)
        class PropertyElementProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-prop-encode-properties"

          protected

          def apply_rule(uml_class, context)
            sequence = context[:sequence_or_choice]
            return unless sequence

            # Process each property/attribute
            attributes = uml_class.attributes || []
            attributes.each do |attribute|
              add_property_element(attribute, context)
            end
          end

          private

          def add_property_element(attribute, context)
            xsd_doc = context[:xsd_document]
            sequence = context[:sequence_or_choice]

            # Create property element
            prop_element = xsd_doc.create_element("element")
            prop_element["name"] = determine_property_name(attribute, context)

            # Determine type
            xsd_type = resolve_property_type(attribute, context)
            prop_element["type"] = xsd_type if xsd_type

            # Add multiplicity
            add_multiplicity(prop_element, attribute)

            sequence.add_child(prop_element)
          end

          def resolve_property_type(attribute, context)
            type_name = attribute.type
            return nil unless type_name

            # Check if it's a mapped type (like CharacterString -> xs:string)
            map_entry = config.find_type_mapping(type_name)
            if map_entry
              return map_entry.xml_type
            end

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
            current_package = context[:uml_class]&.package&.name || context[:package_name]

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
              classes = uml_repo.classes_in_package(pkg_name) rescue []
              return pkg_name if classes.any? { |c| c.name == type_name }
            end

            nil
          end

          def find_package_prefix(package_name, context)
            # Look up in config's package_infos
            pkg_info = config.package_infos.find { |pi| pi.package_name&.strip == package_name&.strip }
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
            if max == "*" || max == "-1"
              element["maxOccurs"] = "unbounded"
            elsif max.to_i > 1
              element["maxOccurs"] = max.to_s
            end
          end
        end
      end
    end
  end
end