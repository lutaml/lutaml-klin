# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Processor for rule-xsd-prop-exclude-derived
          #
          # Excludes derived properties from XML Schema generation
          # when this rule is active.
          #
          # Based on XsdDocument.java:includeProperty() lines 1896-1903
          class ExcludeDerivedProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-prop-exclude-derived"

            def self.rule_name
              RULE_NAME
            end

            # Process property to determine if it should be excluded
            #
            # @param property [Object] The property to process
            # @param context [Hash] Processing context
            # @return [Hash] Processing result indicating exclusion
            def process(property, context = {})
              return default_result unless applies_to?(property)

              is_derived = check_if_derived(property)

              if is_derived
                {
                  applies: true,
                  result: {
                    exclude_property: true,
                    reason: "derived",
                    derived: true
                  },
                  message: "Excluding derived property #{property.name}"
                }
              else
                {
                  applies: true,
                  result: {
                    exclude_property: false,
                    reason: nil,
                    derived: false
                  },
                  message: "Property #{property.name} is not derived"
                }
              end
            end

            private

            # Check if property is derived
            #
            # @param property [Object] The property
            # @return [Boolean] True if property is derived
            def check_if_derived(property)
              # Try isDerived? first
              if property.respond_to?(:is_derived?)
                begin
                  result = property.is_derived?
                  return result if result.is_a?(TrueClass) || result.is_a?(FalseClass)
                rescue StandardError
                  # Fall through
                end
              end

              # Try isDerived (without ?)
              if property.respond_to?(:is_derived)
                begin
                  result = property.is_derived
                  return result if result.is_a?(TrueClass) || result.is_a?(FalseClass)
                rescue StandardError
                  # Fall through
                end
              end

              # Try derived?
              if property.respond_to?(:derived?)
                begin
                  result = property.derived?
                  return result if result.is_a?(TrueClass) || result.is_a?(FalseClass)
                rescue StandardError
                  # Fall through
                end
              end

              # Try derived (without ?)
              if property.respond_to?(:derived)
                begin
                  result = property.derived
                  return result if result.is_a?(TrueClass) || result.is_a?(FalseClass)
                rescue StandardError
                  # Fall through
                end
              end

              # Check tagged values
              derived_tv = get_tagged_value(property, "derived")
              return true if derived_tv&.to_s&.downcase == "true"

              # Check isDerived tagged value
              is_derived_tv = get_tagged_value(property, "isDerived")
              return true if is_derived_tv&.to_s&.downcase == "true"

              false
            rescue StandardError
              false
            end

            # Get tagged value from property
            #
            # @param property [Object] The property
            # @param tag_name [String] Tag name
            # @return [String, nil] Tag value
            def get_tagged_value(property, tag_name)
              return nil unless property.respond_to?(:tagged_values)

              tagged_values = property.tagged_values
              return nil unless tagged_values

              if tagged_values.respond_to?(:[])
                tagged_values[tag_name]
              elsif tagged_values.respond_to?(:find)
                tv = tagged_values.find { |t| t.respond_to?(:tag) && t.tag == tag_name }
                tv&.value if tv.respond_to?(:value)
              end
            rescue StandardError
              nil
            end

            # Check if rule applies to the property
            #
            # @param property [Object] The property
            # @return [Boolean] True if rule is active for property
            def applies_to?(property)
              # Rule always applies - it's a filter rule
              # The actual decision is whether the property is derived
              true
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: {
                  exclude_property: false,
                  reason: nil,
                  derived: false
                },
                message: "Rule not active"
              }
            end
          end
        end
      end
    end
  end
end