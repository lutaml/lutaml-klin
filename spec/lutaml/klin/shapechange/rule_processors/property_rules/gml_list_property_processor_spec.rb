# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../../../lib/lutaml/klin/shapechange/rule_processors/property_rules/gml_list_property_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::GmlListPropertyProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-prop-gmlListProperty")
    end
  end

  describe "#process" do
    context "when property is a GML list property with no restrictions" do
      let(:property) do
        instance_double(
          "Property",
          name: "values",
          tagged_values: { "gmlListProperty" => "true" },
          lower_value: instance_double("Value", value: 0),
          upper_value: instance_double("Value", value: -1)
        )
      end

      let(:context) { { item_type: "xs:double" } }

      it "applies the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:is_list]).to be true
      end

      it "does not need restrictions" do
        result = processor.process(property, context)

        expect(result[:result][:needs_restriction]).to be false
      end

      it "includes item type" do
        result = processor.process(property, context)

        expect(result[:result][:item_type]).to eq("xs:double")
      end
    end

    context "when property has length restrictions" do
      let(:property) do
        instance_double(
          "Property",
          name: "limitedValues",
          tagged_values: { "gmlListProperty" => "true" },
          lower_value: instance_double("Value", value: 2),
          upper_value: instance_double("Value", value: 5)
        )
      end

      let(:context) { { item_type: "xs:integer" } }

      it "needs restrictions" do
        result = processor.process(property, context)

        expect(result[:result][:needs_restriction]).to be true
      end

      it "sets min and max length" do
        result = processor.process(property, context)

        expect(result[:result][:min_length]).to eq(2)
        expect(result[:result][:max_length]).to eq(5)
      end

      it "does not use single length facet" do
        result = processor.process(property, context)

        expect(result[:result][:use_length]).to be false
      end
    end

    context "when property has fixed length" do
      let(:property) do
        instance_double(
          "Property",
          name: "fixedValues",
          tagged_values: { "gmlListProperty" => "true" },
          lower_value: instance_double("Value", value: 3),
          upper_value: instance_double("Value", value: 3)
        )
      end

      let(:context) { { item_type: "xs:string" } }

      it "uses single length facet" do
        result = processor.process(property, context)

        expect(result[:result][:use_length]).to be true
        expect(result[:result][:min_length]).to eq(3)
        expect(result[:result][:max_length]).to eq(3)
      end
    end

    context "when property has only minimum length" do
      let(:property) do
        instance_double(
          "Property",
          name: "minOnly",
          tagged_values: { "gmlListProperty" => "true" },
          lower_value: instance_double("Value", value: 1),
          upper_value: instance_double("Value", value: -1)
        )
      end

      let(:context) { { item_type: "xs:double" } }

      it "sets only min length" do
        result = processor.process(property, context)

        expect(result[:result][:min_length]).to eq(1)
        expect(result[:result][:max_length]).to be_nil
      end

      it "needs restrictions" do
        result = processor.process(property, context)

        expect(result[:result][:needs_restriction]).to be true
      end
    end

    context "when property has only maximum length" do
      let(:property) do
        instance_double(
          "Property",
          name: "maxOnly",
          tagged_values: { "gmlListProperty" => "true" },
          lower_value: instance_double("Value", value: 0),
          upper_value: instance_double("Value", value: 10)
        )
      end

      let(:context) { { item_type: "xs:integer" } }

      it "sets only max length" do
        result = processor.process(property, context)

        expect(result[:result][:min_length]).to eq(0)
        expect(result[:result][:max_length]).to eq(10)
      end

      it "needs restrictions" do
        result = processor.process(property, context)

        expect(result[:result][:needs_restriction]).to be true
      end
    end

    context "when gmlListProperty tag is false" do
      let(:property) do
        instance_double(
          "Property",
          name: "notList",
          tagged_values: { "gmlListProperty" => "false" }
        )
      end

      it "does not apply the rule" do
        result = processor.process(property)

        expect(result[:applies]).to be false
      end
    end

    context "when gmlListProperty tag is missing" do
      let(:property) do
        instance_double(
          "Property",
          name: "plain",
          tagged_values: {}
        )
      end

      it "does not apply the rule" do
        result = processor.process(property)

        expect(result[:applies]).to be false
        expect(result[:message]).to eq("Not a GML list property")
      end
    end

    context "when handling asterisk as unbounded" do
      let(:property) do
        instance_double(
          "Property",
          name: "asterisk",
          tagged_values: { "gmlListProperty" => "true" },
          lower_value: instance_double("Value", value: 0),
          upper_value: instance_double("Value", value: "*")
        )
      end

      it "converts asterisk to unbounded" do
        result = processor.process(property)

        expect(result[:result][:max_length]).to be_nil
      end
    end
  end
end