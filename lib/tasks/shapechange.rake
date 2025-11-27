# frozen_string_literal: true

namespace :shapechange do
  desc "Import encoding rules from ShapeChange installation"
  task :import_rules, [:shapechange_dir] do |_t, args|
    require_relative "../lutaml/klin/shapechange/parsers/standard_rules_parser"
    require "fileutils"

    shapechange_dir = args[:shapechange_dir] || ENV["SHAPECHANGE_DIR"] ||
                      File.expand_path("~/src/external/ShapeChange")

    config_dir = File.join(shapechange_dir,
                           "shapechange-core/src/main/resources/config")
    standard_rules_file = File.join(config_dir, "StandardRules.xml")

    unless File.exist?(standard_rules_file)
      puts "Error: StandardRules.xml not found at: #{standard_rules_file}"
      puts "Please set SHAPECHANGE_DIR environment variable or pass as argument"
      exit 1
    end

    puts "Importing ShapeChange rules from: #{shapechange_dir}"
    puts ""

    # Parse StandardRules.xml
    parser = Lutaml::Klin::Shapechange::Parsers::StandardRulesParser.new
    encoding_rules = parser.parse_file(standard_rules_file)

    puts "Found #{encoding_rules.size} encoding rules:"
    encoding_rules.each do |er|
      puts "  - #{er.name} (#{er.rules.size} rules)"
      puts "    extends: #{er.extends}" if er.extends
    end
    puts ""

    # Create output directory
    output_dir = "config/shapechange"
    FileUtils.mkdir_p(output_dir)

    # Copy StandardRules.xml
    output_file = File.join(output_dir, "StandardRules.xml")
    FileUtils.cp(standard_rules_file, output_file)

    puts "✓ Copied StandardRules.xml to: #{output_file}"

    # Also copy StandardMapEntries files
    %w[
      StandardMapEntries.xml
      StandardMapEntries_iso19136_2007.xml
      StandardMapEntries_iso19139_2007.xml
    ].each do |filename|
      source = File.join(config_dir, filename)
      next unless File.exist?(source)

      dest = File.join(output_dir, filename)
      FileUtils.cp(source, dest)
      puts "✓ Copied #{filename}"
    end

    puts ""
    puts "Import complete!"
    puts "Rules are now available in: #{output_dir}"
  end

  desc "Validate encoding rules configuration"
  task :validate_rules do
    require_relative "../lutaml/klin/shapechange/rule_registry"
    require_relative "../lutaml/klin/shapechange/parsers/standard_rules_parser"

    # Check if local config exists
    local_config = "config/shapechange/StandardRules.xml"
    if File.exist?(local_config)
      puts "Validating local ShapeChange rules..."
      parser = Lutaml::Klin::Shapechange::Parsers::StandardRulesParser.new
      rules = parser.parse_file(local_config)

      puts "✓ Successfully parsed #{rules.size} encoding rules"

      # Build registry
      registry = Lutaml::Klin::Shapechange::RuleRegistry.new
      rules.each { |er| registry.register_encoding_rule(er) }

      puts "✓ All rules registered successfully"

      # Check inheritance chains
      rules.each do |er|
        next unless er.extends

        parent = registry.encoding_rule(er.extends)
        if parent
          puts "✓ #{er.name} extends #{er.extends} (OK)"
        else
          puts "✗ #{er.name} extends #{er.extends} (NOT FOUND)"
        end
      end
    else
      puts "No local rules found. Run 'rake shapechange:import_rules' first."
    end
  end

  desc "Show encoding rules summary"
  task :show_rules do
    require_relative "../lutaml/klin/shapechange/rule_registry"
    require_relative "../lutaml/klin/shapechange/base_encoding_rules"

    registry = Lutaml::Klin::Shapechange::RuleRegistry.new
    Lutaml::Klin::Shapechange.load_base_encoding_rules(registry)

    puts "Encoding Rules Summary"
    puts "=" * 70
    puts ""

    registry.encoding_rules.each do |name, er|
      puts "#{name}:"
      puts "  Extends: #{er.extends || 'none'}"
      puts "  Rules: #{er.rules.size}"

      all_rules = registry.all_rules_for(name)
      puts "  Total (with inheritance): #{all_rules.size}"
      puts ""
    end
  end
end
