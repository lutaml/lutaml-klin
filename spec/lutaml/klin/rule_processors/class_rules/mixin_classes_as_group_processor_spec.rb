# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/class_rules/mixin_classes_as_group_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::ClassRules::MixinClassesAsGroupProcessor do
  let(:config) do
    instance_double(
      Lutaml::Klin::XsdGeneratorConfiguration,
      rule_enabled?: true
    )
  end

  let(:xsd_builder) do
    instance_double(Lutaml::Klin::Builders::XsdDocumentBuilder)
  end

  let(:package) do
    instance_double(
      Lutaml::Uml::Package,
      xmlns: "prefix",
      target_namespace: "http://example.org/ns"
    )
  end

  describe ".applies_to?" do
    context "when all required rules are enabled and class has generalizations" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          generalizations: [double("generalization")]
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-mixin-classes-as-group")
          .and_return(true)
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-mixin-classes")
          .and_return(true)
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-sequence")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.applies_to?(uml_class, config)).to be true
      end
    end

    context "when mixin-classes-as-group rule is disabled" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          generalizations: [double("generalization")]
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-mixin-classes-as-group")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end

    context "when class has no generalizations" do
      let(:uml_class) do
        instance_double(
          Lutaml::Uml::Class,
          generalizations: nil
        )
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end
  end

  describe ".is_mixin_or_abstract?" do
    context "when class is a mixin" do
      let(:mixin_class) do
        instance_double(Lutaml::Uml::Mixin)
      end

      it "returns true" do
        expect(described_class.is_mixin_or_abstract?(mixin_class,
                                                     config)).to be true
      end
    end

    context "when class is abstract with no-abstract-classes rule" do
      let(:abstract_class) do
        instance_double(
          Lutaml::Uml::Class,
          is_abstract?: true
        )
      end

      before do
        allow(abstract_class).to receive(:is_a?)
          .with(Lutaml::Uml::Mixin)
          .and_return(false)
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-abstract-classes")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.is_mixin_or_abstract?(abstract_class,
                                                     config)).to be true
      end
    end

    context "when class is concrete" do
      let(:concrete_class) do
        instance_double(
          Lutaml::Uml::Class,
          is_abstract?: false
        )
      end

      before do
        allow(concrete_class).to receive(:is_a?)
          .with(Lutaml::Uml::Mixin)
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.is_mixin_or_abstract?(concrete_class,
                                                     config)).to be false
      end
    end
  end

  describe ".add_group_references" do
    let(:mixin_class) do
      instance_double(
        Lutaml::Uml::Mixin,
        name: "Identifiable",
        qualified_name: "prefix:Identifiable",
        package: package,
        generalizations: nil
      )
    end

    let(:uml_class) do
      instance_double(
        Lutaml::Uml::Class,
        generalizations: [generalization]
      )
    end

    let(:generalization) do
      instance_double(
        Lutaml::Uml::Generalization,
        general: "Identifiable"
      )
    end

    let(:sequence_element) { double("sequence_element") }
    let(:group_ref_element) { double("group_ref_element") }

    before do
      allow(xsd_builder).to receive(:find_class)
        .with("Identifiable")
        .and_return(mixin_class)
      allow(mixin_class).to receive(:is_a?)
        .with(Lutaml::Uml::Mixin)
        .and_return(true)
      allow(sequence_element).to receive(:add_group_reference)
        .with("prefix:IdentifiableGroup")
        .and_yield(group_ref_element)
      allow(xsd_builder).to receive(:add_import)
    end

    it "adds group reference for mixin supertype" do
      expect(sequence_element).to receive(:add_group_reference)
        .with("prefix:IdentifiableGroup")

      described_class.add_group_references(
        uml_class,
        sequence_element,
        xsd_builder,
        config,
        recursive: false
      )
    end

    it "imports mixin namespace" do
      expect(xsd_builder).to receive(:add_import)
        .with("prefix", "http://example.org/ns")

      described_class.add_group_references(
        uml_class,
        sequence_element,
        xsd_builder,
        config,
        recursive: false
      )
    end

    context "with recursive processing" do
      let(:parent_mixin) do
        instance_double(
          Lutaml::Uml::Mixin,
          name: "ParentMixin",
          qualified_name: "prefix:ParentMixin",
          package: package,
          generalizations: [parent_generalization]
        )
      end

      let(:parent_generalization) do
        instance_double(
          Lutaml::Uml::Generalization,
          general: "GrandparentMixin"
        )
      end

      let(:grandparent_mixin) do
        instance_double(
          Lutaml::Uml::Mixin,
          name: "GrandparentMixin",
          qualified_name: "prefix:GrandparentMixin",
          package: package,
          generalizations: nil
        )
      end

      before do
        allow(mixin_class).to receive(:generalizations).and_return([parent_generalization])
        allow(xsd_builder).to receive(:find_class)
          .with("ParentMixin")
          .and_return(parent_mixin)
        allow(xsd_builder).to receive(:find_class)
          .with("GrandparentMixin")
          .and_return(grandparent_mixin)
        allow(parent_mixin).to receive(:is_a?)
          .with(Lutaml::Uml::Mixin)
          .and_return(true)
        allow(grandparent_mixin).to receive(:is_a?)
          .with(Lutaml::Uml::Mixin)
          .and_return(true)
        allow(sequence_element).to receive(:add_group_reference)
          .and_yield(group_ref_element)
      end

      it "recursively processes mixin hierarchy" do
        expect(sequence_element).to receive(:add_group_reference)
          .with("prefix:IdentifiableGroup")
        expect(sequence_element).to receive(:add_group_reference)
          .with("prefix:ParentMixinGroup")
        expect(sequence_element).to receive(:add_group_reference)
          .with("prefix:GrandparentMixinGroup")

        described_class.add_group_references(
          uml_class,
          sequence_element,
          xsd_builder,
          config,
          recursive: true
        )
      end
    end

    context "with non-mixin supertype and non-mixin-supertypes rule" do
      let(:non_mixin_class) do
        instance_double(
          Lutaml::Uml::Class,
          name: "Feature",
          is_abstract?: false,
          generalizations: nil,
          attributes: [property]
        )
      end

      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          name: "featureProperty"
        )
      end

      before do
        allow(xsd_builder).to receive(:find_class)
          .with("Identifiable")
          .and_return(non_mixin_class)
        allow(non_mixin_class).to receive(:is_a?)
          .with(Lutaml::Uml::Mixin)
          .and_return(false)
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-mixin-classes-non-mixin-supertypes")
          .and_return(true)
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-abstract-classes")
          .and_return(false)

        # Mock PropertyProcessor
        property_processor = class_double("PropertyProcessor")
        stub_const(
          "Lutaml::Klin::RuleProcessors::ClassRules::MixinClassesAsGroupProcessor::PropertyProcessor", property_processor
        )
        allow(property_processor).to receive(:process_property)
      end

      it "processes non-mixin properties inline when recursive" do
        property_processor = Lutaml::Klin::RuleProcessors::ClassRules::MixinClassesAsGroupProcessor::PropertyProcessor
        expect(property_processor).to receive(:process_property)
          .with(property, sequence_element, xsd_builder, config)

        described_class.add_group_references(
          uml_class,
          sequence_element,
          xsd_builder,
          config,
          recursive: true
        )
      end
    end
  end

  describe ".create_mixin_group" do
    let(:mixin_class) do
      instance_double(
        Lutaml::Uml::Mixin,
        name: "Identifiable",
        definition: "Provides identification",
        generalizations: nil,
        attributes: [property1, property2]
      )
    end

    let(:property1) do
      instance_double(
        Lutaml::Uml::Attribute,
        name: "identifier"
      )
    end

    let(:property2) do
      instance_double(
        Lutaml::Uml::Attribute,
        name: "name"
      )
    end

    let(:group_builder) { double("group_builder") }
    let(:annotation_builder) { double("annotation_builder") }
    let(:sequence_builder) { double("sequence_builder") }

    before do
      allow(mixin_class).to receive(:is_a?)
        .with(Lutaml::Uml::Mixin)
        .and_return(true)
      allow(xsd_builder).to receive(:add_group)
        .with("IdentifiableGroup")
        .and_yield(group_builder)
      allow(group_builder).to receive(:add_annotation)
        .and_yield(annotation_builder)
      allow(annotation_builder).to receive(:add_documentation)
      allow(group_builder).to receive(:add_sequence)
        .and_yield(sequence_builder)

      # Mock PropertyProcessor
      property_processor = class_double("PropertyProcessor")
      stub_const(
        "Lutaml::Klin::RuleProcessors::ClassRules::MixinClassesAsGroupProcessor::PropertyProcessor", property_processor
      )
      allow(property_processor).to receive(:process_property)

      allow(config).to receive(:rule_enabled?)
        .with("rule-xsd-cls-mixin-classes")
        .and_return(true)
    end

    it "creates group with correct name" do
      expect(xsd_builder).to receive(:add_group)
        .with("IdentifiableGroup")
      described_class.create_mixin_group(mixin_class, xsd_builder, config)
    end

    it "adds documentation annotation" do
      expect(annotation_builder).to receive(:add_documentation)
        .with("Provides identification")
      described_class.create_mixin_group(mixin_class, xsd_builder, config)
    end

    it "creates sequence for properties" do
      expect(group_builder).to receive(:add_sequence)
      described_class.create_mixin_group(mixin_class, xsd_builder, config)
    end

    it "processes all mixin properties" do
      property_processor = Lutaml::Klin::RuleProcessors::ClassRules::MixinClassesAsGroupProcessor::PropertyProcessor
      expect(property_processor).to receive(:process_property)
        .with(property1, sequence_builder, xsd_builder, config)
      expect(property_processor).to receive(:process_property)
        .with(property2, sequence_builder, xsd_builder, config)
      described_class.create_mixin_group(mixin_class, xsd_builder, config)
    end

    context "when mixin has no definition" do
      let(:mixin_class) do
        instance_double(
          Lutaml::Uml::Mixin,
          name: "Identifiable",
          definition: nil,
          generalizations: nil,
          attributes: []
        )
      end

      it "does not add documentation" do
        expect(annotation_builder).not_to receive(:add_documentation)
        described_class.create_mixin_group(mixin_class, xsd_builder, config)
      end
    end

    context "when class is not a mixin" do
      let(:non_mixin) do
        instance_double(
          Lutaml::Uml::Class,
          name: "Feature"
        )
      end

      before do
        allow(non_mixin).to receive(:is_a?)
          .with(Lutaml::Uml::Mixin)
          .and_return(false)
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-no-abstract-classes")
          .and_return(false)
      end

      it "does not create group" do
        expect(xsd_builder).not_to receive(:add_group)
        described_class.create_mixin_group(non_mixin, xsd_builder, config)
      end
    end
  end

  describe ".add_mixin_group_reference" do
    let(:mixin_class) do
      instance_double(
        Lutaml::Uml::Mixin,
        qualified_name: "prefix:Identifiable",
        package: package
      )
    end

    let(:sequence_element) { double("sequence_element") }
    let(:group_ref_element) { double("group_ref_element") }

    before do
      allow(sequence_element).to receive(:add_group_reference)
        .with("prefix:IdentifiableGroup")
        .and_yield(group_ref_element)
      allow(xsd_builder).to receive(:add_import)
    end

    it "adds group reference" do
      expect(sequence_element).to receive(:add_group_reference)
        .with("prefix:IdentifiableGroup")

      described_class.add_mixin_group_reference(
        mixin_class,
        sequence_element,
        xsd_builder,
        config
      )
    end

    it "imports mixin namespace" do
      expect(xsd_builder).to receive(:add_import)
        .with("prefix", "http://example.org/ns")

      described_class.add_mixin_group_reference(
        mixin_class,
        sequence_element,
        xsd_builder,
        config
      )
    end
  end
end
