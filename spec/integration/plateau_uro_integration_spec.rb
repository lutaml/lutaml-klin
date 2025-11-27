# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "yaml"
require_relative "../../lib/lutaml/klin/xmi_navigator"
require_relative "../../lib/lutaml/klin/shapechange/config_parser"
require_relative "../../lib/lutaml/klin/commands/report_command"

RSpec.describe "PLATEAU URO Package Integration", :integration do
  let(:xmi_path) do
    "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"
  end
  let(:config_path) do
    "/Users/mulgogi/src/mn/mn-samples-plateau/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/ShapeChangeConfig_Plateau_uro.xml"
  end
  let(:package_name) { "uro" }

  describe "XMI Parsing" do
    it "successfully parses the PLATEAU URO XMI file" do
      skip "XMI file not available" unless File.exist?(xmi_path)

      navigator = Lutaml::Klin::XmiNavigator.new
      navigator.parse_file(xmi_path)

      expect(navigator.document).not_to be_nil
      expect(navigator.packages).not_to be_empty

      uro_package = navigator.find_package(package_name)
      expect(uro_package).not_to be_nil
      expect(uro_package.name).to eq(package_name)

      classes_in_uro = navigator.classes_in_package(package_name)
      expect(classes_in_uro.size).to eq(174)
    end

    it "extracts classes with correct structure" do
      skip "XMI file not available" unless File.exist?(xmi_path)

      navigator = Lutaml::Klin::XmiNavigator.new
      navigator.parse_file(xmi_path)
      navigator.find_package(package_name)

      # Verify some key classes exist
      classes_in_uro = navigator.classes_in_package(package_name)

      boundary_surface = classes_in_uro.find do |c|
        c.name == "_BoundarySurface"
      end
      expect(boundary_surface).not_to be_nil
      expect(boundary_surface.attributes.size).to be >= 2

      abstract_construction = classes_in_uro.find do |c|
        c.name == "AbstractConstruction"
      end
      expect(abstract_construction).not_to be_nil
      expect(abstract_construction.attributes.size).to be >= 10
    end
  end

  describe "ShapeChange Config Parsing" do
    it "successfully parses the PLATEAU URO config" do
      skip "Config file not available" unless File.exist?(config_path)

      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)

      expect(config).not_to be_nil
      expect(config).to be_a(Lutaml::Klin::Shapechange::ShapeChangeConfiguration)

      # Should have loaded some configuration data
      expect(config.xml_namespaces).not_to be_nil
      expect(config.xsd_map_entries).not_to be_nil
    end

    it "extracts type mappings from config" do
      skip "Config file not available" unless File.exist?(config_path)

      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)

      # Should have XsdMapEntry instances
      expect(config.xsd_map_entries).not_to be_empty
      expect(config.xsd_map_entries.first).to be_a(Lutaml::Klin::Shapechange::XsdMapEntry)
    end
  end

  describe "End-to-End Mapping Generation" do
    let(:output_file) { Tempfile.new(["uro_mapping", ".yaml"]) }

    after do
      output_file.close
      output_file.unlink
    end

    it "generates mapping YAML from real PLATEAU data" do
      skip "Requires XSD file"

      # This test will work once we have the XSD file
      # For now, it's marked as pending
      #
      # generator = Lutaml::Klin::MappingGenerator.new(
      #   config_path: config_path,
      #   xmi_path: xmi_path,
      #   xsd_path: xsd_path
      # )
      #
      # mapping = generator.generate_mapping(package_name)
      #
      # expect(mapping).to be_a(Lutaml::Klin::Models::Mapping::SchemaMapping)
      # expect(mapping.packages.size).to eq(1)
      # expect(mapping.packages.first.classes.size).to eq(174)
    end

    it "validates generated mapping structure" do
      skip "Requires complete workflow"

      # Validate that generated YAML has correct structure
      # yaml_content = File.read(output_file.path)
      # parsed = YAML.safe_load(yaml_content, permitted_classes: [Symbol])
      #
      # expect(parsed).to have_key("schema_mapping")
      # expect(parsed["schema_mapping"]).to have_key("packages")
    end
  end

  describe "Performance" do
    it "processes 174 classes in reasonable time" do
      skip "XMI file not available" unless File.exist?(xmi_path)

      start_time = Time.now

      navigator = Lutaml::Klin::XmiNavigator.new
      navigator.parse_file(xmi_path)
      classes = navigator.classes_in_package(package_name)

      elapsed = Time.now - start_time

      expect(classes.size).to eq(174)
      expect(elapsed).to be < 10.0 # Should complete in under 10 seconds
    end
  end

  describe "Data Validation" do
    it "verifies attribute types are correctly extracted" do
      skip "XMI file not available" unless File.exist?(xmi_path)

      navigator = Lutaml::Klin::XmiNavigator.new
      navigator.parse_file(xmi_path)
      classes_in_uro = navigator.classes_in_package(package_name)

      abstract_construction = classes_in_uro.find do |c|
        c.name == "AbstractConstruction"
      end

      # Check specific attributes
      date_attr = abstract_construction.attributes.find do |a|
        a.name == "dateOfConstruction"
      end
      expect(date_attr).not_to be_nil
      expect(date_attr.type).to eq("xs:date").or eq("date")

      condition_attr = abstract_construction.attributes.find do |a|
        a.name == "conditionOfConstruction"
      end
      expect(condition_attr).not_to be_nil
      expect(condition_attr.type).to eq("ConditionOfConstructionValue")
    end

    it "verifies class inheritance relationships" do
      skip "XMI file not available" unless File.exist?(xmi_path)

      navigator = Lutaml::Klin::XmiNavigator.new
      navigator.parse_file(xmi_path)
      classes_in_uro = navigator.classes_in_package(package_name)

      # Many PLATEAU classes inherit from base CityGML types
      # Verify inheritance is captured if available
      classes_with_generalizations = classes_in_uro.select do |c|
        c.respond_to?(:generalization) && c.generalization
      end

      # Should have some inheritance relationships
      expect(classes_with_generalizations).not_to be_empty if
        classes_in_uro.first.respond_to?(:generalization)
    end
  end

  describe "Report Generation" do
    let(:mapping_file) { Tempfile.new(["uro_mapping", ".yaml"]) }
    let(:report_file) { Tempfile.new(["uro_report", ".txt"]) }

    after do
      mapping_file.close
      mapping_file.unlink
      report_file.close
      report_file.unlink
    end

    it "generates human-readable report from mapping",
       pending: "Requires mapping generation" do
      skip "Requires complete workflow"

      # Once we have generated mappings, test report generation
      # command = Lutaml::Klin::Commands::ReportCommand.new(
      #   mapping_file: mapping_file.path,
      #   output_file: report_file.path
      # )
      #
      # expect { command.run }.not_to raise_error
      #
      # report_content = File.read(report_file.path)
      # expect(report_content).to include("TRANSFORMATION INVESTIGATION REPORT")
      # expect(report_content).to include("UML Class:")
      # expect(report_content).to include("XSD Element:")
    end
  end
end
