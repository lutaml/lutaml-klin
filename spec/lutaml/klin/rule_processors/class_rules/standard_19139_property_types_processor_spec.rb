# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/class_rules/standard_19139_property_types_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::ClassRules::Standard19139PropertyTypesProcessor do
  let(:config) { instance_double(Lutaml::Klin::XsdGeneratorConfiguration) }
  let(:xsd_builder) { instance_double(Lutaml::Klin::Builders::XsdDocumentBuilder) }
  let(:uml_class) { instance_double(Lutaml::Uml::Class) }
  let(:package) { instance_double(Lutaml::Uml::Package) }

  describe ".applies_to?" do
    context "when rule is enabled" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-standard-19139-property-types")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.applies_to?(uml_class, config)).to be true
      end
    end

    context "when rule is disabled" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-standard-19139-property-types")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end
  end

  describe ".generate_property_type" do
    before do
      allow(config).to receive(:rule_enabled?)
        .with("rule-xsd-cls-standard-19139-property-types")
        .and_return(true)
      allow(uml_class).to receive(:name).and_return("Building")
      allow(uml_class).to receive(:package).and_return(package)
      allow(package).to receive(:xmlns).and_return("bldg")
    end

    context "for feature/object types (with gco:ObjectReference)" do
      before do
        allow(uml_class).to receive(:category).and_return(:feature)
      end

      it "generates property type with gco:ObjectReference and gco:nilReason" do
        complex_type = double("complex_type")
        sequence = double("sequence")

        expect(xsd_builder).to receive(:add_complex_type)
          .with("Building_PropertyType")
          .and_yield(complex_type)

        expect(complex_type).to receive(:add_sequence)
          .with(min_occurs: 0)
          .and_yield(sequence)

        expect(sequence).to receive(:add_element_ref).with("bldg:Building")

        expect(complex_type).to receive(:add_attribute_group).with("gco:ObjectReference")
        expect(complex_type).to receive(:add_attribute_ref).with("gco:nilReason")

        expect(xsd_builder).to receive(:add_import)
          .with("gco", described_class::GCO_NS)

        described_class.generate_property_type(uml_class, xsd_builder, config)
      end
    end

    context "for codelist types (without gco:ObjectReference)" do
      before do
        allow(uml_class).to receive(:category).and_return(:codelist)
      end

      it "generates property type with gco:nilReason only" do
        complex_type = double("complex_type")
        sequence = double("sequence")

        expect(xsd_builder).to receive(:add_complex_type)
          .with("Building_PropertyType")
          .and_yield(complex_type)

        expect(complex_type).to receive(:add_sequence)
          .with(min_occurs: 0)
          .and_yield(sequence)

        expect(sequence).to receive(:add_element_ref).with("bldg:Building")

        expect(complex_type).not_to receive(:add_attribute_group).with("gco:ObjectReference")
        expect(complex_type).to receive(:add_attribute_ref).with("gco:nilReason")

        expect(xsd_builder).to receive(:add_import)
          .with("gco", described_class::GCO_NS)

        described_class.generate_property_type(uml_class, xsd_builder, config)
      end
    end

    context "for enumeration types (without gco:ObjectReference)" do
      before do
        allow(uml_class).to receive(:category).and_return(:enumeration)
      end

      it "generates property type with gco:nilReason only" do
        complex_type = double("complex_type")
        sequence = double("sequence")

        expect(xsd_builder).to receive(:add_complex_type).and_yield(complex_type)
        expect(complex_type).to receive(:add_sequence).and_yield(sequence)
        expect(sequence).to receive(:add_element_ref)
        expect(complex_type).not_to receive(:add_attribute_group).with("gco:ObjectReference")
        expect(complex_type).to receive(:add_attribute_ref).with("gco:nilReason")
        expect(xsd_builder).to receive(:add_import)

        described_class.generate_property_type(uml_class, xsd_builder, config)
      end
    end

    context "for union types (without gco:ObjectReference)" do
      before do
        allow(uml_class).to receive(:category).and_return(:union)
      end

      it "generates property type with gco:nilReason only" do
        complex_type = double("complex_type")
        sequence = double("sequence")

        expect(xsd_builder).to receive(:add_complex_type).and_yield(complex_type)
        expect(complex_type).to receive(:add_sequence).and_yield(sequence)
        expect(sequence).to receive(:add_element_ref)
        expect(complex_type).not_to receive(:add_attribute_group).with("gco:ObjectReference")
        expect(complex_type).to receive(:add_attribute_ref).with("gco:nilReason")
        expect(xsd_builder).to receive(:add_import)

        described_class.generate_property_type(uml_class, xsd_builder, config)
      end
    end
  end

  describe ".build_property_type_name" do
    before do
      allow(uml_class).to receive(:name).and_return("Building")
    end

    it "returns property type name" do
      expect(described_class.build_property_type_name(uml_class)).to eq("Building_PropertyType")
    end
  end

  describe ".build_element_reference" do
    context "when class has package" do
      before do
        allow(uml_class).to receive(:name).and_return("Building")
        allow(uml_class).to receive(:package).and_return(package)
        allow(package).to receive(:xmlns).and_return("bldg")
      end

      it "returns qualified element reference" do
        result = described_class.build_element_reference(uml_class, xsd_builder)
        expect(result).to eq("bldg:Building")
      end
    end

    context "when class has no package" do
      before do
        allow(uml_class).to receive(:package).and_return(nil)
      end

      it "returns nil" do
        result = described_class.build_element_reference(uml_class, xsd_builder)
        expect(result).to be_nil
      end
    end
  end

  describe ".omit_object_reference?" do
    context "for codelist" do
      before do
        allow(uml_class).to receive(:category).and_return(:codelist)
      end

      it "returns true" do
        expect(described_class.omit_object_reference?(uml_class)).to be true
      end
    end

    context "for enumeration" do
      before do
        allow(uml_class).to receive(:category).and_return(:enumeration)
      end

      it "returns true" do
        expect(described_class.omit_object_reference?(uml_class)).to be true
      end
    end

    context "for union" do
      before do
        allow(uml_class).to receive(:category).and_return(:union)
      end

      it "returns true" do
        expect(described_class.omit_object_reference?(uml_class)).to be true
      end
    end

    context "for feature" do
      before do
        allow(uml_class).to receive(:category).and_return(:feature)
      end

      it "returns false" do
        expect(described_class.omit_object_reference?(uml_class)).to be false
      end
    end

    context "for datatype" do
      before do
        allow(uml_class).to receive(:category).and_return(:datatype)
      end

      it "returns false" do
        expect(described_class.omit_object_reference?(uml_class)).to be false
      end
    end
  end
end