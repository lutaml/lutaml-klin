# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module ClassRules
        # Processes ISO 19139-style property types
        #
        # Generates property types following ISO 19139:2007 metadata
        # encoding standards with gco:ObjectReference and gco:nilReason.
        #
        # @example ISO 19139 Property Type
        #   <xs:complexType name="Building_PropertyType">
        #     <xs:sequence minOccurs="0">
        #       <xs:element ref="bldg:Building"/>
        #     </xs:sequence>
        #     <xs:attributeGroup ref="gco:ObjectReference"/>
        #     <xs:attribute ref="gco:nilReason"/>
        #   </xs:complexType>
        class Standard19139PropertyTypesProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-cls-standard-19139-property-types"

          # GCO namespace (ISO 19139)
          GCO_NS = "http://www.isotc211.org/2005/gco"

          # Checks if this processor applies to the given class
          #
          # @param uml_class [Lutaml::Uml::Class] The UML class to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if rule is enabled
          def self.applies_to?(uml_class, config)
            config.rule_enabled?(RULE_NAME)
          end

          # Generates a property type for the class
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.generate_property_type(uml_class, xsd_builder, config)
            return unless applies_to?(uml_class, config)

            property_type_name = build_property_type_name(uml_class)

            xsd_builder.add_complex_type(property_type_name) do |complex_type|
              # Add sequence with minOccurs="0"
              complex_type.add_sequence(min_occurs: 0) do |sequence|
                # Add element reference
                element_ref = build_element_reference(uml_class, xsd_builder)
                sequence.add_element_ref(element_ref) if element_ref
              end

              # Add gco:ObjectReference for non-codelist/enumeration/union types
              unless omit_object_reference?(uml_class)
                complex_type.add_attribute_group("gco:ObjectReference")
              end

              # Add gco:nilReason attribute
              complex_type.add_attribute_ref("gco:nilReason")

              # Import gco namespace
              xsd_builder.add_import("gco", GCO_NS)
            end
          end

          # Builds the property type name
          #
          # Format: {ClassName}_PropertyType
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @return [String] The property type name
          def self.build_property_type_name(uml_class)
            class_name = uml_class.name
            "#{class_name}_PropertyType"
          end

          # Builds the element reference for the property type
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @return [String, nil] The element reference (e.g., "prefix:ClassName")
          def self.build_element_reference(uml_class, xsd_builder)
            return nil unless uml_class.package

            xmlns = uml_class.package.xmlns
            element_name = uml_class.name

            "#{xmlns}:#{element_name}"
          end

          # Determines if gco:ObjectReference should be omitted
          #
          # Object reference is omitted for:
          # - CodeList types
          # - Enumeration types
          # - Union types
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @return [Boolean] true if should omit gco:ObjectReference
          def self.omit_object_reference?(uml_class)
            category = uml_class.category

            category == :codelist ||
              category == :enumeration ||
              category == :union
          end
        end
      end
    end
  end
end