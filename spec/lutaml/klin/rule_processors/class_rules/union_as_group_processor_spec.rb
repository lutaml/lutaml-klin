# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/class_rules/union_as_group_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::ClassRules::UnionAsGroupProcessor do
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
    context "when class is a union with asGroup enabled" do
      let(:union_class) do
        instance_double(
          Lutaml::Uml::Union,
          as_group: true
        )
      end

      it "returns true" do
        expect(described_class.applies_to?(union_class, config)).to be true
      end
    end

    context "when class is a union without asGroup" do
      let(:union_class) do
        instance_double(
          Lutaml::Uml::Union,
          as_group: false
        )
      end

      it "returns false" do
        expect(described_class.applies_to?(union_class, config)).to be false
      end
    end

    context "when class is not a union" do
      let(:data_type) do
        instance_double(Lutaml::Uml::DataType)
      end

      it "returns false" do
        expect(described_class.applies_to?(data_type, config)).to be false
      end
    end

    context "when rule is disabled" do
      let(:union_class) do
        instance_double(
          Lutaml::Uml::Union,
          as_group: true
        )
      end

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asGroup")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(union_class, config)).to be false
      end
    end
  end

  describe ".process_class" do
    let(:union_class) do
      instance_double(
        Lutaml::Uml::Union,
        name: "GeometryUnion",
        definition: "Union of geometry types",
        as_group: true,
        attributes: union_options
      )
    end

    let(:point_class) do
      instance_double(
        Lutaml::Uml::Class,
        name: "Point",
        package: package
      )
    end

    let(:curve_class) do
      instance_double(
        Lutaml::Uml::Class,
        name: "Curve",
        package: package
      )
    end

    let(:union_options) do
      [
        instance_double(
          Lutaml::Uml::Attribute,
          name: "point",
          type: "Point"
        ),
        instance_double(
          Lutaml::Uml::Attribute,
          name: "curve",
          type: "Curve"
        )
      ]
    end

    let(:group_builder) { double("group_builder") }
    let(:annotation_builder) { double("annotation_builder") }
    let(:choice_builder) { double("choice_builder") }

    before do
      allow(xsd_builder).to receive(:add_group)
        .with("GeometryUnionGroup")
        .and_yield(group_builder)
      allow(group_builder).to receive(:add_annotation).and_yield(annotation_builder)
      allow(annotation_builder).to receive(:add_documentation)
      allow(group_builder).to receive(:add_choice).and_yield(choice_builder)

      allow(xsd_builder).to receive(:find_class).with("Point").and_return(point_class)
      allow(xsd_builder).to receive(:find_class).with("Curve").and_return(curve_class)
      allow(xsd_builder).to receive(:map_to_element).and_return("gml:Point",
                                                                "gml:Curve")
      allow(choice_builder).to receive(:add_element_reference).and_yield(double("elem_ref"))
      allow(xsd_builder).to receive(:add_import)
    end

    it "creates xs:group with correct name" do
      expect(xsd_builder).to receive(:add_group).with("GeometryUnionGroup")
      described_class.process_class(union_class, xsd_builder, config)
    end

    it "adds documentation annotation" do
      expect(annotation_builder).to receive(:add_documentation)
        .with("Union of geometry types")
      described_class.process_class(union_class, xsd_builder, config)
    end

    it "creates choice container" do
      expect(group_builder).to receive(:add_choice)
      described_class.process_class(union_class, xsd_builder, config)
    end

    it "adds element references for each union option" do
      expect(choice_builder).to receive(:add_element_reference)
        .with("gml:Point")
      expect(choice_builder).to receive(:add_element_reference)
        .with("gml:Curve")
      described_class.process_class(union_class, xsd_builder, config)
    end

    it "imports namespaces for option types" do
      expect(xsd_builder).to receive(:add_import)
        .with("prefix", "http://example.org/ns")
        .at_least(:once)
      described_class.process_class(union_class, xsd_builder, config)
    end

    context "when union has no definition" do
      let(:union_class) do
        instance_double(
          Lutaml::Uml::Union,
          name: "GeometryUnion",
          definition: nil,
          as_group: true,
          attributes: []
        )
      end

      it "does not add documentation" do
        expect(annotation_builder).not_to receive(:add_documentation)
        described_class.process_class(union_class, xsd_builder, config)
      end
    end
  end

  describe ".process_property" do
    let(:type_class) do
      instance_double(
        Lutaml::Uml::Union,
        name: "GeometryUnion",
        qualified_name: "prefix:GeometryUnion",
        as_group: true,
        package: package
      )
    end

    let(:property) do
      instance_double(
        Lutaml::Uml::Attribute,
        name: "geometry",
        type: "GeometryUnion",
        definition: "The geometry property",
        cardinality: { min: 0, max: -1 }
      )
    end

    let(:parent_element) { double("parent_element") }
    let(:group_ref_builder) { double("group_ref_builder") }
    let(:annotation_builder) { double("annotation_builder") }

    before do
      allow(xsd_builder).to receive(:find_class)
        .with("GeometryUnion")
        .and_return(type_class)
      allow(parent_element).to receive(:add_group_reference)
        .with("prefix:GeometryUnionGroup")
        .and_yield(group_ref_builder)
      allow(group_ref_builder).to receive(:add_annotation)
        .and_yield(annotation_builder)
      allow(annotation_builder).to receive(:add_documentation)
      allow(group_ref_builder).to receive(:min_occurs=)
      allow(group_ref_builder).to receive(:max_occurs=)
      allow(xsd_builder).to receive(:add_import)
    end

    it "creates group reference with correct name" do
      expect(parent_element).to receive(:add_group_reference)
        .with("prefix:GeometryUnionGroup")
      described_class.process_property(property, parent_element, xsd_builder,
                                       config)
    end

    it "adds property documentation" do
      expect(annotation_builder).to receive(:add_documentation)
        .with("The geometry property")
      described_class.process_property(property, parent_element, xsd_builder,
                                       config)
    end

    it "applies multiplicity constraints" do
      expect(group_ref_builder).to receive(:min_occurs=).with(0)
      expect(group_ref_builder).to receive(:max_occurs=).with("unbounded")
      described_class.process_property(property, parent_element, xsd_builder,
                                       config)
    end

    it "imports type namespace" do
      expect(xsd_builder).to receive(:add_import)
        .with("prefix", "http://example.org/ns")
      described_class.process_property(property, parent_element, xsd_builder,
                                       config)
    end

    context "when type class has no package" do
      let(:type_class) do
        instance_double(
          Lutaml::Uml::Union,
          name: "GeometryUnion",
          as_group: true,
          package: nil
        )
      end

      it "adds error and returns" do
        expect(xsd_builder).to receive(:add_error)
          .with(/no package or namespace/, property)
        expect(parent_element).not_to receive(:add_group_reference)
        described_class.process_property(property, parent_element, xsd_builder,
                                         config)
      end
    end

    context "when type is not a union-as-group" do
      let(:type_class) do
        instance_double(
          Lutaml::Uml::DataType,
          name: "SomeType"
        )
      end

      before do
        allow(type_class).to receive(:is_a?)
          .with(Lutaml::Uml::Union)
          .and_return(false)
      end

      it "does not process the property" do
        expect(parent_element).not_to receive(:add_group_reference)
        described_class.process_property(property, parent_element, xsd_builder,
                                         config)
      end
    end

    context "with required single occurrence" do
      let(:property) do
        instance_double(
          Lutaml::Uml::Attribute,
          name: "geometry",
          type: "GeometryUnion",
          definition: nil,
          cardinality: { min: 1, max: 1 }
        )
      end

      it "does not set multiplicity attributes" do
        expect(group_ref_builder).not_to receive(:min_occurs=)
        expect(group_ref_builder).not_to receive(:max_occurs=)
        described_class.process_property(property, parent_element, xsd_builder,
                                         config)
      end
    end
  end

  describe ".process_union_options" do
    let(:union_class) do
      instance_double(
        Lutaml::Uml::Union,
        attributes: options
      )
    end

    let(:point_class) do
      instance_double(
        Lutaml::Uml::Class,
        package: package
      )
    end

    let(:options) do
      [
        instance_double(
          Lutaml::Uml::Attribute,
          type: "Point"
        )
      ]
    end

    let(:choice_element) { double("choice_element") }
    let(:elem_ref) { double("elem_ref") }

    before do
      allow(xsd_builder).to receive(:find_class)
        .with("Point")
        .and_return(point_class)
      allow(xsd_builder).to receive(:map_to_element)
        .with(point_class)
        .and_return("gml:Point")
      allow(choice_element).to receive(:add_element_reference)
        .with("gml:Point")
        .and_yield(elem_ref)
      allow(xsd_builder).to receive(:add_import)
    end

    it "adds element reference for each option" do
      expect(choice_element).to receive(:add_element_reference)
        .with("gml:Point")
      described_class.process_union_options(
        union_class,
        choice_element,
        xsd_builder,
        config
      )
    end

    it "imports option type namespace" do
      expect(xsd_builder).to receive(:add_import)
        .with("prefix", "http://example.org/ns")
      described_class.process_union_options(
        union_class,
        choice_element,
        xsd_builder,
        config
      )
    end
  end

  describe ".apply_multiplicity" do
    let(:element) { double("element") }

    context "with unbounded max occurs" do
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
  end
end
