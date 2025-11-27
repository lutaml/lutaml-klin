# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds name attribute for soft-typed properties
          # Implements rule-xsd-prop-soft-typed
          # Based on addAnonymousPropertyType() and addName()
          # in XsdDocument.java lines 4225-4231 and 3957-3961
          #
          # For dynamically typed properties (SWE Common),
          # adds a required name attribute of type NCName
          class SoftTypedProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-soft-typed"

            protected

            def apply_rule(property, context)
              return unless soft_typed?(property)

              # Find appropriate parent element for name attribute
              parent_element = determine_parent_element(context)
              return unless parent_element

              add_name_attribute(parent_element, context)
            end

            private

            def soft_typed?(property)
              # Check for soft-typed tagged value
              return false unless property.respond_to?(:tags)

              tags = begin
                property.tags
              rescue StandardError
                nil
              end
              return false unless tags

              tag = tags.find { |t| t.name == "soft-typed" }
              return false unless tag
              return false unless tag.respond_to?(:value)

              tag.value&.downcase == "true"
            end

            def determine_parent_element(context)
              # Name attribute is added to:
              # 1. Extension element (typeOrExtension in Java)
              # 2. ComplexType element
              # 3. Anonymous type element
              context[:extension_element] ||
                context[:type_or_extension_element] ||
                context[:complex_type_element] ||
                context[:anonymous_type_element] ||
                context[:property_type_element]
            end

            def add_name_attribute(parent, context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              # Create xs:attribute element with name, type, and use
              # Based on addName() in XsdDocument.java lines 3957-3961
              name_attr = xsd_doc.create_element("attribute")
              xsd_doc.add_attribute(name_attr, "name", "name")
              xsd_doc.add_attribute(name_attr, "type", "NCName")
              xsd_doc.add_attribute(name_attr, "use", "required")

              # Append to parent
              parent.add_child(name_attr) if parent.respond_to?(:add_child)
            end
          end
        end
      end
    end
  end
end
