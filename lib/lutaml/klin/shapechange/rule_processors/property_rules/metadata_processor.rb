# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds metadata attribute to property types
          # Implements rule-xsd-prop-metadata
          # Based on addMetadata() in XsdDocument.java lines 4254-4259
          #
          # When a property has propertyMetadata flag set,
          # adds a metadata attribute of type anyURI to allow
          # linking to external metadata resources
          class MetadataProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-metadata"

            protected

            def apply_rule(property, context)
              return unless property_has_metadata?(property)

              # Find appropriate parent element for metadata attribute
              parent_element = determine_parent_element(context)
              return unless parent_element

              add_metadata_attribute(parent_element, context)
            end

            private

            def property_has_metadata?(property)
              # Check propertyMetadata flag
              if property.respond_to?(:property_metadata?)
                begin
                  return property.property_metadata?
                rescue StandardError, NoMethodError
                  # Fall through to alternative check
                end
              end

              # Try without question mark
              if property.respond_to?(:property_metadata)
                begin
                  return property.property_metadata
                rescue StandardError, NoMethodError
                  return false
                end
              end

              false
            end

            def determine_parent_element(context)
              # Metadata attribute can be added to:
              # 1. Extension element (most common)
              # 2. ComplexType element
              # 3. Anonymous type element
              context[:extension_element] ||
                context[:complex_type_element] ||
                context[:anonymous_type_element] ||
                context[:property_type_element]
            end

            def add_metadata_attribute(parent, context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              # Create xs:attribute element
              metadata_attr = xsd_doc.create_element("attribute")
              xsd_doc.add_attribute(metadata_attr, "name", "metadata")
              xsd_doc.add_attribute(metadata_attr, "type", "anyURI")

              # Append to parent
              parent.add_child(metadata_attr) if parent.respond_to?(:add_child)
            end
          end
        end
      end
    end
  end
end
