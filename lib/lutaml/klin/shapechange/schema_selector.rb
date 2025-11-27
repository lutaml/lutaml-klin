# frozen_string_literal: true

module Lutaml
  module Klin
    module Shapechange
      # Selects application schemas based on ShapeChange configuration
      # Implements the logic from ShapeChange's Model.selectedSchemas()
      class SchemaSelector
        attr_reader :config

        def initialize(config)
          @config = config
        end

        # Get list of selected schema names from config
        # @return [Array<String>] List of schema names (e.g., ["uro"])
        def selected_schema_names
          # Read appSchemaName from input config
          app_schema_name = config.input_config&.dig(:app_schema_name)

          return [] unless app_schema_name

          # appSchemaName can be comma-separated list
          app_schema_name.split(',').map(&:strip)
        end

        # Check if a schema (package) is selected for processing
        # @param package_name [String] Package name to check
        # @return [Boolean] True if package is selected
        def selected_schema?(package_name)
          selected = selected_schema_names
          return true if selected.empty? # No filter = process all

          # Match by exact package name (case-insensitive)
          selected.any? { |schema| schema.downcase == package_name.to_s.downcase }
        end
      end
    end
  end
end