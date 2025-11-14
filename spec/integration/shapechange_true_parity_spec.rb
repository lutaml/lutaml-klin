require "spec_helper"
require "nokogiri"
require "fileutils"

RSpec.describe "ShapeChange True Parity (Against Unmodified Reference)" do
  before(:all) do
    @reference_dir = File.expand_path("../../fixtures/shapechange_unmodified", __FILE__)
    @generated_dir = File.expand_path("../../../tmp/true_parity_test", __FILE__)
    FileUtils.mkdir_p(@generated_dir)
  end

  after(:all) do
    # Keep generated files for inspection
    # FileUtils.rm_rf(@generated_dir)
  end

  let(:reference_dir) { @reference_dir }
  let(:generated_dir) { @generated_dir }

  describe "URO (Urban Object) package" do
    let(:reference_file) { File.join(reference_dir, "urbanObject.xsd") }
    let(:generated_file) { File.join(generated_dir, "urbanObject.xsd") }

    before do
      skip "Reference file not found" unless File.exist?(reference_file)
      skip "XSD generation not yet implemented" # Remove this when ready
    end

    it "matches unmodified ShapeChange output exactly" do
      # TODO: Generate XSD using lutaml-klin
      # This will be implemented once the XSD generator is ready
      #
      # Example code structure:
      # lur_file = File.expand_path("../../../packages/plateau_all.lur", __FILE__)
      # config_file = File.expand_path("../../../reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml", __FILE__)
      #
      # generator = Lutaml::Klin::XsdGenerator.new(lur_file, config_file)
      # generator.generate_package("uro", generated_file)

      # Load both XSD files
      reference_doc = load_xsd(reference_file)
      generated_doc = load_xsd(generated_file)

      # Perform comprehensive comparison
      compare_xsd_structure(reference_doc, generated_doc, "urbanObject.xsd")
    end

    it "contains no VBA modification markers" do
      reference_content = File.read(reference_file)

      expect(reference_content).not_to include("整形プログラム")
      expect(reference_content).not_to include("_GenericApplicationPropertyOf")
    end

    it "has correct element count without VBA additions" do
      reference_doc = load_xsd(reference_file)

      # Count all xs:element declarations
      elements = reference_doc.xpath("//xs:element", ns_map)

      # The reference should NOT have the 99 VBA-added elements
      # We verify this by checking that specific VBA-added elements don't exist
      vba_elements = [
        "bldgDataQualityAttribute",
        "bridBaseAttribute",
        "ifcBuildingAttribute",
        "pointCloud"
      ]

      vba_elements.each do |elem_name|
        global_elem = reference_doc.xpath(
          "//xs:element[@name='#{elem_name}' and @substitutionGroup]",
          ns_map
        )
        expect(global_elem).to be_empty,
          "Found VBA-added element '#{elem_name}' in unmodified reference"
      end
    end
  end

  describe "URF (Urban Function) package" do
    let(:reference_file) { File.join(reference_dir, "urbanFunction.xsd") }
    let(:generated_file) { File.join(generated_dir, "urbanFunction.xsd") }

    before do
      skip "Reference file not found" unless File.exist?(reference_file)
      skip "XSD generation not yet implemented" # Remove this when ready
    end

    it "matches unmodified ShapeChange output exactly" do
      # TODO: Generate XSD using lutaml-klin
      #
      # generator = Lutaml::Klin::XsdGenerator.new(lur_file, config_file)
      # generator.generate_package("urf", generated_file)

      # Load both XSD files
      reference_doc = load_xsd(reference_file)
      generated_doc = load_xsd(generated_file)

      # Perform comprehensive comparison
      compare_xsd_structure(reference_doc, generated_doc, "urbanFunction.xsd")
    end

    it "contains no VBA modifications (was not modified by VBA)" do
      reference_content = File.read(reference_file)

      # urbanFunction.xsd was never modified by VBA
      expect(reference_content).not_to include("整形プログラム")
    end
  end

  private

  def ns_map
    {
      "xs" => "http://www.w3.org/2001/XMLSchema",
      "gml" => "http://www.opengis.net/gml/3.2",
      "uro" => "https://www.geospatial.jp/iur/uro/3.0",
      "urf" => "https://www.geospatial.jp/iur/urf/3.0"
    }
  end

  def load_xsd(file_path)
    Nokogiri::XML(File.read(file_path)) do |config|
      config.strict.noblanks
    end
  end

  def compare_xsd_structure(reference_doc, generated_doc, filename)
    puts "\n" + "=" * 80
    puts "Comparing XSD Structure: #{filename}"
    puts "=" * 80

    # Compare namespace declarations
    compare_namespaces(reference_doc, generated_doc)

    # Compare imports
    compare_imports(reference_doc, generated_doc)

    # Compare complex types
    compare_complex_types(reference_doc, generated_doc)

    # Compare simple types
    compare_simple_types(reference_doc, generated_doc)

    # Compare global elements
    compare_global_elements(reference_doc, generated_doc)

    # Compare attribute groups
    compare_attribute_groups(reference_doc, generated_doc)

    puts "=" * 80
  end

  def compare_namespaces(reference_doc, generated_doc)
    ref_ns = reference_doc.root.namespaces
    gen_ns = generated_doc.root.namespaces

    expect(gen_ns).to eq(ref_ns),
      "Namespace declarations don't match:\n" \
      "Reference: #{ref_ns.inspect}\n" \
      "Generated: #{gen_ns.inspect}"

    puts "✓ Namespace declarations match (#{ref_ns.size} namespaces)"
  end

  def compare_imports(reference_doc, generated_doc)
    ref_imports = reference_doc.xpath("//xs:import", ns_map)
    gen_imports = generated_doc.xpath("//xs:import", ns_map)

    ref_import_data = extract_import_data(ref_imports)
    gen_import_data = extract_import_data(gen_imports)

    expect(gen_import_data).to match_array(ref_import_data),
      "Import declarations don't match:\n" \
      "Missing: #{(ref_import_data - gen_import_data).inspect}\n" \
      "Extra: #{(gen_import_data - ref_import_data).inspect}"

    puts "✓ Import declarations match (#{ref_imports.size} imports)"
  end

  def extract_import_data(imports)
    imports.map do |imp|
      {
        namespace: imp["namespace"],
        schema_location: imp["schemaLocation"]
      }
    end
  end

  def compare_complex_types(reference_doc, generated_doc)
    ref_types = reference_doc.xpath("//xs:complexType", ns_map)
    gen_types = generated_doc.xpath("//xs:complexType", ns_map)

    ref_type_names = ref_types.map { |t| t["name"] }.compact.sort
    gen_type_names = gen_types.map { |t| t["name"] }.compact.sort

    expect(gen_type_names).to match_array(ref_type_names),
      "Complex type names don't match:\n" \
      "Missing: #{(ref_type_names - gen_type_names).inspect}\n" \
      "Extra: #{(gen_type_names - ref_type_names).inspect}"

    puts "✓ Complex types match (#{ref_types.size} types)"

    # Compare each complex type in detail
    ref_type_names.each do |type_name|
      ref_type = ref_types.find { |t| t["name"] == type_name }
      gen_type = gen_types.find { |t| t["name"] == type_name }

      compare_complex_type_structure(ref_type, gen_type, type_name)
    end
  end

  def compare_complex_type_structure(ref_type, gen_type, type_name)
    # Compare annotations (documentation)
    ref_docs = ref_type.xpath(".//xs:documentation", ns_map).map(&:text)
    gen_docs = gen_type.xpath(".//xs:documentation", ns_map).map(&:text)

    unless ref_docs == gen_docs
      puts "  ⚠ Documentation differs for #{type_name}"
    end

    # Compare structure (sequence, choice, etc.)
    ref_structure = extract_type_structure(ref_type)
    gen_structure = extract_type_structure(gen_type)

    expect(gen_structure).to eq(ref_structure),
      "Structure differs for complex type '#{type_name}'"
  end

  def extract_type_structure(complex_type)
    {
      base: complex_type.xpath(".//xs:extension/@base", ns_map).first&.value,
      sequence_elements: complex_type.xpath(".//xs:sequence/xs:element", ns_map).map { |e|
        {
          name: e["name"],
          type: e["type"],
          min_occurs: e["minOccurs"],
          max_occurs: e["maxOccurs"]
        }
      },
      attributes: complex_type.xpath(".//xs:attribute", ns_map).map { |a|
        {
          name: a["name"],
          type: a["type"],
          use: a["use"]
        }
      }
    }
  end

  def compare_simple_types(reference_doc, generated_doc)
    ref_types = reference_doc.xpath("//xs:simpleType", ns_map)
    gen_types = generated_doc.xpath("//xs:simpleType", ns_map)

    ref_type_names = ref_types.map { |t| t["name"] }.compact.sort
    gen_type_names = gen_types.map { |t| t["name"] }.compact.sort

    expect(gen_type_names).to match_array(ref_type_names),
      "Simple type names don't match:\n" \
      "Missing: #{(ref_type_names - gen_type_names).inspect}\n" \
      "Extra: #{(gen_type_names - ref_type_names).inspect}"

    puts "✓ Simple types match (#{ref_types.size} types)"
  end

  def compare_global_elements(reference_doc, generated_doc)
    # Only top-level elements directly under xs:schema
    ref_elements = reference_doc.xpath("/xs:schema/xs:element", ns_map)
    gen_elements = generated_doc.xpath("/xs:schema/xs:element", ns_map)

    ref_elem_names = ref_elements.map { |e| e["name"] }.sort
    gen_elem_names = gen_elements.map { |e| e["name"] }.sort

    expect(gen_elem_names).to match_array(ref_elem_names),
      "Global element names don't match:\n" \
      "Missing: #{(ref_elem_names - gen_elem_names).inspect}\n" \
      "Extra: #{(gen_elem_names - ref_elem_names).inspect}"

    puts "✓ Global elements match (#{ref_elements.size} elements)"

    # Verify no VBA-style substitution group elements
    vba_style_elements = gen_elements.select { |e| e["substitutionGroup"]&.include?("_GenericApplicationPropertyOf") }

    expect(vba_style_elements).to be_empty,
      "Found VBA-style substitution group elements in generated XSD: " \
      "#{vba_style_elements.map { |e| e['name'] }.inspect}"
  end

  def compare_attribute_groups(reference_doc, generated_doc)
    ref_groups = reference_doc.xpath("//xs:attributeGroup", ns_map)
    gen_groups = generated_doc.xpath("//xs:attributeGroup", ns_map)

    ref_group_names = ref_groups.map { |g| g["name"] }.compact.sort
    gen_group_names = gen_groups.map { |g| g["name"] }.compact.sort

    expect(gen_group_names).to match_array(ref_group_names),
      "Attribute group names don't match:\n" \
      "Missing: #{(ref_group_names - gen_group_names).inspect}\n" \
      "Extra: #{(gen_group_names - ref_group_names).inspect}"

    puts "✓ Attribute groups match (#{ref_groups.size} groups)"
  end
end