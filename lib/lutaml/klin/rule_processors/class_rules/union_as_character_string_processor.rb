# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module ClassRules
        # Processes union types that should be encoded as simple strings
        #
        # When a union class has the `asCharacterString` flag set to true,
        # it is encoded as xs:string instead of a complex choice structure.
        #
        # @example Simple String Encoding
        #   <xs:element name="value" type="xs:string"/>
        class UnionAsCharacterStringProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-cls-union-asCharacterString"

          # Checks if this processor applies to the given class
          #
          # @param uml_class [Lutaml::Uml::Class] The UML class to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if class is union with asCharacterString
          def self.applies_to?(uml_class, config)
            return false unless config.rule_enabled?(RULE_NAME)
            return false unless uml_class.category == :union
            return false unless uml_class.as_character_string?

            true
          end

          # Maps a property with union-as-string type
          #
          # @param element [Object] The property element being configured
          # @param property [Lutaml::Uml::Attribute] The property
          # @param type_class [Lutaml::Uml::Class] The union type class
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if processed (type set to xs:string)
          def self.map_property_type(element, property, type_class, xsd_builder, config)
            return false unless applies_to?(type_class, config)

            # Set simple string type
            element.type = "xs:string"

            true
          end

          # Checks if a union should be encoded as character string
          #
          # This is a convenience method for use in property type mapping
          #
          # @param type_class [Lutaml::Uml::Class] The potential union class
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if should encode as string
          def self.encode_as_string?(type_class, config)
            return false unless type_class
            applies_to?(type_class, config)
          end
        end
      end
    end
  end
end