# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module GlobalRules
        # Processes descriptor annotations for model elements
        #
        # Generates sc:descriptor annotation elements for configured descriptors
        # (alias, definition, description, etc.) in XML Schema annotations.
        #
        # @example Descriptor Annotation
        #   <xs:annotation>
        #     <xs:appinfo>
        #       <sc:descriptor name="alias">Bâtiment</sc:descriptor>
        #       <sc:descriptor name="alias" lang="de">Gebäude</sc:descriptor>
        #       <sc:descriptor name="definition">A permanent structure</sc:descriptor>
        #     </xs:appinfo>
        #   </xs:annotation>
        class DescriptorAnnotationProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-all-descriptorAnnotation"

          # ShapeChange Application Info namespace
          SCAI_NS = "http://www.interactive-instruments.de/ShapeChange/AppInfo"
          SCAI_PREFIX = "sc"

          # Checks if this processor applies to the given model element
          #
          # @param model_element [Object] The model element (Class, Property, Package)
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if rule is enabled and descriptors configured
          def self.applies_to?(model_element, config)
            return false unless config.rule_enabled?(RULE_NAME)
            return false if descriptors_to_represent(config).empty?

            true
          end

          # Adds descriptor annotations to an annotation element
          #
          # @param annotation_builder [Object] The annotation builder
          # @param model_element [Object] The model element with descriptors
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @return [void]
          def self.add_descriptor_annotations(annotation_builder, model_element, config, xsd_builder)
            return unless applies_to?(model_element, config)
            return unless model_element.respond_to?(:descriptors)

            descriptors = model_element.descriptors
            return if descriptors.nil? || descriptors.empty?

            # Get configured descriptors to represent
            descriptors_to_rep = descriptors_to_represent(config)

            # Process each configured descriptor
            descriptors_to_rep.each do |descriptor_name|
              next unless descriptors.key?(descriptor_name)

              descriptor_values = descriptors[descriptor_name]
              next if descriptor_values.nil? || descriptor_values.empty?

              # Sort values for consistent output
              sorted_values = descriptor_values.sort_by do |val|
                [val[:lang] || "", val[:value] || ""]
              end

              # Add descriptor elements
              sorted_values.each do |descriptor_val|
                next if descriptor_val[:value].nil? || descriptor_val[:value].strip.empty?

                add_descriptor_element(
                  annotation_builder,
                  descriptor_name,
                  descriptor_val,
                  xsd_builder
                )
              end
            end
          end

          # Adds a single descriptor element
          #
          # @param annotation_builder [Object] The annotation builder
          # @param descriptor_name [String] The descriptor name
          # @param descriptor_value [Hash] Hash with :value and optional :lang
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @return [void]
          def self.add_descriptor_element(annotation_builder, descriptor_name, descriptor_value, xsd_builder)
            # Ensure appinfo exists
            appinfo = annotation_builder.appinfo || annotation_builder.add_appinfo

            # Create descriptor element
            appinfo.add_element("#{SCAI_PREFIX}:descriptor") do |desc|
              desc.add_attribute("name", descriptor_name)

              # Add lang attribute if present
              if descriptor_value[:lang] && !descriptor_value[:lang].strip.empty?
                desc.add_attribute("lang", descriptor_value[:lang])
              end

              # Add text content
              desc.text = descriptor_value[:value]
            end

            # Import ShapeChange Application Info namespace
            xsd_builder.add_import(SCAI_PREFIX, SCAI_NS)
          end

          # Gets the list of descriptors to represent from configuration
          #
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Array<String>] List of descriptor names
          def self.descriptors_to_represent(config)
            param = config.parameter("representDescriptors")
            return [] if param.nil? || param.strip.empty?

            # Split by comma and normalize
            param.split(",").map(&:strip).reject(&:empty?)
          end
        end
      end
    end
  end
end