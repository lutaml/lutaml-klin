# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "yaml"
require "json"

RSpec.describe "Output Generation Integration", :integration do
  let(:output_dir) { File.join(__dir__, "../../tmp/output_generation_test") }

  before do
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
  end

  describe "YAML mapping generation" do
    let(:package_mapping) do
      Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
        pm.uml_name = "TestPackage"
        pm.uml_package_name = "ModelRoot::TestPackage"
        pm.xsd_namespace = "http://example.org/test"
        pm.xsd_namespace_prefix = "test"
        pm.xsd_schema_location = "test.xsd"
        pm.created_at = "2024-01-01T00:00:00Z"

        # Add a class mapping
        class_mapping = Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
          cm.uml_name = "TestClass"
          cm.uml_qualified_name = "ModelRoot::TestPackage::TestClass"
          cm.uml_stereotype = "featureType"
          cm.uml_documentation = "Test class documentation"
          cm.xsd_namespace = "http://example.org/test"
          cm.xsd_element_name = "TestClass"
          cm.xsd_type_name = "TestClassType"
          cm.xsd_documentation = "XSD documentation"
          cm.resolution_status = "resolved"
          cm.resolution_method = "shapechange_mapping"
          cm.resolution_confidence = "high"

          # Add attribute mappings
          attr1 = Lutaml::Klin::Mapping::AttributeMapping.new.tap do |am|
            am.uml_name = "id"
            am.uml_type = "Integer"
            am.uml_multiplicity = "1"
            am.xsd_name = "id"
            am.xsd_type = "xs:integer"
            am.xsd_min_occurs = "1"
            am.xsd_max_occurs = "1"
            am.resolution_status = "resolved"
            am.resolution_method = "shapechange_mapping"
          end

          attr2 = Lutaml::Klin::Mapping::AttributeMapping.new.tap do |am|
            am.uml_name = "name"
            am.uml_type = "String"
            am.uml_multiplicity = "1"
            am.xsd_name = "name"
            am.xsd_type = "xs:string"
            am.xsd_min_occurs = "1"
            am.xsd_max_occurs = "1"
            am.resolution_status = "resolved"
            am.resolution_method = "xsd_lookup"
          end

          cm.attribute_mappings = [attr1, attr2]
        end

        pm.class_mappings = [class_mapping]
        pm.resolution_statistics = pm.calculate_statistics.to_yaml
      end
    end

    let(:schema_mapping) do
      Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.version = "1.0"
        sm.package_mappings = [package_mapping]
        sm.set_timestamp!
        sm.namespaces = ["http://example.org/test"]
      end
    end

    it "generates valid YAML structure" do
      yaml_path = File.join(output_dir, "mapping.yaml")
      yaml_content = schema_mapping.to_yaml

      File.write(yaml_path, yaml_content)

      expect(File.exist?(yaml_path)).to be true
      expect(File.size(yaml_path)).to be > 0

      # Verify YAML structure
      expect(yaml_content).to include("version:")
      expect(yaml_content).to include("generated_at:")
      expect(yaml_content).to include("package_mappings:")
      expect(yaml_content).to include("uml_package_name:")
      expect(yaml_content).to include("TestPackage")
    end

    it "can be reloaded from YAML" do
      yaml_path = File.join(output_dir, "reloadable.yaml")
      File.write(yaml_path, schema_mapping.to_yaml)

      # Reload YAML
      loaded_yaml = YAML.safe_load(
        File.read(yaml_path),
        permitted_classes: [Symbol, Time],
        aliases: true
      )

      expect(loaded_yaml).to be_a(Hash)
      expect(loaded_yaml).to have_key("version")
      expect(loaded_yaml["package_mappings"]).to be_an(Array)
      expect(loaded_yaml["package_mappings"].first["uml_name"])
        .to eq("TestPackage")
    end

    it "includes all mapping details" do
      yaml_content = schema_mapping.to_yaml

      # Verify package details
      expect(yaml_content).to include("uml_package_name: ModelRoot::TestPackage")
      expect(yaml_content).to include("xsd_namespace: http://example.org/test")
      expect(yaml_content).to include("xsd_namespace_prefix: test")

      # Verify class details
      expect(yaml_content).to include("uml_name: TestClass")
      expect(yaml_content).to include("uml_stereotype: featureType")
      expect(yaml_content).to include("resolution_status: resolved")

      # Verify attribute details
      expect(yaml_content).to include("- uml_name: id")
      expect(yaml_content).to include("uml_type: Integer")
      expect(yaml_content).to include("xsd_type: xs:integer")
    end

    it "includes resolution statistics" do
      yaml_content = schema_mapping.to_yaml

      expect(yaml_content).to include("resolution_statistics:")

      # Parse to verify statistics
      loaded = YAML.safe_load(
        yaml_content,
        permitted_classes: [Symbol, Time],
        aliases: true
      )
      pkg = loaded["package_mappings"].first
      stats_yaml = pkg["resolution_statistics"]
      stats = YAML.safe_load(stats_yaml, permitted_classes: [Symbol])

      expect(stats["total_classes"]).to eq(1)
      expect(stats["total_attributes"]).to eq(2)
      expect(stats["resolved_attributes"]).to eq(2)
    end
  end

  describe "validation report generation" do
    let(:validation_result) do
      Lutaml::Klin::Domain::ValidationResult.new(
        summary: {
          total_packages: 1,
          total_classes: 2,
          resolved_classes: 1,
          partial_classes: 1,
          unresolved_classes: 0,
          total_attributes: 5,
          resolved_attributes: 3,
          partial_attributes: 1,
          unresolved_attributes: 1,
          resolution_rate: 50.0,
          attribute_resolution_rate: 60.0,
        },
        unresolved_items: [
          {
            type: "attribute",
            package: "TestPackage",
            class: "TestClass",
            attribute: "unknownAttr",
            uml_type: "UnknownType",
            status: "unresolved",
            error: "Type not found in repository",
            suggestions: [
              "Check namespace mappings",
              "Verify type exists",
            ],
          },
        ],
        packages: [
          {
            name: "TestPackage",
            namespace: "http://example.org/test",
            resolution_rate: 50.0,
            classes: [
              {
                name: "TestClass",
                status: "partial",
                attributes: [],
              },
            ],
          },
        ],
        generated_at: "2024-01-01T00:00:00Z"
      )
    end

    it "generates valid JSON report" do
      json_path = File.join(output_dir, "validation.json")
      reporter = Lutaml::Klin::Domain::Reporters::JsonReporter.new

      result_path = reporter.generate(validation_result, json_path)

      expect(result_path).to eq(json_path)
      expect(File.exist?(json_path)).to be true

      # Verify JSON is valid
      json_data = JSON.parse(File.read(json_path))
      expect(json_data).to have_key("summary")
      expect(json_data).to have_key("unresolved_items")
      expect(json_data).to have_key("packages")
    end

    it "generates formatted Markdown report" do
      md_path = File.join(output_dir, "validation.md")
      reporter = Lutaml::Klin::Domain::Reporters::MarkdownReporter.new

      result_path = reporter.generate(validation_result, md_path)

      expect(result_path).to eq(md_path)
      expect(File.exist?(md_path)).to be true

      # Verify Markdown content
      md_content = File.read(md_path)
      expect(md_content).to include("# Validation Report")
      expect(md_content).to include("## Summary Statistics")
      expect(md_content).to include("Total Packages:")
      expect(md_content).to include("Resolution Rate:")
    end

    it "includes all validation details in JSON" do
      json_path = File.join(output_dir, "detailed_validation.json")
      reporter = Lutaml::Klin::Domain::Reporters::JsonReporter.new
      reporter.generate(validation_result, json_path)

      json_data = JSON.parse(File.read(json_path))

      # Check summary
      expect(json_data["summary"]["total_classes"]).to eq(2)
      expect(json_data["summary"]["resolution_rate"]).to eq(50.0)

      # Check unresolved items
      expect(json_data["unresolved_items"]).to be_an(Array)
      expect(json_data["unresolved_items"].first["attribute"]).to eq("unknownAttr")
      expect(json_data["unresolved_items"].first["suggestions"]).to be_an(Array)

      # Check packages
      expect(json_data["packages"]).to be_an(Array)
      expect(json_data["packages"].first["name"]).to eq("TestPackage")
    end

    it "includes all validation details in Markdown" do
      md_path = File.join(output_dir, "detailed_validation.md")
      reporter = Lutaml::Klin::Domain::Reporters::MarkdownReporter.new
      reporter.generate(validation_result, md_path)

      md_content = File.read(md_path)

      # Check structure
      expect(md_content).to include("## Summary Statistics")
      expect(md_content).to include("## Unresolved Items")
      expect(md_content).to include("## Package Details")

      # Check unresolved items
      expect(md_content).to include("unknownAttr")
      expect(md_content).to include("UnknownType")
      expect(md_content).to include("Suggestions:")

      # Check statistics
      expect(md_content).to include("Total Classes: 2")
      expect(md_content).to include("Resolution Rate: 50.0%")
    end
  end

  describe "SPA website generation" do
    let(:schema_mapping) do
      pkg = Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
        pm.uml_name = "SpaTest"
        pm.uml_package_name = "ModelRoot::SpaTest"
        pm.xsd_namespace = "http://example.org/spa"
        pm.xsd_namespace_prefix = "spa"

        cls = Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
          cm.uml_name = "SpaClass"
          cm.uml_stereotype = "featureType"
          cm.resolution_status = "resolved"
          cm.attribute_mappings = []
        end

        pm.class_mappings = [cls]
      end

      Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.version = "1.0"
        sm.package_mappings = [pkg]
        sm.set_timestamp!
      end
    end

    let(:spa_generator) { Lutaml::Klin::Domain::Services::SpaGenerator.new }

    it "generates mappings JSON data file" do
      mappings_json = spa_generator.generate_mappings_json(schema_mapping)
      json_path = File.join(output_dir, "mappings.json")

      File.write(json_path, JSON.pretty_generate(mappings_json))

      expect(File.exist?(json_path)).to be true

      # Verify JSON structure
      parsed = JSON.parse(File.read(json_path))
      expect(parsed["version"]).to eq("1.0")
      expect(parsed["packages"]).to be_an(Array)
      expect(parsed["packages"].first["name"]).to eq("SpaTest")
    end

    it "generates search index JSON" do
      search_index = spa_generator.generate_search_index(schema_mapping)
      json_path = File.join(output_dir, "search-index.json")

      File.write(json_path, JSON.pretty_generate(search_index))

      expect(File.exist?(json_path)).to be true

      # Verify search index structure
      parsed = JSON.parse(File.read(json_path))
      expect(parsed["index"]).to be_an(Array)

      # Should have entries for package and class
      expect(parsed["index"].size).to be >= 2

      # Verify search entry fields
      first_entry = parsed["index"].first
      expect(first_entry).to have_key("id")
      expect(first_entry).to have_key("type")
      expect(first_entry).to have_key("title")
      expect(first_entry).to have_key("keywords")
    end

    it "generates statistics JSON" do
      stats = spa_generator.generate_statistics(schema_mapping)
      json_path = File.join(output_dir, "statistics.json")

      File.write(json_path, JSON.pretty_generate(stats))

      expect(File.exist?(json_path)).to be true

      # Verify statistics structure
      parsed = JSON.parse(File.read(json_path))
      expect(parsed["summary"]).to be_a(Hash)
      expect(parsed["packages"]).to be_an(Array)

      # Check summary fields
      expect(parsed["summary"]).to have_key("total_packages")
      expect(parsed["summary"]).to have_key("total_classes")
      expect(parsed["summary"]).to have_key("resolution_rate")
    end

    it "generates all SPA data files with correct structure" do
      # Generate all three data files
      mappings_json = spa_generator.generate_mappings_json(schema_mapping)
      search_index = spa_generator.generate_search_index(schema_mapping)
      statistics = spa_generator.generate_statistics(schema_mapping)

      # Save them
      File.write(
        File.join(output_dir, "mappings.json"),
        JSON.pretty_generate(mappings_json)
      )
      File.write(
        File.join(output_dir, "search-index.json"),
        JSON.pretty_generate(search_index)
      )
      File.write(
        File.join(output_dir, "statistics.json"),
        JSON.pretty_generate(statistics)
      )

      # Verify all files exist
      expect(File.exist?(File.join(output_dir, "mappings.json"))).to be true
      expect(File.exist?(File.join(output_dir, "search-index.json"))).to be true
      expect(File.exist?(File.join(output_dir, "statistics.json"))).to be true

      # Verify all are valid JSON
      expect do
        JSON.parse(File.read(File.join(output_dir, "mappings.json")))
        JSON.parse(File.read(File.join(output_dir, "search-index.json")))
        JSON.parse(File.read(File.join(output_dir, "statistics.json")))
      end.not_to raise_error
    end

    it "includes searchable keywords in search index" do
      search_index = spa_generator.generate_search_index(schema_mapping)

      # Find class entry
      class_entry = search_index[:index].find { |e| e[:type] == "class" }

      expect(class_entry).not_to be_nil
      expect(class_entry[:keywords]).to be_an(Array)
      expect(class_entry[:keywords]).not_to be_empty

      # Keywords should be lowercase
      expect(class_entry[:keywords].all? { |k| k == k.downcase }).to be true
    end
  end

  describe "output file error handling" do
    it "raises error when output directory doesn't exist" do
      non_existent_dir = "/non/existent/directory"
      yaml_path = File.join(non_existent_dir, "mapping.yaml")

      schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new

      expect do
        File.write(yaml_path, schema_mapping.to_yaml)
      end.to raise_error(Errno::ENOENT)
    end

    it "handles write permission errors gracefully" do
      skip "Difficult to test without changing permissions"
    end
  end

  describe "comprehensive output workflow" do
    let(:complete_mapping) do
      pkg = Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
        pm.uml_name = "Complete"
        pm.uml_package_name = "ModelRoot::Complete"
        pm.xsd_namespace = "http://example.org/complete"
        pm.xsd_namespace_prefix = "cmp"

        cls = Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
          cm.uml_name = "CompleteClass"
          cm.resolution_status = "resolved"
          cm.resolution_method = "shapechange_mapping"

          attr = Lutaml::Klin::Mapping::AttributeMapping.new.tap do |am|
            am.uml_name = "attr1"
            am.uml_type = "String"
            am.xsd_type = "xs:string"
            am.resolution_status = "resolved"
          end

          cm.attribute_mappings = [attr]
        end

        pm.class_mappings = [cls]
      end

      Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.version = "1.0"
        sm.package_mappings = [pkg]
        sm.set_timestamp!
      end
    end

    it "generates all output types in one workflow" do
      # 1. Generate YAML mapping
      yaml_path = File.join(output_dir, "complete_mapping.yaml")
      File.write(yaml_path, complete_mapping.to_yaml)

      # 2. Generate validation reports
      validation_service = Lutaml::Klin::Domain::Services::ValidationService.new
      validation_result = validation_service.validate(complete_mapping)

      json_reporter = Lutaml::Klin::Domain::Reporters::JsonReporter.new
      md_reporter = Lutaml::Klin::Domain::Reporters::MarkdownReporter.new

      json_path = File.join(output_dir, "validation.json")
      md_path = File.join(output_dir, "validation.md")

      json_reporter.generate(validation_result, json_path)
      md_reporter.generate(validation_result, md_path)

      # 3. Generate SPA data files
      spa_generator = Lutaml::Klin::Domain::Services::SpaGenerator.new

      mappings_data = spa_generator.generate_mappings_json(complete_mapping)
      search_data = spa_generator.generate_search_index(complete_mapping)
      stats_data = spa_generator.generate_statistics(complete_mapping)

      File.write(
        File.join(output_dir, "spa_mappings.json"),
        JSON.pretty_generate(mappings_data)
      )
      File.write(
        File.join(output_dir, "spa_search.json"),
        JSON.pretty_generate(search_data)
      )
      File.write(
        File.join(output_dir, "spa_stats.json"),
        JSON.pretty_generate(stats_data)
      )

      # Verify all files created
      expect(File.exist?(yaml_path)).to be true
      expect(File.exist?(json_path)).to be true
      expect(File.exist?(md_path)).to be true
      expect(File.exist?(File.join(output_dir, "spa_mappings.json"))).to be true
      expect(File.exist?(File.join(output_dir, "spa_search.json"))).to be true
      expect(File.exist?(File.join(output_dir, "spa_stats.json"))).to be true

      # Verify content validity
      expect(YAML.safe_load(File.read(yaml_path), permitted_classes: [Symbol, Time]))
        .to be_a(Hash)
      expect(JSON.parse(File.read(json_path))).to be_a(Hash)
      expect(File.read(md_path)).to include("# Validation Report")
      expect(JSON.parse(File.read(File.join(output_dir, "spa_mappings.json"))))
        .to be_a(Hash)
    end
  end
end