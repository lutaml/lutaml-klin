# frozen_string_literal: true

require_relative "base_processor"

module Lutaml
  module Klin
    module XsdGen
      module RuleProcessors
        # Processor for rule-xsd-all-tagged-values
        #
        # Add sc:taggedValue annotations for specified tagged values from
        # model elements. Enables preservation of model metadata in XSD schemas.
        #
        # @see http://www.interactive-instruments.de/ShapeChange/AppInfo ShapeChange AppInfo
        class TaggedValuesProcessor < BaseProcessor
          RULE_NAME = "rule-xsd-all-tagged-values"
          SCAI_NAMESPACE = "http://www.interactive-instruments.de/ShapeChange/AppInfo"
          SCAI_PREFIX = "sc"

          # Check if this processor applies to the given element
          #
          # @param element [Object] the element to check
          # @param context [Context] the processing context
          # @return [Boolean] true if element has specified tagged values
          def self.applies_to?(element, context)
            return false unless context.rule_enabled?(RULE_NAME)

            represent_tags = get_represent_tags(context)
            return false if represent_tags.empty?

            tagged_values = get_tagged_values_for_tags(element, represent_tags)
            !tagged_values.empty?
          end

          # Process an element to add tagged value annotations
          #
          # @param element [Object] the element to process
          # @param context [Context] the processing context
          # @return [Hash] processing result with appinfo elements
          def self.process(element, context)
            return {} unless applies_to?(element, context)

            represent_tags = get_represent_tags(context)
            tagged_values = get_tagged_values_for_tags(element, represent_tags)

            appinfo = []

            # Sort tags alphabetically for deterministic output
            sorted_tags = tagged_values.keys.sort

            sorted_tags.each do |tag|
              values = tagged_values[tag]

              # Sort values alphabetically
              sorted_values = Array(values).sort

              # Create element for each non-empty value
              sorted_values.each do |value|
                next if value.nil? || value.to_s.strip.empty?

                appinfo << {
                  namespace: SCAI_NAMESPACE,
                  element: "taggedValue",
                  attributes: { tag: tag },
                  text: value.to_s,
                }
              end
            end

            return {} if appinfo.empty?

            {
              appinfo: appinfo,
              imports: [
                {
                  prefix: SCAI_PREFIX,
                  namespace: SCAI_NAMESPACE,
                },
              ],
            }
          end

          # Get list of tags to represent from configuration
          #
          # @param context [Context] the processing context
          # @return [Array<String>] list of tag names
          def self.get_represent_tags(context)
            # Get from configuration parameter
            tags_param = context.config["representTaggedValues"]
            return [] if tags_param.nil?

            # Split on comma and strip whitespace
            tags_param.to_s.split(",").map(&:strip).reject(&:empty?)
          end

          # Get tagged values for specified tags
          #
          # @param element [Object] the element
          # @param tags [Array<String>] tag names to retrieve
          # @return [Hash] hash of tag name to value(s)
          def self.get_tagged_values_for_tags(element, tags)
            result = {}

            tags.each do |tag|
              # Try to get tagged value
              if element.respond_to?(:tagged_value)
                value = element.tagged_value(tag)
                result[tag] = Array(value) if value
              elsif element.respond_to?(:tagged_values)
                # Try as hash access
                value = element.tagged_values[tag]
                result[tag] = Array(value) if value
              end
            end

            result
          end
        end
      end
    end
  end
end