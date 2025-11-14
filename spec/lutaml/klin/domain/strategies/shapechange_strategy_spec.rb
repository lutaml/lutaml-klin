# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/strategies/shapechange_strategy"
require "lutaml/klin/domain/resolution_result"
require "lutaml/klin/domain/resolution_context"

RSpec.describe Lutaml::Klin::Domain::Strategies::ShapeChangeMappingStrategy do
  let(:strategy) { described_class.new }
  let(:xsd_repository) { double("SchemaRepositoryAdapter") }
  let(:shapechange_config) { double("ShapeChangeConfig") }
  let(:context) do
    Lutaml::Klin::Domain::ResolutionContext.new(
      xsd_repository: xsd_repository,
      shapechange_config: shapechange_config
    )
  end

  describe "#applicable?" do
    it "returns true when ShapeChange mapping exists" do
      element = double("UMLElement", type: "CharacterString")
      allow(shapechange_config).to receive(:has_type_mapping?)
        .with("CharacterString").and_return(true)

      expect(strategy.applicable?(element, context)).to be true
    end

    it "returns false when ShapeChange mapping does not exist" do
      element = double("UMLElement", type: "CustomType")
      allow(shapechange_config).to receive(:has_type_mapping?)
        .with("CustomType").and_return(false)

      expect(strategy.applicable?(element, context)).to be false
    end

    it "returns false when element has no type" do
      element = double("UMLElement", type: nil)
      expect(strategy.applicable?(element, context)).to be false
    end

    it "returns false when element has empty type" do
      element = double("UMLElement", type: "")
      expect(strategy.applicable?(element, context)).to be false
    end

    it "returns false when config doesn't respond to has_type_mapping?" do
      bad_config = double("BadConfig")
      bad_context = Lutaml::Klin::Domain::ResolutionContext.new(
        xsd_repository: xsd_repository,
        shapechange_config: bad_config
      )
      element = double("UMLElement", type: "CharacterString")

      expect(strategy.applicable?(element, bad_context)).to be false
    end
  end

  describe "#resolve" do
    context "when mapping xml_type is found in XSD repository" do
      it "returns resolved result with hash mapping" do
        element = double("UMLElement", type: "CharacterString")
        mapping = { xml_type: "xs:string" }
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("CharacterString").and_return(mapping)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
          .and_return({ local_name: "string", namespace: "http://www.w3.org/2001/XMLSchema" })

        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.xsd_type).to eq("string")
        expect(result.xsd_namespace).to eq("http://www.w3.org/2001/XMLSchema")
        expect(result.method).to eq("ShapeChangeMappingStrategy")
        expect(result.confidence).to eq(0.9)
      end

      it "returns resolved result with object mapping" do
        element = double("UMLElement", type: "CharacterString")
        mapping = double("Mapping", xml_type: "xs:string")
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("CharacterString").and_return(mapping)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
          .and_return({ local_name: "string", namespace: "http://www.w3.org/2001/XMLSchema" })

        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
      end

      it "normalizes :: to : in xml_type" do
        element = double("UMLElement", type: "CharacterString")
        mapping = { xml_type: "xs::string" }
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("CharacterString").and_return(mapping)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
          .and_return({ local_name: "string", namespace: "http://www.w3.org/2001/XMLSchema" })

        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
      end

      it "includes metadata about the resolution" do
        element = double("UMLElement", type: "CharacterString")
        mapping = { xml_type: "xs:string" }
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("CharacterString").and_return(mapping)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
          .and_return({ local_name: "string", namespace: "http://www.w3.org/2001/XMLSchema" })

        result = strategy.resolve(element, context: context)

        expect(result.metadata[:original_type]).to eq("CharacterString")
        expect(result.metadata[:xml_type]).to eq("xs:string")
        expect(result.metadata[:mapping_source]).to eq("ShapeChange")
      end
    end

    context "when mapping is nil" do
      it "returns unresolved result" do
        element = double("UMLElement", type: "CharacterString")
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("CharacterString").and_return(nil)

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("mapping not found")
      end
    end

    context "when mapping has no xml_type" do
      it "returns unresolved result" do
        element = double("UMLElement", type: "CharacterString")
        mapping = {}
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("CharacterString").and_return(mapping)

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("has no xml_type")
      end
    end

    context "when xml_type is not found in XSD repository" do
      it "returns unresolved result" do
        element = double("UMLElement", type: "CharacterString")
        mapping = { xml_type: "xs:string" }
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("CharacterString").and_return(mapping)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
          .and_return(nil)

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("not found in XSD repository")
      end
    end

    context "when an error occurs" do
      it "returns unresolved result with error details" do
        element = double("UMLElement", type: "CharacterString")
        allow(shapechange_config).to receive(:get_type_mapping)
          .and_raise(StandardError, "Config error")

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("Config error")
        expect(result.metadata[:exception]).to eq("StandardError")
      end
    end
  end

  describe "#name" do
    it "returns strategy name" do
      expect(strategy.name).to eq("ShapeChangeMappingStrategy")
    end
  end

  describe "#to_s" do
    it "includes description" do
      expect(strategy.to_s).to include("ShapeChange")
      expect(strategy.to_s).to include("type mappings")
    end
  end
end