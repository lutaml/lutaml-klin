# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Processor for rule-xsd-cls-byValuePropertyType
          #
          # Generates PropertyByValueType for classes with identity
          # that support inline-only encoding.
          class ByValuePropertyTypeProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-cls-byValuePropertyType"

            # Categories that have identity
            IDENTITY_CATEGORIES = %w[
              feature
              object
              mixin
            ].freeze

            def self.rule_name
              RULE_NAME
            end

            # Process by-value property type generation
            #
            # @param uml_class [Lutaml::Uml::Class] The class to process
            # @param context [Hash] Processing context
            # @return [Hash] Processing result with property type info
            def process(uml_class, _context = {})
              return default_result unless applies_to?(uml_class)

              {
                applies: true,
                result: {
                  type_name: "#{uml_class.name}PropertyByValueType",
                  element_ref: qualified_name(uml_class),
                  has_identity: true,
                  inline_only: true
                },
                message: "ByValue property type for #{uml_class.name}"
              }
            end

            private

            # Check if rule applies to the class
            #
            # @param uml_class [Lutaml::Uml::Class] The class
            # @return [Boolean] True if class has identity and includes by-value type
            def applies_to?(uml_class)
              return false unless has_identity?(uml_class)
              return false unless include_by_value_property_type?(uml_class)

              true
            end

            # Check if class has identity
            #
            # @param uml_class [Lutaml::Uml::Class] The class
            # @return [Boolean] True if class category has identity
            def has_identity?(uml_class)
              category = uml_class.category&.downcase
              IDENTITY_CATEGORIES.include?(category)
            end

            # Check if class includes by-value property type
            #
            # @param uml_class [Lutaml::Uml::Class] The class
            # @return [Boolean] True if flag is set
            def include_by_value_property_type?(uml_class)
              # Check for tagged value or flag
              tag_value = uml_class.tagged_values&.fetch(
                "includeByValuePropertyType", nil
              )
              return false if tag_value&.downcase == "false"
              return true if tag_value&.downcase == "true"

              # Default: generate for classes with identity
              true
            end

            # Get qualified name for element reference
            #
            # @param uml_class [Lutaml::Uml::Class] The class
            # @return [String] Qualified name
            def qualified_name(uml_class)
              # TODO: Get xmlns from ShapeChange config's PackageInfo instead of uml_class.package
              # if uml_class.package&.xmlns
              #   "#{uml_class.package.xmlns}:#{uml_class.name}"
              # else
              uml_class.name
              # end
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: nil,
                message: "Class does not have identity or by-value property type not included"
              }
            end
          end
        end
      end
    end
  end
end
