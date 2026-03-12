# frozen_string_literal: true

require_relative "../application/spa_workflow"

module Lutaml
  module Klin
    module Commands
      # Command to generate SPA from existing mapping file
      # Implements Process 3 in the standard workflow
      class SpaCommand
        attr_reader :options

        # @param options [Hash] Command options
        # @option options [Array<String>, String] :mapping Path(s) to mapping YAML file(s)
        # @option options [String] :output Output directory path
        # @option options [String] :template_type Template type (alpine/vanilla)
        # @option options [String] :data_mode Data mode (embedded/linked)
        # @option options [String] :title Custom SPA title (optional)
        # @option options [Boolean] :verbose Enable verbose output
        def initialize(options = {})
          @options = options
        end

        # Execute the spa command
        # @return [void]
        def run
          validate_options!

          log_header
          log_config

          workflow = Application::SpaWorkflow.new

          # Convert single mapping to array for uniform handling
          mapping_files = Array(options[:mapping])

          output_path = workflow.generate_spa_from_files(
            mapping_file_paths: mapping_files,
            output_path: options[:output],
            template_type: options[:template_type]&.to_sym || :alpine,
            data_mode: options[:data_mode]&.to_sym || :embedded,
            title: options[:title]
          )

          log_success(output_path)
        rescue ArgumentError => e
          error("Invalid input: #{e.message}")
          exit(1)
        rescue StandardError => e
          error("SPA generation failed: #{e.message}")
          error(e.backtrace.join("\n")) if verbose?
          exit(1)
        end

        private

        # Validate command options
        # @raise [ArgumentError] if options are invalid
        def validate_options!
          unless options[:mapping]
            raise ArgumentError, "Mapping file path is required (--mapping)"
          end

          unless options[:output]
            raise ArgumentError, "Output directory is required (--output)"
          end

          # Validate all mapping files exist
          mapping_files = Array(options[:mapping])
          mapping_files.each do |file|
            unless File.exist?(file)
              raise ArgumentError, "Mapping file not found: #{file}"
            end
          end
        end

        # Display command header
        def log_header
          return unless verbose?

          puts "\n#{'=' * 70}"
          puts "  LUTAML-KLIN: Generate SPA from Mapping"
          puts "=" * 70
          puts ""
        end

        # Display configuration
        def log_config
          mapping_files = Array(options[:mapping])
          
          if mapping_files.size == 1
            puts "Generating SPA from mapping file..."
            puts "  Mapping: #{mapping_files.first}"
          else
            puts "Generating multi-schema SPA from #{mapping_files.size} mapping files..."
            mapping_files.each_with_index do |file, idx|
              puts "  Mapping #{idx + 1}: #{file}"
            end
          end
          
          puts "  Output: #{options[:output]}"
          puts "  Template: #{options[:template_type] || 'alpine'}"
          puts "  Data Mode: #{options[:data_mode] || 'embedded'}"
          puts ""
        end

        # Display success message
        # @param output_path [String] Generated SPA path
        def log_success(output_path)
          puts ""
          puts "=" * 70
          puts "✅ SPA Generated Successfully!"
          puts "=" * 70
          puts ""
          puts "Output: #{output_path}"

          index_path = File.expand_path(File.join(output_path, "index.html"))
          puts ""
          puts "Open in browser:"
          puts "  file://#{index_path}"
          puts ""
          puts "Or use:"
          puts "  open #{index_path}"
          puts ""
        end

        # Display error message
        # @param message [String] Error message
        def error(message)
          warn "ERROR: #{message}"
        end

        # Check if verbose mode is enabled
        # @return [Boolean]
        def verbose?
          options[:verbose] == true
        end
      end
    end
  end
end