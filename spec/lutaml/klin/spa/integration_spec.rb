# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/data_loader"
require "lutaml/klin/spa/cross_reference_builder"
require "lutaml/klin/spa/search_index_builder"
require "tempfile"

RSpec.describe "SPA Integration" do
  let(:loader) { Lutaml::Klin::Spa::DataLoader.new(verbose: false) }
  let(:cross_ref_builder) do
    Lutaml::Klin::Spa::CrossReferenceBuilder.new(verbose: false)
  end
  let(:search_builder) do
    Lutaml::Klin::Spa::SearchIndexBuilder.new(verbose: false)
  end

  describe "full workflow" do
    let(:lxr_file) do
      Tempfile.new(["test", ".lxr"]).tap do |f|
        f.write("mock lxr content")
        f.close
      end
    end

    let(:yaml_file) do
      Tempfile.new(["test", ".yaml"]).tap do |f|
        f.write(<<~YAML)
          schema_mapping:
            source:
              name: "PLATEAU Urban Schema"
              version: "5.0"
              description: "Urban planning schema for PLATEAU"
            traceability:
              resolution_strategies:
                - type_override
                - schema_repository
              lxr_package:
                path: "plateau_schemas.lxr"
                version: "1.0"
                created_at: "2024-01-01T00:00:00Z"
          mapping:
            uro:Building:
              uml_class: "Building"
              uml_package: "uro"
              stereotype: "featureType"
              resolution_strategy: "type_override"
        YAML
        f.close
      end
    end

    after do
      lxr_file.unlink
      yaml_file.unlink
    end

    it "loads, merges, and indexes schema data" do
      # Step 1: Load LXR data
      lxr_data = loader.load_lxr(lxr_file.path)
      expect(lxr_data).to be_a(Hash)
      expect(lxr_data).to have_key(:metadata)

      # Step 2: Load YAML mapping
      yaml_data = loader.load_yaml(yaml_file.path)
      expect(yaml_data).to be_a(Hash)
      expect(yaml_data[:traceability]).to be_a(
        Lutaml::Klin::Spa::Models::Traceability
      )

      # Step 3: Merge data into UnifiedSchema
      schema = loader.merge(lxr_data, yaml_data)
      expect(schema).to be_a(Lutaml::Klin::Spa::Models::UnifiedSchema)
      expect(schema.metadata.name).to eq("PLATEAU Urban Schema")
      expect(schema.metadata.traceability.resolution_strategies)
        .to include("type_override")

      # Step 4: Build cross-references
      cross_refs = cross_ref_builder.build(schema)
      schema.cross_references = cross_refs
      expect(schema.cross_references).to be_a(
        Lutaml::Klin::Spa::Models::CrossReferenceIndex
      )

      # Step 5: Build search index
      search_index = search_builder.build(schema)
      schema.search_index = search_index
      expect(schema.search_index).to be_a(
        Lutaml::Klin::Spa::Models::SearchIndex
      )

      # Step 6: Serialize to JSON
      json_data = schema.to_json
      expect(json_data).to be_a(String)
      expect(json_data).to include("PLATEAU Urban Schema")

      # Step 7: Deserialize from JSON
      deserialized = Lutaml::Klin::Spa::Models::UnifiedSchema.from_json(
        json_data
      )
      expect(deserialized.metadata.name).to eq("PLATEAU Urban Schema")
    end

    it "handles complex schema with elements and types" do
      # Prepare LXR data with sample content
      lxr_data = {
        metadata: {
          path: lxr_file.path,
          version: "1.0",
          created_at: Time.now.iso8601
        },
        namespaces: [
          {
            id: "uro",
            prefix: "uro",
            uri: "http://www.opengis.net/uro/5.0",
            name: "Urban Object"
          }
        ],
        elements: [],
        complex_types: [],
        simple_types: [],
        attributes: [],
        statistics: Lutaml::Klin::Spa::Models::Statistics.new.tap do |s|
          s.total_schemas = 1
          s.total_namespaces = 1
        end
      }

      yaml_data = loader.load_yaml(yaml_file.path)
      schema = loader.merge(lxr_data, yaml_data)

      # Build indexes
      cross_refs = cross_ref_builder.build(schema)
      search_index = search_builder.build(schema)

      schema.cross_references = cross_refs
      schema.search_index = search_index

      # Validate complete schema
      expect(schema.schemas.size).to eq(1)
      expect(schema.schemas.first.prefix).to eq("uro")
      expect(schema.metadata.source_lxr).to eq(lxr_file.path)
      expect(schema.statistics.total_schemas).to eq(1)
    end
  end

  describe "error handling" do
    it "handles missing LXR file gracefully" do
      expect do
        loader.load_lxr("nonexistent.lxr")
      end.to raise_error(Lutaml::Klin::Spa::DataLoadError)
    end

    it "handles missing YAML file gracefully" do
      expect do
        loader.load_yaml("nonexistent.yaml")
      end.to raise_error(Lutaml::Klin::Spa::DataLoadError)
    end
  end
end