#!/usr/bin/env ruby
# frozen_string_literal: true

# Example demonstrating Phase 5: Validation Workflow & Reporters
#
# This example shows how to validate a schema mapping and generate
# comprehensive reports in multiple formats.

require "bundler/setup"
require "lutaml/klin"
require "lutaml/klin/application/validation_workflow"
require "lutaml/klin/models/mapping/schema_mapping"
require "lutaml/klin/models/mapping/package_mapping"
require "lutaml/klin/models/mapping/class_mapping"
require "lutaml/klin/models/mapping/attribute_mapping"

# Create a sample schema mapping with some resolved and unresolved items
def create_sample_mapping
  # Package 1 - Fully resolved
  resolved_attr = Lutaml::Klin::Mapping::AttributeMapping.new.tap do |attr|
    attr.uml_name = "name"
    attr.uml_type = "CharacterString"
    attr.resolution_status = "resolved"
    attr.resolution_method = "TypeOverrideStrategy"
    attr.xsd_type = "string"
    attr.xsd_name = "name"
  end

  resolved_class = Lutaml::Klin::Mapping::ClassMapping.new.tap do |cls|
    cls.uml_name = "Building"
    cls.resolution_status = "resolved"
    cls.resolution_method = "ShapeChangeStrategy"
    cls.xsd_name = "BuildingType"
    cls.attribute_mappings = [resolved_attr]
  end

  package1 = Lutaml::Klin::Mapping::PackageMapping.new.tap do |pkg|
    pkg.uml_package_name = "BuildingPackage"
    pkg.xsd_namespace = "http://example.com/building"
    pkg.class_mappings = [resolved_class]
  end

  # Package 2 - Has unresolved items
  unresolved_attr = Lutaml::Klin::Mapping::AttributeMapping.new.tap do |attr|
    attr.uml_name = "customProperty"
    attr.uml_type = "CustomType"
    attr.resolution_status = "unresolved"
    attr.resolution_error = "Type not found in XSD repository"
  end

  partial_attr = Lutaml::Klin::Mapping::AttributeMapping.new.tap do |attr|
    attr.uml_name = "location"
    attr.uml_type = "Point"
    attr.resolution_status = "partial"
    attr.resolution_method = "ShapeChangeStrategy"
    attr.resolution_error = "Namespace not fully mapped"
    attr.xsd_type = "gml:PointPropertyType"
  end

  mixed_class = Lutaml::Klin::Mapping::ClassMapping.new.tap do |cls|
    cls.uml_name = "UrbanPlanningArea"
    cls.resolution_status = "resolved"
    cls.resolution_method = "ShapeChangeStrategy"
    cls.xsd_name = "UrbanPlanningAreaType"
    cls.attribute_mappings = [unresolved_attr, partial_attr]
  end

  package2 = Lutaml::Klin::Mapping::PackageMapping.new.tap do |pkg|
    pkg.uml_package_name = "UrbanPlanningPackage"
    pkg.xsd_namespace = "http://example.com/urbanplanning"
    pkg.class_mappings = [mixed_class]
  end

  # Create schema mapping
  Lutaml::Klin::Mapping::SchemaMapping.new.tap do |schema|
    schema.version = "1.0"
    schema.generated_at = Time.now.utc.iso8601
    schema.package_mappings = [package1, package2]
  end
end

puts "=" * 70
puts "Phase 5 Validation Workflow Example"
puts "=" * 70
puts

# Create sample mapping
puts "Creating sample schema mapping..."
schema_mapping = create_sample_mapping
puts "✓ Sample mapping created with 2 packages, 2 classes, 3 attributes"
puts

# Initialize validation workflow
puts "Initializing validation workflow..."
workflow = Lutaml::Klin::Application::ValidationWorkflow.new
puts "✓ Validation workflow initialized"
puts

# Validate the mapping
puts "Validating schema mapping..."
result = workflow.validate_mapping(schema_mapping)
puts "✓ Validation complete"
puts

# Display results
puts "-" * 70
puts "Validation Results"
puts "-" * 70
puts "Status: #{result.valid? ? '✅ Valid' : '⚠️ Invalid'}"
puts "Resolution Rate: #{result.resolution_rate.round(2)}%"
puts
puts "Statistics:"
puts "  Total Packages: #{result.total_packages}"
puts "  Total Classes: #{result.total_classes}"
puts "  Resolved Classes: #{result.resolved_classes}"
puts "  Total Attributes: #{result.total_attributes}"
puts "  Resolved Attributes: #{result.resolved_attributes}"
puts "  Unresolved Items: #{result.unresolved_count}"
puts

if result.unresolved_count > 0
  puts "-" * 70
  puts "Unresolved Items"
  puts "-" * 70
  result.unresolved_items.each_with_index do |item, idx|
    puts "\n#{idx + 1}. #{item[:package]}::#{item[:class]}::#{item[:attribute]}"
    puts "   Type: #{item[:uml_type]}"
    puts "   Status: #{item[:status]}"
    puts "   Error: #{item[:error]}"
    puts "   Suggestions:"
    item[:suggestions].each { |s| puts "     - #{s}" }
  end
  puts
end

# Generate reports
puts "-" * 70
puts "Generating Reports"
puts "-" * 70

output_path = "tmp/validation_example"
FileUtils.mkdir_p("tmp")

report_paths = workflow.generate_reports(result, output_path)
puts "✓ Reports generated:"
report_paths.each do |path|
  size = File.size(path)
  puts "  - #{path} (#{size} bytes)"
end
puts

# Display sample of JSON report
puts "-" * 70
puts "JSON Report Sample"
puts "-" * 70
json_content = File.read("#{output_path}.json")
json_data = JSON.parse(json_content)
puts "Version: #{json_data['version']}"
puts "Validation Status: #{json_data['validation_status']}"
puts "Generated At: #{json_data['generated_at']}"
puts "Unresolved Items: #{json_data['unresolved_items'].size}"
puts

# Display sample of Markdown report
puts "-" * 70
puts "Markdown Report Sample (first 20 lines)"
puts "-" * 70
md_content = File.read("#{output_path}.md")
puts md_content.lines.first(20).join
puts "..."
puts

puts "=" * 70
puts "Example Complete!"
puts "=" * 70
puts "Check the generated reports at:"
puts "  - #{output_path}.json"
puts "  - #{output_path}.md"
puts "=" * 70