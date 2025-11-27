# frozen_string_literal: true

require "spec_helper"
require "nokogiri"
require "fileutils"
require "lutaml/klin/repositories/uml_repository_adapter"
require "lutaml/klin/shapechange/config_parser"
require "lutaml/klin/shapechange/xsd_generator"

RSpec.describe "Complete ShapeChange Parity Validation", type: :integration do
  let(:lur_path) { "spec/fixtures/packages/plateau_all.lur" }
  let(:output_dir) { "tmp/complete_parity_test" }
  
  # URO package paths
  let(:uro_config_path) { "examples/ShapeChangeConfig_Plateau_uro.xml" }
  let(:uro_reference_path) { "spec/fixtures/shapechange/urbanObject.xsd" }
  let(:uro_output_path) { File.join(output_dir, "urbanObject.xsd") }
  
  # URF package paths
  let(:urf_config_path) { "examples/ShapeChangeConfig_Plateau_urf.xml" }
  let(:urf_reference_path) { "spec/fixtures/shapechange/urbanFunction.xsd" }
  let(:urf_output_path) { File.join(output_dir, "urbanFunction.xsd") }

  before(:all) do
    @output_dir = "tmp/complete_parity_test"
    FileUtils.mkdir_p(@output_dir)
  end

  after(:all) do
    # Keep generated files for inspection
    # FileUtils.rm_rf(@output_dir)
  end

  describe "URO Package (Urban Object)" do
    before do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "URO config not found" unless File.exist?(uro_config_path)
      skip "URO reference not found" unless File.exist?(uro_reference_path)
    end

    it "generates XSD with perfect structural match" do
      # Generate URO XSD
      generate_xsd("uro", uro_config_path, output_dir)

      # Load generated and reference XSDs
      generated = load_xsd(uro_output_path)
      reference = load_xsd(uro_reference_path)

      # Validate structural parity
      validate_structural_parity(generated, reference, "urbanObject.xsd")
    end

    it "validates default namespace (no xs: prefix)" do
      generate_xsd("uro", uro_config_path, output_dir)
      
      generated = load_xsd(uro_output_path)
      root = generated.root

      # Check that schema element uses default namespace
      expect(root.name).to eq("schema")
      expect(root.namespace.prefix).to be_nil
      expect(root.namespace.href).to eq("http://www.w3.org/2001/XMLSchema")

      puts "\n✓ URO uses default XML Schema namespace (no xs: prefix)"
    end

    it "validates complete content match" do
      generate_xsd("uro", uro_config_path, output_dir)

      generated = load_xsd(uro_output_path)
      reference = load_xsd(uro_reference_path)

      validate_content_parity(generated, reference, "urbanObject.xsd")
    end

    it "validates namespace declarations" do
      generate_xsd("uro", uro_config_path, output_dir)

      generated = load_xsd(uro_output_path)
      reference = load_xsd(uro_reference_path)

      validate_namespace_parity(generated, reference, "urbanObject.xsd")
    end
  end

  describe "URF Package (Urban Function)" do
    before do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "URF config not found" unless File.exist?(urf_config_path)
      skip "URF reference not found" unless File.exist?(urf_reference_path)
    end

    it "generates XSD with perfect structural match" do
      generate_xsd("urf", urf_config_path, output_dir)

      generated = load_xsd(urf_output_path)
      reference = load_xsd(urf_reference_path)

      validate_structural_parity(generated, reference, "urbanFunction.xsd")
    end

    it "validates default namespace (no xs: prefix)" do
      generate_xsd("urf", urf_config_path, output_dir)
      
      generated = load_xsd(urf_output_path)
      root = generated.root

      expect(root.name).to eq("schema")
      expect(root.namespace.prefix).to be_nil
      expect(root.namespace.href).to eq("http://www.w3.org/2001/XMLSchema")

      puts "\n✓ URF uses default XML Schema namespace (no xs: prefix)"
    end

    it "validates complete content match" do
      generate_xsd("urf", urf_config_path, output_dir)

      generated = load_xsd(urf_output_path)
      reference = load_xsd(urf_reference_path)

      validate_content_parity(generated, reference, "urbanFunction.xsd")
    end

    it "validates namespace declarations" do
      generate_xsd("urf", urf_config_path, output_dir)

      generated = load_xsd(urf_output_path)
      reference = load_xsd(urf_reference_path)

      validate_namespace_parity(generated, reference, "urbanFunction.xsd")
    end
  end

  private

  def generate_xsd(package_name, config_path, output_dir)
    lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
    config = Lutaml::Klin::Shapechange::ConfigParser.new.parse_file(config_path)
    generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
      lur_adapter.repository,
      config
    )

    generator.generate_schemas([package_name], output_dir)
  end

  def load_xsd(file_path)
    Nokogiri::XML(File.read(file_path)) do |config|
      config.strict.noblanks
    end
  end

  def validate_structural_parity(generated, reference, filename)
    puts "\n#{'=' * 80}"
    puts "Structural Parity Validation: #{filename}"
    puts "=" * 80

    # Count top-level elements
    ref_elements = count_top_level_elements(reference)
    gen_elements = count_top_level_elements(generated)

    puts "\n📝 Top-level elements:"
    puts "  Reference: #{ref_elements[:total]} (#{ref_elements[:with_subst]} with substitutionGroup, #{ref_elements[:without_subst]} without)"
    puts "  Generated: #{gen_elements[:total]} (#{gen_elements[:with_subst]} with substitutionGroup, #{gen_elements[:without_subst]} without)"

    expect(gen_elements[:total]).to eq(ref_elements[:total]),
      "Element count mismatch"
    expect(gen_elements[:with_subst]).to eq(ref_elements[:with_subst]),
      "SubstitutionGroup element count mismatch"
    expect(gen_elements[:without_subst]).to eq(ref_elements[:without_subst]),
      "Non-substitutionGroup element count mismatch"

    # Count complex types
    ref_types = reference.xpath("//complexType[@name]").size
    gen_types = generated.xpath("//complexType[@name]").size

    puts "\n📝 Complex types:"
    puts "  Reference: #{ref_types}"
    puts "  Generated: #{gen_types}"

    expect(gen_types).to eq(ref_types),
      "Complex type count mismatch"

    puts "\n✅ PERFECT STRUCTURAL MATCH"
    puts "=" * 80
  end

  def count_top_level_elements(doc)
    # Only count top-level elements (direct children of schema)
    # Use local-name() to work regardless of namespace prefix
    elements = doc.xpath("//*[local-name()='schema']/*[local-name()='element'][@name]")
    
    with_subst = elements.select { |e| e["substitutionGroup"] }
    without_subst = elements.reject { |e| e["substitutionGroup"] }

    {
      total: elements.size,
      with_subst: with_subst.size,
      without_subst: without_subst.size
    }
  end

  def validate_content_parity(generated, reference, filename)
    puts "\n#{'=' * 80}"
    puts "Content Parity Validation: #{filename}"
    puts "=" * 80

    # Compare element names
    ref_elem_names = extract_element_names(reference)
    gen_elem_names = extract_element_names(generated)

    puts "\n📝 Element names validation:"
    missing = ref_elem_names - gen_elem_names
    extra = gen_elem_names - ref_elem_names

    if missing.empty? && extra.empty?
      puts "  ✅ All #{ref_elem_names.size} element names match"
    else
      puts "  ❌ Element name mismatches found:"
      puts "     Missing: #{missing.inspect}" unless missing.empty?
      puts "     Extra: #{extra.inspect}" unless extra.empty?
    end

    expect(gen_elem_names).to match_array(ref_elem_names),
      "Element names must match exactly"

    # Compare type names
    ref_type_names = extract_type_names(reference)
    gen_type_names = extract_type_names(generated)

    puts "\n📝 Type names validation:"
    missing_types = ref_type_names - gen_type_names
    extra_types = gen_type_names - ref_type_names

    if missing_types.empty? && extra_types.empty?
      puts "  ✅ All #{ref_type_names.size} type names match"
    else
      puts "  ❌ Type name mismatches found:"
      puts "     Missing: #{missing_types.inspect}" unless missing_types.empty?
      puts "     Extra: #{extra_types.inspect}" unless extra_types.empty?
    end

    expect(gen_type_names).to match_array(ref_type_names),
      "Type names must match exactly"

    # Compare substitutionGroup attributes
    ref_subst = extract_substitution_groups(reference)
    gen_subst = extract_substitution_groups(generated)

    puts "\n📝 SubstitutionGroup validation:"
    puts "  ✅ All #{ref_subst.size} substitutionGroup declarations match" if ref_subst == gen_subst

    expect(gen_subst).to eq(ref_subst),
      "SubstitutionGroup attributes must match exactly"

    # Compare base types (inheritance)
    ref_bases = extract_base_types(reference)
    gen_bases = extract_base_types(generated)

    puts "\n📝 Base type validation (inheritance):"
    puts "  ✅ All #{ref_bases.size} base types match" if ref_bases == gen_bases

    expect(gen_bases).to eq(ref_bases),
      "Base types (inheritance) must match exactly"

    puts "\n✅ PERFECT CONTENT MATCH"
    puts "=" * 80
  end

  def extract_element_names(doc)
    doc.xpath("//*[local-name()='schema']/*[local-name()='element'][@name]")
       .map { |e| e["name"] }
       .sort
  end

  def extract_type_names(doc)
    doc.xpath("//*[local-name()='complexType'][@name]")
       .map { |t| t["name"] }
       .sort
  end

  def extract_substitution_groups(doc)
    doc.xpath("//*[local-name()='element'][@substitutionGroup]")
       .map { |e| [e["name"], e["substitutionGroup"]] }
       .sort
  end

  def extract_base_types(doc)
    doc.xpath("//*[local-name()='extension'][@base]")
       .map { |e| e["base"] }
       .sort
  end

  def validate_namespace_parity(generated, reference, filename)
    puts "\n#{'=' * 80}"
    puts "Namespace Parity Validation: #{filename}"
    puts "=" * 80

    # Extract namespace prefixes from both documents
    ref_prefixes = extract_namespace_prefixes(reference)
    gen_prefixes = extract_namespace_prefixes(generated)

    puts "\n📝 Namespace prefixes:"
    puts "  Reference: #{ref_prefixes.sort.join(', ')}"
    puts "  Generated: #{gen_prefixes.sort.join(', ')}"

    # Check that both use same prefixes
    missing = ref_prefixes - gen_prefixes
    extra = gen_prefixes - ref_prefixes

    if missing.empty? && extra.empty?
      puts "  ✅ All namespace prefixes match"
    else
      puts "  ❌ Namespace prefix mismatches:"
      puts "     Missing: #{missing.inspect}" unless missing.empty?
      puts "     Extra: #{extra.inspect}" unless extra.empty?
    end

    expect(gen_prefixes).to match_array(ref_prefixes),
      "Namespace prefixes must match"

    puts "\n✅ PERFECT NAMESPACE MATCH"
    puts "=" * 80
  end

  def extract_namespace_prefixes(doc)
    prefixes = Set.new

    # Scan all type attributes for prefixes
    doc.xpath(".//@type").each do |attr|
      if attr.value.include?(":")
        prefix = attr.value.split(":").first
        # Exclude "xs" prefix since we use default namespace
        prefixes << prefix unless prefix == "xs"
      end
    end

    # Scan all ref attributes
    doc.xpath(".//@ref").each do |attr|
      if attr.value.include?(":")
        prefix = attr.value.split(":").first
        prefixes << prefix unless prefix == "xs"
      end
    end

    # Scan all base attributes
    doc.xpath(".//@base").each do |attr|
      if attr.value.include?(":")
        prefix = attr.value.split(":").first
        prefixes << prefix unless prefix == "xs"
      end
    end

    # Scan all substitutionGroup attributes
    doc.xpath(".//@substitutionGroup").each do |attr|
      if attr.value.include?(":")
        prefix = attr.value.split(":").first
        prefixes << prefix unless prefix == "xs"
      end
    end

    prefixes.to_a
  end
end
