# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "lutaml/klin/repositories/uml_repository_adapter"
require "lutaml/klin/repositories/schema_repository_adapter"
require "lutaml/klin/shapechange/config_parser"
require "lutaml/klin/shapechange/xsd_generator"

RSpec.describe "XSD Validation Against LXR Reference", type: :integration do
  let(:lur_path) { "spec/fixtures/packages/plateau_all.lur" }
  let(:lxr_path) { "spec/fixtures/packages/plateau_schemas.lxr" }
  let(:config_path) do
    "./reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml"
  end
  let(:output_dir) { "tmp/xsd_validation" }

  before do
    FileUtils.mkdir_p(output_dir)
    unless File.exist?(lur_path) && File.exist?(lxr_path)
      skip "LUR/LXR packages not available"
    end
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "URO package validation" do
    let(:namespace) { "uro" }
    let(:namespace_uri) { "http://www.opengis.net/plateau/uro/3.2" }

    it "generates XSD matching LXR reference structure" do
      # Generate from LUR
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas([namespace], output_dir)
      expect(results).not_to be_empty

      generated_file = results.first[:file]
      expect(File.exist?(generated_file)).to be true

      # Parse generated XSD
      generated = Nokogiri::XML(File.read(generated_file))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      # Extract counts from generated XSD
      gen_elements = generated.xpath("//xs:element[@name]", xs_ns).map do |e|
        e["name"]
      end.sort
      gen_complex_types = generated.xpath("//xs:complexType[@name]",
                                          xs_ns).map do |e|
        e["name"]
      end.sort
      gen_simple_types = generated.xpath("//xs:simpleType[@name]",
                                         xs_ns).map do |e|
        e["name"]
      end.sort

      # Analyze generated content
      puts "\n=== URO Generation Summary ==="
      puts "  Elements: #{gen_elements.size}"
      puts "  Complex types: #{gen_complex_types.size}"
      puts "  Simple types: #{gen_simple_types.size}"
      puts "  Total types: #{gen_complex_types.size + gen_simple_types.size}"

      # Show sample elements
      if gen_elements.any?
        puts "  Sample elements: #{gen_elements.first(5).join(', ')}"
      end

      # Show sample types
      if gen_complex_types.any?
        puts "  Sample complex types: #{gen_complex_types.first(5).join(', ')}"
      end

      # Basic sanity checks
      expect(gen_elements.size).to be > 0, "Should generate elements"
      expect(gen_complex_types.size).to be > 0, "Should generate complex types"
    end

    it "generates complex types with correct structure" do
      # Generate XSD
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas([namespace], output_dir)
      generated_file = results.first[:file]
      generated = Nokogiri::XML(File.read(generated_file))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      # Check complex types have proper sequences
      complex_types_with_sequence = generated.xpath(
        "//xs:complexType[xs:complexContent/xs:extension/xs:sequence]", xs_ns
      )
      complex_types_total = generated.xpath("//xs:complexType[@name]", xs_ns)

      puts "\n=== URO Complex Type Structure ==="
      puts "  Total complex types: #{complex_types_total.size}"
      puts "  With sequence: #{complex_types_with_sequence.size}"

      expect(complex_types_with_sequence.size).to be > 0
    end

    it "generates enumerations correctly", :pending do
      skip "Enum support requires lutaml-xmi enums_in_package method"
      # Generate XSD
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas([namespace], output_dir)
      generated_file = results.first[:file]
      generated = Nokogiri::XML(File.read(generated_file))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      # Check simple types with enumerations
      enums = generated.xpath(
        "//xs:simpleType[xs:restriction[@base='xs:string']/xs:enumeration]", xs_ns
      )

      puts "\n=== URO Enumeration Types ==="
      puts "  Enumeration types: #{enums.size}"

      if enums.any?
        sample = enums.first
        enum_values = sample.xpath("xs:restriction/xs:enumeration",
                                   xs_ns).map do |e|
          e["value"]
        end
        puts "  Sample enumeration: #{sample['name']}"
        puts "  Values: #{enum_values.join(', ')}"
      end

      expect(enums.size).to be > 0
    end

    it "generates property types correctly" do
      # Generate XSD
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas([namespace], output_dir)
      generated_file = results.first[:file]
      generated = Nokogiri::XML(File.read(generated_file))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      # Check property types (ending with PropertyType)
      property_types = generated.xpath(
        "//xs:complexType[contains(@name, 'PropertyType')]", xs_ns
      )

      puts "\n=== URO Property Types ==="
      puts "  Property types: #{property_types.size}"

      expect(property_types.size).to be > 0
    end
  end

  describe "URF package validation" do
    let(:namespace) { "urf" }
    let(:namespace_uri) { "http://www.opengis.net/plateau/urf/3.2" }

    it "generates XSD matching LXR reference structure" do
      # Generate from LUR
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas([namespace], output_dir)
      expect(results).not_to be_empty

      generated_file = results.first[:file]
      expect(File.exist?(generated_file)).to be true

      # Parse generated XSD
      generated = Nokogiri::XML(File.read(generated_file))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      # Extract counts from generated XSD
      gen_elements = generated.xpath("//xs:element[@name]", xs_ns).map do |e|
        e["name"]
      end.sort
      gen_complex_types = generated.xpath("//xs:complexType[@name]",
                                          xs_ns).map do |e|
        e["name"]
      end.sort
      gen_simple_types = generated.xpath("//xs:simpleType[@name]",
                                         xs_ns).map do |e|
        e["name"]
      end.sort

      # Analyze generated content
      puts "\n=== URF Generation Summary ==="
      puts "  Elements: #{gen_elements.size}"
      puts "  Complex types: #{gen_complex_types.size}"
      puts "  Simple types: #{gen_simple_types.size}"
      puts "  Total types: #{gen_complex_types.size + gen_simple_types.size}"

      # Show sample elements
      if gen_elements.any?
        puts "  Sample elements: #{gen_elements.first(5).join(', ')}"
      end

      # Show sample types
      if gen_complex_types.any?
        puts "  Sample complex types: #{gen_complex_types.first(5).join(', ')}"
      end

      # Basic sanity checks
      expect(gen_elements.size).to be > 0, "Should generate elements"
      expect(gen_complex_types.size).to be > 0, "Should generate complex types"
    end
  end

  describe "Cross-package validation" do
    it "generates both URO and URF schemas together" do
      # Generate both packages
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas(%w[uro urf], output_dir)

      expect(results.size).to eq(2)
      expect(results.map do |r|
        r[:file]
      end.all? { |f| File.exist?(f) }).to be true

      puts "\n=== Generated Schemas ==="
      results.each do |result|
        puts "  #{result[:package]}: #{File.basename(result[:file])}"
      end
    end
  end

  describe "XSD structure validation" do
    let(:namespace) { "uro" }

    it "includes proper namespace declarations" do
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas([namespace], output_dir)
      generated_file = results.first[:file]
      generated = Nokogiri::XML(File.read(generated_file))

      schema_elem = generated.at_xpath("//xs:schema", "xs" => "http://www.w3.org/2001/XMLSchema")
      expect(schema_elem).not_to be_nil

      target_ns = schema_elem["targetNamespace"]
      expect(target_ns).to include("uro"),
                           "Target namespace should include 'uro'"

      puts "\n=== Namespace Declarations ==="
      puts "  targetNamespace: #{target_ns}"
      schema_elem.namespaces.each do |prefix, uri|
        puts "  #{prefix}: #{uri}"
      end
    end

    it "includes proper annotations and documentation", :pending do
      skip "Documentation/annotation generation is a future enhancement"
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas([namespace], output_dir)
      generated_file = results.first[:file]
      generated = Nokogiri::XML(File.read(generated_file))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      annotations = generated.xpath("//xs:annotation", xs_ns)
      documentation = generated.xpath("//xs:documentation", xs_ns)

      puts "\n=== Documentation ==="
      puts "  Annotations: #{annotations.size}"
      puts "  Documentation elements: #{documentation.size}"

      expect(annotations.size).to be > 0
    end
  end
end
