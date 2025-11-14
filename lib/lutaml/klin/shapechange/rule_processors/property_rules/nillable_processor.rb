# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds nillable attribute to property elements
          # Implements rule-xsd-prop-nillable
          # Based on addProperty() in XsdDocument.java lines 2240-2243
          #
          # When a property is voidable, the corresponding element
          # should allow nil values through the nillable attribute
          class NillableProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-nillable"

            protected

            def apply_rule(property, context)
              # Get the property element from context
              property_element = context[:property_element]
              return unless property_element

              # Check if property is voidable or nilReasonAllowed
              if should_add_nillable?(property)
                add_nillable_attribute(property_element, context)
              end
            end

            private

            def should_add_nillable?(property)
              # Check voidable flag with maximum defensive programming
              voidable = safe_call_voidable(property)
              nil_reason_allowed = safe_call_nil_reason_allowed(property)

              voidable || nil_reason_allowed
            end

            def safe_call_voidable(property)
              # Try voidable? first
              if property.respond_to?(:voidable?)
                begin
                  return property.voidable?
                rescue StandardError, NoMethodError
                  # Fall through to try voidable
                end
              end

              # Try voidable (without ?)
              if property.respond_to?(:voidable)
                begin
                  return property.voidable
                rescue StandardError, NoMethodError
                  return false
                end
              end

              false
            end

            def safe_call_nil_reason_allowed(property)
              # Try nil_reason_allowed? first
              if property.respond_to?(:nil_reason_allowed?)
                begin
                  return property.nil_reason_allowed?
                rescue StandardError, NoMethodError
                  # Fall through to try nilReasonAllowed
                end
              end

              # Try nilReasonAllowed
              if property.respond_to?(:nilReasonAllowed)
                begin
                  return property.nilReasonAllowed
                rescue StandardError, NoMethodError
                  return false
                end
              end

              false
            end

            def add_nillable_attribute(element, context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              # Add nillable="true" attribute
              xsd_doc.add_attribute(element, "nillable", "true")
            end
          end
        end
      end
    end
  end
end