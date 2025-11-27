# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/no_abstract_classes_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::NoAbstractClassesProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { double("Config") }
  let(:processor) { described_class.new(rule_checker, config) }

  describe "#process" do
    let(:context) { {} }

    before do
      allow(rule_checker).to receive(:applies?).and_return(true)
    end

    context "when class is abstract" do
      let(:abstract_class) do
        double("AbstractClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:is_abstract?)
                                           .and_return(true)
          allow(c).to receive(:is_abstract?).and_return(true)
        end
      end

      it "marks context to skip object element creation" do
        expect(processor.process(abstract_class, context)).to be true
        expect(context[:skip_object_element]).to be true
      end

      it "marks context to skip property processing" do
        expect(processor.process(abstract_class, context)).to be true
        expect(context[:skip_property_processing]).to be true
      end
    end

    context "when class is concrete" do
      let(:concrete_class) do
        double("ConcreteClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:is_abstract?)
                                           .and_return(true)
          allow(c).to receive(:is_abstract?).and_return(false)
        end
      end

      it "does not mark context to skip processing" do
        expect(processor.process(concrete_class, context)).to be true
        expect(context[:skip_object_element]).to be_nil
        expect(context[:skip_property_processing]).to be_nil
      end
    end

    context "when class does not respond to is_abstract?" do
      let(:unknown_class) do
        double("UnknownClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:is_abstract?)
                                           .and_return(false)
        end
      end

      it "does not mark context to skip processing" do
        expect(processor.process(unknown_class, context)).to be true
        expect(context[:skip_object_element]).to be_nil
      end
    end

    context "when rule does not apply" do
      let(:abstract_class) do
        double("AbstractClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:is_abstract?)
                                           .and_return(true)
          allow(c).to receive(:is_abstract?).and_return(true)
        end
      end

      before do
        allow(rule_checker).to receive(:applies?).and_return(false)
      end

      it "returns false" do
        expect(processor.process(abstract_class, context)).to be false
        expect(context[:skip_object_element]).to be_nil
      end
    end
  end

  describe "#find_concrete_subtypes" do
    let(:model) { double("Model") }
    let(:context) { { model: model } }

    before do
      allow(rule_checker).to receive(:applies?).and_return(true)
    end

    context "with simple subtype hierarchy" do
      let(:concrete1) do
        double("Concrete1").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:is_abstract?).and_return(true)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:is_abstract?).and_return(false)
          allow(c).to receive(:stereotype).with("mixin").and_return(false)
        end
      end

      let(:concrete2) do
        double("Concrete2").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:is_abstract?).and_return(true)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:is_abstract?).and_return(false)
          allow(c).to receive(:stereotype).with("mixin").and_return(false)
        end
      end

      let(:abstract_class) do
        double("AbstractClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:subtypes).and_return(true)
          allow(c).to receive(:subtypes).and_return(%w[id1 id2])
        end
      end

      before do
        allow(model).to receive(:class_by_id).with("id1")
                                             .and_return(concrete1)
        allow(model).to receive(:class_by_id).with("id2")
                                             .and_return(concrete2)
      end

      it "returns all concrete subtypes" do
        subtypes = processor.send(:find_concrete_subtypes, abstract_class,
                                  context)
        expect(subtypes).to contain_exactly(concrete1, concrete2)
      end
    end

    context "with nested abstract subtypes" do
      let(:concrete) do
        double("Concrete").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:is_abstract?).and_return(true)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:is_abstract?).and_return(false)
          allow(c).to receive(:stereotype).with("mixin").and_return(false)
        end
      end

      let(:abstract_subtype) do
        double("AbstractSubtype").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:is_abstract?).and_return(true)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:respond_to?).with(:subtypes).and_return(true)
          allow(c).to receive(:is_abstract?).and_return(true)
          allow(c).to receive(:stereotype).with("mixin").and_return(false)
          allow(c).to receive(:subtypes).and_return(["id2"])
        end
      end

      let(:abstract_class) do
        double("AbstractClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:subtypes).and_return(true)
          allow(c).to receive(:subtypes).and_return(["id1"])
        end
      end

      before do
        allow(model).to receive(:class_by_id).with("id1")
                                             .and_return(abstract_subtype)
        allow(model).to receive(:class_by_id).with("id2")
                                             .and_return(concrete)
      end

      it "recursively finds concrete subtypes" do
        subtypes = processor.send(:find_concrete_subtypes, abstract_class,
                                  context)
        expect(subtypes).to contain_exactly(concrete)
      end
    end

    context "with mixin subtype" do
      let(:concrete) do
        double("Concrete").tap do |c|
          allow(c).to receive(:respond_to?).and_return(false)
          allow(c).to receive(:respond_to?).with(:is_abstract?).and_return(true)
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:respond_to?).with(:category).and_return(false)
          allow(c).to receive(:is_abstract?).and_return(false)
          allow(c).to receive(:stereotype).with("mixin").and_return(false)
        end
      end

      let(:mixin_subtype) do
        double("MixinSubtype").tap do |c|
          allow(c).to receive(:respond_to?).with(:stereotype).and_return(true)
          allow(c).to receive(:stereotype).with("mixin").and_return(true)
          allow(c).to receive(:respond_to?).with(:subtypes).and_return(true)
          allow(c).to receive(:subtypes).and_return(["id2"])
        end
      end

      let(:abstract_class) do
        double("AbstractClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:subtypes).and_return(true)
          allow(c).to receive(:subtypes).and_return(["id1"])
        end
      end

      before do
        allow(model).to receive(:class_by_id).with("id1")
                                             .and_return(mixin_subtype)
        allow(model).to receive(:class_by_id).with("id2")
                                             .and_return(concrete)
      end

      it "skips mixin and finds concrete subtypes" do
        subtypes = processor.send(:find_concrete_subtypes, abstract_class,
                                  context)
        expect(subtypes).to contain_exactly(concrete)
      end
    end

    context "with no subtypes" do
      let(:abstract_class) do
        double("AbstractClass").tap do |c|
          allow(c).to receive(:respond_to?).with(:subtypes).and_return(true)
          allow(c).to receive(:subtypes).and_return([])
        end
      end

      it "returns empty array" do
        subtypes = processor.send(:find_concrete_subtypes, abstract_class,
                                  context)
        expect(subtypes).to be_empty
      end
    end
  end
end
