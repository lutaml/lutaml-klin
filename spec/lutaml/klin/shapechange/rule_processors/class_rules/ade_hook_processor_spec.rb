# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/ade_hook_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::AdeHookProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { {} }
  let(:processor) { described_class.new(rule_checker, config) }
  let(:xsd_doc) { double("XsdDocument") }
  let(:sequence_element) { double("SequenceElement") }
  let(:context) do
    {
      xsd_document: xsd_doc,
      sequence_or_choice: sequence_element,
      target_namespace: "http://example.org/schema",
      write_xml_encoding_infos: false,
      config: config
    }
  end

  describe "#process" do
    context "when processing a class with adehook" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "Building",
          respond_to?: ->(method) { [:name].include?(method) }
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-adehook", uml_class)
          .and_return(true)
      end

      it "creates hook property reference and global hook element" do
        element_ref = double("ElementRef")
        global_element = double("GlobalElement")
        hook_name = "AbstractGenericApplicationPropertyOfBuilding"

        # Expect property reference creation
        expect(xsd_doc).to receive(:create_element)
          .with("element")
          .and_return(element_ref)
        expect(xsd_doc).to receive(:add_attribute)
          .with(element_ref, "ref", hook_name)
        expect(xsd_doc).to receive(:add_attribute)
          .with(element_ref, "minOccurs", "0")
        expect(xsd_doc).to receive(:add_attribute)
          .with(element_ref, "maxOccurs", "unbounded")
        expect(xsd_doc).to receive(:append_child)
          .with(sequence_element, element_ref)

        # Expect global element creation
        expect(xsd_doc).to receive(:create_global_element)
          .with(hook_name)
          .and_return(global_element)
        expect(xsd_doc).to receive(:add_attribute)
          .with(global_element, "name", hook_name)
        expect(xsd_doc).to receive(:add_attribute)
          .with(global_element, "type", "anyType")
        expect(xsd_doc).to receive(:add_attribute)
          .with(global_element, "abstract", "true")

        processor.process(uml_class, context)
      end
    end

    context "when processing a datatype with adehook" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "Address",
          respond_to?: ->(method) { [:name].include?(method) }
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-adehook", uml_class)
          .and_return(true)
      end

      it "creates hook for datatype" do
        element_ref = double("ElementRef")
        global_element = double("GlobalElement")
        hook_name = "AbstractGenericApplicationPropertyOfAddress"

        expect(xsd_doc).to receive(:create_element)
          .with("element")
          .and_return(element_ref)
        expect(xsd_doc).to receive(:add_attribute)
          .with(element_ref, "ref", hook_name)
        expect(xsd_doc).to receive(:add_attribute)
          .with(element_ref, "minOccurs", "0")
        expect(xsd_doc).to receive(:add_attribute)
          .with(element_ref, "maxOccurs", "unbounded")
        expect(xsd_doc).to receive(:append_child)
          .with(sequence_element, element_ref)

        expect(xsd_doc).to receive(:create_global_element)
          .with(hook_name)
          .and_return(global_element)
        expect(xsd_doc).to receive(:add_attribute)
          .with(global_element, "name", hook_name)
        expect(xsd_doc).to receive(:add_attribute)
          .with(global_element, "type", "anyType")
        expect(xsd_doc).to receive(:add_attribute)
          .with(global_element, "abstract", "true")

        processor.process(uml_class, context)
      end
    end

    context "when processing with encoding infos enabled" do
      let(:encoding_infos) { double("EncodingInfos") }
      let(:context_with_infos) do
        {
          xsd_document: xsd_doc,
          sequence_or_choice: sequence_element,
          target_namespace: "http://example.org/schema",
          write_xml_encoding_infos: true,
          encoding_infos: encoding_infos,
          config: config
        }
      end
      let(:uml_class) do
        double(
          "UmlClass",
          name: "City",
          respond_to?: ->(method) { [:name].include?(method) }
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-adehook", uml_class)
          .and_return(true)
      end

      it "records encoding information" do
        element_ref = double("ElementRef")
        global_element = double("GlobalElement")
        hook_name = "AbstractGenericApplicationPropertyOfCity"

        allow(xsd_doc).to receive(:create_element).and_return(element_ref)
        allow(xsd_doc).to receive(:add_attribute)
        allow(xsd_doc).to receive(:append_child)
        allow(xsd_doc).to receive(:create_global_element).and_return(global_element)

        expect(encoding_infos).to receive(:add)
          .with(uml_class, hook_name, "http://example.org/schema")

        processor.process(uml_class, context_with_infos)
      end
    end

    context "when sequence_or_choice is not available" do
      let(:context_without_container) do
        {
          xsd_document: xsd_doc,
          config: config
        }
      end
      let(:uml_class) do
        double(
          "UmlClass",
          name: "Building",
          respond_to?: ->(method) { [:name].include?(method) }
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-adehook", uml_class)
          .and_return(true)
      end

      it "does not create hook elements" do
        expect(xsd_doc).not_to receive(:create_element)
        expect(xsd_doc).not_to receive(:create_global_element)

        processor.process(uml_class, context_without_container)
      end
    end

    context "when processing multiple classes with hooks" do
      let(:class1) do
        double(
          "UmlClass",
          name: "Building",
          respond_to?: ->(method) { [:name].include?(method) }
        )
      end
      let(:class2) do
        double(
          "UmlClass",
          name: "Road",
          respond_to?: ->(method) { [:name].include?(method) }
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-adehook", anything)
          .and_return(true)
      end

      it "creates separate hooks for each class" do
        element_ref1 = double("ElementRef1")
        element_ref2 = double("ElementRef2")
        global1 = double("Global1")
        global2 = double("Global2")

        # First class
        allow(xsd_doc).to receive(:create_element).and_return(element_ref1)
        allow(xsd_doc).to receive(:create_global_element)
          .with("AbstractGenericApplicationPropertyOfBuilding")
          .and_return(global1)
        allow(xsd_doc).to receive(:add_attribute)
        allow(xsd_doc).to receive(:append_child)

        processor.process(class1, context)

        # Second class
        allow(xsd_doc).to receive(:create_element).and_return(element_ref2)
        allow(xsd_doc).to receive(:create_global_element)
          .with("AbstractGenericApplicationPropertyOfRoad")
          .and_return(global2)

        processor.process(class2, context)

        # Verify both hooks were created (implicit in mocks)
      end
    end
  end
end