# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/class_rules/suppress_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::ClassRules::SuppressProcessor do
  let(:config) do
    instance_double(
      Lutaml::Klin::XsdGeneratorConfiguration,
      rule_enabled?: true
    )
  end

  let(:xsd_builder) do
    instance_double(
      Lutaml::Klin::Builders::XsdDocumentBuilder,
      write_xml_encoding_infos?: false,
      target_namespace: "http://example.org/ade"
    )
  end

  let(:package) do
    instance_double(
      Lutaml::Uml::Package,
      xmlns: "bldg",
      target_namespace: "http://example.org/building"
    )
  end

  describe ".applies_to?" do
    context "when class has adeelement stereotype" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          name: "Building"
        )
      end

      before do
        allow(uml_class).to receive(:stereotype?).with("adeelement").and_return(true)
      end

      it "returns true" do
        expect(described_class.applies_to?(uml_class, config)).to be true
      end
    end

    context "when class does not have adeelement stereotype" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          name: "Building"
        )
      end

      before do
        allow(uml_class).to receive(:stereotype?).with("adeelement").and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end

    context "when rule is disabled" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          name: "Building"
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-suppress")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end
  end

  describe ".process_property" do
    let(:parent_class) do
      instance_double(
        Lutaml::Uml::Class,
        name: "Building",
        generalizations: [generalization]
      )
    end

    let(:generalization) do
      instance_double(
        Lutaml::Uml::Generalization,
        general: "AbstractBuilding"
      )
    end

    let(:unsuppressed_supertype) do
      instance_double(
        Lutaml::Uml::Class,
        name: "AbstractBuilding",
        package: package
      )
    end

    let(:property) do
      instance_double(
        Lutaml::Uml::Attribute,
        name: "height",
        type: "Measure",
        definition: "Building height"
      )
    end

    let(:element_builder) { double("element_builder") }
    let(:annotation_builder) { double("annotation_builder") }

    before do
      allow(parent_class).to receive(:stereotype?).with("adeelement").and_return(true)
      allow(unsuppressed_supertype).to receive(:stereotype?).with("adeelement").and_return(false)
      allow(xsd_builder).to receive(:find_class)
        .with("AbstractBuilding")
        .and_return(unsuppressed_supertype)
      allow(xsd_builder).to receive(:add_element)
        .with("height")
        .and_yield(element_builder)
      allow(element_builder).to receive(:add_annotation).and_yield(annotation_builder)
      allow(annotation_builder).to receive(:add_documentation)
      allow(element_builder).to receive(:substitution_group=)
      allow(xsd_builder).to receive(:add_import)
      allow(xsd_builder).to receive(:map_to_element)
        .with(unsuppressed_supertype)
        .and_return("bldg:AbstractBuilding")

      # Mock PropertyTypeMapper
      property_type_mapper = class_double("PropertyTypeMapper")
      stub_const(
        "Lutaml::Klin::RuleProcessors::ClassRules::SuppressProcessor::PropertyTypeMapper", property_type_mapper
      )
      allow(property_type_mapper).to receive(:map_property_type)
    end

    it "creates element for property" do
      expect(xsd_builder).to receive(:add_element).with("height")
      described_class.process_property(property, parent_class, xsd_builder,
                                       config)
    end

    it "adds property documentation" do
      expect(annotation_builder).to receive(:add_documentation)
        .with("Building height")
      described_class.process_property(property, parent_class, xsd_builder,
                                       config)
    end

    it "sets substitution group" do
      expect(element_builder).to receive(:substitution_group=)
        .with("bldg:_GenericApplicationPropertyOfAbstractBuilding")
      described_class.process_property(property, parent_class, xsd_builder,
                                       config)
    end

    it "imports supertype namespace" do
      expect(xsd_builder).to receive(:add_import)
        .with("bldg", "http://example.org/building")
      described_class.process_property(property, parent_class, xsd_builder,
                                       config)
    end

    context "when no unsuppressed supertype exists" do
      let(:parent_class) do
        instance_double(
          Lutaml::Uml::Class,
          name: "Building",
          generalizations: nil
        )
      end

      it "adds error and returns" do
        expect(xsd_builder).to receive(:add_error)
          .with(/no unsuppressed supertype/, parent_class)
        expect(xsd_builder).not_to receive(:add_element)
        described_class.process_property(property, parent_class, xsd_builder,
                                         config)
      end
    end

    context "when property type has asCharacterString" do
      let(:type_class) do
        instance_double(
          Lutaml::Uml::Class,
          as_character_string?: true
        )
      end

      before do
        allow(xsd_builder).to receive(:find_class)
          .with("Measure")
          .and_return(type_class)
        allow(element_builder).to receive(:type=)
      end

      it "sets type to xs:string" do
        expect(element_builder).to receive(:type=).with("xs:string")
        described_class.process_property(property, parent_class, xsd_builder,
                                         config)
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
            "height",
            "http://example.org/ade",
            false
          )
        described_class.process_property(property, parent_class, xsd_builder,
                                         config)
      end
    end
  end

  describe ".find_unsuppressed_supertype" do
    context "with direct unsuppressed supertype" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          generalizations: [generalization]
        )
      end

      let(:generalization) do
        instance_double(
          Lutaml::Uml::Generalization,
          general: "AbstractBuilding"
        )
      end

      let(:supertype) do
        instance_double(
          Lutaml::Uml::Class,
          name: "AbstractBuilding"
        )
      end

      before do
        allow(xsd_builder).to receive(:find_class)
          .with("AbstractBuilding")
          .and_return(supertype)
        allow(supertype).to receive(:stereotype?).with("adeelement").and_return(false)
      end

      it "returns the unsuppressed supertype" do
        result = described_class.find_unsuppressed_supertype(uml_class,
                                                             xsd_builder)
        expect(result).to eq(supertype)
      end
    end

    context "with suppressed intermediate supertype" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          generalizations: [generalization1]
        )
      end

      let(:generalization1) do
        instance_double(
          Lutaml::Uml::Generalization,
          general: "SuppressedSuper"
        )
      end

      let(:generalization2) do
        instance_double(
          Lutaml::Uml::Generalization,
          general: "UnsuppressedSuper"
        )
      end

      let(:suppressed_super) do
        instance_double(
          Lutaml::Uml::Class,
          name: "SuppressedSuper",
          generalizations: [generalization2]
        )
      end

      let(:unsuppressed_super) do
        instance_double(
          Lutaml::Uml::Class,
          name: "UnsuppressedSuper"
        )
      end

      before do
        allow(xsd_builder).to receive(:find_class)
          .with("SuppressedSuper")
          .and_return(suppressed_super)
        allow(xsd_builder).to receive(:find_class)
          .with("UnsuppressedSuper")
          .and_return(unsuppressed_super)
        allow(suppressed_super).to receive(:stereotype?).with("adeelement").and_return(true)
        allow(unsuppressed_super).to receive(:stereotype?).with("adeelement").and_return(false)
      end

      it "recursively finds unsuppressed supertype" do
        result = described_class.find_unsuppressed_supertype(uml_class,
                                                             xsd_builder)
        expect(result).to eq(unsuppressed_super)
      end
    end

    context "when no unsuppressed supertype exists" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          generalizations: nil
        )
      end

      it "returns nil" do
        result = described_class.find_unsuppressed_supertype(uml_class,
                                                             xsd_builder)
        expect(result).to be_nil
      end
    end
  end

  describe ".build_substitution_group_name" do
    let(:supertype) do
      instance_double(Lutaml::Uml::Class)
    end

    context "with prefixed element name" do
      before do
        allow(xsd_builder).to receive(:map_to_element)
          .with(supertype)
          .and_return("bldg:AbstractBuilding")
      end

      it "builds correct substitution group name" do
        result = described_class.build_substitution_group_name(supertype,
                                                               xsd_builder)
        expect(result).to eq("bldg:_GenericApplicationPropertyOfAbstractBuilding")
      end
    end

    context "with element name containing :_" do
      before do
        allow(xsd_builder).to receive(:map_to_element)
          .with(supertype)
          .and_return("bldg:_AbstractBuilding")
      end

      it "normalizes and builds substitution group name" do
        result = described_class.build_substitution_group_name(supertype,
                                                               xsd_builder)
        expect(result).to eq("bldg:_GenericApplicationPropertyOfAbstractBuilding")
      end
    end

    context "with unprefixed element name" do
      before do
        allow(xsd_builder).to receive(:map_to_element)
          .with(supertype)
          .and_return("AbstractBuilding")
      end

      it "builds substitution group name without prefix" do
        result = described_class.build_substitution_group_name(supertype,
                                                               xsd_builder)
        expect(result).to eq("_GenericApplicationPropertyOfAbstractBuilding")
      end
    end

    context "when element mapping fails" do
      before do
        allow(xsd_builder).to receive(:map_to_element)
          .with(supertype)
          .and_return(nil)
      end

      it "returns nil" do
        result = described_class.build_substitution_group_name(supertype,
                                                               xsd_builder)
        expect(result).to be_nil
      end
    end
  end

  describe ".set_property_type" do
    let(:element) { double("element") }
    let(:property) do
      instance_double(
        Lutaml::Uml::Attribute,
        type: "SomeType"
      )
    end
    let(:parent_class) { double("parent_class") }

    context "when type has asCharacterString" do
      let(:type_class) do
        instance_double(
          Lutaml::Uml::Class,
          as_character_string?: true
        )
      end

      before do
        allow(xsd_builder).to receive(:find_class)
          .with("SomeType")
          .and_return(type_class)
        allow(element).to receive(:type=)
      end

      it "sets type to xs:string" do
        expect(element).to receive(:type=).with("xs:string")
        described_class.set_property_type(element, property, parent_class,
                                          xsd_builder, config)
      end
    end

    context "when type does not have asCharacterString" do
      let(:type_class) do
        instance_double(
          Lutaml::Uml::Class,
          as_character_string?: false
        )
      end

      before do
        allow(xsd_builder).to receive(:find_class)
          .with("SomeType")
          .and_return(type_class)

        # Mock PropertyTypeMapper
        property_type_mapper = class_double("PropertyTypeMapper")
        stub_const(
          "Lutaml::Klin::RuleProcessors::ClassRules::SuppressProcessor::PropertyTypeMapper", property_type_mapper
        )
        allow(property_type_mapper).to receive(:map_property_type)
      end

      it "maps property type normally" do
        property_type_mapper = Lutaml::Klin::RuleProcessors::ClassRules::SuppressProcessor::PropertyTypeMapper
        expect(property_type_mapper).to receive(:map_property_type)
          .with(element, property, parent_class, xsd_builder, config)
        described_class.set_property_type(element, property, parent_class,
                                          xsd_builder, config)
      end
    end
  end
end
