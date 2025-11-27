# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/mixin_classes_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::MixinClassesProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe "#process" do
    let(:model) { double("Model") }
    let(:sequence_element) { double("SequenceElement") }
    let(:context) do
      {
        sequence_element: sequence_element,
        model: model,
        rule_checker: rule_checker
      }
    end

    before do
      allow(rule_checker).to receive(:applies?)
        .with("rule-xsd-cls-mixin-classes", anything).and_return(true)
    end

    context "when class has mixin supertype" do
      let(:mixin_property) do
        double("MixinProperty").tap do |p|
          allow(p).to receive(:name).and_return("mixinProp")
        end
      end

      let(:mixin_class) do
        double("MixinClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:stereotype).with("mixin").and_return(true)
          allow(c).to receive(:respond_to?).with(:properties).and_return(true)
          allow(c).to receive(:properties).and_return({ "prop1" => mixin_property })
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:supertypes).and_return([])
        end
      end

      let(:concrete_class) do
        double("ConcreteClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:supertypes).and_return(["mixin_id"])
        end
      end

      before do
        allow(model).to receive(:class_by_id).with("mixin_id")
                                             .and_return(mixin_class)
      end

      it "processes mixin properties" do
        expect(processor.process(concrete_class, context)).to be true
        expect(context[:mixin_properties]).to include(mixin_property)
      end
    end

    context "when class has abstract supertype with no-abstract-classes rule" do
      let(:abstract_property) do
        double("AbstractProperty").tap do |p|
          allow(p).to receive(:name).and_return("abstractProp")
        end
      end

      let(:abstract_class) do
        double("AbstractClass").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:respond_to?).with(:is_abstract?).and_return(true)
          allow(c).to receive(:respond_to?).with(:properties).and_return(true)
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:stereotype).with("mixin").and_return(false)
          allow(c).to receive(:is_abstract?).and_return(true)
          allow(c).to receive(:properties).and_return({ "prop1" => abstract_property })
          allow(c).to receive(:supertypes).and_return([])
        end
      end

      let(:concrete_class) do
        double("ConcreteClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:supertypes).and_return(["abstract_id"])
        end
      end

      before do
        allow(model).to receive(:class_by_id).with("abstract_id")
                                             .and_return(abstract_class)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-no-abstract-classes", abstract_class)
          .and_return(true)
      end

      it "processes abstract class properties as mixin" do
        expect(processor.process(concrete_class, context)).to be true
        expect(context[:mixin_properties]).to include(abstract_property)
      end
    end

    context "when class has nested mixin hierarchy" do
      let(:base_property) do
        double("BaseProperty").tap do |p|
          allow(p).to receive(:name).and_return("baseProp")
        end
      end

      let(:extended_property) do
        double("ExtendedProperty").tap do |p|
          allow(p).to receive(:name).and_return("extendedProp")
        end
      end

      let(:base_mixin) do
        double("BaseMixin").tap do |c|
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:stereotype).with("mixin").and_return(true)
          allow(c).to receive(:respond_to?).with(:properties).and_return(true)
          allow(c).to receive(:properties).and_return({ "base" => base_property })
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:supertypes).and_return([])
        end
      end

      let(:extended_mixin) do
        double("ExtendedMixin").tap do |c|
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:stereotype).with("mixin").and_return(true)
          allow(c).to receive(:respond_to?).with(:properties).and_return(true)
          allow(c).to receive(:properties).and_return({ "extended" => extended_property })
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:supertypes).and_return(["base_id"])
        end
      end

      let(:concrete_class) do
        double("ConcreteClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:supertypes).and_return(["extended_id"])
        end
      end

      before do
        allow(model).to receive(:class_by_id).with("base_id")
                                             .and_return(base_mixin)
        allow(model).to receive(:class_by_id).with("extended_id")
                                             .and_return(extended_mixin)
      end

      it "recursively processes all mixin properties" do
        expect(processor.process(concrete_class, context)).to be true
        expect(context[:mixin_properties]).to include(extended_property)
        expect(context[:mixin_properties]).to include(base_property)
      end
    end

    context "when class has no mixin supertypes" do
      let(:regular_supertype) do
        double("RegularSupertype").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:respond_to?).with(:is_abstract?).and_return(true)
          allow(c).to receive(:stereotype).with("mixin").and_return(false)
          allow(c).to receive(:is_abstract?).and_return(false)
        end
      end

      let(:concrete_class) do
        double("ConcreteClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:supertypes).and_return(["regular_id"])
        end
      end

      before do
        allow(model).to receive(:class_by_id).with("regular_id")
                                             .and_return(regular_supertype)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-no-abstract-classes", regular_supertype)
          .and_return(false)
      end

      it "does not process regular supertype properties" do
        expect(processor.process(concrete_class, context)).to be true
        expect(context[:mixin_properties]).to be_nil
      end
    end

    context "when class has no supertypes" do
      let(:standalone_class) do
        double("StandaloneClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:supertypes).and_return(true)
          allow(c).to receive(:supertypes).and_return([])
        end
      end

      it "processes without error" do
        expect(processor.process(standalone_class, context)).to be true
        expect(context[:mixin_properties]).to be_nil
      end
    end

    context "when sequence element is not in context" do
      let(:concrete_class) { double("ConcreteClass") }
      let(:context_without_sequence) { { model: model } }

      it "does not process" do
        expect(processor.process(concrete_class,
                                 context_without_sequence)).to be true
        expect(context_without_sequence[:mixin_properties]).to be_nil
      end
    end

    context "when rule does not apply" do
      let(:concrete_class) { double("ConcreteClass") }

      before do
        allow(rule_checker).to receive(:applies?).and_return(false)
      end

      it "returns false" do
        expect(processor.process(concrete_class, context)).to be false
      end
    end
  end
end
