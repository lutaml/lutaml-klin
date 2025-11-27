#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "lib/lutaml/klin"
require "yaml"
require "json"

# Add lutaml-xsd to the load path
$LOAD_PATH.unshift("/Users/mulgogi/src/lutaml/lutaml-xsd/lib")
require "lutaml/xsd"

puts "=" * 80
puts "PLATEAU UML-to-XSD Full Resolution Mapping Generator"
puts "=" * 80
puts

# Configuration
XMI_FILE = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251010-242.xmi"
XSD_FIXTURES_DIR = "/Users/mulgogi/src/lutaml/lutaml-xsd/spec/fixtures"
OUTPUT_DIR = "plateau_xsd_mapping"

# Create output directory
FileUtils.mkdir_p(OUTPUT_DIR)

puts "Configuration:"
puts "  XMI File: #{XMI_FILE}"
puts "  XSD Fixtures: #{XSD_FIXTURES_DIR}"
puts "  Output Directory: #{OUTPUT_DIR}"
puts

# Step 1: Parse XMI and extract UML classes
puts "Step 1: Parsing XMI file..."
puts "-" * 80

navigator = Lutaml::Klin::XmiNavigator.new
navigator.parse_file(XMI_FILE)

# Get all packages
all_packages = navigator.packages
puts "Found #{all_packages.size} packages in XMI"

package_data = {}
all_packages.each do |pkg|
  next unless pkg.name # Skip packages without names

  classes = navigator.classes_in_package(pkg.name)
  next if classes.empty?

  package_data[pkg.name] = {
    id: pkg.id,
    class_count: classes.size,
    classes: classes
  }
  puts "  Package: #{pkg.name} (#{classes.size} classes)"
end
puts

# Step 2: Define schema mappings for XSD parsing
puts "Step 2: Setting up XSD schema mappings..."
puts "-" * 80

schema_mappings = [
  # Map specific relative path to local file
  { from: "../../uro/3.2/urbanObject.xsd",
    to: File.join(XSD_FIXTURES_DIR, "i-ur/urbanObject.xsd") },

  # Map xlink relative paths
  { from: %r{(?:\.\./)+xlink/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR, "codesynthesis-gml-3.2.1/xlink/\\1") },

  # Map GML relative paths
  { from: %r{(?:\.\./)+gml/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR, "codesynthesis-gml-3.2.1/gml/\\1") },

  # Map ISO relative paths
  { from: %r{(?:\.\./)+iso/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR, "codesynthesis-gml-3.2.1/iso/\\1") },

  # Map simple relative paths for GMD, GSS, GTS, GSR, GCO, GMX
  { from: %r{^\.\./gmd/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR,
                  "codesynthesis-gml-3.2.1/iso/19139/20070417/gmd/\\1") },
  { from: %r{^\.\./gss/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR,
                  "codesynthesis-gml-3.2.1/iso/19139/20070417/gss/\\1") },
  { from: %r{^\.\./gts/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR,
                  "codesynthesis-gml-3.2.1/iso/19139/20070417/gts/\\1") },
  { from: %r{^\.\./gsr/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR,
                  "codesynthesis-gml-3.2.1/iso/19139/20070417/gsr/\\1") },
  { from: %r{^\.\./gco/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR,
                  "codesynthesis-gml-3.2.1/iso/19139/20070417/gco/\\1") },
  { from: %r{^\.\./gmx/(.+\.xsd)$},
    to: File.join(XSD_FIXTURES_DIR,
                  "codesynthesis-gml-3.2.1/iso/19139/20070417/gmx/\\1") }
]

puts "Schema mappings configured: #{schema_mappings.size}"
puts

# Step 3: Parse XSD schemas
puts "Step 3: Parsing XSD schemas..."
puts "-" * 80

xsd_schemas = {}

# Parse urbanFunction.xsd
urban_function_xsd = File.join(XSD_FIXTURES_DIR, "i-ur/urbanFunction.xsd")
if File.exist?(urban_function_xsd)
  puts "Parsing urbanFunction.xsd..."
  begin
    xsd_content = File.read(urban_function_xsd)
    parsed_schema = Lutaml::Xsd.parse(
      xsd_content,
      location: File.dirname(urban_function_xsd),
      schema_mappings: schema_mappings
    )
    xsd_schemas[:urbanFunction] = parsed_schema
    puts "  ✓ Parsed successfully"
    puts "    - Elements: #{parsed_schema.element&.size || 0}"
    puts "    - Complex Types: #{parsed_schema.complex_type&.size || 0}"
    puts "    - Simple Types: #{parsed_schema.simple_type&.size || 0}"
  rescue StandardError => e
    puts "  ✗ Error: #{e.message}"
  end
else
  puts "  ✗ File not found: #{urban_function_xsd}"
end

# Parse urbanObject.xsd
urban_object_xsd = File.join(XSD_FIXTURES_DIR, "i-ur/urbanObject.xsd")
if File.exist?(urban_object_xsd)
  puts "Parsing urbanObject.xsd..."
  begin
    xsd_content = File.read(urban_object_xsd)
    parsed_schema = Lutaml::Xsd.parse(
      xsd_content,
      location: File.dirname(urban_object_xsd),
      schema_mappings: schema_mappings
    )
    xsd_schemas[:urbanObject] = parsed_schema
    puts "  ✓ Parsed successfully"
    puts "    - Elements: #{parsed_schema.element&.size || 0}"
    puts "    - Complex Types: #{parsed_schema.complex_type&.size || 0}"
    puts "    - Simple Types: #{parsed_schema.simple_type&.size || 0}"
  rescue StandardError => e
    puts "  ✗ Error: #{e.message}"
  end
else
  puts "  ✗ File not found: #{urban_object_xsd}"
end
puts

# Step 4: Build XSD type registry
puts "Step 4: Building XSD type registry..."
puts "-" * 80

xsd_type_registry = {}

xsd_schemas.each do |schema_name, schema|
  # Register elements
  schema.element&.each do |elem|
    key = "#{schema_name}:element:#{elem.name}"
    xsd_type_registry[key] = {
      type: :element,
      name: elem.name,
      xsd_type: elem.type,
      schema: schema_name
    }
  end

  # Register complex types
  schema.complex_type&.each do |ct|
    key = "#{schema_name}:complexType:#{ct.name}"

    # Extract attributes and elements from complex type
    attributes = []
    elements = []

    ct.sequence&.element&.each do |elem|
      elements << {
        name: elem.name,
        type: elem.type,
        min_occurs: elem.min_occurs,
        max_occurs: elem.max_occurs
      }
    end

    ct.attribute&.each do |attr|
      attributes << {
        name: attr.name,
        type: attr.type,
        use: attr.use
      }
    end

    xsd_type_registry[key] = {
      type: :complexType,
      name: ct.name,
      schema: schema_name,
      elements: elements,
      attributes: attributes,
      extension_base: ct.complex_content&.extension&.base
    }
  end

  # Register simple types
  schema.simple_type&.each do |st|
    key = "#{schema_name}:simpleType:#{st.name}"
    xsd_type_registry[key] = {
      type: :simpleType,
      name: st.name,
      schema: schema_name
    }
  end
end

puts "XSD type registry built: #{xsd_type_registry.size} types registered"
puts

# Step 5: Map UML to XSD and detect unresolved types
puts "Step 5: Mapping UML to XSD and detecting unresolved types..."
puts "-" * 80

mapping_results = {}
total_attributes = 0
resolved_attributes = 0
unresolved_attributes = 0

package_data.each do |pkg_name, pkg_info|
  puts "Processing package: #{pkg_name}"

  package_mapping = {
    package_name: pkg_name,
    class_count: pkg_info[:class_count],
    classes: []
  }

  pkg_info[:classes].each do |uml_class|
    class_mapping = {
      name: uml_class.name,
      id: uml_class.id,
      stereotype: uml_class.stereotype,
      attributes: [],
      unresolved_count: 0
    }

    uml_class.attributes.each do |attr|
      total_attributes += 1

      # Try to resolve the attribute type in XSD
      resolved_xsd = nil
      resolution_path = []

      # Look for matching element or complex type
      xsd_type_registry.each do |key, xsd_info|
        # Check if attribute name matches element name
        if xsd_info[:type] == :element && xsd_info[:name].downcase == attr.name.downcase
          resolved_xsd = xsd_info
          resolution_path << "Matched element: #{key}"
          break
        end

        # Check if attribute type matches complex type name
        unless xsd_info[:type] == :complexType && xsd_info[:name].downcase == attr.type.downcase
          next
        end

        resolved_xsd = xsd_info
        resolution_path << "Matched complexType: #{key}"
        break
      end

      attr_mapping = {
        name: attr.name,
        uml_type: attr.type,
        multiplicity: {
          min: attr.multiplicity_min,
          max: attr.multiplicity_max
        },
        resolved: !resolved_xsd.nil?,
        xsd_info: resolved_xsd,
        resolution_path: resolution_path
      }

      if resolved_xsd
        resolved_attributes += 1
      else
        unresolved_attributes += 1
        class_mapping[:unresolved_count] += 1
      end

      class_mapping[:attributes] << attr_mapping
    end

    package_mapping[:classes] << class_mapping
  end

  mapping_results[pkg_name] = package_mapping
end

puts
puts "Mapping Statistics:"
puts "  Total Attributes: #{total_attributes}"
if total_attributes.positive?
  puts "  Resolved: #{resolved_attributes} (#{(resolved_attributes * 100.0 / total_attributes).round(1)}%)"
  puts "  Unresolved: #{unresolved_attributes} (#{(unresolved_attributes * 100.0 / total_attributes).round(1)}%)"
else
  puts "  Resolved: 0 (0.0%)"
  puts "  Unresolved: 0 (0.0%)"
end
puts

# Step 6: Save results
puts "Step 6: Saving results..."
puts "-" * 80

# Save as YAML
yaml_file = File.join(OUTPUT_DIR, "plateau_xsd_mapping.yaml")
File.write(yaml_file, YAML.dump(mapping_results))
puts "  ✓ Saved YAML: #{yaml_file}"

# Save as JSON (for HTML embedding)
json_file = File.join(OUTPUT_DIR, "plateau_xsd_mapping.json")
json_data = {
  metadata: {
    xmi_file: XMI_FILE,
    generated_at: Time.now.iso8601,
    total_packages: mapping_results.size,
    total_attributes: total_attributes,
    resolved_attributes: resolved_attributes,
    unresolved_attributes: unresolved_attributes,
    resolution_rate: (resolved_attributes * 100.0 / total_attributes).round(2)
  },
  xsd_schemas: xsd_schemas.keys.map(&:to_s),
  packages: mapping_results
}
File.write(json_file, JSON.pretty_generate(json_data))
puts "  ✓ Saved JSON: #{json_file}"

puts
puts "=" * 80
puts "Mapping generation complete!"
puts "=" * 80
puts
puts "Next step: Generate HTML visualization with:"
puts "  ruby generate_xsd_mapping_html.rb"
puts
