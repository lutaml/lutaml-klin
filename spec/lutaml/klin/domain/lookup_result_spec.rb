# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/lookup_result"

RSpec.describe Lutaml::Klin::Domain::LookupResult do
  describe "#initialize" do
    it "creates a lookup result with all attributes" do
      result = described_class.new(
        query: "TestClass",
        direction: :uml_to_xsd,
        matches: [{ uml_class: "TestClass", xsd_type: "TestType" }],
        metadata: { fuzzy: false }
      )

      expect(result.query).to eq("TestClass")
      expect(result.direction).to eq(:uml_to_xsd)
      expect(result.matches.size).to eq(1)
      expect(result.metadata[:fuzzy]).to be(false)
    end

    it "initializes with empty matches if not provided" do
      result = described_class.new(
        query: "TestClass",
        direction: :uml_to_xsd
      )

      expect(result.matches).to eq([])
      expect(result.metadata).to eq({})
    end
  end

  describe "#found?" do
    it "returns true when matches exist" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: [{ test: "data" }]
      )

      expect(result.found?).to be(true)
    end

    it "returns false when no matches exist" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: []
      )

      expect(result.found?).to be(false)
    end
  end

  describe "#single_match?" do
    it "returns true for exactly one match" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: [{ test: "data" }]
      )

      expect(result.single_match?).to be(true)
    end

    it "returns false for zero matches" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: []
      )

      expect(result.single_match?).to be(false)
    end

    it "returns false for multiple matches" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: [{ test: "data1" }, { test: "data2" }]
      )

      expect(result.single_match?).to be(false)
    end
  end

  describe "#multiple_matches?" do
    it "returns true for multiple matches" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: [{ test: "data1" }, { test: "data2" }]
      )

      expect(result.multiple_matches?).to be(true)
    end

    it "returns false for single match" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: [{ test: "data" }]
      )

      expect(result.multiple_matches?).to be(false)
    end
  end

  describe "#first_match" do
    it "returns the first match" do
      match1 = { test: "data1" }
      match2 = { test: "data2" }
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: [match1, match2]
      )

      expect(result.first_match).to eq(match1)
    end

    it "returns nil when no matches" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: []
      )

      expect(result.first_match).to be_nil
    end
  end

  describe "#match_count" do
    it "returns the number of matches" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd,
        matches: [{ test: "data1" }, { test: "data2" }, { test: "data3" }]
      )

      expect(result.match_count).to eq(3)
    end
  end

  describe "#uml_to_xsd?" do
    it "returns true for UML to XSD direction" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd
      )

      expect(result.uml_to_xsd?).to be(true)
    end

    it "returns false for other directions" do
      result = described_class.new(
        query: "Test",
        direction: :xsd_to_uml
      )

      expect(result.uml_to_xsd?).to be(false)
    end
  end

  describe "#xsd_to_uml?" do
    it "returns true for XSD to UML direction" do
      result = described_class.new(
        query: "Test",
        direction: :xsd_to_uml
      )

      expect(result.xsd_to_uml?).to be(true)
    end

    it "returns false for other directions" do
      result = described_class.new(
        query: "Test",
        direction: :uml_to_xsd
      )

      expect(result.xsd_to_uml?).to be(false)
    end
  end

  describe "#to_h" do
    it "converts the result to a hash" do
      result = described_class.new(
        query: "TestClass",
        direction: :uml_to_xsd,
        matches: [{ test: "data" }],
        metadata: { fuzzy: true }
      )

      hash = result.to_h

      expect(hash[:query]).to eq("TestClass")
      expect(hash[:direction]).to eq(:uml_to_xsd)
      expect(hash[:match_count]).to eq(1)
      expect(hash[:matches]).to eq([{ test: "data" }])
      expect(hash[:metadata]).to eq({ fuzzy: true })
    end
  end

  describe "#to_json" do
    it "converts the result to JSON" do
      result = described_class.new(
        query: "TestClass",
        direction: :uml_to_xsd,
        matches: [{ test: "data" }]
      )

      json = result.to_json
      expect(json).to be_a(String)
      expect(json).to include("TestClass")
      expect(json).to include("uml_to_xsd")
    end
  end

  describe "#to_yaml" do
    it "converts the result to YAML" do
      result = described_class.new(
        query: "TestClass",
        direction: :uml_to_xsd,
        matches: [{ test: "data" }]
      )

      yaml = result.to_yaml
      expect(yaml).to be_a(String)
      expect(yaml).to include("TestClass")
      expect(yaml).to include("uml_to_xsd")
    end
  end
end
