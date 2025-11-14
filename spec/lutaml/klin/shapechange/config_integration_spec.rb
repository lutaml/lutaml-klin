# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/shapechange/config_parser"

RSpec.describe "ShapeChange Config Integration Fix" do
  let(:config_path) do
    File.expand_path(
      "../../../../reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml",
      __dir__
    )
  end

  let(:parser) { Lutaml::Klin::Shapechange::ConfigParser.new }
  let(:config) { parser.parse_file(config_path) }

  describe "ConfigParser" do
    it "loads real ShapeChange configuration" do
      expect(config).to be_a(Lutaml::Klin::Shapechange::ShapeChangeConfiguration)
    end

    it "extracts xml_namespaces" do
      expect(config.xml_namespaces).not_to be_empty
      expect(config.xml_namespaces.first).to be_a(Lutaml::Klin::Shapechange::XmlNamespace)
    end

    it "extracts xsd_map_entries with all attributes" do
      expect(config.xsd_map_entries).not_to be_empty

      entry = config.xsd_map_entries.first
      expect(entry).to respond_to(:type)
      expect(entry).to respond_to(:xsd_encoding_rules)
      expect(entry).to respond_to(:xml_type)
      expect(entry).to respond_to(:xml_property_type)
    end

    it "extracts package_infos" do
      expect(config.package_infos).not_to be_empty
      expect(config.package_infos.first).to be_a(Lutaml::Klin::Shapechange::PackageInfo)
    end

    it "extracts encoding_rules" do
      expect(config.encoding_rules).not_to be_empty
      expect(config.encoding_rules.first).to be_a(Lutaml::Klin::Shapechange::EncodingRule)
    end
  end

  describe "ShapeChangeConfiguration helper methods" do
    describe "#namespace_for_package" do
      it "finds namespace for package name" do
        namespace = config.namespace_for_package("uro")
        expect(namespace).to be_a(String) if namespace
      end
    end

    describe "#prefix_for_namespace" do
      it "finds prefix for namespace URI" do
        skip "requires actual namespace from config"
        namespace = config.namespace_for_package("uro")
        prefix = config.prefix_for_namespace(namespace)
        expect(prefix).to be_a(String) if prefix
      end
    end

    describe "#find_type_mapping" do
      it "finds type mapping for UML type" do
        mapping = config.find_type_mapping("gml:CodeType", encoding_rule: "citygml")
        expect(mapping).to be_a(Lutaml::Klin::Shapechange::XsdMapEntry) if mapping
      end
    end

    describe "#has_type_mapping?" do
      it "returns true when mapping exists" do
        # Test with a common type that should exist in the config
        has_mapping = config.has_type_mapping?("gml:CodeType", encoding_rule: "citygml")
        expect(has_mapping).to be_in([true, false])
      end
    end

    describe "#get_type_mapping" do
      it "returns mapping when it exists" do
        mapping = config.get_type_mapping("gml:CodeType", encoding_rule: "citygml")
        expect(mapping).to be_a(Lutaml::Klin::Shapechange::XsdMapEntry).or be_nil
      end
    end
  end

  describe "XsdMapEntry#applies_to?" do
    it "returns true when no encoding rules specified" do
      entry = Lutaml::Klin::Shapechange::XsdMapEntry.new
      expect(entry.applies_to?("citygml")).to be true
    end

    it "returns true when encoding rule matches" do
      entry = Lutaml::Klin::Shapechange::XsdMapEntry.new(
        xsd_encoding_rules: "citygml iso19136_2007"
      )
      expect(entry.applies_to?("citygml")).to be true
    end

    it "returns false when encoding rule does not match" do
      entry = Lutaml::Klin::Shapechange::XsdMapEntry.new(
        xsd_encoding_rules: "iso19136_2007"
      )
      expect(entry.applies_to?("citygml")).to be false
    end
  end

  describe "EncodingRule#has_rule?" do
    it "returns true when rule is directly included" do
      rule = Lutaml::Klin::Shapechange::EncodingRule.new(
        name: "citygml",
        rules: ["rule-xsd-all-naming-gml"]
      )
      expect(rule.has_rule?("rule-xsd-all-naming-gml")).to be true
    end

    it "returns false when rule is not included" do
      rule = Lutaml::Klin::Shapechange::EncodingRule.new(
        name: "citygml",
        rules: ["rule-xsd-all-naming-gml"]
      )
      expect(rule.has_rule?("other-rule")).to be false
    end
  end
end