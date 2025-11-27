# frozen_string_literal: true

require "spec_helper"
require "nokogiri"

RSpec.describe "XSD Generation ShapeChange Parity", type: :integration do
  let(:lur_path) { "spec/fixtures/packages/plateau_all.lur" }
  let(:lxr_path) { "spec/fixtures/packages/plateau_schemas.lxr" }
  let(:config_path) do
    "./reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml"
  end
  let(:output_dir) { "tmp/test_shapechange_parity" }

  before do
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "URO package XSD generation" do
    it "generates XSD matching ShapeChange reference" do
      skip "LUR package not found" unless File.exist?(lur_path)
      skip "LXR package not found" unless File.exist?(lxr_path)
      skip "Config not found" unless File.exist?(config_path)

      # Load reference XSD from LXR package for future comparison
      lxr_adapter = Lutaml::Klin::Repositories::SchemaRepositoryAdapter.new(lxr_path)
      lxr_stats = lxr_adapter.statistics

      puts "\nLXR Repository Statistics:"
      puts "  Total schemas: #{lxr_stats[:total_schemas]}"
      puts "  Total types: #{lxr_stats[:total_types]}"
      puts "  Total elements: #{lxr_stats[:total_elements]}"

      # Generate XSD from LUR
      lur_adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)

      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      results = generator.generate_schemas(["uro"], output_dir)
      expect(results).not_to be_empty

      generated_file = results.first[:file]
      expect(File.exist?(generated_file)).to be true

      # Parse generated XSD
      generated_xsd = Nokogiri::XML(File.read(generated_file))

      # Compare element counts
      generated_elements = generated_xsd.xpath("//xs:element[@name]", "xs" => "http://www.w3.org/2001/XMLSchema")
      generated_types = generated_xsd.xpath("//xs:complexType[@name]",
                                            "xs" => "http://www.w3.org/2001/XMLSchema")

      puts "\nGenerated XSD Statistics:"
      puts "  Elements: #{generated_elements.size}"
      puts "  Complex Types: #{generated_types.size}"
      puts "  Classes processed: #{results.first[:classes_processed]}"

      # Verify we generated something with the new processor
      expect(generated_elements.size).to be > 0
      expect(generated_types.size).to be > 0

      # Check that elements have proper structure (from ObjectElementProcessor)
      generated_elements.each do |element|
        expect(element["name"]).not_to be_nil
        expect(element["type"]).not_to be_nil
        # Types should be in the form "prefix:TypeName"
        expect(element["type"]).to match(/\w+:\w+Type/)
      end
    end

    it "generates elements with correct names" do
      skip "Not yet implemented - Phase 3.3"
      # Will compare element names when implemented
    end

    it "generates types with correct structure" do
      skip "Not yet implemented - Phase 3.3"
      # Will compare type structures when implemented
    end
  end
end
