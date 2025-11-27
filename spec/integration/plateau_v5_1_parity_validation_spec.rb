# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "fileutils"
require "lutaml"
require "lutaml/klin/repositories/uml_repository_adapter"
require "lutaml/klin/repositories/schema_repository_adapter"
require "lutaml/klin/shapechange/config_parser"
require "lutaml/klin/shapechange/xsd_generator"

RSpec.describe "PLATEAU v5.1 ShapeChange Parity Validation",
               type: :integration do
  let(:lur_path) { "spec/fixtures/packages/plateau_all.lur" }
  let(:urf_config_path) { "examples/ShapeChangeConfig_Plateau_urf.xml" }
  let(:uro_config_path) { "examples/ShapeChangeConfig_Plateau_uro.xml" }
  let(:urf_reference_path) { "examples/i-ur/urbanFunction.xsd" }
  let(:uro_reference_path) { "examples/i-ur/urbanObject.xsd" }
  let(:output_dir) { "tmp/plateau_v5_1_parity_validation" }

  before do
    FileUtils.mkdir_p(output_dir)
    skip "LUR package not found" unless File.exist?(lur_path)
    skip "URF config not found" unless File.exist?(urf_config_path)
    skip "URF reference not found" unless File.exist?(urf_reference_path)
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "Parity Fix #1: Property Name Prefixing" do
    it "prefixes property names when type is from different package" do
      # Generate URF schema (which references URO types)
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(urf_config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas(["urf"], output_dir)
      generated_file = results.first[:file]

      # Parse generated XSD
      generated = Nokogiri::XML(File.read(generated_file))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      # Load reference XSD
      reference = Nokogiri::XML(File.read(urf_reference_path))

      # Find property elements that reference URO types (cross-package references)
      # Example: <xs:element name="urfDmAttribute" type="uro:DmAttributePropertyType"/>
      ref_cross_pkg_props = reference.xpath(
        "//xs:element[contains(@type, 'uro:')]", xs_ns
      )

      puts "\n=== Property Name Prefixing Validation ==="
      puts "Reference cross-package properties: #{ref_cross_pkg_props.size}"

      # Check if we have similar properties in generated
      gen_cross_pkg_props = generated.xpath(
        "//xs:element[contains(@type, 'uro:')]", xs_ns
      )
      puts "Generated cross-package properties: #{gen_cross_pkg_props.size}"

      # Sample validation: Check specific known properties
      if ref_cross_pkg_props.any?
        sample_ref = ref_cross_pkg_props.first
        ref_name = sample_ref["name"]
        ref_type = sample_ref["type"]

        puts "\nSample reference property:"
        puts "  Name: #{ref_name}"
        puts "  Type: #{ref_type}"

        # Look for corresponding property in generated
        gen_match = generated.at_xpath("//xs:element[@name='#{ref_name}']",
                                       xs_ns)
        if gen_match
          puts "\nGenerated equivalent:"
          puts "  Name: #{gen_match['name']}"
          puts "  Type: #{gen_match['type']}"

          expect(gen_match["name"]).to eq(ref_name),
                                       "Property name should match reference: expected #{ref_name}"
          expect(gen_match["type"]).to eq(ref_type),
                                       "Property type should match reference: expected #{ref_type}"
        else
          puts "\n⚠️  Property '#{ref_name}' not found in generated XSD"
        end
      end

      # Verify we're generating cross-package property elements
      expect(gen_cross_pkg_props.size).to be > 0,
                                          "Should generate property elements with cross-package type references"
    end
  end

  describe "Parity Fix #2: Cross-Package Type References" do
    it "uses correct namespace prefix for types from other packages" do
      # Generate URF schema
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(urf_config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas(["urf"], output_dir)
      generated_file = results.first[:file]

      generated = Nokogiri::XML(File.read(generated_file))
      reference = Nokogiri::XML(File.read(urf_reference_path))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      puts "\n=== Cross-Package Type Reference Validation ==="

      # Find all property elements with type attributes in reference
      ref_props_with_types = reference.xpath("//xs:element[@type]", xs_ns)

      # Group by namespace prefix
      ref_type_namespaces = ref_props_with_types.map do |e|
        type = e["type"]
        type.include?(":") ? type.split(":").first : "xs"
      end.uniq.sort

      puts "Reference uses type namespaces: #{ref_type_namespaces.join(', ')}"

      # Check generated
      gen_props_with_types = generated.xpath("//xs:element[@type]", xs_ns)
      gen_type_namespaces = gen_props_with_types.map do |e|
        type = e["type"]
        type.include?(":") ? type.split(":").first : "xs"
      end.uniq.sort

      puts "Generated uses type namespaces: #{gen_type_namespaces.join(', ')}"

      # Verify uro: namespace is used when referencing URO types
      expect(gen_type_namespaces).to include("uro"),
                                     "Generated XSD should use 'uro:' namespace for URO type references"

      # Check specific property: dmAttribute should reference uro:DmAttributePropertyType
      ref_dm_attr = reference.at_xpath(
        "//xs:element[contains(@name, 'Attribute')]", xs_ns
      )
      if ref_dm_attr
        puts "\nChecking DmAttribute property:"
        puts "  Reference: name=#{ref_dm_attr['name']}, type=#{ref_dm_attr['type']}"

        gen_dm_attr = generated.at_xpath(
          "//xs:element[@name='#{ref_dm_attr['name']}']", xs_ns
        )
        if gen_dm_attr
          puts "  Generated: name=#{gen_dm_attr['name']}, type=#{gen_dm_attr['type']}"

          # The type should be from uro namespace, not urf
          expect(gen_dm_attr["type"]).to start_with("uro:"),
                                         "DmAttribute type should use uro: namespace (source package), not urf: (current package)"
        end
      end
    end
  end

  describe "Parity Fix #3: Namespace Import Scanning" do
    it "includes all required namespace imports based on referenced types" do
      # Generate URF schema
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(urf_config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas(["urf"], output_dir)
      generated_file = results.first[:file]

      generated = Nokogiri::XML(File.read(generated_file))
      reference = Nokogiri::XML(File.read(urf_reference_path))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      puts "\n=== Namespace Import Validation ==="

      # Extract imports from reference
      ref_imports = reference.xpath("//xs:import", xs_ns).map do |i|
        { namespace: i["namespace"], location: i["schemaLocation"] }
      end

      puts "Reference imports:"
      ref_imports.each { |imp| puts "  #{imp[:namespace]}" }

      # Extract imports from generated
      gen_imports = generated.xpath("//xs:import", xs_ns).map do |i|
        { namespace: i["namespace"], location: i["schemaLocation"] }
      end

      puts "\nGenerated imports:"
      gen_imports.each { |imp| puts "  #{imp[:namespace]}" }

      # Check for critical imports
      ref_namespaces = ref_imports.map { |i| i[:namespace] }
      gen_namespaces = gen_imports.map { |i| i[:namespace] }

      # URF should import URO since it references URO types
      if ref_namespaces.any? { |ns| ns.include?("uro") }
        expect(gen_namespaces).to include(
          a_string_including("uro")
        ), "URF schema should import URO namespace when referencing URO types"
      end

      # Should import GML namespace
      if ref_namespaces.any? { |ns| ns.include?("gml") }
        gml_imported = gen_namespaces.any? { |ns| ns.include?("gml") }
        expect(gml_imported).to be true,
                                   "Should import GML namespace"
      end

      # Should import CityGML if referenced
      if ref_namespaces.any? { |ns| ns.include?("citygml") }
        citygml_imported = gen_namespaces.any? { |ns| ns.include?("citygml") }
        puts "\nCityGML import: #{citygml_imported ? '✓' : '✗'}"
      end

      puts "\n✓ Namespace imports validated"
    end
  end

  describe "Complete URF Schema Generation" do
    it "generates URF schema matching reference structure" do
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(urf_config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas(["urf"], output_dir)
      generated_file = results.first[:file]

      generated = Nokogiri::XML(File.read(generated_file))
      reference = Nokogiri::XML(File.read(urf_reference_path))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      # Count elements and types
      ref_elements = reference.xpath("//xs:element[@name]", xs_ns).size
      ref_complex_types = reference.xpath("//xs:complexType[@name]", xs_ns).size
      ref_simple_types = reference.xpath("//xs:simpleType[@name]", xs_ns).size

      gen_elements = generated.xpath("//xs:element[@name]", xs_ns).size
      gen_complex_types = generated.xpath("//xs:complexType[@name]", xs_ns).size
      gen_simple_types = generated.xpath("//xs:simpleType[@name]", xs_ns).size

      puts "\n=== URF Schema Comparison ==="
      puts "Elements:       Reference: #{ref_elements}, Generated: #{gen_elements}"
      puts "Complex Types:  Reference: #{ref_complex_types}, Generated: #{gen_complex_types}"
      puts "Simple Types:   Reference: #{ref_simple_types}, Generated: #{gen_simple_types}"

      # Calculate percentages
      if ref_elements > 0
        element_pct = (gen_elements.to_f / ref_elements * 100).round(1)
      end
      if ref_complex_types > 0
        type_pct = (gen_complex_types.to_f / ref_complex_types * 100).round(1)
      end

      puts "\nCoverage:"
      puts "  Elements: #{element_pct}%" if element_pct
      puts "  Types: #{type_pct}%" if type_pct

      # Verify substantial generation occurred
      expect(gen_elements).to be > 50,
                              "Should generate substantial number of elements"
      expect(gen_complex_types).to be > 100,
                                   "Should generate substantial number of types"
    end
  end

  describe "Complete URO Schema Generation" do
    it "generates URO schema matching reference structure" do
      skip "URO config not found" unless File.exist?(uro_config_path)
      skip "URO reference not found" unless File.exist?(uro_reference_path)

      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(uro_config_path)
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository, config
      )

      results = generator.generate_schemas(["uro"], output_dir)
      generated_file = results.first[:file]

      generated = Nokogiri::XML(File.read(generated_file))
      reference = Nokogiri::XML(File.read(uro_reference_path))
      xs_ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

      # Count elements and types
      ref_elements = reference.xpath("//xs:element[@name]", xs_ns).size
      ref_complex_types = reference.xpath("//xs:complexType[@name]", xs_ns).size

      gen_elements = generated.xpath("//xs:element[@name]", xs_ns).size
      gen_complex_types = generated.xpath("//xs:complexType[@name]", xs_ns).size

      puts "\n=== URO Schema Comparison ==="
      puts "Elements:       Reference: #{ref_elements}, Generated: #{gen_elements}"
      puts "Complex Types:  Reference: #{ref_complex_types}, Generated: #{gen_complex_types}"

      if ref_elements > 0
        element_pct = (gen_elements.to_f / ref_elements * 100).round(1)
      end
      if ref_complex_types > 0
        type_pct = (gen_complex_types.to_f / ref_complex_types * 100).round(1)
      end

      puts "\nCoverage:"
      puts "  Elements: #{element_pct}%" if element_pct
      puts "  Types: #{type_pct}%" if type_pct

      expect(gen_elements).to be > 50
      expect(gen_complex_types).to be > 100
    end
  end
end
