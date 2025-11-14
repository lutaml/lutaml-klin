# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_checker"
require "lutaml/klin/shapechange/rule_registry"
require "lutaml/klin/shapechange/models/config/encoding_rule"
require "lutaml/klin/shapechange/models/rule_definition"

RSpec.describe Lutaml::Klin::Shapechange::RuleChecker do
  let(:registry) { Lutaml::Klin::Shapechange::RuleRegistry.new }
  let(:checker) { described_class.new(registry, "iso19136_2007") }

  let(:encoding_rule) do
    Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
      er.name = "iso19136_2007"
      er.rules = ["rule-xsd-cls-type", "rule-xsd-cls-codelist"]
    end
  end

  # Mock UML class with stereotype
  let(:feature_type_class) do
    double("UMLClass", stereotype: ["FeatureType"], respond_to?: true)
  end

  let(:data_type_class) do
    double("UMLClass", stereotype: ["DataType"], respond_to?: true)
  end

  let(:codelist_class) do
    double("UMLClass", stereotype: ["CodeList"], respond_to?: true)
  end

  let(:plain_class) do
    double("UMLClass", stereotype: [], respond_to?: true)
  end

  let(:uml_property) do
    double("UMLProperty", respond_to?: true)
  end

  let(:uml_package) do
    double("UMLPackage", respond_to?: true)
  end

  before do
    registry.register_encoding_rule(encoding_rule)
  end

  describe "#initialize" do
    it "stores registry and encoding rule name" do
      expect(checker.instance_variable_get(:@registry)).to eq(registry)
      expect(checker.instance_variable_get(:@encoding_rule)).to eq("iso19136_2007")
    end
  end

  describe "#applies?" do
    context "when rule is not in encoding rule set" do
      it "returns false" do
        expect(checker.applies?("non-existent-rule", feature_type_class)).to be false
      end
    end

    context "when rule is in encoding rule set" do
      context "when rule definition does not exist" do
        it "returns true (assumes applies)" do
          expect(checker.applies?("rule-xsd-cls-type", feature_type_class)).to be true
        end
      end

      context "when rule definition exists" do
        context "with class scope" do
          let(:class_rule) do
            Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
              rd.id = "rule-xsd-cls-type"
              rd.scope = "class"
              rd.category = "required"
              rd.description = "Generate complexType for classes"
              rd.applies_to = []
            end
          end

          before do
            registry.register_rule_definition(class_rule)
          end

          context "when applies_to is empty" do
            it "returns true for any class" do
              expect(checker.applies?("rule-xsd-cls-type", feature_type_class)).to be true
              expect(checker.applies?("rule-xsd-cls-type", data_type_class)).to be true
              expect(checker.applies?("rule-xsd-cls-type", plain_class)).to be true
            end
          end

          context "when applies_to specifies stereotypes" do
            before do
              class_rule.applies_to = ["FeatureType", "DataType"]
            end

            it "returns true for matching stereotypes" do
              expect(checker.applies?("rule-xsd-cls-type", feature_type_class)).to be true
              expect(checker.applies?("rule-xsd-cls-type", data_type_class)).to be true
            end

            it "returns false for non-matching stereotypes" do
              expect(checker.applies?("rule-xsd-cls-type", codelist_class)).to be false
              expect(checker.applies?("rule-xsd-cls-type", plain_class)).to be false
            end
          end

          context "when class has multiple stereotypes" do
            let(:multi_stereotype_class) do
              double("UMLClass",
                     stereotype: ["FeatureType", "AbstractType"],
                     respond_to?: true)
            end

            before do
              class_rule.applies_to = ["FeatureType"]
            end

            it "returns true if any stereotype matches" do
              expect(checker.applies?("rule-xsd-cls-type", multi_stereotype_class)).to be true
            end
          end

          context "when element does not respond to stereotype" do
            let(:non_stereotype_element) do
              double("Element", respond_to?: false)
            end

            before do
              class_rule.applies_to = ["FeatureType"]
            end

            it "returns false" do
              expect(checker.applies?("rule-xsd-cls-type", non_stereotype_element)).to be false
            end
          end
        end

        context "with property scope" do
          let(:property_rule) do
            Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
              rd.id = "rule-xsd-prop-att"
              rd.scope = "property"
              rd.category = "required"
              rd.description = "Generate attribute for properties"
            end
          end

          before do
            registry.register_rule_definition(property_rule)
            encoding_rule.rules << "rule-xsd-prop-att"
          end

          it "returns true for properties" do
            expect(checker.applies?("rule-xsd-prop-att", uml_property)).to be true
          end
        end

        context "with package scope" do
          let(:package_rule) do
            Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
              rd.id = "rule-xsd-pkg-contained"
              rd.scope = "package"
              rd.category = "optional"
              rd.description = "Include contained packages"
            end
          end

          before do
            registry.register_rule_definition(package_rule)
            encoding_rule.rules << "rule-xsd-pkg-contained"
          end

          it "returns true for packages" do
            expect(checker.applies?("rule-xsd-pkg-contained", uml_package)).to be true
          end
        end

        context "with all scope" do
          let(:universal_rule) do
            Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
              rd.id = "rule-xsd-all-naming"
              rd.scope = "all"
              rd.category = "optional"
              rd.description = "Apply naming conventions"
            end
          end

          before do
            registry.register_rule_definition(universal_rule)
            encoding_rule.rules << "rule-xsd-all-naming"
          end

          it "returns true for any element" do
            expect(checker.applies?("rule-xsd-all-naming", feature_type_class)).to be true
            expect(checker.applies?("rule-xsd-all-naming", uml_property)).to be true
            expect(checker.applies?("rule-xsd-all-naming", uml_package)).to be true
          end
        end
      end
    end
  end

  describe "integration with registry inheritance" do
    let(:base_rule) do
      Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "xsd"
        er.rules = ["rule-xsd-base"]
      end
    end

    let(:child_rule) do
      Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "gml"
        er.extends = "xsd"
        er.rules = ["rule-xsd-gml"]
      end
    end

    let(:base_rule_def) do
      Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
        rd.id = "rule-xsd-base"
        rd.scope = "class"
        rd.category = "required"
      end
    end

    let(:child_checker) { described_class.new(registry, "gml") }

    before do
      registry.register_encoding_rule(base_rule)
      registry.register_encoding_rule(child_rule)
      registry.register_rule_definition(base_rule_def)
    end

    it "applies inherited rules from parent encoding rule" do
      expect(child_checker.applies?("rule-xsd-base", feature_type_class)).to be true
    end

    it "applies rules defined in child encoding rule" do
      child_rule_def = Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
        rd.id = "rule-xsd-gml"
        rd.scope = "class"
        rd.category = "optional"
      end
      registry.register_rule_definition(child_rule_def)

      expect(child_checker.applies?("rule-xsd-gml", feature_type_class)).to be true
    end
  end

  describe "edge cases" do
    context "when stereotype is a string instead of array" do
      let(:string_stereotype_class) do
        double("UMLClass", stereotype: "FeatureType", respond_to?: true)
      end

      let(:class_rule) do
        Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
          rd.id = "rule-xsd-cls-type"
          rd.scope = "class"
          rd.applies_to = ["FeatureType"]
        end
      end

      before do
        registry.register_rule_definition(class_rule)
      end

      it "handles string stereotype correctly" do
        expect(checker.applies?("rule-xsd-cls-type", string_stereotype_class)).to be true
      end
    end

    context "when stereotype is nil" do
      let(:nil_stereotype_class) do
        double("UMLClass", stereotype: nil, respond_to?: true)
      end

      let(:class_rule) do
        Lutaml::Klin::Shapechange::RuleDefinition.new.tap do |rd|
          rd.id = "rule-xsd-cls-type"
          rd.scope = "class"
          rd.applies_to = ["FeatureType"]
        end
      end

      before do
        registry.register_rule_definition(class_rule)
      end

      it "returns false when stereotype is required" do
        expect(checker.applies?("rule-xsd-cls-type", nil_stereotype_class)).to be false
      end
    end
  end
end