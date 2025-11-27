# frozen_string_literal: true

require_relative "base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Generates <xs:element> for UML classes
        # Implements rule-xsd-cls-object-element
        class ObjectElementProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-cls-object-element"

          protected

          def apply_rule(uml_class, context)
            # Skip enums - they're handled by EnumerationProcessor
            return if uml_class.is_a?(Lutaml::Uml::Enum)

            xsd_doc = context[:xsd_document]
            attrs = additional_attributes(uml_class, context)

            # Add element: <xs:element name="Building" type="uro:BuildingType"/>
            xsd_doc.add_element(
              name: uml_class.name,
              type: "#{xsd_doc.prefix}:#{uml_class.name}Type",
              **attrs
            )

            # Record mapping if collector present
            record_element_mapping(uml_class, attrs, context) if context[:mapping_collector]
          end

          private

          def additional_attributes(uml_class, context)
            attrs = {}

            # Add abstract="true" if class is abstract (only for Class types)
            if uml_class.respond_to?(:is_abstract) && uml_class.is_abstract
              attrs[:abstract] = "true"
            end

            # Add substitutionGroup if has superclass
            if uml_class.generalization&.general
              # Parent class reference
              parent_name = uml_class.generalization.general.name ||
                            uml_class.generalization.general_name
              if parent_name
                attrs[:substitutionGroup] =
                  "#{context[:prefix]}:#{parent_name}"
              end
            elsif should_use_gml_substitution?(uml_class)
              # Use GML base types for stereotyped classes
              attrs[:substitutionGroup] = gml_substitution_group(uml_class)
            end

            attrs
          end

          def should_use_gml_substitution?(uml_class)
            # FeatureTypes use gml:AbstractFeature
            return true if uml_class.stereotype&.include?("FeatureType")
            return true if uml_class.stereotype&.include?("featuretype")

            false
          end

          def gml_substitution_group(uml_class)
            # Check stereotype array
            stereotypes = uml_class.stereotype || []

            if stereotypes.include?("FeatureType") || stereotypes.include?("featuretype")
              "gml:AbstractFeature"
            elsif stereotypes.include?("ObjectType") || stereotypes.include?("objecttype")
              "gml:AbstractGML"
            end
          end

          def record_element_mapping(uml_class, attrs, context)
            collector = context[:mapping_collector]
            return unless collector

            collector.record_class_mapping(
              uml_class: uml_class,
              xsd_element_name: uml_class.name,
              xsd_element_substitution_group: attrs[:substitutionGroup],
              rules_applied: [RULE_ID],
              context: {
                encoding_rule: context[:config]&.target_config&.dig(:default_encoding_rule),
                is_abstract: attrs[:abstract] == "true",
                is_substitutable: !attrs[:substitutionGroup].nil? && !attrs[:substitutionGroup].to_s.empty?,
                substitution_group: attrs[:substitutionGroup]
              }
            )
          end
        end
      end
    end
  end
end
