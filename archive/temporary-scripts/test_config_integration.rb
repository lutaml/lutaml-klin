#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin"

puts "=" * 80
puts "Testing ShapeChange Config Integration"
puts "=" * 80
puts

# Parse the config
parser = Lutaml::Klin::Shapechange::ConfigParser.new
config = parser.parse_file("./reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml")

puts "Config loaded successfully:"
puts "  XsdMapEntries: #{config.xsd_map_entries.size}"
puts "  PackageInfos: #{config.package_infos.size}"
puts "  XmlNamespaces: #{config.xml_namespaces.size}"
puts "  EncodingRules: #{config.encoding_rules.size}"
puts

# Test specific type lookups
test_types = [
  ["gml::CodeType", "citygml"],
  ["CharacterString", "iso19136_2007"],
  ["CharacterString", "citygml"],
  ["Integer", "iso19136_2007"],
  ["Boolean", "iso19136_2007"]
]

puts "Testing type lookups:"
puts "-" * 80

test_types.each do |uml_type, encoding_rule|
  mapping = config.find_type_mapping(uml_type, encoding_rule: encoding_rule)

  puts "\nUML Type: #{uml_type}"
  puts "  Encoding Rule: #{encoding_rule}"
  puts "  Found: #{!mapping.nil?}"

  next unless mapping

  puts "  xml_type: #{mapping.xml_type}"
  puts "  xml_type_type: #{mapping.xml_type_type}"
  puts "  xml_element: #{mapping.xml_element}" if mapping.xml_element
end

puts
puts "=" * 80
puts "Testing has_type_mapping? and get_type_mapping wrapper methods:"
puts "=" * 80

test_types.each do |uml_type, encoding_rule|
  has_mapping = config.has_type_mapping?(uml_type, encoding_rule: encoding_rule)
  mapping = config.get_type_mapping(uml_type, encoding_rule: encoding_rule)

  puts "\n#{uml_type} (#{encoding_rule}):"
  puts "  has_type_mapping?: #{has_mapping}"
  puts "  get_type_mapping: #{mapping.nil? ? 'nil' : mapping.xml_type}"
end

puts
puts "=" * 80
puts "Test Complete!"
puts "=" * 80
