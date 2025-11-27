# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/services/validation_service"
require "lutaml/klin/models/mapping/schema_mapping"
require "lutaml/klin/models/mapping/package_mapping"
require "lutaml/klin/models/mapping/class_mapping"
require "lutaml/klin/models/mapping/attribute_mapping"

RSpec.describe Lutaml::Klin::Domain::Services::ValidationService do
  let(:service) { described_class.new }

  # Helper to create test attribute mappings
  def create_attribute(name, status, uml_type = "String", error = nil)
    Lutaml::Klin::Mapping::AttributeMapping.new.tap do |attr|
      attr.uml_name = name
      attr.resolution_status = status
      attr.uml_type = uml_type
      attr.resolution_error = error
      attr.resolution_method = status == "resolved" ? "TypeOverride" : nil
      attr.xsd_type = status == "resolved" ? "string" : nil
    end
  end

  # Helper to create test class mappings
  def create_class(name, status, attributes = [])
    Lutaml::Klin::Mapping::ClassMapping.new.tap do |cls|
      cls.uml_name = name
      cls.resolution_status = status
      cls.resolution_method = status == "resolved" ? "ShapeChange" : nil
      cls.xsd_name = status == "resolved" ? name : nil
      cls.attribute_mappings = attributes
    end
  end

  # Helper to create test package mappings
  def create_package(name, namespace, classes = [])
    Lutaml::Klin::Mapping::PackageMapping.new.tap do |pkg|
      pkg.uml_package_name = name
      pkg.xsd_namespace = namespace
      pkg.class_mappings = classes
    end
  end

  describe "#validate" do
    context "with fully resolved mapping" do
      it "returns valid result with no unresolved items" do
        attr1 = create_attribute("prop1", "resolved")
        attr2 = create_attribute("prop2", "resolved")
        class1 = create_class("Class1", "resolved", [attr1, attr2])
        package1 = create_package("Package1", "http://example.com", [class1])

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1]
        end

        result = service.validate(schema_mapping)

        expect(result).to be_a(Lutaml::Klin::Domain::ValidationResult)
        expect(result.valid?).to be true
        expect(result.unresolved_items).to be_empty
        expect(result.resolution_rate).to eq(100.0)
      end
    end

    context "with unresolved attributes" do
      it "returns invalid result with unresolved items" do
        attr1 = create_attribute("prop1", "resolved")
        attr2 = create_attribute(
          "prop2",
          "unresolved",
          "CustomType",
          "Type not found in XSD repository"
        )
        class1 = create_class("Class1", "resolved", [attr1, attr2])
        package1 = create_package(
          "Package1",
          "http://example.com",
          [class1]
        )

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1]
        end

        result = service.validate(schema_mapping)

        expect(result.valid?).to be false
        expect(result.unresolved_items.size).to eq(1)

        unresolved = result.unresolved_items.first
        expect(unresolved[:type]).to eq("attribute")
        expect(unresolved[:package]).to eq("Package1")
        expect(unresolved[:class]).to eq("Class1")
        expect(unresolved[:attribute]).to eq("prop2")
        expect(unresolved[:uml_type]).to eq("CustomType")
        expect(unresolved[:error]).to eq("Type not found in XSD repository")
        expect(unresolved[:suggestions]).to be_an(Array)
        expect(unresolved[:suggestions]).not_to be_empty
      end
    end

    context "with partial resolution" do
      it "includes partial items in unresolved list" do
        attr1 = create_attribute(
          "prop1",
          "partial",
          "PartialType",
          "Namespace not mapped"
        )
        class1 = create_class("Class1", "resolved", [attr1])
        package1 = create_package("Package1", "http://example.com", [class1])

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1]
        end

        result = service.validate(schema_mapping)

        expect(result.valid?).to be false
        expect(result.unresolved_items.size).to eq(1)
        expect(result.unresolved_items.first[:status]).to eq("partial")
      end
    end

    context "with multiple packages" do
      it "analyzes all packages and aggregates statistics" do
        # Package 1 - fully resolved
        attr1 = create_attribute("prop1", "resolved")
        class1 = create_class("Class1", "resolved", [attr1])
        package1 = create_package("Package1", "http://example.com/1", [class1])

        # Package 2 - has unresolved
        attr2 = create_attribute("prop2", "resolved")
        attr3 = create_attribute(
          "prop3",
          "unresolved",
          "UnknownType",
          "Type not found"
        )
        class2 = create_class("Class2", "resolved", [attr2, attr3])
        package2 = create_package("Package2", "http://example.com/2", [class2])

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1, package2]
        end

        result = service.validate(schema_mapping)

        expect(result.total_packages).to eq(2)
        expect(result.total_classes).to eq(2)
        expect(result.resolved_classes).to eq(2)
        expect(result.total_attributes).to eq(3)
        expect(result.resolved_attributes).to eq(2)
        expect(result.unresolved_items.size).to eq(1)
      end
    end

    context "with empty schema mapping" do
      it "returns valid result with zero statistics" do
        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = []
        end

        result = service.validate(schema_mapping)

        expect(result.valid?).to be true
        expect(result.total_packages).to eq(0)
        expect(result.total_classes).to eq(0)
        expect(result.resolution_rate).to eq(0.0)
      end
    end

    describe "suggestions generation" do
      it "provides specific suggestions for 'not found' errors" do
        attr = create_attribute(
          "prop",
          "unresolved",
          "CustomType",
          "Type not found in XSD repository"
        )
        class1 = create_class("Class1", "resolved", [attr])
        package1 = create_package("Package1", "http://example.com", [class1])

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1]
        end

        result = service.validate(schema_mapping)
        suggestions = result.unresolved_items.first[:suggestions]

        expect(suggestions).to include(
          match(/Verify that type 'CustomType'/)
        )
        expect(suggestions).to include(match(/Check namespace mappings/))
      end

      it "provides namespace-specific suggestions" do
        attr = create_attribute(
          "prop",
          "unresolved",
          "Type",
          "Invalid namespace mapping"
        )
        class1 = create_class("Class1", "resolved", [attr])
        package1 = create_package("Package1", "http://example.com", [class1])

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1]
        end

        result = service.validate(schema_mapping)
        suggestions = result.unresolved_items.first[:suggestions]

        expect(suggestions).to include(
          match(/Add namespace mapping/)
        )
      end

      it "provides custom class suggestions for capitalized types" do
        attr = create_attribute(
          "prop",
          "unresolved",
          "CustomClass",
          "Unknown error"
        )
        class1 = create_class("Class1", "resolved", [attr])
        package1 = create_package("Package1", "http://example.com", [class1])

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1]
        end

        result = service.validate(schema_mapping)
        suggestions = result.unresolved_items.first[:suggestions]

        expect(suggestions).to include(
          match(/appears to be a custom class/)
        )
        expect(suggestions).to include(match(/type override mapping/))
      end

      it "provides generic suggestions when no specific match" do
        attr = create_attribute(
          "prop",
          "unresolved",
          "type",
          "Generic error"
        )
        class1 = create_class("Class1", "resolved", [attr])
        package1 = create_package("Package1", "http://example.com", [class1])

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1]
        end

        result = service.validate(schema_mapping)
        suggestions = result.unresolved_items.first[:suggestions]

        expect(suggestions).to include(
          match(/Review the resolution error/)
        )
      end
    end

    describe "package details" do
      it "includes package-level statistics" do
        attr1 = create_attribute("prop1", "resolved")
        attr2 = create_attribute("prop2", "unresolved", "Type", "Error")
        class1 = create_class("Class1", "resolved", [attr1, attr2])
        package1 = create_package("Package1", "http://example.com", [class1])

        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
          sm.package_mappings = [package1]
        end

        result = service.validate(schema_mapping)
        package_detail = result.packages.first

        expect(package_detail[:name]).to eq("Package1")
        expect(package_detail[:namespace]).to eq("http://example.com")
        expect(package_detail[:statistics]).to be_a(Hash)
        expect(package_detail[:resolution_rate]).to be_a(Float)
        expect(package_detail[:fully_resolved]).to be false
        expect(package_detail[:classes]).to be_an(Array)
      end
    end
  end
end
