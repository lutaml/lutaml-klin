# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_registry"
require "lutaml/klin/shapechange/models/config/encoding_rule"
require "lutaml/klin/shapechange/models/rule_definition"

RSpec.describe Lutaml::Klin::Shapechange::RuleRegistry do
  let(:registry) { described_class.new }

  let(:base_encoding_rule) do
    Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
      er.name = "xsd"
      er.rules = ["rule-xsd-cls-type", "rule-xsd-cls-object-element"]
    end
  end

  let(:child_encoding_rule) do
    Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
      er.name = "iso19136_2007"
      er.extends = "xsd"
      er.rules = ["rule-xsd-all-naming-gml"]
    end
  end

  let(:rule_definition) do
    Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
      rd.id = "rule-xsd-cls-type"
      rd.scope = "class"
      rd.category = "required"
      rd.description = "Generate complexType for classes"
    end
  end

  describe "#initialize" do
    it "initializes with empty registries" do
      expect(registry.encoding_rules).to eq({})
      expect(registry.rule_definitions).to eq({})
    end
  end

  describe "#register_encoding_rule" do
    it "registers an encoding rule by name" do
      registry.register_encoding_rule(base_encoding_rule)

      expect(registry.encoding_rules["xsd"]).to eq(base_encoding_rule)
    end

    it "registers multiple encoding rules" do
      registry.register_encoding_rule(base_encoding_rule)
      registry.register_encoding_rule(child_encoding_rule)

      expect(registry.encoding_rules.keys).to contain_exactly("xsd", "iso19136_2007")
    end
  end

  describe "#register_rule_definition" do
    it "registers a rule definition by id" do
      registry.register_rule_definition(rule_definition)

      expect(registry.rule_definitions["rule-xsd-cls-type"]).to eq(rule_definition)
    end
  end

  describe "#has_rule?" do
    before do
      registry.register_encoding_rule(base_encoding_rule)
      registry.register_encoding_rule(child_encoding_rule)
    end

    context "when rule is in current encoding rule" do
      it "returns true" do
        expect(registry.has_rule?("rule-xsd-cls-type", "xsd")).to be true
      end
    end

    context "when rule is in parent encoding rule" do
      it "returns true for inherited rule" do
        expect(registry.has_rule?("rule-xsd-cls-type", "iso19136_2007")).to be true
      end
    end

    context "when rule is only in child encoding rule" do
      it "returns true" do
        expect(registry.has_rule?("rule-xsd-all-naming-gml", "iso19136_2007")).to be true
      end

      it "returns false for parent" do
        expect(registry.has_rule?("rule-xsd-all-naming-gml", "xsd")).to be false
      end
    end

    context "when rule does not exist" do
      it "returns false" do
        expect(registry.has_rule?("non-existent-rule", "xsd")).to be false
      end
    end

    context "when encoding rule does not exist" do
      it "returns false" do
        expect(registry.has_rule?("rule-xsd-cls-type", "non-existent")).to be false
      end
    end
  end

  describe "#all_rules_for" do
    before do
      registry.register_encoding_rule(base_encoding_rule)
      registry.register_encoding_rule(child_encoding_rule)
    end

    it "returns all rules for base encoding rule" do
      rules = registry.all_rules_for("xsd")

      expect(rules).to contain_exactly(
        "rule-xsd-cls-type",
        "rule-xsd-cls-object-element"
      )
    end

    it "returns all rules including inherited ones" do
      rules = registry.all_rules_for("iso19136_2007")

      expect(rules).to contain_exactly(
        "rule-xsd-cls-type",
        "rule-xsd-cls-object-element",
        "rule-xsd-all-naming-gml"
      )
    end

    it "removes duplicates if same rule appears in parent and child" do
      # Add a rule that exists in both
      child_with_duplicate = Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "custom"
        er.extends = "xsd"
        er.rules = ["rule-xsd-cls-type", "rule-custom"]
      end
      registry.register_encoding_rule(child_with_duplicate)

      rules = registry.all_rules_for("custom")

      expect(rules.count("rule-xsd-cls-type")).to eq(1)
      expect(rules).to include("rule-xsd-cls-type", "rule-custom")
    end

    it "returns empty array for non-existent encoding rule" do
      rules = registry.all_rules_for("non-existent")

      expect(rules).to eq([])
    end
  end

  describe "#encoding_rule" do
    before do
      registry.register_encoding_rule(base_encoding_rule)
    end

    it "returns encoding rule by name" do
      expect(registry.encoding_rule("xsd")).to eq(base_encoding_rule)
    end

    it "returns nil for non-existent encoding rule" do
      expect(registry.encoding_rule("non-existent")).to be_nil
    end
  end

  describe "#rule_definition" do
    before do
      registry.register_rule_definition(rule_definition)
    end

    it "returns rule definition by id" do
      expect(registry.rule_definition("rule-xsd-cls-type")).to eq(rule_definition)
    end

    it "returns nil for non-existent rule definition" do
      expect(registry.rule_definition("non-existent")).to be_nil
    end
  end

  describe "inheritance chain" do
    let(:grandparent_rule) do
      Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "base"
        er.rules = ["rule-base"]
      end
    end

    let(:parent_rule) do
      Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "parent"
        er.extends = "base"
        er.rules = ["rule-parent"]
      end
    end

    let(:child_rule) do
      Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "child"
        er.extends = "parent"
        er.rules = ["rule-child"]
      end
    end

    before do
      registry.register_encoding_rule(grandparent_rule)
      registry.register_encoding_rule(parent_rule)
      registry.register_encoding_rule(child_rule)
    end

    it "traverses full inheritance chain" do
      expect(registry.has_rule?("rule-base", "child")).to be true
      expect(registry.has_rule?("rule-parent", "child")).to be true
      expect(registry.has_rule?("rule-child", "child")).to be true
    end

    it "collects all rules from inheritance chain" do
      rules = registry.all_rules_for("child")

      expect(rules).to contain_exactly("rule-base", "rule-parent", "rule-child")
    end
  end
end