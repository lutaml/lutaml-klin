# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Processor for rule-xsd-prop-gmlListProperty
          #
          # Creates XML Schema list-based simple types for properties
          # with gmlListProperty tagged value.
          class GmlListPropertyProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-prop-gmlListProperty"

            def self.rule_name
              RULE_NAME
            end

            # Process GML list property
            #
            # @param property [Object] The property to process
            # @param context [Hash] Processing context with :item_type
            # @return [Hash] Processing result with list configuration
            def process(property, context = {})
              return default_result unless applies_to?(property)

              min_occurs = extract_min_occurs(property)
              max_occurs = extract_max_occurs(property)

              {
                applies: true,
                result: {
                  is_list: true,
                  item_type: context[:item_type],
                  needs_restriction: needs_length_restriction?(min_occurs,
                                                               max_occurs),
                  min_length: min_occurs,
                  max_length: max_occurs == "unbounded" ? nil : max_occurs,
                  use_length: min_occurs == max_occurs && max_occurs != "unbounded",
                  multiplicity_set: true
                },
                message: "List property for #{property.name}"
              }
            end

            private

            # Check if rule applies
            #
            # @param property [Object] The property
            # @return [Boolean] True if property should be list
            def applies_to?(property)
              tag_value = property.tagged_values&.fetch("gmlListProperty", nil)
              tag_value&.downcase == "true"
            end

            # Check if length restrictions are needed
            #
            # @param min_occurs [Integer] Minimum occurrences
            # @param max_occurs [String, Integer] Maximum occurrences
            # @return [Boolean] True if restrictions needed
            def needs_length_restriction?(min_occurs, max_occurs)
              return false if min_occurs.zero? && max_occurs == "unbounded"

              true
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
              return "unbounded" if [-1, "*"].include?(upper)

              upper || 1
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: nil,
                message: "Not a GML list property"
              }
            end
          end
        end
      end
    end
  end
end
