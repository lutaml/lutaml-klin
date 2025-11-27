# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe "Mapping Generation Integration", :integration do
  let(:plateau_base) do
    "/Users/mulgogi/src/mn/mn-samples-plateau"
  end

  let(:config_file) do
    File.join(
      plateau_base,
      "PLATEAU-Manual-Generator/src/ShapeChange-3.1.0",
      "ShapeChangeConfig_Plateau_urf.xml"
    )
  end

  let(:xsd_file) do
    File.join(
      plateau_base,
      "reference-docs/xsd/i-ur/urbanFunction.xsd"
    )
  end

  let(:output_file) { Tempfile.new(["mapping", ".yaml"]) }

  after do
    output_file.close
    output_file.unlink
  end

  describe "generating mapping from PLATEAU data" do
    it "generates valid YAML mapping from urbanFunction XSD" do
      unless File.exist?(xsd_file)
        skip "Skipping unless PLATEAU data is available"
      end

      generator = Lutaml::Klin::MappingGenerator.new(config_file)
      mapping = generator.generate_from_xsd(xsd_file)

      expect(mapping).to be_a(Lutaml::Klin::Mapping::SchemaMapping)
      expect(mapping.package_mappings).not_to be_empty

      # Test YAML serialization
      yaml_content = mapping.to_yaml
      expect(yaml_content).to include("package_mappings")

      # Verify it can be saved to file
      generator.save_mapping(mapping, output_file.path)
      expect(File.exist?(output_file.path)).to be true

      # Verify file content is valid YAML
      saved_content = File.read(output_file.path)
      expect { YAML.safe_load(saved_content) }.not_to raise_error
    end

    it "extracts correct namespace information" do
      unless File.exist?(xsd_file)
        skip "Skipping unless PLATEAU data is available"
      end

      generator = Lutaml::Klin::MappingGenerator.new(config_file)
      mapping = generator.generate_from_xsd(xsd_file)

      # urbanFunction.xsd should have i-ur namespace in package mappings
      namespaces = mapping.package_mappings.map(&:xsd_namespace).compact
      expect(namespaces).not_to be_empty
      expect(namespaces.any? do |ns|
        ns.include?("i-ur") || ns.include?("urbanFunction")
      end).to be true
    end

    it "creates package mappings with classes" do
      unless File.exist?(xsd_file)
        skip "Skipping unless PLATEAU data is available"
      end

      generator = Lutaml::Klin::MappingGenerator.new(config_file)
      mapping = generator.generate_from_xsd(xsd_file)

      expect(mapping.package_mappings).not_to be_empty

      # Check that at least one package has classes
      has_classes = mapping.package_mappings.any? do |pkg|
        pkg.class_mappings && !pkg.class_mappings.empty?
      end
      expect(has_classes).to be true
    end

    it "includes attribute mappings for classes" do
      unless File.exist?(xsd_file)
        skip "Skipping unless PLATEAU data is available"
      end

      generator = Lutaml::Klin::MappingGenerator.new(config_file)
      mapping = generator.generate_from_xsd(xsd_file)

      # Find a class with attributes
      class_with_attrs = mapping.package_mappings.flat_map(&:class_mappings).find do |cls|
        cls.attribute_mappings && !cls.attribute_mappings.empty?
      end

      expect(class_with_attrs).not_to be_nil
      expect(class_with_attrs.attribute_mappings.first).to be_a(
        Lutaml::Klin::Mapping::AttributeMapping
      )
    end
  end

  describe "error handling" do
    it "handles missing config file gracefully" do
      expect do
        Lutaml::Klin::MappingGenerator.new("/nonexistent/config.xml")
      end.to raise_error(Lutaml::Klin::FatalError, /Config file not found/)
    end

    it "handles missing XSD file gracefully" do
      unless File.exist?(config_file)
        skip "Skipping unless PLATEAU data is available"
      end

      generator = Lutaml::Klin::MappingGenerator.new(config_file)
      expect do
        generator.generate_from_xsd("/nonexistent/schema.xsd")
      end.to raise_error(Lutaml::Klin::FatalError, /XSD file not found/)
    end
  end
end
