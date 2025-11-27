#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin/xsd_analyzer"

# Test XSD analysis with PLATEAU urbanObject.xsd
xsd_path = "/Users/mulgogi/src/mn/mn-samples-plateau/reference-docs/xsd/i-ur/urbanObject.xsd"

puts "=" * 80
puts "Testing XSD Analysis with PLATEAU urbanObject.xsd"
puts "=" * 80
puts

analyzer = Lutaml::Klin::XsdAnalyzer.new
puts "Parsing XSD file..."
analyzer.parse_file(xsd_path)

puts "Target Namespace: #{analyzer.target_namespace}"
puts "Number of complex types: #{analyzer.complex_types.count}"
puts "Number of simple types: #{analyzer.simple_types.count}"
puts "Number of top-level elements: #{analyzer.elements.count}"
puts

puts "=" * 80
puts "Extracting Complex Type Mappings..."
puts "=" * 80
puts

mappings = analyzer.extract_complex_type_mappings

# Find a specific complex type to examine
test_types = %w[
  AbstractConstructionType
  BuildingDetailAttributeType
  DataQualityAttributeType
]

test_types.each do |type_name|
  mapping = mappings.find { |m| m.name == type_name }
  next unless mapping

  puts
  puts "-" * 80
  puts "Complex Type: #{mapping.name}"
  puts "-" * 80
  puts "  Abstract: #{mapping.abstract}"
  puts "  Mixed: #{mapping.mixed}"
  puts "  Extension: #{mapping.extension}"
  puts "  Base Type: #{mapping.base_type}" if mapping.base_type
  puts "  Namespace: #{mapping.namespace}"
  puts
  puts "  Elements (#{mapping.elements.count}):"
  mapping.elements.first(10).each do |el|
    puts "    - #{el.name}: #{el.type} [#{el.min_occurs}..#{el.max_occurs}]"
  end
  if mapping.elements.count > 10
    puts "    ... and #{mapping.elements.count - 10} more elements"
  end
  puts
  puts "  Attributes (#{mapping.attributes.count}):"
  mapping.attributes.each do |attr|
    puts "    - #{attr.name}: #{attr.type} [#{attr.min_occurs}..#{attr.max_occurs}]"
  end
end

puts
puts "=" * 80
puts "Summary"
puts "=" * 80
puts "Total complex type mappings extracted: #{mappings.count}"
puts

# Count how many have extensions
extension_count = mappings.count(&:extension)
puts "Types with extensions: #{extension_count}"
puts

# Count total elements across all types
total_elements = mappings.sum { |m| m.elements.count }
puts "Total elements extracted: #{total_elements}"
puts

# Count total attributes across all types
total_attributes = mappings.sum { |m| m.attributes.count }
puts "Total attributes extracted: #{total_attributes}"
puts

puts "=" * 80
puts "XSD Analysis Test Complete!"
puts "=" * 80
