# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Processor for rule-xsd-cls-noPropertyType
          #
          # Suppresses generation of PropertyType definitions unless
          # explicitly required via includePropertyType tagged value.
          #
          # Based on XsdDocument.java:pPropertyTypes() lines 1207-1208
          # and pPropertyTypeWithSubtypes() lines 1234-1237
          class NoPropertyTypeProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-cls-noPropertyType"

            def self.rule_name
              RULE_NAME
            end

            # Process class to determine if PropertyType should be generated
            #
            # @param uml_class [Lutaml::Uml::Class] The class
            # @param context [Hash] Processing context
            # @return [Hash] Processing result
            def process(uml_class, _context = {})
              return default_result(true) unless applies_to?(uml_class)

              # Rule is active, check includePropertyType
              should_generate = should_generate_property_type?(uml_class)

              {
                applies: true,
                result: {
                  generate_property_type: should_generate,
                  reason: determine_reason(should_generate)
                },
                message: generate_message(should_generate)
              }
            end

            private

            # Check if rule applies to the class
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if class has identity
            def applies_to?(uml_class)
              # Rule applies to classes that would normally get PropertyTypes
              has_identity?(uml_class)
            end

            # Check if class has identity
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if class has identity
            def has_identity?(uml_class)
              return false unless uml_class.respond_to?(:category)

              category = uml_class.category
              return false unless category

              cat_str = category.to_s.downcase

              # Categories that typically have identity
              cat_str == "feature" ||
                cat_str == "object" ||
                cat_str == "mixin" ||
                (cat_str == "datatype" && has_identity_flag?(uml_class))
            rescue StandardError
              false
            end

            # Check if datatype has identity flag
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if has identity
            def has_identity_flag?(uml_class)
              # Some datatypes can have identity (e.g., for SWE Common)
              # Check for standard-swe-property-types rule
              return false unless uml_class.respond_to?(:matches?)

              uml_class.matches?("rule-xsd-cls-standard-swe-property-types")
            rescue StandardError
              false
            end

            # Determine if property type should be generated
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if PropertyType should be generated
            def should_generate_property_type?(uml_class)
              # Check includePropertyType tagged value
              include_value = get_include_property_type(uml_class)

              # Generate only if explicitly set to true
              [true, "true"].include?(include_value)
            end

            # Get includePropertyType tagged value
            #
            # @param uml_class [Object] The class
            # @return [Boolean, String, nil] The tagged value
            def get_include_property_type(uml_class)
              # Try includePropertyType? method first
              if uml_class.respond_to?(:include_property_type?)
                begin
                  return uml_class.include_property_type?
                rescue StandardError
                  # Fall through
                end
              end

              # Try includePropertyType method
              if uml_class.respond_to?(:includePropertyType)
                begin
                  return uml_class.includePropertyType
                rescue StandardError
                  # Fall through
                end
              end

              # Try tagged value lookup
              if uml_class.respond_to?(:tagged_value)
                begin
                  value = uml_class.tagged_value("includePropertyType")
                  return value unless value.nil?
                rescue StandardError
                  # Fall through
                end
              end

              # Default: not set (which means suppress with this rule)
              nil
            end

            # Determine reason for decision
            #
            # @param should_generate [Boolean] Whether to generate
            # @return [String] Reason for decision
            def determine_reason(should_generate)
              if should_generate
                "includePropertyType=true explicitly set"
              else
                "includePropertyType not set or false, suppressing generation"
              end
            end

            # Generate message
            #
            # @param should_generate [Boolean] Whether to generate
            # @return [String] Processing message
            def generate_message(should_generate)
              if should_generate
                "PropertyType will be generated (explicitly included)"
              else
                "PropertyType generation suppressed (not explicitly included)"
              end
            end

            # Default result when rule doesn't apply
            #
            # @param generate [Boolean] Whether to generate by default
            # @return [Hash] Default result structure
            def default_result(generate = true)
              {
                applies: false,
                result: {
                  generate_property_type: generate,
                  reason: "Rule not active, using default behavior"
                },
                message: "Class does not have identity or rule not active"
              }
            end
          end
        end
      end
    end
  end
end
