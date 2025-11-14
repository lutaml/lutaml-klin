# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/nil_reason_allowed_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::NilReasonAllowedProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-prop-nilReasonAllowed")
    end
  end

  describe "#process" do
    context "when property has nilReasonAllowed" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: true,
          voidable?: false,
          matches?: false
        )
      end

      let(:context) { { gml_version: "3.2" } }

      it "applies the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:add_nil_reason]).to be true
      end

      it "uses GML 3.2 NilReasonType" do
        result = processor.process(property, context)

        expect(result[:result][:nil_reason_type]).to eq("gml:NilReasonType")
      end
    end

    context "when property is voidable with nillable rule" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: false,
          voidable?: true,
          matches?: true
        )
      end

      let(:context) { { gml_version: "3.2" } }

      it "applies the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:add_nil_reason]).to be true
      end
    end

    context "when GML version is 3.1" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: true,
          voidable?: false,
          matches?: false
        )
      end

      let(:context) { { gml_version: "3.1" } }

      it "uses GML 3.1 NullType" do
        result = processor.process(property, context)

        expect(result[:result][:nil_reason_type]).to eq("gml:NullType")
      end
    end

    context "when GML version is 3.0" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: true,
          voidable?: false,
          matches?: false
        )
      end

      let(:context) { { gml_version: "3.0" } }

      it "uses GML 3.0/3.1 NullType" do
        result = processor.process(property, context)

        expect(result[:result][:nil_reason_type]).to eq("gml:NullType")
      end
    end

    context "when no GML version specified" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: true,
          voidable?: false,
          matches?: false
        )
      end

      let(:context) { {} }

      it "defaults to GML 3.2" do
        result = processor.process(property, context)

        expect(result[:result][:nil_reason_type]).to eq("gml:NilReasonType")
        expect(result[:result][:gml_version]).to eq("3.2")
      end
    end

    context "when property is neither nilReasonAllowed nor voidable" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: false,
          voidable?: false,
          matches?: false
        )
      end

      let(:context) { {} }

      it "does not apply the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be false
        expect(result[:result]).to be_nil
      end
    end

    context "when property is voidable but nillable rule does not apply" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: false,
          voidable?: true,
          matches?: false
        )
      end

      let(:context) { {} }

      it "does not apply the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be false
      end
    end

    context "when using alternative method names" do
      let(:property) do
        double("Property")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:nil_reason_allowed?).and_return(false)
        allow(property).to receive(:respond_to?).with(:voidable?).and_return(false)
        allow(property).to receive(:respond_to?).with(:matches?).and_return(false)
        allow(property).to receive(:respond_to?).with(:nilReasonAllowed).and_return(true)
        allow(property).to receive(:nilReasonAllowed).and_return(true)
      end

      it "checks alternative method names" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
      end
    end

    context "when methods raise exceptions" do
      let(:property) do
        double("Property")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:nil_reason_allowed?).and_return(true)
        allow(property).to receive(:nil_reason_allowed?).and_raise(StandardError)
        allow(property).to receive(:respond_to?).with(:nilReasonAllowed).and_return(true)
        allow(property).to receive(:nilReasonAllowed).and_return(true)
      end

      it "handles exceptions gracefully" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
      end
    end

    context "when both nilReasonAllowed and voidable are true" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: true,
          voidable?: true,
          matches?: true
        )
      end

      let(:context) { { gml_version: "3.2" } }

      it "applies the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:add_nil_reason]).to be true
      end
    end

    context "when property uses voidable without question mark" do
      let(:property) do
        double("Property")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:nil_reason_allowed?).and_return(false)
        allow(property).to receive(:respond_to?).with(:nilReasonAllowed).and_return(false)
        allow(property).to receive(:respond_to?).with(:voidable?).and_return(false)
        allow(property).to receive(:respond_to?).with(:voidable).and_return(true)
        allow(property).to receive(:voidable).and_return(true)
        allow(property).to receive(:respond_to?).with(:matches?).and_return(true)
        allow(property).to receive(:matches?).with("rule-xsd-prop-nillable").and_return(true)
      end

      it "handles voidable without question mark" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
      end
    end

    context "when matches? raises exception" do
      let(:property) do
        double(
          "Property",
          nil_reason_allowed?: false,
          voidable?: true,
          matches?: true
        )
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:matches?).and_raise(StandardError)
      end

      it "assumes nillable rule applies when check fails" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
      end
    end
  end

  describe "GML version handling" do
    let(:property) do
      double(
        "Property",
        nil_reason_allowed?: true,
        voidable?: false,
        matches?: false
      )
    end

    it "supports GML 3.2" do
      result = processor.process(property, { gml_version: "3.2" })
      expect(result[:result][:nil_reason_type]).to eq("gml:NilReasonType")
    end

    it "supports GML 3.1" do
      result = processor.process(property, { gml_version: "3.1" })
      expect(result[:result][:nil_reason_type]).to eq("gml:NullType")
    end

    it "supports GML 3.0" do
      result = processor.process(property, { gml_version: "3.0" })
      expect(result[:result][:nil_reason_type]).to eq("gml:NullType")
    end

    it "handles unknown version by defaulting to 3.2" do
      result = processor.process(property, { gml_version: "4.0" })
      expect(result[:result][:nil_reason_type]).to eq("gml:NilReasonType")
    end
  end

  describe "message generation" do
    let(:property) do
      double(
        "Property",
        nil_reason_allowed?: true,
        voidable?: false,
        matches?: false
      )
    end

    it "provides descriptive message when rule applies" do
      result = processor.process(property, {})
      expect(result[:message]).to include("allows nil reason")
    end

    it "provides descriptive message when rule does not apply" do
      property = double(
        "Property",
        nil_reason_allowed?: false,
        voidable?: false,
        matches?: false
      )
      result = processor.process(property, {})
      expect(result[:message]).to include("does not allow")
    end
  end
end