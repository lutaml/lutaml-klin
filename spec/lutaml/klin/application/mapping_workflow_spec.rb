# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/application/mapping_workflow"
require "lutaml/klin/repositories/uml_repository_adapter"
require "lutaml/klin/repositories/schema_repository_adapter"
require "lutaml/klin/domain/resolution_engine"
require "lutaml/klin/domain/resolution_result"
require "tempfile"
require "ostruct"

RSpec.describe Lutaml::Klin::Application::MappingWorkflow do
  let(:mock_uml_repo) { instance_double("UmlRepositoryAdapter") }
  let(:mock_xsd_repo) { instance_double("SchemaRepositoryAdapter") }
  let(:mock_config) do
    double("ShapeChangeConfig",
           namespace_for_package: "http://example.org/core",
           prefix_for_namespace: "core")
  end
  let(:type_overrides) { { "OldType" => "NewType" } }

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
      expect do
        described_class.new(
          uml_repository: nil,
          xsd_repository: mock_xsd_repo,
          shapechange_config: mock_config
        )
      end.to raise_error(ArgumentError, /uml_repository is required/)
    end

    it "requires xsd_repository" do
      expect do
        described_class.new(
          uml_repository: mock_uml_repo,
          xsd_repository: nil,
          shapechange_config: mock_config
        )
      end.to raise_error(ArgumentError, /xsd_repository is required/)
    end

    it "requires shapechange_config" do
      expect do
        described_class.new(
          uml_repository: mock_uml_repo,
          xsd_repository: mock_xsd_repo,
          shapechange_config: nil
        )
      end.to raise_error(ArgumentError, /shapechange_config is required/)
    end

    it "initializes with all required parameters" do
      expect(workflow.uml_repository).to eq(mock_uml_repo)
      expect(workflow.xsd_repository).to eq(mock_xsd_repo)
      expect(workflow.shapechange_config).to eq(mock_config)
      expect(workflow.type_overrides).to eq(type_overrides)
    end

    it "builds a resolution engine" do
      expect(workflow.resolution_engine).to be_a(
        Lutaml::Klin::Domain::ResolutionEngine
      )
    end

    it "creates a mapping service" do
      expect(workflow.mapping_service).to be_a(
        Lutaml::Klin::Domain::Services::MappingService
      )
    end

    it "handles nil type_overrides" do
      wf = described_class.new(
        uml_repository: mock_uml_repo,
        xsd_repository: mock_xsd_repo,
        shapechange_config: mock_config,
        type_overrides: nil
      )
      expect(wf.type_overrides).to eq({})
    end
  end

  describe "#generate_mapping_for_package" do
    let(:package_path) { "ModelRoot::Core::Building" }
    let(:mock_package) do
      OpenStruct.new(
        name: "Building",
        qualified_name: package_path
      )
    end

    let(:mock_class) do
      OpenStruct.new(
        name: "Building",
        qualified_name: "ModelRoot::Core::Building::Building",
        stereotype: "featureType",
        documentation: "Building feature",
        package: OpenStruct.new(qualified_name: package_path),
        attributes: [
          OpenStruct.new(
            name: "height",
            type: "Real",
            documentation: "Height in meters",
            multiplicity: "0..1"
          )
        ]
      )
    end

    before do
      allow(mock_uml_repo).to receive(:find_package)
        .with(package_path)
        .and_return(mock_package)

      allow(mock_uml_repo).to receive(:classes_in_package)
        .with(package_path, recursive: false)
        .and_return([mock_class])

      # Mock the resolution engine to return resolved results
      allow_any_instance_of(Lutaml::Klin::Domain::ResolutionEngine)
        .to receive(:resolve)
        .and_return(
          Lutaml::Klin::Domain::ResolutionResult.resolved(
            xsd_type: "BuildingType",
            method: "MockStrategy",
            xsd_element: OpenStruct.new(
              name: "Building",
              documentation: "Building element"
            )
          )
        )
    end

    it "generates a package mapping" do
      result = workflow.generate_mapping_for_package(package_path)

      expect(result).to be_a(Lutaml::Klin::Mapping::PackageMapping)
      expect(result.uml_name).to eq("Building")
      expect(result.uml_package_name).to eq(package_path)
      expect(result.xsd_namespace).to eq("http://example.org/core")
      expect(result.xsd_namespace_prefix).to eq("core")
    end

    it "includes class mappings" do
      result = workflow.generate_mapping_for_package(package_path)

      expect(result.class_mappings).not_to be_empty
      expect(result.class_mappings.first.uml_name).to eq("Building")
    end

    it "includes attribute mappings" do
      result = workflow.generate_mapping_for_package(package_path)

      class_mapping = result.class_mappings.first
      expect(class_mapping.attribute_mappings).not_to be_empty
      expect(class_mapping.attribute_mappings.first.uml_name).to eq("height")
    end

    it "sets created_at timestamp" do
      result = workflow.generate_mapping_for_package(package_path)

      expect(result.created_at).not_to be_nil
      expect(result.created_at).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "calculates resolution statistics" do
      result = workflow.generate_mapping_for_package(package_path)

      expect(result.resolution_statistics).not_to be_nil
    end

    it "raises error if package not found" do
      allow(mock_uml_repo).to receive(:find_package)
        .with(package_path)
        .and_return(nil)

      expect do
        workflow.generate_mapping_for_package(package_path)
      end.to raise_error(/Package not found/)
    end

    it "supports recursive flag" do
      expect(mock_uml_repo).to receive(:classes_in_package)
        .with(package_path, recursive: true)
        .and_return([mock_class])

      workflow.generate_mapping_for_package(package_path, recursive: true)
    end
  end

  describe "#generate_mappings_for_packages" do
    let(:package_paths) do
      ["ModelRoot::Core::Building", "ModelRoot::Core::Road"]
    end

    let(:mock_packages) do
      package_paths.map do |path|
        OpenStruct.new(
          name: path.split("::").last,
          qualified_name: path
        )
      end
    end

    let(:mock_classes) do
      [
        OpenStruct.new(
          name: "Building",
          qualified_name: "ModelRoot::Core::Building::Building",
          stereotype: "featureType",
          documentation: "Building",
          package: OpenStruct.new(qualified_name: package_paths[0]),
          attributes: []
        ),
        OpenStruct.new(
          name: "Road",
          qualified_name: "ModelRoot::Core::Road::Road",
          stereotype: "featureType",
          documentation: "Road",
          package: OpenStruct.new(qualified_name: package_paths[1]),
          attributes: []
        )
      ]
    end

    before do
      package_paths.each_with_index do |path, idx|
        allow(mock_uml_repo).to receive(:find_package)
          .with(path)
          .and_return(mock_packages[idx])

        allow(mock_uml_repo).to receive(:classes_in_package)
          .with(path, recursive: false)
          .and_return([mock_classes[idx]])
      end

      allow_any_instance_of(Lutaml::Klin::Domain::ResolutionEngine)
        .to receive(:resolve)
        .and_return(
          Lutaml::Klin::Domain::ResolutionResult.resolved(
            xsd_type: "SomeType",
            method: "MockStrategy"
          )
        )
    end

    it "generates a schema mapping" do
      result = workflow.generate_mappings_for_packages(package_paths)

      expect(result).to be_a(Lutaml::Klin::Mapping::SchemaMapping)
      expect(result.version).to eq("1.0")
    end

    it "includes all package mappings" do
      result = workflow.generate_mappings_for_packages(package_paths)

      expect(result.package_mappings.size).to eq(2)
      expect(result.package_mappings[0].uml_name).to eq("Building")
      expect(result.package_mappings[1].uml_name).to eq("Road")
    end

    it "sets generated_at timestamp" do
      result = workflow.generate_mappings_for_packages(package_paths)

      expect(result.generated_at).not_to be_nil
      expect(result.generated_at).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it "collects unique namespaces" do
      result = workflow.generate_mappings_for_packages(package_paths)

      expect(result.namespaces).to include("http://example.org/core")
      expect(result.namespaces.uniq).to eq(result.namespaces)
    end

    it "supports recursive flag" do
      expect(mock_uml_repo).to receive(:classes_in_package)
        .twice
        .with(anything, recursive: true)
        .and_return([])

      workflow.generate_mappings_for_packages(package_paths, recursive: true)
    end
  end

  describe "#save_mapping" do
    let(:package_mapping) do
      Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
        pm.uml_name = "Test"
        pm.xsd_namespace = "http://example.org/test"
      end
    end

    it "saves mapping to YAML file" do
      Tempfile.create(["mapping", ".yaml"]) do |file|
        workflow.save_mapping(package_mapping, file.path)

        content = File.read(file.path)
        expect(content).to include("uml_name: Test")
        expect(content).to include("http://example.org/test")
      end
    end

    it "raises error if save fails" do
      invalid_path = "/invalid/path/that/does/not/exist/mapping.yaml"

      expect do
        workflow.save_mapping(package_mapping, invalid_path)
      end.to raise_error(/Failed to save mapping/)
    end
  end

  describe "private methods" do
    describe "#build_resolution_engine" do
      it "creates engine with type override strategy when overrides provided" do
        engine = workflow.send(:build_resolution_engine)

        strategy_names = engine.strategies.map(&:name)
        expect(strategy_names).to include("TypeOverrideStrategy")
      end

      it "creates engine with shapechange strategy" do
        engine = workflow.send(:build_resolution_engine)

        strategy_names = engine.strategies.map(&:name)
        expect(strategy_names).to include("ShapeChangeMappingStrategy")
      end

      it "creates engine with schema repository strategy" do
        engine = workflow.send(:build_resolution_engine)

        strategy_names = engine.strategies.map(&:name)
        expect(strategy_names).to include("SchemaRepositoryStrategy")
      end

      it "omits type override strategy when no overrides" do
        wf = described_class.new(
          uml_repository: mock_uml_repo,
          xsd_repository: mock_xsd_repo,
          shapechange_config: mock_config,
          type_overrides: {}
        )

        engine = wf.send(:build_resolution_engine)
        strategy_names = engine.strategies.map(&:name)
        expect(strategy_names).not_to include("TypeOverrideStrategy")
      end
    end

    describe "#derive_prefix_from_namespace" do
      it "extracts prefix from namespace URI" do
        namespace = "http://www.opengis.net/gml/3.2"
        prefix = workflow.send(:derive_prefix_from_namespace, namespace)
        expect(prefix).to eq("gml")
      end

      it "handles simple namespaces" do
        namespace = "http://example.org/core"
        prefix = workflow.send(:derive_prefix_from_namespace, namespace)
        expect(prefix).to eq("core")
      end

      it "ignores http/https/www parts" do
        namespace = "https://www.example.org/test/namespace"
        prefix = workflow.send(:derive_prefix_from_namespace, namespace)
        expect(prefix).to eq("namespace")
      end

      it "returns nil for empty namespace" do
        prefix = workflow.send(:derive_prefix_from_namespace, "")
        expect(prefix).to be_nil
      end

      it "returns nil for nil namespace" do
        prefix = workflow.send(:derive_prefix_from_namespace, nil)
        expect(prefix).to be_nil
      end
    end
  end
end