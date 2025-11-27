# frozen_string_literal: true

require_relative "../shapechange/config_parser"
require_relative "../xmi_navigator"
require_relative "../xsd_analyzer"
require_relative "../mapping_generator"

module Lutaml
  module Klin
    module Commands
      # Command to generate UML-XSD mapping files
      class GenerateCommand
        attr_reader :config_path, :xmi_path, :xsd_dir, :output_path,
                    :package, :encoding_rule, :type_mapping_path, :verbose

        def initialize(config_path:, xmi_path:, xsd_dir:, output_path:,
                       package:, encoding_rule: nil, type_mapping_path: nil,
                       verbose: false)
          @config_path = config_path
          @xmi_path = xmi_path
          @xsd_dir = xsd_dir
          @output_path = output_path
          @package = package
          @encoding_rule = encoding_rule
          @type_mapping_path = type_mapping_path
          @verbose = verbose
        end

        def run
          log "Starting mapping generation..."
          validate_inputs
          log "Inputs validated successfully"

          # Parse ShapeChange configuration
          log "Parsing ShapeChange configuration: #{config_path}"
          config = parse_config
          log "Configuration parsed successfully"

          # Initialize XMI navigator
          log "Loading XMI file: #{xmi_path}"
          xmi_navigator = XmiNavigator.new(xmi_path)
          xmi_navigator.parse
          log "XMI loaded successfully"

          # Initialize XSD analyzers
          log "Analyzing XSD files in: #{xsd_dir}"
          xsd_analyzers = load_xsd_analyzers
          log "Found #{xsd_analyzers.length} XSD files"

          # Load type overrides if provided
          type_overrides = load_type_overrides
          log "Loaded #{type_overrides.size} type overrides" if type_overrides

          # Generate mapping
          log "Generating mapping for package: #{package}"
          generator = MappingGenerator.new(
            config: config,
            xmi_navigator: xmi_navigator,
            xsd_analyzers: xsd_analyzers,
            type_overrides: type_overrides
          )

          mapping = generator.generate_mapping(package)
          log "Mapping generated successfully"

          # Write output
          log "Writing output to: #{output_path}"
          write_output(mapping)
          log "Output written successfully"

          puts "✓ Mapping generated: #{output_path}"
        rescue StandardError => e
          error "Failed to generate mapping: #{e.message}"
          error e.backtrace.join("\n") if verbose
          exit 1
        end

        private

        def validate_inputs
          unless File.exist?(config_path)
            error "Configuration file not found: #{config_path}"
            exit 1
          end

          unless File.exist?(xmi_path)
            error "XMI file not found: #{xmi_path}"
            exit 1
          end

          unless Dir.exist?(xsd_dir)
            error "XSD directory not found: #{xsd_dir}"
            exit 1
          end

          output_dir = File.dirname(output_path)
          return if Dir.exist?(output_dir)

          error "Output directory not found: #{output_dir}"
          exit 1
        end

        def parse_config
          parser = Shapechange::ConfigParser.new
          config = parser.parse_file(config_path)

          # If encoding rule specified, validate it exists
          if encoding_rule
            rule = config.encoding_rules&.find do |r|
              r.name == encoding_rule
            end
            unless rule
              error "Encoding rule not found: #{encoding_rule}"
              exit 1
            end
          end

          config
        end

        def load_xsd_analyzers
          xsd_files = Dir.glob(File.join(xsd_dir, "**", "*.xsd"))

          if xsd_files.empty?
            error "No XSD files found in: #{xsd_dir}"
            exit 1
          end

          analyzers = {}
          xsd_files.each do |xsd_file|
            log "  - #{File.basename(xsd_file)}" if verbose
            analyzer = XsdAnalyzer.new
            analyzer.parse_file(xsd_file)

            # Index by namespace
            namespace = analyzer.target_namespace
            analyzers[namespace] = analyzer if namespace
          end

          analyzers
        end

        def load_type_overrides
          return nil unless type_mapping_path

          unless File.exist?(type_mapping_path)
            error "Type mapping file not found: #{type_mapping_path}"
            exit 1
          end

          log "Loading type overrides from: #{type_mapping_path}"

          content = YAML.load_file(type_mapping_path)
          unless content.is_a?(Hash) && content.key?("type_overrides")
            error "Invalid type mapping file format. Expected 'type_overrides' key."
            exit 1
          end

          content["type_overrides"]
        rescue StandardError => e
          error "Failed to load type mapping file: #{e.message}"
          exit 1
        end

        def write_output(mapping)
          yaml_content = mapping.to_yaml

          File.write(output_path, yaml_content)
        end

        def log(message)
          puts message if verbose
        end

        def error(message)
          warn "ERROR: #{message}"
        end
      end
    end
  end
end
