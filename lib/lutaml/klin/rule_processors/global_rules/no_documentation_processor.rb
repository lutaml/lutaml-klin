# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module GlobalRules
        # Processes suppression of documentation elements
        #
        # When enabled, prevents generation of xs:documentation elements
        # in XML Schema annotations, creating minimal schemas without
        # human-readable documentation.
        #
        # @example No Documentation
        #   <xs:element name="Building" type="bldg:BuildingType">
        #     <xs:annotation>
        #       <xs:appinfo>
        #         <sc:globalIdentifier>urn:x:building</sc:globalIdentifier>
        #       </xs:appinfo>
        #     </xs:annotation>
        #   </xs:element>
        class NoDocumentationProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-all-no-documentation"

          # Checks if this processor applies (documentation should be suppressed)
          #
          # @param model_element [Object] The model element
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if documentation should be suppressed
          def self.applies_to?(_model_element, config)
            config.rule_enabled?(RULE_NAME)
          end

          # Determines if documentation should be generated
          #
          # @param model_element [Object] The model element
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] false if rule is enabled (suppress docs)
          def self.should_generate_documentation?(model_element, config)
            !applies_to?(model_element, config)
          end

          # Adds documentation to an annotation if rule allows
          #
          # @param annotation_builder [Object] The annotation builder
          # @param model_element [Object] The model element
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @param documentation_text [String, nil] The documentation text
          # @return [Boolean] true if documentation was added, false if suppressed
          def self.add_documentation(annotation_builder, model_element, config,
                                     documentation_text)
            return false if applies_to?(model_element, config)
            if documentation_text.nil? || documentation_text.strip.empty?
              return false
            end

            # Documentation allowed - add it
            annotation_builder.add_documentation(documentation_text)
            true
          end
        end
      end
    end
  end
end
