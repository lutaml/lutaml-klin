# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/application/validation_workflow"
require "lutaml/klin/models/mapping/schema_mapping"
require "lutaml/klin/models/mapping/package_mapping"
require "lutaml/klin/models/mapping/class_mapping"
require "lutaml/klin/models/mapping/attribute_mapping"

RSpec.describe Lutaml::Klin::Application::ValidationWorkflow do
  let(:workflow) { described_class.new }

  # Helper to create test schema mapping
  def create_test_schema_mapping
    attr1 = Lutaml::Klin::Mapping::AttributeMapping.new.tap do |a|
      a.uml_name = "prop1"
      a.resolution_status = "resolved"
      a.uml_type = "String"
      a.xsd_type = "string"
    end

    class1 = Lutaml::Klin::Mapping::ClassMapping.new.tap do |c|
      c.uml_name = "Class1"
      c.resolution_status = "resolved"
      c.attribute_mappings = [attr1]
    end

    package1 = Lutaml::Klin::Mapping::PackageMapping.new.tap do |p|
      p.uml_package_name = "Package1"
      p.xsd_namespace = "http://example.com"
      p.class_mappings = [class1]
    end

    Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
      sm.package_mappings = [package1]
    end
  end

  describe "#initialize" do
    it "creates workflow with default validation service" do
      workflow = described_class.new

      expect(workflow.validation_service).to be_a(
        Lutaml::Klin::Domain::Services::ValidationService
      )
    end

    it "accepts custom validation service" do
      custom_service = double("validation_service")
      workflow = described_class.new(validation_service: custom_service)

      expect(workflow.validation_service).to eq(custom_service)
    end
  end

  describe "#validate_mapping" do
    it "validates schema mapping and returns ValidationResult" do
      schema_mapping = create_test_schema_mapping

      result = workflow.validate_mapping(schema_mapping)

      expect(result).to be_a(Lutaml::Klin::Domain::ValidationResult)
      expect(result.valid?).to be true
    end

    it "delegates to validation service" do
      schema_mapping = create_test_schema_mapping
      mock_result = double("validation_result")
      mock_service = double("validation_service")
      allow(mock_service).to receive(:validate)
        .with(schema_mapping)
        .and_return(mock_result)

      workflow = described_class.new(validation_service: mock_service)
      result = workflow.validate_mapping(schema_mapping)

      expect(result).to eq(mock_result)
    end
  end

  describe "#generate_reports" do
    let(:validation_result) do
      Lutaml::Klin::Domain::ValidationResult.new(
        summary: {
          total_packages: 1,
          total_classes: 1,
          resolved_classes: 1,
          resolution_rate: 100.0
        },
        unresolved_items: [],
        packages: []
      )
    end

    it "generates both JSON and Markdown reports" do
      Dir.mktmpdir do |dir|
        base_path = File.join(dir, "validation")

        report_paths = workflow.generate_reports(
          validation_result,
          base_path
        )

        expect(report_paths).to be_an(Array)
        expect(report_paths.size).to eq(2)
        expect(report_paths).to include("#{base_path}.json")
        expect(report_paths).to include("#{base_path}.md")

        expect(File.exist?("#{base_path}.json")).to be true
        expect(File.exist?("#{base_path}.md")).to be true
      end
    end

    it "returns paths to generated reports" do
      Dir.mktmpdir do |dir|
        base_path = File.join(dir, "validation")

        report_paths = workflow.generate_reports(
          validation_result,
          base_path
        )

        report_paths.each do |path|
          expect(File.exist?(path)).to be true
        end
      end
    end

    it "handles errors gracefully when JSON generation fails" do
      Dir.mktmpdir do |dir|
        # Create a read-only directory to force write failure
        base_path = File.join(dir, "readonly", "validation")
        FileUtils.mkdir_p(File.dirname(base_path))
        FileUtils.chmod(0o444, File.dirname(base_path))

        # Should not raise, but should warn and continue
        expect do
          report_paths = workflow.generate_reports(
            validation_result,
            base_path
          )
          # At least one report might succeed or both fail
          expect(report_paths).to be_an(Array)
        end.not_to raise_error

        # Clean up
        FileUtils.chmod(0o755, File.dirname(base_path))
      end
    end
  end

  describe "#validate_and_report" do
    it "validates mapping and generates reports in one operation" do
      schema_mapping = create_test_schema_mapping

      Dir.mktmpdir do |dir|
        base_path = File.join(dir, "validation")

        result = workflow.validate_and_report(schema_mapping, base_path)

        expect(result).to be_a(Hash)
        expect(result[:result]).to be_a(
          Lutaml::Klin::Domain::ValidationResult
        )
        expect(result[:report_paths]).to be_an(Array)
        expect(result[:report_paths].size).to eq(2)
      end
    end

    it "returns validation result and report paths" do
      schema_mapping = create_test_schema_mapping

      Dir.mktmpdir do |dir|
        base_path = File.join(dir, "validation")

        result = workflow.validate_and_report(schema_mapping, base_path)

        expect(result).to have_key(:result)
        expect(result).to have_key(:report_paths)
        expect(result[:result].valid?).to be true
        expect(result[:report_paths]).not_to be_empty
      end
    end

    it "creates actual report files" do
      schema_mapping = create_test_schema_mapping

      Dir.mktmpdir do |dir|
        base_path = File.join(dir, "validation")

        result = workflow.validate_and_report(schema_mapping, base_path)

        result[:report_paths].each do |path|
          expect(File.exist?(path)).to be true
          expect(File.size(path)).to be > 0
        end
      end
    end
  end

  describe "integration with real mapping" do
    it "handles complex schema mapping with unresolved items" do
      # Create mapping with unresolved attribute
      unresolved_attr = Lutaml::Klin::Mapping::AttributeMapping.new.tap do |a|
        a.uml_name = "customProp"
        a.resolution_status = "unresolved"
        a.uml_type = "CustomType"
        a.resolution_error = "Type not found"
      end

      class1 = Lutaml::Klin::Mapping::ClassMapping.new.tap do |c|
        c.uml_name = "TestClass"
        c.resolution_status = "resolved"
        c.attribute_mappings = [unresolved_attr]
      end

      package1 = Lutaml::Klin::Mapping::PackageMapping.new.tap do |p|
        p.uml_package_name = "TestPackage"
        p.xsd_namespace = "http://test.com"
        p.class_mappings = [class1]
      end

      schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.package_mappings = [package1]
      end

      Dir.mktmpdir do |dir|
        base_path = File.join(dir, "validation")

        result = workflow.validate_and_report(schema_mapping, base_path)

        # Check validation result
        expect(result[:result].valid?).to be false
        expect(result[:result].unresolved_count).to eq(1)

        # Check reports were generated
        json_path = "#{base_path}.json"
        md_path = "#{base_path}.md"

        expect(File.exist?(json_path)).to be true
        expect(File.exist?(md_path)).to be true

        # Verify JSON content
        json_content = JSON.parse(File.read(json_path))
        expect(json_content["validation_status"]).to eq("invalid")
        expect(json_content["unresolved_items"].size).to eq(1)

        # Verify Markdown content
        md_content = File.read(md_path)
        expect(md_content).to include("⚠️ Invalid")
        expect(md_content).to include("customProp")
        expect(md_content).to include("CustomType")
      end
    end
  end
end