# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Resolution Integration", :integration do
  let(:xsd_repo) { double("SchemaRepositoryAdapter") }
  let(:shapechange_config) { double("ShapeChangeConfiguration") }
  let(:type_overrides) { {} }

  let(:context) do
    Lutaml::Klin::Domain::ResolutionContext.new(
      xsd_repository: xsd_repo,
      shapechange_config: shapechange_config,
      type_overrides: type_overrides
    )
  end

  describe "type override strategy" do
    let(:type_overrides) { { "OldType" => "NewType" } }
    let(:strategy) do
      Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new
    end

    it "resolves through type override with highest priority" do
      result = strategy.resolve("OldType", context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to eq("NewType")
      expect(result.resolution_method).to eq("type_override")
      expect(result.confidence).to eq("high")
    end

    it "skips types not in override map" do
      result = strategy.resolve("UnmappedType", context)

      expect(result.resolved?).to be false
      expect(result.skipped?).to be true
    end

    it "resolves complex type paths" do
      overrides = {
        "pkg::OldClass" => "ns:NewClass",
        "SimpleName" => "xs:string",
      }

      override_context = Lutaml::Klin::Domain::ResolutionContext.new(
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: overrides
      )

      result1 = strategy.resolve("pkg::OldClass", override_context)
      expect(result1.xsd_type).to eq("ns:NewClass")

      result2 = strategy.resolve("SimpleName", override_context)
      expect(result2.xsd_type).to eq("xs:string")
    end
  end

  describe "shapechange strategy" do
    let(:strategy) do
      Lutaml::Klin::Domain::Strategies::ShapeChangeMappingStrategy.new
    end

    before do
      # Mock ShapeChange XSD map entries
      map_entries = [
        double("XsdMapEntry",
               type: "CharacterString",
               xmlPropertyType: "gml:CodeType",
               xmlElement: "gml:Code",
               xmlType: "gml:CodeType",
               xmlTypeContent: "simple",
               xmlTypeNilReason: false),
        double("XsdMapEntry",
               type: "Integer",
               xmlPropertyType: nil,
               xmlElement: nil,
               xmlType: "xs:integer",
               xmlTypeContent: "simple",
               xmlTypeNilReason: false),
      ]

      allow(shapechange_config).to receive(:xsd_map_entries)
        .and_return(map_entries)
    end

    it "resolves through ShapeChange mappings" do
      result = strategy.resolve("CharacterString", context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to eq("gml:CodeType")
      expect(result.resolution_method).to eq("shapechange_mapping")
      expect(result.confidence).to eq("high")
    end

    it "handles simple type mappings" do
      result = strategy.resolve("Integer", context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to eq("xs:integer")
      expect(result.resolution_method).to eq("shapechange_mapping")
    end

    it "skips unmapped types" do
      result = strategy.resolve("UnmappedCustomType", context)

      expect(result.resolved?).to be false
      expect(result.skipped?).to be true
    end

    it "prefers xmlType over xmlPropertyType" do
      map_entry = double("XsdMapEntry",
                         type: "ComplexType",
                         xmlPropertyType: "ct:PropertyType",
                         xmlElement: "ct:Element",
                         xmlType: "ct:ComplexType",
                         xmlTypeContent: "complex",
                         xmlTypeNilReason: false)

      allow(shapechange_config).to receive(:xsd_map_entries)
        .and_return([map_entry])

      result = strategy.resolve("ComplexType", context)

      expect(result.xsd_type).to eq("ct:ComplexType")
    end
  end

  describe "schema repository strategy" do
    let(:strategy) do
      Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new
    end

    before do
      # Mock XSD repository lookups
      string_type = double("XsdType",
                           name: "string",
                           namespace: "http://www.w3.org/2001/XMLSchema")

      custom_type = double("XsdType",
                           name: "CustomType",
                           namespace: "http://example.org/custom")

      allow(xsd_repo).to receive(:find_type) do |type_name, _namespace|
        case type_name
        when "string", "String"
          string_type
        when "CustomType"
          custom_type
        else
          nil
        end
      end

      allow(xsd_repo).to receive(:find_element).and_return(nil)
    end

    it "resolves through direct XSD lookup" do
      result = strategy.resolve("String", context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to eq("xs:string")
      expect(result.resolution_method).to eq("xsd_lookup")
      expect(result.confidence).to eq("medium")
    end

    it "handles custom types from repository" do
      result = strategy.resolve("CustomType", context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to include("CustomType")
      expect(result.resolution_method).to eq("xsd_lookup")
    end

    it "fails when type not found in repository" do
      result = strategy.resolve("NonExistentType", context)

      expect(result.resolved?).to be false
      expect(result.unresolved?).to be true
      expect(result.error).to include("not found")
    end
  end

  describe "resolution engine with multiple strategies" do
    let(:engine) do
      strategies = [
        Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new,
        Lutaml::Klin::Domain::Strategies::ShapeChangeMappingStrategy.new,
        Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new,
      ]
      Lutaml::Klin::Domain::ResolutionEngine.new(strategies)
    end

    before do
      # Setup all strategy mocks
      allow(shapechange_config).to receive(:xsd_map_entries)
        .and_return([
                      double("XsdMapEntry",
                             type: "CharacterString",
                             xmlType: "gml:CodeType",
                             xmlPropertyType: nil,
                             xmlElement: nil,
                             xmlTypeContent: "simple",
                             xmlTypeNilReason: false),
                    ])

      string_type = double("XsdType",
                           name: "string",
                           namespace: "http://www.w3.org/2001/XMLSchema")

      allow(xsd_repo).to receive(:find_type) do |type_name, _namespace|
        type_name =~ /string/i ? string_type : nil
      end
      allow(xsd_repo).to receive(:find_element).and_return(nil)
    end

    it "tries strategies in priority order" do
      # Type override should win if present
      override_context = Lutaml::Klin::Domain::ResolutionContext.new(
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: { "CharacterString" => "xs:string" }
      )

      result = engine.resolve("CharacterString", override_context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to eq("xs:string")
      expect(result.resolution_method).to eq("type_override")
    end

    it "falls back to next strategy when first skips" do
      # No override, should use ShapeChange
      result = engine.resolve("CharacterString", context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to eq("gml:CodeType")
      expect(result.resolution_method).to eq("shapechange_mapping")
    end

    it "tracks resolution method correctly" do
      # Override strategy
      override_ctx = Lutaml::Klin::Domain::ResolutionContext.new(
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: { "Test" => "xs:string" }
      )
      result1 = engine.resolve("Test", override_ctx)
      expect(result1.resolution_method).to eq("type_override")

      # ShapeChange strategy
      result2 = engine.resolve("CharacterString", context)
      expect(result2.resolution_method).to eq("shapechange_mapping")

      # XSD lookup strategy
      result3 = engine.resolve("String", context)
      expect(result3.resolution_method).to eq("xsd_lookup")
    end

    it "returns unresolved when all strategies fail" do
      result = engine.resolve("CompletelyUnknownType", context)

      expect(result.resolved?).to be false
      expect(result.unresolved?).to be true
      expect(result.error).not_to be_nil
    end
  end

  describe "resolution with namespace handling" do
    let(:strategy) do
      Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new
    end

    before do
      gml_type = double("XsdType",
                        name: "PointType",
                        namespace: "http://www.opengis.net/gml/3.2")

      allow(xsd_repo).to receive(:find_type) do |type_name, namespace|
        if type_name == "PointType" &&
           (namespace.nil? || namespace.include?("gml"))
          gml_type
        else
          nil
        end
      end

      allow(xsd_repo).to receive(:find_element).and_return(nil)
    end

    it "resolves types with namespace prefixes" do
      result = strategy.resolve("gml:PointType", context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to include("PointType")
    end

    it "resolves types without namespace prefixes" do
      result = strategy.resolve("PointType", context)

      expect(result.resolved?).to be true
      expect(result.xsd_type).to include("PointType")
    end
  end

  describe "confidence levels" do
    let(:engine) do
      strategies = [
        Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new,
        Lutaml::Klin::Domain::Strategies::ShapeChangeMappingStrategy.new,
        Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new,
      ]
      Lutaml::Klin::Domain::ResolutionEngine.new(strategies)
    end

    before do
      allow(shapechange_config).to receive(:xsd_map_entries).and_return([])
      allow(xsd_repo).to receive(:find_type).and_return(nil)
      allow(xsd_repo).to receive(:find_element).and_return(nil)
    end

    it "assigns high confidence to override resolutions" do
      ctx = Lutaml::Klin::Domain::ResolutionContext.new(
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: { "Type1" => "xs:string" }
      )

      result = engine.resolve("Type1", ctx)
      expect(result.confidence).to eq("high")
    end

    it "assigns high confidence to ShapeChange resolutions" do
      map_entry = double("XsdMapEntry",
                         type: "Type2",
                         xmlType: "xs:integer",
                         xmlPropertyType: nil,
                         xmlElement: nil,
                         xmlTypeContent: "simple",
                         xmlTypeNilReason: false)

      allow(shapechange_config).to receive(:xsd_map_entries)
        .and_return([map_entry])

      result = engine.resolve("Type2", context)
      expect(result.confidence).to eq("high")
    end

    it "assigns medium confidence to XSD lookup resolutions" do
      xsd_type = double("XsdType",
                        name: "Type3",
                        namespace: "http://example.org/ns")

      allow(xsd_repo).to receive(:find_type)
        .with("Type3", anything)
        .and_return(xsd_type)

      result = engine.resolve("Type3", context)
      expect(result.confidence).to eq("medium")
    end

    it "assigns no confidence to unresolved types" do
      result = engine.resolve("UnresolvableType", context)
      expect(result.confidence).to be_nil
    end
  end

  describe "error handling in resolution" do
    let(:engine) do
      strategies = [
        Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new,
      ]
      Lutaml::Klin::Domain::ResolutionEngine.new(strategies)
    end

    it "captures errors when repository throws exception" do
      allow(xsd_repo).to receive(:find_type)
        .and_raise(StandardError, "Repository error")
      allow(xsd_repo).to receive(:find_element)
        .and_raise(StandardError, "Repository error")

      result = engine.resolve("ErrorType", context)

      expect(result.unresolved?).to be true
      expect(result.error).to include("Repository error")
    end

    it "handles nil context gracefully" do
      nil_context = Lutaml::Klin::Domain::ResolutionContext.new(
        xsd_repository: nil,
        shapechange_config: nil,
        type_overrides: {}
      )

      result = engine.resolve("Type", nil_context)

      expect(result.unresolved?).to be true
    end
  end
end