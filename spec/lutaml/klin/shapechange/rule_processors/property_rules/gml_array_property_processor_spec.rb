# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../../../lib/lutaml/klin/shapechange/rule_processors/property_rules/gml_array_property_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::GmlArrayPropertyProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-prop-gmlArrayProperty")
    end
  end

  describe "#process" do
    context "when property is a GML array property" do
      let(:property) do
        instance_double(
          "Property",
          name: "members",
          tagged_values: {
            "gmlArrayProperty" => "true",
            "inlineOrByReference" => "inline"
          },
          lower_value: instance_double("Value", value: 0),
          upper_value: instance_double("Value", value: -1)
        )
      end

      let(:context) do
        {
          inline_or_by_reference: "inline",
          target_element: "gml:AbstractFeature"
        }
      end

      it "applies the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:is_array]).to be true
      end

      it "sets multiplicity correctly" do
        result = processor.process(property, context)

        expect(result[:result][:min_occurs]).to eq(0)
        expect(result[:result][:max_occurs]).to eq("unbounded")
      end

      it "includes target element" do
        result = processor.process(property, context)

        expect(result[:result][:target_element]).to eq("gml:AbstractFeature")
      end

      it "marks multiplicity as set" do
        result = processor.process(property, context)

        expect(result[:result][:multiplicity_set]).to be true
      end
    end

    context "when property has bounded multiplicity" do
      let(:property) do
        instance_double(
          "Property",
          name: "items",
          tagged_values: {
            "gmlArrayProperty" => "true",
            "inlineOrByReference" => "inline"
          },
          lower_value: instance_double("Value", value: 1),
          upper_value: instance_double("Value", value: 5)
        )
      end

      let(:context) { { inline_or_by_reference: "inline" } }

      it "uses specific numeric bounds" do
        result = processor.process(property, context)

        expect(result[:result][:min_occurs]).to eq(1)
        expect(result[:result][:max_occurs]).to eq(5)
      end
    end

    context "when property is not inline" do
      let(:property) do
        instance_double(
          "Property",
          name: "reference",
          tagged_values: {
            "gmlArrayProperty" => "true",
            "inlineOrByReference" => "byreference"
          }
        )
      end

      let(:context) { { inline_or_by_reference: "byreference" } }

      it "does not apply the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be false
      end

      it "provides appropriate message" do
        result = processor.process(property, context)

        expect(result[:message]).to eq("Not a GML array property")
      end
    end

    context "when gmlArrayProperty tag is false" do
      let(:property) do
        instance_double(
          "Property",
          name: "normal",
          tagged_values: {
            "gmlArrayProperty" => "false",
            "inlineOrByReference" => "inline"
          }
        )
      end

      let(:context) { { inline_or_by_reference: "inline" } }

      it "does not apply the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be false
      end
    end

    context "when gmlArrayProperty tag is missing" do
      let(:property) do
        instance_double(
          "Property",
          name: "plain",
          tagged_values: { "inlineOrByReference" => "inline" }
        )
      end

      let(:context) { { inline_or_by_reference: "inline" } }

      it "does not apply the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be false
      end
    end

    context "when handling unbounded upper value as asterisk" do
      let(:property) do
        instance_double(
          "Property",
          name: "unbounded",
          tagged_values: {
            "gmlArrayProperty" => "true",
            "inlineOrByReference" => "inline"
          },
          lower_value: instance_double("Value", value: 0),
          upper_value: instance_double("Value", value: "*")
        )
      end

      let(:context) { { inline_or_by_reference: "inline" } }

      it "converts asterisk to unbounded" do
        result = processor.process(property, context)

        expect(result[:result][:max_occurs]).to eq("unbounded")
      end
    end
  end
end
