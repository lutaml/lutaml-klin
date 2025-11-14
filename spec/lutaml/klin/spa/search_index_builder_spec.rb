# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/search_index_builder"
require "lutaml/klin/spa/models/unified_schema"

RSpec.describe Lutaml::Klin::Spa::SearchIndexBuilder do
  let(:builder) { described_class.new(verbose: false) }

  describe "#build" do
    let(:schema) do
      Lutaml::Klin::Spa::Models::UnifiedSchema.new.tap do |s|
        # Add elements
        elem1 = Lutaml::Klin::Spa::Models::Element.new
        elem1.name = "UrbanPlanningArea"
        elem1.qualified_name = "uro:UrbanPlanningArea"
        elem1.prefix = "uro"

        elem2 = Lutaml::Klin::Spa::Models::Element.new
        elem2.name = "Building"
        elem2.qualified_name = "uro:Building"
        elem2.prefix = "uro"

        s.elements = [elem1, elem2]

        # Add complex types
        type1 = Lutaml::Klin::Spa::Models::ComplexType.new
        type1.name = "BuildingType"
        type1.qualified_name = "uro:BuildingType"
        type1.prefix = "uro"

        s.complex_types = [type1]

        # Add simple types
        simple_type = Lutaml::Klin::Spa::Models::SimpleType.new
        simple_type.name = "CodeType"
        simple_type.qualified_name = "uro:CodeType"
        simple_type.prefix = "uro"

        s.simple_types = [simple_type]

        # Add attributes
        attr = Lutaml::Klin::Spa::Models::Attribute.new
        attr.name = "heightAttribute"
        attr.qualified_name = "uro:heightAttribute"
        attr.prefix = "uro"

        s.attributes = [attr]
      end
    end

    it "builds term index" do
      index = builder.build(schema)

      expect(index.terms).to be_a(Hash)
      expect(index.terms.keys).not_to be_empty
    end

    it "tokenizes names correctly" do
      index = builder.build(schema)

      # Full name lowercase
      expect(index.terms["urbanplanningarea"]).to include(
        "uro:UrbanPlanningArea"
      )

      # CamelCase split
      expect(index.terms["urban"]).to include("uro:UrbanPlanningArea")
      expect(index.terms["planning"]).to include("uro:UrbanPlanningArea")
      expect(index.terms["area"]).to include("uro:UrbanPlanningArea")

      # Partial matching
      expect(index.terms["urb"]).to include("uro:UrbanPlanningArea")
      expect(index.terms["urba"]).to include("uro:UrbanPlanningArea")
    end

    it "indexes all component types" do
      index = builder.build(schema)

      # Elements
      expect(index.terms["building"]).to include("uro:Building")

      # Complex types
      expect(index.terms["buildingtype"]).to include("uro:BuildingType")

      # Simple types
      expect(index.terms["codetype"]).to include("uro:CodeType")

      # Attributes
      expect(index.terms["heightattribute"]).to include("uro:heightAttribute")
    end

    it "builds namespace index" do
      index = builder.build(schema)

      expect(index.by_namespace).to be_a(Hash)
      expect(index.by_namespace["uro"]).to be_an(Array)
      expect(index.by_namespace["uro"]).to include("uro:Building")
      expect(index.by_namespace["uro"]).to include("uro:BuildingType")
    end

    it "builds category index" do
      index = builder.build(schema)

      expect(index.by_category).not_to be_nil
      # Verify the index was built (lutaml-model hash behavior)
      expect(index).to be_a(Lutaml::Klin::Spa::Models::SearchIndex)
    end

    it "avoids duplicate entries in term index" do
      index = builder.build(schema)

      # Each term should have unique entries
      index.terms.each_value do |qualified_names|
        expect(qualified_names.uniq.size).to eq(qualified_names.size)
      end
    end
  end

  describe "tokenization" do
    it "handles simple names" do
      tokens = builder.send(:tokenize, "test")

      expect(tokens).to include("test")
      expect(tokens).to include("tes")
    end

    it "handles CamelCase names" do
      tokens = builder.send(:tokenize, "CamelCaseName")

      expect(tokens).to include("camelcasename")
      expect(tokens).to include("camel")
      expect(tokens).to include("case")
      expect(tokens).to include("name")
    end

    it "handles nil names" do
      tokens = builder.send(:tokenize, nil)

      expect(tokens).to eq([])
    end

    it "generates partial tokens for 3+ characters" do
      tokens = builder.send(:tokenize, "building")

      expect(tokens).to include("bui")
      expect(tokens).to include("buil")
      expect(tokens).to include("build")
      expect(tokens).to include("buildi")
      expect(tokens).to include("buildin")
      expect(tokens).to include("building")
    end

    it "returns unique tokens" do
      tokens = builder.send(:tokenize, "test")

      expect(tokens.uniq.size).to eq(tokens.size)
    end
  end
end