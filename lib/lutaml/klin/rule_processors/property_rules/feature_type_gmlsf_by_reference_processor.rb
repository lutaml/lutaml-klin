# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module PropertyRules
        # Processes feature type properties for GMLSF by-reference encoding
        #
        # In GML Simple Features (GMLSF) profiles, feature properties must use
        # by-reference encoding via gml:ReferenceType to ensure compliance with
        # the Simple Features specification.
        #
        # @example GMLSF Feature Property
        #   <xs:element name="relatedFeature"
        #               type="gml:ReferenceType"
        #               minOccurs="0"/>
        class FeatureTypeGmlsfByReferenceProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-prop-featureType-gmlsf-byReference"

          # GML namespace for ReferenceType
          GML_NAMESPACE = "http://www.opengis.net/gml/3.2"

          # Checks if this processor applies to the given property
          #
          # @param property [Lutaml::Uml::Attribute] The property to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if property has feature type value in GMLSF context
          def self.applies_to?(property, config)
            return false unless config.rule_enabled?(RULE_NAME)
            return false unless property.category_of_value == :feature

            true
          end

          # Processes a feature type property for GMLSF encoding
          #
          # @param property [Lutaml::Uml::Attribute] The property to process
          # @param parent_element [Object] Parent XSD element
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.process_property(property, parent_element, xsd_builder,
                                    config)
            return unless applies_to?(property, config)

            parent_element.add_element(property.name) do |element|
              # Add standard annotation
              if property.definition
                element.add_annotation do |annotation|
                  annotation.add_documentation(property.definition)
                end
              end

              # Set type to gml:ReferenceType
              element.type = "gml:ReferenceType"

              # Apply multiplicity
              apply_multiplicity(element, property)

              # Import GML namespace
              gml_prefix = config.namespace_prefix_for(GML_NAMESPACE) || "gml"
              xsd_builder.add_import(gml_prefix, GML_NAMESPACE)

              # Record encoding info if enabled
              if xsd_builder.write_xml_encoding_infos?
                xsd_builder.add_encoding_info(
                  property,
                  property.name,
                  xsd_builder.target_namespace,
                  false
                )
              end
            end
          end

          # Applies multiplicity constraints to the element
          #
          # @param element [Object] The element
          # @param property [Lutaml::Uml::Attribute] The property
          # @return [void]
          def self.apply_multiplicity(element, property)
            return unless property.cardinality

            min_occurs = property.cardinality[:min] || 1
            max_occurs = property.cardinality[:max] || 1

            element.min_occurs = min_occurs unless min_occurs == 1

            if [-1, Float::INFINITY].include?(max_occurs)
              element.max_occurs = "unbounded"
            elsif max_occurs != 1
              element.max_occurs = max_occurs
            end
          end
        end
      end
    end
  end
end
