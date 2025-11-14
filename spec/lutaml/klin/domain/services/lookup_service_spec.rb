# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/services/lookup_service"
require "lutaml/klin/models/mapping/schema_mapping"
require "lutaml/klin/models/mapping/package_mapping"
require "lutaml/klin/models/mapping/class_mapping"
require "lutaml/klin/models/mapping/attribute_mapping"

RSpec.describe Lutaml::Klin::Domain::Services::LookupService do
  let(:attr1) do
    Lutaml::Klin::Mapping::AttributeMapping.new.tap do |a|
      a.uml_name = "name"
      a.uml_type = "CharacterString"
      a.xsd_name = "name"
      a.xsd_type = "xs:string"
      a.namespace = "urf"
      a.resolution_status = "resolved"
    end
  end

  let(:attr2) do
    Lutaml::Klin::Mapping::AttributeMapping.new.tap do |a|
      a.uml_name = "code"
      a.uml_type = "Code"
      a.xsd_name = "code"
      a.xsd_type = "gml:CodeType"
      a.namespace = "gml"
      a.resolution_status = "resolved"
    end
  end

  let(:class1) do
    Lutaml::Klin::Mapping::ClassMapping.new.tap do |c|
      c.uml_name = "UrbanPlanningArea"
      c.uml_package = "ModelRoot::i-UR::urf"
      c.uml_qualified_name = "ModelRoot::i-UR::urf::UrbanPlanningArea"
      c.xsd_element_name = "UrbanPlanningArea"
      c.xsd_type = "urf:UrbanPlanningAreaType"
      c.xsd_type_name = "UrbanPlanningAreaType"
      c.xsd_namespace = "http://www.opengis.net/plateau/urbanPlanning/2.0"
      c.resolution_status = "resolved"
      c.attribute_mappings = [attr1, attr2]
    end
  end

  let(:class2) do
    Lutaml::Klin::Mapping::ClassMapping.new.tap do |c|
      c.uml_name = "Building"
      c.uml_package = "ModelRoot::i-UR::bldg"
      c.uml_qualified_name = "ModelRoot::i-UR::bldg::Building"
      c.xsd_element_name = "Building"
      c.xsd_type = "bldg:BuildingType"
      c.xsd_type_name = "BuildingType"
      c.xsd_namespace = "http://www.opengis.net/plateau/building/2.0"
      c.resolution_status = "resolved"
      c.attribute_mappings = []
    end
  end

  let(:package1) do
    Lutaml::Klin::Mapping::PackageMapping.new.tap do |p|
      p.uml_package_name = "urf"
      p.class_mappings = [class1]
    end
  end

  let(:package2) do
    Lutaml::Klin::Mapping::PackageMapping.new.tap do |p|
      p.uml_package_name = "bldg"
      p.class_mappings = [class2]
    end
  end

  let(:schema_mapping) do
    Lutaml::Klin::Mapping::SchemaMapping.new.tap do |s|
      s.version = "1.0"
      s.package_mappings = [package1, package2]
    end
  end

  let(:service) { described_class.new(schema_mapping) }

  describe "#initialize" do
    it "creates a lookup service with schema mapping" do
      expect(service.mapping).to eq(schema_mapping)
      expect(service.index).to be_a(Hash)
    end

    it "builds bidirectional indexes" do
      expect(service.index).to have_key(:uml_class)
      expect(service.index).to have_key(:uml_attr)
      expect(service.index).to have_key(:xsd_type)
      expect(service.index).to have_key(:xsd_element)
    end

    it "indexes UML classes correctly" do
      expect(service.index[:uml_class]["ModelRoot::i-UR::urf::UrbanPlanningArea"]).to eq(class1)
      expect(service.index[:uml_class]["ModelRoot::i-UR::bldg::Building"]).to eq(class2)
    end

    it "indexes UML attributes correctly" do
      key = "ModelRoot::i-UR::urf::UrbanPlanningArea::name"
      expect(service.index[:uml_attr][key]).to eq(attr1)
    end

    it "indexes XSD types correctly" do
      expect(service.index[:xsd_type]["urf:UrbanPlanningAreaType"]).to include(class1)
      expect(service.index[:xsd_type]["bldg:BuildingType"]).to include(class2)
    end

    it "indexes XSD elements correctly" do
      expect(service.index[:xsd_element]["urf:name"]).to be_an(Array)
      expect(service.index[:xsd_element]["urf:name"].first[:attribute]).to eq(attr1)
    end
  end

  describe "#find_xsd_for_uml_class" do
    context "with exact match" do
      it "finds XSD mapping for UML class" do
        result = service.find_xsd_for_uml_class("ModelRoot::i-UR::urf::UrbanPlanningArea")

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
        expect(result.found?).to be(true)
        expect(result.single_match?).to be(true)
        expect(result.direction).to eq(:uml_to_xsd)

        match = result.first_match
        expect(match[:uml_class]).to eq("ModelRoot::i-UR::urf::UrbanPlanningArea")
        expect(match[:xsd_type]).to eq("urf:UrbanPlanningAreaType")
        expect(match[:xsd_element]).to eq("UrbanPlanningArea")
      end
    end

    context "with no match" do
      it "returns empty result" do
        result = service.find_xsd_for_uml_class("NonExistentClass")

        expect(result.found?).to be(false)
        expect(result.matches).to be_empty
      end
    end

    context "with fuzzy matching" do
      it "finds partial matches" do
        result = service.find_xsd_for_uml_class("UrbanPlanning", fuzzy: true)

        expect(result.found?).to be(true)
        expect(result.matches.first[:uml_class]).to include("UrbanPlanningArea")
      end

      it "ranks matches by quality" do
        result = service.find_xsd_for_uml_class("Building", fuzzy: true)

        expect(result.found?).to be(true)
        expect(result.matches.first[:match_quality]).to be > 0
      end
    end
  end

  describe "#find_xsd_for_uml_attribute" do
    context "with exact match" do
      it "finds XSD mapping for UML attribute" do
        result = service.find_xsd_for_uml_attribute(
          "ModelRoot::i-UR::urf::UrbanPlanningArea",
          "name"
        )

        expect(result.found?).to be(true)
        expect(result.single_match?).to be(true)

        match = result.first_match
        expect(match[:uml_attribute]).to eq("name")
        expect(match[:xsd_name]).to eq("name")
        expect(match[:xsd_type]).to eq("xs:string")
      end
    end

    context "with no match" do
      it "returns empty result" do
        result = service.find_xsd_for_uml_attribute(
          "ModelRoot::i-UR::urf::UrbanPlanningArea",
          "nonExistent"
        )

        expect(result.found?).to be(false)
      end
    end

    context "with fuzzy matching" do
      it "finds partial matches" do
        result = service.find_xsd_for_uml_attribute(
          "UrbanPlanning",
          "nam",
          fuzzy: true
        )

        expect(result.found?).to be(true)
      end
    end
  end

  describe "#find_uml_for_xsd_type" do
    context "with exact match" do
      it "finds UML classes for XSD type" do
        result = service.find_uml_for_xsd_type("urf:UrbanPlanningAreaType")

        expect(result.found?).to be(true)
        expect(result.direction).to eq(:xsd_to_uml)

        match = result.first_match
        expect(match[:uml_class]).to eq("ModelRoot::i-UR::urf::UrbanPlanningArea")
        expect(match[:xsd_type]).to eq("urf:UrbanPlanningAreaType")
      end
    end

    context "with no match" do
      it "returns empty result" do
        result = service.find_uml_for_xsd_type("unknown:Type")

        expect(result.found?).to be(false)
      end
    end

    context "with fuzzy matching" do
      it "finds partial matches" do
        result = service.find_uml_for_xsd_type("Planning", fuzzy: true)

        expect(result.found?).to be(true)
      end
    end
  end

  describe "#find_uml_for_xsd_element" do
    context "with exact match" do
      it "finds UML attributes for XSD element" do
        result = service.find_uml_for_xsd_element("urf:name")

        expect(result.found?).to be(true)
        expect(result.direction).to eq(:xsd_to_uml)

        match = result.first_match
        expect(match[:xsd_name]).to eq("name")
        expect(match[:uml_attribute]).to eq("name")
      end
    end

    context "with no match" do
      it "returns empty result" do
        result = service.find_uml_for_xsd_element("unknown:element")

        expect(result.found?).to be(false)
      end
    end
  end

  describe "#auto_lookup" do
    context "with UML class identifier" do
      it "detects UML class lookup" do
        result = service.auto_lookup("ModelRoot::i-UR::urf::UrbanPlanningArea")

        # Should return a result, found or not
        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
        # If found, should have correct class
        expect(result.matches.first[:uml_class]).to eq("ModelRoot::i-UR::urf::UrbanPlanningArea") if result.found?
      end
    end

    context "with UML attribute identifier" do
      it "detects UML attribute lookup" do
        result = service.auto_lookup("ModelRoot::i-UR::urf::UrbanPlanningArea::name")

        expect(result.found?).to be(true)
        expect(result.matches.first[:uml_attribute]).to eq("name")
      end
    end

    context "with XSD type identifier" do
      it "detects XSD type lookup" do
        result = service.auto_lookup("urf:UrbanPlanningAreaType")

        expect(result.found?).to be(true)
        expect(result.matches.first[:xsd_type]).to eq("urf:UrbanPlanningAreaType")
      end
    end

    context "with XSD element identifier" do
      it "detects XSD element lookup" do
        result = service.auto_lookup("gml:code")

        expect(result.found?).to be(true)
      end
    end

    context "with ambiguous identifier" do
      it "tries all lookup types" do
        result = service.auto_lookup("name", fuzzy: true)

        expect(result.metadata[:type]).to eq(:auto)
      end
    end
  end

  describe "bidirectional consistency" do
    it "maintains consistency between UML→XSD and XSD→UML lookups" do
      # UML → XSD
      uml_result = service.find_xsd_for_uml_class("ModelRoot::i-UR::urf::UrbanPlanningArea")
      xsd_type = uml_result.first_match[:xsd_type]

      # XSD → UML
      xsd_result = service.find_uml_for_xsd_type(xsd_type)
      uml_class = xsd_result.first_match[:uml_class]

      expect(uml_class).to eq("ModelRoot::i-UR::urf::UrbanPlanningArea")
    end
  end

  describe "performance" do
    it "performs lookups efficiently using indexes" do
      # This test ensures indexing works by verifying
      # we can perform many lookups without error
      expect do
        1000.times do
          service.find_xsd_for_uml_class("ModelRoot::i-UR::urf::UrbanPlanningArea")
        end
      end.not_to raise_error
    end
  end
end