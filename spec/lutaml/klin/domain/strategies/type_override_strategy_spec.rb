# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/strategies/type_override_strategy"
require "lutaml/klin/domain/resolution_result"
require "lutaml/klin/domain/resolution_context"

RSpec.describe Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy do
  let(:strategy) { described_class.new }
  let(:xsd_repository) { double("SchemaRepositoryAdapter") }
  let(:shapechange_config) { double("ShapeChangeConfig") }
  let(:type_overrides) do
    { "CharacterString" => "xs:string", "xs::string" => "xs:string" }
  end
  let(:context) do
    Lutaml::Klin::Domain::ResolutionContext.new(
      xsd_repository: xsd_repository,
      shapechange_config: shapechange_config,
      type_overrides: type_overrides
    )
  end

  describe "#applicable?" do
    it "returns true when override exists" do
      element = double("UMLElement", type: "CharacterString")
      expect(strategy.applicable?(element, context)).to be true
    end

    it "returns false when override does not exist" do
      element = double("UMLElement", type: "NonExistent")
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

    it "returns false when element doesn't respond to type" do
      element = double("UMLElement")
      expect(strategy.applicable?(element, context)).to be false
    end
  end

  describe "#resolve" do
    context "when override type is found in XSD repository" do
      it "returns resolved result" do
        element = double("UMLElement", type: "CharacterString")
        xsd_result = double("TypeResolutionResult",
                            resolved: true,
                            local_name: "string",
                            namespace: "http://www.w3.org/2001/XMLSchema",
                            schema_file: "schemas/xmlschema.xsd",
                            resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(xsd_result)

        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.xsd_type).to eq("string")
        expect(result.xsd_namespace).to eq("http://www.w3.org/2001/XMLSchema")
        expect(result.method).to eq("TypeOverrideStrategy")
        expect(result.confidence).to eq(1.0)
      end

      it "normalizes :: to : in override type" do
        element = double("UMLElement", type: "xs::string")
        xsd_result = double("TypeResolutionResult",
                            resolved: true,
                            local_name: "string",
                            namespace: "http://www.w3.org/2001/XMLSchema",
                            schema_file: "schemas/xmlschema.xsd",
                            resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(xsd_result)

        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
      end

      it "includes metadata about the resolution" do
        element = double("UMLElement", type: "CharacterString")
        xsd_result = double("TypeResolutionResult",
                            resolved: true,
                            local_name: "string",
                            namespace: "http://www.w3.org/2001/XMLSchema",
                            schema_file: "schemas/xmlschema.xsd",
                            resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(xsd_result)

        result = strategy.resolve(element, context: context)

        expect(result.metadata[:original_type]).to eq("CharacterString")
        expect(result.metadata[:override_type]).to eq("xs:string")
        expect(result.metadata[:normalized_type]).to eq("xs:string")
      end
    end

    context "when override type is not found in XSD repository" do
      it "returns unresolved result" do
        element = double("UMLElement", type: "CharacterString")
        failed_result = double("TypeResolutionResult",
                               resolved: false,
                               error_message: "Type not found in repository",
                               resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(failed_result)

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("Type not found in repository")
      end

      it "includes metadata about the failed resolution" do
        element = double("UMLElement", type: "CharacterString")
        failed_result = double("TypeResolutionResult",
                               resolved: false,
                               error_message: "Type not found in repository",
                               resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(failed_result)

        result = strategy.resolve(element, context: context)

        expect(result.metadata[:original_type]).to eq("CharacterString")
        expect(result.metadata[:override_type]).to eq("xs:string")
        expect(result.metadata[:strategy]).to eq("TypeOverrideStrategy")
      end
    end

    context "when an error occurs" do
      it "returns unresolved result with error details" do
        element = double("UMLElement", type: "CharacterString")
        allow(xsd_repository).to receive(:resolve_type)
          .and_raise(StandardError, "Connection error")

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("Connection error")
        expect(result.metadata[:exception]).to eq("StandardError")
      end
    end
  end

  describe "#name" do
    it "returns strategy name" do
      expect(strategy.name).to eq("TypeOverrideStrategy")
    end
  end

  describe "#to_s" do
    it "includes description" do
      expect(strategy.to_s).to include("highest priority")
      expect(strategy.to_s).to include("manual overrides")
    end
  end
end
