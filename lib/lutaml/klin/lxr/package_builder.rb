# frozen_string_literal: true

require "English"
require "fileutils"
require "tempfile"
require_relative "errors"

module Lutaml
  module Klin
    module Lxr
      # PackageBuilder interfaces with lutaml-xsd CLI to build LXR packages
      # Responsible for executing the external lutaml-xsd command
      class PackageBuilder
        attr_reader :verbose

        # @param verbose [Boolean] Enable verbose output
        def initialize(verbose: false)
          @verbose = verbose
        end

        # Build LXR package using lutaml-xsd CLI
        # @param config_hash [Hash] Package configuration
        # @param output_path [String] Path for output LXR package
        # @param options [Hash] Additional build options
        # @option options [String] :name Package name
        # @option options [String] :version Package version
        # @option options [String] :description Package description
        # @option options [Boolean] :validate Validate package after creation
        # @return [Hash] Build result with :success, :output_path, :messages
        def build(config_hash, output_path, options = {})
          validate_lutaml_xsd_available!

          # Create temporary config file
          config_file = create_temp_config(config_hash)

          begin
            # Build package using lutaml-xsd
            result = execute_build_command(config_file, output_path, options)

            # Validate if requested
            if options[:validate] && result[:success]
              validation_result = validate_package(output_path)
              result[:validation] = validation_result
              result[:success] = validation_result[:valid]
            end

            result
          ensure
            # Clean up temporary config file
            FileUtils.rm_f(config_file)
          end
        end

        # Validate an existing LXR package
        # @param package_path [String] Path to LXR package file
        # @return [Hash] Validation result with :valid, :messages
        def validate_package(package_path)
          unless File.exist?(package_path)
            return {
              valid: false,
              messages: ["Package file not found: #{package_path}"]
            }
          end

          # For now, basic validation - check file exists and has content
          # In future, could use lutaml-xsd validate command if available
          file_size = File.size(package_path)
          if file_size.zero?
            {
              valid: false,
              messages: ["Package file is empty"]
            }
          else
            {
              valid: true,
              messages: ["Package file created successfully (#{file_size} bytes)"]
            }
          end
        end

        private

        # Check if lutaml-xsd is available in PATH
        # @raise [PackageBuildError] If lutaml-xsd is not available
        def validate_lutaml_xsd_available!
          result = system("which lutaml-xsd > /dev/null 2>&1")
          return if result

          raise PackageBuildError,
                "lutaml-xsd command not found. " \
                "Please install lutaml-xsd gem: gem install lutaml-xsd"
        end

        # Create temporary YAML configuration file
        # @param config_hash [Hash] Configuration data
        # @return [String] Path to temporary config file
        def create_temp_config(config_hash)
          temp_file = Tempfile.new(["lxr_config", ".yaml"])
          temp_file.write(config_hash.to_yaml)
          temp_file.close
          temp_file.path
        end

        # Execute lutaml-xsd build command
        # @param config_file [String] Path to config file
        # @param output_path [String] Output package path
        # @param options [Hash] Build options
        # @return [Hash] Build result
        def execute_build_command(config_file, output_path, options)
          cmd = build_command_array(config_file, output_path, options)

          log("Executing: #{cmd.join(' ')}")

          # Capture output
          output = []

          # Execute command
          IO.popen(cmd, err: %i[child out]) do |io|
            io.each_line do |line|
              line = line.chomp
              output << line
              log(line)
            end
          end

          success = $CHILD_STATUS.success?

          {
            success: success,
            output_path: output_path,
            messages: success ? output : ["Build failed: #{output.join("\n")}"],
            command: cmd.join(" ")
          }
        rescue StandardError => e
          {
            success: false,
            output_path: output_path,
            messages: ["Failed to execute lutaml-xsd: #{e.message}"],
            command: cmd.join(" "),
            error: e
          }
        end

        # Build command array for lutaml-xsd
        # @param config_file [String] Configuration file path
        # @param output_path [String] Output path
        # @param options [Hash] Additional options
        # @return [Array<String>] Command arguments
        def build_command_array(config_file, output_path, options)
          cmd = ["lutaml-xsd", "package", "build", config_file]

          # Add output path
          cmd += ["--output", output_path]

          # Add options from config (these are in the YAML, but can be overridden)
          cmd += ["--name", options[:name]] if options[:name]
          cmd += ["--version", options[:version]] if options[:version]
          if options[:description]
            cmd += ["--description",
                    options[:description]]
          end

          # Add verbose flag if needed
          cmd << "--verbose" if verbose

          cmd
        end

        # Log message if verbose mode enabled
        # @param message [String] Message to log
        def log(message)
          puts message if verbose
        end
      end
    end
  end
end
