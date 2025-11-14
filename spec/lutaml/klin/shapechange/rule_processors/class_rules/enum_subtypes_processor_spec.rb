# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/enum_subtypes_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::EnumSubtypesProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-cls-enum-subtypes")
    end
  end

  describe "#process" do
    context "when enumeration has subtype enumerations" do
      let(:pending_prop) { double("Property", name: "pending", initial_value: nil) }
      let(:active_prop) { double("Property", name: "active", initial_value: nil) }
      let(:completed_prop) { double("Property", name: "completed", initial_value: nil) }
      let(:archived_prop) { double("Property", name: "archived", initial_value: nil) }

      let(:extended_enum) do
        double(
          "ExtendedEnum",
          name: "ExtendedStatus",
          category: "enumeration",
          properties: { "completed" => completed_prop, "archived" => archived_prop },
          subtypes: nil
        )
      end

      let(:base_enum) do
        double(
          "BaseEnum",
          name: "BaseStatus",
          category: "enumeration",
          properties: { "pending" => pending_prop, "active" => active_prop },
          subtypes: ["extended_enum_id"]
        )
      end

      let(:model) do
        double(
          "Model",
          class_by_id: extended_enum
        )
      end

      let(:context) { { model: model } }

      it "collects values from subtypes" do
        result = processor.process(base_enum, context)

        expect(result[:applies]).to be true
        expect(result[:result][:all_values].size).to eq(4)
      end

      it "includes current values first, then subtype values" do
        result = processor.process(base_enum, context)
        values = result[:result][:all_values]

        # Current class values should come first
        expect(values[0][:name]).to eq("pending")
        expect(values[1][:name]).to eq("active")
        # Then subtype values
        expect(values[2][:name]).to eq("completed")
        expect(values[3][:name]).to eq("archived")
      end

      it "tracks which class each value comes from" do
        result = processor.process(base_enum, context)
        values = result[:result][:all_values]

        expect(values[0][:from_class]).to eq("BaseStatus")
        expect(values[1][:from_class]).to eq("BaseStatus")
        expect(values[2][:from_class]).to eq("ExtendedStatus")
        expect(values[3][:from_class]).to eq("ExtendedStatus")
      end

      it "indicates subtypes are included" do
        result = processor.process(base_enum, context)

        expect(result[:result][:includes_subtypes]).to be true
        expect(result[:result][:class_count]).to eq(2)
      end
    end

    context "when enumeration has multiple subtype levels" do
      let(:prop1) { double("Property", name: "new", initial_value: nil) }
      let(:prop2) { double("Property", name: "active", initial_value: nil) }
      let(:prop3) { double("Property", name: "processing", initial_value: nil) }
      let(:prop4) { double("Property", name: "waiting", initial_value: nil) }
      let(:prop5) { double("Property", name: "validated", initial_value: nil) }
      let(:prop6) { double("Property", name: "finalized", initial_value: nil) }

      let(:detailed_state) do
        double(
          "DetailedState",
          name: "DetailedState",
          category: "enumeration",
          properties: { "validated" => prop5, "finalized" => prop6 },
          subtypes: nil
        )
      end

      let(:intermediate_state) do
        double(
          "IntermediateState",
          name: "IntermediateState",
          category: "enumeration",
          properties: { "processing" => prop3, "waiting" => prop4 },
          subtypes: ["detailed_id"]
        )
      end

      let(:basic_state) do
        double(
          "BasicState",
          name: "BasicState",
          category: "enumeration",
          properties: { "new" => prop1, "active" => prop2 },
          subtypes: ["intermediate_id"]
        )
      end

      let(:model) do
        double("Model")
      end

      let(:context) { { model: model } }

      before do
        allow(model).to receive(:class_by_id).with("intermediate_id").and_return(intermediate_state)
        allow(model).to receive(:class_by_id).with("detailed_id").and_return(detailed_state)
      end

      it "collects values from entire subtype hierarchy" do
        result = processor.process(basic_state, context)

        expect(result[:result][:all_values].size).to eq(6)
        expect(result[:result][:class_count]).to eq(3)
      end

      it "maintains correct order (current to leaf)" do
        result = processor.process(basic_state, context)
        values = result[:result][:all_values]

        # From current (BasicState)
        expect(values[0][:name]).to eq("new")
        expect(values[1][:name]).to eq("active")
        # From direct subtype (IntermediateState)
        expect(values[2][:name]).to eq("processing")
        expect(values[3][:name]).to eq("waiting")
        # From indirect subtype (DetailedState)
        expect(values[4][:name]).to eq("validated")
        expect(values[5][:name]).to eq("finalized")
      end
    end

    context "when enumeration has code list subtype" do
      let(:enum_prop) { double("Property", name: "enumValue", initial_value: nil) }
      let(:code_prop) { double("Property", name: "codeValue", initial_value: nil) }

      let(:code_list) do
        double(
          "CodeList",
          name: "ExtendedCodeList",
          category: "codelist",
          properties: { "codeValue" => code_prop },
          subtypes: nil
        )
      end

      let(:enumeration) do
        double(
          "Enumeration",
          name: "BaseEnum",
          category: "enumeration",
          properties: { "enumValue" => enum_prop },
          subtypes: ["codelist_id"]
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
          subtypes: nil
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

    context "when enumeration has no subtypes" do
      let(:prop) { double("Property", name: "value", initial_value: nil) }

      let(:enumeration) do
        double(
          "Enumeration",
          name: "SimpleEnum",
          category: "enumeration",
          properties: { "value" => prop },
          subtypes: nil
        )
      end

      let(:model) { double("Model") }
      let(:context) { { model: model } }

      it "processes only current class" do
        result = processor.process(enumeration, context)

        expect(result[:applies]).to be true
        expect(result[:result][:class_count]).to eq(1)
        expect(result[:result][:includes_subtypes]).to be false
      end
    end

    context "when enumeration has non-enum subtype" do
      let(:enum_prop) { double("Property", name: "value", initial_value: nil) }

      let(:feature_subtype) do
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
          subtypes: ["feature_id"]
        )
      end

      let(:model) do
        double(
          "Model",
          class_by_id: feature_subtype
        )
      end

      let(:context) { { model: model } }

      it "ignores non-enum subtype" do
        result = processor.process(enumeration, context)

        expect(result[:result][:class_count]).to eq(1)
        expect(result[:result][:includes_subtypes]).to be false
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
          subtypes: nil
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
          subtypes: nil
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
          subtypes: nil
        )
      end

      let(:context) { { model: double("Model") } }

      it "handles empty properties" do
        result = processor.process(enumeration, context)

        expect(result[:applies]).to be true
        expect(result[:result][:all_values]).to be_empty
      end
    end

    context "when enumeration has empty subtypes array" do
      let(:prop) { double("Property", name: "value", initial_value: nil) }

      let(:enumeration) do
        double(
          "Enumeration",
          name: "EmptySubtypesEnum",
          category: "enumeration",
          properties: { "value" => prop },
          subtypes: []
        )
      end

      let(:context) { { model: double("Model") } }

      it "handles empty subtypes" do
        result = processor.process(enumeration, context)

        expect(result[:applies]).to be true
        expect(result[:result][:class_count]).to eq(1)
        expect(result[:result][:includes_subtypes]).to be false
      end
    end

    context "when subtypes form a wide tree" do
      let(:prop1) { double("Property", name: "base", initial_value: nil) }
      let(:prop2) { double("Property", name: "sub1", initial_value: nil) }
      let(:prop3) { double("Property", name: "sub2", initial_value: nil) }
      let(:prop4) { double("Property", name: "sub3", initial_value: nil) }

      let(:subtype1) do
        double(
          "Subtype1",
          name: "Subtype1",
          category: "enumeration",
          properties: { "sub1" => prop2 },
          subtypes: nil
        )
      end

      let(:subtype2) do
        double(
          "Subtype2",
          name: "Subtype2",
          category: "enumeration",
          properties: { "sub2" => prop3 },
          subtypes: nil
        )
      end

      let(:subtype3) do
        double(
          "Subtype3",
          name: "Subtype3",
          category: "enumeration",
          properties: { "sub3" => prop4 },
          subtypes: nil
        )
      end

      let(:base_enum) do
        double(
          "BaseEnum",
          name: "BaseEnum",
          category: "enumeration",
          properties: { "base" => prop1 },
          subtypes: ["sub1_id", "sub2_id", "sub3_id"]
        )
      end

      let(:model) do
        double("Model")
      end

      let(:context) { { model: model } }

      before do
        allow(model).to receive(:class_by_id).with("sub1_id").and_return(subtype1)
        allow(model).to receive(:class_by_id).with("sub2_id").and_return(subtype2)
        allow(model).to receive(:class_by_id).with("sub3_id").and_return(subtype3)
      end

      it "collects values from all subtypes" do
        result = processor.process(base_enum, context)

        expect(result[:result][:all_values].size).to eq(4)
        expect(result[:result][:class_count]).to eq(4)
      end

      it "includes base value first" do
        result = processor.process(base_enum, context)
        values = result[:result][:all_values]

        expect(values[0][:name]).to eq("base")
      end
    end
  end
end