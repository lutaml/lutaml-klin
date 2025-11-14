# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Processor for rule-xsd-all-notEncoded
          #
          # Excludes properties from XML Schema generation when their
          # encoding rule is set to "notencoded".
          #
          # Based on XsdDocument.java:includeProperty() line 1902
          class NotEncodedProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-all-notEncoded"

            def self.rule_name
              RULE_NAME
            end

            # Process property to determine if it should be included
            #
            # @param property [Object] The UML property
            # @param context [Hash] Processing context
            # @return [Hash] Processing result
            def process(property, context = {})
              encoding_rule = get_encoding_rule(property, "xsd")
              is_not_encoded = is_not_encoded?(encoding_rule)

              {
                applies: true,
                result: {
                  include_property: !is_not_encoded,
                  encoding_rule: encoding_rule,
                  is_not_encoded: is_not_encoded
                },
                message: generate_message(is_not_encoded, encoding_rule)
              }
            end

            private

            # Get encoding rule for property
            #
            # @param property [Object] The property
            # @param target [String] Target name (e.g., "xsd")
            # @return [String, nil] Encoding rule value
            def get_encoding_rule(property, target)
              return nil unless property.respond_to?(:encoding_rule)

              begin
                rule = property.encoding_rule(target)
                return rule if rule && !rule.to_s.empty?
              rescue StandardError
                # Fall through to try encodingRule
              end

              # Try alternative method name
              if property.respond_to?(:encodingRule)
                begin
                  return property.encodingRule(target)
                rescue StandardError
                  # Fall through
                end
              end

              # Try tagged value
              if property.respond_to?(:tagged_value)
                begin
                  return property.tagged_value("encodingRule")
                rescue StandardError
                  # Fall through
                end
              end

              nil
            end

            # Check if encoding rule indicates not encoded
            #
            # @param encoding_rule [String, nil] The encoding rule value
            # @return [Boolean] True if property should not be encoded
            def is_not_encoded?(encoding_rule)
              return false if encoding_rule.nil?
              return false if encoding_rule.to_s.strip.empty?

              # Case-insensitive comparison
              encoding_rule.to_s.strip.casecmp("notencoded")&.zero? || false
            end

            # Generate processing message
            #
            # @param is_not_encoded [Boolean] Whether property is not encoded
            # @param encoding_rule [String, nil] The encoding rule value
            # @return [String] Processing message
            def generate_message(is_not_encoded, encoding_rule)
              if is_not_encoded
                "Property excluded: encodingRule=#{encoding_rule}"
              elsif encoding_rule
                "Property included: encodingRule=#{encoding_rule}"
              else
                "Property included: no encoding rule specified"
              end
            end

            # Check if rule applies to the property
            #
            # This rule always applies (it's a filter rule)
            #
            # @param property [Object] The property
            # @return [Boolean] Always true
            def applies_to?(property)
              true
            end
          end
        end
      end
    end
  end
end