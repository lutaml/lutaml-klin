# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../../../lib/lutaml/klin/shapechange/rule_processors/class_rules/by_value_property_type_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::ByValuePropertyTypeProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-cls-byValuePropertyType")
    end
  end

  describe "#process" do
    context "when class is a feature with identity" do
      let(:package) do
        double(
          "Package",
          xmlns: "app"
        )
      end

      let(:uml_class) do
        double(
          "Class",
          name: "Building",
          category: "feature",
          tagged_values: {},
          package: package
        )
      end

      it "applies the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
      end

      it "generates correct type name" do
        result = processor.process(uml_class)

        expect(result[:result][:type_name]).to eq("BuildingPropertyByValueType")
      end

      it "includes qualified element reference" do
        result = processor.process(uml_class)

        expect(result[:result][:element_ref]).to eq("app:Building")
      end

      it "marks as having identity" do
        result = processor.process(uml_class)

        expect(result[:result][:has_identity]).to be true
      end

      it "marks as inline only" do
        result = processor.process(uml_class)

        expect(result[:result][:inline_only]).to be true
      end
    end

    context "when class is an object with identity" do
      let(:uml_class) do
        double(
          "Class",
          name: "GeometricObject",
          category: "object",
          tagged_values: {},
          package: nil
        )
      end

      it "applies the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
      end

      it "uses unqualified name when package is nil" do
        result = processor.process(uml_class)

        expect(result[:result][:element_ref]).to eq("GeometricObject")
      end
    end

    context "when class is a mixin with identity" do
      let(:uml_class) do
        double(
          "Class",
          name: "Locatable",
          category: "mixin",
          tagged_values: {},
          package: nil
        )
      end

      it "applies the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
        expect(result[:result][:type_name]).to eq("LocatablePropertyByValueType")
      end
    end

    context "when class explicitly includes by-value property type" do
      let(:uml_class) do
        double(
          "Class",
          name: "ExplicitClass",
          category: "feature",
          tagged_values: { "includeByValuePropertyType" => "true" },
          package: nil
        )
      end

      it "applies the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
      end
    end

    context "when class explicitly excludes by-value property type" do
      let(:uml_class) do
        double(
          "Class",
          name: "ExcludedClass",
          category: "feature",
          tagged_values: { "includeByValuePropertyType" => "false" },
          package: nil
        )
      end

      it "does not apply the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be false
      end
    end

    context "when class is a datatype without identity" do
      let(:uml_class) do
        double(
          "Class",
          name: "MeasureType",
          category: "datatype",
          tagged_values: {},
          package: nil
        )
      end

      it "does not apply the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be false
      end

      it "provides appropriate message" do
        result = processor.process(uml_class)

        expect(result[:message]).to include("does not have identity")
      end
    end

    context "when class is an enumeration" do
      let(:uml_class) do
        double(
          "Class",
          name: "ColorEnum",
          category: "enumeration",
          tagged_values: {},
          package: nil
        )
      end

      it "does not apply the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be false
      end
    end

    context "when class is a codelist" do
      let(:uml_class) do
        double(
          "Class",
          name: "StatusCode",
          category: "codelist",
          tagged_values: {},
          package: nil
        )
      end

      it "does not apply the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be false
      end
    end
  end
end