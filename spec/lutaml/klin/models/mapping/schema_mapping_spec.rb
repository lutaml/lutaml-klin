# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Klin::Mapping::SchemaMapping do
  describe "YAML serialization" do
    it "serializes and deserializes correctly" do
      mapping = described_class.new.tap do |m|
        m.version = "1.0"
        m.generated_at = "2025-01-01T00:00:00Z"
        m.source_xmi = "model.xmi"
        m.source_config = "config.xml"
        m.namespaces = ["http://example.org/ns1", "http://example.org/ns2"]

        m.package_mappings = [
          Lutaml::Klin::Mapping::PackageMapping.new.tap do |pkg|
            pkg.uml_package_name = "TestPackage"
            pkg.xsd_namespace = "http://example.org/test"
            pkg.xsd_namespace_prefix = "test"
            pkg.xsd_schema_location = "test.xsd"

            pkg.class_mappings = [
              Lutaml::Klin::Mapping::ClassMapping.new.tap do |cls|
                cls.uml_name = "Person"
                cls.uml_package = "TestPackage"
                cls.xsd_name = "PersonType"
                cls.xsd_namespace = "http://example.org/test"
                cls.xsd_type = "complex"
                cls.stereotypes = ["featureType"]

                cls.attribute_mappings = [
                  Lutaml::Klin::Mapping::AttributeMapping.new.tap do |attr|
                    attr.uml_name = "name"
                    attr.uml_type = "String"
                    attr.xsd_name = "name"
                    attr.xsd_type = "xs:string"
                    attr.xsd_path = "test:PersonType/test:name"
                    attr.is_element = true
                    attr.min_occurs = "1"
                    attr.max_occurs = "1"
                    attr.namespace = "http://example.org/test"
                  end
                ]
              end
            ]
          end
        ]
      end

      # Serialize to YAML
      yaml_output = mapping.to_yaml

      # Verify YAML contains expected content
      expect(yaml_output).to include("version: '1.0'")
      expect(yaml_output).to include("source_xmi: model.xmi")
      expect(yaml_output).to include("uml_package_name: TestPackage")
      expect(yaml_output).to include("uml_name: Person")
      expect(yaml_output).to include("xsd_name: PersonType")

      # Deserialize from YAML
      deserialized = described_class.from_yaml(yaml_output)

      # Verify structure
      expect(deserialized.version).to eq("1.0")
      expect(deserialized.source_xmi).to eq("model.xmi")
      expect(deserialized.package_mappings.size).to eq(1)

      pkg = deserialized.package_mappings.first
      expect(pkg.uml_package_name).to eq("TestPackage")
      expect(pkg.class_mappings.size).to eq(1)

      cls = pkg.class_mappings.first
      expect(cls.uml_name).to eq("Person")
      expect(cls.xsd_name).to eq("PersonType")
      expect(cls.attribute_mappings.size).to eq(1)

      attr = cls.attribute_mappings.first
      expect(attr.uml_name).to eq("name")
      expect(attr.xsd_type).to eq("xs:string")
    end
  end
end
