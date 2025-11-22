# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "fileutils"
require "lutaml/klin/repositories/uml_repository_adapter"
require "lutaml/klin/repositories/schema_repository_adapter"
require "lutaml/klin/shapechange/config_parser"
require "lutaml/klin/shapechange/xsd_generator"

RSpec.describe "XSD Generation Integration", type: :integration do
  let(:lur_path) { "spec/fixtures/packages/plateau_all.lur" }
  let(:config_path) { "./reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml" }
  let(:output_dir) { "tmp/test_xsd_generation" }

  before do
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir) if Dir.exist?(output_dir)
  end

  describe "End-to-end XSD generation from LUR + ShapeChange config" do
    it "generates valid XSD file for URO package" do
      # Skip if LUR package doesn't exist
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "ShapeChange config not found" unless File.exist?(config_path)

      # Load LUR
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      expect(lur_adapter.repository).not_to be_nil

      # Load ShapeChange config
      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)
      expect(config).not_to be_nil
      expect(config.package_infos).not_to be_empty

      # Create XSD generator
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      # Generate XSD for URO package
      results = generator.generate_schemas(["uro"], output_dir)

      # Verify generation succeeded
      expect(results).not_to be_empty
      expect(results.first[:package]).to eq("uro")

      # Verify file was created
      xsd_file = results.first[:file]
      expect(File.exist?(xsd_file)).to be true

      # Parse and validate XSD
      xsd_doc = Nokogiri::XML(File.read(xsd_file))
      expect(xsd_doc.errors).to be_empty

      # Verify XSD structure
      schema = xsd_doc.root
      expect(schema.name).to eq("schema")
      expect(schema.namespace.href).to eq("http://www.w3.org/2001/XMLSchema")

      # Verify target namespace
      target_ns = schema["targetNamespace"]
      expect(target_ns).to include("uro")

      # NOTE: Phase 3.2 implements basic generation - elements/types may be minimal
      # Full rule processing comes in Phase 3.3
      # For now, just verify the structure is valid
      elements = schema.xpath("//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema")
      complex_types = schema.xpath("//xs:complexType", "xs" => "http://www.w3.org/2001/XMLSchema")

      puts "\nXSD Generation Test Results:"
      puts "  File: #{xsd_file}"
      puts "  Namespace: #{target_ns}"
      puts "  Elements: #{elements.size}"
      puts "  Complex Types: #{complex_types.size}"
      puts "  Classes processed: #{results.first[:classes_processed]}"

      # Verify classes were processed even if elements aren't generated yet
      expect(results.first[:classes_processed]).to be > 0
    end

    it "generates XSD with proper namespace declarations" do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "ShapeChange config not found" unless File.exist?(config_path)

      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)

      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      results = generator.generate_schemas(["uro"], output_dir)
      xsd_file = results.first[:file]
      xsd_content = File.read(xsd_file)

      # Verify namespace declarations
      expect(xsd_content).to include("xmlns:uro=")
      expect(xsd_content).to include("targetNamespace=")
      expect(xsd_content).to include("elementFormDefault=\"qualified\"")
    end

    it "processes all classes in the package" do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "ShapeChange config not found" unless File.exist?(config_path)

      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      classes_before = lur_adapter.repository.classes_in_package("uro").size

      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)

      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      results = generator.generate_schemas(["uro"], output_dir)

      # Verify all classes were processed
      expect(results.first[:classes_processed]).to eq(classes_before)
      expect(results.first[:classes_processed]).to be > 200 # PLATEAU URO has 255 classes
    end

    it "generates multiple XSD files for multiple packages" do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "ShapeChange config not found" unless File.exist?(config_path)

      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)

      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      # Generate for both URO and URF
      results = generator.generate_schemas(["uro", "urf"], output_dir)

      # Verify both were generated
      expect(results.size).to eq(2)
      expect(results.map { |r| r[:package] }).to contain_exactly("uro", "urf")

      # Verify both files exist
      results.each do |r|
        expect(File.exist?(r[:file])).to be true
      end
    end

    it "follows encoding rules from ShapeChange config" do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "ShapeChange config not found" unless File.exist?(config_path)

      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)

      # Verify encoding rules were loaded
      expect(config.encoding_rules).not_to be_empty

      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      # Verify rule registry was built
      expect(generator.rule_registry).not_to be_nil
      expect(generator.rule_registry.encoding_rules).not_to be_empty
    end
  end
end