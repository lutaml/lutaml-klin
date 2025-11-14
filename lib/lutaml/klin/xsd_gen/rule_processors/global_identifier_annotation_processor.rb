# frozen_string_literal: true

require_relative "base_processor"

module Lutaml
  module Klin
    module XsdGen
      module RuleProcessors
        # Processor for rule-xsd-all-globalIdentifierAnnotation
        #
        # Add sc:globalIdentifier annotation for classes and properties
        # with global identifiers. Enables unique identification of
        # schema elements across different schemas and applications.
        #
        # @see http://www.interactive-instruments.de/ShapeChange/AppInfo ShapeChange AppInfo
        class GlobalIdentifierAnnotationProcessor < BaseProcessor
          RULE_NAME = "rule-xsd-all-globalIdentifierAnnotation"
          SCAI_NAMESPACE = "http://www.interactive-instruments.de/ShapeChange/AppInfo"
          SCAI_PREFIX = "sc"

          # Check if this processor applies to the given element
          #
          # @param element [Lutaml::Uml::Class, Lutaml::Uml::Property] the element
          # @param context [Context] the processing context
          # @return [Boolean] true if element has global identifier
          def self.applies_to?(element, context)
            return false unless context.rule_enabled?(RULE_NAME)
            return false unless element_is_class_or_property?(element)

            global_id = get_global_identifier(element)
            !global_id.nil? && !global_id.strip.empty?
          end

          # Process an element to add global identifier annotation
          #
          # @param element [Lutaml::Uml::Class, Lutaml::Uml::Property] the element
          # @param context [Context] the processing context
          # @return [Hash] processing result with appinfo elements
          def self.process(element, context)
            return {} unless applies_to?(element, context)

            global_id = get_global_identifier(element)

            {
              appinfo: [
                {
                  namespace: SCAI_NAMESPACE,
                  element: "globalIdentifier",
                  text: global_id,
                },
              ],
              imports: [
                {
                  prefix: SCAI_PREFIX,
                  namespace: SCAI_NAMESPACE,
                },
              ],
            }
          end

          # Check if element is a class or property
          #
          # @param element [Object] the element to check
          # @return [Boolean] true if class or property
          def self.element_is_class_or_property?(element)
            element.is_a?(Lutaml::Uml::Class) ||
              element.is_a?(Lutaml::Uml::Property) ||
              (element.respond_to?(:type) &&
               (element.type == :class || element.type == :property))
          end

          # Get the global identifier from element
          #
          # @param element [Object] the element
          # @return [String, nil] the global identifier or nil
          def self.get_global_identifier(element)
            # Try tagged value first
            value = element.tagged_value("globalIdentifier") if element.respond_to?(:tagged_value)
            return value if value

            # Try as property if available
            if element.respond_to?(:global_identifier)
              element.global_identifier
            else
              nil
            end
          end
        end
      end
    end
  end
end