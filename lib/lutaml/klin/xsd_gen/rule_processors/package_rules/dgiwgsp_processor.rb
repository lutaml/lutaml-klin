# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module XsdGen
      module RuleProcessors
        module PackageRules
          # Processor for rule-xsd-pkg-dgiwgsp
          #
          # Add DGIWG compliance level and GML profile schema annotations
          # for DGIWG Spatial Profile compliance. Both ComplianceLevel and
          # GMLProfileSchema must be present.
          #
          # @see http://www.dgiwg.org/gml/3.2/profiles/spatial/1.0/ DGIWG Spatial Profile
          class DgiwgspProcessor < BaseProcessor
            RULE_NAME = "rule-xsd-pkg-dgiwgsp"
            DGIWG_NAMESPACE = "http://www.dgiwg.org/gml/3.2/profiles/spatial/1.0/"
            DGIWG_NSABR = "gmldgiwgsp"
            DGIWG_SCHEMA_LOCATION = "http://www.dgiwg.org/gml/3.2/profiles/spatial/1.0/profile.xsd"

            # Check if this processor applies to the given package
            #
            # @param package [Lutaml::Uml::Package] the package to check
            # @param context [Context] the processing context
            # @return [Boolean] true if both DGIWG values present
            def self.applies_to?(package, context)
              return false unless context.rule_enabled?(RULE_NAME)

              compliance_level = get_compliance_level(package)
              profile_schema = get_profile_schema(package)

              !compliance_level.nil? && !compliance_level.strip.empty? &&
                !profile_schema.nil? && !profile_schema.strip.empty?
            end

            # Process a package to add DGIWG annotations
            #
            # @param package [Lutaml::Uml::Package] the package to process
            # @param context [Context] the processing context
            # @return [Hash] processing result with appinfo elements
            def self.process(package, context)
              return {} unless applies_to?(package, context)

              compliance_level = get_compliance_level(package)
              profile_schema = get_profile_schema(package)

              {
                appinfo: [
                  {
                    source: DGIWG_SCHEMA_LOCATION,
                    elements: [
                      {
                        namespace: DGIWG_NAMESPACE,
                        element: "ComplianceLevel",
                        text: compliance_level
                      },
                      {
                        namespace: DGIWG_NAMESPACE,
                        element: "GMLProfileSchema",
                        text: profile_schema
                      }
                    ]
                  }
                ],
                imports: [
                  {
                    prefix: DGIWG_NSABR,
                    namespace: DGIWG_NAMESPACE
                  }
                ]
              }
            end

            # Get the DGIWG compliance level from package
            #
            # @param package [Lutaml::Uml::Package] the package
            # @return [String, nil] the compliance level or nil
            def self.get_compliance_level(package)
              package.tagged_value("dgiwgComplianceLevel")
            end

            # Get the DGIWG GML profile schema from package
            #
            # @param package [Lutaml::Uml::Package] the package
            # @return [String, nil] the profile schema URL or nil
            def self.get_profile_schema(package)
              package.tagged_value("dgiwgGMLProfileSchema")
            end
          end
        end
      end
    end
  end
end
