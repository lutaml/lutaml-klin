# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module XsdGen
      module RuleProcessors
        module PackageRules
          # Processor for rule-xsd-pkg-gmlProfileSchema
          #
          # Add gml:gmlProfileSchema annotation to schema for GML profile
          # compliance metadata. This enables packages to declare which GML
          # profile they conform to.
          #
          # @see http://schemas.opengis.net/gml/3.2.1/gmlBase.xsd GML 3.2 Schema
          class GmlProfileSchemaProcessor < BaseProcessor
            RULE_NAME = "rule-xsd-pkg-gmlProfileSchema"
            GML_32_NAMESPACE = "http://www.opengis.net/gml/3.2"

            # Check if this processor applies to the given package
            #
            # @param package [Lutaml::Uml::Package] the package to check
            # @param context [Context] the processing context
            # @return [Boolean] true if rule enabled and GML 3.2
            def self.applies_to?(package, context)
              return false unless context.rule_enabled?(RULE_NAME)
              return false unless context.gml_namespace == GML_32_NAMESPACE

              # Check if package has gmlProfileSchema value
              profile_value = get_profile_value(package)
              !profile_value.nil? && !profile_value.strip.empty?
            end

            # Process a package to add gml:gmlProfileSchema annotation
            #
            # @param package [Lutaml::Uml::Package] the package to process
            # @param context [Context] the processing context
            # @return [Hash] processing result with appinfo elements
            def self.process(package, context)
              return {} unless applies_to?(package, context)

              profile_value = get_profile_value(package)

              {
                appinfo: [
                  {
                    namespace: context.gml_namespace,
                    element: "gmlProfileSchema",
                    text: profile_value
                  }
                ],
                imports: [
                  {
                    prefix: "gml",
                    namespace: context.gml_namespace
                  }
                ]
              }
            end

            # Get the GML profile schema value from package
            #
            # @param package [Lutaml::Uml::Package] the package
            # @return [String, nil] the profile value or nil
            def self.get_profile_value(package)
              # Try tagged value first
              value = package.tagged_value("gmlProfileSchema")
              return value if value

              # Try as a property if available
              package.respond_to?(:gml_profile_schema) ? package.gml_profile_schema : nil
            end
          end
        end
      end
    end
  end
end
