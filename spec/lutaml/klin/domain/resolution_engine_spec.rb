# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/resolution_engine"
require "lutaml/klin/domain/strategies/type_override_strategy"
require "lutaml/klin/domain/strategies/shapechange_strategy"
require "lutaml/klin/domain/strategies/schema_repository_strategy"

RSpec.describe Lutaml::Klin::Domain::ResolutionEngine do
  let(:xsd_repository) { double("SchemaRepositoryAdapter") }
  let(:shapechange_config) { double("ShapeChangeConfig") }
  let(:type_overrides) { { "CharacterString" => "xs:string" } }
  let(:context) do
    Lutaml::Klin::Domain::ResolutionContext.new(
      xsd_repository: xsd_repository,
      shapechange_config: shapechange_config,
      type_overrides: type_overrides
    )
  end

  describe "#initialize" do
    it "creates engine with strategies" do
      strategies = [
        Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new,
        Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new
      ]

      engine = described_class.new(strategies)

      expect(engine.strategies).to eq(strategies)
      expect(engine.strategies).to be_frozen
    end

    it "raises error if strategies is nil" do
      expect do
        described_class.new(nil)
      end.to raise_error(ArgumentError, /cannot be nil or empty/)
    end

    it "raises error if strategies is empty" do
      expect do
        described_class.new([])
      end.to raise_error(ArgumentError, /cannot be nil or empty/)
    end

    it "raises error if strategy doesn't respond to applicable?" do
      bad_strategy = double("BadStrategy")
      allow(bad_strategy).to receive(:resolve)

      expect do
        described_class.new([bad_strategy])
      end.to raise_error(ArgumentError, /must respond to #applicable?/)
    end

    it "raises error if strategy doesn't respond to resolve" do
      bad_strategy = double("BadStrategy")
      allow(bad_strategy).to receive(:applicable?)

      expect do
        described_class.new([bad_strategy])
      end.to raise_error(ArgumentError, /must respond to #resolve/)
    end
  end

  describe "#resolve" do
    let(:strategies) do
      [
        Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new,
        Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new
      ]
    end
    let(:engine) { described_class.new(strategies) }

    it "raises error if uml_element is nil" do
      expect do
        engine.resolve(nil, context: context)
      end.to raise_error(ArgumentError, /uml_element is required/)
    end

    it "raises error if context is nil" do
      element = double("UMLElement", type: "xs:string")
      expect do
        engine.resolve(element, context: nil)
      end.to raise_error(ArgumentError, /context is required/)
    end

    context "when first strategy resolves" do
      it "returns resolved result from first strategy" do
        element = double("UMLElement", type: "CharacterString")
        xsd_result = double("TypeResolutionResult",
                            resolved: true,
                            local_name: "string",
                            namespace: "http://www.w3.org/2001/XMLSchema",
                            schema_file: "schemas/xmlschema.xsd",
                            resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(xsd_result)

        result = engine.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.method).to eq("TypeOverrideStrategy")
      end

      it "does not try subsequent strategies" do
        element = double("UMLElement", type: "CharacterString")
        xsd_result = double("TypeResolutionResult",
                            resolved: true,
                            local_name: "string",
                            namespace: "http://www.w3.org/2001/XMLSchema",
                            schema_file: "schemas/xmlschema.xsd",
                            resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(xsd_result)

        # Should only be called once by TypeOverrideStrategy
        expect(xsd_repository).to receive(:resolve_type).once

        engine.resolve(element, context: context)
      end
    end

    context "when first strategy is not applicable" do
      it "tries next strategy" do
        element = double("UMLElement", type: "xs:string")
        xsd_result = double("TypeResolutionResult",
                            resolved: true,
                            local_name: "string",
                            namespace: "http://www.w3.org/2001/XMLSchema",
                            schema_file: "schemas/xmlschema.xsd",
                            resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(xsd_result)

        result = engine.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.method).to eq("SchemaRepositoryStrategy")
      end
    end

    context "when first strategy fails but second succeeds" do
      it "returns result from second strategy" do
        element = double("UMLElement", type: "CharacterString")
        # First strategy (override) will fail
        failed_result = double("TypeResolutionResult",
                               resolved: false,
                               error_message: "Type not found",
                               resolution_path: nil)
        # Second strategy (repository) will succeed
        success_result = double("TypeResolutionResult",
                                resolved: true,
                                local_name: "CharacterString",
                                namespace: "http://example.com",
                                schema_file: "schemas/example.xsd",
                                resolution_path: nil)

        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(failed_result)
        allow(xsd_repository).to receive(:resolve_type).with("CharacterString")
                                                       .and_return(success_result)

        result = engine.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.method).to eq("SchemaRepositoryStrategy")
      end
    end

    context "when all strategies fail" do
      it "returns aggregate failure result" do
        element = double("UMLElement", type: "UnknownType")
        failed_result = double("TypeResolutionResult",
                               resolved: false,
                               error_message: "Type not found in repository",
                               resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).and_return(failed_result)

        result = engine.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("not resolved by any strategy")
        expect(result.metadata[:attempted_strategies]).to include("SchemaRepositoryStrategy")
      end

      it "includes errors from all strategies" do
        element = double("UMLElement", type: "UnknownType")
        failed_result = double("TypeResolutionResult",
                               resolved: false,
                               error_message: "Type not found in repository",
                               resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).and_return(failed_result)

        result = engine.resolve(element, context: context)

        expect(result.metadata[:strategy_errors]).to be_a(Array)
        expect(result.metadata[:strategy_errors]).not_to be_empty
      end
    end

    context "when no strategies are applicable" do
      it "returns failure result with appropriate message" do
        # Create a mock strategy that's never applicable
        never_applicable = double("NeverApplicable")
        allow(never_applicable).to receive(:applicable?).and_return(false)
        allow(never_applicable).to receive(:resolve)
        allow(never_applicable).to receive(:name).and_return("NeverApplicable")

        engine = described_class.new([never_applicable])
        element = double("UMLElement", type: "SomeType")

        result = engine.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("No applicable strategies")
        expect(result.metadata[:attempted_strategies]).to be_empty
      end
    end

    context "with multiple strategies" do
      let(:strategies) do
        [
          Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new,
          Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new
        ]
      end

      it "tries strategies in order" do
        element = double("UMLElement", type: "xs:string")
        xsd_result = double("TypeResolutionResult",
                            resolved: true,
                            local_name: "string",
                            namespace: "http://www.w3.org/2001/XMLSchema",
                            schema_file: "schemas/xmlschema.xsd",
                            resolution_path: nil)
        allow(xsd_repository).to receive(:resolve_type).with("xs:string")
                                                       .and_return(xsd_result)

        result = engine.resolve(element, context: context)

        # Should be resolved by SchemaRepositoryStrategy since no override
        expect(result.method).to eq("SchemaRepositoryStrategy")
      end
    end
  end

  describe "#to_s" do
    it "includes strategy count and names" do
      strategies = [
        Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new,
        Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new
      ]
      engine = described_class.new(strategies)

      result = engine.to_s

      expect(result).to include("2 strategies")
      expect(result).to include("TypeOverrideStrategy")
      expect(result).to include("SchemaRepositoryStrategy")
    end
  end

  describe "#inspect" do
    it "includes strategy names" do
      strategies = [
        Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new
      ]
      engine = described_class.new(strategies)

      result = engine.inspect

      expect(result).to include("ResolutionEngine")
      expect(result).to include("TypeOverrideStrategy")
    end
  end
end
