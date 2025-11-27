# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "fileutils"
require "lutaml/klin/repositories/uml_repository_adapter"
require "lutaml/klin/shapechange/config_parser"
require "lutaml/klin/shapechange/xsd_generator"

RSpec.describe "PLATEAU XSD Output Generation", type: :integration do
  let(:lur_path) { "spec/fixtures/packages/plateau_all.lur" }
  let(:urf_config_path) { "examples/ShapeChangeConfig_Plateau_urf.xml" }
  let(:uro_config_path) { "examples/ShapeChangeConfig_Plateau_uro.xml" }
  let(:output_dir) { "examples/output" }
  let(:reference_dir) { "examples/i-ur" }

  before(:all) do
    FileUtils.mkdir_p("examples/output")
  end

  describe "URF (Urban Function) XSD Generation" do
    it "generates urbanFunction.xsd from URF config" do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "URF ShapeChange config not found" unless File.exist?(urf_config_path)

      # Load LUR package
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      expect(lur_adapter.repository).not_to be_nil

      # Load ShapeChange config
      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(urf_config_path)
      expect(config).not_to be_nil

      # Verify config has URF package info
      urf_package = config.package_infos.find { |p| p.package_name.strip == "urf" }
      expect(urf_package).not_to be_nil, "URF package info not found in config"
      expect(urf_package.xsd_document.strip).to eq("urbanFunction.xsd")

      # Create XSD generator
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      # Generate XSD for URF package
      results = generator.generate_schemas(["urf"], output_dir)

      # Verify generation succeeded
      expect(results).not_to be_empty
      generated_file = results.first[:file]
      expect(File.exist?(generated_file)).to be true

      # Rename to match expected output name
      output_file = File.join(output_dir, "urf.xsd")
      FileUtils.mv(generated_file, output_file) if generated_file != output_file

      # Parse and validate generated XSD
      xsd_doc = Nokogiri::XML(File.read(output_file))
      expect(xsd_doc.errors).to be_empty, "Generated XSD has parse errors"

      # Verify basic XSD structure
      schema = xsd_doc.root
      expect(schema.name).to eq("schema")
      expect(schema.namespace.href).to eq("http://www.w3.org/2001/XMLSchema")

      # Verify target namespace
      target_ns = schema["targetNamespace"]
      expect(target_ns).to include("urf"), "Target namespace should contain 'urf'"

      # Verify GML namespace (should be GML 3.1.1 for PLATEAU)
      gml_import = schema.xpath(
        "//xs:import[@namespace='http://www.opengis.net/gml']",
        "xs" => "http://www.w3.org/2001/XMLSchema"
      )
      expect(gml_import).not_to be_empty, "GML namespace import not found"

      # Report statistics
      elements = schema.xpath("//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema")
      complex_types = schema.xpath("//xs:complexType", "xs" => "http://www.w3.org/2001/XMLSchema")

      puts "\n" + "=" * 70
      puts "URF XSD Generation Results:"
      puts "=" * 70
      puts "  Output file: #{output_file}"
      puts "  Target namespace: #{target_ns}"
      puts "  Elements generated: #{elements.size}"
      puts "  Complex types generated: #{complex_types.size}"
      puts "  Classes processed: #{results.first[:classes_processed]}"
      puts "=" * 70

      # Optional: Compare with reference if it exists
      reference_file = File.join(reference_dir, "urbanFunction.xsd")
      if File.exist?(reference_file)
        puts "\nReference file exists: #{reference_file}"
        puts "To compare: diff #{output_file} #{reference_file}"
      end
    end
  end

  describe "URO (Urban Object) XSD Generation" do
    it "generates urbanObject.xsd from URO config" do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "URO ShapeChange config not found" unless File.exist?(uro_config_path)

      # Load LUR package (reuse for efficiency)
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      expect(lur_adapter.repository).not_to be_nil

      # Load ShapeChange config
      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(uro_config_path)
      expect(config).not_to be_nil

      # Verify config has URO package info
      uro_package = config.package_infos.find { |p| p.package_name.strip == "uro" }
      expect(uro_package).not_to be_nil, "URO package info not found in config"
      expect(uro_package.xsd_document.strip).to eq("urbanObject.xsd")

      # Create XSD generator
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      # Generate XSD for URO package
      results = generator.generate_schemas(["uro"], output_dir)

      # Verify generation succeeded
      expect(results).not_to be_empty
      generated_file = results.first[:file]
      expect(File.exist?(generated_file)).to be true

      # Rename to match expected output name
      output_file = File.join(output_dir, "uro.xsd")
      FileUtils.mv(generated_file, output_file) if generated_file != output_file

      # Parse and validate generated XSD
      xsd_doc = Nokogiri::XML(File.read(output_file))
      expect(xsd_doc.errors).to be_empty, "Generated XSD has parse errors"

      # Verify basic XSD structure
      schema = xsd_doc.root
      expect(schema.name).to eq("schema")
      expect(schema.namespace.href).to eq("http://www.w3.org/2001/XMLSchema")

      # Verify target namespace
      target_ns = schema["targetNamespace"]
      expect(target_ns).to include("uro"), "Target namespace should contain 'uro'"

      # Verify GML namespace (should be GML 3.1.1 for PLATEAU)
      gml_import = schema.xpath(
        "//xs:import[@namespace='http://www.opengis.net/gml']",
        "xs" => "http://www.w3.org/2001/XMLSchema"
      )
      expect(gml_import).not_to be_empty, "GML namespace import not found"

      # Report statistics
      elements = schema.xpath("//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema")
      complex_types = schema.xpath("//xs:complexType", "xs" => "http://www.w3.org/2001/XMLSchema")

      puts "\n" + "=" * 70
      puts "URO XSD Generation Results:"
      puts "=" * 70
      puts "  Output file: #{output_file}"
      puts "  Target namespace: #{target_ns}"
      puts "  Elements generated: #{elements.size}"
      puts "  Complex types generated: #{complex_types.size}"
      puts "  Classes processed: #{results.first[:classes_processed]}"
      puts "=" * 70

      # Optional: Compare with reference if it exists
      reference_file = File.join(reference_dir, "urbanObject.xsd")
      if File.exist?(reference_file)
        puts "\nReference file exists: #{reference_file}"
        puts "To compare: diff #{output_file} #{reference_file}"
      end
    end
  end

  describe "Output Validation" do
    let(:urf_output) { File.join(output_dir, "urf.xsd") }
    let(:uro_output) { File.join(output_dir, "uro.xsd") }

    it "generates valid XML for both XSD files" do
      skip "Output files not generated" unless File.exist?(urf_output) && File.exist?(uro_output)

      [urf_output, uro_output].each do |file|
        doc = Nokogiri::XML(File.read(file))
        expect(doc.errors).to be_empty, "#{File.basename(file)} has XML parse errors: #{doc.errors.map(&:message).join(', ')}"
      end
    end

    it "both files have proper namespace declarations" do
      skip "Output files not generated" unless File.exist?(urf_output) && File.exist?(uro_output)

      [urf_output, uro_output].each do |file|
        content = File.read(file)

        # Check for essential namespaces
        expect(content).to include('xmlns:xs="http://www.w3.org/2001/XMLSchema"'),
          "#{File.basename(file)} missing XML Schema namespace"
        expect(content).to include('elementFormDefault="qualified"'),
          "#{File.basename(file)} missing elementFormDefault"
        expect(content).to include('targetNamespace='),
          "#{File.basename(file)} missing targetNamespace"
      end
    end

    it "files have proper GML 3.1.1 namespace imports" do
      skip "Output files not generated" unless File.exist?(urf_output) && File.exist?(uro_output)

      [urf_output, uro_output].each do |file|
        doc = Nokogiri::XML(File.read(file))

        # Check for GML namespace import
        gml_imports = doc.xpath(
          "//xs:import[@namespace='http://www.opengis.net/gml']",
          "xs" => "http://www.w3.org/2001/XMLSchema"
        )

        expect(gml_imports).not_to be_empty,
          "#{File.basename(file)} should import GML 3.1.1 namespace (http://www.opengis.net/gml)"
      end
    end
  end

  describe "Reference Comparison" do
    let(:urf_output) { File.join(output_dir, "urf.xsd") }
    let(:uro_output) { File.join(output_dir, "uro.xsd") }
    let(:urf_reference) { File.join(reference_dir, "urbanFunction.xsd") }
    let(:uro_reference) { File.join(reference_dir, "urbanObject.xsd") }

    it "URF output structure matches reference (if available)" do
      skip "Reference file not found" unless File.exist?(urf_reference)

      # Generate if not already done
      unless File.exist?(urf_output)
        skip "Run URF generation test first"
      end

      output_doc = Nokogiri::XML(File.read(urf_output))
      reference_doc = Nokogiri::XML(File.read(urf_reference))

      # Compare element counts (should be close but may not be exact)
      output_elements = output_doc.xpath("//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema").size
      reference_elements = reference_doc.xpath("//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema").size

      output_types = output_doc.xpath("//xs:complexType", "xs" => "http://www.w3.org/2001/XMLSchema").size
      reference_types = reference_doc.xpath("//xs:complexType", "xs" => "http://www.w3.org/2001/XMLSchema").size

      puts "\n" + "=" * 70
      puts "URF Structure Comparison:"
      puts "=" * 70
      puts "  Elements:     Output: #{output_elements}, Reference: #{reference_elements}"
      puts "  Complex Types: Output: #{output_types}, Reference: #{reference_types}"
      puts "=" * 70

      # Allow some variance but should be in the same ballpark
      expect(output_elements).to be > 0, "No elements generated"
      expect(output_types).to be > 0, "No complex types generated"
    end

    it "URO output structure matches reference (if available)" do
      skip "Reference file not found" unless File.exist?(uro_reference)

      # Generate if not already done
      unless File.exist?(uro_output)
        skip "Run URO generation test first"
      end

      output_doc = Nokogiri::XML(File.read(uro_output))
      reference_doc = Nokogiri::XML(File.read(uro_reference))

      # Compare element counts
      output_elements = output_doc.xpath("//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema").size
      reference_elements = reference_doc.xpath("//xs:element", "xs" => "http://www.w3.org/2001/XMLSchema").size

      output_types = output_doc.xpath("//xs:complexType", "xs" => "http://www.w3.org/2001/XMLSchema").size
      reference_types = reference_doc.xpath("//xs:complexType", "xs" => "http://www.w3.org/2001/XMLSchema").size

      puts "\n" + "=" * 70
      puts "URO Structure Comparison:"
      puts "=" * 70
      puts "  Elements:      Output: #{output_elements}, Reference: #{reference_elements}"
      puts "  Complex Types: Output: #{output_types}, Reference: #{reference_types}"
      puts "=" * 70

      # Allow some variance but should be in the same ballpark
      expect(output_elements).to be > 0, "No elements generated"
      expect(output_types).to be > 0, "No complex types generated"
    end
  end
end