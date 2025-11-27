#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating the bidirectional lookup API for UML ↔ XSD mappings

require "bundler/setup"
require "lutaml/klin"
require "lutaml/klin/application/lookup_workflow"

# This example assumes you have a mapping YAML file
# You can generate one using: lutaml-klin generate ...

MAPPING_FILE = ARGV[0] || "mapping.yaml"

unless File.exist?(MAPPING_FILE)
  puts "Error: Mapping file not found: #{MAPPING_FILE}"
  puts "Usage: ruby examples/lookup_example.rb [mapping.yaml]"
  exit 1
end

puts "=" * 80
puts "Lutaml-Klin Bidirectional Lookup Example"
puts "=" * 80
puts

# Initialize the lookup workflow
workflow = Lutaml::Klin::Application::LookupWorkflow.new(MAPPING_FILE)

puts "Loaded mapping file: #{MAPPING_FILE}"
puts "Total packages: #{workflow.mapping.package_count}"
puts

# ============================================================================
# Example 1: UML Class → XSD Type Lookup
# ============================================================================
puts "Example 1: UML Class → XSD Type Lookup"
puts "-" * 80

uml_class = "ModelRoot::i-UR::urf::UrbanPlanningArea"
puts "Looking up UML class: #{uml_class}"
puts

result = workflow.lookup_uml_to_xsd(uml_class, type: :class)

if result.found?
  match = result.first_match
  puts "✓ Found mapping:"
  puts "  XSD Element: #{match[:xsd_element]}"
  puts "  XSD Type: #{match[:xsd_type]}"
  puts "  XSD Namespace: #{match[:xsd_namespace]}"
  puts "  Resolution Status: #{match[:resolution_status]}"
else
  puts "✗ No mapping found"
end
puts

# ============================================================================
# Example 2: UML Attribute → XSD Element Lookup
# ============================================================================
puts "Example 2: UML Attribute → XSD Element Lookup"
puts "-" * 80

uml_attr = "ModelRoot::i-UR::urf::UrbanPlanningArea::areaType"
puts "Looking up UML attribute: #{uml_attr}"
puts

result = workflow.lookup_uml_to_xsd(uml_attr, type: :attribute)

if result.found?
  match = result.first_match
  puts "✓ Found mapping:"
  puts "  UML Type: #{match[:uml_type]}"
  puts "  XSD Name: #{match[:xsd_name]}"
  puts "  XSD Type: #{match[:xsd_type]}"
  puts "  XSD Namespace: #{match[:xsd_namespace]}"
  puts "  Min Occurs: #{match[:min_occurs]}"
  puts "  Max Occurs: #{match[:max_occurs]}"
else
  puts "✗ No mapping found"
end
puts

# ============================================================================
# Example 3: XSD Type → UML Class Lookup
# ============================================================================
puts "Example 3: XSD Type → UML Class Lookup"
puts "-" * 80

xsd_type = "gml:CodeType"
puts "Looking up XSD type: #{xsd_type}"
puts

result = workflow.lookup_xsd_to_uml(xsd_type, type: :type)

if result.found?
  puts "✓ Found #{result.match_count} mapping(s):"
  result.matches.each_with_index do |match, i|
    puts "  Match #{i + 1}:"
    puts "    UML Class: #{match[:uml_class]}"
    puts "    UML Package: #{match[:uml_package]}" if match[:uml_package]
    puts "    Resolution Status: #{match[:resolution_status]}"
  end
else
  puts "✗ No mappings found"
end
puts

# ============================================================================
# Example 4: XSD Element → UML Attribute Lookup
# ============================================================================
puts "Example 4: XSD Element → UML Attribute Lookup"
puts "-" * 80

xsd_element = "urf:name"
puts "Looking up XSD element: #{xsd_element}"
puts

result = workflow.lookup_xsd_to_uml(xsd_element, type: :element)

if result.found?
  puts "✓ Found #{result.match_count} mapping(s):"
  result.matches.each_with_index do |match, i|
    puts "  Match #{i + 1}:"
    puts "    UML Class: #{match[:uml_class]}"
    puts "    UML Attribute: #{match[:uml_attribute]}"
    puts "    UML Type: #{match[:uml_type]}"
  end
else
  puts "✗ No mappings found"
end
puts

# ============================================================================
# Example 5: Auto-Detection Lookup
# ============================================================================
puts "Example 5: Auto-Detection Lookup"
puts "-" * 80

identifier = "gml:CodeType"
puts "Looking up (auto-detect): #{identifier}"
puts

result = workflow.auto_lookup(identifier)

if result.found?
  puts "✓ Auto-detected as #{result.direction} lookup"
  puts "  Found #{result.match_count} match(es)"
else
  puts "✗ No mappings found"
end
puts

# ============================================================================
# Example 6: Fuzzy Matching
# ============================================================================
puts "Example 6: Fuzzy Matching"
puts "-" * 80

partial_name = "Urban"
puts "Looking up (fuzzy): #{partial_name}"
puts

result = workflow.auto_lookup(partial_name, fuzzy: true)

if result.found?
  puts "✓ Found #{result.match_count} fuzzy match(es):"
  result.matches.take(3).each_with_index do |match, i|
    puts "  Match #{i + 1}:"
    next unless match[:uml_class]

    puts "    UML Class: #{match[:uml_class]}"
    if match[:match_quality]
      puts "    Match Quality: #{(match[:match_quality] * 100).round(1)}%"
    end
  end
  puts "  ... (#{result.match_count - 3} more)" if result.match_count > 3
else
  puts "✗ No fuzzy matches found"
end
puts

# ============================================================================
# Example 7: Output Formats
# ============================================================================
puts "Example 7: Output Formats"
puts "-" * 80
puts

# Text format (default)
puts "Text Format:"
puts workflow.format_result(result, format: :text)
puts

# JSON format
puts "JSON Format (first 200 chars):"
json_output = workflow.format_result(result, format: :json)
puts "#{json_output[0..200]}..."
puts

# YAML format
puts "YAML Format (first 200 chars):"
yaml_output = workflow.format_result(result, format: :yaml)
puts "#{yaml_output[0..200]}..."
puts

puts "=" * 80
puts "Examples completed!"
puts "=" * 80
