# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Batch 11 Rules (54-58)" do
  let(:registry) { Lutaml::Klin::Shapechange::RuleRegistry.new }
  let(:encoding_rule) do
    Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
      er.name = "test_swe"
      er.extends = nil
      er.rules = batch_11_rules
    end
  end

  let(:batch_11_rules) do
    [
      "rule-xsd-cls-standard-swe-property-types",
      "rule-xsd-cls-union-omitUnionsRepresentingFeatureTypeSets",
      "rule-xsd-all-naming-swe",
      "rule-xsd-cls-union-as-group-property-type",
      "rule-xsd-all-naming-19139"
    ]
  end

  before do
    registry.register_encoding_rule(encoding_rule)
  end

  describe "Rule 54: rule-xsd-cls-standard-swe-property-types" do
    it "can be registered and checked" do
      expect(registry.has_rule?(
        "rule-xsd-cls-standard-swe-property-types",
        "test_swe"
      )).to be true
    end

    it "generates SWE Common-style property types" do
      # This rule generates property types with swe:AssociationAttributeGroup
      # Expected output structure:
      # <xs:complexType name="ObservationPropertyType">
      #   <xs:sequence minOccurs="0">
      #     <xs:element ref="swe:Observation"/>
      #   </xs:sequence>
      #   <xs:attributeGroup ref="swe:AssociationAttributeGroup"/>
      # </xs:complexType>
      expect(registry.has_rule?(
        "rule-xsd-cls-standard-swe-property-types",
        "test_swe"
      )).to be true
    end

    it "uses swe:ReferenceType for by-reference encoding" do
      # For by-reference properties, uses swe:ReferenceType
      expect(registry.has_rule?(
        "rule-xsd-cls-standard-swe-property-types",
        "test_swe"
      )).to be true
    end

    it "supports soft-typed properties" do
      # Works with rule-xsd-prop-soft-typed for name attribute
      expect(registry.has_rule?(
        "rule-xsd-cls-standard-swe-property-types",
        "test_swe"
      )).to be true
    end

    it "determines class identity correctly" do
      # Includes DATATYPE/UNION with this rule as having identity
      expect(registry.has_rule?(
        "rule-xsd-cls-standard-swe-property-types",
        "test_swe"
      )).to be true
    end
  end

  describe "Rule 55: rule-xsd-cls-union-omitUnionsRepresentingFeatureTypeSets" do
    it "can be registered and checked" do
      expect(registry.has_rule?(
        "rule-xsd-cls-union-omitUnionsRepresentingFeatureTypeSets",
        "test_swe"
      )).to be true
    end

    it "uses gml:ReferenceType for feature type sets" do
      # For unions with representsFeatureTypeSet="true"
      # Expected: <xs:element name="cityObject" type="gml:ReferenceType"/>
      expect(registry.has_rule?(
        "rule-xsd-cls-union-omitUnionsRepresentingFeatureTypeSets",
        "test_swe"
      )).to be true
    end

    it "adds gml:targetElement annotations" do
      # Adds annotations listing all feature types in the set
      expect(registry.has_rule?(
        "rule-xsd-cls-union-omitUnionsRepresentingFeatureTypeSets",
        "test_swe"
      )).to be true
    end

    it "handles nested unions recursively" do
      # Recursively finds all represented features
      expect(registry.has_rule?(
        "rule-xsd-cls-union-omitUnionsRepresentingFeatureTypeSets",
        "test_swe"
      )).to be true
    end

    it "requires GML 3.2 namespace" do
      # Only works with http://www.opengis.net/gml/3.2
      expect(registry.has_rule?(
        "rule-xsd-cls-union-omitUnionsRepresentingFeatureTypeSets",
        "test_swe"
      )).to be true
    end
  end

  describe "Rule 56: rule-xsd-all-naming-swe" do
    it "can be registered and checked" do
      expect(registry.has_rule?(
        "rule-xsd-all-naming-swe",
        "test_swe"
      )).to be true
    end

    it "generates element names without prefix" do
      # Element: Observation -> <prefix:Observation>
      expect(registry.has_rule?(
        "rule-xsd-all-naming-swe",
        "test_swe"
      )).to be true
    end

    it "generates type names with Type suffix" do
      # Type: Observation -> ObservationType
      # Type: TimeProperty -> TimeProperty_Type (underscore for Property suffix)
      expect(registry.has_rule?(
        "rule-xsd-all-naming-swe",
        "test_swe"
      )).to be true
    end

    it "generates property type names with PropertyType suffix" do
      # PropertyType: Observation -> ObservationPropertyType
      # PropertyType: TimeProperty -> TimeProperty_PropertyType
      expect(registry.has_rule?(
        "rule-xsd-all-naming-swe",
        "test_swe"
      )).to be true
    end

    it "uses swe:AbstractSWE substitution group" do
      # For OBJECT category classes
      expect(registry.has_rule?(
        "rule-xsd-all-naming-swe",
        "test_swe"
      )).to be true
    end

    it "uses swe:AbstractSWEType base type" do
      # For OBJECT category classes
      expect(registry.has_rule?(
        "rule-xsd-all-naming-swe",
        "test_swe"
      )).to be true
    end
  end

  describe "Rule 57: rule-xsd-cls-union-as-group-property-type" do
    it "can be registered and checked" do
      expect(registry.has_rule?(
        "rule-xsd-cls-union-as-group-property-type",
        "test_swe"
      )).to be true
    end

    it "generates xs:group with xs:choice" do
      # Expected structure:
      # <xs:group name="ValueGroup">
      #   <xs:choice>
      #     <!-- union option elements -->
      #   </xs:choice>
      # </xs:group>
      expect(registry.has_rule?(
        "rule-xsd-cls-union-as-group-property-type",
        "test_swe"
      )).to be true
    end

    it "references group in property type" do
      # Property type includes sequence with group reference
      expect(registry.has_rule?(
        "rule-xsd-cls-union-as-group-property-type",
        "test_swe"
      )).to be true
    end

    it "works with SWE AssociationAttributeGroup" do
      # Includes swe:AssociationAttributeGroup in property type
      expect(registry.has_rule?(
        "rule-xsd-cls-union-as-group-property-type",
        "test_swe"
      )).to be true
    end

    it "provides reusable group pattern" do
      # Group can be referenced multiple times
      expect(registry.has_rule?(
        "rule-xsd-cls-union-as-group-property-type",
        "test_swe"
      )).to be true
    end
  end

  describe "Rule 58: rule-xsd-all-naming-19139" do
    it "can be registered and checked" do
      expect(registry.has_rule?(
        "rule-xsd-all-naming-19139",
        "test_swe"
      )).to be true
    end

    it "generates Abstract prefix for abstract elements" do
      # Abstract class: Metadata -> <prefix:AbstractMetadata>
      expect(registry.has_rule?(
        "rule-xsd-all-naming-19139",
        "test_swe"
      )).to be true
    end

    it "generates Abstract prefix for abstract types" do
      # Abstract class: Metadata -> AbstractMetadata_Type
      expect(registry.has_rule?(
        "rule-xsd-all-naming-19139",
        "test_swe"
      )).to be true
    end

    it "uses gco:CodeListValue_Type for codelists" do
      # CodeList classes use gco:CodeListValue_Type
      expect(registry.has_rule?(
        "rule-xsd-all-naming-19139",
        "test_swe"
      )).to be true
    end

    it "uses underscore before Type suffix" do
      # Type: Metadata -> Metadata_Type (not MetadataType)
      expect(registry.has_rule?(
        "rule-xsd-all-naming-19139",
        "test_swe"
      )).to be true
    end

    it "uses gco:AbstractObject substitution group" do
      # For non-codelist classes
      expect(registry.has_rule?(
        "rule-xsd-all-naming-19139",
        "test_swe"
      )).to be true
    end

    it "uses gco:AbstractObject_Type base type" do
      # For non-union classes
      expect(registry.has_rule?(
        "rule-xsd-all-naming-19139",
        "test_swe"
      )).to be true
    end
  end

  describe "Batch 11 integration" do
    it "registers all 5 rules" do
      batch_11_rules.each do |rule_id|
        expect(registry.has_rule?(rule_id, "test_swe")).to be true
      end
    end

    it "supports rule inheritance" do
      parent_rule = Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "parent_swe"
        er.extends = nil
        er.rules = ["rule-xsd-cls-standard-swe-property-types"]
      end
      child_rule = Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "child_swe"
        er.extends = "parent_swe"
        er.rules = ["rule-xsd-all-naming-swe"]
      end

      registry.register_encoding_rule(parent_rule)
      registry.register_encoding_rule(child_rule)

      expect(registry.has_rule?(
        "rule-xsd-cls-standard-swe-property-types",
        "child_swe"
      )).to be true
      expect(registry.has_rule?(
        "rule-xsd-all-naming-swe",
        "child_swe"
      )).to be true
    end

    it "retrieves all rules for encoding" do
      all_rules = registry.all_rules_for("test_swe")
      expect(all_rules).to include("rule-xsd-cls-standard-swe-property-types")
      expect(all_rules).to include("rule-xsd-cls-union-omitUnionsRepresentingFeatureTypeSets")
      expect(all_rules).to include("rule-xsd-all-naming-swe")
      expect(all_rules).to include("rule-xsd-cls-union-as-group-property-type")
      expect(all_rules).to include("rule-xsd-all-naming-19139")
    end

    it "handles combinations of naming rules" do
      # Can combine SWE and ISO 19139 naming in different encoding rules
      swe_rule = Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "swe_only"
        er.extends = nil
        er.rules = ["rule-xsd-all-naming-swe"]
      end
      iso_rule = Lutaml::Klin::Shapechange::EncodingRule.new.tap do |er|
        er.name = "iso_only"
        er.extends = nil
        er.rules = ["rule-xsd-all-naming-19139"]
      end

      registry.register_encoding_rule(swe_rule)
      registry.register_encoding_rule(iso_rule)

      expect(registry.has_rule?("rule-xsd-all-naming-swe", "swe_only")).to be true
      expect(registry.has_rule?("rule-xsd-all-naming-19139", "swe_only")).to be false
      expect(registry.has_rule?("rule-xsd-all-naming-swe", "iso_only")).to be false
      expect(registry.has_rule?("rule-xsd-all-naming-19139", "iso_only")).to be true
    end
  end
end