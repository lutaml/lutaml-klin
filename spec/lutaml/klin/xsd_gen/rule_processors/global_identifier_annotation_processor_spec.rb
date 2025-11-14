# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/xsd_gen/rule_processors/global_identifier_annotation_processor"

RSpec.describe Lutaml::Klin::XsdGen::RuleProcessors::GlobalIdentifierAnnotationProcessor do
  let(:processor) { described_class }
  let(:scai_namespace) { "http://www.interactive-instruments.de/ShapeChange/AppInfo" }
  let(:context) do
    double(
      "Context",
      rule_enabled?: true,
    )
  end

  describe ".applies_to?" do
    context "when rule is enabled" do
      context "with class having global identifier" do
        let(:element) do
          double(
            "Class",
            tagged_value: "urn:example:def:featureType:Building",
          )
        end

        before do
          allow(processor).to receive(:element_is_class_or_property?).and_return(true)
        end

        it "returns true" do
          expect(processor.applies_to?(element, context)).to be true
        end
      end

      context "with property having global identifier" do
        let(:element) do
          double(
            "Property",
            tagged_value: "urn:example:def:propertyType:height",
          )
        end

        before do
          allow(processor).to receive(:element_is_class_or_property?).and_return(true)
        end

        it "returns true" do
          expect(processor.applies_to?(element, context)).to be true
        end
      end

      context "with element having global_identifier property" do
        let(:element) do
          double(
            "Class",
            global_identifier: "urn:inspire:def:featureType:Parcel",
          )
        end

        before do
          allow(processor).to receive(:element_is_class_or_property?).and_return(true)
          allow(element).to receive(:tagged_value).and_return(nil)
          allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
          allow(element).to receive(:respond_to?).with(:global_identifier).and_return(true)
        end

        it "returns true" do
          expect(processor.applies_to?(element, context)).to be true
        end
      end

      context "with empty global identifier" do
        let(:element) do
          double(
            "Class",
            tagged_value: "  ",
          )
        end

        before do
          allow(processor).to receive(:element_is_class_or_property?).and_return(true)
        end

        it "returns false" do
          expect(processor.applies_to?(element, context)).to be false
        end
      end

      context "with nil global identifier" do
        let(:element) do
          double(
            "Class",
            tagged_value: nil,
          )
        end

        before do
          allow(processor).to receive(:element_is_class_or_property?).and_return(true)
          allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
          allow(element).to receive(:respond_to?).with(:global_identifier).and_return(false)
        end

        it "returns false" do
          expect(processor.applies_to?(element, context)).to be false
        end
      end

      context "with non-class/property element" do
        let(:element) do
          double(
            "Package",
            tagged_value: "urn:example:def:package:MyPackage",
          )
        end

        before do
          allow(processor).to receive(:element_is_class_or_property?).and_return(false)
        end

        it "returns false" do
          expect(processor.applies_to?(element, context)).to be false
        end
      end
    end

    context "when rule is disabled" do
      let(:context) do
        double(
          "Context",
          rule_enabled?: false,
        )
      end
      let(:element) do
        double(
          "Class",
          tagged_value: "urn:example:def:featureType:Road",
        )
      end

      it "returns false" do
        expect(processor.applies_to?(element, context)).to be false
      end
    end
  end

  describe ".process" do
    context "with valid global identifier" do
      let(:element) do
        double(
          "Class",
          tagged_value: "urn:example:def:featureType:Building",
        )
      end

      before do
        allow(processor).to receive(:element_is_class_or_property?).and_return(true)
      end

      it "returns appinfo with globalIdentifier element" do
        result = processor.process(element, context)

        expect(result[:appinfo]).to include(
          hash_including(
            namespace: scai_namespace,
            element: "globalIdentifier",
            text: "urn:example:def:featureType:Building",
          ),
        )
      end

      it "includes ShapeChange AppInfo namespace import" do
        result = processor.process(element, context)

        expect(result[:imports]).to include(
          hash_including(
            prefix: "sc",
            namespace: scai_namespace,
          ),
        )
      end
    end

    context "with property global identifier" do
      let(:element) do
        double(
          "Property",
          tagged_value: "urn:inspire:def:propertyType:areaValue",
        )
      end

      before do
        allow(processor).to receive(:element_is_class_or_property?).and_return(true)
      end

      it "returns appinfo with property identifier" do
        result = processor.process(element, context)

        expect(result[:appinfo]).to include(
          hash_including(
            text: "urn:inspire:def:propertyType:areaValue",
          ),
        )
      end
    end

    context "when rule does not apply" do
      let(:element) do
        double(
          "Class",
          tagged_value: nil,
        )
      end

      before do
        allow(processor).to receive(:element_is_class_or_property?).and_return(true)
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(element).to receive(:respond_to?).with(:global_identifier).and_return(false)
      end

      it "returns empty hash" do
        result = processor.process(element, context)

        expect(result).to eq({})
      end
    end
  end

  describe ".element_is_class_or_property?" do
    context "with Lutaml::Uml::Class" do
      let(:element) { Lutaml::Uml::Class.new }

      it "returns true" do
        expect(processor.element_is_class_or_property?(element)).to be true
      end
    end

    context "with Lutaml::Uml::Property" do
      let(:element) { Lutaml::Uml::Property.new }

      it "returns true" do
        expect(processor.element_is_class_or_property?(element)).to be true
      end
    end

    context "with element having type :class" do
      let(:element) do
        double("Element", type: :class)
      end

      before do
        allow(element).to receive(:respond_to?).with(:type).and_return(true)
      end

      it "returns true" do
        expect(processor.element_is_class_or_property?(element)).to be true
      end
    end

    context "with element having type :property" do
      let(:element) do
        double("Element", type: :property)
      end

      before do
        allow(element).to receive(:respond_to?).with(:type).and_return(true)
      end

      it "returns true" do
        expect(processor.element_is_class_or_property?(element)).to be true
      end
    end

    context "with other element type" do
      let(:element) do
        double("Element")
      end

      it "returns false" do
        expect(processor.element_is_class_or_property?(element)).to be false
      end
    end
  end

  describe ".get_global_identifier" do
    context "when element has tagged value" do
      let(:element) do
        double(
          "Class",
          tagged_value: "urn:example:def:featureType:Road",
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
      end

      it "returns the tagged value" do
        value = processor.get_global_identifier(element)

        expect(value).to eq("urn:example:def:featureType:Road")
      end
    end

    context "when element has global_identifier property" do
      let(:element) do
        double(
          "Class",
          global_identifier: "urn:inspire:def:featureType:Parcel",
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(element).to receive(:tagged_value).and_return(nil)
        allow(element).to receive(:respond_to?).with(:global_identifier).and_return(true)
      end

      it "returns the property value" do
        value = processor.get_global_identifier(element)

        expect(value).to eq("urn:inspire:def:featureType:Parcel")
      end
    end

    context "when element has neither" do
      let(:element) do
        double("Class")
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(false)
        allow(element).to receive(:respond_to?).with(:global_identifier).and_return(false)
      end

      it "returns nil" do
        value = processor.get_global_identifier(element)

        expect(value).to be_nil
      end
    end
  end
end