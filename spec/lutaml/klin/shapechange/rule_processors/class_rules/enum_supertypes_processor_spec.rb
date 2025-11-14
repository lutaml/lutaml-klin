# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/enum_supertypes_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::EnumSupertypesProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-cls-enum-supertypes")
    end
  end

  describe "#process" do
    context "when enumeration has supertype enumerations" do
      let(:red_prop) { double("Property", name: "red", initial_value: nil) }
      let(:blue_prop) { double("Property", name: "blue", initial_value: nil) }
      let(:yellow_prop) { double("Property", name: "yellow", initial_value: nil) }
      let(:green_prop) { double("Property", name: "green", initial_value: nil) }

      let(:base_enum) do
        double(
          "BaseEnum",
          name: "PrimaryColors",
          category: "enumeration",
          properties: { "red" => red_prop, "blue" => blue_prop },
          supertypes: nil
        )
      end

      let(:extended_enum) do
        double(
          "ExtendedEnum",
          name: "AllColors",
          category: "enumeration",
          properties: { "yellow" => yellow_prop, "green" => green_prop },
          supertypes: ["base_enum_id"]
        )
      end

      let(:model) do
        double(
          "Model",
          class_by_id: base_enum
        )
      end

      let(:context) { { model: model } }

      it "collects values from supertypes" do
        result = processor.process(extended_enum, context)

        expect(result[:applies]).to be true
        expect(result[:result][:all_values].size).to eq(4)
      end

      it "includes supertype values first" do
        result = processor.process(extended_enum, context)
        values = result[:result][:all_values]

        # Supertype values should come first
        expect(values[0][:name]).to eq("red")
        expect(values[1][:name]).to eq("blue")
        expect(values[2][:name]).to eq("yellow")
        expect(values[3][:name]).to eq("green")
      end

      it "tracks which class each value comes from" do
        result = processor.process(extended_enum, context)
        values = result[:result][:all_values]

        expect(values[0][:from_class]).to eq("PrimaryColors")
        expect(values[1][:from_class]).to eq("PrimaryColors")
        expect(values[2][:from_class]).to eq("AllColors")
        expect(values[3][:from_class]).to eq("AllColors")
      end

      it "indicates supertypes are included" do
        result = processor.process(extended_enum, context)

        expect(result[:result][:includes_supertypes]).to be true
        expect(result[:result][:class_count]).to eq(2)
      end
    end

    context "when enumeration has multiple inheritance levels" do
      let(:prop1) { double("Property", name: "value1", initial_value: nil) }
      let(:prop2) { double("Property", name: "value2", initial_value: nil) }
      let(:prop3) { double("Property", name: "value3", initial_value: nil) }
      let(:prop4) { double("Property", name: "value4", initial_value: nil) }

      let(:root_enum) do
        double(
          "RootEnum",
          name: "RootEnum",
          category: "enumeration",
          properties: { "value1" => prop1 },
          supertypes: nil
        )
      end

      let(:middle_enum) do
        double(
          "MiddleEnum",
          name: "MiddleEnum",
          category: "enumeration",
          properties: { "value2" => prop2 },
          supertypes: ["root_id"]
        )
      end

      let(:leaf_enum) do
        double(
          "LeafEnum",
          name: "LeafEnum",
          category: "enumeration",
          properties: { "value3" => prop3, "value4" => prop4 },
          supertypes: ["middle_id"]
        )
      end

      let(:model) do
        double("Model")
      end

      let(:context) { { model: model } }

      before do
        allow(model).to receive(:class_by_id).with("middle_id").and_return(middle_enum)
        allow(model).to receive(:class_by_id).with("root_id").and_return(root_enum)
      end

      it "collects values from entire hierarchy" do
        result = processor.process(leaf_enum, context)

        expect(result[:result][:all_values].size).to eq(4)
        expect(result[:result][:class_count]).to eq(3)
      end

      it "maintains correct order (root to leaf)" do
        result = processor.process(leaf_enum, context)
        values = result[:result][:all_values]

        expect(values[0][:name]).to eq("value1") # From root
        expect(values[1][:name]).to eq("value2") # From middle
        expect(values[2][:name]).to eq("value3") # From leaf
        expect(values[3][:name]).to eq("value4") # From leaf
      end
    end

    context "when enumeration has code list supertype" do
      let(:enum_prop) { double("Property", name: "enumValue", initial_value: nil) }
      let(:code_prop) { double("Property", name: "codeValue", initial_value: nil) }

      let(:code_list) do
        double(
          "CodeList",
          name: "BaseCodeList",
          category: "codelist",
          properties: { "codeValue" => code_prop },
          supertypes: nil
        )
      end

      let(:enumeration) do
        double(
          "Enumeration",
          name: "ExtendedEnum",
          category: "enumeration",
          properties: { "enumValue" => enum_prop },
          supertypes: ["codelist_id"]
        )
      end

      let(:model) do
        double(
          "Model",
          class_by_id: code_list
        )
      end

      let(:context) { { model: model } }

      it "includes code list values" do
        result = processor.process(enumeration, context)

        expect(result[:result][:all_values].size).to eq(2)
        expect(result[:result][:class_count]).to eq(2)
      end
    end

    context "when properties have initial values" do
      let(:prop_with_value) do
        double(
          "Property",
          name: "RED",
          initial_value: "r"
        )
      end

      let(:prop_without_value) do
        double(
          "Property",
          name: "BLUE",
          initial_value: nil
        )
      end

      let(:enumeration) do
        double(
          "Enumeration",
          name: "ColorEnum",
          category: "enumeration",
          properties: { "RED" => prop_with_value, "BLUE" => prop_without_value },
          supertypes: nil
        )
      end

      let(:model) { double("Model") }
      let(:context) { { model: model } }

      it "extracts initial values" do
        result = processor.process(enumeration, context)
        values = result[:result][:all_values]

        expect(values[0][:initial_value]).to eq("r")
        expect(values[1][:initial_value]).to be_nil
      end
    end

    context "when enumeration has no supertypes" do
      let(:prop) { double("Property", name: "value", initial_value: nil) }

      let(:enumeration) do
        double(
          "Enumeration",
          name: "SimpleEnum",
          category: "enumeration",
          properties: { "value" => prop },
          supertypes: nil
        )
      end

      let(:model) { double("Model") }
      let(:context) { { model: model } }

      it "processes only current class" do
        result = processor.process(enumeration, context)

        expect(result[:applies]).to be true
        expect(result[:result][:class_count]).to eq(1)
        expect(result[:result][:includes_supertypes]).to be false
      end
    end

    context "when enumeration has non-enum supertype" do
      let(:enum_prop) { double("Property", name: "value", initial_value: nil) }

      let(:feature_supertype) do
        double(
          "Feature",
          name: "FeatureType",
          category: "feature"
        )
      end

      let(:enumeration) do
        double(
          "Enumeration",
          name: "MixedEnum",
          category: "enumeration",
          properties: { "value" => enum_prop },
          supertypes: ["feature_id"]
        )
      end

      let(:model) do
        double(
          "Model",
          class_by_id: feature_supertype
        )
      end

      let(:context) { { model: model } }

      it "ignores non-enum supertype" do
        result = processor.process(enumeration, context)

        expect(result[:result][:class_count]).to eq(1)
        expect(result[:result][:includes_supertypes]).to be false
      end
    end

    context "when class is not an enumeration" do
      let(:feature) do
        double(
          "Feature",
          name: "Building",
          category: "feature"
        )
      end

      let(:context) { { model: double("Model") } }

      it "does not apply the rule" do
        result = processor.process(feature, context)

        expect(result[:applies]).to be false
        expect(result[:result]).to be_nil
      end
    end

    context "when category is uppercase" do
      let(:prop) { double("Property", name: "val", initial_value: nil) }

      let(:enumeration) do
        double(
          "Enumeration",
          name: "UpperEnum",
          category: "ENUMERATION",
          properties: { "val" => prop },
          supertypes: nil
        )
      end

      let(:context) { { model: double("Model") } }

      it "handles case-insensitive category" do
        result = processor.process(enumeration, context)

        expect(result[:applies]).to be true
      end
    end

    context "when category is a symbol" do
      let(:prop) { double("Property", name: "val", initial_value: nil) }

      let(:enumeration) do
        double(
          "Enumeration",
          name: "SymbolEnum",
          category: :enumeration,
          properties: { "val" => prop },
          supertypes: nil
        )
      end

      let(:context) { { model: double("Model") } }

      it "handles symbol category" do
        result = processor.process(enumeration, context)

        expect(result[:applies]).to be true
      end
    end

    context "when enumeration has empty properties" do
      let(:enumeration) do
        double(
          "Enumeration",
          name: "EmptyEnum",
          category: "enumeration",
          properties: {},
          supertypes: nil
        )
      end

      let(:context) { { model: double("Model") } }

      it "handles empty properties" do
        result = processor.process(enumeration, context)

        expect(result[:applies]).to be true
        expect(result[:result][:all_values]).to be_empty
      end
    end
  end
end