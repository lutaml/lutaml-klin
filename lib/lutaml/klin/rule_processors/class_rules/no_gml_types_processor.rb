# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module ClassRules
        # Processes classes that should not use GML-specific types
        #
        # Omits GML substitution groups, base types, and attribute groups,
        # using simpler xlink-based references instead.
        #
        # @example Simplified Encoding
        #   <xs:complexType name="BuildingPropertyType">
        #     <xs:sequence minOccurs="0">
        #       <xs:element ref="bldg:Building"/>
        #     </xs:sequence>
        #     <xs:attributeGroup ref="xlink:simpleAttrs"/>
        #   </xs:complexType>
        class NoGmlTypesProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-cls-no-gml-types"

          # Checks if this processor applies to the given class
          #
          # @param uml_class [Lutaml::Uml::Class] The UML class to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if rule is enabled
          def self.applies_to?(uml_class, config)
            config.rule_enabled?(RULE_NAME)
          end

          # Gets the default substitution group (returns nil for no-gml-types)
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [String, nil] nil (no GML substitution group)
          def self.default_substitution_group(uml_class, config)
            return nil if applies_to?(uml_class, config)

            # If rule doesn't apply, return appropriate value
            # (This will be handled by other processors)
            :not_processed
          end

          # Gets the default base type (returns nil for no-gml-types)
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [String, nil] nil (no GML base type)
          def self.default_base_type(uml_class, config)
            return nil if applies_to?(uml_class, config)

            # If rule doesn't apply, return appropriate value
            # (This will be handled by other processors)
            :not_processed
          end

          # Adds property type attribute groups (uses xlink instead of GML)
          #
          # @param property_type_element [Object] The property type element
          # @param uml_class [Lutaml::Uml::Class] The class
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.add_property_type_attributes(property_type_element, uml_class, xsd_builder, config)
            return unless applies_to?(uml_class, config)

            # Add xlink:simpleAttrs instead of GML attribute groups
            property_type_element.add_attribute_group("xlink:simpleAttrs")

            # Import xlink namespace
            xsd_builder.add_import("xlink", xsd_builder.xlink_namespace)
          end

          # Checks if should use GML types
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] false if no-gml-types is enabled
          def self.use_gml_types?(uml_class, config)
            !applies_to?(uml_class, config)
          end

          # Gets the attribute group reference for associations
          #
          # When no-gml-types is enabled, returns xlink:simpleAttrs
          # Otherwise returns nil to let other processors handle it
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [String, Symbol, nil] Attribute group reference or :not_processed
          def self.association_attribute_group(uml_class, config)
            return "xlink:simpleAttrs" if applies_to?(uml_class, config)

            :not_processed
          end
        end
      end
    end
  end
end