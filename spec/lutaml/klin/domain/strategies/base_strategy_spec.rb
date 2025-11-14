# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/strategies/base_strategy"

RSpec.describe Lutaml::Klin::Domain::Strategies::BaseStrategy do
  let(:strategy) { described_class.new }
  let(:uml_element) { double("UMLElement", type: "TestType") }
  let(:context) { double("ResolutionContext") }

  describe "#applicable?" do
    it "raises NotImplementedError" do
      expect do
        strategy.applicable?(uml_element, context)
      end.to raise_error(NotImplementedError, /must implement #applicable?/)
    end
  end

  describe "#resolve" do
    it "raises NotImplementedError" do
      expect do
        strategy.resolve(uml_element, context: context)
      end.to raise_error(NotImplementedError, /must implement #resolve/)
    end
  end

  describe "#name" do
    it "returns the simple class name" do
      expect(strategy.name).to eq("BaseStrategy")
    end

    it "strips module namespaces" do
      # Even though it's in Lutaml::Klin::Domain::Strategies::BaseStrategy
      # it should return just "BaseStrategy"
      expect(strategy.name).not_to include("::")
    end
  end

  describe "protected helper methods" do
    # We'll test these through a concrete subclass
    let(:concrete_strategy) do
      Class.new(described_class) do
        def applicable?(uml_element, context)
          true
        end

        def resolve(uml_element, context:)
          # Expose protected methods for testing
          {
            normalized: normalize_type_name(uml_element.type),
            prefix: extract_namespace_prefix(uml_element.type),
            local: extract_local_name(uml_element.type),
          }
        end
      end.new
    end

    describe "#normalize_type_name" do
      it "converts :: to :" do
        element = double("UMLElement", type: "xs::string")
        result = concrete_strategy.resolve(element, context: context)
        expect(result[:normalized]).to eq("xs:string")
      end

      it "leaves already normalized names unchanged" do
        element = double("UMLElement", type: "xs:string")
        result = concrete_strategy.resolve(element, context: context)
        expect(result[:normalized]).to eq("xs:string")
      end

      it "handles non-qualified names" do
        element = double("UMLElement", type: "string")
        result = concrete_strategy.resolve(element, context: context)
        expect(result[:normalized]).to eq("string")
      end
    end

    describe "#extract_namespace_prefix" do
      it "extracts prefix from qualified name" do
        element = double("UMLElement", type: "xs:string")
        result = concrete_strategy.resolve(element, context: context)
        expect(result[:prefix]).to eq("xs")
      end

      it "returns nil for non-qualified name" do
        element = double("UMLElement", type: "string")
        result = concrete_strategy.resolve(element, context: context)
        expect(result[:prefix]).to be_nil
      end
    end

    describe "#extract_local_name" do
      it "extracts local name from qualified name" do
        element = double("UMLElement", type: "xs:string")
        result = concrete_strategy.resolve(element, context: context)
        expect(result[:local]).to eq("string")
      end

      it "returns full name for non-qualified name" do
        element = double("UMLElement", type: "string")
        result = concrete_strategy.resolve(element, context: context)
        expect(result[:local]).to eq("string")
      end
    end
  end
end