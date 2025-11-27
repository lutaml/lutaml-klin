# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/xsd_as_attribute_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::XsdAsAttributeProcessor do
  let(:rule_checker) { instance_double("RuleChecker") }
  let(:config) { instance_double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe ".rule_name" do
    it "returns the correct rule name" do
      expect(described_class.rule_name).to eq("rule-xsd-prop-xsdAsAttribute")
    end
  end

  describe "#process" do
    context "when xsdAsAttribute is true and maxOccurs is 1" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 1, max_occurs: 1)
      end

      let(:property) do
        double(
          "Property",
          name: "unit",
          tagged_value: "true",
          cardinality: cardinality,
          matches?: true
        )
      end

      let(:context) { { in_association_class: false } }

      it "encodes as attribute" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
      end

      it "marks as required" do
        result = processor.process(property, context)

        expect(result[:result][:use_required]).to be true
      end

      it "provides descriptive message" do
        result = processor.process(property, context)

        expect(result[:message]).to include("XML attribute")
      end
    end

    context "when xsdAsAttribute is true but maxOccurs > 1" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 0, max_occurs: 5)
      end

      let(:property) do
        double(
          "Property",
          name: "codes",
          cardinality: cardinality,
          matches?: false
        )
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:respond_to?).with(:cardinality).and_return(true)
        allow(property).to receive(:respond_to?).with(:matches?).and_return(true)
        allow(property).to receive(:tagged_value).with("xsdAsAttribute").and_return("true")
        allow(property).to receive(:tagged_value).with("asXMLAttribute").and_return(nil)
      end

      it "does not encode as attribute" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be false
      end

      it "explains multiplicity constraint" do
        result = processor.process(property, context)

        expect(result[:message]).to include("multiplicity constraint")
      end
    end

    context "when xsdAsAttribute is true in association class" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 1, max_occurs: 1)
      end

      let(:property) do
        double(
          "Property",
          name: "attr",
          tagged_value: "true",
          cardinality: cardinality,
          matches?: true
        )
      end

      let(:context) { { in_association_class: true } }

      it "does not encode as attribute" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be false
      end

      it "explains association class constraint" do
        result = processor.process(property, context)

        expect(result[:message]).to include("association class")
      end
    end

    context "when xsdAsAttribute is false" do
      let(:property) do
        double(
          "Property",
          name: "normal",
          tagged_value: "false"
        )
      end

      let(:context) { {} }

      it "encodes as element" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be false
      end
    end

    context "when xsdAsAttribute is not set" do
      let(:property) do
        double("Property", name: "prop")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:tagged_value).with("xsdAsAttribute").and_return(nil)
        allow(property).to receive(:tagged_value).with("asXMLAttribute").and_return(nil)
      end

      it "encodes as element" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be false
      end
    end

    context "when using asXMLAttribute alternative" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 0, max_occurs: 1)
      end

      let(:property) do
        double(
          "Property",
          name: "legacy",
          cardinality: cardinality,
          matches?: true
        )
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:respond_to?).with(:cardinality).and_return(true)
        allow(property).to receive(:tagged_value).with("xsdAsAttribute").and_return(nil)
        allow(property).to receive(:tagged_value).with("asXMLAttribute").and_return("true")
      end

      it "uses alternative tagged value name" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
      end
    end

    context "when property is optional (minOccurs=0)" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 0, max_occurs: 1)
      end

      let(:property) do
        double(
          "Property",
          name: "optional_attr",
          tagged_value: "true",
          cardinality: cardinality,
          matches?: true
        )
      end

      let(:context) { {} }

      it "does not set use=required" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
        expect(result[:result][:use_required]).to be false
      end
    end

    context "when xsdAsAttribute is 'TRUE' (uppercase)" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 1, max_occurs: 1)
      end

      let(:property) do
        double(
          "Property",
          name: "attr",
          tagged_value: "TRUE",
          cardinality: cardinality,
          matches?: true
        )
      end

      let(:context) { {} }

      it "handles case-insensitive value" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
      end
    end

    context "when xsdAsAttribute is 'True' (mixed case)" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 1, max_occurs: 1)
      end

      let(:property) do
        double(
          "Property",
          name: "attr",
          tagged_value: "True",
          cardinality: cardinality,
          matches?: true
        )
      end

      let(:context) { {} }

      it "handles mixed case" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
      end
    end

    context "when property allows list encoding" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 0, max_occurs: 10)
      end

      let(:property) do
        double(
          "Property",
          name: "list_attr",
          cardinality: cardinality
        )
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:respond_to?).with(:cardinality).and_return(true)
        allow(property).to receive(:tagged_value).with("xsdAsAttribute").and_return("true")
        allow(property).to receive(:tagged_value).with("asXMLAttribute").and_return(nil)
        allow(property).to receive(:tagged_value).with("gmlListProperty").and_return("true")
        allow(property).to receive(:respond_to?).with(:matches?).and_return(true)
        allow(property).to receive(:matches?).with("rule-xsd-prop-gmlListProperty").and_return(true)
      end

      it "allows attribute encoding with list" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
      end
    end

    context "when cardinality method is missing" do
      let(:property) do
        double("Property", name: "prop")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:cardinality).and_return(false)
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:tagged_value).with("xsdAsAttribute").and_return("true")
        allow(property).to receive(:tagged_value).with("asXMLAttribute").and_return(nil)
      end

      it "assumes valid multiplicity" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
      end
    end

    context "when cardinality uses alternative method names" do
      let(:cardinality) do
        double("Cardinality")
      end

      let(:property) do
        double(
          "Property",
          name: "attr",
          cardinality: cardinality,
          matches?: true
        )
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:respond_to?).with(:cardinality).and_return(true)
        allow(property).to receive(:tagged_value).with("xsdAsAttribute").and_return("true")
        allow(property).to receive(:tagged_value).with("asXMLAttribute").and_return(nil)
        allow(cardinality).to receive(:respond_to?).with(:min_occurs).and_return(false)
        allow(cardinality).to receive(:respond_to?).with(:minOccurs).and_return(true)
        allow(cardinality).to receive(:minOccurs).and_return(1)
        allow(cardinality).to receive(:respond_to?).with(:max_occurs).and_return(false)
        allow(cardinality).to receive(:respond_to?).with(:maxOccurs).and_return(true)
        allow(cardinality).to receive(:maxOccurs).and_return(1)
      end

      it "handles alternative cardinality method names" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
        expect(result[:result][:use_required]).to be true
      end
    end

    context "when tagged_value raises exception" do
      let(:property) do
        double("Property", name: "prop")
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:tagged_value).and_raise(StandardError)
      end

      it "handles exceptions gracefully" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be false
      end
    end

    context "when xsdAsAttribute has whitespace" do
      let(:cardinality) do
        double("Cardinality", min_occurs: 1, max_occurs: 1)
      end

      let(:property) do
        double(
          "Property",
          name: "attr",
          cardinality: cardinality,
          matches?: true
        )
      end

      let(:context) { {} }

      before do
        allow(property).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(property).to receive(:respond_to?).with(:cardinality).and_return(true)
        allow(property).to receive(:tagged_value).with("xsdAsAttribute").and_return("  true  ")
        allow(property).to receive(:tagged_value).with("asXMLAttribute").and_return(nil)
      end

      it "strips whitespace" do
        result = processor.process(property, context)

        expect(result[:result][:encode_as_attribute]).to be true
      end
    end
  end

  describe "edge cases" do
    let(:context) { {} }

    it "handles maxOccurs = Integer::MAX_VALUE" do
      cardinality = double("Cardinality", min_occurs: 0,
                                          max_occurs: 2_147_483_647)
      prop = double("Property", cardinality: cardinality, matches?: false)
      allow(prop).to receive(:respond_to?).with(:tagged_value).and_return(true)
      allow(prop).to receive(:respond_to?).with(:cardinality).and_return(true)
      allow(prop).to receive(:respond_to?).with(:matches?).and_return(true)
      allow(prop).to receive(:tagged_value).with("xsdAsAttribute").and_return("true")
      allow(prop).to receive(:tagged_value).with("asXMLAttribute").and_return(nil)

      result = processor.process(prop, context)
      expect(result[:result][:encode_as_attribute]).to be false
    end

    it "handles empty tagged value" do
      prop = double("Property", name: "prop")
      allow(prop).to receive(:respond_to?).with(:tagged_value).and_return(true)
      allow(prop).to receive(:tagged_value).with("xsdAsAttribute").and_return("")
      allow(prop).to receive(:tagged_value).with("asXMLAttribute").and_return(nil)

      result = processor.process(prop, context)
      expect(result[:result][:encode_as_attribute]).to be false
    end

    it "handles nil tagged value" do
      prop = double("Property", name: "prop")
      allow(prop).to receive(:respond_to?).with(:tagged_value).and_return(true)
      allow(prop).to receive(:tagged_value).and_return(nil)

      result = processor.process(prop, context)
      expect(result[:result][:encode_as_attribute]).to be false
    end
  end

  describe "message generation" do
    let(:cardinality) { double("Cardinality", min_occurs: 1, max_occurs: 1) }

    it "provides attribute message when encoding as attribute" do
      prop = double("Property", name: "attr", tagged_value: "true",
                                cardinality: cardinality, matches?: true)
      result = processor.process(prop, {})
      expect(result[:message]).to include("XML attribute")
    end

    it "provides element message when not encoding as attribute" do
      prop = double("Property", name: "elem", tagged_value: "false",
                                cardinality: cardinality)
      result = processor.process(prop, {})
      expect(result[:message]).to include("XML element")
    end

    it "explains association class constraint" do
      prop = double("Property", name: "attr", tagged_value: "true",
                                cardinality: cardinality, matches?: true)
      result = processor.process(prop, { in_association_class: true })
      expect(result[:message]).to include("association class")
    end
  end

  describe "context handling" do
    let(:cardinality) { double("Cardinality", min_occurs: 1, max_occurs: 1) }
    let(:property) do
      double("Property", name: "attr", tagged_value: "true",
                         cardinality: cardinality, matches?: true)
    end

    it "handles missing context" do
      result = processor.process(property, nil)
      expect(result[:result][:encode_as_attribute]).to be true
    end

    it "handles empty context" do
      result = processor.process(property, {})
      expect(result[:result][:encode_as_attribute]).to be true
    end

    it "handles in_association_class explicitly false" do
      result = processor.process(property, { in_association_class: false })
      expect(result[:result][:encode_as_attribute]).to be true
    end

    it "handles in_association_class explicitly true" do
      result = processor.process(property, { in_association_class: true })
      expect(result[:result][:encode_as_attribute]).to be false
    end
  end
end
