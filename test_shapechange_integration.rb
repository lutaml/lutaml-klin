#!/usr/bin/env ruby
# frozen_string_literal: true

# Quick test of ShapeChange integration fix

require_relative "lib/lutaml/klin"

puts "Testing ShapeChange Config Integration Fix"
puts "=" * 80

# Test 1: Load config
puts "\n1. Loading ShapeChange configuration..."
config_path = "./reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml"

begin
  parser = Lutaml::Klin::Shapechange::ConfigParser.new
  config = parser.parse_file(config_path)
  puts "   ✓ Config loaded successfully"
  puts "   - XML Namespaces: #{config.xml_namespaces.size}"
  puts "   - XSD Map Entries: #{config.xsd_map_entries.size}"
  puts "   - Package Infos: #{config.package_infos.size}"
  puts "   - Encoding Rules: #{config.encoding_rules.size}"
rescue StandardError => e
  puts "   ✗ Failed: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end

# Test 2: Test helper methods
puts "\n2. Testing helper methods..."

# Test namespace_for_package
puts "   Testing namespace_for_package..."
ns = config.namespace_for_package("uro")
if ns
  puts "   ✓ Found namespace for 'uro': #{ns}"
else
  puts "   ⚠ No namespace found for 'uro'"
end

# Test prefix_for_namespace
puts "   Testing prefix_for_namespace..."
prefix = config.prefix_for_namespace(ns) if ns
if prefix
  puts "   ✓ Found prefix for namespace: #{prefix}"
else
  puts "   ⚠ No prefix found"
end

# Test find_type_mapping
puts "   Testing find_type_mapping..."
mapping = config.find_type_mapping("gml:CodeType", encoding_rule: "citygml")
if mapping
  puts "   ✓ Found type mapping for gml:CodeType"
  puts "     - type: #{mapping.type}"
  puts "     - xml_type: #{mapping.xml_type}"
  puts "     - applies_to citygml: #{mapping.applies_to?('citygml')}"
else
  puts "   ⚠ No mapping found for gml:CodeType"
end

# Test 3: XsdMapEntry.applies_to?
puts "\n3. Testing XsdMapEntry.applies_to?..."
sample_entries = config.xsd_map_entries.first(3)
sample_entries.each do |entry|
  next unless entry.type

  rules = entry.xsd_encoding_rules || "(all rules)"
  applies = entry.applies_to?("citygml")
  puts "   - #{entry.type}: rules=#{rules}, applies_to(citygml)=#{applies}"
end

puts "\n#{'=' * 80}"
puts "All tests completed!"
puts "=" * 80
