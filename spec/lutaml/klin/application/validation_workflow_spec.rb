# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/application/validation_workflow"

RSpec.describe Lutaml::Klin::Application::ValidationWorkflow do
  let(:workflow) { described_class.new }
  let(:schema_mapping) { create_test_schema_mapping }

  describe "#initialize" do
    it "creates workflow with default validation service" do
      workflow = described_class.new
      expect(workflow.validation_service).to be_a(
        Lutaml::Klin::Domain::Services::ValidationService
      )
    end

    it "accepts custom validation service" do
      custom_service = double("ValidationService")
      workflow = described_class.new(validation_service: custom_service)
      expect(workflow.validation_service).to eq(custom_service)
    end
  end

  describe "#validate_mapping" do
    it "delegates to validation service" do
      mock_service = double("ValidationService")
      mock_result = double("ValidationResult", valid?: true)
      allow(mock_service).to receive(:validate).and_return(mock_result)

      workflow = described_class.new(validation_service: mock_service)
      result = workflow.validate_mapping(schema_mapping)

      expect(mock_service).to have_received(:validate).with(schema_mapping)
      expect(result).to eq(mock_result)
    end

    it "returns ValidationResult" do
      result = workflow.validate_mapping(schema_mapping)
      expect(result).to be_a(Lutaml::Klin::Domain::ValidationResult)
    end
  end

  describe "#generate_reports" do
    let(:validation_result) { workflow.validate_mapping(schema_mapping) }
    let(:output_path) { "test_report" }

    after do
      Dir.glob("#{output_path}.*").each { |f| File.delete(f) }
    end

    it "generates JSON and Markdown reports" do
      paths = workflow.generate_reports(validation_result, output_path)

      expect(paths).to be_an(Array)
      expect(paths.size).to eq(2)
      expect(paths).to include(match(/\.json$/), match(/\.md$/))
    end

    it "returns array of report paths" do
      paths = workflow.generate_reports(validation_result, output_path)

      paths.each do |path|
        expect(File.exist?(path)).to be true
      end
    end

    it "handles report generation errors gracefully" do
      allow_any_instance_of(Lutaml::Klin::Domain::Reporters::JsonReporter)
        .to receive(:generate).and_raise(StandardError)

      expect {
        workflow.generate_reports(validation_result, output_path)
      }.not_to raise_error
    end
  end

  describe "#validate_and_report" do
    let(:output_path) { "test_validation" }

    after do
      Dir.glob("#{output_path}.*").each { |f| File.delete(f) }
    end

    it "validates and generates reports in one operation" do
      result = workflow.validate_and_report(schema_mapping, output_path)

      expect(result).to be_a(Hash)
      expect(result).to have_key(:result)
      expect(result).to have_key(:report_paths)
    end

    it "returns validation result" do
      result = workflow.validate_and_report(schema_mapping, output_path)

      expect(result[:result]).to be_a(Lutaml::Klin::Domain::ValidationResult)
    end

    it "returns report paths" do
      result = workflow.validate_and_report(schema_mapping, output_path)

      expect(result[:report_paths]).to be_an(Array)
      expect(result[:report_paths]).not_to be_empty
    end

    it "creates report files" do
      workflow.validate_and_report(schema_mapping, output_path)

      expect(File.exist?("#{output_path}.json")).to be true
      expect(File.exist?("#{output_path}.md")).to be true
    end
  end

  describe "private methods" do
    let(:validation_result) { workflow.validate_mapping(schema_mapping) }
    let(:output_path) { "test_report" }

    after do
      Dir.glob("#{output_path}.*").each { |f| File.delete(f) }
    end

    describe "#generate_json_report" do
      it "creates JSON report file" do
        workflow.send(:generate_json_report, validation_result, output_path)

        expect(File.exist?("#{output_path}.json")).to be true
      end

      it "returns JSON report path" do
        path = workflow.send(
          :generate_json_report,
          validation_result,
          output_path
        )

        expect(path).to eq("#{output_path}.json")
      end

      it "handles generation errors" do
        allow_any_instance_of(Lutaml::Klin::Domain::Reporters::JsonReporter)
          .to receive(:generate).and_raise(StandardError, "Test error")

        expect {
          workflow.send(:generate_json_report, validation_result, output_path)
        }.not_to raise_error
      end
    end

    describe "#generate_markdown_report" do
      it "creates Markdown report file" do
        workflow.send(
          :generate_markdown_report,
          validation_result,
          output_path
        )

        expect(File.exist?("#{output_path}.md")).to be true
      end

      it "returns Markdown report path" do
        path = workflow.send(
          :generate_markdown_report,
          validation_result,
          output_path
        )

        expect(path).to eq("#{output_path}.md")
      end

      it "handles generation errors" do
        allow_any_instance_of(Lutaml::Klin::Domain::Reporters::MarkdownReporter)
          .to receive(:generate).and_raise(StandardError, "Test error")

        expect {
          workflow.send(
            :generate_markdown_report,
            validation_result,
            output_path
          )
        }.not_to raise_error
      end
    end
  end
end