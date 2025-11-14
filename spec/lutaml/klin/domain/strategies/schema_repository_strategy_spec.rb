# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/strategies/schema_repository_strategy"
require "lutaml/klin/domain/resolution_result"
require "lutaml/klin/domain/resolution_context"

RSpec.describe Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy do
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
    it "returns true for any element with a type" do
      element = double("UMLElement", type: "CustomType")
      expect(strategy.applicable?(element, context)).to be true
    end

    it "returns true even for unknown types" do
      element = double("UMLElement", type: "UnknownType")
      expect(strategy.applicable?(element, context)).to be true
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
    context "when type is found in XSD repository" do
      it "returns resolved result" do
        element = double("UMLElement", type: "xs:string")

        # Create proper mock result object with required methods
        xsd_result = double("TypeResolutionResult",
          resolved: true,
          local_name: "string",
          namespace: "http://www.w3.org/2001/XMLSchema",
          schema_file: "schemas/xmlschema.xsd"
        )

        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
          .and_return(xsd_result)

        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.xsd_type).to eq("string")
        expect(result.xsd_namespace).to eq("http://www.w3.org/2001/XMLSchema")
        expect(result.method).to eq("SchemaRepositoryStrategy")
        expect(result.confidence).to eq(0.8)
      end

      it "normalizes :: to : before lookup" do
        element = double("UMLElement", type: "xs::string")

        # Create proper mock result object
        xsd_result = double("TypeResolutionResult",
          resolved: true,
          local_name: "string",
          namespace: "http://www.w3.org/2001/XMLSchema",
          schema_file: "schemas/xmlschema.xsd"
        )

        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
          .and_return(xsd_result)

        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
      end

      it "includes metadata about the resolution" do
        element = double("UMLElement", type: "xs:string")

        # Create proper mock result object
        xsd_result = double("TypeResolutionResult",
          resolved: true,
          local_name: "string",
          namespace: "http://www.w3.org/2001/XMLSchema",
          schema_file: "schemas/xmlschema.xsd"
        )

        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
          .and_return(xsd_result)

        result = strategy.resolve(element, context: context)

        expect(result.metadata[:original_type]).to eq("xs:string")
        expect(result.metadata[:normalized_type]).to eq("xs:string")
        expect(result.metadata[:resolution_method]).to eq("direct_lookup")
      end
    end

    context "when type is not found in XSD repository" do
      it "returns unresolved result" do
        element = double("UMLElement", type: "UnknownType")

        # Create proper mock result object for unresolved case
        xsd_result = double("TypeResolutionResult",
          resolved: false,
          error_message: "Type 'UnknownType' not found",
          resolution_path: nil
        )

        allow(xsd_repository).to receive(:resolve_type).with("UnknownType")
          .and_return(xsd_result)

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("Type 'UnknownType' not found")
      end

      it "includes helpful note about being fallback strategy" do
        element = double("UMLElement", type: "UnknownType")

        # Create proper mock result object for unresolved case
        xsd_result = double("TypeResolutionResult",
          resolved: false,
          error_message: "Type 'UnknownType' not found",
          resolution_path: nil
        )

        allow(xsd_repository).to receive(:resolve_type).with("UnknownType")
          .and_return(xsd_result)

        result = strategy.resolve(element, context: context)

        expect(result.metadata[:note]).to include("fallback strategy")
      end

      it "handles nil result from repository" do
        element = double("UMLElement", type: "UnknownType")
        allow(xsd_repository).to receive(:resolve_type).with("UnknownType")
          .and_return(nil)

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("not found in XSD repository")
      end
    end

    context "when an error occurs" do
      it "returns unresolved result with error details" do
        element = double("UMLElement", type: "xs:string")
        allow(xsd_repository).to receive(:resolve_type)
          .and_raise(StandardError, "Repository error")

        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("Repository error")
        expect(result.metadata[:exception]).to eq("StandardError")
        expect(result.metadata[:backtrace]).to be_a(Array)
      end
    end
  end

  describe "#name" do
    it "returns strategy name" do
      expect(strategy.name).to eq("SchemaRepositoryStrategy")
    end
  end

  describe "#to_s" do
    it "includes description as fallback" do
      expect(strategy.to_s).to include("fallback")
      expect(strategy.to_s).to include("direct XSD repository lookup")
    end
  end
end