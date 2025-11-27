# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/nillable_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::NillableProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { {} }
  let(:processor) { described_class.new(rule_checker, config) }
  let(:xsd_doc) { double("XsdDocument") }
  let(:property_element) { double("PropertyElement") }
  let(:context) do
    {
      xsd_document: xsd_doc,
      property_element: property_element,
      config: config
    }
  end

  describe "#process" do
    context "when processing a voidable property" do
      let(:property) do
        double(
          "Property",
          name: "height",
          respond_to?: lambda do |method|
            %i[voidable? voidable nil_reason_allowed?
               nilReasonAllowed].include?(method)
          end,
          voidable?: true,
          nil_reason_allowed?: false
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-nillable", property)
          .and_return(true)
      end

      it "adds nillable='true' attribute" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(property_element, "nillable", "true")

        processor.process(property, context)
      end
    end

    context "when processing a non-voidable property" do
      let(:property) do
        double(
          "Property",
          name: "name",
          respond_to?: lambda do |method|
            %i[voidable? voidable nil_reason_allowed?
               nilReasonAllowed].include?(method)
          end,
          voidable?: false,
          nil_reason_allowed?: false
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-nillable", property)
          .and_return(true)
      end

      it "does not add nillable attribute" do
        expect(xsd_doc).not_to receive(:add_attribute)

        processor.process(property, context)
      end
    end

    context "when processing a property with nilReasonAllowed" do
      let(:property) do
        double(
          "Property",
          name: "description",
          respond_to?: lambda do |method|
            %i[voidable? voidable nil_reason_allowed?
               nilReasonAllowed].include?(method)
          end,
          voidable?: false,
          nil_reason_allowed?: true
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-nillable", property)
          .and_return(true)
      end

      it "adds nillable='true' attribute" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(property_element, "nillable", "true")

        processor.process(property, context)
      end
    end

    context "when processing property without voidable method" do
      let(:property) { double("Property", name: "code") }

      before do
        allow(property).to receive(:respond_to?).with(:voidable?).and_return(false)
        allow(property).to receive(:respond_to?).with(:voidable).and_return(false)
        allow(property).to receive(:respond_to?).with(:nil_reason_allowed?).and_return(false)
        allow(property).to receive(:respond_to?).with(:nilReasonAllowed).and_return(false)

        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-nillable", property)
          .and_return(true)
      end

      it "does not add nillable attribute" do
        expect(xsd_doc).not_to receive(:add_attribute)

        processor.process(property, context)
      end
    end

    context "when property element is not available" do
      let(:property) do
        double(
          "Property",
          name: "test",
          respond_to?: ->(method) { [:voidable?].include?(method) },
          voidable?: true
        )
      end
      let(:context_without_element) do
        {
          xsd_document: xsd_doc,
          config: config
        }
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-nillable", property)
          .and_return(true)
      end

      it "does not add nillable attribute" do
        expect(xsd_doc).not_to receive(:add_attribute)

        processor.process(property, context_without_element)
      end
    end

    context "when using voidable method instead of voidable?" do
      let(:property) { double("Property", name: "measure") }

      before do
        # Only voidable (not voidable?) is available
        allow(property).to receive(:respond_to?).with(:voidable?).and_return(false)
        allow(property).to receive(:respond_to?).with(:voidable).and_return(true)
        allow(property).to receive(:respond_to?).with(:nil_reason_allowed?).and_return(false)
        allow(property).to receive(:respond_to?).with(:nilReasonAllowed).and_return(false)
        allow(property).to receive(:voidable).and_return(true)

        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-nillable", property)
          .and_return(true)
      end

      it "adds nillable='true' attribute" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(property_element, "nillable", "true")

        processor.process(property, context)
      end
    end
  end
end
