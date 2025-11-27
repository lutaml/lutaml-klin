# frozen_string_literal: true

require "yaml"
require_relative "errors"

module Lutaml
  module Klin
    module Lxr
      # ConfigBuilder transforms extracted schema information into
      # lutaml-xsd compatible package configuration format
      class ConfigBuilder
        # Default configuration values
        DEFAULT_XSD_MODE = "include_all"
        DEFAULT_RESOLUTION_MODE = "resolved"
        DEFAULT_SERIALIZATION_FORMAT = "marshal"

        attr_reader :xsd_mode, :resolution_mode, :serialization_format

        # @param xsd_mode [String] XSD bundling mode (include_all, allow_external)
        # @param resolution_mode [String] Resolution mode (resolved, bare)
        # @param serialization_format [String] Serialization format (marshal, json, yaml, parse)
        def initialize(xsd_mode: DEFAULT_XSD_MODE,
                       resolution_mode: DEFAULT_RESOLUTION_MODE,
                       serialization_format: DEFAULT_SERIALIZATION_FORMAT)
          @xsd_mode = xsd_mode
          @resolution_mode = resolution_mode
          @serialization_format = serialization_format
          validate_options!
        end

        # Build lutaml-xsd package configuration from schema information
        # @param schema_info [Hash] Schema info with :xsd_files, :namespace_mappings, :schema_location_mappings
        # @param metadata [Hash] Optional package metadata (:name, :version, :description)
        # @return [Hash] Configuration hash compatible with lutaml-xsd
        def build(schema_info, metadata = {})
          validate_schema_info!(schema_info)

          config = {
            "package" => build_package_metadata(metadata),
            "schemas" => build_schemas_section(schema_info),
            "options" => build_options_section
          }

          # Add namespace mappings if present
          if schema_info[:namespace_mappings]&.any?
            config["namespaces"] = build_namespaces_section(
              schema_info[:namespace_mappings]
            )
          end

          # Add schema location mappings if present
          if schema_info[:schema_location_mappings]&.any?
            config["schema_locations"] = build_schema_locations_section(
              schema_info[:schema_location_mappings]
            )
          end

          config
        end

        # Build configuration and write to YAML file
        # @param schema_info [Hash] Schema information
        # @param output_path [String] Path to write YAML configuration
        # @param metadata [Hash] Optional package metadata
        # @return [String] Path to written configuration file
        def build_and_write(schema_info, output_path, metadata = {})
          config = build(schema_info, metadata)
          write_config(config, output_path)
          output_path
        end

        private

        # Validate configuration options
        # @raise [ConfigurationError] If options are invalid
        def validate_options!
          valid_xsd_modes = %w[include_all allow_external]
          unless valid_xsd_modes.include?(xsd_mode)
            raise ConfigurationError,
                  "Invalid xsd_mode: #{xsd_mode}. " \
                  "Must be one of: #{valid_xsd_modes.join(', ')}"
          end

          valid_resolution_modes = %w[resolved bare]
          unless valid_resolution_modes.include?(resolution_mode)
            raise ConfigurationError,
                  "Invalid resolution_mode: #{resolution_mode}. " \
                  "Must be one of: #{valid_resolution_modes.join(', ')}"
          end

          valid_formats = %w[marshal json yaml parse]
          return if valid_formats.include?(serialization_format)

          raise ConfigurationError,
                "Invalid serialization_format: #{serialization_format}. " \
                "Must be one of: #{valid_formats.join(', ')}"
        end

        # Validate schema information structure
        # @param schema_info [Hash] Schema information to validate
        # @raise [InvalidInputError] If schema info is invalid
        def validate_schema_info!(schema_info)
          unless schema_info.is_a?(Hash)
            raise InvalidInputError, "Schema info must be a Hash"
          end

          unless schema_info[:xsd_files]
            raise InvalidInputError,
                  "Schema info must contain :xsd_files"
          end

          unless schema_info[:xsd_files].is_a?(Array)
            raise InvalidInputError,
                  "Schema info :xsd_files must be an Array"
          end

          return unless schema_info[:xsd_files].empty?

          raise InvalidInputError,
                "Schema info :xsd_files cannot be empty"
        end

        # Build package metadata section
        # @param metadata [Hash] Package metadata
        # @return [Hash] Package metadata configuration
        def build_package_metadata(metadata)
          {
            "name" => metadata[:name] || "lxr_package",
            "version" => metadata[:version] || "1.0.0",
            "description" => metadata[:description] || "LXR package created by lutaml-klin"
          }
        end

        # Build schemas section with XSD file list
        # @param schema_info [Hash] Schema information
        # @return [Hash] Schemas configuration
        def build_schemas_section(schema_info)
          {
            "files" => schema_info[:xsd_files].map do |file|
              normalize_path(file)
            end
          }
        end

        # Build options section
        # @return [Hash] Options configuration
        def build_options_section
          {
            "xsd_mode" => xsd_mode,
            "resolution_mode" => resolution_mode,
            "serialization_format" => serialization_format
          }
        end

        # Build namespaces section
        # @param mappings [Array<Hash>] Namespace mappings
        # @return [Array<Hash>] Namespace configuration
        def build_namespaces_section(mappings)
          mappings.map do |mapping|
            {
              "prefix" => mapping[:prefix].to_s,
              "uri" => mapping[:uri].to_s
            }
          end
        end

        # Build schema locations section
        # @param mappings [Array<Hash>] Schema location mappings
        # @return [Array<Hash>] Schema location configuration
        def build_schema_locations_section(mappings)
          mappings.map do |mapping|
            {
              "from" => mapping[:from].to_s,
              "to" => mapping[:to].to_s
            }
          end
        end

        # Normalize file path for consistent handling
        # @param path [String] File path
        # @return [String] Normalized path
        def normalize_path(path)
          # Convert to relative path if absolute
          if path.start_with?("/") || path.match?(/^[A-Za-z]:/)
            File.basename(path)
          else
            path
          end
        end

        # Write configuration to YAML file
        # @param config [Hash] Configuration to write
        # @param output_path [String] Output file path
        def write_config(config, output_path)
          # Ensure output directory exists
          output_dir = File.dirname(output_path)
          FileUtils.mkdir_p(output_dir)

          File.write(output_path, config.to_yaml)
        end
      end
    end
  end
end
