# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/no_property_type_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::NoPropertyTypeProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-cls-noPropertyType")
    end
  end

  describe "#process" do
    context "when class has includePropertyType=true" do
      let(:feature_class) do
        double(
          "Feature",
          name: "Building",
          category: "feature",
          include_property_type?: true,
          matches?: true
        )
      end

      let(:context) { {} }

      it "generates PropertyType" do
        result = processor.process(feature_class, context)

        expect(result[:applies]).to be true
        expect(result[:result][:generate_property_type]).to be true
      end

      it "provides correct reason" do
        result = processor.process(feature_class, context)

        expect(result[:result][:reason]).to include("explicitly set")
      end
    end

    context "when class has includePropertyType=false" do
      let(:feature_class) do
        double(
          "Feature",
          name: "SimpleDataType",
          category: "feature",
          include_property_type?: false,
          matches?: true
        )
      end

      let(:context) { {} }

      it "suppresses PropertyType" do
        result = processor.process(feature_class, context)

        expect(result[:applies]).to be true
        expect(result[:result][:generate_property_type]).to be false
      end

      it "provides correct reason" do
        result = processor.process(feature_class, context)

        expect(result[:result][:reason]).to include("suppressing generation")
      end
    end

    context "when includePropertyType is not set" do
      let(:feature_class) do
        double(
          "Feature",
          name: "DefaultClass",
          category: "feature",
          matches?: true
        )
      end

      let(:context) { {} }

      before do
        allow(feature_class).to receive(:respond_to?).with(:category).and_return(true)
        allow(feature_class).to receive(:respond_to?).with(:include_property_type?).and_return(false)
        allow(feature_class).to receive(:respond_to?).with(:includePropertyType).and_return(false)
        allow(feature_class).to receive(:respond_to?).with(:tagged_value).and_return(false)
        allow(feature_class).to receive(:respond_to?).with(:matches?).and_return(true)
      end

      it "suppresses PropertyType by default" do
        result = processor.process(feature_class, context)

        expect(result[:result][:generate_property_type]).to be false
      end
    end

    context "when class is an object" do
      let(:object_class) do
        double(
          "Object",
          name: "MyObject",
          category: "object",
          include_property_type?: true,
          matches?: true
        )
      end

      let(:context) { {} }

      it "applies to object classes" do
        result = processor.process(object_class, context)

        expect(result[:applies]).to be true
      end
    end

    context "when class is a mixin" do
      let(:mixin_class) do
        double(
          "Mixin",
          name: "MyMixin",
          category: "mixin",
          include_property_type?: false,
          matches?: true
        )
      end

      let(:context) { {} }

      it "applies to mixin classes" do
        result = processor.process(mixin_class, context)

        expect(result[:applies]).to be true
        expect(result[:result][:generate_property_type]).to be false
      end
    end

    context "when class is a datatype with SWE rule" do
      let(:swe_datatype) do
        double(
          "SWEDataType",
          name: "SWEType",
          category: "datatype",
          include_property_type?: true
        )
      end

      let(:context) { {} }

      before do
        allow(swe_datatype).to receive(:respond_to?).with(:category).and_return(true)
        allow(swe_datatype).to receive(:respond_to?).with(:include_property_type?).and_return(true)
        allow(swe_datatype).to receive(:respond_to?).with(:matches?).and_return(true)
        allow(swe_datatype).to receive(:matches?).with("rule-xsd-cls-standard-swe-property-types").and_return(true)
      end

      it "applies to SWE datatypes" do
        result = processor.process(swe_datatype, context)

        expect(result[:applies]).to be true
      end
    end

    context "when class is a datatype without identity" do
      let(:simple_datatype) do
        double(
          "SimpleDataType",
          name: "SimpleType",
          category: "datatype"
        )
      end

      let(:context) { {} }

      before do
        allow(simple_datatype).to receive(:respond_to?).with(:category).and_return(true)
        allow(simple_datatype).to receive(:respond_to?).with(:matches?).and_return(true)
        allow(simple_datatype).to receive(:matches?).with("rule-xsd-cls-standard-swe-property-types").and_return(false)
      end

      it "does not apply to datatypes without identity" do
        result = processor.process(simple_datatype, context)

        expect(result[:applies]).to be false
      end
    end

    context "when class is an enumeration" do
      let(:enum_class) do
        double(
          "Enumeration",
          name: "StatusEnum",
          category: "enumeration"
        )
      end

      let(:context) { {} }

      it "does not apply to enumerations" do
        result = processor.process(enum_class, context)

        expect(result[:applies]).to be false
        expect(result[:result][:generate_property_type]).to be true
      end
    end

    context "when class is a code list" do
      let(:codelist_class) do
        double(
          "CodeList",
          name: "StatusCode",
          category: "codelist"
        )
      end

      let(:context) { {} }

      it "does not apply to code lists" do
        result = processor.process(codelist_class, context)

        expect(result[:applies]).to be false
      end
    end

    context "when using alternative method names" do
      let(:feature_class) do
        double("Feature")
      end

      let(:context) { {} }

      before do
        allow(feature_class).to receive(:respond_to?).with(:category).and_return(true)
        allow(feature_class).to receive(:category).and_return("feature")
        allow(feature_class).to receive(:respond_to?).with(:include_property_type?).and_return(false)
        allow(feature_class).to receive(:respond_to?).with(:includePropertyType).and_return(true)
        allow(feature_class).to receive(:includePropertyType).and_return("true")
        allow(feature_class).to receive(:respond_to?).with(:matches?).and_return(true)
      end

      it "checks alternative method names" do
        result = processor.process(feature_class, context)

        expect(result[:applies]).to be true
        expect(result[:result][:generate_property_type]).to be true
      end
    end

    context "when using tagged_value method" do
      let(:feature_class) do
        double("Feature")
      end

      let(:context) { {} }

      before do
        allow(feature_class).to receive(:respond_to?).with(:category).and_return(true)
        allow(feature_class).to receive(:category).and_return("feature")
        allow(feature_class).to receive(:respond_to?).with(:include_property_type?).and_return(false)
        allow(feature_class).to receive(:respond_to?).with(:includePropertyType).and_return(false)
        allow(feature_class).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(feature_class).to receive(:tagged_value).with("includePropertyType").and_return("true")
        allow(feature_class).to receive(:respond_to?).with(:matches?).and_return(true)
      end

      it "uses tagged_value fallback" do
        result = processor.process(feature_class, context)

        expect(result[:applies]).to be true
        expect(result[:result][:generate_property_type]).to be true
      end
    end

    context "when category is uppercase" do
      let(:feature_class) do
        double(
          "Feature",
          name: "UpperFeature",
          category: "FEATURE",
          include_property_type?: false,
          matches?: true
        )
      end

      let(:context) { {} }

      it "handles case-insensitive category" do
        result = processor.process(feature_class, context)

        expect(result[:applies]).to be true
      end
    end

    context "when category is a symbol" do
      let(:feature_class) do
        double(
          "Feature",
          name: "SymbolFeature",
          category: :feature,
          include_property_type?: true,
          matches?: true
        )
      end

      let(:context) { {} }

      it "handles symbol category" do
        result = processor.process(feature_class, context)

        expect(result[:applies]).to be true
      end
    end

    context "when methods raise exceptions" do
      let(:feature_class) do
        double("Feature")
      end

      let(:context) { {} }

      before do
        allow(feature_class).to receive(:respond_to?).with(:category).and_return(true)
        allow(feature_class).to receive(:category).and_return("feature")
        allow(feature_class).to receive(:respond_to?).with(:include_property_type?).and_return(true)
        allow(feature_class).to receive(:include_property_type?).and_raise(StandardError)
        allow(feature_class).to receive(:respond_to?).with(:includePropertyType).and_return(true)
        allow(feature_class).to receive(:includePropertyType).and_return(true)
        allow(feature_class).to receive(:respond_to?).with(:matches?).and_return(true)
      end

      it "handles exceptions gracefully" do
        result = processor.process(feature_class, context)

        expect(result[:applies]).to be true
        expect(result[:result][:generate_property_type]).to be true
      end
    end
  end

  describe "message generation" do
    let(:feature_with_include) do
      double(
        "Feature",
        name: "Building",
        category: "feature",
        include_property_type?: true,
        matches?: true
      )
    end

    let(:feature_without_include) do
      double(
        "Feature",
        name: "Simple",
        category: "feature",
        include_property_type?: false,
        matches?: true
      )
    end

    it "provides descriptive message when generating" do
      result = processor.process(feature_with_include, {})
      expect(result[:message]).to include("will be generated")
    end

    it "provides descriptive message when suppressing" do
      result = processor.process(feature_without_include, {})
      expect(result[:message]).to include("suppressed")
    end
  end
end