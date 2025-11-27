# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/models/unified_schema"

RSpec.describe Lutaml::Klin::Spa::Models::UnifiedSchema do
  describe "initialization" do
    it "creates an empty schema" do
      schema = described_class.new

      expect(schema.metadata).to be_nil
      expect(schema.schemas).to eq([])
      expect(schema.elements).to eq([])
      expect(schema.complex_types).to eq([])
      expect(schema.simple_types).to eq([])
      expect(schema.attributes).to eq([])
      expect(schema.cross_references).to be_nil
      expect(schema.search_index).to be_nil
      expect(schema.statistics).to be_nil
    end

    it "accepts nested models" do
      metadata = Lutaml::Klin::Spa::Models::SchemaMetadata.new
      metadata.name = "Test Schema"
      metadata.version = "1.0"

      schema = described_class.new
      schema.metadata = metadata

      expect(schema.metadata.name).to eq("Test Schema")
      expect(schema.metadata.version).to eq("1.0")
    end
  end

  describe "serialization" do
    let(:schema) do
      described_class.new.tap do |s|
        s.metadata = Lutaml::Klin::Spa::Models::SchemaMetadata.new.tap do |m|
          m.name = "Test Schema"
          m.version = "1.0"
          m.generated_at = "2024-01-01T00:00:00Z"
        end
        s.statistics = Lutaml::Klin::Spa::Models::Statistics.new.tap do |st|
          st.total_schemas = 2
          st.total_elements = 10
        end
      end
    end

    it "serializes to JSON" do
      json = schema.to_json
      expect(json).to include('"name":"Test Schema"')
      expect(json).to include('"version":"1.0"')
      expect(json).to include('"totalSchemas":2')
      expect(json).to include('"totalElements":10')
    end

    it "deserializes from JSON" do
      json_str = schema.to_json
      deserialized = described_class.from_json(json_str)

      expect(deserialized.metadata.name).to eq("Test Schema")
      expect(deserialized.metadata.version).to eq("1.0")
      expect(deserialized.statistics.total_schemas).to eq(2)
      expect(deserialized.statistics.total_elements).to eq(10)
    end
  end

  describe "collections" do
    it "handles element collections" do
      schema = described_class.new
      elem1 = Lutaml::Klin::Spa::Models::Element.new
      elem1.name = "Building"
      elem1.qualified_name = "uro:Building"

      elem2 = Lutaml::Klin::Spa::Models::Element.new
      elem2.name = "Road"
      elem2.qualified_name = "uro:Road"

      schema.elements = [elem1, elem2]

      expect(schema.elements.size).to eq(2)
      expect(schema.elements.first.name).to eq("Building")
      expect(schema.elements.last.name).to eq("Road")
    end

    it "handles type collections" do
      schema = described_class.new
      type1 = Lutaml::Klin::Spa::Models::ComplexType.new
      type1.name = "BuildingType"

      schema.complex_types = [type1]

      expect(schema.complex_types.size).to eq(1)
      expect(schema.complex_types.first.name).to eq("BuildingType")
    end
  end
end
