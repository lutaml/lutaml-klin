# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      # Value object representing the result of a complete processing operation.
      #
      # A ProcessingResult encapsulates the entire output of the unified
      # process workflow, including the schema mapping, validation results,
      # output paths, statistics, and metadata.
      #
      # This is an immutable value object - all attributes are read-only and
      # set at construction time.
      #
      # @example Creating a processing result
      #   result = ProcessingResult.new(
      #     schema_mapping: schema_mapping,
      #     validation_result: validation_result,
      #     output_paths: {
      #       mappings: "output/mappings",
      #       validation: "output/validation",
      #       spa: "output/spa"
      #     },
      #     statistics: {
      #       total_packages: 3,
      #       resolution_rate: 96.0
      #     }
      #   )
      class ProcessingResult
        # @return [Mapping::SchemaMapping] The generated schema mapping
        attr_reader :schema_mapping

        # @return [ValidationResult, nil] Validation result if validation
        #   was performed
        attr_reader :validation_result

        # @return [Hash<Symbol, String>] Paths to generated outputs
        attr_reader :output_paths

        # @return [Hash] Processing statistics
        attr_reader :statistics

        # @return [Hash] Additional metadata about the processing
        attr_reader :metadata

        # @return [String] ISO 8601 timestamp when processing completed
        attr_reader :completed_at

        # Create a new ProcessingResult.
        #
        # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
        # @param validation_result [ValidationResult, nil] Validation result
        # @param output_paths [Hash<Symbol, String>] Output file/directory
        #   paths
        # @param statistics [Hash] Processing statistics
        # @param metadata [Hash] Additional metadata
        # @param completed_at [String] ISO 8601 timestamp (default: now)
        def initialize(schema_mapping:, validation_result: nil,
                       output_paths: {}, statistics: {}, metadata: {},
                       completed_at: nil)
          @schema_mapping = schema_mapping
          @validation_result = validation_result
          @output_paths = output_paths.freeze
          @statistics = statistics.freeze
          @metadata = metadata.freeze
          @completed_at = completed_at || Time.now.utc.iso8601
          freeze
        end

        # Check if processing completed successfully.
        #
        # @return [Boolean] true if all steps completed without errors
        def success?
          schema_mapping && (!validation_enabled? || validation_passed?)
        end

        # Check if validation was performed.
        #
        # @return [Boolean] true if validation result is present
        def validation_enabled?
          !validation_result.nil?
        end

        # Check if validation passed (if it was performed).
        #
        # @return [Boolean] true if validation passed or wasn't performed
        def validation_passed?
          return true unless validation_enabled?

          validation_result.valid?
        end

        # Get the overall resolution rate.
        #
        # @return [Float] resolution rate as percentage (0-100)
        def resolution_rate
          statistics[:resolution_rate] || 0.0
        end

        # Get total number of packages processed.
        #
        # @return [Integer] total packages
        def total_packages
          statistics[:total_packages] || 0
        end

        # Get total number of classes processed.
        #
        # @return [Integer] total classes
        def total_classes
          statistics[:total_classes] || 0
        end

        # Get number of resolved classes.
        #
        # @return [Integer] resolved classes
        def resolved_classes
          statistics[:resolved_classes] || 0
        end

        # Get total number of attributes processed.
        #
        # @return [Integer] total attributes
        def total_attributes
          statistics[:total_attributes] || 0
        end

        # Get number of resolved attributes.
        #
        # @return [Integer] resolved attributes
        def resolved_attributes
          statistics[:resolved_attributes] || 0
        end

        # Get mapping output paths.
        #
        # @return [Array<String>] list of mapping file paths
        def mapping_paths
          Array(output_paths[:mappings])
        end

        # Get validation report paths.
        #
        # @return [Array<String>] list of validation report paths
        def validation_paths
          Array(output_paths[:validation])
        end

        # Get SPA output path.
        #
        # @return [String, nil] SPA directory path
        def spa_path
          output_paths[:spa]
        end

        # Returns a human-readable summary of the processing result.
        #
        # @return [String] Summary description
        def summary
          lines = []
          lines << "Processing completed at #{completed_at}"
          lines << "Status: #{success? ? 'SUCCESS' : 'COMPLETED WITH ISSUES'}"
          lines << ""
          lines << "Statistics:"
          lines << "  Packages: #{total_packages}"
          lines << "  Classes: #{resolved_classes}/#{total_classes} " \
                   "(#{resolution_rate.round(1)}%)"
          lines << "  Attributes: #{resolved_attributes}/#{total_attributes}"

          if validation_enabled?
            lines << ""
            lines << "Validation: #{validation_passed? ? 'PASSED' : 'FAILED'}"
          end

          if output_paths.any?
            lines << ""
            lines << "Output:"
            output_paths.each do |type, path|
              lines << "  #{type.to_s.capitalize}: #{path}"
            end
          end

          lines.join("\n")
        end

        # Returns a detailed inspection string for debugging.
        #
        # @return [String] Detailed result information
        def inspect
          "#<#{self.class.name} " \
            "success=#{success?} " \
            "resolution_rate=#{resolution_rate}% " \
            "packages=#{total_packages} " \
            "classes=#{resolved_classes}/#{total_classes} " \
            "validation=#{validation_enabled? ? (validation_passed? ? 'passed' : 'failed') : 'disabled'}>"
        end

        alias to_s summary
      end
    end
  end
end