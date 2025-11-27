# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "yaml"

RSpec.describe "Complete Workflow Integration", :integration do
  let(:fixtures_dir) { File.join(__dir__, "../fixtures/integration") }
  let(:output_dir) { File.join(__dir__, "../../tmp/integration_test_output") }
  let(:uml_repo) { double("UmlRepositoryAdapter") }
  let(:xsd_repo) { double("SchemaRepositoryAdapter") }
  let(:shapechange_config) { double("ShapeChangeConfiguration") }

  before do
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "minimal test model workflow" do
    let(:type_overrides) { { "OldType" => "NewType" } }
    let(:workflow) do
      Lutaml::Klin::Application::MappingWorkflow.new(
        uml_repository: uml_repo,
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: type_overrides
      )
    end

    before do
      # Mock UML package
      uml_package = double("UmlPackage",
                           name: "TestPackage",
                           qualified_name: "ModelRoot::TestPackage")

      # Mock UML classes
      test_class = double("UmlClass",
                          name: "TestClass",
                          qualified_name: "ModelRoot::TestPackage::TestClass",
                          stereotype: "featureType",
                          documentation: "Test class documentation",
                          attributes: [
                            double("UmlAttribute",
                                   name: "testAttr",
                                   type: "String",
                                   documentation: "Test attribute",
                                   multiplicity: "1")
                          ])

      allow(uml_repo).to receive(:find_package)
        .with("ModelRoot::TestPackage")
        .and_return(uml_package)

      allow(uml_repo).to receive(:classes_in_package)
        .with("ModelRoot::TestPackage", recursive: false)
        .and_return([test_class])

      # Mock ShapeChange config
      allow(shapechange_config).to receive(:namespace_for_package)
        .with("ModelRoot::TestPackage")
        .and_return("http://example.org/test")

      allow(shapechange_config).to receive(:prefix_for_namespace)
        .with("http://example.org/test")
        .and_return("test")

      # Mock XSD repository
      xsd_element = double("XsdElement",
                           name: "TestClass",
                           namespace: "http://example.org/test",
                           type: "TestClassType",
                           documentation: "XSD documentation")

      xsd_type = double("XsdType",
                        name: "string",
                        namespace: "http://www.w3.org/2001/XMLSchema")

      allow(xsd_repo).to receive(:find_element)
        .and_return(xsd_element)

      allow(xsd_repo).to receive(:find_type)
        .and_return(xsd_type)
    end

    it "generates all outputs successfully" do
      # Generate mapping
      mapping = workflow.generate_mapping_for_package("ModelRoot::TestPackage")

      expect(mapping).to be_a(Lutaml::Klin::Mapping::PackageMapping)
      expect(mapping.uml_package_name).to eq("ModelRoot::TestPackage")
      expect(mapping.xsd_namespace).to eq("http://example.org/test")
      expect(mapping.class_mappings).not_to be_empty

      # Save YAML mapping
      yaml_path = File.join(output_dir, "test_mapping.yaml")
      workflow.save_mapping(mapping, yaml_path)

      expect(File.exist?(yaml_path)).to be true

      # Verify YAML can be reloaded
      yaml_content = File.read(yaml_path)
      expect(yaml_content).to include("uml_package_name")
      expect(yaml_content).to include("TestPackage")

      # Generate validation report
      schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.version = "1.0"
        sm.package_mappings = [mapping]
        sm.set_timestamp!
      end

      validation_workflow = Lutaml::Klin::Application::ValidationWorkflow.new
      validation_result = validation_workflow.validate_mapping(schema_mapping)

      expect(validation_result).to be_a(Lutaml::Klin::Domain::ValidationResult)
      expect(validation_result.summary).to include(:total_packages)

      # Generate validation reports
      validation_base = File.join(output_dir, "validation_report")
      report_paths = validation_workflow.generate_reports(
        validation_result,
        validation_base
      )

      expect(report_paths).not_to be_empty
      expect(File.exist?("#{validation_base}.json")).to be true
      expect(File.exist?("#{validation_base}.md")).to be true

      # Check resolution statistics
      stats = mapping.calculate_statistics
      expect(stats).to include("total_classes")
      expect(stats["total_classes"]).to be > 0
    end

    it "generates working SPA data files" do
      mapping = workflow.generate_mapping_for_package("ModelRoot::TestPackage")

      schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.version = "1.0"
        sm.package_mappings = [mapping]
        sm.set_timestamp!
      end

      # Generate SPA data
      spa_generator = Lutaml::Klin::Domain::Services::SpaGenerator.new

      # Generate mappings JSON
      mappings_json = spa_generator.generate_mappings_json(schema_mapping)
      expect(mappings_json).to include(:version, :packages)
      expect(mappings_json[:packages]).to be_an(Array)

      # Save mappings JSON
      mappings_path = File.join(output_dir, "mappings.json")
      File.write(mappings_path, JSON.pretty_generate(mappings_json))
      expect(File.exist?(mappings_path)).to be true

      # Generate search index
      search_index = spa_generator.generate_search_index(schema_mapping)
      expect(search_index).to include(:index)
      expect(search_index[:index]).to be_an(Array)

      # Save search index
      search_path = File.join(output_dir, "search-index.json")
      File.write(search_path, JSON.pretty_generate(search_index))
      expect(File.exist?(search_path)).to be true

      # Generate statistics
      stats = spa_generator.generate_statistics(schema_mapping)
      expect(stats).to include(:summary, :packages)

      # Save statistics
      stats_path = File.join(output_dir, "statistics.json")
      File.write(stats_path, JSON.pretty_generate(stats))
      expect(File.exist?(stats_path)).to be true

      # Verify JSON files are valid
      parsed_mappings = JSON.parse(File.read(mappings_path))
      expect(parsed_mappings["version"]).to eq("1.0")

      parsed_search = JSON.parse(File.read(search_path))
      expect(parsed_search["index"]).to be_an(Array)

      parsed_stats = JSON.parse(File.read(stats_path))
      expect(parsed_stats["summary"]).to be_a(Hash)
    end
  end

  describe "partially resolvable model" do
    let(:workflow) do
      Lutaml::Klin::Application::MappingWorkflow.new(
        uml_repository: uml_repo,
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: {}
      )
    end

    before do
      uml_package = double("UmlPackage",
                           name: "PartialPackage",
                           qualified_name: "ModelRoot::PartialPackage")

      # Class with unresolvable attribute type
      partial_class = double("UmlClass",
                             name: "PartialClass",
                             qualified_name: "ModelRoot::PartialPackage::PartialClass",
                             stereotype: "featureType",
                             documentation: "Partial class",
                             attributes: [
                               double("UmlAttribute",
                                      name: "resolvedAttr",
                                      type: "String",
                                      documentation: "Resolvable",
                                      multiplicity: "1"),
                               double("UmlAttribute",
                                      name: "unresolvedAttr",
                                      type: "UnknownType",
                                      documentation: "Unresolvable",
                                      multiplicity: "1")
                             ])

      allow(uml_repo).to receive(:find_package)
        .with("ModelRoot::PartialPackage")
        .and_return(uml_package)

      allow(uml_repo).to receive(:classes_in_package)
        .with("ModelRoot::PartialPackage", recursive: false)
        .and_return([partial_class])

      allow(shapechange_config).to receive(:namespace_for_package)
        .with("ModelRoot::PartialPackage")
        .and_return("http://example.org/partial")

      allow(shapechange_config).to receive(:prefix_for_namespace)
        .and_return("partial")

      # Mock XSD repository - String resolves, UnknownType doesn't
      allow(xsd_repo).to receive(:find_type) do |type_name, _namespace|
        if %w[String string].include?(type_name)
          double("XsdType",
                 name: "string",
                 namespace: "http://www.w3.org/2001/XMLSchema")
        end
      end

      allow(xsd_repo).to receive(:find_element).and_return(nil)
    end

    it "handles unresolved types gracefully" do
      mapping = workflow.generate_mapping_for_package("ModelRoot::PartialPackage")

      expect(mapping.class_mappings).not_to be_empty

      test_class = mapping.class_mappings.first
      expect(test_class.attribute_mappings.size).to eq(2)

      # Check resolution status
      resolved_attr = test_class.attribute_mappings.find do |a|
        a.uml_name == "resolvedAttr"
      end
      expect(resolved_attr.resolution_status).to eq("resolved")

      unresolved_attr = test_class.attribute_mappings.find do |a|
        a.uml_name == "unresolvedAttr"
      end
      expect(unresolved_attr.resolution_status).to eq("unresolved")

      # Verify partial resolution tracked correctly
      stats = mapping.calculate_statistics
      expect(stats["total_attributes"]).to eq(2)
      expect(stats["resolved_attributes"]).to eq(1)
      expect(stats["unresolved_attributes"]).to eq(1)

      # Verify suggestions generated
      validation_service = Lutaml::Klin::Domain::Services::ValidationService.new
      schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.package_mappings = [mapping]
      end

      validation_result = validation_service.validate(schema_mapping)
      expect(validation_result.unresolved_items).not_to be_empty

      unresolved_item = validation_result.unresolved_items.first
      expect(unresolved_item[:suggestions]).to be_an(Array)
      expect(unresolved_item[:suggestions]).not_to be_empty
    end
  end

  describe "package filtering" do
    let(:workflow) do
      Lutaml::Klin::Application::MappingWorkflow.new(
        uml_repository: uml_repo,
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: {}
      )
    end

    before do
      # Setup multiple packages
      allow(shapechange_config).to receive(:namespace_for_package)
        .and_return("http://example.org/test")
      allow(shapechange_config).to receive(:prefix_for_namespace)
        .and_return("test")
    end

    it "processes only filtered packages" do
      # Create package filter
      filter = Lutaml::Klin::Domain::Services::PackageFilter.new("ModelRoot::i-UR::**")

      # Test matching
      expect(filter.matches?("ModelRoot::i-UR::urf")).to be true
      expect(filter.matches?("ModelRoot::i-UR::urf::Building")).to be true
      expect(filter.matches?("ModelRoot::Core")).to be false
      expect(filter.matches?("ModelRoot::Extensions")).to be false

      # Test wildcard patterns
      all_filter = Lutaml::Klin::Domain::Services::PackageFilter.new("**")
      expect(all_filter.matches?("any::package::path")).to be true

      # Test specific ending
      ending_filter = Lutaml::Klin::Domain::Services::PackageFilter.new("**::urf")
      expect(ending_filter.matches?("ModelRoot::i-UR::urf")).to be true
      expect(ending_filter.matches?("Other::Path::urf")).to be true
      expect(ending_filter.matches?("ModelRoot::i-UR::Building")).to be false
    end
  end

  describe "error handling" do
    let(:workflow) do
      Lutaml::Klin::Application::MappingWorkflow.new(
        uml_repository: uml_repo,
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: {}
      )
    end

    it "raises error when package not found" do
      allow(uml_repo).to receive(:find_package)
        .with("NonExistent::Package")
        .and_return(nil)

      expect do
        workflow.generate_mapping_for_package("NonExistent::Package")
      end.to raise_error(RuntimeError, /Package not found/)
    end

    it "raises error when namespace cannot be determined" do
      uml_package = double("UmlPackage",
                           name: "NoNamespace",
                           qualified_name: "ModelRoot::NoNamespace")

      allow(uml_repo).to receive(:find_package)
        .with("ModelRoot::NoNamespace")
        .and_return(uml_package)

      allow(shapechange_config).to receive(:namespace_for_package)
        .with("ModelRoot::NoNamespace")
        .and_return(nil)

      expect do
        workflow.generate_mapping_for_package("ModelRoot::NoNamespace")
      end.to raise_error(RuntimeError, /Cannot determine XSD namespace/)
    end
  end
end
