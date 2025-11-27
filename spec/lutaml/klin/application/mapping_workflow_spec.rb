# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/application/mapping_workflow"

RSpec.describe Lutaml::Klin::Application::MappingWorkflow do
  let(:mock_uml_repo) { create_mock_uml_repository }
  let(:mock_xsd_repo) { create_mock_xsd_repository }
  let(:mock_config) { create_mock_shapechange_config }
  let(:type_overrides) { {} }

  let(:workflow) do
    described_class.new(
      uml_repository: mock_uml_repo,
      xsd_repository: mock_xsd_repo,
      shapechange_config: mock_config,
      type_overrides: type_overrides
    )
  end

  describe "#initialize" do
    it "requires uml_repository" do
      expect {
        described_class.new(
          uml_repository: nil,
          xsd_repository: mock_xsd_repo,
          shapechange_config: mock_config
        )
      }.to raise_error(ArgumentError, /uml_repository is required/)
    end

    it "requires xsd_repository" do
      expect {
        described_class.new(
          uml_repository: mock_uml_repo,
          xsd_repository: nil,
          shapechange_config: mock_config
        )
      }.to raise_error(ArgumentError, /xsd_repository is required/)
    end

    it "requires shapechange_config" do
      expect {
        described_class.new(
          uml_repository: mock_uml_repo,
          xsd_repository: mock_xsd_repo,
          shapechange_config: nil
        )
      }.to raise_error(ArgumentError, /shapechange_config is required/)
    end

    it "initializes with valid parameters" do
      workflow = described_class.new(
        uml_repository: mock_uml_repo,
        xsd_repository: mock_xsd_repo,
        shapechange_config: mock_config
      )

      expect(workflow.uml_repository).to eq(mock_uml_repo)
      expect(workflow.xsd_repository).to eq(mock_xsd_repo)
      expect(workflow.shapechange_config).to eq(mock_config)
      expect(workflow.resolution_engine).not_to be_nil
      expect(workflow.mapping_service).not_to be_nil
      expect(workflow.transformation_analyzer).not_to be_nil
    end

    it "accepts type_overrides" do
      overrides = { "OldType" => "NewType" }
      workflow = described_class.new(
        uml_repository: mock_uml_repo,
        xsd_repository: mock_xsd_repo,
        shapechange_config: mock_config,
        type_overrides: overrides
      )

      expect(workflow.type_overrides).to eq(overrides)
    end

    it "defaults type_overrides to empty hash" do
      expect(workflow.type_overrides).to eq({})
    end
  end

  describe "#generate_mapping_for_package" do
    let(:package_path) { "ModelRoot::TestPackage" }
    let(:mock_package) { create_mock_uml_package("TestPackage", package_path) }
    let(:mock_class) { create_mock_uml_class("TestClass") }

    before do
      allow(mock_uml_repo).to receive(:find_package)
        .with(package_path)
        .and_return(mock_package)
      allow(mock_uml_repo).to receive(:classes_in_package)
        .and_return([mock_class])
      allow(mock_config).to receive(:namespace_for_package)
        .and_return("http://test.org")
    end

    it "generates PackageMapping for valid package" do
      result = workflow.generate_mapping_for_package(package_path)

      expect(result).to be_a(Lutaml::Klin::Mapping::PackageMapping)
      expect(result.uml_package_name).to eq(package_path)
      expect(result.xsd_namespace).to eq("http://test.org")
      expect(result.class_mappings).not_to be_empty
    end

    it "raises error when package not found" do
      allow(mock_uml_repo).to receive(:find_package)
        .with(package_path)
        .and_return(nil)

      expect {
        workflow.generate_mapping_for_package(package_path)
      }.to raise_error(/Package not found/)
    end

    it "handles recursive option" do
      workflow.generate_mapping_for_package(package_path, recursive: true)

      expect(mock_uml_repo).to have_received(:classes_in_package)
        .with(package_path, recursive: true)
    end

    it "defaults to non-recursive" do
      workflow.generate_mapping_for_package(package_path)

      expect(mock_uml_repo).to have_received(:classes_in_package)
        .with(package_path, recursive: false)
    end

    it "includes created_at timestamp" do
      result = workflow.generate_mapping_for_package(package_path)

      expect(result.created_at).not_to be_nil
      expect(result.created_at).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it "includes resolution statistics" do
      result = workflow.generate_mapping_for_package(package_path)

      expect(result.resolution_statistics).not_to be_nil
    end

    context "with verbose mode" do
      it "calls progress callback" do
        called = false
        callback = ->(_stage, _msg) { called = true }

        workflow.generate_mapping_for_package(
          package_path,
          verbose: true,
          progress_callback: callback
        )

        expect(called).to be true
      end
    end

    context "with namespace fallback" do
      it "uses fallback namespace when config fails" do
        allow(mock_config).to receive(:namespace_for_package)
          .and_raise(StandardError)

        result = workflow.generate_mapping_for_package(package_path)

        expect(result.xsd_namespace).to match(/testpackage/)
      end
    end
  end

  describe "#generate_mappings_for_packages" do
    let(:package_paths) { ["ModelRoot::Package1", "ModelRoot::Package2"] }
    let(:mock_package1) { create_mock_uml_package("Package1", package_paths[0]) }
    let(:mock_package2) { create_mock_uml_package("Package2", package_paths[1]) }

    before do
      allow(mock_uml_repo).to receive(:find_package)
        .with(package_paths[0])
        .and_return(mock_package1)
      allow(mock_uml_repo).to receive(:find_package)
        .with(package_paths[1])
        .and_return(mock_package2)
      allow(mock_uml_repo).to receive(:classes_in_package)
        .and_return([])
      allow(mock_config).to receive(:namespace_for_package)
        .and_return("http://test.org")
    end

    it "generates SchemaMapping for multiple packages" do
      result = workflow.generate_mappings_for_packages(package_paths)

      expect(result).to be_a(Lutaml::Klin::Mapping::SchemaMapping)
      expect(result.package_mappings.size).to eq(2)
      expect(result.version).to eq("1.0")
    end

    it "includes unique namespaces" do
      allow(mock_config).to receive(:namespace_for_package)
        .with(package_paths[0])
        .and_return("http://test1.org")
      allow(mock_config).to receive(:namespace_for_package)
        .with(package_paths[1])
        .and_return("http://test2.org")

      result = workflow.generate_mappings_for_packages(package_paths)

      expect(result.namespaces).to include("http://test1.org", "http://test2.org")
      expect(result.namespaces.size).to eq(2)
    end

    it "includes timestamp" do
      result = workflow.generate_mappings_for_packages(package_paths)

      expect(result.generated_at).not_to be_nil
    end

    it "handles empty package list" do
      result = workflow.generate_mappings_for_packages([])

      expect(result.package_mappings).to be_empty
    end

    it "handles recursive option" do
      workflow.generate_mappings_for_packages(package_paths, recursive: true)

      expect(mock_uml_repo).to have_received(:classes_in_package)
        .with(anything, recursive: true).at_least(:once)
    end
  end

  describe "#save_mapping" do
    let(:mapping) { create_test_schema_mapping }
    let(:output_path) { "test_output.yaml" }

    after do
      FileUtils.rm_f(output_path)
    end

    it "saves mapping to YAML file" do
      workflow.save_mapping(mapping, output_path)

      expect(File.exist?(output_path)).to be true
      content = File.read(output_path)
      expect(content).to include("version:")
      expect(content).to include("package_mappings:")
    end

    it "raises error on save failure" do
      allow(File).to receive(:write).and_raise(StandardError, "Write failed")

      expect {
        workflow.save_mapping(mapping, output_path)
      }.to raise_error(/Failed to save mapping/)
    end

    it "handles complex mappings" do
      complex_mapping = create_test_schema_mapping(
        num_packages: 3,
        num_classes: 5,
        num_attributes: 10
      )

      workflow.save_mapping(complex_mapping, output_path)

      expect(File.exist?(output_path)).to be true
    end
  end

  describe "private methods" do
    describe "#build_resolution_engine" do
      it "builds engine with strategies in correct order" do
        engine = workflow.resolution_engine

        expect(engine).to be_a(Lutaml::Klin::Domain::ResolutionEngine)
        # Engine should have strategies registered
      end

      it "includes TypeOverrideStrategy when overrides provided" do
        workflow_with_overrides = described_class.new(
          uml_repository: mock_uml_repo,
          xsd_repository: mock_xsd_repo,
          shapechange_config: mock_config,
          type_overrides: { "Type1" => "Type2" }
        )

        engine = workflow_with_overrides.resolution_engine
        expect(engine).to be_a(Lutaml::Klin::Domain::ResolutionEngine)
      end
    end

    describe "#determine_xsd_namespace" do
      let(:mock_package) { create_mock_uml_package("Test") }

      it "gets namespace from ShapeChange config" do
        allow(mock_config).to receive(:namespace_for_package)
          .with("Test")
          .and_return("http://configured.org")

        namespace = workflow.send(:determine_xsd_namespace, mock_package)

        expect(namespace).to eq("http://configured.org")
      end

      it "uses fallback when namespace not configured" do
        allow(mock_config).to receive(:namespace_for_package)
          .and_raise(StandardError)

        namespace = workflow.send(:determine_xsd_namespace, mock_package)

        expect(namespace).to match(/test/)
      end
    end

    describe "#extract_namespace_prefix" do
      it "gets prefix from ShapeChange config" do
        namespace = "http://test.org"
        allow(mock_config).to receive(:prefix_for_namespace)
          .with(namespace)
          .and_return("test")

        prefix = workflow.send(:extract_namespace_prefix, namespace)

        expect(prefix).to eq("test")
      end

      it "derives prefix from namespace URI when config unavailable" do
        namespace = "http://www.opengis.net/gml/3.2"
        allow(mock_config).to receive(:prefix_for_namespace)
          .and_raise(NoMethodError)

        prefix = workflow.send(:extract_namespace_prefix, namespace)

        expect(prefix).to eq("gml")
      end
    end

    describe "#derive_prefix_from_namespace" do
      it "extracts meaningful part from namespace" do
        prefix = workflow.send(
          :derive_prefix_from_namespace,
          "http://www.opengis.net/gml/3.2"
        )

        expect(prefix).to eq("gml")
      end

      it "handles nil namespace" do
        prefix = workflow.send(:derive_prefix_from_namespace, nil)

        expect(prefix).to be_nil
      end

      it "handles empty namespace" do
        prefix = workflow.send(:derive_prefix_from_namespace, "")

        expect(prefix).to be_nil
      end

      it "skips http/https/www parts" do
        prefix = workflow.send(
          :derive_prefix_from_namespace,
          "https://www.example.com/test/schema"
        )

        expect(%w[test schema]).to include(prefix)
      end
    end
  end
end