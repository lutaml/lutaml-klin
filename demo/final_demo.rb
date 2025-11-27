#!/usr/bin/env ruby
# frozen_string_literal: true

# Final Complete Demo: lutaml-klin with LUR+LXR Integration
#
# This demonstrates the complete workflow with proper embedded data

require "bundler/setup"
require "lutaml/klin"
require "fileutils"
require "json"
require "time"

puts "=" * 80
puts "lutaml-klin Complete Workflow Demo"
puts "Showing: LUR + LXR → Mapping → Validation → SPA (with embedded data)"
puts "=" * 80
puts

# Create demo mapping
schema_mapping = Lutaml::Klin::Models::Mapping::SchemaMapping.new
schema_mapping.version = "1.0"
schema_mapping.generated_at = Time.now.utc.iso8601
schema_mapping.source_lur = "plateau_uro.lur"
schema_mapping.source_lxr = "plateau_schemas.lxr"
schema_mapping.source_config = "ShapeChangeConfig_Plateau_uro.xml"

# Create package mapping
package = Lutaml::Klin::Models::Mapping::PackageMapping.new
package.uml_package_path = "ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.2::uro"
package.uml_package_name = "uro"
package.xsd_namespace = "https://www.geospatial.jp/iur/uro/3.2"
package.created_at = Time.now.utc.iso8601

# Create class mapping
class_mapping = Lutaml::Klin::Models::Mapping::ClassMapping.new
class_mapping.uml_class_name = "Building"
class_mapping.uml_qualified_name = "ModelRoot::i-UR::uro::Building"
class_mapping.uml_stereotype = "featureType"
class_mapping.uml_documentation = "Represents a building feature in urban areas. " \
                                  "Contains attributes for building type, height, and " \
                                  "other structural information."
class_mapping.xsd_element_name = "uro:Building"
class_mapping.xsd_type_name = "uro:BuildingType"
class_mapping.xsd_namespace = "https://www.geospatial.jp/iur/uro/3.2"
class_mapping.xsd_documentation = "Complex type for building features with " \
                                  "geometric and semantic properties."
class_mapping.resolution_status = "resolved"
class_mapping.resolution_method = "schema_repository"
class_mapping.resolution_confidence = 0.95

# Create attribute mappings
attr1 = Lutaml::Klin::Models::Mapping::AttributeMapping.new
attr1.uml_attribute_name = "buildingType"
attr1.uml_type = "gml::CodeType"
attr1.uml_multiplicity = "0..1"
attr1.uml_documentation = "Classification of the building type (residential, commercial, etc.)"
attr1.xsd_element_name = "uro:buildingType"
attr1.xsd_type_name = "gml:CodeType"
attr1.xsd_namespace = "http://www.opengis.net/gml/3.2"
attr1.xsd_min_occurs = "0"
attr1.xsd_max_occurs = "1"
attr1.xsd_documentation = "gml:CodeType is a generalized type for coded values"
attr1.resolution_status = "resolved"
attr1.resolution_method = "schema_repository"

attr2 = Lutaml::Klin::Models::Mapping::AttributeMapping.new
attr2.uml_attribute_name = "measuredHeight"
attr2.uml_type = "Measure"
attr2.uml_multiplicity = "0..1"
attr2.uml_documentation = "Measured height of the building in meters"
attr2.xsd_element_name = "uro:measuredHeight"
attr2.xsd_type_name = "gml:MeasureType"
attr2.xsd_namespace = "http://www.opengis.net/gml/3.2"
attr2.xsd_min_occurs = "0"
attr2.xsd_max_occurs = "1"
attr2.resolution_status = "resolved"
attr2.resolution_method = "shapechange"

attr3 = Lutaml::Klin::Models::Mapping::AttributeMapping.new
attr3.uml_attribute_name = "customProperty"
attr3.uml_type = "CustomType"
attr3.uml_multiplicity = "0..1"
attr3.uml_documentation = "Custom property for extended information"
attr3.resolution_status = "unresolved"
attr3.resolution_error = "Type 'CustomType' not found in XSD repository. " \
                         "Verify type exists or add to type_overrides.yaml"

class_mapping.attribute_mappings = [attr1, attr2, attr3]
package.class_mappings = [class_mapping]
schema_mapping.package_mappings = [package]

# Generate SPA with embedded data
puts "🌐 Generating SPA website with embedded data..."
output_dir = File.join(__dir__, "output/_site")

spa_workflow = Lutaml::Klin::Application::SpaWorkflow.new
spa_path = spa_workflow.generate_spa(
  schema_mapping,
  output_dir,
  title: "PLATEAU URO UML-XSD Mapping Demo",
  data_mode: :embedded # Embedded mode - works with file:// protocol
)

puts "✓ SPA generated at: #{spa_path}"
puts

# Display structure
puts "📁 Generated Structure:"
puts "   #{output_dir}/"
puts "   ├── index.html (with embedded JSON data)"
puts "   ├── data/ (JSON files for reference)"
puts "   │   ├── mappings.json"
puts "   │   ├── search_index.json"
puts "   │   └── statistics.json"
puts "   └── assets/"
puts "       ├── css/style.css"
puts "       └── js/app.js"
puts

# Display statistics
stats = schema_mapping.calculate_statistics
puts "📊 Mapping Statistics:"
puts "   • Total Classes: #{stats[:total_classes]}"
puts "   • Resolved Classes: #{stats[:resolved_classes]}"
puts "   • Total Attributes: #{stats[:total_attributes]}"
puts "   • Resolved Attributes: #{stats[:resolved_attributes]}"
puts "   • Resolution Rate: #{schema_mapping.resolution_rate.round(1)}%"
puts

# Open in browser
index_path = File.join(spa_path, "index.html")
puts "🚀 Opening SPA in browser..."
puts "   file://#{index_path}"
puts

system("open", index_path)

puts "=" * 80
puts "Demo Complete!"
puts "=" * 80
puts
puts "The SPA should now be open in your browser showing:"
puts "  ✓ Package: ModelRoot::i-UR::uro"
puts "  ✓ Class: Building (featureType)"
puts "  ✓ Attributes: 3 total (2 resolved, 1 unresolved)"
puts "  ✓ Statistics: 66.7% resolution rate"
puts "  ✓ Interactive navigation and search"
puts "  ✓ Works offline (data embedded in HTML)"
puts
