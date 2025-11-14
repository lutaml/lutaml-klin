# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Enhanced Mapping Models" do
  describe "AttributeMapping resolution tracking" do
    it "tracks resolution status and provides query methods" do
      attr = Lutaml::Klin::Mapping::AttributeMapping.new(
        uml_name: "address",
        uml_type: "String",
        uml_documentation: "The street address",
        uml_multiplicity: "0..1",
        xsd_name: "Address",
        xsd_type: "xs:string",
        xsd_documentation: "Street address element",
        xsd_min_occurs: "0",
        xsd_max_occurs: "1",
        resolution_status: "resolved",
        resolution_method: "shapechange",
        namespace: "http://example.org/schema"
      )

      expect(attr.resolved?).to be true
      expect(attr.unresolved?).to be false
      expect(attr.partial?).to be false
      expect(attr.uml_documentation).to eq("The street address")
      expect(attr.xsd_documentation).to eq("Street address element")
    end
  end

  describe "ClassMapping resolution tracking" do
    it "tracks class-level resolution and attribute statistics" do
      class_mapping = Lutaml::Klin::Mapping::ClassMapping.new(
        uml_name: "Building",
        uml_qualified_name: "Model::Building",
        uml_stereotype: "FeatureType",
        uml_documentation: "Represents a building",
        xsd_element_name: "Building",
        xsd_type_name: "BuildingType",
        xsd_namespace: "http://example.org/schema",
        xsd_documentation: "Building feature type",
        resolution_status: "resolved",
        resolution_method: "shapechange",
        resolution_confidence: 0.95,
        attribute_mappings: [
          Lutaml::Klin::Mapping::AttributeMapping.new(
            uml_name: "height",
            resolution_status: "resolved"
          ),
          Lutaml::Klin::Mapping::AttributeMapping.new(
            uml_name: "owner",
            resolution_status: "unresolved"
          )
        ]
      )

      expect(class_mapping.attribute_count).to eq(2)
      expect(class_mapping.resolved_attribute_count).to eq(1)
      expect(class_mapping.unresolved_attribute_count).to eq(1)
      expect(class_mapping.fully_resolved?).to be false
      expect(class_mapping.uml_documentation).to eq("Represents a building")
      expect(class_mapping.xsd_documentation).to eq("Building feature type")
    end
  end

  describe "PackageMapping statistics" do
    it "calculates resolution statistics across classes" do
      package = Lutaml::Klin::Mapping::PackageMapping.new(
        uml_name: "Core",
        uml_package_name: "Model::Core",
        xsd_namespace: "http://example.org/core",
        created_at: Time.now.utc.iso8601,
        class_mappings: [
          Lutaml::Klin::Mapping::ClassMapping.new(
            uml_name: "Building",
            resolution_status: "resolved",
            attribute_mappings: [
              Lutaml::Klin::Mapping::AttributeMapping.new(
                uml_name: "height",
                resolution_status: "resolved"
              )
            ]
          ),
          Lutaml::Klin::Mapping::ClassMapping.new(
            uml_name: "Road",
            resolution_status: "partial",
            attribute_mappings: [
              Lutaml::Klin::Mapping::AttributeMapping.new(
                uml_name: "width",
                resolution_status: "unresolved"
              )
            ]
          )
        ]
      )

      stats = package.calculate_statistics
      expect(stats["total_classes"]).to eq(2)
      expect(stats["resolved_classes"]).to eq(1)
      expect(stats["partial_classes"]).to eq(1)
      expect(stats["total_attributes"]).to eq(2)
      expect(stats["resolved_attributes"]).to eq(1)
      expect(stats["unresolved_attributes"]).to eq(1)

      expect(package.resolution_rate).to eq(50.0)
      expect(package.class_count).to eq(2)
      expect(package.resolved_class_count).to eq(1) # Building is fully resolved
    end
  end

  describe "SchemaMapping overall statistics" do
    it "aggregates statistics across all packages" do
      schema = Lutaml::Klin::Mapping::SchemaMapping.new(
        version: "1.0",
        source_lur: "/path/to/model.lur",
        source_lxr: "/path/to/schema.lxr",
        source_config: "/path/to/config.xml",
        package_mappings: [
          Lutaml::Klin::Mapping::PackageMapping.new(
            uml_name: "Core",
            class_mappings: [
              Lutaml::Klin::Mapping::ClassMapping.new(
                uml_name: "Building",
                resolution_status: "resolved",
                attribute_mappings: [
                  Lutaml::Klin::Mapping::AttributeMapping.new(
                    resolution_status: "resolved"
                  )
                ]
              )
            ]
          ),
          Lutaml::Klin::Mapping::PackageMapping.new(
            uml_name: "Transport",
            class_mappings: [
              Lutaml::Klin::Mapping::ClassMapping.new(
                uml_name: "Road",
                resolution_status: "unresolved",
                attribute_mappings: []
              )
            ]
          )
        ]
      )

      schema.set_timestamp!
      expect(schema.generated_at).not_to be_nil

      stats = schema.calculate_statistics
      expect(stats["total_packages"]).to eq(2)
      expect(stats["total_classes"]).to eq(2)
      expect(stats["resolved_classes"]).to eq(1)
      expect(stats["unresolved_classes"]).to eq(1)

      expect(schema.resolution_rate).to eq(50.0)
      expect(schema.package_count).to eq(2)
    end
  end

  describe "YAML serialization with enhanced models" do
    it "serializes and deserializes complete mapping with all new fields" do
      original = Lutaml::Klin::Mapping::SchemaMapping.new(
        version: "1.0",
        generated_at: "2025-01-01T00:00:00Z",
        source_lur: "/path/to/model.lur",
        source_lxr: "/path/to/schema.lxr",
        source_config: "/path/to/config.xml",
        package_mappings: [
          Lutaml::Klin::Mapping::PackageMapping.new(
            uml_name: "Core",
            created_at: "2025-01-01T00:00:00Z",
            class_mappings: [
              Lutaml::Klin::Mapping::ClassMapping.new(
                uml_name: "Building",
                uml_documentation: "A building feature",
                xsd_documentation: "Building element",
                resolution_status: "resolved",
                resolution_method: "shapechange",
                resolution_confidence: 0.95,
                attribute_mappings: [
                  Lutaml::Klin::Mapping::AttributeMapping.new(
                    uml_name: "height",
                    uml_documentation: "Building height",
                    xsd_documentation: "Height element",
                    resolution_status: "resolved",
                    resolution_method: "repository"
                  )
                ]
              )
            ]
          )
        ]
      )

      yaml = original.to_yaml
      restored = Lutaml::Klin::Mapping::SchemaMapping.from_yaml(yaml)

      expect(restored.source_lur).to eq("/path/to/model.lur")
      expect(restored.source_lxr).to eq("/path/to/schema.lxr")
      expect(restored.source_config).to eq("/path/to/config.xml")

      pkg = restored.package_mappings.first
      expect(pkg.created_at).to eq("2025-01-01T00:00:00Z")

      cls = pkg.class_mappings.first
      expect(cls.uml_documentation).to eq("A building feature")
      expect(cls.xsd_documentation).to eq("Building element")
      expect(cls.resolution_status).to eq("resolved")
      expect(cls.resolution_method).to eq("shapechange")
      expect(cls.resolution_confidence).to eq(0.95)

      attr = cls.attribute_mappings.first
      expect(attr.uml_documentation).to eq("Building height")
      expect(attr.xsd_documentation).to eq("Height element")
      expect(attr.resolution_status).to eq("resolved")
      expect(attr.resolution_method).to eq("repository")
    end
  end
end