# frozen_string_literal: true

require "json"

module Lutaml
  module Klin
    module Domain
      module Reporters
        # Reporter for generating JSON validation reports.
        #
        # This reporter converts ValidationResult objects into structured
        # JSON documents suitable for machine processing and integration
        # with other tools.
        #
        # The JSON format includes all validation details, statistics,
        # and unresolved items in a hierarchical structure.
        #
        # @example Generating a JSON report
        #   reporter = JsonReporter.new
        #   path = reporter.generate(validation_result, "report.json")
        #   puts "Report written to #{path}"
        class JsonReporter
          # Generate a JSON validation report.
          #
          # @param validation_result [ValidationResult] The validation result
          # @param output_path [String] Path where the report should be written
          # @return [String] The path to the generated report
          def generate(validation_result, output_path)
            json_structure = build_json_structure(validation_result)
            json_content = JSON.pretty_generate(json_structure)

            File.write(output_path, json_content)
            output_path
          end

          private

          # Build the complete JSON structure from validation result.
          #
          # @param result [ValidationResult] The validation result
          # @return [Hash] JSON-serializable hash structure
          def build_json_structure(result)
            {
              "version" => "1.0",
              "generated_at" => result.generated_at,
              "validation_status" => result.valid? ? "valid" : "invalid",
              "summary" => build_summary_section(result),
              "unresolved_items" => result.unresolved_items,
              "packages" => build_packages_section(result),
              "global_issues" => result.global_issues
            }
          end

          # Build the summary statistics section.
          #
          # @param result [ValidationResult] The validation result
          # @return [Hash] Summary statistics
          def build_summary_section(result)
            {
              "total_packages" => result.total_packages,
              "total_classes" => result.total_classes,
              "resolved_classes" => result.resolved_classes,
              "partial_classes" => result.summary[:partial_classes] || 0,
              "unresolved_classes" => result.summary[:unresolved_classes] || 0,
              "total_attributes" => result.total_attributes,
              "resolved_attributes" => result.resolved_attributes,
              "partial_attributes" => result.summary[:partial_attributes] || 0,
              "unresolved_attributes" =>
                result.summary[:unresolved_attributes] || 0,
              "resolution_rate" => result.resolution_rate,
              "attribute_resolution_rate" =>
                result.summary[:attribute_resolution_rate] || 0.0
            }
          end

          # Build the packages section with detailed information.
          #
          # @param result [ValidationResult] The validation result
          # @return [Array<Hash>] Package details
          def build_packages_section(result)
            result.packages.map do |package|
              {
                "name" => package[:name],
                "namespace" => package[:namespace],
                "statistics" => package[:statistics],
                "resolution_rate" => package[:resolution_rate],
                "fully_resolved" => package[:fully_resolved],
                "classes" => build_classes_section(package[:classes])
              }
            end
          end

          # Build the classes section for a package.
          #
          # @param classes [Array<Hash>] Class details
          # @return [Array<Hash>] Formatted class details
          def build_classes_section(classes)
            return [] unless classes

            classes.map do |cls|
              {
                "name" => cls[:name],
                "status" => cls[:status],
                "method" => cls[:method],
                "xsd_name" => cls[:xsd_name],
                "attributes" => build_attributes_section(cls[:attributes])
              }
            end
          end

          # Build the attributes section for a class.
          #
          # @param attributes [Array<Hash>] Attribute details
          # @return [Array<Hash>] Formatted attribute details
          def build_attributes_section(attributes)
            return [] unless attributes

            attributes.map do |attr|
              {
                "name" => attr[:name],
                "status" => attr[:status],
                "method" => attr[:method],
                "uml_type" => attr[:uml_type],
                "xsd_type" => attr[:xsd_type],
                "error" => attr[:error]
              }
            end
          end
        end
      end
    end
  end
end