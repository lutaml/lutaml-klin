# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/not_encoded_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::NotEncodedProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-all-notEncoded")
    end
  end

  describe "#process" do
    context "when encoding rule is 'notencoded'" do
      let(:property) do
        double(
          "Property",
          name: "internal_id",
          encoding_rule: "notencoded"
        )
      end

      let(:context) { {} }

      it "excludes the property" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:include_property]).to be false
        expect(result[:result][:is_not_encoded]).to be true
      end

      it "provides descriptive message" do
        result = processor.process(property, context)

        expect(result[:message]).to include("excluded")
        expect(result[:message]).to include("notencoded")
      end
    end

    context "when encoding rule is 'NOTENCODED' (uppercase)" do
      let(:property) do
        double(
          "Property",
          name: "prop",
          encoding_rule: "NOTENCODED"
        )
      end

      let(:context) { {} }

      it "handles case-insensitive comparison" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be false
        expect(result[:result][:is_not_encoded]).to be true
      end
    end

    context "when encoding rule is 'NotEncoded' (mixed case)" do
      let(:property) do
        double(
          "Property",
          name: "prop",
          encoding_rule: "NotEncoded"
        )
      end

      let(:context) { {} }

      it "handles mixed case" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be false
      end
    end

    context "when encoding rule is 'iso19136_2007'" do
      let(:property) do
        double(
          "Property",
          name: "normal_prop",
          encoding_rule: "iso19136_2007"
        )
      end

      let(:context) { {} }

      it "includes the property" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be true
        expect(result[:result][:is_not_encoded]).to be false
      end

      it "provides descriptive message" do
        result = processor.process(property, context)

        expect(result[:message]).to include("included")
        expect(result[:message]).to include("iso19136_2007")
      end
    end

    context "when encoding rule is not set" do
      let(:property) do
        double(
          "Property",
          name: "default_prop"
        )
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:encoding_rule).and_return(true)
        allow(property).to receive(:encoding_rule).with("xsd").and_return(nil)
        allow(property).to receive(:respond_to?).with(:encodingRule).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(false)
      end

      it "includes the property by default" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be true
        expect(result[:result][:is_not_encoded]).to be false
      end

      it "provides message indicating no rule" do
        result = processor.process(property, context)

        expect(result[:message]).to include("no encoding rule")
      end
    end

    context "when encoding rule is empty string" do
      let(:property) do
        double(
          "Property",
          name: "empty_prop",
          encoding_rule: ""
        )
      end

      let(:context) { {} }

      it "includes the property" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be true
        expect(result[:result][:is_not_encoded]).to be false
      end
    end

    context "when encoding rule is whitespace" do
      let(:property) do
        double(
          "Property",
          name: "space_prop",
          encoding_rule: "   "
        )
      end

      let(:context) { {} }

      it "includes the property" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be true
      end
    end

    context "when using alternative method name encodingRule" do
      let(:property) do
        double("Property")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:encoding_rule).and_return(true)
        allow(property).to receive(:encoding_rule).with("xsd").and_raise(StandardError)
        allow(property).to receive(:respond_to?).with(:encodingRule).and_return(true)
        allow(property).to receive(:encodingRule).with("xsd").and_return("notencoded")
      end

      it "uses fallback method" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be false
      end
    end

    context "when using tagged_value fallback" do
      let(:property) do
        double("Property")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:encoding_rule).and_return(true)
        allow(property).to receive(:encoding_rule).with("xsd").and_return(nil)
        allow(property).to receive(:respond_to?).with(:encodingRule).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:tagged_value).with("encodingRule").and_return("notencoded")
      end

      it "uses tagged_value as final fallback" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be false
      end
    end

    context "when encoding_rule method raises exception" do
      let(:property) do
        double("Property")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:encoding_rule).and_return(true)
        allow(property).to receive(:encoding_rule).and_raise(StandardError)
        allow(property).to receive(:respond_to?).with(:encodingRule).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(false)
      end

      it "handles exceptions gracefully" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be true
      end
    end

    context "when encoding rule contains 'notencoded' with surrounding text" do
      let(:property) do
        double(
          "Property",
          name: "prop",
          encoding_rule: "  notencoded  "
        )
      end

      let(:context) { {} }

      it "strips whitespace before comparison" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be false
      end
    end

    context "when encoding rule is similar but not exact" do
      let(:property) do
        double(
          "Property",
          name: "prop",
          encoding_rule: "encoded"
        )
      end

      let(:context) { {} }

      it "does not match partial strings" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be true
      end
    end

    context "when property has no encoding_rule method" do
      let(:property) do
        double(
          "Property",
          name: "legacy_prop"
        )
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:encoding_rule).and_return(false)
        allow(property).to receive(:respond_to?).with(:encodingRule).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(false)
      end

      it "includes the property by default" do
        result = processor.process(property, context)

        expect(result[:result][:include_property]).to be true
      end
    end
  end

  describe "encoding rule values" do
    let(:context) { {} }

    it "excludes with 'notencoded'" do
      prop = double("Property", encoding_rule: "notencoded")
      result = processor.process(prop, context)
      expect(result[:result][:include_property]).to be false
    end

    it "includes with 'iso19136_2007'" do
      prop = double("Property", encoding_rule: "iso19136_2007")
      result = processor.process(prop, context)
      expect(result[:result][:include_property]).to be true
    end

    it "includes with 'iso19139_2007'" do
      prop = double("Property", encoding_rule: "iso19139_2007")
      result = processor.process(prop, context)
      expect(result[:result][:include_property]).to be true
    end

    it "includes with custom encoding rule" do
      prop = double("Property", encoding_rule: "custom_encoding")
      result = processor.process(prop, context)
      expect(result[:result][:include_property]).to be true
    end
  end

  describe "message generation" do
    let(:context) { {} }

    it "provides excluded message for notencoded" do
      prop = double("Property", encoding_rule: "notencoded")
      result = processor.process(prop, context)
      expect(result[:message]).to match(/excluded.*notencoded/i)
    end

    it "provides included message with rule" do
      prop = double("Property", encoding_rule: "iso19136_2007")
      result = processor.process(prop, context)
      expect(result[:message]).to match(/included.*iso19136_2007/i)
    end

    it "provides no-rule message when not set" do
      prop = double("Property")
      allow(prop).to receive(:respond_to?).with(:encoding_rule).and_return(true)
      allow(prop).to receive(:encoding_rule).with("xsd").and_return(nil)
      allow(prop).to receive(:respond_to?).with(:encodingRule).and_return(false)
      allow(prop).to receive(:respond_to?).with(:tagged_value).and_return(false)
      result = processor.process(prop, context)
      expect(result[:message]).to include("no encoding rule")
    end
  end
end
