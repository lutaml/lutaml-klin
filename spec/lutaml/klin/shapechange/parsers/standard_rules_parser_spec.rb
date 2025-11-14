# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/parsers/standard_rules_parser"

RSpec.describe Lutaml::Klin::Shapechange::Parsers::StandardRulesParser do
  let(:standard_rules_path) do
    File.expand_path(
      "../../../../../reference/shapechange-configs/StandardRules.xml",
      __dir__
    )
  end

  describe ".parse_file" do
    it "parses ShapeChange StandardRules.xml successfully" do
      expect(File).to exist(standard_rules_path)

      standard_rules = described_class.parse_file(standard_rules_path)

      expect(standard_rules).to be_a(Lutaml::Klin::Shapechange::StandardRules)
      expect(standard_rules.encoding_rules).to be_an(Array)
      expect(standard_rules.encoding_rules).not_to be_empty
    end

    it "loads iso19136_2007_INSPIRE_Extensions encoding rule" do
      standard_rules = described_class.parse_file(standard_rules_path)

      inspire_rule = standard_rules.find_encoding_rule("iso19136_2007_INSPIRE_Extensions")

      expect(inspire_rule).not_to be_nil
      expect(inspire_rule.name).to eq("iso19136_2007_INSPIRE_Extensions")
      expect(inspire_rule.extends).to eq("gml33")
      expect(inspire_rule.rules).to include("req-all-all-documentation")
      expect(inspire_rule.rules).to include("rule-xsd-cls-mixin-classes")
    end

    it "loads okstra encoding rule" do
      standard_rules = described_class.parse_file(standard_rules_path)

      okstra_rule = standard_rules.find_encoding_rule("okstra")

      expect(okstra_rule).not_to be_nil
      expect(okstra_rule.name).to eq("okstra")
      expect(okstra_rule.extends).to eq("iso19136_2007")
      expect(okstra_rule.rules).to include("rule-xsd-cls-no-base-class")
      expect(okstra_rule.rules).to include("rule-xsd-cls-okstra-schluesseltabelle")
    end

    it "loads gml21 encoding rule" do
      standard_rules = described_class.parse_file(standard_rules_path)

      gml21_rule = standard_rules.find_encoding_rule("gml21")

      expect(gml21_rule).not_to be_nil
      expect(gml21_rule.name).to eq("gml21")
      expect(gml21_rule.extends).to eq("iso19136_2007")
      expect(gml21_rule.rules).to include("rule-xsd-cls-codelist-anonymous-xlink")
      expect(gml21_rule.rules).to include("rule-xsd-all-gml21")
    end

    it "loads notEncoded encoding rule with wildcard extension" do
      standard_rules = described_class.parse_file(standard_rules_path)

      not_encoded_rule = standard_rules.find_encoding_rule("notEncoded")

      expect(not_encoded_rule).not_to be_nil
      expect(not_encoded_rule.name).to eq("notEncoded")
      expect(not_encoded_rule.extends).to eq("*")
      expect(not_encoded_rule.rules).to include("rule-xsd-all-notEncoded")
      expect(not_encoded_rule.rules).to include("rule-json-all-notEncoded")
    end

    it "loads citygml-ade encoding rule" do
      standard_rules = described_class.parse_file(standard_rules_path)

      citygml_rule = standard_rules.find_encoding_rule("citygml-ade")

      expect(citygml_rule).not_to be_nil
      expect(citygml_rule.name).to eq("citygml-ade")
      expect(citygml_rule.extends).to eq("iso19136_2007")
      expect(citygml_rule.rules).to include("req-xsd-cls-suppress-supertype")
      expect(citygml_rule.rules).to include("rule-xsd-cls-adeelement")
    end

    it "loads metadata-profile encoding rule" do
      standard_rules = described_class.parse_file(standard_rules_path)

      metadata_rule = standard_rules.find_encoding_rule("metadata-profile")

      expect(metadata_rule).not_to be_nil
      expect(metadata_rule.name).to eq("metadata-profile")
      expect(metadata_rule.extends).to eq("iso19139_2007")
      expect(metadata_rule.rules).to include("rule-xsd-cls-standard-19139-isoType")
      expect(metadata_rule.rules).to include("rule-xsd-pkg-schematron")
    end

    it "loads all encoding rules from StandardRules.xml" do
      standard_rules = described_class.parse_file(standard_rules_path)

      rule_names = standard_rules.encoding_rule_names

      expect(rule_names).to include("iso19136_2007_INSPIRE_Extensions")
      expect(rule_names).to include("okstra")
      expect(rule_names).to include("gml21")
      expect(rule_names).to include("notEncoded")
      expect(rule_names).to include("citygml-ade")
      expect(rule_names).to include("metadata-profile")
      expect(rule_names).to include("iso19136_2007_ShapeChange_1.0_Extensions")
      expect(rule_names).to include("external")
      expect(rule_names).to include("iso19136_2007_NoGmlBaseTypes")
    end
  end

  describe ".parse_encoding_rules" do
    it "returns array of encoding rules directly" do
      encoding_rules = described_class.parse_encoding_rules(standard_rules_path)

      expect(encoding_rules).to be_an(Array)
      expect(encoding_rules.first).to be_a(Lutaml::Klin::Shapechange::EncodingRule)
      expect(encoding_rules.size).to be >= 9
    end
  end
end