# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Processor for rule-xsd-cls-codelist-gmlsf
          #
          # Handles code list properties for GMLSF (GML Simple Features) profiles
          # with a fixed codeSpace attribute.
          #
          # Based on XsdDocument.java:addProperty() lines 2179-2213
          class CodelistGmlsfProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-cls-codelist-gmlsf"

            def self.rule_name
              RULE_NAME
            end

            # Process code list property for GMLSF encoding
            #
            # @param property [Object] The property to process
            # @param context [Hash] Processing context
            # @return [Hash] Processing result with GMLSF encoding info
            def process(property, context = {})
              return default_result unless applies_to?(property, context)

              value_type = get_value_type(property, context)
              code_list_uri = extract_code_list_uri(value_type)

              {
                applies: true,
                result: {
                  encoding_type: "gml:CodeType",
                  fixed_code_space: code_list_uri,
                  gmlsf_encoding: true,
                  creates_anonymous_type: true
                },
                message: "Encoding property #{property.name} as GMLSF code list"
              }
            end

            private

            # Check if rule applies to the property
            #
            # @param property [Object] The property
            # @param context [Hash] Processing context
            # @return [Boolean] True if GMLSF code list encoding applies
            def applies_to?(property, context)
              return false unless property_has_codelist_type?(property, context)

              # Check if property's containing class uses GMLSF encoding
              containing_class = get_containing_class(property, context)
              return false unless containing_class

              class_matches_rule?(containing_class, RULE_NAME)
            end

            # Check if property has a code list value type
            #
            # @param property [Object] The property
            # @param context [Hash] Processing context
            # @return [Boolean] True if value type is code list
            def property_has_codelist_type?(property, context)
              value_type = get_value_type(property, context)
              return false unless value_type

              is_code_list?(value_type)
            end

            # Get the value type of the property
            #
            # @param property [Object] The property
            # @param context [Hash] Processing context
            # @return [Object, nil] The value type class
            def get_value_type(property, context)
              # Try to get from context first
              return context[:value_type] if context[:value_type]

              # Try to get type info from property
              return nil unless property.respond_to?(:type)

              type_info = property.type
              return nil unless type_info

              # Try to resolve from model in context
              model = context[:model]
              return nil unless model

              if model.respond_to?(:class_by_id)
                if type_info.respond_to?(:id)
                  type_class = model.class_by_id(type_info.id)
                end
                return type_class if type_class
              end

              if model.respond_to?(:class_by_name)
                if type_info.respond_to?(:name)
                  type_class = model.class_by_name(type_info.name)
                end
                return type_class if type_class
              end

              nil
            rescue StandardError
              nil
            end

            # Get the containing class of the property
            #
            # @param property [Object] The property
            # @param context [Hash] Processing context
            # @return [Object, nil] The containing class
            def get_containing_class(property, context)
              # Try context first
              return context[:containing_class] if context[:containing_class]

              # Try property method
              if property.respond_to?(:in_class)
                return property.in_class
              elsif property.respond_to?(:owner)
                return property.owner
              end

              nil
            rescue StandardError
              nil
            end

            # Check if class is a code list
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if code list
            def is_code_list?(uml_class)
              return false unless uml_class.respond_to?(:category)

              category = uml_class.category
              return false unless category

              category.to_s.downcase == "codelist"
            rescue StandardError
              false
            end

            # Check if class matches a rule
            #
            # @param uml_class [Object] The class
            # @param rule_name [String] Rule name to check
            # @return [Boolean] True if class matches rule
            def class_matches_rule?(uml_class, rule_name)
              return false unless uml_class.respond_to?(:matches?)

              uml_class.matches?(rule_name)
            rescue StandardError
              false
            end

            # Extract code list URI from value type
            #
            # @param value_type [Object] The code list class
            # @return [String, nil] Code list URI
            def extract_code_list_uri(value_type)
              return nil unless value_type

              # Try 'codeList' first
              uri = get_tagged_value(value_type, "codeList")

              # Fall back to 'vocabulary'
              uri ||= get_tagged_value(value_type, "vocabulary")

              uri&.strip
            end

            # Get tagged value from class
            #
            # @param uml_class [Object] The class
            # @param tag_name [String] Tag name
            # @return [String, nil] Tag value
            def get_tagged_value(uml_class, tag_name)
              return nil unless uml_class.respond_to?(:tagged_values)

              tagged_values = uml_class.tagged_values
              return nil unless tagged_values

              if tagged_values.respond_to?(:[])
                tagged_values[tag_name]
              elsif tagged_values.respond_to?(:find)
                tv = tagged_values.find do |t|
                  t.respond_to?(:tag) && t.tag == tag_name
                end
                tv&.value if tv.respond_to?(:value)
              end
            rescue StandardError
              nil
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: nil,
                message: "Not a GMLSF code list property"
              }
            end
          end
        end
      end
    end
  end
end
