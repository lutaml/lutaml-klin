# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/services/spa_generator"
require "lutaml/klin/models/mapping/schema_mapping"
require "lutaml/klin/models/mapping/package_mapping"
require "lutaml/klin/models/mapping/class_mapping"
require "lutaml/klin/models/mapping/attribute_mapping"

RSpec.describe Lutaml::Klin::Domain::Services::SpaGenerator do
  subject(:generator) { described_class.new }

  let(:schema_mapping) do
    Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
      sm.version = "1.0"
      sm.generated_at = "2024-01-01T00:00:00Z"
      sm.package_mappings = [package_mapping]
      sm.namespaces = ["http://example.org/test"]
    end
  end

  let(:package_mapping) do
    Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
      pm.uml_name = "TestPackage"
      pm.uml_package_name = "Model::TestPackage"
      pm.xsd_namespace = "http://example.org/test"
      pm.xsd_namespace_prefix = "test"
      pm.class_mappings = [class_mapping]
    end
  end

  let(:class_mapping) do
    Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
      cm.uml_name = "TestClass"
      cm.uml_qualified_name = "Model::TestPackage::TestClass"
      cm.uml_stereotype = "FeatureType"
      cm.uml_documentation = "A test class"
      cm.xsd_namespace = "http://example.org/test"
      cm.xsd_element_name = "TestClass"
      cm.xsd_type_name = "test:TestClassType"
      cm.xsd_documentation = "XSD test class"
      cm.resolution_status = "resolved"
      cm.resolution_method = "shapechange"
      cm.resolution_confidence = 0.95
      cm.attribute_mappings = [attribute_mapping]
    end
  end

  let(:attribute_mapping) do
    Lutaml::Klin::Mapping::AttributeMapping.new.tap do |am|
      am.uml_name = "testAttribute"
      am.uml_type = "CharacterString"
      am.uml_documentation = "A test attribute"
      am.uml_multiplicity = "1"
      am.xsd_name = "testAttribute"
      am.xsd_type = "xs:string"
      am.xsd_documentation = "XSD test attribute"
      am.xsd_min_occurs = "1"
      am.xsd_max_occurs = "1"
      am.resolution_status = "resolved"
      am.resolution_method = "shapechange"
    end
  end

  describe "#generate_mappings_json" do
    subject(:result) { generator.generate_mappings_json(schema_mapping) }

    it "generates a valid mappings JSON structure" do
      expect(result).to be_a(Hash)
      expect(result[:metadata]).to be_a(Hash)
      expect(result[:metadata][:version]).to eq("1.0")
      expect(result[:metadata][:generated_at]).to eq("2024-01-01T00:00:00Z")
      expect(result[:packages]).to be_a(Hash)
      expect(result[:packages].size).to eq(1)
      expect(result[:classes]).to be_a(Hash)
      expect(result[:attributes]).to be_a(Hash)
    end

    it "includes package details" do
      pkg = result[:packages].values.first
      expect(pkg[:name]).to eq("TestPackage")
      expect(pkg[:qualified_name]).to eq("Model::TestPackage")
      expect(pkg[:namespace]).to eq("http://example.org/test")
      expect(pkg[:namespace_prefix]).to eq("test")
      expect(pkg[:classes]).to be_an(Array)
      expect(pkg[:classes].size).to eq(1)
    end

    it "includes class details" do
      cls = result[:classes].values.first
      expect(cls[:name]).to eq("TestClass")
      expect(cls[:qualified_name]).to eq("Model::TestPackage::TestClass")
      expect(cls[:stereotype]).to eq("FeatureType")
      expect(cls[:definition]).to eq("A test class")
      expect(cls[:xsd_type_name]).to eq("test:TestClassType")
      expect(cls[:resolution_status]).to eq("resolved")
      expect(cls[:resolution_method]).to eq("shapechange")
      expect(cls[:resolution_confidence]).to eq(0.95)
      expect(cls[:attributes]).to be_an(Array)
      expect(cls[:attributes].size).to eq(1)
      expect(cls[:xml_instance]).to be_a(String)
    end

    it "includes attribute details" do
      attr = result[:attributes].values.first
      expect(attr[:name]).to eq("testAttribute")
      expect(attr[:uml_type]).to eq("CharacterString")
      expect(attr[:xsd_type]).to eq("xs:string")
      expect(attr[:resolution_status]).to eq("resolved")
      expect(attr[:xsd_min_occurs]).to eq("1")
      expect(attr[:xsd_max_occurs]).to eq("1")
    end

    it "generates stable IDs" do
      pkg_id = result[:packages].keys.first
      expect(pkg_id).to match(/^pkg_/)

      cls_id = result[:classes].keys.first
      expect(cls_id).to match(/^class_/)

      attr_id = result[:attributes].keys.first
      expect(attr_id).to match(/^attr_/)
    end
  end

  describe "#generate_search_index" do
    subject(:result) { generator.generate_search_index(schema_mapping) }

    it "generates a search index structure" do
      expect(result).to be_a(Hash)
      expect(result[:index]).to be_an(Array)
    end

    it "includes package entries" do
      pkg_entry = result[:index].find { |e| e[:type] == "package" }
      expect(pkg_entry).not_to be_nil
      expect(pkg_entry[:title]).to eq("TestPackage")
      expect(pkg_entry[:qualified_name]).to eq("Model::TestPackage")
      expect(pkg_entry[:url]).to include("#/packages/")
      expect(pkg_entry[:keywords]).to be_an(Array)
    end

    it "includes class entries" do
      cls_entry = result[:index].find { |e| e[:type] == "class" }
      expect(cls_entry).not_to be_nil
      expect(cls_entry[:title]).to eq("TestClass")
      expect(cls_entry[:resolution_status]).to eq("resolved")
      expect(cls_entry[:url]).to include("#/classes/")
    end

    it "includes attribute entries" do
      attr_entry = result[:index].find { |e| e[:type] == "attribute" }
      expect(attr_entry).not_to be_nil
      expect(attr_entry[:title]).to eq("testAttribute")
      expect(attr_entry[:uml_type]).to eq("CharacterString")
      expect(attr_entry[:xsd_type]).to eq("xs:string")
    end

    it "extracts keywords from names" do
      cls_entry = result[:index].find { |e| e[:type] == "class" }
      expect(cls_entry[:keywords]).to include("test", "class")
    end
  end

  describe "#generate_statistics" do
    subject(:result) { generator.generate_statistics(schema_mapping) }

    it "generates statistics structure" do
      expect(result).to be_a(Hash)
      expect(result[:summary]).to be_a(Hash)
      expect(result[:packages]).to be_an(Array)
    end

    it "includes summary statistics" do
      summary = result[:summary]
      expect(summary[:total_packages]).to eq(1)
      expect(summary[:total_classes]).to eq(1)
      expect(summary[:resolved_classes]).to eq(1)
      expect(summary[:total_attributes]).to eq(1)
      expect(summary[:resolved_attributes]).to eq(1)
      expect(summary[:resolution_rate]).to eq(100.0)
    end

    it "includes package-level statistics" do
      pkg_stat = result[:packages].first
      expect(pkg_stat[:name]).to eq("TestPackage")
      expect(pkg_stat[:qualified_name]).to eq("Model::TestPackage")
      expect(pkg_stat[:resolution_rate]).to eq(100.0)
      expect(pkg_stat[:statistics]).to be_a(Hash)
    end
  end

  describe "edge cases" do
    context "with empty package mappings" do
      let(:schema_mapping) do
        Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.version = "1.0"
          sm.generated_at = "2024-01-01T00:00:00Z"
          sm.package_mappings = []
        end
      end

      it "generates valid empty structures" do
        mappings = generator.generate_mappings_json(schema_mapping)
        expect(mappings[:packages]).to eq({})
        expect(mappings[:classes]).to eq({})
        expect(mappings[:attributes]).to eq({})

        search_index = generator.generate_search_index(schema_mapping)
        expect(search_index[:index]).to eq([])

        statistics = generator.generate_statistics(schema_mapping)
        expect(statistics[:summary][:total_packages]).to eq(0)
      end
    end

    context "with partial resolution" do
      let(:class_mapping) do
        Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
          cm.uml_name = "PartialClass"
          cm.uml_qualified_name = "Model::PartialClass"
          cm.xsd_element_name = "PartialClass"
          cm.resolution_status = "partial"
          cm.resolution_method = "shapechange"
          cm.attribute_mappings = []
        end
      end

      it "includes partial resolution status" do
        result = generator.generate_mappings_json(schema_mapping)
        cls = result[:classes].values.first
        expect(cls[:resolution_status]).to eq("partial")
      end
    end

    context "with nil values" do
      let(:class_mapping) do
        Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
          cm.uml_name = "NilClass"
          cm.uml_qualified_name = nil
          cm.uml_stereotype = nil
          cm.xsd_element_name = nil
          cm.xsd_type_name = nil
          cm.resolution_status = "unresolved"
          cm.attribute_mappings = []
        end
      end

      it "handles nil values gracefully" do
        result = generator.generate_mappings_json(schema_mapping)
        cls = result[:classes].values.first
        expect(cls[:qualified_name]).to include("NilClass")
        expect(cls[:stereotype]).to be_nil
        expect(cls[:xsd_type_name]).to be_nil
        expect(cls[:xml_instance]).to be_nil
      end
    end
  end
end
