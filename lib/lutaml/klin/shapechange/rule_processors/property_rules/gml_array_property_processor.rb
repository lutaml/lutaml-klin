# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Processor for rule-xsd-prop-gmlArrayProperty
          #
          # Creates GML array property types for properties with
          # gmlArrayProperty tagged value.
          class GmlArrayPropertyProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-prop-gmlArrayProperty"

            def self.rule_name
              RULE_NAME
            end

            # Process GML array property
            #
            # @param property [Object] The property to process
            # @param context [Hash] Processing context with :inline_or_by_reference
            # @return [Hash] Processing result with array configuration
            def process(property, context = {})
              return default_result unless applies_to?(property, context)

              {
                applies: true,
                result: {
                  is_array: true,
                  min_occurs: extract_min_occurs(property),
                  max_occurs: extract_max_occurs(property),
                  target_element: context[:target_element],
                  multiplicity_set: true
                },
                message: "Array property for #{property.name}"
              }
            end

            private

            # Check if rule applies
            #
            # @param property [Object] The property
            # @param context [Hash] Processing context
            # @return [Boolean] True if property should be array
            def applies_to?(property, context)
              return false unless has_array_tag?(property)
              return false unless inline_only?(property, context)

              true
            end

            # Check if property has gmlArrayProperty tag
            #
            # @param property [Object] The property
            # @return [Boolean] True if tag is set to true
            def has_array_tag?(property)
              tag_value = property.tagged_values&.fetch("gmlArrayProperty", nil)
              tag_value&.downcase == "true"
            end

            # Check if property is inline-only
            #
            # @param property [Object] The property
            # @param context [Hash] Processing context
            # @return [Boolean] True if inline-only
            def inline_only?(property, context)
              inline_or_by_ref = context[:inline_or_by_reference] ||
                                 property.tagged_values&.fetch("inlineOrByReference", nil)

              inline_or_by_ref&.downcase == "inline"
            end

            # Extract minimum occurrences
            #
            # @param property [Object] The property
            # @return [Integer] Minimum occurrences
            def extract_min_occurs(property)
              property.lower_value&.value || 0
            end

            # Extract maximum occurrences
            #
            # @param property [Object] The property
            # @return [String, Integer] Maximum occurrences
            def extract_max_occurs(property)
              upper = property.upper_value&.value
              upper == -1 || upper == "*" ? "unbounded" : upper || 1
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: nil,
                message: "Not a GML array property"
              }
            end
          end
        end
      end
    end
  end
end