#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone SPA Demo - No external gem dependencies
# Shows the final SPA output with embedded data

require "fileutils"
require "json"
require "time"

OUTPUT_DIR = File.join(__dir__, "output/_site")
TEMPLATE_DIR = File.join(__dir__, "../lib/lutaml/klin/templates/spa")

puts "=" * 80
puts "lutaml-klin SPA Generation Demo"
puts "Output directory: _site (like Jekyll and other static site generators)"
puts "Data mode: embedded (works with file:// protocol, no server needed)"
puts "=" * 80
puts

# Create directories
FileUtils.mkdir_p(File.join(OUTPUT_DIR, "data"))
FileUtils.mkdir_p(File.join(OUTPUT_DIR, "assets/css"))
FileUtils.mkdir_p(File.join(OUTPUT_DIR, "assets/js"))

# Create demo data
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
      name: "ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.2::uro",
      namespace: "https://www.geospatial.jp/iur/uro/3.2",
      qualified_name: "ModelRoot::i-UR::uro",
      classes: [
        {
          id: "class_building",
          uml_name: "Building",
          uml_qualified_name: "ModelRoot::i-UR::uro::Building",
          uml_stereotype: "featureType",
          uml_documentation: "Represents a building feature in urban planning areas",
          xsd_element_name: "uro:Building",
          xsd_type_name: "uro:BuildingType",
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
              uml_documentation: "Classification of building type",
              xsd_element_name: "uro:buildingType",
              xsd_type: "gml:CodeType",
              xsd_namespace: "http://www.opengis.net/gml/3.2",
              xsd_min_occurs: "0",
              xsd_max_occurs: "1",
              xsd_documentation: "gml:CodeType for coded values",
              resolved: true,
              resolution_status: "resolved",
              resolution_method: "schema_repository"
            },
            {
              id: "attr_height",
              uml_name: "measuredHeight",
              uml_type: "Measure",
              uml_multiplicity: "0..1",
              uml_documentation: "Measured height in meters",
              xsd_element_name: "uro:measuredHeight",
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
              uml_documentation: "Custom extended property",
              resolved: false,
              resolution_status: "unresolved",
              resolution_error: "Type 'CustomType' not found in XSD repository"
            }
          ]
        }
      ]
    }
  ]
}

search_index = {
  index: [
    {
      id: "class_building",
      type: "class",
      title: "Building",
      qualified_name: "ModelRoot::i-UR::uro::Building",
      keywords: %w[building feature urban],
      resolution_status: "resolved"
    },
    {
      id: "attr_building_type",
      type: "attribute",
      title: "buildingType",
      qualified_name: "Building::buildingType",
      keywords: %w[building type code],
      resolution_status: "resolved"
    }
  ]
}

statistics = {
  summary: {
    total_packages: 1,
    total_classes: 1,
    total_attributes: 3,
    resolved_classes: 1,
    resolved_attributes: 2,
    resolution_rate: 66.67
  }
}

# Write JSON files
File.write(File.join(OUTPUT_DIR, "data/mappings.json"),
           JSON.pretty_generate(mappings_data))
File.write(File.join(OUTPUT_DIR, "data/search_index.json"),
           JSON.pretty_generate(search_index))
File.write(File.join(OUTPUT_DIR, "data/statistics.json"),
           JSON.pretty_generate(statistics))

puts "✓ Generated JSON data files"

# Read HTML template and inject data
template_html = File.read(File.join(TEMPLATE_DIR, "index.html"))
html_with_data = template_html
                 .gsub("%<MAPPINGS_JSON>s", JSON.generate(mappings_data))
                 .gsub("%<SEARCH_INDEX_JSON>s", JSON.generate(search_index))
                 .gsub("%<STATISTICS_JSON>s", JSON.generate(statistics))

File.write(File.join(OUTPUT_DIR, "index.html"), html_with_data)
puts "✓ Generated index.html with embedded data"

# Copy CSS and JS
FileUtils.cp(
  File.join(TEMPLATE_DIR, "assets/css/style.css"),
  File.join(OUTPUT_DIR, "assets/css/style.css")
)
FileUtils.cp(
  File.join(TEMPLATE_DIR, "assets/js/app.js"),
  File.join(OUTPUT_DIR, "assets/js/app.js")
)
puts "✓ Copied CSS and JavaScript files"
puts

puts "=" * 80
puts "SPA Website Generated Successfully!"
puts "=" * 80
puts
puts "Output: #{OUTPUT_DIR}/"
puts "  ├── index.html (with embedded JSON data)"
puts "  ├── data/ (JSON files)"
puts "  └── assets/ (CSS/JS)"
puts
puts "Statistics:"
puts "  • Classes: 1 (100% resolved)"
puts "  • Attributes: 3 (66.7% resolved)"
puts "  • Resolution methods: schema_repository, shapechange"
puts
puts "Opening in browser..."
index_path = File.join(OUTPUT_DIR, "index.html")
puts "  file://#{index_path}"
puts

system("open", index_path)

puts "The SPA demonstrates:"
puts "  ✓ Package tree with URO package"
puts "  ✓ Building class with complete details"
puts "  ✓ 3 attributes (2 resolved ✓, 1 unresolved ✗)"
puts "  ✓ Resolution tracking and documentation"
puts "  ✓ Interactive navigation"
puts "  ✓ Works offline (embedded data)"
puts
