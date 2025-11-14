# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Processor for rule-xsd-cls-codelist-asDictionaryGml33
          #
          # Handles code lists represented as GML dictionaries using gml:ReferenceType
          # for GML 3.3 encodings.
          #
          # Based on XsdDocument.java:mapPropertyType() lines 3192-3210
          class CodelistAsDictionaryGml33Processor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-cls-codelist-asDictionaryGml33"

            def self.rule_name
              RULE_NAME
            end

            # Process code list as dictionary for GML 3.3
            #
            # @param uml_class [Lutaml::Uml::Class] The class to process
            # @param context [Hash] Processing context
            # @return [Hash] Processing result with code list encoding info
            def process(uml_class, context = {})
              return default_result unless applies_to?(uml_class)

              {
                applies: true,
                result: {
                  encoding_type: "gml:ReferenceType",
                  as_dictionary: true,
                  gml_version: "3.3",
                  code_list_uri: extract_code_list_uri(uml_class),
                  representation: extract_representation(uml_class)
                },
                message: "Encoding code list #{uml_class.name} as GML 3.3 dictionary"
              }
            end

            private

            # Extract code list URI from tagged values
            #
            # @param uml_class [Lutaml::Uml::Class] The code list class
            # @return [String, nil] Code list URI
            def extract_code_list_uri(uml_class)
              # Try 'codeList' first, then 'vocabulary'
              uri = get_tagged_value(uml_class, "codeList")
              uri ||= get_tagged_value(uml_class, "vocabulary")
              uri&.strip
            end

            # Extract code list representation from tagged values
            #
            # @param uml_class [Lutaml::Uml::Class] The code list class
            # @return [String, nil] Representation type
            def extract_representation(uml_class)
              rep = get_tagged_value(uml_class, "codeListRepresentation")
              rep&.strip
            end

            # Get tagged value with defensive programming
            #
            # @param uml_class [Object] The class
            # @param tag_name [String] Tag name to retrieve
            # @return [String, nil] Tag value or nil
            def get_tagged_value(uml_class, tag_name)
              return nil unless uml_class.respond_to?(:tagged_values)

              tagged_values = uml_class.tagged_values
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

            # Check if rule applies to the class
            #
            # @param uml_class [Lutaml::Uml::Class] The class
            # @return [Boolean] True if class is a code list represented as dictionary for GML 3.3
            def applies_to?(uml_class)
              return false unless is_code_list?(uml_class)

              # Check if marked as dictionary
              as_dictionary?(uml_class)
            end

            # Check if class is a code list
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if code list
            def is_code_list?(uml_class)
              return false unless uml_class.respond_to?(:category)

              category = uml_class.category
              return false unless category

              # Category can be a string or symbol
              category.to_s.downcase == "codelist"
            rescue StandardError
              false
            end

            # Check if code list is marked as dictionary
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if dictionary representation
            def as_dictionary?(uml_class)
              # Try asDictionary method
              if uml_class.respond_to?(:as_dictionary?)
                return uml_class.as_dictionary?
              elsif uml_class.respond_to?(:as_dictionary)
                result = uml_class.as_dictionary
                return result if result.is_a?(TrueClass) || result.is_a?(FalseClass)
              end

              # Try asDictionaryGml33 method
              if uml_class.respond_to?(:as_dictionary_gml33?)
                return uml_class.as_dictionary_gml33?
              elsif uml_class.respond_to?(:as_dictionary_gml33)
                result = uml_class.as_dictionary_gml33
                return result if result.is_a?(TrueClass) || result.is_a?(FalseClass)
              end

              # Check tagged values
              as_dict_tv = get_tagged_value(uml_class, "asDictionary")
              return true if as_dict_tv&.to_s&.downcase == "true"

              as_dict_gml33_tv = get_tagged_value(uml_class, "asDictionaryGml33")
              return true if as_dict_gml33_tv&.to_s&.downcase == "true"

              false
            rescue StandardError
              false
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: nil,
                message: "Not a code list represented as dictionary for GML 3.3"
              }
            end
          end
        end
      end
    end
  end
end