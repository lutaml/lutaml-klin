# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/property_rules/feature_type_gmlsf_by_reference_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::PropertyRules::FeatureTypeGmlsfByReferenceProcessor do
  let(:config) do
    instance_double(
      Lutaml::Klin::XsdGeneratorConfiguration,
      rule_enabled?: true,
      namespace_prefix_for: "gml"
    )
  end

  let(:xsd_builder) do
    instance_double(
      Lutaml::Klin::Builders::XsdDocumentBuilder,
      write_xml_encoding_infos?: false,
      target_namespace: "http://example.org/ns"
    )
  end

  describe ".applies_to?" do
    context "when property has feature type value" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          category_of_value: :feature
        )
      end

      it "returns true" do
        expect(described_class.applies_to?(property, config)).to be true
      end
    end

    context "when property does not have feature type value" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          category_of_value: :datatype
        )
      end

      it "returns false" do
        expect(described_class.applies_to?(property, config)).to be false
      end
    end

    context "when rule is disabled" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          category_of_value: :feature
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-featureType-gmlsf-byReference")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(property, config)).to be false
      end
    end
  end

  describe ".process_property" do
    let(:property) do
      instance_double(
        Lutaml::Uml::Attribute,
        name: "relatedFeature",
        category_of_value: :feature,
        definition: "Reference to related feature",
        cardinality: { min: 0, max: 1 }
      )
    end

    let(:parent_element) { double("parent_element") }
    let(:element_builder) { double("element_builder") }
    let(:annotation_builder) { double("annotation_builder") }

    before do
      allow(parent_element).to receive(:add_element)
        .with("relatedFeature")
        .and_yield(element_builder)
      allow(element_builder).to receive(:add_annotation)
        .and_yield(annotation_builder)
      allow(annotation_builder).to receive(:add_documentation)
      allow(element_builder).to receive(:type=)
      allow(element_builder).to receive(:min_occurs=)
      allow(element_builder).to receive(:max_occurs=)
      allow(xsd_builder).to receive(:add_import)
    end

    it "creates element for property" do
      expect(parent_element).to receive(:add_element)
        .with("relatedFeature")
      described_class.process_property(property, parent_element, xsd_builder, config)
    end

    it "adds property documentation" do
      expect(annotation_builder).to receive(:add_documentation)
        .with("Reference to related feature")
      described_class.process_property(property, parent_element, xsd_builder, config)
    end

    it "sets type to gml:ReferenceType" do
      expect(element_builder).to receive(:type=)
        .with("gml:ReferenceType")
      described_class.process_property(property, parent_element, xsd_builder, config)
    end

    it "applies multiplicity constraints" do
      expect(element_builder).to receive(:min_occurs=).with(0)
      described_class.process_property(property, parent_element, xsd_builder, config)
    end

    it "imports GML namespace" do
      expect(xsd_builder).to receive(:add_import)
        .with("gml", "http://www.opengis.net/gml/3.2")
      described_class.process_property(property, parent_element, xsd_builder, config)
    end

    context "with multiple occurrences" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          name: "relatedFeatures",
          category_of_value: :feature,
          definition: nil,
          cardinality: { min: 0, max: -1 }
        )
      end

      it "sets max_occurs to unbounded" do
        expect(element_builder).to receive(:min_occurs=).with(0)
        expect(element_builder).to receive(:max_occurs=).with("unbounded")
        described_class.process_property(property, parent_element, xsd_builder, config)
      end
    end

    context "with required property" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          name: "relatedFeature",
          category_of_value: :feature,
          definition: nil,
          cardinality: { min: 1, max: 1 }
        )
      end

      it "does not set multiplicity attributes for default 1..1" do
        expect(element_builder).not_to receive(:min_occurs=)
        expect(element_builder).not_to receive(:max_occurs=)
        described_class.process_property(property, parent_element, xsd_builder, config)
      end
    end

    context "with encoding infos enabled" do
      before do
        allow(xsd_builder).to receive(:write_xml_encoding_infos?).and_return(true)
        allow(xsd_builder).to receive(:add_encoding_info)
      end

      it "records encoding info" do
        expect(xsd_builder).to receive(:add_encoding_info)
          .with(
            property,
            "relatedFeature",
            "http://example.org/ns",
            false
          )
        described_class.process_property(property, parent_element, xsd_builder, config)
      end
    end

    context "with custom GML namespace prefix" do
      before do
        allow(config).to receive(:namespace_prefix_for)
          .with("http://www.opengis.net/gml/3.2")
          .and_return("gml32")
      end

      it "uses custom prefix for import" do
        expect(xsd_builder).to receive(:add_import)
          .with("gml32", "http://www.opengis.net/gml/3.2")
        described_class.process_property(property, parent_element, xsd_builder, config)
      end
    end

    context "when property is not a feature type" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          name: "someProperty",
          category_of_value: :datatype
        )
      end

      it "does not process the property" do
        expect(parent_element).not_to receive(:add_element)
        described_class.process_property(property, parent_element, xsd_builder, config)
      end
    end
  end

  describe ".apply_multiplicity" do
    let(:element) { double("element") }

    context "with optional property" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          cardinality: { min: 0, max: 1 }
        )
      end

      it "sets min_occurs to 0" do
        expect(element).to receive(:min_occurs=).with(0)
        described_class.apply_multiplicity(element, property)
      end
    end

    context "with unbounded multiplicity" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          cardinality: { min: 0, max: -1 }
        )
      end

      it "sets max_occurs to unbounded" do
        expect(element).to receive(:min_occurs=).with(0)
        expect(element).to receive(:max_occurs=).with("unbounded")
        described_class.apply_multiplicity(element, property)
      end
    end

    context "with specific multiplicity" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          cardinality: { min: 2, max: 5 }
        )
      end

      it "sets specific values" do
        expect(element).to receive(:min_occurs=).with(2)
        expect(element).to receive(:max_occurs=).with(5)
        described_class.apply_multiplicity(element, property)
      end
    end

    context "with default multiplicity (1..1)" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          cardinality: { min: 1, max: 1 }
        )
      end

      it "does not set attributes" do
        expect(element).not_to receive(:min_occurs=)
        expect(element).not_to receive(:max_occurs=)
        described_class.apply_multiplicity(element, property)
      end
    end

    context "with Float::INFINITY for unbounded" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          cardinality: { min: 1, max: Float::INFINITY }
        )
      end

      it "sets max_occurs to unbounded" do
        expect(element).to receive(:max_occurs=).with("unbounded")
        described_class.apply_multiplicity(element, property)
      end
    end

    context "when property has no cardinality" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          cardinality: nil
        )
      end

      it "does not set multiplicity" do
        expect(element).not_to receive(:min_occurs=)
        expect(element).not_to receive(:max_occurs=)
        described_class.apply_multiplicity(element, property)
      end
    end
  end
end