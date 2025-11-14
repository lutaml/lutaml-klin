# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/enumeration_processor"
require "lutaml/klin/shapechange/rule_processors/code_list_processor"
require "lutaml/klin/shapechange/models/xsd_document"
require "lutaml/klin/shapechange/rule_checker"
require "lutaml/klin/shapechange/rule_registry"

RSpec.describe "Special Type Processors" do
  let(:rule_registry) { Lutaml::Klin::Shapechange::RuleRegistry.new }
  let(:encoding_rule) { "iso19136_2007" }
  let(:rule_checker) { Lutaml::Klin::Shapechange::RuleChecker.new(rule_registry, encoding_rule) }
  let(:config) { double("config") }
  let(:xsd_doc) do
    Lutaml::Klin::Shapechange::Models::XsdDocument.new(
      namespace: "http://example.org/test",
      prefix: "test",
      version: "1.0"
    )
  end

  describe Lutaml::Klin::Shapechange::RuleProcessors::EnumerationProcessor do
    let(:processor) { described_class.new(rule_checker, config) }

    context "when processing an enumeration class" do
      let(:enum_class) do
        double(
          "EnumClass",
          name: "StatusCode",
          category: 5, # ENUMERATION
          values: [
            double("Value1", name: "active", value: "active"),
            double("Value2", name: "inactive", value: "inactive"),
            double("Value3", name: "pending", value: "pending")
          ]
        )
      end

      let(:context) do
        {
          xsd_document: xsd_doc,
          uml_class: enum_class,
          prefix: "test",
          config: config
        }
      end

      before do
        # Mock rule_checker to make this processor applicable
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-enum-object-element", enum_class)
          .and_return(true)
      end

      it "creates a simpleType with restriction base='string'" do
        processor.process(enum_class, context)

        xml = xsd_doc.to_xml
        expect(xml).to include('<simpleType name="StatusCodeType">')
        expect(xml).to include('<restriction base="string">')
      end

      it "adds enumeration values" do
        processor.process(enum_class, context)

        xml = xsd_doc.to_xml
        expect(xml).to include('<enumeration value="active"/>')
        expect(xml).to include('<enumeration value="inactive"/>')
        expect(xml).to include('<enumeration value="pending"/>')
      end

      it "generates valid XSD structure" do
        processor.process(enum_class, context)

        xml = xsd_doc.to_xml
        # Verify XSD namespace is present
        expect(xml).to include('xmlns="http://www.w3.org/2001/XMLSchema"')
        # Verify target namespace
        expect(xml).to include('targetNamespace="http://example.org/test"')
      end
    end

    context "when enumeration has no values" do
      let(:empty_enum) do
        double(
          "EmptyEnum",
          name: "EmptyStatus",
          category: 5,
          values: []
        )
      end

      let(:context) do
        {
          xsd_document: xsd_doc,
          uml_class: empty_enum,
          prefix: "test",
          config: config
        }
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-enum-object-element", empty_enum)
          .and_return(true)
      end

      it "creates simpleType but with no enumeration values" do
        processor.process(empty_enum, context)

        xml = xsd_doc.to_xml
        expect(xml).to include('<simpleType name="EmptyStatusType">')
        expect(xml).to include('<restriction base="string"/>')
      end
    end
  end

  describe Lutaml::Klin::Shapechange::RuleProcessors::CodeListProcessor do
    let(:processor) { described_class.new(rule_checker, config) }

    context "when processing a code list class" do
      let(:codelist_class) do
        double(
          "CodeListClass",
          name: "UsageCode",
          category: 4, # CODELIST
          values: [
            double("Code1", name: "residential", value: "residential"),
            double("Code2", name: "commercial", value: "commercial"),
            double("Code3", name: "industrial", value: "industrial")
          ]
        )
      end

      let(:context) do
        {
          xsd_document: xsd_doc,
          uml_class: codelist_class,
          prefix: "test",
          config: config
        }
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-codelist-constraints", codelist_class)
          .and_return(true)
      end

      it "creates union type combining enumeration and other types" do
        processor.process(codelist_class, context)

        xml = xsd_doc.to_xml
        expect(xml).to include('<simpleType name="UsageCodeType">')
        expect(xml).to include('<union memberTypes="test:UsageCodeEnumerationType test:UsageCodeOtherType"/>')
      end

      it "creates enumeration type with known values" do
        processor.process(codelist_class, context)

        xml = xsd_doc.to_xml
        expect(xml).to include('<simpleType name="UsageCodeEnumerationType">')
        expect(xml).to include('<enumeration value="residential"/>')
        expect(xml).to include('<enumeration value="commercial"/>')
        expect(xml).to include('<enumeration value="industrial"/>')
      end

      it "creates other type with pattern for extensibility" do
        processor.process(codelist_class, context)

        xml = xsd_doc.to_xml
        expect(xml).to include('<simpleType name="UsageCodeOtherType">')
        expect(xml).to include('<pattern value="other: \\w{2,}"/>')
      end

      it "generates complete code list structure" do
        processor.process(codelist_class, context)

        xml = xsd_doc.to_xml

        # Verify all three types are present
        expect(xml.scan(/<simpleType name="UsageCode/).size).to eq(3)

        # Verify the main union type
        expect(xml).to match(/<simpleType name="UsageCodeType">.*?<union.*?>.*?<\/simpleType>/m)

        # Verify enumeration type
        expect(xml).to match(/<simpleType name="UsageCodeEnumerationType">.*?<restriction.*?>.*?<\/restriction>.*?<\/simpleType>/m)

        # Verify other type
        expect(xml).to match(/<simpleType name="UsageCodeOtherType">.*?<pattern.*?>.*?<\/simpleType>/m)
      end
    end

    context "when code list has no predefined values" do
      let(:empty_codelist) do
        double(
          "EmptyCodeList",
          name: "CustomCode",
          category: 4,
          values: []
        )
      end

      let(:context) do
        {
          xsd_document: xsd_doc,
          uml_class: empty_codelist,
          prefix: "test",
          config: config
        }
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-codelist-constraints", empty_codelist)
          .and_return(true)
      end

      it "still creates union and other type for extensibility" do
        processor.process(empty_codelist, context)

        xml = xsd_doc.to_xml
        expect(xml).to include('<simpleType name="CustomCodeType">')
        expect(xml).to include('<union memberTypes="test:CustomCodeEnumerationType test:CustomCodeOtherType"/>')
        expect(xml).to include('<simpleType name="CustomCodeOtherType">')
        expect(xml).to include('<pattern value="other: \\w{2,}"/>')
      end
    end
  end

  describe "Integration between processors" do
    let(:enum_processor) do
      Lutaml::Klin::Shapechange::RuleProcessors::EnumerationProcessor.new(rule_checker, config)
    end

    let(:codelist_processor) do
      Lutaml::Klin::Shapechange::RuleProcessors::CodeListProcessor.new(rule_checker, config)
    end

    it "can process both enumerations and code lists in the same document" do
      enum_class = double(
        "Enum",
        name: "Status",
        category: 5,
        values: [double("V1", name: "active", value: "active")]
      )

      codelist_class = double(
        "CodeList",
        name: "Usage",
        category: 4,
        values: [double("C1", name: "residential", value: "residential")]
      )

      allow(rule_checker).to receive(:applies?)
        .with("rule-xsd-cls-enum-object-element", enum_class)
        .and_return(true)

      allow(rule_checker).to receive(:applies?)
        .with("rule-xsd-cls-codelist-constraints", codelist_class)
        .and_return(true)

      context = {
        xsd_document: xsd_doc,
        prefix: "test",
        config: config
      }

      # Process enumeration
      enum_processor.process(enum_class, context.merge(uml_class: enum_class))

      # Process code list
      codelist_processor.process(codelist_class, context.merge(uml_class: codelist_class))

      xml = xsd_doc.to_xml

      # Both should be in the same document
      expect(xml).to include('<simpleType name="StatusType">')
      expect(xml).to include('<simpleType name="UsageCodeType">')
      expect(xml).to include('<union memberTypes="test:UsageCodeEnumerationType test:UsageCodeOtherType"/>')
    end
  end
end