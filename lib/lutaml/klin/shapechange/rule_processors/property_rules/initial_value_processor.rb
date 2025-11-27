# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds default or fixed attributes for initial values
          # Implements rule-xsd-prop-initialValue
          # Based on addProperty() in XsdDocument.java lines 2139-2150 and 2245-2250
          #
          # Properties with initial values get default (changeable) or
          # fixed (readonly) attributes in the generated XSD
          class InitialValueProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-initialValue"

            protected

            def apply_rule(property, context)
              # Get the property element from context
              property_element = context[:property_element]
              return unless property_element

              # Get initial value
              initial_value = get_initial_value(property)
              return if initial_value.nil? || initial_value.empty?

              # Add appropriate attribute based on readonly status
              add_initial_value_attribute(
                property,
                property_element,
                initial_value,
                context
              )
            end

            private

            def get_initial_value(property)
              return nil unless property.respond_to?(:initial_value)

              value = property.initial_value
              return nil if value.nil?

              # Handle both string and method responses
              value.is_a?(String) ? value : value.to_s
            end

            def add_initial_value_attribute(property, element, value, context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              # Strip quotes from value
              clean_value = strip_quotes(value)

              # Determine if property is readonly
              if readonly?(property)
                # Use 'fixed' for readonly properties
                xsd_doc.add_attribute(element, "fixed", clean_value)
              else
                # Use 'default' for changeable properties
                xsd_doc.add_attribute(element, "default", clean_value)

                # For attributes with default, remove 'use' attribute
                # because default implies optional
                if attribute_element?(element)
                  remove_use_attribute(element, xsd_doc)
                end
              end
            end

            def readonly?(property)
              return false unless property.respond_to?(:read_only?)

              property.read_only?
            rescue StandardError
              # Fallback for different method names
              return property.readonly if property.respond_to?(:readonly)

              false
            end

            def attribute_element?(element)
              # Check if this is an XML attribute element (not element)
              # This would be determined by element's local name
              element.respond_to?(:local_name?) &&
                element.local_name? == "attribute"
            rescue StandardError
              false
            end

            def strip_quotes(value)
              # Remove surrounding quotes from value
              # Based on stripQuotes() in XsdDocument.java
              result = value.dup
              result.delete!('"')
              result
            end

            def remove_use_attribute(element, xsd_doc)
              # Remove 'use' attribute if present
              # Default attribute implies optional use
              if element.respond_to?(:has_attribute?) &&
                 element.has_attribute?("use")
                xsd_doc.remove_attribute(element, "use")
              end
            end
          end
        end
      end
    end
  end
end
