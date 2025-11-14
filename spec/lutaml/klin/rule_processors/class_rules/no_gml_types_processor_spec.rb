# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/class_rules/no_gml_types_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::ClassRules::NoGmlTypesProcessor do
  let(:config) { instance_double(Lutaml::Klin::XsdGeneratorConfiguration) }
  let(:xsd_builder) { instance_double(Lutaml::Klin::Builders::XsdDocumentBuilder) }
  let(:uml_class) { instance_double(Lutaml::Uml::Class) }

  describe ".applies_to?" do
    context "when rule is enabled" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.applies_to?(uml_class, config)).to be true
      end
    end

    context "when rule is disabled" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end
  end

  describe ".default_substitution_group" do
    context "when rule applies" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(true)
      end

      it "returns nil (no GML substitution group)" do
        result = described_class.default_substitution_group(uml_class, config)
        expect(result).to be_nil
      end
    end

    context "when rule does not apply" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(false)
      end

      it "returns :not_processed" do
        result = described_class.default_substitution_group(uml_class, config)
        expect(result).to eq(:not_processed)
      end
    end
  end

  describe ".default_base_type" do
    context "when rule applies" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(true)
      end

      it "returns nil (no GML base type)" do
        result = described_class.default_base_type(uml_class, config)
        expect(result).to be_nil
      end
    end

    context "when rule does not apply" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(false)
      end

      it "returns :not_processed" do
        result = described_class.default_base_type(uml_class, config)
        expect(result).to eq(:not_processed)
      end
    end
  end

  describe ".add_property_type_attributes" do
    let(:property_type_element) { double("property_type_element") }

    context "when rule applies" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(true)
        allow(xsd_builder).to receive(:xlink_namespace).and_return("http://www.w3.org/1999/xlink")
      end

      it "adds xlink:simpleAttrs attribute group" do
        expect(property_type_element).to receive(:add_attribute_group).with("xlink:simpleAttrs")
        expect(xsd_builder).to receive(:add_import).with("xlink", "http://www.w3.org/1999/xlink")

        described_class.add_property_type_attributes(
          property_type_element,
          uml_class,
          xsd_builder,
          config
        )
      end
    end

    context "when rule does not apply" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(false)
      end

      it "does not add attributes" do
        expect(property_type_element).not_to receive(:add_attribute_group)
        expect(xsd_builder).not_to receive(:add_import)

        described_class.add_property_type_attributes(
          property_type_element,
          uml_class,
          xsd_builder,
          config
        )
      end
    end
  end

  describe ".use_gml_types?" do
    context "when rule applies (no-gml-types enabled)" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(true)
      end

      it "returns false" do
        expect(described_class.use_gml_types?(uml_class, config)).to be false
      end
    end

    context "when rule does not apply (no-gml-types disabled)" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(false)
      end

      it "returns true" do
        expect(described_class.use_gml_types?(uml_class, config)).to be true
      end
    end
  end

  describe ".association_attribute_group" do
    context "when rule applies" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(true)
      end

      it "returns xlink:simpleAttrs" do
        result = described_class.association_attribute_group(uml_class, config)
        expect(result).to eq("xlink:simpleAttrs")
      end
    end

    context "when rule does not apply" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-gml-types")
          .and_return(false)
      end

      it "returns :not_processed" do
        result = described_class.association_attribute_group(uml_class, config)
        expect(result).to eq(:not_processed)
      end
    end
  end
end