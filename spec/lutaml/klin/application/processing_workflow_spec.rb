# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/application/processing_workflow"
require "lutaml/klin/domain/processing_result"
require "fileutils"
require "tempfile"

RSpec.describe Lutaml::Klin::Application::ProcessingWorkflow do
  let(:workflow) { described_class.new }
  let(:lur_path) { "test.lur" }
  let(:lxr_path) { "test.lxr" }
  let(:config_path) { "config.xml" }
  let(:output_path) { Dir.mktmpdir }

  let(:mock_uml_repo) { create_mock_uml_repository }
  let(:mock_xsd_repo) { create_mock_xsd_repository }
  let(:mock_config) { create_mock_shapechange_config }
  let(:mock_package) { create_mock_uml_package("TestPackage", "ModelRoot::Test") }
  let(:mock_class) { create_mock_uml_class("TestClass") }

  after { FileUtils.rm_rf(output_path) }

  describe "#initialize" do
    it "creates workflow without progress callback" do
      workflow = described_class.new
      expect(workflow.progress_callback).to be_nil
    end

    it "creates workflow with progress callback" do
      callback = ->(stage, msg) {}
      workflow = described_class.new(progress_callback: callback)
      expect(workflow.progress_callback).to eq(callback)
    end
  end

  describe "#execute" do
    before do
      # Mock repository loading
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(lur_path).and_return(true)
      allow(File).to receive(:exist?).with(lxr_path).and_return(true)
      allow(File).to receive(:exist?).with(config_path).and_return(true)

      allow_any_instance_of(described_class).to receive(:load_repositories)
        .and_return([mock_uml_repo, mock_xsd_repo])
      allow_any_instance_of(described_class).to receive(:load_configuration)
        .and_return([mock_config, {}])

      # Mock package filtering
      allow(mock_uml_repo).to receive(:all_packages).and_return([mock_package])
      allow(mock_uml_repo).to receive(:classes_in_package).and_return([mock_class])

      # Mock mapping workflow
      allow_any_instance_of(Lutaml::Klin::Application::MappingWorkflow)
        .to receive(:generate_mappings_for_packages)
        .and_return(create_test_schema_mapping)
    end

    context "with successful execution" do
      it "returns ProcessingResult" do
        allow(mock_uml_repo).to receive(:all_packages).and_return([mock_package])

        result = workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          output_path: output_path,
          generate_mappings: false,
          validate: false,
          generate_spa: false
        )

        expect(result).to be_a(Lutaml::Klin::Domain::ProcessingResult)
        expect(result.schema_mapping).not_to be_nil
        expect(result.statistics).to be_a(Hash)
        expect(result.metadata).to be_a(Hash)
      end

      it "includes processing statistics" do
        allow(mock_uml_repo).to receive(:all_packages).and_return([mock_package])

        result = workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          output_path: output_path,
          generate_mappings: false,
          validate: false,
          generate_spa: false
        )

        expect(result.statistics[:processing_time]).to be_a(Float)
        expect(result.statistics[:resolution_rate]).to be_a(Float)
      end

      it "includes metadata" do
        allow(mock_uml_repo).to receive(:all_packages).and_return([mock_package])

        result = workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          package_filter: "Test*",
          output_path: output_path,
          generate_mappings: false,
          validate: false,
          generate_spa: false
        )

        expect(result.metadata[:lur_path]).to eq(lur_path)
        expect(result.metadata[:lxr_path]).to eq(lxr_path)
        expect(result.metadata[:config_path]).to eq(config_path)
        expect(result.metadata[:package_filter]).to eq("Test*")
        expect(result.metadata[:packages_processed]).to be_an(Array)
      end
    end

    context "with progress callback" do
      it "reports progress to callback" do
        stages = []
        callback = ->(stage, _msg) { stages << stage }
        workflow = described_class.new(progress_callback: callback)

        workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          output_path: output_path,
          generate_mappings: false,
          validate: false,
          generate_spa: false
        )

        expect(stages).to include(:loading, :config, :filtering, :mapping, :complete)
      end
    end

    context "with package filtering" do
      it "filters packages by pattern" do
        allow(mock_uml_repo).to receive(:all_packages).and_return([
                                                                    create_mock_uml_package("Package1", "ModelRoot::Package1"),
                                                                    create_mock_uml_package("Package2", "ModelRoot::Package2"),
                                                                    create_mock_uml_package("Other", "ModelRoot::Other")
                                                                  ])
        allow(mock_uml_repo).to receive(:classes_in_package).and_return([mock_class])

        result = workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          package_filter: "Package*",
          output_path: output_path,
          generate_mappings: false,
          validate: false,
          generate_spa: false
        )

        expect(result.metadata[:packages_processed]).to include(
          match(/Package1/), match(/Package2/)
        )
      end

      it "raises error when no packages match filter" do
        allow(mock_uml_repo).to receive(:all_packages).and_return([mock_package])

        expect {
          workflow.execute(
            lur_path: lur_path,
            lxr_path: lxr_path,
            config_path: config_path,
            package_filter: "NonExistent",
            output_path: output_path
          )
        }.to raise_error(/No packages matched filter pattern/)
      end
    end

    context "with optional workflows" do
      it "generates mappings when requested" do
        allow(mock_uml_repo).to receive(:all_packages).and_return([mock_package])

        # Don't actually try to save files - just verify the flow
        result = workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          output_path: output_path,
          generate_mappings: true, # Changed to true to just use the repository
          validate: false,
          generate_spa: false
        )

        expect(result.schema_mapping).not_to be_nil
      end

      it "validates mappings when requested" do
        validation_workflow = instance_double(
          Lutaml::Klin::Application::ValidationWorkflow
        )
        allow(Lutaml::Klin::Application::ValidationWorkflow).to receive(:new)
          .and_return(validation_workflow)
        allow(validation_workflow).to receive(:validate_and_report)
          .and_return({ result: double(valid?: true), report_paths: [] })

        result = workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          output_path: output_path,
          generate_mappings: false,
          validate: true,
          generate_spa: false
        )

        expect(result.validation_result).not_to be_nil
      end

      it "generates SPA when requested" do
        spa_workflow = instance_double(Lutaml::Klin::Application::SpaWorkflow)
        allow(Lutaml::Klin::Application::SpaWorkflow).to receive(:new)
          .and_return(spa_workflow)
        allow(spa_workflow).to receive(:generate_spa)
          .and_return(File.join(output_path, "spa"))

        result = workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          output_path: output_path,
          generate_mappings: false,
          validate: false,
          generate_spa: true
        )

        expect(result.output_paths[:spa]).to match(/spa/)
      end
    end

    context "with error handling" do
      it "raises error when LUR file not found" do
        # Need to mock before workflow.execute is called
        allow_any_instance_of(described_class).to receive(:load_repositories)
          .and_raise("LUR package not found: #{lur_path}")

        expect {
          workflow.execute(
            lur_path: lur_path,
            lxr_path: lxr_path,
            config_path: config_path,
            output_path: output_path
          )
        }.to raise_error(/LUR package not found/)
      end

      it "raises error when LXR file not found" do
        allow_any_instance_of(described_class).to receive(:load_repositories)
          .and_raise("LXR package not found: #{lxr_path}")

        expect {
          workflow.execute(
            lur_path: lur_path,
            lxr_path: lxr_path,
            config_path: config_path,
            output_path: output_path
          )
        }.to raise_error(/LXR package not found/)
      end

      it "raises error when config file not found" do
        allow_any_instance_of(described_class).to receive(:load_configuration)
          .and_raise("Configuration file not found: #{config_path}")

        expect {
          workflow.execute(
            lur_path: lur_path,
            lxr_path: lxr_path,
            config_path: config_path,
            output_path: output_path
          )
        }.to raise_error(/Configuration file not found/)
      end

      it "reports progress on error" do
        stages = []
        callback = ->(stage, msg) { stages << [stage, msg] }
        workflow = described_class.new(progress_callback: callback)

        allow_any_instance_of(described_class).to receive(:load_repositories)
          .and_raise(StandardError, "Test error")

        expect {
          workflow.execute(
            lur_path: lur_path,
            lxr_path: lxr_path,
            config_path: config_path,
            output_path: output_path
          )
        }.to raise_error(StandardError)

        error_stage = stages.find { |s, _| s == :error }
        expect(error_stage).not_to be_nil
      end
    end

    context "with verbose mode" do
      it "provides detailed progress information" do
        messages = []
        callback = ->(_stage, msg) { messages << msg }
        workflow = described_class.new(progress_callback: callback)

        workflow.execute(
          lur_path: lur_path,
          lxr_path: lxr_path,
          config_path: config_path,
          output_path: output_path,
          verbose: true,
          generate_mappings: false,
          validate: false,
          generate_spa: false
        )

        expect(messages.any? { |m| m.include?("→") }).to be true
      end
    end
  end
end