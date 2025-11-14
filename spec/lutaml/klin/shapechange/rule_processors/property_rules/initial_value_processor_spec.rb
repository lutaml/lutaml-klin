# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/initial_value_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::InitialValueProcessor do
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
    context "when processing property with default value (non-readonly)" do
      let(:property) do
        double(
          "Property",
          name: "floors",
          respond_to?: ->(method) { [:initial_value, :read_only?].include?(method) },
          initial_value: "1",
          read_only?: false
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-initialValue", property)
          .and_return(true)
      end

      it "adds default attribute" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(property_element, "default", "1")

        processor.process(property, context)
      end
    end

    context "when processing property with fixed value (readonly)" do
      let(:property) do
        double(
          "Property",
          name: "pi",
          respond_to?: ->(method) { [:initial_value, :read_only?].include?(method) },
          initial_value: "3.14159",
          read_only?: true
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-initialValue", property)
          .and_return(true)
      end

      it "adds fixed attribute" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(property_element, "fixed", "3.14159")

        processor.process(property, context)
      end
    end

    context "when processing property with quoted string value" do
      let(:property) do
        double(
          "Property",
          name: "status",
          respond_to?: ->(method) { [:initial_value, :read_only?].include?(method) },
          initial_value: '"active"',
          read_only?: false
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-initialValue", property)
          .and_return(true)
      end

      it "strips quotes and adds default attribute" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(property_element, "default", "active")

        processor.process(property, context)
      end
    end

    context "when processing property without initial value" do
      let(:property) do
        double(
          "Property",
          name: "name",
          respond_to?: ->(method) { [:initial_value].include?(method) },
          initial_value: nil
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-initialValue", property)
          .and_return(true)
      end

      it "does not add default or fixed attribute" do
        expect(xsd_doc).not_to receive(:add_attribute)

        processor.process(property, context)
      end
    end

    context "when processing property with empty initial value" do
      let(:property) do
        double(
          "Property",
          name: "description",
          respond_to?: ->(method) { [:initial_value].include?(method) },
          initial_value: ""
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-initialValue", property)
          .and_return(true)
      end

      it "does not add default or fixed attribute" do
        expect(xsd_doc).not_to receive(:add_attribute)

        processor.process(property, context)
      end
    end

    context "when property element is not available" do
      let(:property) do
        double(
          "Property",
          name: "test",
          respond_to?: ->(method) { [:initial_value, :read_only?].include?(method) },
          initial_value: "value",
          read_only?: false
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
          .with("rule-xsd-prop-initialValue", property)
          .and_return(true)
      end

      it "does not add attribute" do
        expect(xsd_doc).not_to receive(:add_attribute)

        processor.process(property, context_without_element)
      end
    end

    context "when processing boolean initial value" do
      let(:property) do
        double(
          "Property",
          name: "enabled",
          respond_to?: ->(method) { [:initial_value, :read_only?].include?(method) },
          initial_value: "true",
          read_only?: false
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-initialValue", property)
          .and_return(true)
      end

      it "adds default attribute with boolean value" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(property_element, "default", "true")

        processor.process(property, context)
      end
    end
  end
end