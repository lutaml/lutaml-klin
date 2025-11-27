# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/constraining_facets_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::ConstrainingFacetsProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe "#process" do
    let(:xsd_doc) { double("XsdDocument") }
    let(:model) { double("Model") }
    let(:property_element) { double("PropertyElement") }
    let(:context) do
      {
        xsd_document: xsd_doc,
        property_element: property_element,
        model: model
      }
    end

    before do
      allow(rule_checker).to receive(:applies?).and_return(true)
      allow(property_element).to receive(:has_attribute?).with("type")
                                                         .and_return(false)
      allow(property_element).to receive(:append_child)
      allow(model).to receive(:class_by_id).and_return(nil)
      allow(model).to receive(:class_by_name).and_return(nil)
    end

    context "when property has length constraint on string type" do
      let(:type_info) { double("TypeInfo", name: "CharacterString") }
      let(:property) do
        double("Property").tap do |p|
          allow(p).to receive(:respond_to?).with(:category_of_value)
                                           .and_return(false)
          allow(p).to receive(:respond_to?).with(:type_info).and_return(true)
          allow(p).to receive(:respond_to?).with(:tagged_value)
                                           .and_return(true)
          allow(p).to receive(:type_info).and_return(type_info)
          allow(p).to receive(:tagged_value).with("length").and_return("255")
          allow(p).to receive(:tagged_value).with("maxLength").and_return(nil)
          allow(p).to receive(:tagged_value).with("size").and_return(nil)
          allow(p).to receive(:tagged_value).with("pattern").and_return(nil)
          allow(p).to receive(:tagged_value).with("rangeMinimum")
                                            .and_return(nil)
          allow(p).to receive(:tagged_value).with("rangeMaximum")
                                            .and_return(nil)
        end
      end

      it "adds maxLength facet" do
        simple_type = double("SimpleType")
        restriction = double("Restriction")
        facet = double("Facet")

        allow(xsd_doc).to receive(:create_element).with("simpleType")
                                                  .and_return(simple_type)
        allow(xsd_doc).to receive(:create_element).with("restriction")
                                                  .and_return(restriction)
        allow(xsd_doc).to receive(:create_element).with("maxLength")
                                                  .and_return(facet)
        allow(xsd_doc).to receive(:add_attribute)
        allow(simple_type).to receive(:append_child)
        allow(restriction).to receive(:append_child)

        expect(processor.process(property, context)).to be true

        expect(xsd_doc).to have_received(:add_attribute)
          .with(restriction, "base", "string")
        expect(xsd_doc).to have_received(:add_attribute)
          .with(facet, "value", "255")
      end
    end

    context "when property has range constraints on integer type" do
      let(:type_info) { double("TypeInfo", name: "Integer") }
      let(:property) do
        double("Property").tap do |p|
          allow(p).to receive(:respond_to?).with(:category_of_value)
                                           .and_return(false)
          allow(p).to receive(:respond_to?).with(:type_info).and_return(true)
          allow(p).to receive(:respond_to?).with(:tagged_value)
                                           .and_return(true)
          allow(p).to receive(:type_info).and_return(type_info)
          allow(p).to receive(:tagged_value).with("length").and_return(nil)
          allow(p).to receive(:tagged_value).with("maxLength").and_return(nil)
          allow(p).to receive(:tagged_value).with("size").and_return(nil)
          allow(p).to receive(:tagged_value).with("pattern").and_return(nil)
          allow(p).to receive(:tagged_value).with("rangeMinimum")
                                            .and_return("1")
          allow(p).to receive(:tagged_value).with("rangeMaximum")
                                            .and_return("100")
        end
      end

      it "adds minInclusive and maxInclusive facets" do
        simple_type = double("SimpleType")
        restriction = double("Restriction")
        min_facet = double("MinFacet")
        max_facet = double("MaxFacet")

        allow(xsd_doc).to receive(:create_element).with("simpleType")
                                                  .and_return(simple_type)
        allow(xsd_doc).to receive(:create_element).with("restriction")
                                                  .and_return(restriction)
        allow(xsd_doc).to receive(:create_element).with("minInclusive")
                                                  .and_return(min_facet)
        allow(xsd_doc).to receive(:create_element).with("maxInclusive")
                                                  .and_return(max_facet)
        allow(xsd_doc).to receive(:add_attribute)
        allow(simple_type).to receive(:append_child)
        allow(restriction).to receive(:append_child)

        expect(processor.process(property, context)).to be true

        expect(xsd_doc).to have_received(:add_attribute)
          .with(restriction, "base", "integer")
        expect(xsd_doc).to have_received(:add_attribute)
          .with(min_facet, "value", "1")
        expect(xsd_doc).to have_received(:add_attribute)
          .with(max_facet, "value", "100")
      end
    end

    context "when property has pattern constraint" do
      let(:type_info) { double("TypeInfo", name: "CharacterString") }
      let(:property) do
        double("Property").tap do |p|
          allow(p).to receive(:respond_to?).with(:category_of_value)
                                           .and_return(false)
          allow(p).to receive(:respond_to?).with(:type_info).and_return(true)
          allow(p).to receive(:respond_to?).with(:tagged_value)
                                           .and_return(true)
          allow(p).to receive(:type_info).and_return(type_info)
          allow(p).to receive(:tagged_value).with("length").and_return(nil)
          allow(p).to receive(:tagged_value).with("maxLength").and_return(nil)
          allow(p).to receive(:tagged_value).with("size").and_return(nil)
          allow(p).to receive(:tagged_value).with("pattern")
                                            .and_return("[A-Z]{3}")
          allow(p).to receive(:tagged_value).with("rangeMinimum")
                                            .and_return(nil)
          allow(p).to receive(:tagged_value).with("rangeMaximum")
                                            .and_return(nil)
        end
      end

      it "adds pattern facet" do
        simple_type = double("SimpleType")
        restriction = double("Restriction")
        facet = double("Facet")

        allow(xsd_doc).to receive(:create_element).with("simpleType")
                                                  .and_return(simple_type)
        allow(xsd_doc).to receive(:create_element).with("restriction")
                                                  .and_return(restriction)
        allow(xsd_doc).to receive(:create_element).with("pattern")
                                                  .and_return(facet)
        allow(xsd_doc).to receive(:add_attribute)
        allow(simple_type).to receive(:append_child)
        allow(restriction).to receive(:append_child)

        expect(processor.process(property, context)).to be true

        expect(xsd_doc).to have_received(:add_attribute)
          .with(facet, "value", "[A-Z]{3}")
      end
    end

    context "when property is a codelist" do
      let(:property) do
        double("Property").tap do |p|
          allow(p).to receive(:respond_to?).with(:category_of_value)
                                           .and_return(true)
          allow(p).to receive(:category_of_value).and_return(:codelist)
        end
      end

      it "does not add restrictions" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(processor.process(property, context)).to be true
      end
    end

    context "when property has no constraints" do
      let(:property) do
        double("Property").tap do |p|
          allow(p).to receive(:respond_to?).with(:category_of_value)
                                           .and_return(false)
          allow(p).to receive(:respond_to?).with(:type_info).and_return(true)
          allow(p).to receive(:respond_to?).with(:tagged_value)
                                           .and_return(true)
          allow(p).to receive(:tagged_value).and_return(nil)
        end
      end

      it "does not add restrictions" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(processor.process(property, context)).to be true
      end
    end

    context "when rule does not apply" do
      let(:property) { double("Property") }

      before do
        allow(rule_checker).to receive(:applies?).and_return(false)
      end

      it "returns false" do
        expect(processor.process(property, context)).to be false
      end
    end
  end

  describe "facet support detection" do
    let(:processor) { described_class.new(rule_checker, config) }

    it "recognizes totalDigits support for integer types" do
      expect(processor.send(:facet_supported?, "totalDigits",
                            "integer")).to be true
      expect(processor.send(:facet_supported?, "totalDigits",
                            "decimal")).to be true
      expect(processor.send(:facet_supported?, "totalDigits",
                            "string")).to be false
    end

    it "recognizes maxLength support for string types" do
      expect(processor.send(:facet_supported?, "maxLength",
                            "string")).to be true
      expect(processor.send(:facet_supported?, "maxLength",
                            "token")).to be true
      expect(processor.send(:facet_supported?, "maxLength",
                            "integer")).to be false
    end

    it "recognizes pattern support for all types" do
      expect(processor.send(:facet_supported?, "pattern",
                            "string")).to be true
      expect(processor.send(:facet_supported?, "pattern",
                            "integer")).to be true
      expect(processor.send(:facet_supported?, "pattern",
                            "boolean")).to be true
    end

    it "recognizes range support for numeric and date types" do
      expect(processor.send(:facet_supported?, "minInclusive",
                            "integer")).to be true
      expect(processor.send(:facet_supported?, "maxInclusive",
                            "decimal")).to be true
      expect(processor.send(:facet_supported?, "minInclusive",
                            "dateTime")).to be true
      expect(processor.send(:facet_supported?, "maxInclusive",
                            "string")).to be false
    end
  end
end
