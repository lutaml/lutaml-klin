# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/exclude_derived_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::ExcludeDerivedProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-prop-exclude-derived")
    end
  end

  describe "#process" do
    context "when property is derived using is_derived? method" do
      let(:property) do
        double(
          "Property",
          name: "area",
          is_derived?: true
        )
      end

      it "excludes the property" do
        result = processor.process(property)

        expect(result[:applies]).to be true
        expect(result[:result][:exclude_property]).to be true
        expect(result[:result][:derived]).to be true
      end

      it "provides exclusion reason" do
        result = processor.process(property)

        expect(result[:result][:reason]).to eq("derived")
      end
    end

    context "when property is derived using derived? method" do
      let(:property) do
        double(
          "Property",
          name: "perimeter",
          derived?: true
        )
      end

      before do
        allow(property).to receive(:respond_to?).with(:is_derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:is_derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived?).and_return(true)
      end

      it "excludes the property" do
        result = processor.process(property)

        expect(result[:result][:exclude_property]).to be true
      end
    end

    context "when property is derived using derived method (no ?)" do
      let(:property) do
        double(
          "Property",
          name: "diagonal",
          derived: true
        )
      end

      before do
        allow(property).to receive(:respond_to?).with(:is_derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:is_derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived).and_return(true)
      end

      it "excludes the property" do
        result = processor.process(property)

        expect(result[:result][:exclude_property]).to be true
      end
    end

    context "when property is derived via tagged value" do
      let(:property) do
        double(
          "Property",
          name: "computed",
          tagged_values: {
            "derived" => "true"
          }
        )
      end

      before do
        allow(property).to receive(:respond_to?).with(:is_derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:is_derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_values).and_return(true)
      end

      it "excludes the property" do
        result = processor.process(property)

        expect(result[:result][:exclude_property]).to be true
      end
    end

    context "when property is derived via isDerived tagged value" do
      let(:property) do
        double(
          "Property",
          name: "calculated",
          tagged_values: {
            "isDerived" => "true"
          }
        )
      end

      before do
        allow(property).to receive(:respond_to?).with(:is_derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:is_derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_values).and_return(true)
      end

      it "excludes the property" do
        result = processor.process(property)

        expect(result[:result][:exclude_property]).to be true
      end
    end

    context "when property is not derived" do
      let(:property) do
        double(
          "Property",
          name: "height",
          is_derived?: false
        )
      end

      it "does not exclude the property" do
        result = processor.process(property)

        expect(result[:applies]).to be true
        expect(result[:result][:exclude_property]).to be false
        expect(result[:result][:derived]).to be false
      end

      it "provides no exclusion reason" do
        result = processor.process(property)

        expect(result[:result][:reason]).to be_nil
      end
    end

    context "when property has no derived information" do
      let(:property) do
        double(
          "Property",
          name: "width",
          tagged_values: {}
        )
      end

      before do
        allow(property).to receive(:respond_to?).with(:is_derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:is_derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_values).and_return(true)
      end

      it "does not exclude the property" do
        result = processor.process(property)

        expect(result[:result][:exclude_property]).to be false
      end
    end

    context "when tagged value is false" do
      let(:property) do
        double(
          "Property",
          name: "length",
          tagged_values: {
            "derived" => "false"
          }
        )
      end

      before do
        allow(property).to receive(:respond_to?).with(:is_derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:is_derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_values).and_return(true)
      end

      it "does not exclude the property" do
        result = processor.process(property)

        expect(result[:result][:exclude_property]).to be false
      end
    end

    context "when derived method returns non-boolean" do
      let(:property) do
        double(
          "Property",
          name: "strange",
          derived: "maybe"
        )
      end

      before do
        allow(property).to receive(:respond_to?).with(:is_derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:is_derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived).and_return(true)
        allow(property).to receive(:respond_to?).with(:tagged_values).and_return(true)
        allow(property).to receive(:tagged_values).and_return({})
      end

      it "falls back to tagged values" do
        result = processor.process(property)

        expect(result[:result][:exclude_property]).to be false
      end
    end

    context "when method raises error" do
      let(:property) do
        double(
          "Property",
          name: "error_prop"
        )
      end

      before do
        allow(property).to receive(:respond_to?).with(:is_derived?).and_return(true)
        allow(property).to receive(:is_derived?).and_raise(StandardError)
        allow(property).to receive(:respond_to?).with(:is_derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived?).and_return(false)
        allow(property).to receive(:respond_to?).with(:derived).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_values).and_return(true)
        allow(property).to receive(:tagged_values).and_return({})
      end

      it "handles error gracefully" do
        result = processor.process(property)

        expect(result[:result][:exclude_property]).to be false
      end
    end
  end
end
