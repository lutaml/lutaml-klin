# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/codelist_as_dictionary_gml33_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::CodelistAsDictionaryGml33Processor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-cls-codelist-asDictionaryGml33")
    end
  end

  describe "#process" do
    context "when class is a code list marked as dictionary for GML 3.3" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "LandUseCode",
          category: "codelist",
          as_dictionary_gml33?: true,
          tagged_values: {
            "codeList" => "http://example.org/codelists/landuse",
            "codeListRepresentation" => "application/gml+xml;version=3.2"
          }
        )
      end

      it "applies the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
        expect(result[:result][:encoding_type]).to eq("gml:ReferenceType")
        expect(result[:result][:as_dictionary]).to be true
        expect(result[:result][:gml_version]).to eq("3.3")
      end

      it "extracts code list URI" do
        result = processor.process(uml_class)

        expect(result[:result][:code_list_uri]).to eq("http://example.org/codelists/landuse")
      end

      it "extracts representation type" do
        result = processor.process(uml_class)

        expect(result[:result][:representation]).to eq("application/gml+xml;version=3.2")
      end
    end

    context "when class has vocabulary instead of codeList" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "VocabularyCode",
          category: "codelist",
          as_dictionary_gml33?: true,
          tagged_values: {
            "vocabulary" => "http://example.org/vocab/terms"
          }
        )
      end

      it "uses vocabulary as code list URI" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
        expect(result[:result][:code_list_uri]).to eq("http://example.org/vocab/terms")
      end
    end

    context "when class uses asDictionaryGml33 tagged value" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "TaggedCode",
          category: "codelist",
          tagged_values: {
            "asDictionaryGml33" => "true",
            "codeList" => "http://example.org/codes"
          }
        )
      end

      before do
        allow(uml_class).to receive(:respond_to?).with(:as_dictionary?).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:as_dictionary).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:as_dictionary_gml33?).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:as_dictionary_gml33).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:category).and_return(true)
        allow(uml_class).to receive(:respond_to?).with(:tagged_values).and_return(true)
      end

      it "applies the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
        expect(result[:result][:encoding_type]).to eq("gml:ReferenceType")
      end
    end

    context "when class uses asDictionary method" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "DictCode",
          category: "codelist",
          as_dictionary?: true,
          tagged_values: {}
        )
      end

      it "applies the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
        expect(result[:result][:gml_version]).to eq("3.3")
      end
    end

    context "when class is not a code list" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "RegularClass",
          category: "feature"
        )
      end

      it "does not apply the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be false
        expect(result[:result]).to be_nil
      end
    end

    context "when code list is not marked as dictionary" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "EnumCode",
          category: "codelist",
          as_dictionary?: false,
          tagged_values: {}
        )
      end

      before do
        allow(uml_class).to receive(:respond_to?).with(:category).and_return(true)
        allow(uml_class).to receive(:respond_to?).with(:tagged_values).and_return(true)
        allow(uml_class).to receive(:respond_to?).with(:as_dictionary?).and_return(true)
        allow(uml_class).to receive(:respond_to?).with(:as_dictionary).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:as_dictionary_gml33?).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:as_dictionary_gml33).and_return(false)
      end

      it "does not apply the rule" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be false
      end
    end

    context "when class has no code list URI" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "NoUriCode",
          category: "codelist",
          as_dictionary_gml33?: true,
          tagged_values: {}
        )
      end

      it "still applies but URI is nil" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
        expect(result[:result][:code_list_uri]).to be_nil
      end
    end

    context "when class has whitespace in URI" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "SpacedCode",
          category: "codelist",
          as_dictionary_gml33?: true,
          tagged_values: {
            "codeList" => "  http://example.org/codes  "
          }
        )
      end

      it "strips whitespace from URI" do
        result = processor.process(uml_class)

        expect(result[:result][:code_list_uri]).to eq("http://example.org/codes")
      end
    end

    context "when category is uppercase" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "UpperCode",
          category: "CODELIST",
          as_dictionary_gml33?: true,
          tagged_values: {}
        )
      end

      it "handles case-insensitive category" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
      end
    end

    context "when category is a symbol" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "SymbolCode",
          category: :codelist,
          as_dictionary_gml33?: true,
          tagged_values: {}
        )
      end

      it "handles symbol category" do
        result = processor.process(uml_class)

        expect(result[:applies]).to be true
      end
    end
  end
end
