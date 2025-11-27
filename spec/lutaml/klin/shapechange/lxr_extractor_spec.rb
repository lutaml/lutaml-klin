# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/lxr_extractor"
require "lutaml/klin/shapechange/config_parser"

RSpec.describe Lutaml::Klin::Shapechange::LxrExtractor do
  let(:config_path) do
    File.expand_path(
      "../../../../reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml",
      __dir__
    )
  end

  let(:extractor) { described_class.new }

  describe "#extract_schema_info" do
    it "extracts comprehensive schema information from ShapeChange config" do
      result = extractor.extract_schema_info(config_path)

      expect(result).to be_a(Hash)
      expect(result).to have_key(:xsd_files)
      expect(result).to have_key(:namespace_mappings)
      expect(result).to have_key(:schema_location_mappings)
    end

    it "returns array of XSD file paths" do
      result = extractor.extract_schema_info(config_path)

      expect(result[:xsd_files]).to be_an(Array)
      expect(result[:xsd_files]).not_to be_empty
    end

    it "returns array of namespace mappings" do
      result = extractor.extract_schema_info(config_path)

      expect(result[:namespace_mappings]).to be_an(Array)
      expect(result[:namespace_mappings]).not_to be_empty

      # Check first mapping has required structure
      first_mapping = result[:namespace_mappings].first
      expect(first_mapping).to have_key(:prefix)
      expect(first_mapping).to have_key(:uri)
    end

    it "returns array of schema location mappings" do
      result = extractor.extract_schema_info(config_path)

      expect(result[:schema_location_mappings]).to be_an(Array)
    end
  end

  describe "#extract_xsd_files" do
    let(:parser) { Lutaml::Klin::Shapechange::ConfigParser.new }
    let(:config) { parser.parse_file(config_path) }

    it "extracts XSD files from PackageInfo xsdDocument attributes" do
      xsd_files = extractor.extract_xsd_files(config)

      expect(xsd_files).to be_an(Array)
      expect(xsd_files).not_to be_empty

      # Should extract files like "urbanFunction.xsd", "urbanObject.xsd"
      expect(xsd_files.any? do |f|
        f.include?("urbanFunction") || f.include?("urbanObject")
      end).to be true
    end

    it "extracts XSD files from XmlNamespace location attributes" do
      xsd_files = extractor.extract_xsd_files(config)

      # Should include XSD locations from namespace elements
      expect(xsd_files.any? { |f| f.end_with?(".xsd") }).to be true
    end

    it "returns unique XSD file paths" do
      xsd_files = extractor.extract_xsd_files(config)

      expect(xsd_files).to eq(xsd_files.uniq)
    end

    it "filters out non-XSD locations" do
      xsd_files = extractor.extract_xsd_files(config)

      xsd_files.each do |file|
        expect(file).to match(/\.xsd$|xsd/)
      end
    end
  end

  describe "#extract_namespace_mappings" do
    let(:parser) { Lutaml::Klin::Shapechange::ConfigParser.new }
    let(:config) { parser.parse_file(config_path) }

    it "extracts namespace prefix-to-URI mappings" do
      mappings = extractor.extract_namespace_mappings(config)

      expect(mappings).to be_an(Array)
      expect(mappings).not_to be_empty
    end

    it "includes mappings from PackageInfo elements" do
      mappings = extractor.extract_namespace_mappings(config)

      # Should include urf and uro mappings
      urf_mapping = mappings.find { |m| m[:prefix]&.strip == "urf" }
      uro_mapping = mappings.find { |m| m[:prefix]&.strip == "uro" }

      expect(urf_mapping).not_to be_nil
      if urf_mapping
        expect(urf_mapping[:uri]).to include("geospatial.jp/iur/urf")
      end

      expect(uro_mapping).not_to be_nil
      if uro_mapping
        expect(uro_mapping[:uri]).to include("geospatial.jp/iur/uro")
      end
    end

    it "includes mappings from XmlNamespace elements" do
      mappings = extractor.extract_namespace_mappings(config)

      # Should include gml mapping
      gml_mapping = mappings.find { |m| m[:prefix]&.strip == "gml" }

      expect(gml_mapping).not_to be_nil
      expect(gml_mapping[:uri]).to include("opengis.net/gml") if gml_mapping
    end

    it "deduplicates mappings by URI" do
      mappings = extractor.extract_namespace_mappings(config)

      uris = mappings.map { |m| m[:uri] }
      expect(uris).to eq(uris.uniq)
    end

    it "returns mappings with correct structure" do
      mappings = extractor.extract_namespace_mappings(config)

      mappings.each do |mapping|
        expect(mapping).to have_key(:prefix)
        expect(mapping).to have_key(:uri)
        expect(mapping[:prefix]).to be_a(String)
        expect(mapping[:uri]).to be_a(String)
      end
    end
  end

  describe "#extract_schema_location_mappings" do
    let(:parser) { Lutaml::Klin::Shapechange::ConfigParser.new }
    let(:config) { parser.parse_file(config_path) }

    it "extracts schema location mappings" do
      mappings = extractor.extract_schema_location_mappings(config)

      expect(mappings).to be_an(Array)
    end

    it "creates mappings from XmlNamespace locations" do
      mappings = extractor.extract_schema_location_mappings(config)

      # Should have mappings for remote schemas to local paths
      mappings.each do |mapping|
        expect(mapping).to have_key(:from)
        expect(mapping).to have_key(:to)
      end
    end

    it "normalizes schema paths for local mapping" do
      mappings = extractor.extract_schema_location_mappings(config)

      mappings.each do |mapping|
        # Local paths should be in reference-docs/xsd/ structure
        if mapping[:to]
          expect(mapping[:to]).to match(%r{reference-docs/xsd/|\.xsd})
        end
      end
    end
  end

  describe "integration with existing ConfigParser" do
    it "works seamlessly with parsed configuration" do
      parser = Lutaml::Klin::Shapechange::ConfigParser.new
      config = parser.parse_file(config_path)

      # Should be able to extract from parsed config
      xsd_files = extractor.extract_xsd_files(config)
      namespace_mappings = extractor.extract_namespace_mappings(config)
      extractor.extract_schema_location_mappings(config)

      expect(xsd_files).not_to be_empty
      expect(namespace_mappings).not_to be_empty
    end

    it "uses custom parser if provided" do
      custom_parser = Lutaml::Klin::Shapechange::ConfigParser.new
      custom_extractor = described_class.new(parser: custom_parser)

      expect(custom_extractor.parser).to eq(custom_parser)
    end
  end

  describe "output format compatibility" do
    it "returns data structure compatible with lutaml-xsd package building" do
      result = extractor.extract_schema_info(config_path)

      # Expected structure:
      # {
      #   xsd_files: [...],
      #   namespace_mappings: [{ prefix: String, uri: String }],
      #   schema_location_mappings: [{ from: String, to: String }]
      # }

      expect(result[:xsd_files]).to all(be_a(String))

      result[:namespace_mappings].each do |mapping|
        expect(mapping).to match(hash_including(prefix: String, uri: String))
      end

      result[:schema_location_mappings].each do |mapping|
        expect(mapping).to match(hash_including(from: String, to: String))
      end
    end
  end
end
