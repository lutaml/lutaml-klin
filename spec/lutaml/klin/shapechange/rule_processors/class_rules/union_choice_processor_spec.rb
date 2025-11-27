# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/union_choice_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::UnionChoiceProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { {} }
  let(:processor) { described_class.new(rule_checker, config) }
  let(:xsd_doc) { double("XsdDocument") }
  let(:container_element) { double("ContainerElement") }
  let(:context) do
    {
      xsd_document: xsd_doc,
      container_element: container_element,
      config: config
    }
  end

  describe "#process" do
    context "when processing a union with properties (no supertype)" do
      let(:attr1) { double("Attribute", name: "pointValue", navigable?: true) }
      let(:attr2) { double("Attribute", name: "lineValue", navigable?: true) }
      let(:uml_class) do
        double(
          "UmlClass",
          name: "GeometryValue",
          stereotype: ->(name) { name == "union" },
          category: "union",
          respond_to?: lambda do |method|
            %i[stereotype category attributes
               generalizations].include?(method)
          end,
          attributes: [attr1, attr2],
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-union-as-choice", uml_class)
          .and_return(true)
      end

      it "creates a choice element" do
        choice = double("ChoiceElement")
        expect(xsd_doc).to receive(:create_element)
          .with("choice")
          .and_return(choice)

        processor.process(uml_class, context)

        expect(context[:choice_element]).to eq(choice)
      end
    end

    context "when processing a union without properties" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "EmptyUnion",
          stereotype: ->(name) { name == "union" },
          category: "union",
          respond_to?: lambda do |method|
            %i[stereotype category attributes
               generalizations].include?(method)
          end,
          attributes: [],
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-union-as-choice", uml_class)
          .and_return(true)
      end

      it "does not create a choice element" do
        expect(xsd_doc).not_to receive(:create_element)

        processor.process(uml_class, context)

        expect(context[:choice_element]).to be_nil
      end
    end

    context "when processing a union subtype without own properties" do
      let(:supertype_attr) do
        double("Attribute", name: "option1", navigable?: true)
      end
      let(:supertype) do
        double(
          "Supertype",
          name: "BaseUnion",
          stereotype: ->(name) { name == "union" },
          category: "union",
          respond_to?: lambda { |method|
            %i[stereotype category attributes].include?(method)
          },
          attributes: [supertype_attr]
        )
      end
      let(:generalization) { double("Generalization", general: supertype) }
      let(:uml_class) do
        double(
          "UmlClass",
          name: "DerivedUnion",
          stereotype: ->(name) { name == "union" },
          category: "union",
          respond_to?: lambda do |method|
            %i[stereotype category attributes
               generalizations].include?(method)
          end,
          attributes: [],
          generalizations: [generalization]
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-union-as-choice", uml_class)
          .and_return(true)
      end

      it "does not create a choice element (inherits from supertype)" do
        expect(xsd_doc).not_to receive(:create_element)

        processor.process(uml_class, context)

        expect(context[:choice_element]).to be_nil
      end
    end

    context "when processing conflicting union subtypes" do
      let(:supertype_attr) do
        double("Attribute", name: "option1", navigable?: true)
      end
      let(:supertype) do
        double(
          "Supertype",
          name: "BaseUnion",
          stereotype: ->(name) { name == "union" },
          category: "union",
          respond_to?: lambda { |method|
            %i[stereotype category attributes].include?(method)
          },
          attributes: [supertype_attr]
        )
      end
      let(:generalization) { double("Generalization", general: supertype) }
      let(:subtype_attr) do
        double("Attribute", name: "option3", navigable?: true)
      end
      let(:uml_class) do
        double(
          "UmlClass",
          name: "SpecializedUnion",
          stereotype: ->(name) { name == "union" },
          category: "union",
          respond_to?: lambda do |method|
            %i[stereotype category attributes
               generalizations].include?(method)
          end,
          attributes: [subtype_attr],
          generalizations: [generalization]
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-union-as-choice", uml_class)
          .and_return(true)
      end

      it "logs an error and does not create a choice element" do
        expect { processor.process(uml_class, context) }
          .to output(/Error: Union 'SpecializedUnion'/).to_stdout

        expect(xsd_doc).not_to receive(:create_element)
        expect(context[:choice_element]).to be_nil
      end
    end

    context "when processing a non-union class" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "RegularClass",
          stereotype: ->(_name) { false },
          respond_to?: lambda do |method|
            %i[stereotype category generalizations
               attributes].include?(method)
          end,
          category: "datatype",
          generalizations: [],
          attributes: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-union-as-choice", uml_class)
          .and_return(true)
      end

      it "does not process the class" do
        expect(xsd_doc).not_to receive(:create_element)

        processor.process(uml_class, context)

        expect(context[:choice_element]).to be_nil
      end
    end

    context "when container element is not available" do
      let(:attr1) { double("Attribute", name: "value", navigable?: true) }
      let(:uml_class) do
        double(
          "UmlClass",
          name: "TestUnion",
          stereotype: ->(name) { name == "union" },
          category: "union",
          respond_to?: lambda do |method|
            %i[stereotype category attributes
               generalizations].include?(method)
          end,
          attributes: [attr1],
          generalizations: []
        )
      end
      let(:context_without_container) do
        {
          xsd_document: xsd_doc,
          config: config
        }
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-union-as-choice", uml_class)
          .and_return(true)
      end

      it "does not create a choice element" do
        expect(xsd_doc).not_to receive(:create_element)

        processor.process(uml_class, context_without_container)
      end
    end
  end
end
