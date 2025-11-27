# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/cross_reference_builder"
require "lutaml/klin/spa/models/unified_schema"

RSpec.describe Lutaml::Klin::Spa::CrossReferenceBuilder do
  let(:builder) { described_class.new(verbose: false) }

  describe "#build" do
    let(:schema) do
      Lutaml::Klin::Spa::Models::UnifiedSchema.new.tap do |s|
        # Add elements
        elem1 = Lutaml::Klin::Spa::Models::Element.new
        elem1.name = "Building"
        elem1.qualified_name = "uro:Building"
        elem1.namespace = "http://example.com/uro"
        elem1.prefix = "uro"
        elem1.type = "uro:BuildingType"

        elem2 = Lutaml::Klin::Spa::Models::Element.new
        elem2.name = "Road"
        elem2.qualified_name = "uro:Road"
        elem2.namespace = "http://example.com/uro"
        elem2.prefix = "uro"
        elem2.type = "uro:RoadType"

        s.elements = [elem1, elem2]

        # Add complex types with inheritance
        type1 = Lutaml::Klin::Spa::Models::ComplexType.new
        type1.name = "BuildingType"
        type1.qualified_name = "uro:BuildingType"
        type1.namespace = "http://example.com/uro"
        type1.prefix = "uro"
        type1.base_type = "gml:AbstractFeatureType"
        type1.attributes = [
          { "name" => "height", "qualifiedName" => "uro:height",
            "type" => "xs:double" }
        ]
        type1.elements = [
          { "name" => "address", "type" => "uro:AddressType" }
        ]

        type2 = Lutaml::Klin::Spa::Models::ComplexType.new
        type2.name = "RoadType"
        type2.qualified_name = "uro:RoadType"
        type2.namespace = "http://example.com/uro"
        type2.prefix = "uro"
        type2.base_type = "gml:AbstractFeatureType"

        type3 = Lutaml::Klin::Spa::Models::ComplexType.new
        type3.name = "AddressType"
        type3.qualified_name = "uro:AddressType"
        type3.namespace = "http://example.com/uro"
        type3.prefix = "uro"

        s.complex_types = [type1, type2, type3]

        # Add simple types
        simple_type = Lutaml::Klin::Spa::Models::SimpleType.new
        simple_type.name = "HeightType"
        simple_type.qualified_name = "uro:HeightType"
        simple_type.namespace = "http://example.com/uro"
        simple_type.prefix = "uro"
        simple_type.base_type = "xs:double"

        s.simple_types = [simple_type]

        # Add schemas
        schema_info = Lutaml::Klin::Spa::Models::SchemaInfo.new
        schema_info.id = "uro"
        schema_info.prefix = "uro"
        schema_info.namespace = "http://example.com/uro"

        s.schemas = [schema_info]
      end
    end

    it "builds element-to-type mappings" do
      index = builder.build(schema)

      expect(index.element_to_type).to be_a(Hash)
      expect(index.element_to_type["uro:Building"]).to eq("uro:BuildingType")
      expect(index.element_to_type["uro:Road"]).to eq("uro:RoadType")
    end

    it "computes type hierarchies" do
      index = builder.build(schema)

      expect(index.type_hierarchy).to be_a(Hash)
      expect(index.type_hierarchy["uro:BuildingType"]).to be_a(Hash)
      expect(index.type_hierarchy["uro:BuildingType"]["parents"]).to include(
        "gml:AbstractFeatureType"
      )
      expect(index.type_hierarchy["uro:BuildingType"]["depth"]).to eq(1)
    end

    it "builds dependency graphs" do
      index = builder.build(schema)

      expect(index.type_dependencies).to be_a(Hash)
      expect(index.type_dependencies["uro:BuildingType"]).to be_a(Hash)
      expect(index.type_dependencies["uro:BuildingType"]["requires"])
        .to include("gml:AbstractFeatureType")
      expect(index.type_dependencies["uro:BuildingType"]["requires"])
        .to include("uro:AddressType")
    end

    it "creates namespace index" do
      index = builder.build(schema)

      ns_index = index.namespace_index
      expect(ns_index).to be_a(Hash)
      expect(ns_index).not_to be_empty
      expect(ns_index.keys).to include("http://example.com/uro")
    end

    it "builds attribute references" do
      index = builder.build(schema)

      expect(index.attribute_references).to be_a(Hash)
      expect(index.attribute_references["uro:height"]).to include(
        "uro:BuildingType"
      )
    end
  end

  describe "inheritance computation" do
    let(:schema) do
      Lutaml::Klin::Spa::Models::UnifiedSchema.new.tap do |s|
        # Create a deeper inheritance hierarchy
        base = Lutaml::Klin::Spa::Models::ComplexType.new
        base.name = "BaseType"
        base.qualified_name = "test:BaseType"
        base.namespace = "http://example.com/test"
        base.prefix = "test"

        middle = Lutaml::Klin::Spa::Models::ComplexType.new
        middle.name = "MiddleType"
        middle.qualified_name = "test:MiddleType"
        middle.namespace = "http://example.com/test"
        middle.prefix = "test"
        middle.base_type = "test:BaseType"

        derived = Lutaml::Klin::Spa::Models::ComplexType.new
        derived.name = "DerivedType"
        derived.qualified_name = "test:DerivedType"
        derived.namespace = "http://example.com/test"
        derived.prefix = "test"
        derived.base_type = "test:MiddleType"

        s.complex_types = [base, middle, derived]
        s.schemas = []
      end
    end

    it "finds parent types recursively" do
      index = builder.build(schema)

      parents = index.type_hierarchy["test:DerivedType"]["parents"]
      expect(parents).to include("test:MiddleType")
      expect(parents).to include("test:BaseType")
    end

    it "finds direct child types" do
      index = builder.build(schema)

      children = index.type_hierarchy["test:BaseType"]["children"]
      expect(children).to include("test:MiddleType")
      expect(children).not_to include("test:DerivedType")
    end

    it "calculates inheritance depth" do
      index = builder.build(schema)

      expect(index.type_hierarchy["test:BaseType"]["depth"]).to eq(0)
      expect(index.type_hierarchy["test:MiddleType"]["depth"]).to eq(1)
      expect(index.type_hierarchy["test:DerivedType"]["depth"]).to eq(2)
    end
  end
end
