# frozen_string_literal: true

require_relative "base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Generates code list encoding for UML code lists
        # Implements rule-xsd-cls-codelist-constraints
        # Based on pGlobalCodeList() in XsdDocument.java lines 1863-1894
        #
        # Creates a union between enumeration and "other" pattern:
        # <xs:simpleType name="StatusCodeType">
        #   <xs:union memberTypes="StatusCodeEnumerationType StatusCodeOtherType"/>
        # </xs:simpleType>
        class CodeListProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-cls-codelist-constraints"

          protected

          def apply_rule(uml_class, context)
            xsd_doc = context[:xsd_document]
            prefix = context[:prefix]

            # Create main union type
            create_union_type(uml_class, xsd_doc, prefix)

            # Create enumeration type
            create_enumeration_type(uml_class, xsd_doc)

            # Create "other" type with pattern
            create_other_type(uml_class, xsd_doc)
          end

          private

          def create_union_type(uml_class, xsd_doc, prefix)
            # Main type: union of enumeration and other
            simple_type = xsd_doc.add_simple_type(
              name: "#{uml_class.name}Type"
            )

            # Add union with memberTypes
            member_types = "#{prefix}:#{uml_class.name}EnumerationType #{prefix}:#{uml_class.name}OtherType"
            xsd_doc.add_union(simple_type, member_types: member_types)
          end

          def create_enumeration_type(uml_class, xsd_doc)
            # Create enumeration type for known values
            simple_type = xsd_doc.add_simple_type(
              name: "#{uml_class.name}EnumerationType"
            )

            # Add restriction with base="string"
            restriction = xsd_doc.add_restriction(
              simple_type,
              base: "string"
            )

            # Add enumeration values
            add_enumeration_values(uml_class, restriction, xsd_doc)
          end

          def create_other_type(uml_class, xsd_doc)
            # Create "other" type for extensibility
            simple_type = xsd_doc.add_simple_type(
              name: "#{uml_class.name}OtherType"
            )

            # Add restriction with base="string"
            restriction = xsd_doc.add_restriction(
              simple_type,
              base: "string"
            )

            # Add pattern: "other: \w{2,}"
            xsd_doc.add_pattern(restriction, value: "other: \\w{2,}")
          end

          def add_enumeration_values(uml_class, restriction, xsd_doc)
            # Get code list values
            values = if uml_class.respond_to?(:values) && uml_class.values
                       uml_class.values
                     elsif uml_class.respond_to?(:attributes) && uml_class.attributes
                       # Fallback: treat attributes as code list values
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
        end
      end
    end
  end
end
