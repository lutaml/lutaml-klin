# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "lutaml/klin/application/spa_workflow"
require "lutaml/klin/models/mapping/schema_mapping"
require "lutaml/klin/models/mapping/package_mapping"
require "lutaml/klin/models/mapping/class_mapping"
require "lutaml/klin/models/mapping/attribute_mapping"

RSpec.describe Lutaml::Klin::Application::SpaWorkflow do
  subject(:workflow) { described_class.new }

  let(:schema_mapping) do
    Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
      sm.version = "1.0"
      sm.generated_at = "2024-01-01T00:00:00Z"
      sm.package_mappings = [package_mapping]
      sm.namespaces = ["http://example.org/test"]
    end
  end

  let(:package_mapping) do
    Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
      pm.uml_name = "TestPackage"
      pm.uml_package_name = "Model::TestPackage"
      pm.xsd_namespace = "http://example.org/test"
      pm.xsd_namespace_prefix = "test"
      pm.class_mappings = [class_mapping]
    end
  end

  let(:class_mapping) do
    Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
      cm.uml_name = "TestClass"
      cm.uml_qualified_name = "Model::TestPackage::TestClass"
      cm.xsd_type_name = "test:TestClassType"
      cm.resolution_status = "resolved"
      cm.resolution_method = "shapechange"
      cm.attribute_mappings = [attribute_mapping]
    end
  end

  let(:attribute_mapping) do
    Lutaml::Klin::Mapping::AttributeMapping.new.tap do |am|
      am.uml_name = "testAttribute"
      am.uml_type = "CharacterString"
      am.xsd_type = "xs:string"
      am.resolution_status = "resolved"
    end
  end

  around do |example|
    Dir.mktmpdir do |dir|
      @output_dir = dir
      example.run
    end
  end

  describe "#generate_spa" do
    let(:output_path) { File.join(@output_dir, "spa") }

    it "creates the SPA directory structure" do
      workflow.generate_spa(schema_mapping, output_path)

      expect(File.directory?(output_path)).to be true
      expect(File.directory?(File.join(output_path, "data"))).to be true
      expect(File.directory?(File.join(output_path, "assets"))).to be true
      expect(File.directory?(File.join(output_path, "assets", "css"))).to be true
      expect(File.directory?(File.join(output_path, "assets", "js"))).to be true
    end

    it "generates all required JSON data files" do
      workflow.generate_spa(schema_mapping, output_path)

      mappings_file = File.join(output_path, "data", "mappings.json")
      search_index_file = File.join(output_path, "data", "search_index.json")
      statistics_file = File.join(output_path, "data", "statistics.json")

      expect(File.exist?(mappings_file)).to be true
      expect(File.exist?(search_index_file)).to be true
      expect(File.exist?(statistics_file)).to be true
    end

    it "generates valid JSON in data files" do
      workflow.generate_spa(schema_mapping, output_path)

      mappings = JSON.parse(File.read(File.join(output_path, "data", "mappings.json")))
      expect(mappings["version"]).to eq("1.0")
      expect(mappings["packages"]).to be_an(Array)

      search_index = JSON.parse(File.read(File.join(output_path, "data", "search_index.json")))
      expect(search_index["index"]).to be_an(Array)

      statistics = JSON.parse(File.read(File.join(output_path, "data", "statistics.json")))
      expect(statistics["summary"]).to be_a(Hash)
    end

    it "generates HTML file" do
      workflow.generate_spa(schema_mapping, output_path)

      html_file = File.join(output_path, "index.html")
      expect(File.exist?(html_file)).to be true

      html_content = File.read(html_file)
      expect(html_content).to include("<!DOCTYPE html>")
      expect(html_content).to include("UML-XSD Mapping Browser")
      expect(html_content).to include("assets/css/style.css")
      expect(html_content).to include("assets/js/app.js")
    end

    it "generates CSS file" do
      workflow.generate_spa(schema_mapping, output_path)

      css_file = File.join(output_path, "assets", "css", "style.css")
      expect(File.exist?(css_file)).to be true

      css_content = File.read(css_file)
      expect(css_content).to include(":root")
      expect(css_content).to include("--color-resolved")
      expect(css_content).to include(".badge-resolved")
    end

    it "generates JavaScript file" do
      workflow.generate_spa(schema_mapping, output_path)

      js_file = File.join(output_path, "assets", "js", "app.js")
      expect(File.exist?(js_file)).to be true

      js_content = File.read(js_file)
      expect(js_content).to include("class MappingBrowserApp")
      expect(js_content).to include("loadData")
      expect(js_content).to include("renderPackageTree")
    end

    it "returns the output path" do
      result = workflow.generate_spa(schema_mapping, output_path)
      expect(result).to eq(output_path)
    end

    it "accepts custom options" do
      result = workflow.generate_spa(
        schema_mapping,
        output_path,
        title: "Custom Title",
        description: "Custom Description"
      )

      expect(result).to eq(output_path)
      expect(File.exist?(File.join(output_path, "index.html"))).to be true
    end

    context "when output directory already exists" do
      it "overwrites existing files" do
        # Create initial SPA
        workflow.generate_spa(schema_mapping, output_path)

        # Modify a file
        test_file = File.join(output_path, "data", "mappings.json")
        File.write(test_file, '{"test": "old"}')

        # Generate again
        workflow.generate_spa(schema_mapping, output_path)

        # Verify file was overwritten
        content = JSON.parse(File.read(test_file))
        expect(content["test"]).to be_nil
        expect(content["version"]).to eq("1.0")
      end
    end

    context "with custom SPA generator" do
      let(:custom_generator) do
        double("SpaGenerator",
               generate_mappings_json: { test: "mappings" },
               generate_search_index: { test: "index" },
               generate_statistics: { test: "stats" })
      end

      let(:workflow) { described_class.new(spa_generator: custom_generator) }

      it "uses the custom generator" do
        workflow.generate_spa(schema_mapping, output_path)

        mappings = JSON.parse(File.read(File.join(output_path, "data", "mappings.json")))
        expect(mappings["test"]).to eq("mappings")

        expect(custom_generator).to have_received(:generate_mappings_json).with(schema_mapping)
        expect(custom_generator).to have_received(:generate_search_index).with(schema_mapping)
        expect(custom_generator).to have_received(:generate_statistics).with(schema_mapping)
      end
    end
  end

  describe "error handling" do
    let(:output_path) { File.join(@output_dir, "spa") }

    context "when directory creation fails" do
      it "raises an error with helpful message" do
        # Make the parent directory read-only to cause a failure
        FileUtils.chmod(0o444, @output_dir)

        expect {
          workflow.generate_spa(schema_mapping, output_path)
        }.to raise_error(RuntimeError, /Failed to generate SPA/)

        # Restore permissions for cleanup
        FileUtils.chmod(0o755, @output_dir)
      end
    end

    context "when JSON generation fails" do
      let(:broken_generator) do
        double("SpaGenerator").tap do |gen|
          allow(gen).to receive(:generate_mappings_json).and_raise(StandardError, "JSON error")
          allow(gen).to receive(:generate_search_index).and_return({})
          allow(gen).to receive(:generate_statistics).and_return({})
        end
      end

      let(:workflow) { described_class.new(spa_generator: broken_generator) }

      it "raises an error" do
        expect {
          workflow.generate_spa(schema_mapping, output_path)
        }.to raise_error(RuntimeError, /Failed to generate SPA/)
      end
    end
  end

  describe "template file handling" do
    let(:output_path) { File.join(@output_dir, "spa") }

    context "when templates exist" do
      before do
        # Create mock template directory
        template_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "lutaml", "klin", "templates", "spa")
        allow(File).to receive(:directory?).and_call_original
        allow(File).to receive(:directory?).with(template_dir).and_return(true)
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(File.join(template_dir, "index.html")).and_return(true)
        allow(FileUtils).to receive(:cp).and_call_original
      end

      it "attempts to copy template files" do
        # This test verifies the workflow tries to use templates when available
        # The actual copying is mocked to avoid file system dependencies
        workflow.generate_spa(schema_mapping, output_path)

        expect(File.exist?(File.join(output_path, "index.html"))).to be true
      end
    end
  end

  describe "integration" do
    let(:output_path) { File.join(@output_dir, "complete_spa") }

    it "generates a complete, functional SPA" do
      workflow.generate_spa(schema_mapping, output_path)

      # Verify all files exist
      expect(File.exist?(File.join(output_path, "index.html"))).to be true
      expect(File.exist?(File.join(output_path, "data", "mappings.json"))).to be true
      expect(File.exist?(File.join(output_path, "data", "search_index.json"))).to be true
      expect(File.exist?(File.join(output_path, "data", "statistics.json"))).to be true
      expect(File.exist?(File.join(output_path, "assets", "css", "style.css"))).to be true
      expect(File.exist?(File.join(output_path, "assets", "js", "app.js"))).to be true

      # Verify JSON data integrity
      mappings = JSON.parse(File.read(File.join(output_path, "data", "mappings.json")))
      expect(mappings["packages"].first["classes"].first["uml_name"]).to eq("TestClass")

      search_index = JSON.parse(File.read(File.join(output_path, "data", "search_index.json")))
      class_entry = search_index["index"].find { |e| e["type"] == "class" }
      expect(class_entry["title"]).to eq("TestClass")

      statistics = JSON.parse(File.read(File.join(output_path, "data", "statistics.json")))
      expect(statistics["summary"]["total_classes"]).to eq(1)
    end
  end
end