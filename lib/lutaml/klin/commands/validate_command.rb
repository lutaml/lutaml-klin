# frozen_string_literal: true

require "yaml"
require_relative "../models/mapping/schema_mapping"
require_relative "../models/mapping/package_mapping"
require_relative "../models/mapping/class_mapping"
require_relative "../models/mapping/attribute_mapping"

module Lutaml
  module Klin
    module Commands
      # Command to validate mapping YAML files
      class ValidateCommand
        attr_reader :mapping_file, :schema, :verbose

        def initialize(mapping_file:, schema: nil, verbose: false)
          @mapping_file = mapping_file
          @schema = schema
          @verbose = verbose
          @errors = []
          @warnings = []
        end

        def run
          log "Starting validation..."
          validate_file_exists
          log "File exists: #{mapping_file}"

          # Load and parse YAML
          log "Loading YAML file..."
          mapping = load_mapping
          log "YAML loaded successfully"

          # Validate structure
          log "Validating structure..."
          validate_structure(mapping)

          # Validate content
          log "Validating content..."
          validate_content(mapping)

          # Report results
          report_results

          if @errors.empty?
            puts "✓ Validation passed: #{mapping_file}"
            exit 0
          else
            puts "✗ Validation failed with #{@errors.length} error(s)"
            exit 1
          end
        rescue StandardError => e
          error "Validation failed: #{e.message}"
          error e.backtrace.join("\n") if verbose
          exit 1
        end

        private

        def validate_file_exists
          return if File.exist?(mapping_file)

          error "Mapping file not found: #{mapping_file}"
          exit 1
        end

        def load_mapping
          yaml_content = File.read(mapping_file)

          # Try to parse as SchemaMapping
          begin
            Models::Mapping::SchemaMapping.from_yaml(yaml_content)
          rescue StandardError => e
            @errors << "Failed to parse YAML: #{e.message}"
            nil
          end
        end

        def validate_structure(mapping)
          return unless mapping

          # Check for package mappings
          if mapping.package_mappings.nil? || mapping.package_mappings.empty?
            @warnings << "No package mappings found"
          else
            log "Found #{mapping.package_mappings.length} package mapping(s)"
          end

          # Validate each package mapping
          mapping.package_mappings.each do |pkg_mapping|
            validate_package_mapping(pkg_mapping)
          end
        end

        def validate_package_mapping(pkg_mapping)
          # Check required fields
          unless pkg_mapping.uml_name
            @errors << "Package mapping missing uml_name"
          end

          unless pkg_mapping.xsd_namespace
            @warnings << "Package '#{pkg_mapping.uml_name}' missing xsd_namespace"
          end

          # Validate class mappings
          if pkg_mapping.class_mappings.nil? || pkg_mapping.class_mappings.empty?
            @warnings << "Package '#{pkg_mapping.uml_name}' has no class mappings"
          else
            log "  Package '#{pkg_mapping.uml_name}': #{pkg_mapping.class_mappings.length} class(es)"
            pkg_mapping.class_mappings.each do |class_mapping|
              validate_class_mapping(class_mapping, pkg_mapping.uml_name)
            end
          end
        end

        def validate_class_mapping(class_mapping, package_name)
          # Check required fields
          unless class_mapping.uml_name
            @errors << "Class mapping in package '#{package_name}' missing uml_name"
          end

          unless class_mapping.xsd_type
            @errors << "Class '#{class_mapping.uml_name}' missing xsd_type"
          end

          # Validate attribute mappings
          return unless class_mapping.attribute_mappings&.any?

          class_mapping.attribute_mappings.each do |attr_mapping|
            validate_attribute_mapping(attr_mapping, class_mapping.uml_name)
          end
        end

        def validate_attribute_mapping(attr_mapping, class_name)
          # Check required fields
          unless attr_mapping.uml_name
            @errors << "Attribute mapping in class '#{class_name}' missing uml_name"
          end

          unless attr_mapping.xsd_element
            @errors << "Attribute '#{attr_mapping.uml_name}' in class '#{class_name}' missing xsd_element"
          end

          # Validate cardinality
          validate_cardinality(attr_mapping, class_name)
        end

        def validate_cardinality(attr_mapping, class_name)
          # Check UML cardinality
          if attr_mapping.uml_multiplicity_min && attr_mapping.uml_multiplicity_max
            min = attr_mapping.uml_multiplicity_min.to_i
            max = attr_mapping.uml_multiplicity_max == "*" ? Float::INFINITY : attr_mapping.uml_multiplicity_max.to_i

            if min > max
              @errors << "Attribute '#{attr_mapping.uml_name}' in class '#{class_name}' has invalid UML cardinality: min (#{min}) > max (#{max})"
            end
          end

          # Check XSD cardinality
          unless attr_mapping.xsd_min_occurs && attr_mapping.xsd_max_occurs
            return
          end

          min = attr_mapping.xsd_min_occurs.to_i
          max = attr_mapping.xsd_max_occurs == "unbounded" ? Float::INFINITY : attr_mapping.xsd_max_occurs.to_i

          return unless min > max

          @errors << "Attribute '#{attr_mapping.uml_name}' in class '#{class_name}' has invalid XSD cardinality: min (#{min}) > max (#{max})"
        end

        def validate_content(mapping)
          return unless mapping

          # Check for duplicate class names within packages
          mapping.package_mappings.each do |pkg_mapping|
            class_names = pkg_mapping.class_mappings.map(&:uml_name)
            duplicates = class_names.select do |name|
              class_names.count(name) > 1
            end.uniq

            if duplicates.any?
              @errors << "Package '#{pkg_mapping.uml_name}' has duplicate class names: #{duplicates.join(', ')}"
            end
          end
        end

        def report_results
          if @errors.any?
            puts "\nErrors (#{@errors.length}):"
            @errors.each { |e| puts "  ✗ #{e}" }
          end

          return unless @warnings.any?

          puts "\nWarnings (#{@warnings.length}):"
          @warnings.each { |w| puts "  ⚠ #{w}" }
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
