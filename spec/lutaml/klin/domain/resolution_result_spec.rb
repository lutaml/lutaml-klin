# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/resolution_result"

RSpec.describe Lutaml::Klin::Domain::ResolutionResult do
  describe ".resolved" do
    it "creates a resolved result with all required fields" do
      result = described_class.resolved(
        xsd_type: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        method: "TypeOverrideStrategy"
      )

      expect(result.status).to eq(:resolved)
      expect(result.xsd_type).to eq("string")
      expect(result.xsd_namespace).to eq("http://www.w3.org/2001/XMLSchema")
      expect(result.method).to eq("TypeOverrideStrategy")
      expect(result.confidence).to eq(1.0)
      expect(result.metadata).to eq({})
      expect(result.error).to be_nil
    end

    it "creates a resolved result with custom confidence" do
      result = described_class.resolved(
        xsd_type: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        method: "ShapeChangeStrategy",
        confidence: 0.9
      )

      expect(result.confidence).to eq(0.9)
    end

    it "creates a resolved result with metadata" do
      metadata = { source: "override", original: "CharacterString" }
      result = described_class.resolved(
        xsd_type: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        method: "TypeOverrideStrategy",
        metadata: metadata
      )

      expect(result.metadata).to eq(metadata)
      expect(result.metadata).to be_frozen
    end
  end

  describe ".unresolved" do
    it "creates an unresolved result with error" do
      result = described_class.unresolved(
        error: "Type not found"
      )

      expect(result.status).to eq(:unresolved)
      expect(result.error).to eq("Type not found")
      expect(result.confidence).to eq(0.0)
      expect(result.xsd_type).to be_nil
      expect(result.xsd_namespace).to be_nil
      expect(result.method).to be_nil
    end

    it "creates an unresolved result with metadata" do
      metadata = { attempted_type: "CustomType", strategies: 3 }
      result = described_class.unresolved(
        error: "No strategies applicable",
        metadata: metadata
      )

      expect(result.metadata).to eq(metadata)
      expect(result.metadata).to be_frozen
    end
  end

  describe "#resolved?" do
    it "returns true for resolved results" do
      result = described_class.resolved(
        xsd_type: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        method: "Strategy"
      )

      expect(result.resolved?).to be true
    end

    it "returns false for unresolved results" do
      result = described_class.unresolved(error: "Failed")

      expect(result.resolved?).to be false
    end
  end

  describe "#unresolved?" do
    it "returns false for resolved results" do
      result = described_class.resolved(
        xsd_type: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        method: "Strategy"
      )

      expect(result.unresolved?).to be false
    end

    it "returns true for unresolved results" do
      result = described_class.unresolved(error: "Failed")

      expect(result.unresolved?).to be true
    end
  end

  describe "#to_s" do
    it "formats resolved result" do
      result = described_class.resolved(
        xsd_type: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        method: "TypeOverrideStrategy",
        confidence: 0.95
      )

      expect(result.to_s).to include("Resolved")
      expect(result.to_s).to include("string")
      expect(result.to_s).to include("TypeOverrideStrategy")
      expect(result.to_s).to include("0.95")
    end

    it "formats unresolved result" do
      result = described_class.unresolved(error: "Type not found")

      expect(result.to_s).to include("Unresolved")
      expect(result.to_s).to include("Type not found")
    end
  end

  describe "immutability" do
    it "freezes the result object" do
      result = described_class.resolved(
        xsd_type: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        method: "Strategy"
      )

      expect(result).to be_frozen
    end

    it "freezes the metadata hash" do
      result = described_class.resolved(
        xsd_type: "string",
        namespace: "http://www.w3.org/2001/XMLSchema",
        method: "Strategy",
        metadata: { key: "value" }
      )

      expect(result.metadata).to be_frozen
    end
  end
end