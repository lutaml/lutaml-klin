# frozen_string_literal: true

require_relative "base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Generates <xs:sequence> or <xs:choice> content model for classes
        # Implements rule-xsd-cls-sequence
        # Based on pComplexType() sequence/choice logic in XsdDocument.java
        class SequenceProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-cls-sequence"

          protected

          def apply_rule(uml_class, context)
            xsd_doc = context[:xsd_document]
            container = context[:content_container]

            return unless container

            # Determine if we need sequence or choice
            sequence_or_choice = if needs_choice?(uml_class)
                                   xsd_doc.add_choice(container)
                                 else
                                   xsd_doc.add_sequence(container)
                                 end

            # Store for PropertyElementProcessor to add property elements
            context[:sequence_or_choice] = sequence_or_choice
            context[:current_sequence] = sequence_or_choice
          end

          private

          def needs_choice?(uml_class)
            # Check if class is a Union type
            # In UML model, unions are indicated by stereotype or category
            stereotypes = Array(uml_class.stereotype)

            # Union types need choice instead of sequence
            return true if stereotypes.include?("Union")
            return true if stereotypes.include?("union")

            false
          end
        end
      end
    end
  end
end
