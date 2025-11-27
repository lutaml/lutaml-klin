# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::InlineOrByReferenceProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { {} }
  let(:processor) { described_class.new(rule_checker, config) }
  let(:xsd_doc) { double("XsdDocument") }
  let(:context) do
    {
      xsd_document: xsd_doc,
      gml_namespace: "http://www.opengis.net/gml/3.2",
      config: config
    }
  end

  describe "#process" do
    context "when processing property with by-reference encoding" do
      let(:property) do
        double(
          "Property",
          name: "capital",
          respond_to?: lambda { |method|
            [:inline_or_by_reference].include?(method)
          },
          inline_or_by_reference: "byreference"
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-inlineOrByReference", property)
          .and_return(true)
      end

      it "sets encoding mode to byreference and embed_property_type to true" do
        processor.process(property, context)

        expect(context[:encoding_mode]).to eq("byreference")
        expect(context[:embed_property_type]).to be true
      end
    end

    context "when processing property with inline encoding" do
      let(:property) do
        double(
          "Property",
          name: "location",
          respond_to?: lambda do |method|
            %i[inline_or_by_reference nil_reason_allowed?
               voidable? aggregation? composition?
               metadata? qualifiers property_metadata? tags type].include?(method)
          end,
          inline_or_by_reference: "inline",
          nil_reason_allowed?: false,
          voidable?: false,
          aggregation?: false,
          composition?: false,
          metadata?: false,
          qualifiers: nil,
          property_metadata?: false,
          tags: [],
          type: nil
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-inlineOrByReference", property)
          .and_return(true)
      end

      it "sets encoding mode to inline" do
        processor.process(property, context)

        expect(context[:encoding_mode]).to eq("inline")
      end
    end

    context "when processing property with standard encoding" do
      let(:property) do
        double(
          "Property",
          name: "admin",
          respond_to?: lambda do |method|
            %i[inline_or_by_reference nil_reason_allowed?
               voidable? aggregation? composition?
               metadata? qualifiers property_metadata? tags type].include?(method)
          end,
          inline_or_by_reference: nil,
          nil_reason_allowed?: false,
          voidable?: false,
          aggregation?: false,
          composition?: false,
          metadata?: false,
          qualifiers: nil,
          property_metadata?: false,
          tags: [],
          type: nil
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-inlineOrByReference", property)
          .and_return(true)
      end

      it "sets encoding mode to standard" do
        processor.process(property, context)

        expect(context[:encoding_mode]).to eq("standard")
      end
    end

    context "when processing inline property with nilReason" do
      let(:property) do
        double(
          "Property",
          name: "description",
          respond_to?: lambda do |method|
            %i[inline_or_by_reference nil_reason_allowed?
               voidable? aggregation? composition?
               metadata? qualifiers property_metadata? tags type].include?(method)
          end,
          inline_or_by_reference: "inline",
          nil_reason_allowed?: true,
          voidable?: false,
          aggregation?: false,
          composition?: false,
          metadata?: false,
          qualifiers: nil,
          property_metadata?: false,
          tags: [],
          type: nil
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-inlineOrByReference", property)
          .and_return(true)
      end

      it "sets embed_property_type to true" do
        processor.process(property, context)

        expect(context[:encoding_mode]).to eq("inline")
        expect(context[:embed_property_type]).to be true
      end
    end

    context "when processing inline aggregation in GML 3.2" do
      let(:type_info) do
        double("TypeInfo", id: "feature-123", name: "Building")
      end
      let(:value_class) do
        double(
          "ValueClass",
          respond_to?: lambda do |method|
            %i[category include_by_value_property_type?
               include_property_type?].include?(method)
          end,
          category: "FEATURE",
          include_by_value_property_type?: false,
          include_property_type?: true
        )
      end
      let(:model) { double("Model") }
      let(:property) do
        double(
          "Property",
          name: "buildings",
          respond_to?: lambda do |method|
            %i[inline_or_by_reference nil_reason_allowed?
               voidable? aggregation? composition?
               metadata? qualifiers property_metadata?
               tags type].include?(method)
          end,
          inline_or_by_reference: "inline",
          nil_reason_allowed?: false,
          voidable?: false,
          aggregation?: true,
          composition?: false,
          metadata?: false,
          qualifiers: nil,
          property_metadata?: false,
          tags: [],
          type: type_info
        )
      end
      let(:context_with_model) do
        {
          xsd_document: xsd_doc,
          gml_namespace: "http://www.opengis.net/gml/3.2",
          model: model,
          config: config
        }
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-inlineOrByReference", property)
          .and_return(true)
        allow(model).to receive(:class_by_id).with("feature-123").and_return(value_class)
        allow(model).to receive(:class_by_name).with("Building").and_return(value_class)
      end

      it "sets embed_property_type to true for GML 3.2 aggregation" do
        processor.process(property, context_with_model)

        expect(context_with_model[:encoding_mode]).to eq("inline")
        expect(context_with_model[:embed_property_type]).to be true
      end
    end

    context "when processing property with qualifiers" do
      let(:qualifier) { double("Qualifier", name: "uom", type: "String") }
      let(:property) do
        double(
          "Property",
          name: "measurement",
          respond_to?: lambda do |method|
            %i[inline_or_by_reference nil_reason_allowed?
               voidable? aggregation? composition?
               metadata? qualifiers property_metadata? tags type].include?(method)
          end,
          inline_or_by_reference: "inline",
          nil_reason_allowed?: false,
          voidable?: false,
          aggregation?: false,
          composition?: false,
          metadata?: false,
          qualifiers: [qualifier],
          property_metadata?: false,
          tags: [],
          type: nil
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-inlineOrByReference", property)
          .and_return(true)
      end

      it "sets embed_property_type to true" do
        processor.process(property, context)

        expect(context[:encoding_mode]).to eq("inline")
        expect(context[:embed_property_type]).to be true
      end
    end
  end
end
