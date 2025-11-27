# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/application/spa_workflow"
require "fileutils"
require "tempfile"

RSpec.describe Lutaml::Klin::Application::SpaWorkflow do
  let(:workflow) { described_class.new }
  let(:schema_mapping) { create_test_schema_mapping }
  let(:output_path) { Dir.mktmpdir }

  after { FileUtils.rm_rf(output_path) }

  describe "#initialize" do
    it "creates workflow with default SPA generator" do
      workflow = described_class.new
      expect(workflow.spa_generator).to be_a(
        Lutaml::Klin::Domain::Services::SpaGenerator
      )
    end

    it "accepts custom SPA generator" do
      custom_generator = double("SpaGenerator")
      workflow = described_class.new(spa_generator: custom_generator)
      expect(workflow.spa_generator).to eq(custom_generator)
    end
  end

  describe "#generate_spa" do
    before do
      # Mock spa_generator methods
      allow(workflow.spa_generator).to receive(:generate_mappings_json)
        .and_return({ packages: [] })
      allow(workflow.spa_generator).to receive(:generate_search_index)
        .and_return({ index: [] })
      allow(workflow.spa_generator).to receive(:generate_statistics)
        .and_return({ summary: {} })
    end

    it "creates output directory structure" do
      workflow.generate_spa(schema_mapping, output_path)

      expect(Dir.exist?(output_path)).to be true
      expect(Dir.exist?(File.join(output_path, "data"))).to be true
      expect(Dir.exist?(File.join(output_path, "assets"))).to be true
      expect(Dir.exist?(File.join(output_path, "assets", "css"))).to be true
      expect(Dir.exist?(File.join(output_path, "assets", "js"))).to be true
    end

    it "generates JSON data files" do
      workflow.generate_spa(schema_mapping, output_path)

      expect(File.exist?(File.join(output_path, "data", "mappings.json")))
        .to be true
      expect(File.exist?(File.join(output_path, "data", "search_index.json")))
        .to be true
      expect(File.exist?(File.join(output_path, "data", "statistics.json")))
        .to be true
    end

    it "generates HTML file" do
      workflow.generate_spa(schema_mapping, output_path)

      expect(File.exist?(File.join(output_path, "index.html"))).to be true
    end

    it "generates CSS file" do
      workflow.generate_spa(schema_mapping, output_path)

      expect(File.exist?(File.join(output_path, "assets", "css", "style.css")))
        .to be true
    end

    it "generates JavaScript file" do
      workflow.generate_spa(schema_mapping, output_path)

      expect(File.exist?(File.join(output_path, "assets", "js", "app.js")))
        .to be true
    end

    it "returns output path" do
      result = workflow.generate_spa(schema_mapping, output_path)
      expect(result).to eq(output_path)
    end

    it "defaults to embedded data mode" do
      workflow.generate_spa(schema_mapping, output_path)

      html_content = File.read(File.join(output_path, "index.html"))
      expect(html_content).to include("window.MAPPING_DATA")
    end

    it "supports linked data mode" do
      workflow.generate_spa(schema_mapping, output_path, data_mode: :linked)

      html_content = File.read(File.join(output_path, "index.html"))
      expect(html_content).not_to include("window.MAPPING_DATA")
    end

    it "accepts custom title" do
      workflow.generate_spa(schema_mapping, output_path, title: "Custom Title")

      html_content = File.read(File.join(output_path, "index.html"))
      expect(html_content).to include("Custom Title")
    end

    it "raises error on generation failure" do
      allow(FileUtils).to receive(:mkdir_p).and_raise(StandardError, "Test error")

      expect {
        workflow.generate_spa(schema_mapping, output_path)
      }.to raise_error(/Failed to generate SPA/)
    end
  end

  describe "private methods" do
    before do
      allow(workflow.spa_generator).to receive(:generate_mappings_json)
        .and_return({ packages: [] })
      allow(workflow.spa_generator).to receive(:generate_search_index)
        .and_return({ index: [] })
      allow(workflow.spa_generator).to receive(:generate_statistics)
        .and_return({ summary: {} })
    end

    describe "#create_directories" do
      it "creates all required directories" do
        workflow.send(:create_directories, output_path)

        expect(Dir.exist?(output_path)).to be true
        expect(Dir.exist?(File.join(output_path, "data"))).to be true
        expect(Dir.exist?(File.join(output_path, "assets"))).to be true
      end
    end

    describe "#generate_data_files" do
      it "generates all data files" do
        FileUtils.mkdir_p(File.join(output_path, "data"))
        workflow.send(:generate_data_files, schema_mapping, output_path)
        expect(File.exist?(File.join(output_path, "data", "mappings.json")))
          .to be true
        expect(File.exist?(File.join(output_path, "data", "search_index.json")))
          .to be true
        expect(File.exist?(File.join(output_path, "data", "statistics.json")))
          .to be true
      end

      it "returns data structures" do
        FileUtils.mkdir_p(File.join(output_path, "data"))
        result = workflow.send(
          :generate_data_files,
          schema_mapping,
          output_path
        )

        expect(result).to have_key(:mappings)
        expect(result).to have_key(:search_index)
        expect(result).to have_key(:statistics)
      end
    end

    describe "#generate_minimal_html" do
      it "generates valid HTML" do
        data = {
          mappings: { packages: [] },
          search_index: { index: [] },
          statistics: { summary: {} }
        }
        html = workflow.send(:generate_minimal_html, "Test", data, :embedded)

        expect(html).to include("<!DOCTYPE html>")
        expect(html).to include("Test")
        expect(html).to include("window.MAPPING_DATA")
      end

      it "supports linked mode" do
        data = {
          mappings: { packages: [] },
          search_index: { index: [] },
          statistics: { summary: {} }
        }
        html = workflow.send(:generate_minimal_html, "Test", data, :linked)

        expect(html).not_to include("window.MAPPING_DATA")
      end
    end

    describe "#generate_minimal_css" do
      it "generates valid CSS" do
        css = workflow.send(:generate_minimal_css)

        expect(css).to include(":root")
        expect(css).to include("--color-resolved")
        expect(css).to include(".search-container")
      end
    end

    describe "#generate_minimal_js" do
      it "generates valid JavaScript" do
        js = workflow.send(:generate_minimal_js)

        expect(js).to include("class MappingBrowserApp")
        expect(js).to include("async init()")
        expect(js).to include("loadData")
      end
    end

    describe "#write_json_file" do
      it "writes pretty JSON" do
        test_path = File.join(output_path, "test.json")
        data = { test: "value", nested: { key: 123 } }

        workflow.send(:write_json_file, test_path, data)

        expect(File.exist?(test_path)).to be true
        content = File.read(test_path)
        expect(content).to include("\"test\": \"value\"")
      end
    end
  end
end