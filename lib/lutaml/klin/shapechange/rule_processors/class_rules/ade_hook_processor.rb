# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Generates ADE hook elements for schema extension points
          # Implements rule-xsd-cls-adehook
          # Based on processLocalProperties() in XsdDocument.java lines 1960-1981
          #
          # ADE hooks allow schemas to be extended with custom properties
          # through substitution groups without modifying the base schema
          class AdeHookProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-cls-adehook"

            protected

            def apply_rule(uml_class, context)
              xsd_doc = context[:xsd_document]
              sequence_or_choice = context[:sequence_or_choice]

              return unless sequence_or_choice

              # Construct hook element name
              element_name = "AbstractGenericApplicationPropertyOf#{uml_class.name}"

              # Add property reference to sequence/choice
              add_hook_property_reference(
                xsd_doc,
                sequence_or_choice,
                element_name
              )

              # Add global hook element definition
              add_global_hook_element(
                xsd_doc,
                element_name,
                uml_class,
                context
              )
            end

            private

            def add_hook_property_reference(xsd_doc, container, element_name)
              # Create element reference with 0..* multiplicity
              element_ref = xsd_doc.create_element("element")
              xsd_doc.add_attribute(element_ref, "ref", element_name)

              # Set multiplicity: minOccurs="0" maxOccurs="unbounded"
              add_ade_hook_multiplicity(xsd_doc, element_ref)

              # Append to container (sequence or choice)
              xsd_doc.append_child(container, element_ref)
            end

            def add_global_hook_element(xsd_doc, element_name, uml_class, context)
              # Create global element definition
              hook_element = xsd_doc.create_global_element(element_name)

              # Set attributes
              xsd_doc.add_attribute(hook_element, "name", element_name)
              xsd_doc.add_attribute(hook_element, "type", "anyType")
              xsd_doc.add_attribute(hook_element, "abstract", "true")

              # Record in encoding infos if enabled
              if context[:write_xml_encoding_infos]
                record_encoding_info(xsd_doc, uml_class, element_name, context)
              end
            end

            def add_ade_hook_multiplicity(xsd_doc, element)
              # ADE hooks are always optional and unbounded
              # Multiplicity: 0..*
              xsd_doc.add_attribute(element, "minOccurs", "0")
              xsd_doc.add_attribute(element, "maxOccurs", "unbounded")
            end

            def record_encoding_info(xsd_doc, uml_class, element_name, context)
              # Record encoding information for documentation
              encoding_infos = context[:encoding_infos]
              return unless encoding_infos

              target_namespace = context[:target_namespace]
              encoding_infos.add(uml_class, element_name, target_namespace)
            end
          end
        end
      end
    end
  end
end