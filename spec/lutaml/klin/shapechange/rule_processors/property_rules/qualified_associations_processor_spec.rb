# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/qualified_associations_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::QualifiedAssociationsProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }
  let(:xsd_doc) { double("XsdDocument") }
  let(:property_type_element) { double("PropertyTypeElement") }
  let(:attr_element) { double("AttributeElement") }
  let(:model) { double("Model") }

  let(:context) do
    {
      xsd_document: xsd_doc,
      property_type_element: property_type_element,
      config: config,
      model: model
    }
  end

  before do
    allow(xsd_doc).to receive(:create_element).with("attribute").and_return(attr_element)
    allow(xsd_doc).to receive(:add_attribute)
    allow(property_type_element).to receive(:appendChild)
  end

  describe "#process" do
    context "when processing association with string qualifier" do
      let(:qualifier) { double("Qualifier", name: "role", type: "String") }
      let(:reverse_property) do
        double(
          "ReverseProperty",
          is_navigable?: true,
          qualifiers: [qualifier]
        )
      end
      let(:property) do
        double(
          "Property",
          name: "connectedTo",
          is_attribute?: false,
          is_navigable?: true,
          reverse_property: reverse_property,
          encoding_rule: "xsd"
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-qualified-associations", property)
          .and_return(true)
        allow(config).to receive(:type_map_entry)
          .with("String", "xsd")
          .and_return(target_type: "string", xml_type_content: "simple/simple")
      end

      it "adds qualifier attribute with string type" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "name", "role")
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "type", "string")
        expect(property_type_element).to receive(:appendChild)
          .with(attr_element)

        processor.process(property, context)
      end
    end

    context "when processing association with enumeration qualifier" do
      let(:enum_class) do
        double(
          "EnumClass",
          category: "ENUMERATION",
          qname: "ConnectionType"
        )
      end
      let(:qualifier) do
        double("Qualifier", name: "type", type: "ConnectionType")
      end
      let(:reverse_property) do
        double(
          "ReverseProperty",
          is_navigable?: true,
          qualifiers: [qualifier]
        )
      end
      let(:property) do
        double(
          "Property",
          name: "related",
          is_attribute?: false,
          is_navigable?: true,
          reverse_property: reverse_property,
          encoding_rule: "xsd"
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-qualified-associations", property)
          .and_return(true)
        allow(config).to receive(:type_map_entry)
          .with("ConnectionType", "xsd")
          .and_return(nil)
        allow(model).to receive(:class_by_name)
          .with("ConnectionType")
          .and_return(enum_class)
      end

      it "adds qualifier attribute with enumeration type" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "name", "type")
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "type", "ConnectionTypeType")
        expect(property_type_element).to receive(:appendChild)
          .with(attr_element)

        processor.process(property, context)
      end
    end

    context "when processing association with code list qualifier" do
      let(:codelist_class) do
        double(
          "CodeListClass",
          category: "CODELIST",
          qname: "Category"
        )
      end
      let(:qualifier) do
        double("Qualifier", name: "category", type: "Category")
      end
      let(:reverse_property) do
        double(
          "ReverseProperty",
          is_navigable?: true,
          qualifiers: [qualifier]
        )
      end
      let(:property) do
        double(
          "Property",
          name: "relatedItems",
          is_attribute?: false,
          is_navigable?: true,
          reverse_property: reverse_property,
          encoding_rule: "xsd"
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-qualified-associations", property)
          .and_return(true)
        allow(config).to receive(:type_map_entry)
          .with("Category", "xsd")
          .and_return(nil)
        allow(model).to receive(:class_by_name)
          .with("Category")
          .and_return(codelist_class)
      end

      it "adds qualifier attribute with anyURI type" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "name", "category")
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "type", "anyURI")
        expect(property_type_element).to receive(:appendChild)
          .with(attr_element)

        processor.process(property, context)
      end
    end

    context "when processing association with multiple qualifiers" do
      let(:qualifier1) { double("Qualifier", name: "distance", type: "Real") }
      let(:qualifier2) do
        double("Qualifier", name: "direction", type: "String")
      end
      let(:reverse_property) do
        double(
          "ReverseProperty",
          is_navigable?: true,
          qualifiers: [qualifier1, qualifier2]
        )
      end
      let(:property) do
        double(
          "Property",
          name: "neighbors",
          is_attribute?: false,
          is_navigable?: true,
          reverse_property: reverse_property,
          encoding_rule: "xsd"
        )
      end
      let(:attr_element2) { double("AttributeElement2") }

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-qualified-associations", property)
          .and_return(true)
        allow(config).to receive(:type_map_entry)
          .with("Real", "xsd")
          .and_return(target_type: "double", xml_type_content: "simple/simple")
        allow(config).to receive(:type_map_entry)
          .with("String", "xsd")
          .and_return(target_type: "string", xml_type_content: "simple/simple")
        allow(xsd_doc).to receive(:create_element)
          .with("attribute")
          .and_return(attr_element, attr_element2)
      end

      it "adds multiple qualifier attributes" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "name", "distance")
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "type", "double")
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element2, "name", "direction")
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element2, "type", "string")
        expect(property_type_element).to receive(:appendChild)
          .with(attr_element)
        expect(property_type_element).to receive(:appendChild)
          .with(attr_element2)

        processor.process(property, context)
      end
    end

    context "when processing qualifier without type" do
      let(:qualifier) { double("Qualifier", name: "tag", type: nil) }
      let(:reverse_property) do
        double(
          "ReverseProperty",
          is_navigable?: true,
          qualifiers: [qualifier]
        )
      end
      let(:property) do
        double(
          "Property",
          name: "related",
          is_attribute?: false,
          is_navigable?: true,
          reverse_property: reverse_property,
          encoding_rule: "xsd"
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-qualified-associations", property)
          .and_return(true)
      end

      it "defaults to string type" do
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "name", "tag")
        expect(xsd_doc).to receive(:add_attribute)
          .with(attr_element, "type", "string")
        expect(property_type_element).to receive(:appendChild)
          .with(attr_element)

        processor.process(property, context)
      end
    end

    context "when property is an attribute" do
      let(:property) do
        double(
          "Property",
          name: "attr",
          is_attribute?: true,
          is_navigable?: true
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-qualified-associations", property)
          .and_return(true)
      end

      it "does not process qualifiers" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(property_type_element).not_to receive(:appendChild)

        processor.process(property, context)
      end
    end

    context "when property has no reverse property" do
      let(:property) do
        double(
          "Property",
          name: "unidirectional",
          is_attribute?: false,
          is_navigable?: true,
          reverse_property: nil
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-qualified-associations", property)
          .and_return(true)
      end

      it "does not process qualifiers" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(property_type_element).not_to receive(:appendChild)

        processor.process(property, context)
      end
    end

    context "when reverse property has no qualifiers" do
      let(:reverse_property) do
        double(
          "ReverseProperty",
          is_navigable?: true,
          qualifiers: []
        )
      end
      let(:property) do
        double(
          "Property",
          name: "simple",
          is_attribute?: false,
          is_navigable?: true,
          reverse_property: reverse_property
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-prop-qualified-associations", property)
          .and_return(true)
      end

      it "does not process qualifiers" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(property_type_element).not_to receive(:appendChild)

        processor.process(property, context)
      end
    end
  end
end
