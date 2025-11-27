# frozen_string_literal: true

require_relative "base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Generates <xs:simpleType> for UML enumerations
        # Implements rule-xsd-cls-enum-object-element
        # Based on pGlobalEnumeration() in XsdDocument.java lines 1845-1855
        class EnumerationProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-cls-enum-object-element"

          protected

          def apply_rule(uml_class, context)
            # Only process Enum types
            return unless uml_class.is_a?(Lutaml::Uml::Enum)

            xsd_doc = context[:xsd_document]

            # Create simpleType with restriction base="string"
            simple_type = xsd_doc.add_simple_type(
              name: type_name(uml_class, xsd_doc)
            )

            # Add restriction element
            restriction = xsd_doc.add_restriction(
              simple_type,
              base: "string"
            )

            # Add enumeration values from class properties/values
            add_enumeration_values(uml_class, restriction, xsd_doc)

            # Record mapping if collector present
            record_enumeration_mapping(uml_class, context) if context[:mapping_collector]
          end

          private

          def type_name(uml_class, _xsd_doc)
            # Follow GML/ISO 19139 naming conventions
            "#{uml_class.name}Type"
          end

          def add_enumeration_values(uml_class, restriction, xsd_doc)
            # Get enumeration values from the class
            # In Lutaml::Uml::Enum, values are stored in the 'values' attribute
            values = if uml_class.respond_to?(:values) && uml_class.values
                       uml_class.values
                     elsif uml_class.respond_to?(:attributes) && uml_class.attributes
                       # Fallback: treat attributes as enum values
                       uml_class.attributes
                     else
                       []
                     end

            return if values.empty?

            values.each do |value|
              # Extract the value name
              value_name = extract_value_name(value)
              next unless value_name

              # Add enumeration element
              xsd_doc.add_enumeration(
                restriction,
                value: value_name
              )
            end
          end

          def extract_value_name(value)
            # Handle different value representations
            if value.respond_to?(:name)
              value.name
            elsif value.respond_to?(:value)
              value.value
            elsif value.is_a?(String)
              value
            else
              value.to_s
            end
          end

          # Record enumeration mapping to collector
          def record_enumeration_mapping(uml_enum, context)
            collector = context[:mapping_collector]
            return unless collector

            xsd_doc = context[:xsd_document]
            type_name = type_name(uml_enum, xsd_doc)

            collector.record_class_mapping(
              uml_class: uml_enum,
              xsd_type_name: type_name,
              rules_applied: [RULE_ID],
              context: {
                encoding_rule: context[:config]&.target_config&.dig(:default_encoding_rule),
                is_enumeration: true
              }
            )
          end
        end
      end
    end
  end
end
