# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/property_rules/att_map_entry_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::PropertyRules::AttMapEntryProcessor do
  let(:config) do
    instance_double(
      Lutaml::Klin::XsdGeneratorConfiguration,
      rule_enabled?: true,
      encoding_rule: "xsd",
      gml_version: "3.2"
    )
  end

  let(:xsd_builder) do
    instance_double(Lutaml::Klin::Builders::XsdDocumentBuilder)
  end

  describe ".applies_to?" do
    context "when property has attribute map entries" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          type: "ExternalReference",
          is_attribute?: false
        )
      end

      let(:map_entry) do
        instance_double(Object, rule: "xlink:href")
      end

      before do
        allow(config).to receive(:attribute_map_entry)
          .with("ExternalReference", "xsd")
          .and_return(map_entry)
      end

      it "returns true" do
        expect(described_class.applies_to?(property, config)).to be true
      end
    end

    context "when property has attributeGroup map entries" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          type: "ExternalReference",
          is_attribute?: false
        )
      end

      let(:map_entry) do
        instance_double(Object, rule: "xlink:simpleAttrs")
      end

      before do
        allow(config).to receive(:attribute_map_entry)
          .with("ExternalReference", "xsd")
          .and_return(nil)
        allow(config).to receive(:attribute_group_map_entry)
          .with("ExternalReference", "xsd")
          .and_return(map_entry)
      end

      it "returns true" do
        expect(described_class.applies_to?(property, config)).to be true
      end
    end

    context "when property is already an attribute" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          type: "String",
          is_attribute?: true
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
          type: "ExternalReference",
          is_attribute?: false
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-att-map-entry")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(property, config)).to be false
      end
    end

    context "when property has no attribute map entries" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          type: "SomeType",
          is_attribute?: false
        )
      end

      before do
        allow(config).to receive(:attribute_map_entry)
          .with("SomeType", "xsd")
          .and_return(nil)
        allow(config).to receive(:attribute_group_map_entry)
          .with("SomeType", "xsd")
          .and_return(nil)
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
        type: "ExternalReference",
        is_attribute?: false,
        nil_reason_allowed?: false,
        voidable?: false,
        property_metadata?: false,
        tagged_value: nil
      )
    end

    let(:parent_element) { double("parent_element") }
    let(:complex_type) { double("complex_type") }
    let(:attribute_element) { double("attribute_element") }

    let(:attribute_map_entry) do
      instance_double(Object, rule: "xlink:href")
    end

    let(:attribute_group_map_entry) do
      instance_double(Object, rule: "xlink:simpleAttrs")
    end

    before do
      allow(config).to receive(:attribute_map_entry)
        .with("ExternalReference", "xsd")
        .and_return(attribute_map_entry)
      allow(config).to receive(:attribute_group_map_entry)
        .with("ExternalReference", "xsd")
        .and_return(attribute_group_map_entry)

      allow(parent_element).to receive(:add_complex_type).and_yield(complex_type)
      allow(complex_type).to receive(:add_attribute).and_yield(attribute_element)
      allow(complex_type).to receive(:add_attribute_group)
      allow(attribute_element).to receive(:ref=)
      allow(xsd_builder).to receive(:resolve_namespace).and_return("http://www.w3.org/1999/xlink")
      allow(xsd_builder).to receive(:add_import)
    end

    it "creates anonymous complex type" do
      expect(parent_element).to receive(:add_complex_type)
      described_class.process_property(property, parent_element, xsd_builder,
                                       config)
    end

    it "adds attribute reference" do
      expect(attribute_element).to receive(:ref=).with("xlink:href")
      described_class.process_property(property, parent_element, xsd_builder,
                                       config)
    end

    it "adds attributeGroup reference" do
      expect(complex_type).to receive(:add_attribute_group)
      described_class.process_property(property, parent_element, xsd_builder,
                                       config)
    end

    it "imports required namespaces" do
      expect(xsd_builder).to receive(:add_import)
        .with("xlink", "http://www.w3.org/1999/xlink")
        .at_least(:once)
      described_class.process_property(property, parent_element, xsd_builder,
                                       config)
    end

    context "with nilReason enabled" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          type: "ExternalReference",
          is_attribute?: false,
          nil_reason_allowed?: true,
          voidable?: false,
          property_metadata?: false,
          tagged_value: nil
        )
      end

      let(:nil_reason_attr) { double("nil_reason_attr") }

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-nillable")
          .and_return(true)
        allow(complex_type).to receive(:add_attribute)
          .and_yield(nil_reason_attr)
          .ordered
        allow(nil_reason_attr).to receive(:name=)
        allow(nil_reason_attr).to receive(:type=)
      end

      it "adds nilReason attribute" do
        expect(nil_reason_attr).to receive(:name=).with("nilReason")
        expect(nil_reason_attr).to receive(:type=).with("gml:NilReasonType")
        described_class.process_property(property, parent_element, xsd_builder,
                                         config)
      end
    end

    context "with metadata enabled" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          type: "ExternalReference",
          is_attribute?: false,
          nil_reason_allowed?: false,
          voidable?: false,
          property_metadata?: true,
          tagged_value: nil
        )
      end

      let(:metadata_attr) { double("metadata_attr") }

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-metadata")
          .and_return(true)
        allow(complex_type).to receive(:add_attribute)
          .and_yield(metadata_attr)
        allow(metadata_attr).to receive(:name=)
        allow(metadata_attr).to receive(:type=)
      end

      it "adds metadata attribute" do
        expect(metadata_attr).to receive(:name=).with("metadata")
        expect(metadata_attr).to receive(:type=).with("xs:anyURI")
        described_class.process_property(property, parent_element, xsd_builder,
                                         config)
      end
    end

    context "with soft-typed enabled" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          type: "ExternalReference",
          is_attribute?: false,
          nil_reason_allowed?: false,
          voidable?: false,
          property_metadata?: false
        )
      end

      let(:name_attr) { double("name_attr") }

      before do
        allow(property).to receive(:tagged_value)
          .with("soft-typed")
          .and_return("true")
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-soft-typed")
          .and_return(true)
        allow(complex_type).to receive(:add_attribute)
          .and_yield(name_attr)
        allow(name_attr).to receive(:name=)
        allow(name_attr).to receive(:type=)
        allow(name_attr).to receive(:use=)
      end

      it "adds name attribute" do
        expect(name_attr).to receive(:name=).with("name")
        expect(name_attr).to receive(:type=).with("xs:NCName")
        expect(name_attr).to receive(:use=).with("required")
        described_class.process_property(property, parent_element, xsd_builder,
                                         config)
      end
    end
  end

  describe ".get_attribute_map_entry" do
    let(:property) do
      instance_double(
        Lutaml::Uml::Attribute,
        type: "ExternalReference"
      )
    end

    context "when map entry exists" do
      let(:map_entry) do
        instance_double(Object, rule: "xlink:href")
      end

      before do
        allow(config).to receive(:attribute_map_entry)
          .with("ExternalReference", "xsd")
          .and_return(map_entry)
      end

      it "returns the attribute reference" do
        result = described_class.get_attribute_map_entry(property, config)
        expect(result).to eq("xlink:href")
      end
    end

    context "when map entry does not exist" do
      before do
        allow(config).to receive(:attribute_map_entry)
          .with("ExternalReference", "xsd")
          .and_return(nil)
      end

      it "returns nil" do
        result = described_class.get_attribute_map_entry(property, config)
        expect(result).to be_nil
      end
    end
  end

  describe ".get_attribute_group_map_entry" do
    let(:property) do
      instance_double(
        Lutaml::Uml::Attribute,
        type: "ExternalReference"
      )
    end

    context "when map entry exists" do
      let(:map_entry) do
        instance_double(Object, rule: "xlink:simpleAttrs")
      end

      before do
        allow(config).to receive(:attribute_group_map_entry)
          .with("ExternalReference", "xsd")
          .and_return(map_entry)
      end

      it "returns the attributeGroup reference" do
        result = described_class.get_attribute_group_map_entry(property, config)
        expect(result).to eq("xlink:simpleAttrs")
      end
    end

    context "when map entry does not exist" do
      before do
        allow(config).to receive(:attribute_group_map_entry)
          .with("ExternalReference", "xsd")
          .and_return(nil)
      end

      it "returns nil" do
        result = described_class.get_attribute_group_map_entry(property, config)
        expect(result).to be_nil
      end
    end
  end

  describe ".should_add_nil_reason?" do
    context "when property allows nil reason" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          nil_reason_allowed?: true,
          voidable?: false
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-nillable")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.should_add_nil_reason?(property,
                                                      config)).to be true
      end
    end

    context "when property is voidable" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          nil_reason_allowed?: false,
          voidable?: true
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-nillable")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.should_add_nil_reason?(property,
                                                      config)).to be true
      end
    end

    context "when rule is disabled" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          nil_reason_allowed?: true,
          voidable?: false
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-nillable")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.should_add_nil_reason?(property,
                                                      config)).to be false
      end
    end
  end

  describe ".should_add_metadata?" do
    context "when property has metadata" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          property_metadata?: true
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-metadata")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.should_add_metadata?(property,
                                                    config)).to be true
      end
    end

    context "when rule is disabled" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          property_metadata?: true
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-metadata")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.should_add_metadata?(property,
                                                    config)).to be false
      end
    end
  end

  describe ".should_add_soft_typed_name?" do
    context "when soft-typed tagged value is true" do
      let(:property) do
        instance_double(Lutaml::Uml::Attribute)
      end

      before do
        allow(property).to receive(:tagged_value)
          .with("soft-typed")
          .and_return("true")
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-prop-soft-typed")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.should_add_soft_typed_name?(property,
                                                           config)).to be true
      end
    end

    context "when soft-typed tagged value is false" do
      let(:property) do
        instance_double(Lutaml::Uml::Attribute)
      end

      before do
        allow(property).to receive(:tagged_value)
          .with("soft-typed")
          .and_return("false")
      end

      it "returns false" do
        expect(described_class.should_add_soft_typed_name?(property,
                                                           config)).to be false
      end
    end
  end
end
