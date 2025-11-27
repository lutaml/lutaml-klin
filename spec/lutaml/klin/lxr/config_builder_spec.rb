# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/lxr/config_builder"
require "lutaml/klin/lxr/errors"

RSpec.describe Lutaml::Klin::Lxr::ConfigBuilder do
  let(:builder) { described_class.new }

  describe "#initialize" do
    it "sets default xsd_mode" do
      expect(builder.xsd_mode).to eq("include_all")
    end

    it "sets default resolution_mode" do
      expect(builder.resolution_mode).to eq("resolved")
    end

    it "sets default serialization_format" do
      expect(builder.serialization_format).to eq("marshal")
    end

    it "accepts custom xsd_mode" do
      builder = described_class.new(xsd_mode: "allow_external")
      expect(builder.xsd_mode).to eq("allow_external")
    end

    it "accepts custom resolution_mode" do
      builder = described_class.new(resolution_mode: "bare")
      expect(builder.resolution_mode).to eq("bare")
    end

    it "accepts custom serialization_format" do
      builder = described_class.new(serialization_format: "json")
      expect(builder.serialization_format).to eq("json")
    end

    context "with invalid options" do
      it "raises ConfigurationError for invalid xsd_mode" do
        expect do
          described_class.new(xsd_mode: "invalid")
        end.to raise_error(
          Lutaml::Klin::Lxr::ConfigurationError,
          /Invalid xsd_mode/
        )
      end

      it "raises ConfigurationError for invalid resolution_mode" do
        expect do
          described_class.new(resolution_mode: "invalid")
        end.to raise_error(
          Lutaml::Klin::Lxr::ConfigurationError,
          /Invalid resolution_mode/
        )
      end

      it "raises ConfigurationError for invalid serialization_format" do
        expect do
          described_class.new(serialization_format: "invalid")
        end.to raise_error(
          Lutaml::Klin::Lxr::ConfigurationError,
          /Invalid serialization_format/
        )
      end
    end
  end

  describe "#build" do
    let(:schema_info) do
      {
        xsd_files: ["schema1.xsd", "schema2.xsd"],
        namespace_mappings: [
          { prefix: "urf", uri: "https://example.com/urf" },
          { prefix: "gml", uri: "http://www.opengis.net/gml/3.2" }
        ],
        schema_location_mappings: [
          { from: "http://example.com/schema1.xsd", to: "local/schema1.xsd" }
        ]
      }
    end

    let(:metadata) do
      {
        name: "Test Package",
        version: "1.0.0",
        description: "Test LXR package"
      }
    end

    it "returns a configuration hash" do
      result = builder.build(schema_info, metadata)
      expect(result).to be_a(Hash)
    end

    it "includes package metadata" do
      result = builder.build(schema_info, metadata)
      expect(result["package"]["name"]).to eq("Test Package")
      expect(result["package"]["version"]).to eq("1.0.0")
      expect(result["package"]["description"]).to eq("Test LXR package")
    end

    it "uses default package metadata when not provided" do
      result = builder.build(schema_info)
      expect(result["package"]["name"]).to eq("lxr_package")
      expect(result["package"]["version"]).to eq("1.0.0")
      expect(result["package"]["description"]).to match(/LXR package/)
    end

    it "includes schemas section with XSD files" do
      result = builder.build(schema_info, metadata)
      expect(result["schemas"]["files"]).to contain_exactly("schema1.xsd",
                                                            "schema2.xsd")
    end

    it "includes options section" do
      result = builder.build(schema_info, metadata)
      expect(result["options"]["xsd_mode"]).to eq("include_all")
      expect(result["options"]["resolution_mode"]).to eq("resolved")
      expect(result["options"]["serialization_format"]).to eq("marshal")
    end

    it "includes namespaces section when namespace_mappings present" do
      result = builder.build(schema_info, metadata)
      expect(result["namespaces"]).to be_an(Array)
      expect(result["namespaces"].size).to eq(2)
      expect(result["namespaces"].first["prefix"]).to eq("urf")
      expect(result["namespaces"].first["uri"]).to eq("https://example.com/urf")
    end

    it "includes schema_locations section when schema_location_mappings present" do
      result = builder.build(schema_info, metadata)
      expect(result["schema_locations"]).to be_an(Array)
      expect(result["schema_locations"].size).to eq(1)
      expect(result["schema_locations"].first["from"]).to eq("http://example.com/schema1.xsd")
      expect(result["schema_locations"].first["to"]).to eq("local/schema1.xsd")
    end

    context "when namespace_mappings is empty" do
      let(:schema_info) do
        {
          xsd_files: ["schema1.xsd"],
          namespace_mappings: []
        }
      end

      it "does not include namespaces section" do
        result = builder.build(schema_info)
        expect(result).not_to have_key("namespaces")
      end
    end

    context "when schema_location_mappings is empty" do
      let(:schema_info) do
        {
          xsd_files: ["schema1.xsd"],
          namespace_mappings: [],
          schema_location_mappings: []
        }
      end

      it "does not include schema_locations section" do
        result = builder.build(schema_info)
        expect(result).not_to have_key("schema_locations")
      end
    end

    context "with invalid schema_info" do
      it "raises InvalidInputError when schema_info is not a Hash" do
        expect do
          builder.build("invalid")
        end.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /must be a Hash/
        )
      end

      it "raises InvalidInputError when xsd_files is missing" do
        expect do
          builder.build({})
        end.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /must contain :xsd_files/
        )
      end

      it "raises InvalidInputError when xsd_files is not an Array" do
        expect do
          builder.build({ xsd_files: "not_an_array" })
        end.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /:xsd_files must be an Array/
        )
      end

      it "raises InvalidInputError when xsd_files is empty" do
        expect do
          builder.build({ xsd_files: [] })
        end.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /:xsd_files cannot be empty/
        )
      end
    end
  end

  describe "#build_and_write" do
    let(:schema_info) do
      {
        xsd_files: ["schema1.xsd"],
        namespace_mappings: [{ prefix: "test", uri: "http://test.com" }]
      }
    end

    let(:output_path) { "tmp/test_config.yaml" }

    before do
      FileUtils.mkdir_p("tmp")
    end

    after do
      FileUtils.rm_f(output_path)
    end

    it "builds configuration and writes to file" do
      result_path = builder.build_and_write(schema_info, output_path)
      expect(result_path).to eq(output_path)
      expect(File.exist?(output_path)).to be true
    end

    it "writes valid YAML" do
      builder.build_and_write(schema_info, output_path)
      content = YAML.load_file(output_path)
      expect(content).to be_a(Hash)
      expect(content["schemas"]["files"]).to include("schema1.xsd")
    end

    it "creates output directory if it doesn't exist" do
      nested_path = "tmp/nested/dir/config.yaml"
      builder.build_and_write(schema_info, nested_path)
      expect(File.exist?(nested_path)).to be true
      FileUtils.rm_rf("tmp/nested")
    end

    it "includes metadata in written config" do
      metadata = { name: "Test", version: "2.0.0" }
      builder.build_and_write(schema_info, output_path, metadata)
      content = YAML.load_file(output_path)
      expect(content["package"]["name"]).to eq("Test")
      expect(content["package"]["version"]).to eq("2.0.0")
    end
  end

  describe "custom configuration options" do
    let(:schema_info) do
      {
        xsd_files: ["schema1.xsd"],
        namespace_mappings: []
      }
    end

    it "uses custom xsd_mode in options" do
      builder = described_class.new(xsd_mode: "allow_external")
      result = builder.build(schema_info)
      expect(result["options"]["xsd_mode"]).to eq("allow_external")
    end

    it "uses custom resolution_mode in options" do
      builder = described_class.new(resolution_mode: "bare")
      result = builder.build(schema_info)
      expect(result["options"]["resolution_mode"]).to eq("bare")
    end

    it "uses custom serialization_format in options" do
      builder = described_class.new(serialization_format: "json")
      result = builder.build(schema_info)
      expect(result["options"]["serialization_format"]).to eq("json")
    end

    it "combines all custom options" do
      builder = described_class.new(
        xsd_mode: "allow_external",
        resolution_mode: "bare",
        serialization_format: "yaml"
      )
      result = builder.build(schema_info)
      expect(result["options"]["xsd_mode"]).to eq("allow_external")
      expect(result["options"]["resolution_mode"]).to eq("bare")
      expect(result["options"]["serialization_format"]).to eq("yaml")
    end
  end
end
