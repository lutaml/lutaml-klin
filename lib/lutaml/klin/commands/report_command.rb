# frozen_string_literal: true

require "yaml"
require_relative "../models/mapping/schema_mapping"
require_relative "../models/mapping/package_mapping"
require_relative "../models/mapping/class_mapping"
require_relative "../models/mapping/attribute_mapping"

module Lutaml
  module Klin
    module Commands
      # Command to generate human-readable transformation reports
      class ReportCommand
        attr_reader :mapping_file, :output_file, :verbose

        def initialize(mapping_file:, output_file: nil, verbose: false)
          @mapping_file = mapping_file
          @output_file = output_file
          @verbose = verbose
        end

        def run
          log "Loading mapping file..."
          mapping = load_mapping
          log "Mapping loaded successfully"

          log "Generating transformation report..."
          report = generate_report(mapping)
          log "Report generated successfully"

          if output_file
            log "Writing report to: #{output_file}"
            File.write(output_file, report)
            puts "✓ Report written to: #{output_file}"
          else
            puts report
          end
        rescue StandardError => e
          error "Failed to generate report: #{e.message}"
          error e.backtrace.join("\n") if verbose
          exit 1
        end

        private

        def load_mapping
          unless File.exist?(mapping_file)
            error "Mapping file not found: #{mapping_file}"
            exit 1
          end

          yaml_content = File.read(mapping_file)
          Models::Mapping::SchemaMapping.from_yaml(yaml_content)
        end

        def generate_report(mapping)
          report = []
          report << "ShapeChange Transformation Investigation"
          report << "=" * 80
          report << ""

          mapping.package_mappings.each do |package|
            report << generate_package_section(package)
            report << ""
          end

          report << generate_transformation_patterns(mapping)

          report.join("\n")
        end

        def generate_package_section(package)
          lines = []
          lines << "Package: #{package.uml_name}"
          lines << "-" * 80
          lines << "XSD Namespace: #{package.xsd_namespace}"
          lines << ""

          package.class_mappings.each do |class_mapping|
            lines << generate_class_section(class_mapping)
            lines << ""
          end

          lines.join("\n")
        end

        def generate_class_section(class_mapping)
          lines = []

          # UML Class section
          lines << "UML Class: #{class_mapping.uml_name}"
          lines << "-" * 40
          if class_mapping.uml_stereotype
            lines << "Stereotype: #{class_mapping.uml_stereotype}"
          end
          if class_mapping.uml_base_class
            lines << "Extends: #{class_mapping.uml_base_class}"
          end

          if class_mapping.attribute_mappings&.any?
            lines << "Attributes:"
            class_mapping.attribute_mappings.each do |attr|
              cardinality = format_uml_cardinality(attr)
              lines << "  - #{attr.uml_name}: #{attr.uml_type} #{cardinality}"
            end
          end
          lines << ""

          # XSD Element section
          if class_mapping.xsd_element
            lines << "XSD Element: #{class_mapping.xsd_element}"
            lines << "-" * 40
            if class_mapping.xsd_substitution_group
              lines << "Substitution Group: #{class_mapping.xsd_substitution_group}"
            end
            lines << "Type: #{class_mapping.xsd_type}"
            lines << ""
          end

          # XSD Type section
          lines << "XSD Type: #{class_mapping.xsd_type}"
          lines << "-" * 40
          if class_mapping.xsd_base_type
            lines << "Base: #{class_mapping.xsd_base_type} (extends)"
          end

          if class_mapping.attribute_mappings&.any?
            lines << "Elements:"
            class_mapping.attribute_mappings.each do |attr|
              cardinality = format_xsd_cardinality(attr)
              lines << "  - #{attr.xsd_element} (#{attr.xsd_type}) #{cardinality}"
            end
          end

          lines.join("\n")
        end

        def generate_transformation_patterns(mapping)
          lines = []
          lines << "Transformation Patterns Observed"
          lines << "=" * 80
          lines << ""

          patterns = analyze_patterns(mapping)

          patterns.each_with_index do |(pattern, examples), index|
            lines << "#{index + 1}. #{pattern}"
            examples.each do |example|
              lines << "   Example: #{example}"
            end
            lines << ""
          end

          lines.join("\n")
        end

        def analyze_patterns(mapping)
          patterns = {}

          # Analyze naming patterns
          type_suffix_count = 0
          direct_mapping_count = 0
          extension_count = 0
          substitution_count = 0

          mapping.package_mappings.each do |package|
            package.class_mappings.each do |cls|
              # Pattern 1: Class → ComplexType naming
              if cls.xsd_type&.end_with?("Type")
                type_suffix_count += 1
                patterns["Class → ComplexType: Name + 'Type' suffix"] ||= []
                patterns["Class → ComplexType: Name + 'Type' suffix"] << "#{cls.uml_name} → #{cls.xsd_type}"
              end

              # Pattern 2: Direct element mapping
              if cls.xsd_element == cls.uml_name
                direct_mapping_count += 1
                patterns["Class name → Element name: Direct mapping"] ||= []
                patterns["Class name → Element name: Direct mapping"] << cls.uml_name
              end

              # Pattern 3: Inheritance via extension
              if cls.xsd_base_type
                extension_count += 1
                patterns["Inheritance: UML extends → XSD extension"] ||= []
                patterns["Inheritance: UML extends → XSD extension"] << "#{cls.uml_name} extends #{cls.uml_base_class} → #{cls.xsd_type} extends #{cls.xsd_base_type}"
              end

              # Pattern 4: Substitution groups
              if cls.xsd_substitution_group
                substitution_count += 1
                patterns["Substitution: FeatureType → substitutionGroup"] ||= []
                patterns["Substitution: FeatureType → substitutionGroup"] << "#{cls.xsd_element} → #{cls.xsd_substitution_group}"
              end
            end
          end

          # Always include these fundamental patterns
          patterns["Attributes → Elements: Within xs:sequence"] ||= ["All UML attributes mapped to XSD elements"]

          # Limit examples to first 3
          patterns.transform_values { |examples| examples.first(3) }
        end

        def format_uml_cardinality(attr)
          return "" unless attr.uml_multiplicity_min || attr.uml_multiplicity_max

          min = attr.uml_multiplicity_min || "0"
          max = attr.uml_multiplicity_max || "1"
          "[#{min}..#{max}]"
        end

        def format_xsd_cardinality(attr)
          return "" unless attr.xsd_min_occurs || attr.xsd_max_occurs

          min = attr.xsd_min_occurs || "1"
          max = attr.xsd_max_occurs || "1"
          return "" if min == "1" && max == "1"

          "[minOccurs=#{min}, maxOccurs=#{max}]"
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
