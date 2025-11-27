#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "lib/lutaml/klin/shapechange/lxr_extractor"
require "json"

config_path = "reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml"

puts "=" * 80
puts "Testing LxrExtractor with PLATEAU ShapeChange Config"
puts "=" * 80
puts

extractor = Lutaml::Klin::Shapechange::LxrExtractor.new

begin
  result = extractor.extract_schema_info(config_path)

  puts "✓ Successfully extracted schema information"
  puts

  puts "XSD Files (#{result[:xsd_files].length}):"
  puts "-" * 80
  result[:xsd_files].each_with_index do |file, i|
    puts "  #{i + 1}. #{file}"
  end
  puts

  puts "Namespace Mappings (#{result[:namespace_mappings].length}):"
  puts "-" * 80
  result[:namespace_mappings].each_with_index do |mapping, i|
    puts "  #{i + 1}. #{mapping[:prefix].ljust(10)} => #{mapping[:uri]}"
  end
  puts

  puts "Schema Location Mappings (#{result[:schema_location_mappings].length}):"
  puts "-" * 80
  result[:schema_location_mappings].each_with_index do |mapping, i|
    puts "  #{i + 1}. From: #{mapping[:from]}"
    puts "     To:   #{mapping[:to]}"
    puts
  end

  puts "=" * 80
  puts "Output Structure Validation:"
  puts "=" * 80

  # Validate structure
  errors = []

  errors << "Missing :xsd_files key" unless result.key?(:xsd_files)
  unless result.key?(:namespace_mappings)
    errors << "Missing :namespace_mappings key"
  end
  unless result.key?(:schema_location_mappings)
    errors << "Missing :schema_location_mappings key"
  end

  errors << ":xsd_files is not an Array" unless result[:xsd_files].is_a?(Array)
  unless result[:namespace_mappings].is_a?(Array)
    errors << ":namespace_mappings is not an Array"
  end
  unless result[:schema_location_mappings].is_a?(Array)
    errors << ":schema_location_mappings is not an Array"
  end

  result[:namespace_mappings].each_with_index do |mapping, i|
    unless mapping.key?(:prefix)
      errors << "namespace_mappings[#{i}] missing :prefix"
    end
    errors << "namespace_mappings[#{i}] missing :uri" unless mapping.key?(:uri)
  end

  result[:schema_location_mappings].each_with_index do |mapping, i|
    unless mapping.key?(:from)
      errors << "schema_location_mappings[#{i}] missing :from"
    end
    unless mapping.key?(:to)
      errors << "schema_location_mappings[#{i}] missing :to"
    end
  end

  if errors.empty?
    puts "✓ All structure validations passed"
    puts "✓ Output is compatible with lutaml-xsd package building"
  else
    puts "✗ Validation errors found:"
    errors.each { |error| puts "  - #{error}" }
  end

  puts
  puts "=" * 80
  puts "JSON Output (for lutaml-xsd integration):"
  puts "=" * 80
  puts JSON.pretty_generate(result)
rescue StandardError => e
  puts "✗ Error extracting schema information:"
  puts "  #{e.class}: #{e.message}"
  puts e.backtrace.first(5).map { |line| "    #{line}" }.join("\n")
  exit 1
end

puts
puts "=" * 80
puts "✓ LxrExtractor test completed successfully!"
puts "=" * 80
