# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"

RSpec.describe "YAML Mapping Generation" do
  let(:lur_path) { File.expand_path("../fixtures/packages/plateau_all.lur", __dir__) }
  let(:config_path) { File.expand_path("../../examples/ShapeChangeConfig_Plateau_uro.xml", __dir__) }
  let(:output_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(output_dir)
  end

  describe "URO package" do
    it "generates YAML mapping file alongside XSD" do
      # Load UML repository
      uml_repository = Lutaml::Uml::UmlRepository.from_file(lur_path)

      # Parse config
      config = Lutaml::Klin::Shapechange::ConfigParser.parse_file(config_path)

      # Create generator with mapping enabled
      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        uml_repository,
        config,
        lur_path: lur_path,
        config_path: config_path,
        generate_mapping: true
      )

      # Generate schemas
      results = generator.generate_schemas(["uro"], output_dir)
      result = results.first

      # Verify XSD exists
      expect(File.exist?(result[:file])).to be true

      # Verify YAML mapping exists
      expect(File.exist?(result[:mapping_file])).to be true
      expect(result[:mapping_file]).to end_with("_mapping.yaml")

      # Load and validate YAML
      mapping = YAML.load_file(result[:mapping_file])

      # Check structure
      expect(mapping).to be_a(Hash)
      expect(mapping["version"]).to eq("1.0")
      expect(mapping["generated_at"]).to be_a(String)
      expect(mapping["package_mappings"]).to be_an(Array)
      expect(mapping["package_mappings"]).not_to be_empty

      # Check package mapping
      pkg_mapping = mapping["package_mappings"].first
      expect(pkg_mapping["uml_package_name"]).to eq("uro")
      expect(pkg_mapping["xsd_namespace"]).to include("uro")
      expect(pkg_mapping["class_mappings"]).to be_an(Array)
      expect(pkg_mapping["class_mappings"].size).to be > 200

      # Check class mapping
      class_mapping = pkg_mapping["class_mappings"].first
      expect(class_mapping["uml_name"]).to be_a(String)
      expect(class_mapping["xsd_element_name"]).to be_a(String)

      # Check transformation info
      if class_mapping["transformation_info"]
        expect(class_mapping["transformation_info"]["rules_applied"]).to be_an(Array)
      end

      # Check attribute mappings exist
      classes_with_attributes = pkg_mapping["class_mappings"].select do |cm|
        cm["attribute_mappings"] && !cm["attribute_mappings"].empty?
      end
      expect(classes_with_attributes.size).to be > 0

      # Verify attribute mapping structure
      if classes_with_attributes.any?
        attr_mapping = classes_with_attributes.first["attribute_mappings"].first
        expect(attr_mapping["uml_name"]).to be_a(String)
        expect(attr_mapping["xsd_name"]).to be_a(String)
        expect(attr_mapping["xsd_type"]).to be_a(String)
      end
    end
  end

  describe "with generate_mapping disabled" do
    it "does not generate YAML mapping file" do
      uml_repository = Lutaml::Uml::UmlRepository.from_file(lur_path)
      config = Lutaml::Klin::Shapechange::ConfigParser.parse_file(config_path)

      generator = Lutaml::Klin::Shapechange::XsdGenerator.new(
        uml_repository,
        config,
        lur_path: lur_path,
        config_path: config_path,
        generate_mapping: false
      )

      results = generator.generate_schemas(["uro"], output_dir)
      result = results.first

      # XSD should exist
      expect(File.exist?(result[:file])).to be true

      # YAML mapping should NOT exist
      expect(result[:mapping_file]).to be_nil
    end
  end
end