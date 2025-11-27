# frozen_string_literal: true

require_relative "../application/processing_workflow"

module Lutaml
  module Klin
    module Commands
      # CLI command for the unified processing workflow.
      #
      # ProcessCommand provides the user interface for executing the complete
      # UML-to-XSD mapping workflow in a single atomic operation.
      #
      # @example Basic usage
      #   command = ProcessCommand.new(
      #     lur: "model.lur",
      #     lxr: "schemas.lxr",
      #     config: "config.xml",
      #     packages: "**",
      #     output: "output/",
      #     verbose: true
      #   )
      #   command.run
      class ProcessCommand
        # @return [Hash] Command options
        attr_reader :options

        # Create a new ProcessCommand.
        #
        # @param options [Hash] Command options from Thor CLI
        # @option options [String] :lur Path to LUR package file
        # @option options [String] :lxr Path to LXR package file
        # @option options [String] :config Path to ShapeChange config XML
        # @option options [String] :packages Package filter pattern
        # @option options [String] :output Output directory path
        # @option options [String] :type_overrides Path to type overrides YAML
        # @option options [Boolean] :generate_mappings Generate YAML mappings
        # @option options [Boolean] :generate_spa Generate SPA website
        # @option options [Boolean] :validate Generate validation reports
        # @option options [Boolean] :verbose Enable verbose output
        def initialize(options)
          @options = options
        end

        # Execute the process command.
        #
        # @return [void]
        def run
          display_header

          # Create progress callback if verbose
          progress_callback = if options[:verbose]
                                ->(stage, msg) { display_progress(stage, msg) }
                              end

          # Create workflow
          workflow = Application::ProcessingWorkflow.new(
            progress_callback: progress_callback
          )

          # Execute workflow
          result = workflow.execute(
            lur_path: options[:lur],
            lxr_path: options[:lxr],
            config_path: options[:config],
            package_filter: options[:packages] || "**",
            output_path: options[:output] || "_site",
            type_overrides_path: options[:type_overrides],
            generate_mappings: options.fetch(:generate_mappings, true),
            generate_spa: options.fetch(:generate_spa, true),
            spa_data_mode: (options[:spa_data_mode] || "embedded").to_sym,
            validate: options.fetch(:validate, true),
            verbose: options.fetch(:verbose, false)
          )

          # Display summary
          display_summary(result)

          # Exit with appropriate code
          exit(result.success? ? 0 : 1)
        rescue StandardError => e
          display_error(e)
          exit(1)
        end

        private

        # Display command header.
        #
        # @return [void]
        def display_header
          return unless options[:verbose]

          puts "\n#{'=' * 70}"
          puts "  LUTAML-KLIN: UML-to-XSD Mapping Processor"
          puts "=" * 70
          puts ""
        end

        # Display progress message for a stage.
        #
        # @param stage [Symbol] Processing stage
        # @param message [String] Progress message
        # @return [void]
        def display_progress(stage, message)
          stage_icons = {
            loading: "📦",
            config: "⚙️",
            filtering: "🔍",
            mapping: "🗺️",
            saving: "💾",
            validation: "✅",
            spa: "🌐",
            complete: "✨",
            error: "❌"
          }

          icon = stage_icons[stage] || "▶️"
          timestamp = Time.now.strftime("%H:%M:%S")

          puts "[#{timestamp}] #{icon}  #{message}"
        end

        # Display final summary of processing results.
        #
        # @param result [Domain::ProcessingResult] Processing result
        # @return [void]
        def display_summary(result)
          puts "\n#{'=' * 70}"
          puts "  PROCESSING SUMMARY"
          puts "=" * 70
          puts ""

          # Status
          status_icon = result.success? ? "✅" : "⚠️"
          status_text = result.success? ? "SUCCESS" : "COMPLETED WITH ISSUES"
          puts "#{status_icon}  Status: #{status_text}"
          puts ""

          # Statistics
          puts "📊  Statistics:"
          puts "   • Packages processed: #{result.total_packages}"
          puts "   • Classes: #{result.resolved_classes}/" \
               "#{result.total_classes} resolved " \
               "(#{result.resolution_rate.round(1)}%)"
          puts "   • Attributes: #{result.resolved_attributes}/" \
               "#{result.total_attributes} resolved"

          if result.statistics[:processing_time]
            puts "   • Processing time: " \
                 "#{result.statistics[:processing_time]}s"
          end
          puts ""

          # Validation
          if result.validation_enabled?
            validation_icon = result.validation_passed? ? "✅" : "❌"
            validation_status = result.validation_passed? ? "PASSED" : "FAILED"
            puts "#{validation_icon}  Validation: #{validation_status}"
            puts ""
          end

          # Output paths
          if result.output_paths.any?
            puts "📁  Output:"

            if result.mapping_paths.any?
              puts "   • Mappings:"
              result.mapping_paths.each do |path|
                puts "     - #{path}"
              end
            end

            if result.validation_paths.any?
              puts "   • Validation reports:"
              result.validation_paths.each do |path|
                puts "     - #{path}"
              end
            end

            if result.spa_path
              puts "   • SPA website: #{result.spa_path}"
              puts "     Open: #{File.join(result.spa_path, 'index.html')}"
            end

            puts ""
          end

          puts "=" * 70
          puts ""
        end

        # Display error message.
        #
        # @param error [Exception] The error that occurred
        # @return [void]
        def display_error(error)
          puts "\n#{'=' * 70}"
          puts "  ❌  ERROR"
          puts "=" * 70
          puts ""
          puts "#{error.class}: #{error.message}"

          if options[:verbose] && error.backtrace
            puts ""
            puts "Backtrace:"
            error.backtrace.first(10).each do |line|
              puts "  #{line}"
            end
          end

          puts ""
          puts "=" * 70
          puts ""
        end
      end
    end
  end
end
