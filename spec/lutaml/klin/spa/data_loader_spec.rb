# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/data_loader"
require "tempfile"

RSpec.describe Lutaml::Klin::Spa::DataLoader do
  let(:loader) { described_class.new(verbose: false) }

  describe "#load_lxr" do
    it "raises error when LXR file does not exist" do
      expect do
        loader.load_lxr("nonexistent.lxr")
      end.to raise_error(
        Lutaml::Klin::Spa::DataLoadError,
        /LXR package not found/
      )
    end

    context "with valid LXR package" do
      let(:lxr_file) do
        Tempfile.new(["test", ".lxr"]).tap do |f|
          f.write("mock lxr content")
          f.close
        end
      end

      after { lxr_file.unlink }

      it "loads LXR package successfully" do
        result = loader.load_lxr(lxr_file.path)

        expect(result).to be_a(Hash)
        expect(result).to have_key(:metadata)
        expect(result).to have_key(:namespaces)
        expect(result).to have_key(:elements)
        expect(result).to have_key(:complex_types)
        expect(result).to have_key(:simple_types)
        expect(result).to have_key(:attributes)
        expect(result).to have_key(:statistics)
      end

      it "extracts metadata from LXR package" do
        result = loader.load_lxr(lxr_file.path)

        expect(result[:metadata][:path]).to eq(lxr_file.path)
        expect(result[:metadata][:version]).to eq("1.0")
        expect(result[:metadata][:created_at]).to be_a(String)
      end
    end
  end

  describe "#load_yaml" do
    it "raises error when YAML file does not exist" do
      expect do
        loader.load_yaml("nonexistent.yaml")
      end.to raise_error(
        Lutaml::Klin::Spa::DataLoadError,
        /YAML mapping file not found/
      )
    end

    context "with valid YAML mapping" do
      let(:yaml_file) do
        Tempfile.new(["test", ".yaml"]).tap do |f|
          f.write(<<~YAML)
            schema_mapping:
              source:
                name: "Test Schema"
                version: "1.0"
                description: "Test description"
              traceability:
                resolution_strategies:
                  - type_override
                  - schema_repository
                lxr_package:
                  path: "test.lxr"
                  version: "1.0"
                  created_at: "2024-01-01T00:00:00Z"
            mapping:
              uro:Building:
                uml_class: "BuildingClass"
                uml_package: "uro"
                stereotype: "featureType"
                resolution_strategy: "type_override"
          YAML
          f.close
        end
      end

      after { yaml_file.unlink }

      it "parses YAML mapping file" do
        result = loader.load_yaml(yaml_file.path)

        expect(result).to be_a(Hash)
        expect(result).to have_key(:traceability)
        expect(result).to have_key(:source)
        expect(result).to have_key(:mappings)
      end

      it "extracts traceability info" do
        result = loader.load_yaml(yaml_file.path)

        expect(result[:traceability]).to be_a(
          Lutaml::Klin::Spa::Models::Traceability
        )
        expect(result[:traceability].resolution_strategies).to include(
          "type_override"
        )
      end

      it "extracts UML mappings" do
        result = loader.load_yaml(yaml_file.path)

        expect(result[:mappings]).to be_a(Hash)
        expect(result[:mappings]["uro:Building"]).to be_a(
          Lutaml::Klin::Spa::Models::UmlMapping
        )
        expect(result[:mappings]["uro:Building"].uml_class).to eq(
          "BuildingClass"
        )
      end
    end
  end

  describe "#merge" do
    let(:lxr_data) do
      {
        metadata: {
          path: "test.lxr",
          version: "1.0",
          created_at: Time.now.iso8601
        },
        namespaces: [
          {
            id: "uro",
            prefix: "uro",
            uri: "http://example.com/uro",
            name: "URO"
          }
        ],
        elements: [],
        complex_types: [],
        simple_types: [],
        attributes: [],
        statistics: Lutaml::Klin::Spa::Models::Statistics.new
      }
    end

    it "merges LXR and YAML data correctly" do
      result = loader.merge(lxr_data, nil)

      expect(result).to be_a(Lutaml::Klin::Spa::Models::UnifiedSchema)
      expect(result.metadata).to be_a(
        Lutaml::Klin::Spa::Models::SchemaMetadata
      )
      expect(result.schemas).to be_an(Array)
      expect(result.elements).to be_an(Array)
      expect(result.complex_types).to be_an(Array)
      expect(result.simple_types).to be_an(Array)
      expect(result.attributes).to be_an(Array)
    end

    it "handles YAML-only mode (no LXR)" do
      minimal_lxr = {
        metadata: { path: "test.lxr", version: "1.0",
                    created_at: Time.now.iso8601 },
        namespaces: [],
        elements: [],
        complex_types: [],
        simple_types: [],
        attributes: [],
        statistics: Lutaml::Klin::Spa::Models::Statistics.new
      }

      result = loader.merge(minimal_lxr, nil)

      expect(result).to be_a(Lutaml::Klin::Spa::Models::UnifiedSchema)
      expect(result.schemas).to eq([])
    end

    it "preserves traceability information" do
      yaml_data = {
        traceability: Lutaml::Klin::Spa::Models::Traceability.new.tap do |t|
          t.resolution_strategies = ["type_override"]
        end,
        source: { "name" => "Test" },
        mappings: {}
      }

      result = loader.merge(lxr_data, yaml_data)

      expect(result.metadata.traceability).to be_a(
        Lutaml::Klin::Spa::Models::Traceability
      )
      expect(result.metadata.traceability.resolution_strategies).to include(
        "type_override"
      )
    end

    it "builds schema list from namespaces" do
      result = loader.merge(lxr_data, nil)

      expect(result.schemas.size).to eq(1)
      expect(result.schemas.first.prefix).to eq("uro")
      expect(result.schemas.first.namespace).to eq("http://example.com/uro")
    end
  end
end
