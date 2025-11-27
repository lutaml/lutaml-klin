#!/usr/bin/env ruby
# frozen_string_literal: true

# This script generates a demo SPA website using test fixtures
# to demonstrate the output format and functionality

require "bundler/setup"
require "lutaml/klin"
require "lutaml/klin/application/spa_workflow"
require "lutaml/klin/models/mapping/schema_mapping"

# Create sample mapping data
schema_mapping = Lutaml::Klin::Models::Mapping::SchemaMapping.new
schema_mapping.version = "1.0"
schema_mapping.generated_at = Time.now.utc.iso8601
schema_mapping.source_lur = "plateau_uro.lur"
schema_mapping.source_lxr = "plateau_schemas.lxr"
schema_mapping.source_config = "ShapeChangeConfig_Plateau_uro.xml"

# Add sample package mapping
package = Lutaml::Klin::Models::Mapping::PackageMapping.new
package.uml_package_path = "ModelRoot::i-UR::uro"
package.xsd_namespace = "https://www.geospatial.jp/iur/uro/3.2"

# Add sample class mapping
class_mapping = Lutaml::Klin::Models::Mapping::ClassMapping.new
class_mapping.uml_class_name = "Building"
class_mapping.uml_qualified_name = "ModelRoot::i-UR::uro::Building"
class_mapping.uml_stereotype = "featureType"
class_mapping.uml_documentation = "Represents a building feature in urban areas"
class_mapping.xsd_element_name = "uro:Building"
class_mapping.xsd_type_name = "uro:BuildingType"
class_mapping.xsd_namespace = "https://www.geospatial.jp/iur/uro/3.2"
class_mapping.xsd_documentation = "Complex type for building features"
class_mapping.resolution_status = "resolved"
class_mapping.resolution_method = "schema_repository"
class_mapping.resolution_confidence = 0.95

# Add sample attribute mappings
attr1 = Lutaml::Klin::Models::Mapping::AttributeMapping.new
attr1.uml_attribute_name = "buildingType"
attr1.uml_type = "gml::CodeType"
attr1.uml_multiplicity = "0..1"
attr1.xsd_element_name = "uro:buildingType"
attr1.xsd_type_name = "gml:CodeType"
attr1.xsd_namespace = "http://www.opengis.net/gml/3.2"
attr1.xsd_min_occurs = "0"
attr1.xsd_max_occurs = "1"
attr1.resolution_status = "resolved"
attr1.resolution_method = "schema_repository"

attr2 = Lutaml::Klin::Models::Mapping::AttributeMapping.new
attr2.uml_attribute_name = "height"
attr2.uml_type = "Measure"
attr2.uml_multiplicity = "0..1"
attr2.xsd_element_name = "uro:height"
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
attr3.resolution_status = "unresolved"
attr3.resolution_error = "Type not found in XSD repository"

class_mapping.attribute_mappings = [attr1, attr2, attr3]
package.class_mappings = [class_mapping]
schema_mapping.package_mappings = [package]

# Generate SPA
puts "Generating demo SPA website..."
workflow = Lutaml::Klin::Application::SpaWorkflow.new
output_path = workflow.generate_spa(
  schema_mapping,
  File.join(__dir__, "output/spa"),
  title: "PLATEAU URO Mapping Demo"
)

puts "✓ SPA generated at: #{output_path}"
puts
puts "Open in browser:"
puts "  file://#{output_path}"
