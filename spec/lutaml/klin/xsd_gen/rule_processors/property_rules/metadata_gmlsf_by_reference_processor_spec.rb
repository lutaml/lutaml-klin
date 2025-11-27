# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/xsd_gen/rule_processors/property_rules/metadata_gmlsf_by_reference_processor"

RSpec.describe Lutaml::Klin::XsdGen::RuleProcessors::PropertyRules::MetadataGmlsfByReferenceProcessor do
  let(:processor) { described_class }
  let(:context) do
    double(
      "Context",
      rule_enabled?: true,
      gml_namespace: "http://www.opengis.net/gml/3.2",
      model: model
    )
  end
  let(:model) { double("Model") }

  describe ".applies_to?" do
    context "when rule is enabled" do
      context "with metadata property" do
        let(:property) do
          double(
            "Property",
            is_metadata: true,
            type: nil
          )
        end

        it "returns true" do
          expect(processor.applies_to?(property, context)).to be true
        end
      end

      context "with property having metadata type" do
        let(:property) do
          double(
            "Property",
            is_metadata: false,
            type: "MetadataType"
          )
        end
        let(:metadata_class) do
          double("Class", stereotype?: true)
        end

        before do
          allow(model).to receive(:find_class_by_name)
            .with("MetadataType")
            .and_return(metadata_class)
        end

        it "returns true" do
          expect(processor.applies_to?(property, context)).to be true
        end
      end

      context "with non-metadata property" do
        let(:property) do
          double(
            "Property",
            is_metadata: false,
            type: "RegularType"
          )
        end
        let(:regular_class) do
          double("Class", stereotype?: false)
        end

        before do
          allow(model).to receive(:find_class_by_name)
            .with("RegularType")
            .and_return(regular_class)
        end

        it "returns false" do
          expect(processor.applies_to?(property, context)).to be false
        end
      end
    end

    context "when rule is disabled" do
      let(:context) do
        double(
          "Context",
          rule_enabled?: false,
          gml_namespace: "http://www.opengis.net/gml/3.2",
          model: model
        )
      end
      let(:property) do
        double(
          "Property",
          is_metadata: true,
          type: nil
        )
      end

      it "returns false" do
        expect(processor.applies_to?(property, context)).to be false
      end
    end
  end

  describe ".process" do
    context "with metadata property" do
      let(:property) do
        double(
          "Property",
          is_metadata: true,
          type: nil
        )
      end

      it "returns gml:ReferenceType configuration" do
        result = processor.process(property, context)

        expect(result[:type]).to eq("gml:ReferenceType")
        expect(result[:processed]).to be true
      end

      it "includes GML namespace import" do
        result = processor.process(property, context)

        expect(result[:imports]).to include(
          hash_including(
            prefix: "gml",
            namespace: "http://www.opengis.net/gml/3.2"
          )
        )
      end
    end

    context "with property having metadata value type" do
      let(:property) do
        double(
          "Property",
          is_metadata: false,
          type: "DataQuality"
        )
      end
      let(:metadata_class) do
        double("Class", stereotype?: true)
      end

      before do
        allow(model).to receive(:find_class_by_name)
          .with("DataQuality")
          .and_return(metadata_class)
      end

      it "returns gml:ReferenceType configuration" do
        result = processor.process(property, context)

        expect(result[:type]).to eq("gml:ReferenceType")
        expect(result[:processed]).to be true
      end
    end

    context "with non-metadata property" do
      let(:property) do
        double(
          "Property",
          is_metadata: false,
          type: "FeatureType"
        )
      end
      let(:regular_class) do
        double("Class", stereotype?: false)
      end

      before do
        allow(model).to receive(:find_class_by_name)
          .with("FeatureType")
          .and_return(regular_class)
      end

      it "returns empty hash" do
        result = processor.process(property, context)

        expect(result).to eq({})
      end
    end

    context "when rule is disabled" do
      let(:context) do
        double(
          "Context",
          rule_enabled?: false,
          gml_namespace: "http://www.opengis.net/gml/3.2",
          model: model
        )
      end
      let(:property) do
        double(
          "Property",
          is_metadata: true,
          type: nil
        )
      end

      it "returns empty hash" do
        result = processor.process(property, context)

        expect(result).to eq({})
      end
    end
  end

  describe ".property_is_metadata?" do
    context "when property is marked as metadata" do
      let(:property) do
        double(
          "Property",
          is_metadata: true,
          type: nil
        )
      end

      it "returns true" do
        expect(processor.property_is_metadata?(property, context)).to be true
      end
    end

    context "when property type is metadata" do
      let(:property) do
        double(
          "Property",
          is_metadata: false,
          type: "Lineage"
        )
      end
      let(:metadata_class) do
        double("Class", stereotype?: true)
      end

      before do
        allow(model).to receive(:find_class_by_name)
          .with("Lineage")
          .and_return(metadata_class)
      end

      it "returns true" do
        expect(processor.property_is_metadata?(property, context)).to be true
      end
    end

    context "when neither property nor type is metadata" do
      let(:property) do
        double(
          "Property",
          is_metadata: false,
          type: "String"
        )
      end
      let(:regular_class) do
        double("Class", stereotype?: false)
      end

      before do
        allow(model).to receive(:find_class_by_name)
          .with("String")
          .and_return(regular_class)
      end

      it "returns false" do
        expect(processor.property_is_metadata?(property, context)).to be false
      end
    end

    context "when property has no type" do
      let(:property) do
        double(
          "Property",
          is_metadata: false,
          type: nil
        )
      end

      it "returns false" do
        expect(processor.property_is_metadata?(property, context)).to be false
      end
    end
  end
end
