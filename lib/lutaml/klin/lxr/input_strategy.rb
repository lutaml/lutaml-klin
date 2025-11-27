# frozen_string_literal: true

require "yaml"
require_relative "errors"
require_relative "../shapechange/lxr_extractor"

module Lutaml
  module Klin
    module Lxr
      # Base strategy for extracting schema information from different input sources
      # Implements the Strategy pattern for flexible input handling
      class InputStrategy
        # Extract schema information from the input source
        # @return [Hash] Schema information with :xsd_files, :namespace_mappings, :schema_location_mappings
        # @raise [NotImplementedError] Must be implemented by subclasses
        def extract_schema_info
          raise NotImplementedError,
                "#{self.class} must implement #extract_schema_info"
        end

        # Validate that required input parameters are present
        # @raise [InvalidInputError] If required parameters are missing
        def validate!
          raise NotImplementedError, "#{self.class} must implement #validate!"
        end
      end

      # Strategy for extracting schema info from ShapeChange configuration
      class ShapeChangeInputStrategy < InputStrategy
        attr_reader :config_path, :extractor

        # @param config_path [String] Path to ShapeChange configuration file
        # @param extractor [Shapechange::LxrExtractor] Optional extractor instance
        def initialize(config_path:, extractor: nil)
          @config_path = config_path
          @extractor = extractor || Shapechange::LxrExtractor.new
        end

        # Validate ShapeChange configuration file exists
        # @raise [InvalidInputError] If configuration file is missing
        def validate!
          unless config_path
            raise InvalidInputError,
                  "ShapeChange configuration path is required"
          end

          return if File.exist?(config_path)

          raise InvalidInputError,
                "ShapeChange configuration file not found: #{config_path}"
        end

        # Extract schema information from ShapeChange configuration
        # @return [Hash] Schema information
        def extract_schema_info
          validate!
          extractor.extract_schema_info(config_path)
        end
      end

      # Strategy for manual input using XSD files and namespace configuration
      class ManualInputStrategy < InputStrategy
        attr_reader :xsd_dir, :namespaces_config, :xsd_files

        # @param xsd_dir [String] Directory containing XSD files
        # @param namespaces_config [String, Hash] Path to YAML config or Hash of namespaces
        # @param xsd_files [Array<String>] Optional explicit list of XSD files
        def initialize(xsd_dir: nil, namespaces_config: nil, xsd_files: nil)
          @xsd_dir = xsd_dir
          @namespaces_config = namespaces_config
          @xsd_files = xsd_files
        end

        # Validate required manual input parameters
        # @raise [InvalidInputError] If required parameters are missing
        def validate!
          if (xsd_files.nil? || xsd_files.empty?) && !(xsd_dir && Dir.exist?(xsd_dir))
            raise InvalidInputError,
                  "Either xsd_dir or xsd_files must be provided"
          end

          unless namespaces_config
            raise InvalidInputError,
                  "Namespace configuration is required for manual input"
          end

          # Validate namespace config if it's a file path
          if namespaces_config.is_a?(String) && !File.exist?(namespaces_config)
            raise InvalidInputError,
                  "Namespace configuration file not found: #{namespaces_config}"
          end
        end

        # Extract schema information from manual inputs
        # @return [Hash] Schema information
        def extract_schema_info
          validate!

          {
            xsd_files: collect_xsd_files,
            namespace_mappings: load_namespace_mappings,
            schema_location_mappings: []
          }
        end

        private

        # Collect XSD files from directory or explicit list
        # @return [Array<String>] List of XSD file paths
        def collect_xsd_files
          if xsd_files && !xsd_files.empty?
            xsd_files
          elsif xsd_dir
            Dir.glob(File.join(xsd_dir, "**", "*.xsd"))
          else
            []
          end
        end

        # Load namespace mappings from configuration
        # @return [Array<Hash>] Array of { prefix: String, uri: String } mappings
        def load_namespace_mappings
          config = if namespaces_config.is_a?(String)
                     YAML.load_file(namespaces_config)
                   elsif namespaces_config.is_a?(Hash)
                     namespaces_config
                   else
                     raise InvalidInputError,
                           "Namespace configuration must be a file path or Hash"
                   end

          mappings = config["namespace_mappings"] || config[:namespace_mappings]
          unless mappings.is_a?(Array)
            raise InvalidInputError,
                  "Namespace configuration must contain 'namespace_mappings' array"
          end

          # Validate each mapping has required fields
          mappings.each do |mapping|
            unless mapping["prefix"] || mapping[:prefix]
              raise InvalidInputError,
                    "Each namespace mapping must have a 'prefix' field"
            end
            unless mapping["uri"] || mapping[:uri]
              raise InvalidInputError,
                    "Each namespace mapping must have a 'uri' field"
            end
          end

          # Normalize to symbol keys
          mappings.map do |mapping|
            {
              prefix: (mapping["prefix"] || mapping[:prefix]).to_s,
              uri: (mapping["uri"] || mapping[:uri]).to_s
            }
          end
        end
      end
    end
  end
end
