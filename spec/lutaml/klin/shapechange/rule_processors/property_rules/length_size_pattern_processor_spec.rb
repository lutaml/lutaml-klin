# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/length_size_pattern_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::LengthSizePatternProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe "#process" do
    let(:xsd_doc) { double("XsdDocument") }
    let(:property_element) { double("PropertyElement") }
    let(:context) do
      {
        xsd_document: xsd_doc,
        property_element: property_element
      }
    end

    context "when property has length constraint" do
      let(:property) do
        double("Property", respond_to?: true).tap do |p|
          allow(p).to receive(:tagged_value).with("length").and_return("255")
          allow(p).to receive(:tagged_value).with("size").and_return(nil)
          allow(p).to receive(:tagged_value).with("pattern").and_return(nil)
        end
      end

      before do
        allow(rule_checker).to receive(:applies?).and_return(true)
        allow(property_element).to receive(:has_attribute?).with("type")
                                                           .and_return(true)
        allow(property_element).to receive(:remove_attribute).with("type")
        allow(property_element).to receive(:append_child)
      end

      it "adds maxLength restriction" do
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
        expect(property_element).to have_received(:remove_attribute)
          .with("type")
      end
    end

    context "when property has both size and pattern constraints" do
      let(:property) do
        double("Property", respond_to?: true).tap do |p|
          allow(p).to receive(:tagged_value).with("length").and_return(nil)
          allow(p).to receive(:tagged_value).with("size").and_return("10")
          allow(p).to receive(:tagged_value).with("pattern").and_return('\d')
        end
      end

      before do
        allow(rule_checker).to receive(:applies?).and_return(true)
        allow(property_element).to receive(:has_attribute?).with("type")
                                                           .and_return(false)
        allow(property_element).to receive(:append_child)
      end

      it "adds pattern restriction with size repetition" do
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
          .with(restriction, "base", "string")
        expect(xsd_doc).to have_received(:add_attribute)
          .with(facet, "value", '\d{10}')
      end
    end

    context "when property has no constraints" do
      let(:property) do
        double("Property", respond_to?: true).tap do |p|
          allow(p).to receive(:tagged_value).with("length").and_return(nil)
          allow(p).to receive(:tagged_value).with("size").and_return(nil)
          allow(p).to receive(:tagged_value).with("pattern").and_return(nil)
        end
      end

      before do
        allow(rule_checker).to receive(:applies?).and_return(true)
      end

      it "does not add restrictions" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(processor.process(property, context)).to be true
      end
    end

    context "when property has only size (no pattern)" do
      let(:property) do
        double("Property", respond_to?: true).tap do |p|
          allow(p).to receive(:tagged_value).with("length").and_return(nil)
          allow(p).to receive(:tagged_value).with("size").and_return("8")
          allow(p).to receive(:tagged_value).with("pattern").and_return(nil)
        end
      end

      before do
        allow(rule_checker).to receive(:applies?).and_return(true)
      end

      it "does not add restrictions" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(processor.process(property, context)).to be true
      end
    end

    context "when property has only pattern (no size)" do
      let(:property) do
        double("Property", respond_to?: true).tap do |p|
          allow(p).to receive(:tagged_value).with("length").and_return(nil)
          allow(p).to receive(:tagged_value).with("size").and_return(nil)
          allow(p).to receive(:tagged_value).with("pattern")
                                            .and_return("[A-Z]+")
        end
      end

      before do
        allow(rule_checker).to receive(:applies?).and_return(true)
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

    context "when property has empty string constraints" do
      let(:property) do
        double("Property", respond_to?: true).tap do |p|
          allow(p).to receive(:tagged_value).with("length").and_return("  ")
          allow(p).to receive(:tagged_value).with("size").and_return("")
          allow(p).to receive(:tagged_value).with("pattern").and_return(nil)
        end
      end

      before do
        allow(rule_checker).to receive(:applies?).and_return(true)
      end

      it "treats empty strings as nil and does not add restrictions" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(processor.process(property, context)).to be true
      end
    end
  end
end
