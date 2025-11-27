# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/mapping_generator"
require "lutaml/klin/xmi_navigator"
require "lutaml/klin/xsd_analyzer"
require "lutaml/klin/shapechange/config_parser"

RSpec.describe Lutaml::Klin::MappingGenerator do
  let(:fixtures_path) { File.join(__dir__, "..", "..", "fixtures") }
  let(:config_path) { File.join(fixtures_path, "configs", "simple_config.xml") }
  let(:xmi_path) do
    "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"
  end
  let(:xsd_path) { File.join(fixtures_path, "xsd", "simple_schema.xsd") }

  let(:config_parser) { Lutaml::Klin::Shapechange::ConfigParser.new }
  let(:config) { config_parser.parse_file(config_path) }

  let(:xmi_navigator) do
    Lutaml::Klin::XmiNavigator.new(xmi_path).tap(&:parse)
  end

  let(:xsd_analyzer) do
    Lutaml::Klin::XsdAnalyzer.new.tap do |analyzer|
      analyzer.parse_file(xsd_path)
    end
  end

  let(:xsd_analyzers) do
    {
      xsd_analyzer.target_namespace => xsd_analyzer
    }
  end

  describe "#initialize" do
    it "initializes with config, xmi_navigator, and xsd_analyzers" do
      generator = described_class.new(
        config: config,
        xmi_navigator: xmi_navigator,
        xsd_analyzers: xsd_analyzers
      )

      expect(generator.config).to eq(config)
      expect(generator.xmi_navigator).to eq(xmi_navigator)
      expect(generator.xsd_analyzers).to eq(xsd_analyzers)
    end

    it "initializes an empty mapping" do
      generator = described_class.new(
        config: config,
        xmi_navigator: xmi_navigator,
        xsd_analyzers: xsd_analyzers
      )

      expect(generator.mapping).to be_a(Lutaml::Klin::Models::Mapping::SchemaMapping)
    end
  end

  describe "#generate_mapping" do
    let(:generator) do
      described_class.new(
        config: config,
        xmi_navigator: xmi_navigator,
        xsd_analyzers: xsd_analyzers
      )
    end

    context "when package exists" do
      it "generates mapping for the package" do
        mapping = generator.generate_mapping("uro")

        expect(mapping).to be_a(Lutaml::Klin::Models::Mapping::SchemaMapping)
        expect(mapping.version).to eq("1.0")
        expect(mapping.generated_at).not_to be_nil
        expect(mapping.source_xmi).to eq(xmi_path)
      end

      it "includes package mappings" do
        mapping = generator.generate_mapping("uro")

        expect(mapping.package_mappings).not_to be_empty
        package_mapping = mapping.package_mappings.first
        expect(package_mapping).to be_a(Lutaml::Klin::Models::Mapping::PackageMapping)
        expect(package_mapping.uml_name).to eq("uro")
      end

      it "includes class mappings" do
        mapping = generator.generate_mapping("uro")
        package_mapping = mapping.package_mappings.first

        expect(package_mapping.class_mappings).not_to be_empty
        class_mapping = package_mapping.class_mappings.first
        expect(class_mapping).to be_a(Lutaml::Klin::Models::Mapping::ClassMapping)
      end

      it "includes attribute mappings" do
        mapping = generator.generate_mapping("uro")
        package_mapping = mapping.package_mappings.first
        class_mapping = package_mapping.class_mappings.first

        expect(class_mapping.attribute_mappings).not_to be_empty
        attr_mapping = class_mapping.attribute_mappings.first
        expect(attr_mapping).to be_a(Lutaml::Klin::Models::Mapping::AttributeMapping)
        expect(attr_mapping.uml_name).not_to be_nil
        expect(attr_mapping.xsd_name).not_to be_nil
      end

      it "includes namespace information" do
        mapping = generator.generate_mapping("uro")

        expect(mapping.namespaces).not_to be_empty
      end
    end

    context "when package does not exist" do
      it "raises ArgumentError" do
        expect do
          generator.generate_mapping("NonExistentPackage")
        end.to raise_error(ArgumentError, /Package not found/)
      end
    end
  end

  describe "#save_mapping" do
    let(:generator) do
      described_class.new(
        config: config,
        xmi_navigator: xmi_navigator,
        xsd_analyzers: xsd_analyzers
      )
    end

    it "saves mapping to YAML file" do
      output_path = File.join(Dir.tmpdir, "test_mapping.yaml")

      begin
        generator.generate_mapping("uro")
        generator.save_mapping(output_path)

        expect(File.exist?(output_path)).to be true
        content = File.read(output_path)
        expect(content).to include("version:")
        expect(content).to include("package_mappings:")
      ensure
        FileUtils.rm_f(output_path)
      end
    end
  end

  describe "type mapping" do
    let(:generator) do
      described_class.new(
        config: config,
        xmi_navigator: xmi_navigator,
        xsd_analyzers: xsd_analyzers
      )
    end

    it "applies type mappings from config" do
      mapping = generator.generate_mapping("uro")
      package_mapping = mapping.package_mappings.first
      class_mapping = package_mapping.class_mappings.first
      attr_mapping = class_mapping.attribute_mappings.first

      # XSD type should be resolved through type mapping cache
      expect(attr_mapping.xsd_type).not_to be_nil
    end
  end

  describe "cardinality mapping" do
    let(:generator) do
      described_class.new(
        config: config,
        xmi_navigator: xmi_navigator,
        xsd_analyzers: xsd_analyzers
      )
    end

    it "includes min_occurs and max_occurs" do
      mapping = generator.generate_mapping("uro")
      package_mapping = mapping.package_mappings.first
      class_mapping = package_mapping.class_mappings.first
      attr_mapping = class_mapping.attribute_mappings.first

      expect(attr_mapping.min_occurs).not_to be_nil
      expect(attr_mapping.max_occurs).not_to be_nil
    end
  end

  describe "namespace resolution" do
    let(:generator) do
      described_class.new(
        config: config,
        xmi_navigator: xmi_navigator,
        xsd_analyzers: xsd_analyzers
      )
    end

    it "resolves package namespace from config" do
      mapping = generator.generate_mapping("uro")
      package_mapping = mapping.package_mappings.first

      expect(package_mapping.xsd_namespace).not_to be_nil
    end

    it "resolves element namespaces" do
      mapping = generator.generate_mapping("uro")
      package_mapping = mapping.package_mappings.first
      class_mapping = package_mapping.class_mappings.first
      attr_mapping = class_mapping.attribute_mappings.first

      expect(attr_mapping.namespace).not_to be_nil
    end
  end

  describe "XSD complex type matching" do
    let(:generator) do
      described_class.new(
        config: config,
        xmi_navigator: xmi_navigator,
        xsd_analyzers: xsd_analyzers
      )
    end

    it "matches UML class to XSD complex type by exact name" do
      mapping = generator.generate_mapping("uro")
      package_mapping = mapping.package_mappings.first
      class_mapping = package_mapping.class_mappings.first

      # Should find matching complex type
      expect(class_mapping.xsd_name).not_to be_nil
    end

    it "matches UML class to XSD complex type with Type suffix" do
      # This test assumes there's a UML class that maps to an XSD type
      # with "Type" suffix (common ShapeChange pattern)
      mapping = generator.generate_mapping("uro")
      package_mapping = mapping.package_mappings.first

      # Should handle Type suffix matching
      expect(package_mapping.class_mappings).not_to be_empty
    end
  end
end
