# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds qualifier attributes to association properties
          # Implements rule-xsd-prop-qualified-associations
          # Based on processQualifier() in XsdDocument.java lines 2458-2544
          #
          # Qualifiers provide additional metadata for associations
          # and are encoded as XML attributes on the property type
          class QualifiedAssociationsProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-qualified-associations"

            protected

            def apply_rule(property, context)
              # Only process navigable non-attribute properties
              return unless should_process_qualifiers?(property)

              # Get qualifiers from reverse property
              qualifiers = get_qualifiers(property)
              return if qualifiers.nil? || qualifiers.empty?

              # Process each qualifier
              property_type_element = context[:property_type_element]
              return unless property_type_element

              qualifiers.each do |qualifier|
                add_qualifier_attribute(
                  qualifier,
                  property,
                  property_type_element,
                  context
                )
              end
            end

            private

            def should_process_qualifiers?(property)
              # Must be navigable and not an attribute
              return false unless property.respond_to?(:is_attribute?)
              return false if safe_call(property, :is_attribute?)
              return false unless property.respond_to?(:is_navigable?)

              safe_call(property, :is_navigable?)
            end

            def get_qualifiers(property)
              # Get reverse property for bidirectional associations
              reverse_property = get_reverse_property(property)
              return nil unless reverse_property

              # Get qualifiers from reverse property
              if reverse_property.respond_to?(:qualifiers)
                qualifiers = safe_call(reverse_property, :qualifiers)
                return qualifiers if qualifiers && !qualifiers.empty?
              end

              nil
            end

            def get_reverse_property(property)
              return nil unless property.respond_to?(:reverse_property)

              begin
                reverse_prop = property.reverse_property
                return nil unless reverse_prop
                return nil unless reverse_prop.respond_to?(:is_navigable?)

                # Only return if reverse property is navigable
                reverse_prop if safe_call(reverse_prop, :is_navigable?)
              rescue StandardError, NoMethodError
                nil
              end
            end

            def add_qualifier_attribute(qualifier, property, element, context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              # Create attribute element
              attr_element = xsd_doc.create_element("attribute")
              return unless attr_element

              # Set attribute name
              qualifier_name = get_qualifier_name(qualifier)
              xsd_doc.add_attribute(attr_element, "name", qualifier_name)

              # Determine and set attribute type
              qualifier_type = determine_qualifier_type(
                qualifier,
                property,
                context
              )
              xsd_doc.add_attribute(attr_element, "type", qualifier_type)

              # Append to property type element
              element.appendChild(attr_element) if element.respond_to?(:appendChild)
            end

            def get_qualifier_name(qualifier)
              if qualifier.respond_to?(:name)
                qualifier.name
              elsif qualifier.respond_to?(:[])
                qualifier[:name] || qualifier["name"] || "qualifier"
              else
                "qualifier"
              end
            end

            def determine_qualifier_type(qualifier, property, context)
              # Get qualifier type
              type_name = get_qualifier_type_name(qualifier)
              return "string" unless type_name

              # Try to map the type
              mapped_type = try_map_type(type_name, property, context)
              return mapped_type if mapped_type

              # Try to find the type in the model
              model_type = try_model_type(type_name, context)
              return model_type if model_type

              # Default to string
              "string"
            end

            def get_qualifier_type_name(qualifier)
              if qualifier.respond_to?(:type)
                return qualifier.type
              elsif qualifier.respond_to?(:[])
                return qualifier[:type] || qualifier["type"]
              end

              nil
            end

            def try_map_type(type_name, property, context)
              config = context[:config]
              return nil unless config

              # Get encoding rule
              encoding_rule = get_encoding_rule(property)

              # Try to get map entry
              map_entry = config.type_map_entry(type_name, encoding_rule)
              return nil unless map_entry

              # Check if it's a simple type
              if map_entry[:xml_type_content] == "simple/simple"
                return map_entry[:target_type]
              end

              nil
            rescue StandardError, NoMethodError
              nil
            end

            def try_model_type(type_name, context)
              model = context[:model]
              return nil unless model

              # Try to find class by name
              type_class = find_class_by_name(model, type_name)
              return nil unless type_class

              # Determine type based on category
              determine_type_by_category(type_class)
            rescue StandardError, NoMethodError
              nil
            end

            def find_class_by_name(model, name)
              if model.respond_to?(:class_by_name)
                model.class_by_name(name)
              elsif model.respond_to?(:classByName)
                model.classByName(name)
              end
            rescue StandardError, NoMethodError
              nil
            end

            def determine_type_by_category(type_class)
              return nil unless type_class.respond_to?(:category)

              category = safe_call(type_class, :category)
              return nil unless category

              case category.to_s.upcase
              when "ENUMERATION"
                # Use enumeration type name + "Type"
                qname = get_qname(type_class)
                qname ? "#{qname}Type" : "string"
              when "CODELIST", "FEATURE", "OBJECT", "GMLOBJECT", "MIXIN"
                # Complex types: use anyURI for reference
                "anyURI"
              when "DATATYPE", "UNION"
                # Not supported for qualifiers, use string
                "string"
              else
                "string"
              end
            end

            def get_qname(type_class)
              if type_class.respond_to?(:qname)
                type_class.qname
              elsif type_class.respond_to?(:name)
                type_class.name
              end
            rescue StandardError, NoMethodError
              nil
            end

            def get_encoding_rule(property)
              if property.respond_to?(:encoding_rule)
                safe_call(property, :encoding_rule, "xsd") || "xsd"
              else
                "xsd"
              end
            end

            def safe_call(object, method, *args)
              return nil unless object.respond_to?(method)

              object.send(method, *args)
            rescue StandardError, NoMethodError
              nil
            end
          end
        end
      end
    end
  end
end