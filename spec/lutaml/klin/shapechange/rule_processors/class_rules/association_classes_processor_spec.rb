# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../../../lib/lutaml/klin/shapechange/rule_processors/class_rules/association_classes_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::AssociationClassesProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-rel-association-classes")
    end
  end

  describe "#process" do
    context "when class is an association class" do
      let(:end1) do
        double(
          "Property",
          name: "source",
          type: "SourceType",
          navigable?: true,
          lower_value: double("Value", value: 1),
          upper_value: double("Value", value: 1)
        )
      end

      let(:end2) do
        double(
          "Property",
          name: "target",
          type: "TargetType",
          navigable?: true,
          lower_value: double("Value", value: 0),
          upper_value: double("Value", value: "*")
        )
      end

      let(:association) do
        double(
          "Association",
          member_end: [end1, end2]
        )
      end

      let(:uml_class) do
        double(
          "Class",
          name: "AssociationClass",
          is_association_class: association
        )
      end

      it "processes association class ends" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
        expect(result[:result][:end1]).to eq(end1)
        expect(result[:result][:end2]).to eq(end2)
      end

      it "extracts association end information" do
        result = processor.process(uml_class)
        ends = result[:result][:association_ends]

        expect(ends.size).to eq(2)
        expect(ends[0][:name]).to eq("source")
        expect(ends[0][:type]).to eq("SourceType")
        expect(ends[1][:name]).to eq("target")
        expect(ends[1][:type]).to eq("TargetType")
      end

      it "extracts multiplicity correctly" do
        result = processor.process(uml_class)
        ends = result[:result][:association_ends]

        expect(ends[0][:multiplicity]).to eq(min: 1, max: 1)
        expect(ends[1][:multiplicity]).to eq(min: 0, max: "*")
      end

      it "includes navigability information" do
        result = processor.process(uml_class)
        ends = result[:result][:association_ends]

        expect(ends[0][:navigable]).to be true
        expect(ends[1][:navigable]).to be true
      end

      it "provides descriptive message" do
        result = processor.process(uml_class)

        expect(result[:message]).to include("AssociationClass")
      end
    end

    context "when class is not an association class" do
      let(:uml_class) do
        double(
          "Class",
          name: "RegularClass",
          is_association_class: nil
        )
      end

      it "does not apply the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be false
        expect(result[:result]).to be_nil
      end

      it "provides appropriate message" do
        result = processor.process(uml_class)

        expect(result[:message]).to eq("Not an association class")
      end
    end

    context "when association has no member ends" do
      let(:association) do
        double(
          "Association",
          member_end: nil
        )
      end

      let(:uml_class) do
        double(
          "Class",
          name: "EmptyAssociationClass",
          is_association_class: association
        )
      end

      it "handles missing member ends gracefully" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
        expect(result[:result][:association_ends]).to eq([])
      end
    end
  end
end