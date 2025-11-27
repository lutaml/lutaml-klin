#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin"
require_relative "lib/lutaml/klin/mapping_generator"
require_relative "lib/lutaml/klin/xmi_navigator"
require_relative "lib/lutaml/klin/xsd_analyzer"
require_relative "lib/lutaml/klin/shapechange/config_parser"

puts "=" * 80
puts "Testing MappingGenerator Integration"
puts "=" * 80

# Paths
config_path = "spec/fixtures/configs/simple_config.xml"
xmi_path = "spec/fixtures/xmi/minimal_test.xmi"
xsd_path = "spec/fixtures/xsd/simple_schema.xsd"
output_path = "/tmp/test_mapping_output.yaml"

puts "\n1. Loading ShapeChange configuration..."
config_parser = Lutaml::Klin::Shapechange::ConfigParser.new
config = config_parser.parse_file(config_path)
puts "   ✓ Config loaded"
puts "   - Encoding rules: #{config.encoding_rules&.map(&:name)&.join(', ') || 'none'}"
puts "   - XSD map entries: #{config.xsd_map_entries&.count || 0}"
puts "   - XML namespaces: #{config.xml_namespaces&.count || 0}"

puts "\n2. Parsing XMI file..."
xmi_navigator = Lutaml::Klin::XmiNavigator.new(xmi_path)
xmi_navigator.parse
puts "   ✓ XMI parsed"
puts "   - Total packages: #{xmi_navigator.packages.count}"
xmi_navigator.packages.each do |pkg|
  puts "     * #{pkg.name} (#{pkg.classes.count} classes)"
end

puts "\n3. Analyzing XSD schema..."
xsd_analyzer = Lutaml::Klin::XsdAnalyzer.new
xsd_analyzer.parse_file(xsd_path)
puts "   ✓ XSD analyzed"
puts "   - Target namespace: #{xsd_analyzer.target_namespace}"
puts "   - Complex types: #{xsd_analyzer.complex_types.count}"
puts "   - Elements: #{xsd_analyzer.elements.count}"

puts "\n4. Building XSD analyzer registry..."
xsd_analyzers = {
  xsd_analyzer.target_namespace => xsd_analyzer
}
puts "   ✓ Registry built with #{xsd_analyzers.keys.count} namespace(s)"

puts "\n5. Initializing MappingGenerator..."
generator = Lutaml::Klin::MappingGenerator.new(
  config: config,
  xmi_navigator: xmi_navigator,
  xsd_analyzers: xsd_analyzers
)
puts "   ✓ Generator initialized"

puts "\n6. Generating mapping for package..."
package_name = xmi_navigator.packages.first.name
puts "   - Package: #{package_name}"

begin
  mapping = generator.generate_mapping(package_name)
  puts "   ✓ Mapping generated"
  puts "   - Version: #{mapping.version}"
  puts "   - Generated at: #{mapping.generated_at}"
  puts "   - Source XMI: #{mapping.source_xmi}"
  puts "   - Package mappings: #{mapping.package_mappings.count}"

  if mapping.package_mappings.any?
    pkg_mapping = mapping.package_mappings.first
    puts "\n   Package Mapping Details:"
    puts "   - UML name: #{pkg_mapping.uml_name}"
    puts "   - XSD namespace: #{pkg_mapping.xsd_namespace}"
    puts "   - Class mappings: #{pkg_mapping.class_mappings.count}"

    if pkg_mapping.class_mappings.any?
      cls_mapping = pkg_mapping.class_mappings.first
      puts "\n   First Class Mapping:"
      puts "   - UML name: #{cls_mapping.uml_name}"
      puts "   - XSD name: #{cls_mapping.xsd_name}"
      puts "   - XSD namespace: #{cls_mapping.xsd_namespace}"
      puts "   - Attribute mappings: #{cls_mapping.attribute_mappings.count}"

      if cls_mapping.attribute_mappings.any?
        puts "\n   Attribute Mappings:"
        cls_mapping.attribute_mappings.each do |attr|
          puts "     * #{attr.uml_name} (#{attr.uml_type}) -> #{attr.xsd_name} (#{attr.xsd_type})"
          puts "       Cardinality: [#{attr.min_occurs}..#{attr.max_occurs}]"
          puts "       Namespace: #{attr.namespace}" if attr.namespace
        end
      end
    end
  end
rescue StandardError => e
  puts "   ✗ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end

puts "\n7. Saving mapping to YAML..."
begin
  generator.save_mapping(output_path)
  puts "   ✓ Mapping saved to: #{output_path}"

  # Display YAML content
  content = File.read(output_path)
  puts "\n   YAML Content Preview:"
  puts "   #{'-' * 76}"
  content.lines.first(30).each do |line|
    puts "   #{line.chomp}"
  end
  if content.lines.count > 30
    puts "   ... (#{content.lines.count - 30} more lines)"
  end
  puts "   #{'-' * 76}"
rescue StandardError => e
  puts "   ✗ Error saving: #{e.message}"
  exit 1
end

puts "\n#{'=' * 80}"
puts "✓ All tests passed!"
puts "=" * 80
