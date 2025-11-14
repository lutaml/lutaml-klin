# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Klin::Shapechange::EncodingRule, "Round-trip serialization" do
  describe "#to_xml and .from_xml" do
    it "round-trips encoding rule with lutaml-model" do
      # Create an encoding rule
      original = described_class.new(
        name: "test_rule",
        extends: "iso19136_2007"
      )
      original.rules = ["rule-xsd-cls-type", "rule-xsd-cls-object-element"]

      # Serialize to XML using lutaml-model's to_xml
      xml_output = original.to_xml

      # Verify XML structure
      expect(xml_output).to include('<EncodingRule')
      expect(xml_output).to include('name="test_rule"')
      expect(xml_output).to include('extends="iso19136_2007"')
      expect(xml_output).to include('<rule name="rule-xsd-cls-type"')
      expect(xml_output).to include('<rule name="rule-xsd-cls-object-element"')

      # Parse back
      parsed = described_class.from_xml(xml_output)

      # Verify round-trip accuracy
      expect(parsed.name).to eq(original.name)
      expect(parsed.extends).to eq(original.extends)
      expect(parsed.rules).to match_array(original.rules)
    end

    it "handles encoding rule without extends attribute" do
      original = described_class.new(name: "base_rule")
      original.rules = ["rule-xsd-cls-type"]

      xml_output = original.to_xml
      parsed = described_class.from_xml(xml_output)

      expect(parsed.name).to eq("base_rule")
      expect(parsed.extends).to be_nil
      expect(parsed.rules).to eq(["rule-xsd-cls-type"])
    end

    it "handles empty rules list" do
      original = described_class.new(name: "empty_rule", extends: "parent")

      xml_output = original.to_xml
      parsed = described_class.from_xml(xml_output)

      expect(parsed.name).to eq("empty_rule")
      expect(parsed.extends).to eq("parent")
      expect(parsed.rules).to be_empty
    end
  end

  describe "Modification and re-serialization" do
    it "can modify and re-serialize encoding rule" do
      # Parse from XML
      xml_input = <<~XML
        <EncodingRule name="custom" extends="iso19136_2007">
          <rule name="rule-xsd-cls-type"/>
        </EncodingRule>
      XML

      rule = described_class.from_xml(xml_input)

      # Modify
      rule.rules = rule.rules + ["rule-xsd-cls-object-element"]

      # Re-serialize
      xml_output = rule.to_xml

      # Verify modification persisted
      expect(xml_output).to include('name="custom"')
      expect(xml_output).to include('<rule name="rule-xsd-cls-type"')
      expect(xml_output).to include('<rule name="rule-xsd-cls-object-element"')

      # Parse again to verify
      re_parsed = described_class.from_xml(xml_output)
      expect(re_parsed.rules).to contain_exactly(
        "rule-xsd-cls-type",
        "rule-xsd-cls-object-element"
      )
    end
  end
end