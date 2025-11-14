# frozen_string_literal: true

require_relative "../lxr/errors"
require_relative "../lxr/input_strategy"
require_relative "../lxr/config_builder"
require_relative "../lxr/package_builder"

module Lutaml
  module Klin
    module Commands
      # Command to create LXR packages from ShapeChange configs or XSD files
      # Implements clean architecture with single responsibility principle
      class CreateLxrCommand
        attr_reader :options, :input_strategy, :config_builder, :package_builder

        # @param options [Hash] Command options
        # @option options [String] :output Output path for LXR package
        # @option options [String] :shapechange Path to ShapeChange config (ShapeChange strategy)
        # @option options [String] :xsd_dir Directory with XSD files (Manual strategy)
        # @option options [String] :namespaces Path to namespace config YAML (Manual strategy)
        # @option options [String] :xsd_mode XSD bundling mode (default: include_all)
        # @option options [String] :resolution_mode Resolution mode (default: resolved)
        # @option options [String] :format Serialization format (default: marshal)
        # @option options [String] :name Package name
        # @option options [String] :version Package version
        # @option options [String] :description Package description
        # @option options [Boolean] :validate Validate package after creation
        # @option options [Boolean] :verbose Enable verbose output
        def initialize(options = {})
          @options = normalize_options(options)
          @input_strategy = create_input_strategy
          @config_builder = create_config_builder
          @package_builder = create_package_builder
        end

        # Execute the create-lxr command
        # @return [void]
        def run
          log_header
          validate_options!

          # Step 1: Extract schema information
          log_step("Extracting schema information...")
          schema_info = extract_schema_info

          # Step 2: Build configuration
          log_step("Building LXR package configuration...")
          config = build_configuration(schema_info)

          # Step 3: Create LXR package
          log_step("Creating LXR package...")
          result = create_package(config)

          # Step 4: Report results
          report_results(result)

          # Exit with appropriate code
          exit(result[:success] ? 0 : 1)
        rescue Lxr::LxrCreationError => e
          error("LXR creation failed: #{e.message}")
          exit(1)
        rescue StandardError => e
          error("Unexpected error: #{e.message}")
          error(e.backtrace.join("\n")) if verbose?
          exit(1)
        end

        private

        # Normalize options to use symbol keys
        # @param options [Hash] Raw options
        # @return [Hash] Normalized options with symbol keys
        def normalize_options(options)
          return {} unless options

          if options.respond_to?(:to_h)
            options.to_h.transform_keys(&:to_sym)
          else
            options
          end
        end

        # Create appropriate input strategy based on options
        # @return [Lxr::InputStrategy] Input strategy instance
        def create_input_strategy
          if options[:shapechange]
            Lxr::ShapeChangeInputStrategy.new(
              config_path: options[:shapechange]
            )
          elsif options[:xsd_dir] || options[:namespaces]
            Lxr::ManualInputStrategy.new(
              xsd_dir: options[:xsd_dir],
              namespaces_config: options[:namespaces]
            )
          else
            raise Lxr::InvalidInputError,
                  "Either --shapechange or --xsd-dir with --namespaces must be provided"
          end
        end

        # Create configuration builder with specified options
        # @return [Lxr::ConfigBuilder] Config builder instance
        def create_config_builder
          Lxr::ConfigBuilder.new(
            xsd_mode: options[:xsd_mode] || "include_all",
            resolution_mode: options[:resolution_mode] || "resolved",
            serialization_format: options[:format] || "marshal"
          )
        end

        # Create package builder
        # @return [Lxr::PackageBuilder] Package builder instance
        def create_package_builder
          Lxr::PackageBuilder.new(verbose: verbose?)
        end

        # Validate command options
        # @raise [Lxr::InvalidInputError] If options are invalid
        def validate_options!
          unless options[:output]
            raise Lxr::InvalidInputError, "Output path is required"
          end

          # Validate input strategy
          input_strategy.validate!
        end

        # Extract schema information using input strategy
        # @return [Hash] Schema information
        def extract_schema_info
          schema_info = input_strategy.extract_schema_info

          log("Found #{schema_info[:xsd_files].size} XSD files")
          log("Found #{schema_info[:namespace_mappings].size} namespace mappings")

          schema_info
        end

        # Build LXR package configuration
        # @param schema_info [Hash] Schema information
        # @return [Hash] Package configuration
        def build_configuration(schema_info)
          metadata = {
            name: options[:name],
            version: options[:version],
            description: options[:description]
          }.compact

          config = config_builder.build(schema_info, metadata)

          if verbose?
            log("Configuration:")
            log(config.to_yaml)
          end

          config
        end

        # Create LXR package using lutaml-xsd
        # @param config [Hash] Package configuration
        # @return [Hash] Build result
        def create_package(config)
          build_options = {
            name: options[:name],
            version: options[:version],
            description: options[:description],
            validate: options[:validate]
          }.compact

          result = package_builder.build(
            config,
            options[:output],
            build_options
          )

          unless result[:success]
            raise Lxr::PackageBuildError,
                  "Failed to build package: #{result[:messages].join(', ')}"
          end

          result
        end

        # Report command results
        # @param result [Hash] Build result
        def report_results(result)
          puts "\n" + "=" * 70
          puts "  LXR PACKAGE CREATION SUMMARY"
          puts "=" * 70
          puts ""

          if result[:success]
            puts "✅  Status: SUCCESS"
            puts ""
            puts "📦  Package created: #{result[:output_path]}"

            if result[:validation]
              validation_icon = result[:validation][:valid] ? "✅" : "❌"
              validation_status = result[:validation][:valid] ? "PASSED" : "FAILED"
              puts "#{validation_icon}  Validation: #{validation_status}"

              if result[:validation][:messages]
                result[:validation][:messages].each do |msg|
                  puts "   • #{msg}"
                end
              end
            end
          else
            puts "❌  Status: FAILED"
            puts ""
            puts "Error messages:"
            result[:messages].each do |msg|
              puts "   • #{msg}"
            end
          end

          puts ""
          puts "=" * 70
          puts ""
        end

        # Display command header
        def log_header
          return unless verbose?

          puts "\n" + "=" * 70
          puts "  LUTAML-KLIN: LXR Package Creator"
          puts "=" * 70
          puts ""
        end

        # Log a processing step
        # @param message [String] Step message
        def log_step(message)
          return unless verbose?

          puts "▶️  #{message}"
        end

        # Log a message
        # @param message [String] Message to log
        def log(message)
          puts message if verbose?
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