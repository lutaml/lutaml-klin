# frozen_string_literal: true

require_relative "../domain/services/validation_service"
require_relative "../domain/reporters/json_reporter"
require_relative "../domain/reporters/markdown_reporter"

module Lutaml
  module Klin
    module Application
      # Workflow for validating schema mappings and generating reports.
      #
      # This workflow orchestrates the validation process by coordinating
      # the ValidationService and reporters to analyze mappings and produce
      # comprehensive reports in multiple formats.
      #
      # @example Basic usage
      #   workflow = ValidationWorkflow.new
      #   result = workflow.validate_mapping(schema_mapping)
      #   paths = workflow.generate_reports(result, "output/validation")
      #
      # @example Custom validation service
      #   custom_service = MyValidationService.new
      #   workflow = ValidationWorkflow.new(validation_service: custom_service)
      class ValidationWorkflow
        # @return [Domain::Services::ValidationService] The validation service
        attr_reader :validation_service

        # Create a new ValidationWorkflow.
        #
        # @param validation_service [Domain::Services::ValidationService]
        #   Custom validation service (default: new ValidationService)
        def initialize(validation_service: nil)
          @validation_service = validation_service ||
                                Domain::Services::ValidationService.new
        end

        # Validate a schema mapping.
        #
        # @param schema_mapping [Lutaml::Klin::Mapping::SchemaMapping]
        #   The schema mapping to validate
        # @return [Domain::ValidationResult] Validation result
        def validate_mapping(schema_mapping)
          validation_service.validate(schema_mapping)
        end

        # Generate validation reports in multiple formats.
        #
        # @param validation_result [Domain::ValidationResult] The validation
        #   result
        # @param output_path [String] Base path for output files (without
        #   extension)
        # @return [Array<String>] Paths to generated report files
        def generate_reports(validation_result, output_path)
          reports = []

          # Generate JSON report
          json_path = generate_json_report(validation_result, output_path)
          reports << json_path if json_path

          # Generate Markdown report
          md_path = generate_markdown_report(validation_result, output_path)
          reports << md_path if md_path

          reports
        end

        # Validate and generate reports in one operation.
        #
        # @param schema_mapping [Lutaml::Klin::Mapping::SchemaMapping]
        #   The schema mapping to validate
        # @param output_path [String] Base path for output files
        # @return [Hash] Hash with :result and :report_paths keys
        def validate_and_report(schema_mapping, output_path)
          result = validate_mapping(schema_mapping)
          report_paths = generate_reports(result, output_path)

          {
            result: result,
            report_paths: report_paths
          }
        end

        private

        # Generate JSON report.
        #
        # @param validation_result [Domain::ValidationResult] The validation
        #   result
        # @param base_path [String] Base output path
        # @return [String, nil] Path to generated JSON file
        def generate_json_report(validation_result, base_path)
          json_path = "#{base_path}.json"
          reporter = Domain::Reporters::JsonReporter.new
          reporter.generate(validation_result, json_path)
        rescue StandardError => e
          warn "Failed to generate JSON report: #{e.message}"
          nil
        end

        # Generate Markdown report.
        #
        # @param validation_result [Domain::ValidationResult] The validation
        #   result
        # @param base_path [String] Base output path
        # @return [String, nil] Path to generated Markdown file
        def generate_markdown_report(validation_result, base_path)
          md_path = "#{base_path}.md"
          reporter = Domain::Reporters::MarkdownReporter.new
          reporter.generate(validation_result, md_path)
        rescue StandardError => e
          warn "Failed to generate Markdown report: #{e.message}"
          nil
        end
      end
    end
  end
end
