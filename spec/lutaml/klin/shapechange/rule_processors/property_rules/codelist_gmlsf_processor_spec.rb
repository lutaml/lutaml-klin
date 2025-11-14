# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/codelist_gmlsf_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::CodelistGmlsfProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-cls-codelist-gmlsf")
    end
  end

  describe "#process" do
    let(:code_list_type) do
      double(
        "CodeListType",
        category: "codelist",
        tagged_values: {
          "codeList" => "http://example.org/codelists/landuse"
        }
      )
    end

    let(:containing_class) do
      double(
        "ContainingClass",
        name: "LandUse",
        matches?: true
      )
    end

    let(:property) do
      double(
        "Property",
        name: "code",
        type: double(id: "code_list_id", name: "LandUseCode")
      )
    end

    let(:model) do
      double(
        "Model",
        class_by_id: code_list_type,
        class_by_name: code_list_type
      )
    end

    let(:context) do
      {
        model: model,
        containing_class: containing_class,
        value_type: code_list_type
      }
    end

    context "when property has GMLSF code list type" do
      it "applies the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:encoding_type]).to eq("gml:CodeType")
        expect(result[:result][:gmlsf_encoding]).to be true
      end

      it "extracts code list URI" do
        result = processor.process(property, context)

        expect(result[:result][:fixed_code_space]).to eq("http://example.org/codelists/landuse")
      end

      it "indicates anonymous type creation" do
        result = processor.process(property, context)

        expect(result[:result][:creates_anonymous_type]).to be true
      end
    end

    context "when code list uses vocabulary tag" do
      let(:code_list_type) do
        double(
          "CodeListType",
          category: "codelist",
          tagged_values: {
            "vocabulary" => "http://example.org/vocab/building"
          }
        )
      end

      it "uses vocabulary as code space" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:fixed_code_space]).to eq("http://example.org/vocab/building")
      end
    end

    context "when code list has whitespace in URI" do
      let(:code_list_type) do
        double(
          "CodeListType",
          category: "codelist",
          tagged_values: {
            "codeList" => "  http://example.org/codes  "
          }
        )
      end

      it "strips whitespace from URI" do
        result = processor.process(property, context)

        expect(result[:result][:fixed_code_space]).to eq("http://example.org/codes")
      end
    end

    context "when containing class doesn't match rule" do
      let(:containing_class) do
        double(
          "ContainingClass",
          name: "Feature",
          matches?: false
        )
      end

      it "does not apply the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be false
      end
    end

    context "when property type is not a code list" do
      let(:code_list_type) do
        double(
          "RegularType",
          category: "datatype",
          tagged_values: {}
        )
      end

      it "does not apply the rule" do
        result = processor.process(property, context)

        expect(result[:applies]).to be false
      end
    end

    context "when value type is provided in context" do
      it "uses context value type" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
      end
    end

    context "when value type must be resolved from model" do
      let(:context_without_value_type) do
        {
          model: model,
          containing_class: containing_class
        }
      end

      it "resolves value type from model" do
        result = processor.process(property, context_without_value_type)

        expect(result[:applies]).to be true
      end
    end

    context "when containing class is provided in context" do
      it "uses context containing class" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
      end
    end

    context "when containing class must be resolved from property" do
      let(:property_with_in_class) do
        double(
          "Property",
          name: "code",
          type: double(id: "code_list_id", name: "LandUseCode"),
          in_class: containing_class
        )
      end

      let(:context_without_containing_class) do
        {
          model: model,
          value_type: code_list_type
        }
      end

      it "resolves containing class from property" do
        result = processor.process(property_with_in_class, context_without_containing_class)

        expect(result[:applies]).to be true
      end
    end

    context "when code list has no URI" do
      let(:code_list_type) do
        double(
          "CodeListType",
          category: "codelist",
          tagged_values: {}
        )
      end

      it "still applies but URI is nil" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
        expect(result[:result][:fixed_code_space]).to be_nil
      end
    end

    context "when category is uppercase" do
      let(:code_list_type) do
        double(
          "CodeListType",
          category: "CODELIST",
          tagged_values: {
            "codeList" => "http://example.org/codes"
          }
        )
      end

      it "handles case-insensitive category" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
      end
    end

    context "when category is a symbol" do
      let(:code_list_type) do
        double(
          "CodeListType",
          category: :codelist,
          tagged_values: {
            "codeList" => "http://example.org/codes"
          }
        )
      end

      it "handles symbol category" do
        result = processor.process(property, context)

        expect(result[:applies]).to be true
      end
    end
  end
end