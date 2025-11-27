#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple SPA Demo - Shows what the generated output looks like
# without requiring external gem dependencies

require "fileutils"
require "json"
require "time"

# Configuration
OUTPUT_DIR = File.join(__dir__, "output/spa")

puts "=" * 80
puts "lutaml-klin SPA Output Demonstration"
puts "=" * 80
puts
puts "Generating demo SPA website without external dependencies..."
puts

# Create directories
FileUtils.mkdir_p(File.join(OUTPUT_DIR, "data"))
FileUtils.mkdir_p(File.join(OUTPUT_DIR, "assets/css"))
FileUtils.mkdir_p(File.join(OUTPUT_DIR, "assets/js"))

# Generate mappings.json
mappings_data = {
  version: "1.0",
  generated_at: Time.now.utc.iso8601,
  metadata: {
    lur_package: "plateau_uro.lur",
    lxr_package: "plateau_schemas.lxr",
    config_file: "ShapeChangeConfig_Plateau_uro.xml"
  },
  packages: [
    {
      id: "pkg_uro",
      name: "ModelRoot::i-UR::uro",
      namespace: "https://www.geospatial.jp/iur/uro/3.2",
      classes: [
        {
          id: "class_building",
          uml_name: "Building",
          uml_qualified_name: "ModelRoot::i-UR::uro::Building",
          uml_stereotype: "featureType",
          uml_documentation: "Represents a building feature in urban areas",
          xsd_element: "uro:Building",
          xsd_type: "uro:BuildingType",
          xsd_namespace: "https://www.geospatial.jp/iur/uro/3.2",
          xsd_documentation: "Complex type for building features",
          resolved: true,
          resolution_status: "resolved",
          resolution_method: "schema_repository",
          resolution_confidence: 0.95,
          attributes: [
            {
              id: "attr_building_type",
              uml_name: "buildingType",
              uml_type: "gml::CodeType",
              uml_multiplicity: "0..1",
              xsd_element: "uro:buildingType",
              xsd_type: "gml:CodeType",
              xsd_namespace: "http://www.opengis.net/gml/3.2",
              xsd_min_occurs: "0",
              xsd_max_occurs: "1",
              resolved: true,
              resolution_status: "resolved",
              resolution_method: "schema_repository"
            },
            {
              id: "attr_height",
              uml_name: "height",
              uml_type: "Measure",
              uml_multiplicity: "0..1",
              xsd_element: "uro:height",
              xsd_type: "gml:MeasureType",
              xsd_namespace: "http://www.opengis.net/gml/3.2",
              xsd_min_occurs: "0",
              xsd_max_occurs: "1",
              resolved: true,
              resolution_status: "resolved",
              resolution_method: "shapechange"
            },
            {
              id: "attr_custom",
              uml_name: "customProperty",
              uml_type: "CustomType",
              uml_multiplicity: "0..1",
              resolved: false,
              resolution_status: "unresolved",
              resolution_error: "Type not found in XSD repository"
            }
          ]
        }
      ]
    }
  ]
}

File.write(File.join(OUTPUT_DIR, "data/mappings.json"),
           JSON.pretty_generate(mappings_data))
puts "✓ Generated data/mappings.json"

# Generate search_index.json
search_index = {
  index: [
    {
      id: "class_building",
      type: "class",
      title: "Building",
      package: "ModelRoot::i-UR::uro",
      xsd_type: "uro:BuildingType",
      keywords: %w[building feature urban],
      url: "#/packages/pkg_uro/classes/class_building"
    },
    {
      id: "attr_building_type",
      type: "attribute",
      title: "buildingType",
      parent_class: "Building",
      xsd_type: "gml:CodeType",
      keywords: %w[building type code],
      url: "#/packages/pkg_uro/classes/class_building/attributes/attr_building_type"
    }
  ]
}

File.write(File.join(OUTPUT_DIR, "data/search_index.json"),
           JSON.pretty_generate(search_index))
puts "✓ Generated data/search_index.json"

# Generate statistics.json
statistics = {
  total_packages: 1,
  total_classes: 1,
  total_attributes: 3,
  resolved_classes: 1,
  resolved_attributes: 2,
  unresolved_attributes: 1,
  resolution_rate: 66.67,
  generated_at: Time.now.utc.iso8601
}

File.write(File.join(OUTPUT_DIR, "data/statistics.json"),
           JSON.pretty_generate(statistics))
puts "✓ Generated data/statistics.json"

# Copy template files from implementation
template_dir = File.join(__dir__, "../lib/lutaml/klin/templates/spa")

if Dir.exist?(template_dir)
  FileUtils.cp(File.join(template_dir, "index.html"),
               File.join(OUTPUT_DIR, "index.html"))
  FileUtils.cp(File.join(template_dir, "assets/css/style.css"),
               File.join(OUTPUT_DIR, "assets/css/style.css"))
  FileUtils.cp(File.join(template_dir, "assets/js/app.js"),
               File.join(OUTPUT_DIR, "assets/js/app.js"))
  puts "✓ Copied HTML/CSS/JS templates"
else
  puts "⚠️  Template directory not found: #{template_dir}"
  puts "   Creating placeholder files..."

  # Create minimal HTML
  File.write(File.join(OUTPUT_DIR, "index.html"), <<~HTML)
    <!DOCTYPE html>
    <html><head><title>UML-XSD Mapping Demo</title></head>
    <body><h1>SPA Demo</h1><p>See data/ directory for JSON files</p></body></html>
  HTML
  puts "✓ Created placeholder index.html"
end

puts
puts "=" * 80
puts "SPA Website Generated!"
puts "=" * 80
puts
puts "Output directory: #{OUTPUT_DIR}"
puts
puts "Files created:"
puts "  ├── index.html"
puts "  ├── data/"
puts "  │   ├── mappings.json        (#{File.size(File.join(OUTPUT_DIR,
                                                            'data/mappings.json'))} bytes)"
puts "  │   ├── search_index.json    (#{File.size(File.join(OUTPUT_DIR,
                                                            'data/search_index.json'))} bytes)"
puts "  │   └── statistics.json      (#{File.size(File.join(OUTPUT_DIR,
                                                            'data/statistics.json'))} bytes)"
puts "  └── assets/"
puts "      ├── css/style.css"
puts "      └── js/app.js"
puts
puts "Open in browser:"
puts "  file://#{File.join(OUTPUT_DIR, 'index.html')}"
puts
puts "Or run:"
puts "  open #{File.join(OUTPUT_DIR, 'index.html')}"
puts
