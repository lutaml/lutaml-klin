# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor"

RSpec.describe Lutaml::Klin::Shapechange::RuleProcessors::ClassRules::BasicTypeProcessor do
  let(:rule_checker) { double("RuleChecker") }
  let(:config) { { "mapEntries" => {} } }
  let(:processor) { described_class.new(rule_checker, config) }
  let(:xsd_doc) { double("XsdDocument") }
  let(:context) { { xsd_document: xsd_doc, config: config } }

  describe "#process" do
    context "when processing a basic type with length restriction" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "RestrictedString",
          tags: [
            double(name: "base", value: "string"),
            double(name: "maxLength", value: "50")
          ],
          respond_to?: ->(method) { [:tags, :generalizations].include?(method) },
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype-list", uml_class)
          .and_return(false)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-local-basictype", uml_class)
          .and_return(false)
      end

      it "creates a simple type with maxLength facet" do
        simple_type = double("SimpleType")
        restriction = double("Restriction")

        expect(xsd_doc).to receive(:add_simple_type)
          .with(name: "RestrictedStringType")
          .and_return(simple_type)
        expect(xsd_doc).to receive(:add_restriction)
          .with(simple_type, base: "string")
          .and_return(restriction)
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "maxLength", "50")

        processor.process(uml_class, context)
      end
    end

    context "when processing a basic type with pattern" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "EmailString",
          tags: [
            double(name: "base", value: "string"),
            double(name: "pattern", value: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          ],
          respond_to?: ->(method) { [:tags, :generalizations].include?(method) },
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype-list", uml_class)
          .and_return(false)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-local-basictype", uml_class)
          .and_return(false)
      end

      it "creates a simple type with pattern facet" do
        simple_type = double("SimpleType")
        restriction = double("Restriction")

        expect(xsd_doc).to receive(:add_simple_type)
          .with(name: "EmailStringType")
          .and_return(simple_type)
        expect(xsd_doc).to receive(:add_restriction)
          .with(simple_type, base: "string")
          .and_return(restriction)
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "pattern", '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')

        processor.process(uml_class, context)
      end
    end

    context "when processing a basic type with range (min/max)" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "PercentageValue",
          tags: [
            double(name: "base", value: "decimal"),
            double(name: "rangeMinimum", value: "0.0"),
            double(name: "rangeMaximum", value: "100.0")
          ],
          respond_to?: ->(method) { [:tags, :generalizations].include?(method) },
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype-list", uml_class)
          .and_return(false)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-local-basictype", uml_class)
          .and_return(false)
      end

      it "creates a simple type with minInclusive and maxInclusive facets" do
        simple_type = double("SimpleType")
        restriction = double("Restriction")

        expect(xsd_doc).to receive(:add_simple_type)
          .with(name: "PercentageValueType")
          .and_return(simple_type)
        expect(xsd_doc).to receive(:add_restriction)
          .with(simple_type, base: "decimal")
          .and_return(restriction)
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "minInclusive", "0.0")
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "maxInclusive", "100.0")

        processor.process(uml_class, context)
      end
    end

    context "when processing a basic type with combined facets" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "RestrictedInteger",
          tags: [
            double(name: "base", value: "integer"),
            double(name: "length", value: "10"),
            double(name: "rangeMinimum", value: "0"),
            double(name: "rangeMaximum", value: "9999999999")
          ],
          respond_to?: ->(method) { [:tags, :generalizations].include?(method) },
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype-list", uml_class)
          .and_return(false)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-local-basictype", uml_class)
          .and_return(false)
      end

      it "creates a simple type with multiple facets" do
        simple_type = double("SimpleType")
        restriction = double("Restriction")

        expect(xsd_doc).to receive(:add_simple_type)
          .with(name: "RestrictedIntegerType")
          .and_return(simple_type)
        expect(xsd_doc).to receive(:add_restriction)
          .with(simple_type, base: "integer")
          .and_return(restriction)
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "totalDigits", "10")
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "minInclusive", "0")
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "maxInclusive", "9999999999")

        processor.process(uml_class, context)
      end
    end

    context "when processing a complex type with simple content" do
      let(:supertype) { double("Supertype", name: "SomeComplexType") }
      let(:generalization) { double("Generalization", general: supertype) }
      let(:uml_class) do
        double(
          "UmlClass",
          name: "AnnotatedString",
          tags: [
            double(name: "base", value: "string"),
            double(name: "maxLength", value: "100")
          ],
          respond_to?: ->(method) { [:tags, :generalizations].include?(method) },
          generalizations: [generalization]
        )
      end

      let(:config_with_map) do
        {
          "mapEntries" => {
            "SomeComplexType" => {
              type: "SomeComplexType",
              content: "complex/simple"
            }
          }
        }
      end

      let(:context_with_map) do
        { xsd_document: xsd_doc, config: config_with_map }
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype-list", uml_class)
          .and_return(false)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-local-basictype", uml_class)
          .and_return(false)
      end

      it "creates a complex type with simple content and facets" do
        complex_type = double("ComplexType")
        simple_content = double("SimpleContent")
        restriction = double("Restriction")

        expect(xsd_doc).to receive(:add_complex_type)
          .with(name: "AnnotatedStringType")
          .and_return(complex_type)
        expect(xsd_doc).to receive(:add_simple_content)
          .with(complex_type)
          .and_return(simple_content)
        expect(xsd_doc).to receive(:add_restriction)
          .with(simple_content, base: "string")
          .and_return(restriction)
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "maxLength", "100")

        processor.process(uml_class, context_with_map)
      end
    end

    context "when processing a list-based basic type" do
      let(:property_type) { double("PropertyType", name: "Real") }
      let(:property) do
        double(
          "Property",
          name: "list",
          type: property_type,
          min_occurs: 4,
          max_occurs: 4
        )
      end
      let(:uml_class) do
        double(
          "UmlClass",
          name: "TransformationMatrix2x2",
          tags: [],
          respond_to?: ->(method) { [:tags, :attributes, :generalizations].include?(method) },
          attributes: [property],
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype-list", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-local-basictype", uml_class)
          .and_return(false)
      end

      it "creates a list-based simple type with length restriction" do
        simple_type = double("SimpleType")
        restriction = double("Restriction")
        list_simple_type = double("ListSimpleType")

        expect(xsd_doc).to receive(:add_simple_type)
          .with(name: "TransformationMatrix2x2Type")
          .and_return(simple_type)
        expect(xsd_doc).to receive(:add_restriction)
          .with(simple_type)
          .and_return(restriction)
        expect(xsd_doc).to receive(:add_simple_type_child)
          .with(restriction)
          .and_return(list_simple_type)
        expect(xsd_doc).to receive(:add_list)
          .with(list_simple_type, item_type: "double")
        expect(xsd_doc).to receive(:add_facet)
          .with(restriction, "length", "4")

        processor.process(uml_class, context)
      end
    end

    context "when processing a list-based type without length restrictions" do
      let(:property_type) { double("PropertyType", name: "Integer") }
      let(:property) do
        double(
          "Property",
          name: "values",
          type: property_type,
          min_occurs: 0,
          max_occurs: "*"
        )
      end
      let(:uml_class) do
        double(
          "UmlClass",
          name: "IntegerList",
          tags: [],
          respond_to?: ->(method) { [:tags, :attributes, :generalizations].include?(method) },
          attributes: [property],
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype-list", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-local-basictype", uml_class)
          .and_return(false)
      end

      it "creates a list-based simple type without length facets" do
        simple_type = double("SimpleType")

        expect(xsd_doc).to receive(:add_simple_type)
          .with(name: "IntegerListType")
          .and_return(simple_type)
        expect(xsd_doc).to receive(:add_list)
          .with(simple_type, item_type: "integer")

        processor.process(uml_class, context)
      end
    end

    context "when processing a basic type without base" do
      let(:uml_class) do
        double(
          "UmlClass",
          name: "InvalidBasicType",
          tags: [],
          respond_to?: ->(method) { [:tags, :generalizations].include?(method) },
          generalizations: []
        )
      end

      before do
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype", uml_class)
          .and_return(true)
        allow(rule_checker).to receive(:applies?)
          .with("rule-xsd-cls-basictype-list", uml_class)
          .and_return(false)
      end

      it "logs a warning and does not create a type" do
        expect { processor.process(uml_class, context) }
          .to output(/Warning: No base type found/).to_stdout

        expect(xsd_doc).not_to receive(:add_simple_type)
      end
    end
  end

  describe "facet support" do
    let(:processor_instance) { described_class.new(rule_checker, config) }

    it "supports totalDigits for integer types" do
      expect(processor_instance.send(:facet_supported?, "totalDigits", "integer")).to be true
      expect(processor_instance.send(:facet_supported?, "totalDigits", "decimal")).to be true
    end

    it "supports maxLength for string types" do
      expect(processor_instance.send(:facet_supported?, "maxLength", "string")).to be true
      expect(processor_instance.send(:facet_supported?, "maxLength", "normalizedString")).to be true
    end

    it "supports min/max inclusive for numeric types" do
      expect(processor_instance.send(:facet_supported?, "minInclusive", "integer")).to be true
      expect(processor_instance.send(:facet_supported?, "maxInclusive", "double")).to be true
      expect(processor_instance.send(:facet_supported?, "minInclusive", "string")).to be false
    end

    it "supports pattern for most types" do
      expect(processor_instance.send(:facet_supported?, "pattern", "string")).to be true
      expect(processor_instance.send(:facet_supported?, "pattern", "integer")).to be true
    end

    it "handles namespaced base types" do
      expect(processor_instance.send(:facet_supported?, "minInclusive", "xs:integer")).to be true
      expect(processor_instance.send(:facet_supported?, "maxLength", "xs:string")).to be true
    end
  end
end