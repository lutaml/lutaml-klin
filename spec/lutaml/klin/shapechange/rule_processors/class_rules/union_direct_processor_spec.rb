# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/union_direct_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::UnionDirectProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe "#process" do
    let(:xsd_doc) { double("XsdDocument") }
    let(:property_element) { double("PropertyElement") }
    let(:context) do
      {
        xsd_document: xsd_doc,
        property_element: property_element,
        current_property: nil # Will be set in each test
      }
    end

    before do
      allow(rule_checker).to receive(:applies?).and_return(true)
      allow(xsd_doc).to receive(:add_attribute)
    end

    context "when union has single navigable property" do
      let(:type_info) { double("TypeInfo", name: "Measure") }
      let(:union_property) do
        double("UnionProperty").tap do |p|
          allow(p).to receive(:respond_to?).with(:navigable?)
                                           .and_return(true)
          allow(p).to receive(:navigable?).and_return(true)
          allow(p).to receive(:respond_to?).with(:is_restriction?)
                                           .and_return(true)
          allow(p).to receive(:is_restriction?).and_return(false)
          allow(p).to receive(:respond_to?).with(:implemented_by_nil_reason?)
                                           .and_return(true)
          allow(p).to receive(:implemented_by_nil_reason?).and_return(false)
          allow(p).to receive(:respond_to?).with(:type_info).and_return(true)
          allow(p).to receive(:type_info).and_return(type_info)
          allow(p).to receive(:respond_to?).with(:cardinality).and_return(true)
          allow(p).to receive(:cardinality)
            .and_return(double(min_occurs: 1, max_occurs: 1))
        end
      end

      let(:nil_property) do
        double("NilProperty").tap do |p|
          allow(p).to receive(:respond_to?).with(:navigable?)
                                           .and_return(true)
          allow(p).to receive(:navigable?).and_return(true)
          allow(p).to receive(:respond_to?).with(:is_restriction?)
                                           .and_return(true)
          allow(p).to receive(:is_restriction?).and_return(false)
          allow(p).to receive(:respond_to?).with(:implemented_by_nil_reason?)
                                           .and_return(true)
          allow(p).to receive(:implemented_by_nil_reason?).and_return(true)
        end
      end

      let(:union_class) do
        double("UnionClass").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:properties).and_return(true)
          allow(c).to receive(:respond_to?).with(:has_nil_reason?).and_return(true)
          allow(c).to receive(:respond_to?).with(:is_union_direct?).and_return(false)
          allow(c).to receive(:respond_to?).with(:isUnionDirect).and_return(false)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:stereotype).with("union").and_return(true)
          allow(c).to receive(:properties)
            .and_return({ "measure" => union_property,
                          "nil" => nil_property })
          allow(c).to receive(:has_nil_reason?).and_return(false)
        end
      end

      let(:property) do
        double("Property").tap do |p|
          allow(p).to receive(:respond_to?).with(:cardinality).and_return(true)
          allow(p).to receive(:cardinality)
            .and_return(double(min_occurs: 1, max_occurs: 1))
        end
      end

      before do
        context[:current_property] = property
      end

      it "sets nillable and maps union property type" do
        expect(processor.process(union_class, context)).to be true

        expect(xsd_doc).to have_received(:add_attribute)
          .with(property_element, "nillable", "true")
        expect(xsd_doc).to have_received(:add_attribute)
          .with(property_element, "type", "MeasureType")
      end
    end

    context "when union has nilReason flag" do
      let(:type_info) { double("TypeInfo", name: "Geometry") }
      let(:union_property) do
        double("UnionProperty").tap do |p|
          allow(p).to receive(:respond_to?).with(:navigable?)
                                           .and_return(true)
          allow(p).to receive(:navigable?).and_return(true)
          allow(p).to receive(:respond_to?).with(:is_restriction?)
                                           .and_return(true)
          allow(p).to receive(:is_restriction?).and_return(false)
          allow(p).to receive(:respond_to?).with(:implemented_by_nil_reason?)
                                           .and_return(true)
          allow(p).to receive(:implemented_by_nil_reason?).and_return(false)
          allow(p).to receive(:respond_to?).with(:type_info).and_return(true)
          allow(p).to receive(:type_info).and_return(type_info)
          allow(p).to receive(:respond_to?).with(:cardinality).and_return(true)
          allow(p).to receive(:cardinality)
            .and_return(double(min_occurs: 1, max_occurs: 1))
          allow(p).to receive(:respond_to?).with(:nil_reason_allowed=)
                                           .and_return(true)
          allow(p).to receive(:nil_reason_allowed=).with(true)
        end
      end

      let(:nil_property) do
        double("NilProperty").tap do |p|
          allow(p).to receive(:respond_to?).with(:navigable?)
                                           .and_return(true)
          allow(p).to receive(:navigable?).and_return(true)
          allow(p).to receive(:respond_to?).with(:is_restriction?)
                                           .and_return(true)
          allow(p).to receive(:is_restriction?).and_return(false)
          allow(p).to receive(:respond_to?).with(:implemented_by_nil_reason?)
                                           .and_return(true)
          allow(p).to receive(:implemented_by_nil_reason?).and_return(true)
        end
      end

      let(:union_class) do
        double("UnionClass").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:properties).and_return(true)
          allow(c).to receive(:respond_to?).with(:has_nil_reason?).and_return(true)
          allow(c).to receive(:respond_to?).with(:is_union_direct?).and_return(false)
          allow(c).to receive(:respond_to?).with(:isUnionDirect).and_return(false)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:stereotype).with("union").and_return(true)
          allow(c).to receive(:properties)
            .and_return({ "geometry" => union_property,
                          "nil" => nil_property })
          allow(c).to receive(:has_nil_reason?).and_return(true)
        end
      end

      let(:property) do
        double("Property").tap do |p|
          allow(p).to receive(:respond_to?).with(:cardinality).and_return(true)
          allow(p).to receive(:cardinality)
            .and_return(double(min_occurs: 1, max_occurs: 1))
        end
      end

      before do
        context[:current_property] = property
      end

      it "propagates nilReason to union property" do
        expect(processor.process(union_class, context)).to be true

        expect(union_property).to have_received(:nil_reason_allowed=)
          .with(true)
      end
    end

    context "when union has all properties as nilReason" do
      let(:nil_property1) do
        double("NilProperty1").tap do |p|
          allow(p).to receive(:respond_to?).with(:navigable?).and_return(true)
          allow(p).to receive(:navigable?).and_return(true)
          allow(p).to receive(:respond_to?).with(:is_restriction?).and_return(true)
          allow(p).to receive(:is_restriction?).and_return(false)
          allow(p).to receive(:respond_to?).with(:implemented_by_nil_reason?)
                                           .and_return(true)
          allow(p).to receive(:implemented_by_nil_reason?).and_return(true)
        end
      end

      let(:nil_property2) do
        double("NilProperty2").tap do |p|
          allow(p).to receive(:respond_to?).with(:navigable?).and_return(true)
          allow(p).to receive(:navigable?).and_return(true)
          allow(p).to receive(:respond_to?).with(:is_restriction?).and_return(true)
          allow(p).to receive(:is_restriction?).and_return(false)
          allow(p).to receive(:respond_to?).with(:implemented_by_nil_reason?)
                                           .and_return(true)
          allow(p).to receive(:implemented_by_nil_reason?).and_return(true)
        end
      end

      let(:union_class) do
        double("UnionClass").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:properties).and_return(true)
          allow(c).to receive(:respond_to?).with(:name).and_return(true)
          allow(c).to receive(:respond_to?).with(:is_union_direct?).and_return(true)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:stereotype).with("union").and_return(true)
          allow(c).to receive(:is_union_direct?).and_return(true)
          allow(c).to receive(:properties)
            .and_return({ "nil1" => nil_property1, "nil2" => nil_property2 })
          allow(c).to receive(:name).and_return("InvalidUnion")
        end
      end

      let(:property) do
        double("Property").tap do |p|
          allow(p).to receive(:respond_to?).with(:name).and_return(true)
          allow(p).to receive(:name).and_return("testProp")
        end
      end

      before do
        context[:current_property] = property
      end

      it "does not process and logs error" do
        expect do
          processor.process(union_class, context)
        end.to output(/Error: Union 'InvalidUnion'/).to_stdout
      end
    end

    context "when not a union class" do
      let(:regular_class) do
        double("RegularClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:stereotype).with("union").and_return(false)
          allow(c).to receive(:respond_to?).with(:category).and_return(true)
          allow(c).to receive(:category).and_return("feature")
        end
      end

      let(:property) { double("Property") }

      before do
        context[:current_property] = property
      end

      it "does not process" do
        expect(processor.process(regular_class, context)).to be true
        expect(xsd_doc).not_to have_received(:add_attribute)
      end
    end

    context "when rule does not apply" do
      let(:union_class) { double("UnionClass") }

      before do
        allow(rule_checker).to receive(:applies?).and_return(false)
      end

      it "returns false" do
        expect(processor.process(union_class, context)).to be false
      end
    end
  end
end
