# frozen_string_literal: true

module ApplicationTestHelpers
  # Shared mock creation helpers for application layer tests

  def create_mock_uml_repository
    double("UmlRepositoryAdapter").tap do |repo|
      allow(repo).to receive(:find_package).and_return(nil)
      allow(repo).to receive(:find_class).and_return(nil)
      allow(repo).to receive(:classes_in_package).and_return([])
      allow(repo).to receive(:enums_in_package).and_return([])
      allow(repo).to receive(:all_packages).and_return([])
      allow(repo).to receive(:statistics).and_return({
        total_packages: 0,
        total_classes: 0
      })
    end
  end

  def create_mock_xsd_repository
    double("SchemaRepositoryAdapter").tap do |repo|
      allow(repo).to receive(:find_type).and_return(nil)
      allow(repo).to receive(:resolve_type).and_return(nil)
      allow(repo).to receive(:all_namespaces).and_return([])
      allow(repo).to receive(:statistics).and_return({
        total_types: 0,
        total_elements: 0
      })
    end
  end

  def create_mock_shapechange_config
    double("ShapeChangeConfiguration").tap do |config|
      allow(config).to receive(:namespace_for_package).and_return("http://example.org")
      allow(config).to receive(:prefix_for_namespace).and_return("ex")
      allow(config).to receive(:type_mappings).and_return([])
      allow(config).to receive(:encoding_rule).and_return("iso19136_2007")
      allow(config).to receive(:xsd_map_entry).and_return(nil)
      allow(config).to receive(:package_info_for).and_return(nil)
    end
  end

  def create_mock_uml_package(name, path = nil)
    double("UmlPackage").tap do |pkg|
      allow(pkg).to receive(:name).and_return(name)
      allow(pkg).to receive(:qualified_name).and_return(path || name)
    end
  end

  def create_mock_uml_class(name, stereotype = "FeatureType", attributes = [])
    double("UmlClass").tap do |cls|
      allow(cls).to receive(:name).and_return(name)
      allow(cls).to receive(:qualified_name).and_return("ModelRoot::#{name}")
      allow(cls).to receive(:stereotype).and_return(stereotype)
      allow(cls).to receive(:attributes).and_return(attributes)
      allow(cls).to receive(:documentation).and_return("Test documentation")
      allow(cls).to receive(:respond_to?).with(:qualified_name).and_return(true)
      allow(cls).to receive(:respond_to?).with(:stereotype).and_return(true)
      allow(cls).to receive(:respond_to?).with(:documentation).and_return(true)
      allow(cls).to receive(:respond_to?).with(:attributes).and_return(true)
    end
  end

  def create_mock_uml_attribute(name, type = "String", multiplicity = "1")
    double("UmlAttribute").tap do |attr|
      allow(attr).to receive(:name).and_return(name)
      allow(attr).to receive(:type).and_return(type)
      allow(attr).to receive(:multiplicity).and_return(multiplicity)
      allow(attr).to receive(:documentation).and_return("Test attribute")
    end
  end

  def create_test_schema_mapping(num_packages: 1, num_classes: 2, num_attributes: 3)
    require "lutaml/klin/models/mapping/schema_mapping"
    require "lutaml/klin/models/mapping/package_mapping"
    require "lutaml/klin/models/mapping/class_mapping"
    require "lutaml/klin/models/mapping/attribute_mapping"

    packages = num_packages.times.map do |i|
      classes = num_classes.times.map do |j|
        attributes = num_attributes.times.map do |k|
          Lutaml::Klin::Mapping::AttributeMapping.new.tap do |attr|
            attr.uml_name = "attr#{k}"
            attr.uml_type = "String"
            attr.resolution_status = "resolved"
            attr.xsd_type = "string"
          end
        end

        Lutaml::Klin::Mapping::ClassMapping.new.tap do |cls|
          cls.uml_name = "Class#{j}"
          cls.resolution_status = "resolved"
          cls.attribute_mappings = attributes
        end
      end

      Lutaml::Klin::Mapping::PackageMapping.new.tap do |pkg|
        pkg.uml_package_name = "Package#{i}"
        pkg.xsd_namespace = "http://example.org/#{i}"
        pkg.class_mappings = classes
      end
    end

    Lutaml::Klin::Mapping::SchemaMapping.new.tap do |mapping|
      mapping.version = "1.0"
      mapping.package_mappings = packages
    end
  end
end

RSpec.configure do |config|
  config.include ApplicationTestHelpers
end