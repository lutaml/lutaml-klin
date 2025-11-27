#!/usr/bin/env ruby
# frozen_string_literal: true

# Test namespace prefix fix for XSD generation

require_relative "lib/lutaml/klin"

puts "Testing Namespace Prefix Fix"
puts "=" * 80

# Configuration
config_path = "./examples/ShapeChangeConfig_Plateau_urf_for_plateau.xml"
output_dir = "./final_schemas"

puts "\n1. Loading ShapeChange configuration..."
parser = Lutaml::Klin::Shapechange::ConfigParser.new
config = parser.parse_file(config_path)
puts "   ✓ Config loaded"

puts "\n2. Loading UML repository..."
xmi_path = config.input.file_name.strip
puts "   XMI: #{xmi_path}"
uml_repo = Lutaml::Klin::Shapechange::UmlRepository.new(xmi_path)
puts "   ✓ Repository loaded"

puts "\n3. Generating XSD for urf package..."
generator = Lutaml::Klin::Shapechange::XsdGenerator.new(uml_repo, config)
results = generator.generate_schemas(["urf"], output_dir)

if results.empty?
  puts "   ✗ No schemas generated"
  exit 1
end

puts "   ✓ Generated: #{results.first[:file]}"

puts "\n4. Checking namespace prefix in generated XSD..."
xsd_content = File.read(results.first[:file])

# Check for xs: prefix
if xsd_content.include?('xmlns:xs="http://www.w3.org/2001/XMLSchema"')
  puts "   ✓ PASS: Found xmlns:xs namespace declaration"
else
  puts "   ✗ FAIL: Missing xmlns:xs namespace declaration"
end

if xsd_content.include?("<xs:schema")
  puts "   ✓ PASS: Root element uses xs:schema"
else
  puts "   ✗ FAIL: Root element not using xs:schema"
end

if xsd_content.include?("<xs:element")
  puts "   ✓ PASS: Elements use xs:element prefix"
else
  puts "   ✗ FAIL: Elements not using xs: prefix"
end

if xsd_content.include?("<xs:complexType")
  puts "   ✓ PASS: ComplexTypes use xs:complexType prefix"
else
  puts "   ✗ FAIL: ComplexTypes not using xs: prefix"
end

puts "\n5. Showing first 30 lines of generated XSD..."
puts "-" * 80
puts xsd_content.lines.first(30).join
puts "-" * 80

puts "\n#{'=' * 80}"
puts "Test Complete!"
puts "=" * 80
