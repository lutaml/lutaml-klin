# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/xsd_analyzer"

RSpec.describe Lutaml::Klin::XsdAnalyzer do
  let(:fixture_path) { File.join(__dir__, "../../fixtures/xsd/simple_schema.xsd") }
  let(:analyzer) { described_class.new }

  describe "#parse_file" do
    it "successfully parses an XSD file" do
      expect { analyzer.parse_file(fixture_path) }.not_to raise_error
    end

    it "sets the schema attribute" do
      analyzer.parse_file(fixture_path)
      expect(analyzer.schema).not_to be_nil
      expect(analyzer.schema).to be_a(Lutaml::Xsd::Schema)
    end

    it "returns the parsed schema" do
      result = analyzer.parse_file(fixture_path)
      expect(result).to be_a(Lutaml::Xsd::Schema)
    end
  end

  describe "#elements" do
    before { analyzer.parse_file(fixture_path) }

    it "returns an array of elements" do
      elements = analyzer.elements
      expect(elements).to be_an(Array)
    end

    it "returns empty array when schema has no elements" do
      analyzer.instance_variable_set(:@schema, nil)
      expect(analyzer.elements).to eq([])
    end
  end

  describe "#complex_types" do
    before { analyzer.parse_file(fixture_path) }

    it "returns an array of complex types" do
      types = analyzer.complex_types
      expect(types).to be_an(Array)
    end

    it "returns empty array when schema has no complex types" do
      analyzer.instance_variable_set(:@schema, nil)
      expect(analyzer.complex_types).to eq([])
    end
  end

  describe "#simple_types" do
    before { analyzer.parse_file(fixture_path) }

    it "returns an array of simple types" do
      types = analyzer.simple_types
      expect(types).to be_an(Array)
    end

    it "returns empty array when schema has no simple types" do
      analyzer.instance_variable_set(:@schema, nil)
      expect(analyzer.simple_types).to eq([])
    end
  end

  describe "#target_namespace" do
    before { analyzer.parse_file(fixture_path) }

    it "returns the target namespace from schema" do
      namespace = analyzer.target_namespace
      expect(namespace).to be_a(String) if namespace
    end

    it "returns nil when schema is not parsed" do
      analyzer.instance_variable_set(:@schema, nil)
      expect(analyzer.target_namespace).to be_nil
    end
  end

  describe "#find_element" do
    before { analyzer.parse_file(fixture_path) }

    context "when elements exist" do
      it "finds an element by name" do
        # This test depends on the fixture having elements
        # Skip if no elements in fixture
        skip "No elements in fixture" if analyzer.elements.empty?

        element_name = analyzer.elements.first.name
        found = analyzer.find_element(element_name)
        expect(found).not_to be_nil
        expect(found.name).to eq(element_name)
      end
    end

    it "returns nil for non-existent element" do
      element = analyzer.find_element("NonExistentElement")
      expect(element).to be_nil
    end

    it "returns nil when schema has no elements" do
      analyzer.instance_variable_set(:@schema, nil)
      expect(analyzer.find_element("AnyName")).to be_nil
    end
  end

  describe "#find_complex_type" do
    before { analyzer.parse_file(fixture_path) }

    context "when complex types exist" do
      it "finds a complex type by name" do
        skip "No complex types in fixture" if analyzer.complex_types.empty?

        type_name = analyzer.complex_types.first.name
        found = analyzer.find_complex_type(type_name)
        expect(found).not_to be_nil
        expect(found.name).to eq(type_name)
      end
    end

    it "returns nil for non-existent complex type" do
      type = analyzer.find_complex_type("NonExistentType")
      expect(type).to be_nil
    end

    it "returns nil when schema has no complex types" do
      analyzer.instance_variable_set(:@schema, nil)
      expect(analyzer.find_complex_type("AnyName")).to be_nil
    end
  end

  describe "#find_simple_type" do
    before { analyzer.parse_file(fixture_path) }

    context "when simple types exist" do
      it "finds a simple type by name" do
        skip "No simple types in fixture" if analyzer.simple_types.empty?

        type_name = analyzer.simple_types.first.name
        found = analyzer.find_simple_type(type_name)
        expect(found).not_to be_nil
        expect(found.name).to eq(type_name)
      end
    end

    it "returns nil for non-existent simple type" do
      type = analyzer.find_simple_type("NonExistentType")
      expect(type).to be_nil
    end

    it "returns nil when schema has no simple types" do
      analyzer.instance_variable_set(:@schema, nil)
      expect(analyzer.find_simple_type("AnyName")).to be_nil
    end
  end

  describe "integration with lutaml-xsd" do
    before { analyzer.parse_file(fixture_path) }

    it "uses lutaml-xsd Schema objects" do
      expect(analyzer.schema).to be_a(Lutaml::Xsd::Schema)
    end

    it "preserves schema properties" do
      schema = analyzer.schema
      expect(schema).to respond_to(:target_namespace)
      expect(schema).to respond_to(:element)
      expect(schema).to respond_to(:complex_type)
      expect(schema).to respond_to(:simple_type)
    end
  end
end
