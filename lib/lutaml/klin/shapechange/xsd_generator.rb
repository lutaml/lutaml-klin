# frozen_string_literal: true

require "fileutils"
require_relative "models/xsd_document"
require_relative "rule_registry"
require_relative "rule_checker"
require_relative "standard_rules"
require_relative "base_encoding_rules"
require_relative "parsers/standard_rules_parser"
require_relative "rule_processors/object_element_processor"
require_relative "rule_processors/complex_type_processor"
require_relative "rule_processors/sequence_processor"
require_relative "rule_processors/property_element_processor"
require_relative "rule_processors/property_type_processor"
require_relative "rule_processors/enumeration_processor"
require_relative "rule_processors/code_list_processor"
require_relative "rule_processors/class_rules/basic_type_processor"
require_relative "rule_processors/plateau_ade_hooks_processor"

module Lutaml
  module Klin
    module Shapechange
      # Main XSD generation orchestrator
      # Coordinates UML loading, transformation, and XSD creation
      # Single Responsibility: Orchestrate XSD generation workflow
      class XsdGenerator
        attr_reader :uml_repository, :config, :rule_registry

        def initialize(uml_repository, config)
          @uml_repository = uml_repository
          @config = config
          @rule_registry = build_rule_registry
        end

        # Generate XSD schemas for specified packages
        # @param package_names [Array<String>] Package names to process
        # @param output_dir [String] Output directory for XSD files
        # @return [Array<Hash>] Generated files info
        def generate_schemas(package_names, output_dir)
          FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir)

          results = []

          package_names.each do |pkg_name|
            result = generate_schema_for_package(pkg_name, output_dir)
            results << result if result
          end

          results
        end

        private

        def build_rule_registry
          # Start with a new registry
          registry = RuleRegistry.new

          # Always load base encoding rules first (provides iso19136_2007, etc.)
          BaseEncodingRules.load_into(registry)

          # Try to load from ShapeChange StandardRules.xml (overlays on top of base)
          shapechange_config_dir = determine_shapechange_config_dir
          if shapechange_config_dir &&
             File.exist?(File.join(shapechange_config_dir, "StandardRules.xml"))
            # Load encoding rules from ShapeChange XML
            standard_rules_path = File.join(shapechange_config_dir, "StandardRules.xml")
            encoding_rules = Parsers::StandardRulesParser.parse_encoding_rules(standard_rules_path)
            encoding_rules.each do |er|
              registry.register_encoding_rule(er)
            end
          end

          # Always load project-specific encoding rules from config
          # These override or extend the standard rules
          config.encoding_rules.each do |er|
            registry.register_encoding_rule(er) unless registry.encoding_rule(er.name)
          end

          # Load standard rule definitions
          Shapechange.load_standard_rules(registry)

          registry
        end

        def determine_shapechange_config_dir
          # Priority 1: Environment variable
          return ENV["SHAPECHANGE_CONFIG_DIR"] if ENV["SHAPECHANGE_CONFIG_DIR"]

          # Priority 2: Local ShapeChange installation
          local_shapechange = File.expand_path(
            "~/src/external/ShapeChange/shapechange-core/src/main/resources/config"
          )
          return local_shapechange if Dir.exist?(local_shapechange)

          # Priority 3: Project reference directory
          project_reference = File.expand_path(
            "reference/shapechange-configs",
            File.dirname(__FILE__) + "/../../.."
          )
          return project_reference if Dir.exist?(project_reference)

          nil
        end

        def generate_schema_for_package(pkg_name, output_dir)
          # Find UML package
          package = uml_repository.find_package(pkg_name)
          unless package
            puts "Warning: Package not found: #{pkg_name}"
            return nil
          end

          # Get package info from config
          package_info = find_package_info(pkg_name)
          unless package_info
            puts "Warning: No package info in config for: #{pkg_name}"
            return nil
          end

          # Create directory structure from package hierarchy
          package_path = determine_package_path(package)
          package_output_dir = File.join(output_dir, package_path)
          FileUtils.mkdir_p(package_output_dir)

          # Create XSD document
          xsd_doc = Models::XsdDocument.new(
            namespace: package_info.ns.strip,
            prefix: package_info.nsabr.strip,
            version: package_info.version || "1.0"
          )

          # Get encoding rule for this package
          encoding_rule = determine_encoding_rule(package)
          rule_checker = RuleChecker.new(rule_registry, encoding_rule)

          # Process all classes and enums in package
          classes = uml_repository.classes_in_package(pkg_name)

          # Also get enums if repository supports it
          enums = begin
                    if uml_repository.respond_to?(:enums_in_package)
                      uml_repository.enums_in_package(pkg_name)
                    else
                      []
                    end
                  rescue StandardError => e
                    puts "Warning: Could not retrieve enums: #{e.message}"
                    []
                  end

          # Process all classes
          classes.each do |uml_class|
            process_class(uml_class, xsd_doc, rule_checker)
          end

          # Process all enums
          enums.each do |uml_enum|
            process_class(uml_enum, xsd_doc, rule_checker)
          end

          # Generate filename with stripped spaces
          clean_pkg_name = pkg_name.strip
          filename = (package_info.xsd_document || "#{clean_pkg_name}.xsd").strip
          filepath = File.join(package_output_dir, filename)

          # Add all required namespace imports based on referenced types
          xsd_doc.add_required_namespace_imports(config)

          File.write(filepath, xsd_doc.to_xml)

          {
            package: pkg_name,
            file: filepath,
            namespace: package_info.ns.strip,
            classes_processed: classes.size,
            enums_processed: enums.size,
          }
        end

        def find_package_info(pkg_name)
          config.package_infos.find do |pi|
            pi.package_name&.strip == pkg_name
          end
        end

        def determine_package_path(package)
          # Convert package hierarchy to directory path
          # e.g., "ModelRoot::Package::uro" → "ModelRoot/Package"
          full_name = package.full_name || package.name
          return "" unless full_name

          parts = full_name.split("::")

          # Remove last part (that's the package name used for filename)
          # Join remaining parts as directory path
          parts[0..-2].join("/")
        end

        def determine_encoding_rule(package)
          # Read from config's target section first
          config.target_config&.dig(:default_encoding_rule) || "citygml"
        end

        def process_class(uml_class, xsd_doc, rule_checker)
          context = {
            xsd_document: xsd_doc,
            uml_class: uml_class,
            prefix: xsd_doc.prefix,
            config: config,
            uml_repository: uml_repository,
            package_name: uml_class.package&.name,
          }

          # Create processors in order of execution
          processors = [
            RuleProcessors::ObjectElementProcessor.new(rule_checker, config),
            RuleProcessors::ComplexTypeProcessor.new(rule_checker, config),
            RuleProcessors::ClassRules::BasicTypeProcessor.new(rule_checker, config),
            RuleProcessors::SequenceProcessor.new(rule_checker, config),
            RuleProcessors::PropertyElementProcessor.new(rule_checker, config),
            RuleProcessors::PropertyTypeProcessor.new(rule_checker, config),
            RuleProcessors::EnumerationProcessor.new(rule_checker, config),
            RuleProcessors::CodeListProcessor.new(rule_checker, config),
            RuleProcessors::PlateauAdeHooksProcessor.new(rule_checker, config),
          ]

          # Apply all applicable processors
          processors.each do |processor|
            processor.process(uml_class, context)
          end
        end
      end
    end
  end
end