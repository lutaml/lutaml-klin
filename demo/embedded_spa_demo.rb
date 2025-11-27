#!/usr/bin/env ruby
# frozen_string_literal: true

# Generate SPA with properly embedded data

require "fileutils"
require "json"
require "time"

OUTPUT_DIR = File.join(__dir__, "output/spa_embedded")

puts "Generating SPA with embedded data..."

# Create directories
FileUtils.mkdir_p(File.join(OUTPUT_DIR, "assets/css"))
FileUtils.mkdir_p(File.join(OUTPUT_DIR, "assets/js"))

# Prepare data
mappings_data = {
  version: "1.0",
  generated_at: Time.now.utc.iso8601,
  metadata: {
    lur_package: "plateau_uro.lur",
    lxr_package: "plateau_schemas.lxr"
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
          uml_documentation: "Represents a building feature",
          xsd_element: "uro:Building",
          xsd_type_name: "uro:BuildingType",
          xsd_namespace: "https://www.geospatial.jp/iur/uro/3.2",
          resolved: true,
          resolution_status: "resolved",
          resolution_method: "schema_repository",
          resolution_confidence: 0.95,
          attributes: [
            {
              id: "attr_type",
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

search_index = {
  index: [
    {
      id: "class_building",
      type: "class",
      title: "Building",
      qualified_name: "ModelRoot::i-UR::uro::Building",
      keywords: %w[building feature],
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

# Read template
template_path = File.join(__dir__,
                          "../lib/lutaml/klin/templates/spa/index.html")
html_template = File.read(template_path)

# Inject data
html_with_data = html_template
                 .gsub("%<MAPPINGS_JSON>s", JSON.generate(mappings_data))
                 .gsub("%<SEARCH_INDEX_JSON>s", JSON.generate(search_index))
                 .gsub("%<STATISTICS_JSON>s", JSON.generate(statistics))

# Write HTML
File.write(File.join(OUTPUT_DIR, "index.html"), html_with_data)

# Copy CSS and JS
FileUtils.cp(
  File.join(__dir__, "../lib/lutaml/klin/templates/spa/assets/css/style.css"),
  File.join(OUTPUT_DIR, "assets/css/style.css")
)

FileUtils.cp(
  File.join(__dir__, "../lib/lutaml/klin/templates/spa/assets/js/app.js"),
  File.join(OUTPUT_DIR, "assets/js/app.js")
)

puts "✓ SPA generated with embedded data at: #{OUTPUT_DIR}"
puts
puts "Open in browser:"
puts "  file://#{File.join(OUTPUT_DIR, 'index.html')}"
puts
puts "Or run: open #{File.join(OUTPUT_DIR, 'index.html')}"
