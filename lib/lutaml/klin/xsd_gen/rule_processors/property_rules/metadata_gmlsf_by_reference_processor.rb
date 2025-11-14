# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module XsdGen
      module RuleProcessors
        module PropertyRules
          # Processor for rule-xsd-prop-metadata-gmlsf-byReference
          #
          # Use gml:ReferenceType for metadata properties in GMLSF encoding.
          # This ensures GMLSF compliance by encoding metadata properties
          # using by-reference semantics only.
          #
          # @see https://portal.ogc.org/files/?artifact_id=42729 GML Simple Features Profile
          class MetadataGmlsfByReferenceProcessor < BaseProcessor
            RULE_NAME = "rule-xsd-prop-metadata-gmlsf-byReference"

            # Check if this processor applies to the given property
            #
            # @param property [Lutaml::Uml::Property] the property to check
            # @param context [Context] the processing context
            # @return [Boolean] true if property is metadata
            def self.applies_to?(property, context)
              return false unless context.rule_enabled?(RULE_NAME)

              property_is_metadata?(property, context)
            end

            # Process a metadata property
            #
            # @param property [Lutaml::Uml::Property] the property to process
            # @param context [Context] the processing context
            # @return [Hash] processing result with type and imports
            def self.process(property, context)
              return {} unless applies_to?(property, context)

              {
                type: "gml:ReferenceType",
                imports: [
                  {
                    prefix: "gml",
                    namespace: context.gml_namespace,
                  },
                ],
                processed: true,
              }
            end

            # Check if property is metadata
            #
            # @param property [Lutaml::Uml::Property] the property to check
            # @param context [Context] the processing context
            # @return [Boolean] true if property or its value is metadata
            def self.property_is_metadata?(property, context)
              # Check if property itself is marked as metadata
              return true if property.is_metadata

              # Check if property value type is metadata
              if property.type
                value_type = context.model.find_class_by_name(property.type)
                return true if value_type&.stereotype?("metadata")
              end

              false
            end
          end
        end
      end
    end
  end
end