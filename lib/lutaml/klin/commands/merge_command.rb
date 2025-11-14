# frozen_string_literal: true

require "yaml"
require_relative "../models/mapping/schema_mapping"
require_relative "../models/mapping/package_mapping"
require_relative "../models/mapping/class_mapping"
require_relative "../models/mapping/attribute_mapping"

module Lutaml
  module Klin
    module Commands
      # Command to merge multiple mapping YAML files
      class MergeCommand
        attr_reader :input_files, :output_path, :verbose

        def initialize(input_files:, output_path:, verbose: false)
          @input_files = input_files
          @output_path = output_path
          @verbose = verbose
        end

        def run
          log "Starting merge operation..."
          validate_inputs
          log "Inputs validated successfully"

          # Load all mapping files
          log "Loading #{input_files.length} mapping files..."
          mappings = load_mappings
          log "All mappings loaded successfully"

          # Merge mappings
          log "Merging mappings..."
          merged = merge_mappings(mappings)
          log "Mappings merged successfully"

          # Write output
          log "Writing merged output to: #{output_path}"
          write_output(merged)
          log "Output written successfully"

          puts "✓ Merged #{input_files.length} files into: #{output_path}"
        rescue StandardError => e
          error "Failed to merge mappings: #{e.message}"
          error e.backtrace.join("\n") if verbose
          exit 1
        end

        private

        def validate_inputs
          input_files.each do |file|
            unless File.exist?(file)
              error "Input file not found: #{file}"
              exit 1
            end
          end

          output_dir = File.dirname(output_path)
          unless Dir.exist?(output_dir)
            error "Output directory not found: #{output_dir}"
            exit 1
          end
        end

        def load_mappings
          input_files.map do |file|
            log "  - Loading #{file}" if verbose
            yaml_content = File.read(file)
            Models::Mapping::SchemaMapping.from_yaml(yaml_content)
          end
        end

        def merge_mappings(mappings)
          return mappings.first if mappings.length == 1

          # Start with first mapping as base
          merged = mappings.first.dup

          # Merge remaining mappings
          mappings[1..].each do |mapping|
            merge_into(merged, mapping)
          end

          merged
        end

        def merge_into(base, other)
          # Merge package mappings
          other.package_mappings.each do |pkg_mapping|
            existing = base.package_mappings.find do |p|
              p.uml_name == pkg_mapping.uml_name
            end

            if existing
              # Merge class mappings within same package
              merge_package_mappings(existing, pkg_mapping)
            else
              # Add new package mapping
              base.package_mappings << pkg_mapping.dup
            end
          end
        end

        def merge_package_mappings(base_pkg, other_pkg)
          other_pkg.class_mappings.each do |class_mapping|
            existing = base_pkg.class_mappings.find do |c|
              c.uml_name == class_mapping.uml_name
            end

            if existing
              log "  - Skipping duplicate class: #{class_mapping.uml_name}" if verbose
            else
              base_pkg.class_mappings << class_mapping.dup
            end
          end
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
