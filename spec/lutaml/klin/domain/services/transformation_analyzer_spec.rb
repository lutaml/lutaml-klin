# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/services/transformation_analyzer"

RSpec.describe Lutaml::Klin::Domain::Services::TransformationAnalyzer do
  let(:shapechange_config) { double("ShapeChangeConfig") }
  let(:analyzer) { described_class.new(shapechange_config) }

  describe "#initialize" do
    it "accepts a ShapeChange configuration" do
      expect { described_class.new(shapechange_config) }.not_to raise_error
    end

    it "stores the configuration" do
      expect(analyzer.config).to eq(shapechange_config)
    end

    it "raises ArgumentError when config is nil" do
      expect do
        described_class.new(nil)
      end.to raise_error(ArgumentError, "shapechange_config is required")
    end

    it "freezes the instance" do
      expect(analyzer).to be_frozen
    end
  end

  describe "#analyze_class" do
    let(:uml_class) do
      double("UMLClass",
             name: "Building",
             qualified_name: "ModelRoot::i-UR::uro::Building")
    end

    before do
      allow(shapechange_config).to receive(:namespace_for_package)
        .with("ModelRoot::i-UR::uro::Building")
        .and_return("https://www.geospatial.jp/iur/uro/3.2")
    end

    it "returns complete analysis hash" do
      result = analyzer.analyze_class(uml_class)

      expect(result).to be_a(Hash)
      expect(result).to include(
        :element_name,
        :type_name,
        :property_type_name,
        :namespace
      )
    end

    it "uses class name as element name" do
      result = analyzer.analyze_class(uml_class)
      expect(result[:element_name]).to eq("Building")
    end

    it "appends Type suffix for type name" do
      result = analyzer.analyze_class(uml_class)
      expect(result[:type_name]).to eq("BuildingType")
    end

    it "appends PropertyType suffix for property type name" do
      result = analyzer.analyze_class(uml_class)
      expect(result[:property_type_name]).to eq("BuildingPropertyType")
    end

    it "determines namespace from package" do
      result = analyzer.analyze_class(uml_class)
      expect(result[:namespace]).to eq("https://www.geospatial.jp/iur/uro/3.2")
    end

    context "when namespace determination fails" do
      before do
        allow(shapechange_config).to receive(:namespace_for_package)
          .and_raise(StandardError, "Package not found")
      end

      it "returns nil namespace" do
        result = analyzer.analyze_class(uml_class)
        expect(result[:namespace]).to be_nil
      end

      it "does not raise an error" do
        expect { analyzer.analyze_class(uml_class) }.not_to raise_error
      end
    end

    context "with class name variations" do
      it "handles simple names" do
        simple_class = double("UMLClass",
                              name: "Point",
                              qualified_name: "Core::Point")
        allow(shapechange_config).to receive(:namespace_for_package)
          .and_return("http://example.org/core")

        result = analyzer.analyze_class(simple_class)
        expect(result[:element_name]).to eq("Point")
        expect(result[:type_name]).to eq("PointType")
      end

      it "handles names with numbers" do
        numbered_class = double("UMLClass",
                                name: "Building3D",
                                qualified_name: "Core::Building3D")
        allow(shapechange_config).to receive(:namespace_for_package)
          .and_return("http://example.org/core")

        result = analyzer.analyze_class(numbered_class)
        expect(result[:type_name]).to eq("Building3DType")
      end
    end
  end

  describe "#analyze_attribute" do
    let(:uml_attr) do
      double("UMLAttribute",
             name: "height",
             type: "Length")
    end

    let(:map_entry) do
      double("XsdMapEntry", xml_type: "gml:LengthType")
    end

    before do
      allow(shapechange_config).to receive(:find_type_mapping)
        .with("Length", encoding_rule: "citygml")
        .and_return(map_entry)
    end

    it "returns complete analysis hash" do
      result = analyzer.analyze_attribute(uml_attr)

      expect(result).to be_a(Hash)
      expect(result).to include(:xml_name, :xml_type, :is_attribute)
    end

    it "uses attribute name as XML name" do
      result = analyzer.analyze_attribute(uml_attr)
      expect(result[:xml_name]).to eq("height")
    end

    it "resolves UML type to XML type" do
      result = analyzer.analyze_attribute(uml_attr)
      expect(result[:xml_type]).to eq("gml:LengthType")
    end

    it "determines if attribute should be XML attribute" do
      result = analyzer.analyze_attribute(uml_attr)
      expect(result[:is_attribute]).to be(true).or be(false)
    end

    context "with XML attribute names" do
      it "marks 'id' as XML attribute" do
        id_attr = double("UMLAttribute", name: "id", type: "CharacterString")
        allow(shapechange_config).to receive(:find_type_mapping)
          .and_return(double(xml_type: "xs:string"))

        result = analyzer.analyze_attribute(id_attr)
        expect(result[:is_attribute]).to be true
      end

      it "marks 'href' as XML attribute" do
        href_attr = double("UMLAttribute", name: "href", type: "CharacterString")
        allow(shapechange_config).to receive(:find_type_mapping)
          .and_return(double(xml_type: "xs:string"))

        result = analyzer.analyze_attribute(href_attr)
        expect(result[:is_attribute]).to be true
      end

      it "marks regular attributes as XML elements" do
        regular_attr = double("UMLAttribute", name: "description", type: "CharacterString")
        allow(shapechange_config).to receive(:find_type_mapping)
          .and_return(double(xml_type: "xs:string"))

        result = analyzer.analyze_attribute(regular_attr)
        expect(result[:is_attribute]).to be false
      end
    end
  end

  describe "#resolve_xml_type" do
    context "with type mapping available" do
      let(:map_entry) do
        double("XsdMapEntry", xml_type: "xs:string")
      end

      before do
        allow(shapechange_config).to receive(:find_type_mapping)
          .with("CharacterString", encoding_rule: "citygml")
          .and_return(map_entry)
      end

      it "returns mapped XML type" do
        result = analyzer.resolve_xml_type("CharacterString")
        expect(result).to eq("xs:string")
      end

      it "strips whitespace from result" do
        map_entry_with_space = double("XsdMapEntry", xml_type: "  xs:string  ")
        allow(shapechange_config).to receive(:find_type_mapping)
          .and_return(map_entry_with_space)

        result = analyzer.resolve_xml_type("CharacterString")
        expect(result).to eq("xs:string")
      end
    end

    context "without type mapping" do
      before do
        allow(shapechange_config).to receive(:find_type_mapping)
          .and_return(nil)
      end

      it "returns normalized type name as fallback" do
        result = analyzer.resolve_xml_type("CustomType")
        expect(result).to eq("CustomType")
      end

      it "normalizes :: to : in fallback" do
        result = analyzer.resolve_xml_type("gml::CodeType")
        expect(result).to eq("gml:CodeType")
      end
    end

    context "with nil or empty type" do
      it "returns nil for nil type" do
        result = analyzer.resolve_xml_type(nil)
        expect(result).to be_nil
      end

      it "returns normalized empty string for empty type" do
        allow(shapechange_config).to receive(:find_type_mapping)
          .and_return(nil)

        result = analyzer.resolve_xml_type("")
        expect(result).to eq("")
      end
    end

    context "with type normalization" do
      before do
        allow(shapechange_config).to receive(:find_type_mapping)
          .with("gml:CodeType", encoding_rule: "citygml")
          .and_return(nil)
      end

      it "normalizes :: to : before lookup" do
        result = analyzer.resolve_xml_type("gml::CodeType")
        expect(result).to eq("gml:CodeType")
      end

      it "strips whitespace before lookup" do
        allow(shapechange_config).to receive(:find_type_mapping)
          .with("CharacterString", encoding_rule: "citygml")
          .and_return(nil)

        result = analyzer.resolve_xml_type("  CharacterString  ")
        expect(result).to eq("CharacterString")
      end
    end

    context "with different encoding rules" do
      let(:map_entry) do
        double("XsdMapEntry", xml_type: "custom:Type")
      end

      it "passes encoding rule to config" do
        allow(shapechange_config).to receive(:find_type_mapping)
          .with("CustomType", encoding_rule: "custom_rule")
          .and_return(map_entry)

        result = analyzer.resolve_xml_type("CustomType", encoding_rule: "custom_rule")
        expect(result).to eq("custom:Type")
      end
    end
  end

  describe "#is_xml_attribute?" do
    it "returns true for 'id' attribute" do
      attr = double("UMLAttribute", name: "id")
      expect(analyzer.is_xml_attribute?(attr)).to be true
    end

    it "returns true for 'href' attribute" do
      attr = double("UMLAttribute", name: "href")
      expect(analyzer.is_xml_attribute?(attr)).to be true
    end

    it "returns true for 'codeSpace' attribute" do
      attr = double("UMLAttribute", name: "codeSpace")
      expect(analyzer.is_xml_attribute?(attr)).to be true
    end

    it "returns true for 'uom' attribute" do
      attr = double("UMLAttribute", name: "uom")
      expect(analyzer.is_xml_attribute?(attr)).to be true
    end

    it "returns true for 'nilReason' attribute" do
      attr = double("UMLAttribute", name: "nilReason")
      expect(analyzer.is_xml_attribute?(attr)).to be true
    end

    it "returns true for 'owns' attribute" do
      attr = double("UMLAttribute", name: "owns")
      expect(analyzer.is_xml_attribute?(attr)).to be true
    end

    it "returns false for regular attributes" do
      attr = double("UMLAttribute", name: "description")
      expect(analyzer.is_xml_attribute?(attr)).to be false
    end

    it "returns false for property names" do
      attr = double("UMLAttribute", name: "buildingHeight")
      expect(analyzer.is_xml_attribute?(attr)).to be false
    end

    it "is case-sensitive" do
      attr = double("UMLAttribute", name: "ID")
      expect(analyzer.is_xml_attribute?(attr)).to be false
    end
  end

  describe "#determine_namespace" do
    let(:uml_class) do
      double("UMLClass",
             name: "Building",
             qualified_name: "ModelRoot::i-UR::uro::Building")
    end

    context "when class has qualified_name" do
      before do
        allow(shapechange_config).to receive(:namespace_for_package)
          .with("ModelRoot::i-UR::uro::Building")
          .and_return("https://www.geospatial.jp/iur/uro/3.2")
      end

      it "returns namespace from config" do
        result = analyzer.determine_namespace(uml_class)
        expect(result).to eq("https://www.geospatial.jp/iur/uro/3.2")
      end
    end

    context "when class doesn't respond to qualified_name" do
      let(:uml_class_no_qname) do
        double("UMLClass", name: "Building")
      end

      before do
        allow(uml_class_no_qname).to receive(:respond_to?)
          .with(:qualified_name).and_return(false)
      end

      it "returns nil" do
        result = analyzer.determine_namespace(uml_class_no_qname)
        expect(result).to be_nil
      end
    end

    context "when namespace lookup fails" do
      before do
        allow(shapechange_config).to receive(:namespace_for_package)
          .and_raise(StandardError, "Package not found")
      end

      it "returns nil" do
        result = analyzer.determine_namespace(uml_class)
        expect(result).to be_nil
      end

      it "does not raise an error" do
        expect do
          analyzer.determine_namespace(uml_class)
        end.not_to raise_error
      end
    end

    context "when qualified_name is nil" do
      let(:uml_class_nil_qname) do
        double("UMLClass", name: "Building", qualified_name: nil)
      end

      it "returns nil" do
        result = analyzer.determine_namespace(uml_class_nil_qname)
        expect(result).to be_nil
      end
    end
  end

  describe "#has_type_mapping?" do
    context "when mapping exists" do
      before do
        allow(shapechange_config).to receive(:has_type_mapping?)
          .with("CharacterString", encoding_rule: "citygml")
          .and_return(true)
      end

      it "returns true" do
        result = analyzer.has_type_mapping?("CharacterString")
        expect(result).to be true
      end
    end

    context "when mapping does not exist" do
      before do
        allow(shapechange_config).to receive(:has_type_mapping?)
          .with("UnknownType", encoding_rule: "citygml")
          .and_return(false)
      end

      it "returns false" do
        result = analyzer.has_type_mapping?("UnknownType")
        expect(result).to be false
      end
    end

    context "with different encoding rules" do
      it "passes encoding rule to config" do
        expect(shapechange_config).to receive(:has_type_mapping?)
          .with("CustomType", encoding_rule: "custom_rule")
          .and_return(true)

        analyzer.has_type_mapping?("CustomType", encoding_rule: "custom_rule")
      end
    end
  end

  describe "#get_type_mapping" do
    let(:map_entry) do
      double("XsdMapEntry",
             uml_type: "CharacterString",
             xml_type: "xs:string")
    end

    context "when mapping exists" do
      before do
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("CharacterString", encoding_rule: "citygml")
          .and_return(map_entry)
      end

      it "returns the mapping entry" do
        result = analyzer.get_type_mapping("CharacterString")
        expect(result).to eq(map_entry)
        expect(result.xml_type).to eq("xs:string")
      end
    end

    context "when mapping does not exist" do
      before do
        allow(shapechange_config).to receive(:get_type_mapping)
          .with("UnknownType", encoding_rule: "citygml")
          .and_return(nil)
      end

      it "returns nil" do
        result = analyzer.get_type_mapping("UnknownType")
        expect(result).to be_nil
      end
    end

    context "with different encoding rules" do
      it "passes encoding rule to config" do
        expect(shapechange_config).to receive(:get_type_mapping)
          .with("CustomType", encoding_rule: "custom_rule")
          .and_return(map_entry)

        analyzer.get_type_mapping("CustomType", encoding_rule: "custom_rule")
      end
    end
  end
end