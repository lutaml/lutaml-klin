# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/property_rules/metadata_processor"
require "lutaml/klin/shapechange/rule_processors/property_rules/target_element_processor"
require "lutaml/klin/shapechange/rule_processors/property_rules/reverse_property_processor"
require "lutaml/klin/shapechange/rule_processors/property_rules/default_code_space_processor"
require "lutaml/klin/shapechange/rule_processors/property_rules/soft_typed_processor"

RSpec.describe "Property Rules Batch 4" do
  let(:rule_checker) { double("rule_checker") }
  let(:config) { double("config") }
  let(:xsd_doc) { double("xsd_document") }
  let(:model) { double("model") }

  # Common mocks for element creation
  let(:element) { double("element", add_child: nil) }
  let(:annotation) { double("annotation", add_child: nil) }
  let(:appinfo) { double("appinfo", add_child: nil) }

  before do
    allow(xsd_doc).to receive(:create_element).and_return(element)
    allow(xsd_doc).to receive(:add_attribute)
  end

  describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::MetadataProcessor do
    let(:processor) { described_class.new(rule_checker, config) }
    let(:property) { double("property") }
    let(:context) do
      {
        xsd_document: xsd_doc,
        extension_element: element,
      }
    end

    describe "#process" do
      context "when property has metadata flag" do
        before do
          allow(rule_checker).to receive(:applies?)
            .with("rule-xsd-prop-metadata", property)
            .and_return(true)
          allow(property).to receive(:property_metadata?).and_return(true)
        end

        it "adds metadata attribute" do
          expect(xsd_doc).to receive(:create_element).with("attribute")
          expect(xsd_doc).to receive(:add_attribute).with(element, "name", "metadata")
          expect(xsd_doc).to receive(:add_attribute).with(element, "type", "anyURI")

          processor.process(property, context)
        end
      end

      context "when property does not have metadata flag" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:property_metadata?).and_return(false)
        end

        it "does not add metadata attribute" do
          expect(xsd_doc).not_to receive(:add_attribute).with(anything, "name", "metadata")

          processor.process(property, context)
        end
      end

      context "when no parent element available" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:property_metadata?).and_return(true)
        end

        it "does not add attribute" do
          context.delete(:extension_element)

          expect(element).not_to receive(:add_child)

          processor.process(property, context)
        end
      end
    end
  end

  describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::TargetElementProcessor do
    let(:processor) { described_class.new(rule_checker, config) }
    let(:property) { double("property") }
    let(:value_class) { double("value_class") }
    let(:type_info) { double("type_info", id: "123", name: "Building") }

    let(:context) do
      {
        xsd_document: xsd_doc,
        gml_namespace: "http://www.opengis.net/gml/3.2",
        model: model,
        annotation_element: annotation,
        appinfo_element: appinfo,
      }
    end

    describe "#process" do
      context "when property is by-reference to a feature" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:inline_or_by_reference).and_return("byreference")
          allow(property).to receive(:type).and_return(type_info)
          allow(model).to receive(:class_by_id).with("123").and_return(value_class)
          allow(value_class).to receive(:category).and_return("FEATURE")
          allow(value_class).to receive(:qname).and_return("app:Building")
          allow(element).to receive(:content=)
        end

        it "adds targetElement annotation" do
          expect(xsd_doc).to receive(:create_element).with("gml:targetElement", anything)
          expect(element).to receive(:content=).with("app:Building")

          processor.process(property, context)
        end
      end

      context "when property type is code list" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:inline_or_by_reference).and_return("byreference")
          allow(property).to receive(:type).and_return(type_info)
          allow(model).to receive(:class_by_id).with("123").and_return(value_class)
          allow(value_class).to receive(:category).and_return("CODELIST")
        end

        it "does not add targetElement" do
          expect(appinfo).not_to receive(:add_child)

          processor.process(property, context)
        end
      end

      context "when not GML 3.2" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          context[:gml_namespace] = "http://www.opengis.net/gml"
        end

        it "does not add targetElement" do
          expect(appinfo).not_to receive(:add_child)

          processor.process(property, context)
        end
      end
    end
  end

  describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::ReversePropertyProcessor do
    let(:processor) { described_class.new(rule_checker, config) }
    let(:property) { double("property") }
    let(:reverse_property) { double("reverse_property") }

    let(:context) do
      {
        xsd_document: xsd_doc,
        gml_namespace: "http://www.opengis.net/gml/3.2",
        annotation_element: annotation,
        appinfo_element: appinfo,
      }
    end

    describe "#process" do
      context "when property has navigable reverse property" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:reverse_property).and_return(reverse_property)
          allow(reverse_property).to receive(:navigable?).and_return(true)
          allow(reverse_property).to receive(:name).and_return("building")
          allow(element).to receive(:content=)
        end

        it "adds reversePropertyName annotation" do
          expect(xsd_doc).to receive(:create_element).with("gml:reversePropertyName", anything)
          expect(element).to receive(:content=).with("building")

          processor.process(property, context)
        end
      end

      context "when reverse property is not navigable" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:reverse_property).and_return(reverse_property)
          allow(reverse_property).to receive(:navigable?).and_return(false)
        end

        it "does not add annotation" do
          expect(appinfo).not_to receive(:add_child)

          processor.process(property, context)
        end
      end

      context "when no reverse property" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:reverse_property).and_return(nil)
        end

        it "does not add annotation" do
          expect(appinfo).not_to receive(:add_child)

          processor.process(property, context)
        end
      end
    end
  end

  describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::DefaultCodeSpaceProcessor do
    let(:processor) { described_class.new(rule_checker, config) }
    let(:property) { double("property") }

    let(:context) do
      {
        xsd_document: xsd_doc,
        gml_namespace: "http://www.opengis.net/gml/3.2",
        annotation_element: annotation,
        appinfo_element: appinfo,
      }
    end

    describe "#process" do
      context "when property has defaultCodeSpace" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:default_code_space).and_return("http://example.org/codelists/colors.xml")
          allow(element).to receive(:content=)
        end

        it "adds defaultCodeSpace annotation" do
          expect(xsd_doc).to receive(:create_element).with("gml:defaultCodeSpace", anything)
          expect(element).to receive(:content=).with("http://example.org/codelists/colors.xml")

          processor.process(property, context)
        end
      end

      context "when defaultCodeSpace is empty" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:default_code_space).and_return("")
        end

        it "does not add annotation" do
          expect(appinfo).not_to receive(:add_child)

          processor.process(property, context)
        end
      end

      context "when no defaultCodeSpace" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:default_code_space).and_return(nil)
        end

        it "does not add annotation" do
          expect(appinfo).not_to receive(:add_child)

          processor.process(property, context)
        end
      end
    end
  end

  describe Lutaml::Klin::Shapechange::RuleProcessors::PropertyRules::SoftTypedProcessor do
    let(:processor) { described_class.new(rule_checker, config) }
    let(:property) { double("property") }
    let(:tag) { double("tag", name: "soft-typed", value: "true") }

    let(:context) do
      {
        xsd_document: xsd_doc,
        extension_element: element,
      }
    end

    describe "#process" do
      context "when property has soft-typed tag set to true" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:tags).and_return([tag])
        end

        it "adds name attribute with required NCName type" do
          expect(xsd_doc).to receive(:create_element).with("attribute")
          expect(xsd_doc).to receive(:add_attribute).with(element, "name", "name")
          expect(xsd_doc).to receive(:add_attribute).with(element, "type", "NCName")
          expect(xsd_doc).to receive(:add_attribute).with(element, "use", "required")

          processor.process(property, context)
        end
      end

      context "when soft-typed is false" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(tag).to receive(:value).and_return("false")
          allow(property).to receive(:tags).and_return([tag])
        end

        it "does not add name attribute" do
          expect(xsd_doc).not_to receive(:add_attribute).with(anything, "name", "name")

          processor.process(property, context)
        end
      end

      context "when no soft-typed tag" do
        before do
          allow(rule_checker).to receive(:applies?).and_return(true)
          allow(property).to receive(:tags).and_return([])
        end

        it "does not add name attribute" do
          expect(xsd_doc).not_to receive(:add_attribute).with(anything, "name", "name")

          processor.process(property, context)
        end
      end
    end
  end
end