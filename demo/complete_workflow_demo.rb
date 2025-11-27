#!/usr/bin/env ruby
# frozen_string_literal: true

# Complete LUR+LXR Workflow Demonstration for lutaml-klin
#
# This script demonstrates the complete workflow:
# 1. Build LUR package from XMI (requires lutaml gem)
# 2. Build LXR package from XSD (requires lutaml-xsd gem)
# 3. Run lutaml-klin process command
# 4. Open generated SPA website in browser

require "fileutils"

# Configuration
DEMO_DIR = File.expand_path(__dir__)
OUTPUT_DIR = File.join(DEMO_DIR, "output")
PKG_DIR = File.join(DEMO_DIR, "packages")

# Source files
XMI_FILE = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"
XSD_DIR = "/Users/mulgogi/src/mn/mn-samples-plateau/reference-docs/xsd/i-ur"
CONFIG_FILE = File.join(DEMO_DIR,
                        "../reference/shapechange-configs/ShapeChangeConfig_Plateau_uro.xml")

# Package outputs
LUR_PACKAGE = File.join(PKG_DIR, "plateau_uro.lur")
LXR_PACKAGE = File.join(PKG_DIR, "plateau_schemas.lxr")

puts "=" * 80
puts "lutaml-klin Complete Workflow Demonstration"
puts "=" * 80
puts

# Create directories
puts "📁 Creating directories..."
FileUtils.mkdir_p(PKG_DIR)
FileUtils.mkdir_p(OUTPUT_DIR)
puts "   ✓ #{PKG_DIR}"
puts "   ✓ #{OUTPUT_DIR}"
puts

# Step 1: Build LUR Package (if not exists)
puts "=" * 80
puts "Step 1: Build LUR Package from XMI"
puts "=" * 80
puts

if File.exist?(LUR_PACKAGE)
  puts "⚡ LUR package already exists: #{LUR_PACKAGE}"
  puts "   Skipping build (delete to rebuild)"
else
  puts "🔨 Building LUR package..."
  puts "   Source: #{XMI_FILE}"
  puts "   Output: #{LUR_PACKAGE}"
  puts

  # NOTE: This requires lutaml gem to be installed
  # lutaml xmi package build XMI_PATH -o OUTPUT.lur
  puts "   Command:"
  cmd = <<~CMD
    cd #{File.dirname(XMI_FILE)} && \
    lutaml xmi package build "#{File.basename(XMI_FILE)}" \
      --output "#{LUR_PACKAGE}" \
      --name "PLATEAU URO Model" \
      --version "2024.1" \
      --format marshal
  CMD
  puts "   #{cmd}"
  puts

  puts "   ⚠️  NOTE: Requires 'lutaml' gem to be installed"
  puts "   Install with: gem install lutaml"
  puts "   (Skipping actual build for demo - package would be created here)"
end
puts

# Step 2: Build LXR Package (if not exists)
puts "=" * 80
puts "Step 2: Build LXR Package from XSD Schemas"
puts "=" * 80
puts

if File.exist?(LXR_PACKAGE)
  puts "⚡ LXR package already exists: #{LXR_PACKAGE}"
  puts "   Skipping build (delete to rebuild)"
else
  puts "🔨 Building LXR package..."
  puts "   Source: #{XSD_DIR}"
  puts "   Output: #{LXR_PACKAGE}"
  puts

  # NOTE: This requires lutaml-xsd gem to be installed
  # lutaml-xsd package build CONFIG.yaml -o OUTPUT.lxr
  puts "   Command:"
  cmd = <<~CMD
    lutaml-xsd package build config/plateau_uro_schemas.yaml \
      --output "#{LXR_PACKAGE}" \
      --name "PLATEAU URO Schemas" \
      --version "3.2" \
      --xsd-mode include_all \
      --resolution-mode resolved \
      --serialization-format marshal
  CMD
  puts "   #{cmd}"
  puts

  puts "   ⚠️  NOTE: Requires 'lutaml-xsd' gem to be installed"
  puts "   Install with: gem install lutaml-xsd"
  puts "   (Skipping actual build for demo - package would be created here)"
end
puts

# Step 3: Run lutaml-klin Process Command
puts "=" * 80
puts "Step 3: Run lutaml-klin Process Command"
puts "=" * 80
puts

puts "🚀 This would execute the unified process command:"
puts

cmd = <<~CMD
  bundle exec lutaml-klin process \
    --lur "#{LUR_PACKAGE}" \
    --lxr "#{LXR_PACKAGE}" \
    --config "#{CONFIG_FILE}" \
    --packages "ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.2::uro" \
    --output "#{OUTPUT_DIR}" \
    --type-overrides config/type_overrides.yaml \
    --generate-mappings \
    --generate-spa \
    --validate \
    --verbose
CMD

puts cmd
puts

puts "📊 Expected Processing Stages:"
puts "   [1/7] 📦  Loading UML repository from LUR package... (<100ms)"
puts "   [2/7] 📦  Loading XSD repository from LXR package... (<100ms)"
puts "   [3/7] ⚙️  Loading ShapeChange configuration..."
puts "   [4/7] 🔍  Filtering packages with pattern..."
puts "   [5/7] 🗺️  Generating UML-to-XSD mappings..."
puts "   [6/7] ✅  Validating mappings and generating reports..."
puts "   [7/7] 🌐  Generating SPA website..."
puts

puts "💾 Expected Outputs:"
puts "   #{OUTPUT_DIR}/"
puts "   ├── mappings/"
puts "   │   ├── schema_mapping.yaml          # Complete schema mapping"
puts "   │   └── uro.yaml                     # URO package mapping"
puts "   ├── validation/"
puts "   │   ├── validation_report.json      # Machine-readable report"
puts "   │   └── validation_report.md        # Human-readable report"
puts "   └── spa/"
puts "       ├── index.html                  # SPA entry point"
puts "       ├── data/"
puts "       │   ├── mappings.json           # All mappings in JSON"
puts "       │   ├── search_index.json       # Search index"
puts "       │   └── statistics.json         # Statistics"
puts "       └── assets/"
puts "           ├── css/style.css           # Responsive styling"
puts "           └── js/app.js               # Interactive application"
puts

# Step 4: Create Demo SPA (Using Test Fixtures)
puts "=" * 80
puts "Step 4: Generate Demo SPA from Test Data"
puts "=" * 80
puts

demo_script = File.join(DEMO_DIR, "generate_demo_spa.rb")

File.write(demo_script, <<~RUBY)
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

  puts "✓ SPA generated at: \#{output_path}"
  puts
  puts "Open in browser:"
  puts "  file://\#{output_path}"
RUBY

puts "📝 Created demo SPA generator script:"
puts "   #{demo_script}"
puts

puts "🎬 Run the demo:"
puts "   ruby #{demo_script}"
puts

# Instructions for opening SPA
puts "=" * 80
puts "Step 5: Open SPA Website in Browser"
puts "=" * 80
puts

spa_index = File.join(OUTPUT_DIR, "spa/index.html")
puts "🌐 After generation, open the SPA in your browser:"
puts

if File.exist?(spa_index)
  puts "   file://#{spa_index}"
  puts
  puts "   Or run: open #{spa_index}"
else
  puts "   file://#{spa_index} (will exist after running demo script)"
end

puts
puts "=" * 80
puts "Demo Preparation Complete!"
puts "=" * 80
puts

puts "Next Steps:"
puts "1. Ensure lutaml and lutaml-xsd gems are installed"
puts "2. Build LUR package: lutaml xmi package build #{XMI_FILE}"
puts "3. Build LXR package: lutaml-xsd package build config.yaml"
puts "4. Run demo: ruby #{demo_script}"
puts "5. Open SPA in browser"
puts
puts "For quick demo without building packages, run:"
puts "   ruby #{demo_script}"
puts
