# frozen_string_literal: true

require "spec_helper"
require "json"
require "fileutils"

RSpec.describe "Multi-Schema SPA Integration", type: :integration do
  let(:uro_mapping) { "test_workflow/step1_uro/urbanObject_mapping.yaml" }
  let(:urf_mapping) { "test_workflow/step1_urf/urbanFunction_mapping.yaml" }
  let(:output_dir) { "tmp/multi_schema_spa_test" }

  before do
    skip "URF mapping not available" unless File.exist?(urf_mapping)
    
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
  end

  describe "Multi-Schema Generation" do
    it "generates SPA from multiple mapping files" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      output = `#{cmd} 2>&1`
      expect($CHILD_STATUS.exitstatus).to eq(0), "Generation failed: #{output}"
      
      expect(File).to exist(File.join(output_dir, "index.html"))
      expect(File).to exist(File.join(output_dir, "data", "mappings.json"))
    end

    it "merges classes by UML qualified name" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      system(cmd)
      
      data = JSON.parse(File.read(File.join(output_dir, "data", "mappings.json")))
      classes = data["classes"]
      
      # Find a class that should exist in both schemas
      multi_schema_class = classes.values.find do |cls|
        cls["schemas"] && cls["schemas"].size > 1
      end
      
      expect(multi_schema_class).not_to be_nil, "No multi-schema classes found"
      expect(multi_schema_class["schemas"]).to be_an(Array)
      expect(multi_schema_class["schemas"].size).to be >= 2
    end

    it "includes schema names in multi-schema classes" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      system(cmd)
      
      data = JSON.parse(File.read(File.join(output_dir, "data", "mappings.json")))
      multi_schema_class = data["classes"].values.find do |cls|
        cls["schemas"]&.size.to_i > 1
      end
      
      schemas = multi_schema_class["schemas"]
      schema_names = schemas.map { |s| s["schema_name"] }
      
      expect(schema_names).to include("URO")
      expect(schema_names).to include("URF")
    end

    it "generates separate XML instances per schema" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      system(cmd)
      
      data = JSON.parse(File.read(File.join(output_dir, "data", "mappings.json")))
      multi_schema_class = data["classes"].values.find do |cls|
        cls["schemas"]&.size.to_i > 1
      end
      
      schemas = multi_schema_class["schemas"]
      
      schemas.each do |schema|
        expect(schema).to have_key("xml_instance")
        expect(schema["xml_instance"]).to include("<?xml")
        expect(schema["xml_instance"]).to include(schema["xsd_namespace"])
      end
    end

    it "includes schema selector UI in HTML" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      system(cmd)
      
      html = File.read(File.join(output_dir, "index.html"))
      
      # Check for schema selector elements
      expect(html).to include("schema-selector")
      expect(html).to include("schema-tabs")
      expect(html).to include("selectedSchemaIndex")
    end

    it "preserves backward compatibility with single-schema mode" do
      # Test with single mapping file
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--output #{output_dir}"
      
      output = `#{cmd} 2>&1`
      expect($CHILD_STATUS.exitstatus).to eq(0), "Single-schema generation failed: #{output}"
      
      data = JSON.parse(File.read(File.join(output_dir, "data", "mappings.json")))
      classes = data["classes"]
      
      # Single-schema classes should not have schemas array or have empty array
      sample_class = classes.values.first
      expect(sample_class["schemas"]).to be_nil.or be_empty
    end
  end

  describe "SpaCommand CLI Integration" do
    it "accepts multiple --mapping arguments" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir} 2>&1"
      
      output = `#{cmd}`
      
      expect(output).to include("Generating multi-schema SPA from 2 mapping files")
      expect(output).to include("Mapping 1:")
      expect(output).to include("Mapping 2:")
    end
  end

  describe "SpaWorkflow API Integration" do
    it "generates multi-schema SPA via API" do
      require "lutaml/klin/application/spa_workflow"
      
      workflow = Lutaml::Klin::Application::SpaWorkflow.new
      
      result = workflow.generate_spa_from_files(
        mapping_file_paths: [uro_mapping, urf_mapping],
        output_path: output_dir,
        template_type: :alpine,
        data_mode: :embedded
      )
      
      expect(result).to eq(output_dir)
      expect(File).to exist(File.join(output_dir, "index.html"))
      
      # Verify merged data
      data = JSON.parse(File.read(File.join(output_dir, "data", "mappings.json")))
      
      multi_schema_classes = data["classes"].values.select do |cls|
        cls["schemas"] && cls["schemas"].size > 1
      end
      
      expect(multi_schema_classes).not_to be_empty
    end
  end
end