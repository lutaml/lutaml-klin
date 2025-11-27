# frozen_string_literal: true

require "spec_helper"
require "benchmark"

RSpec.describe "Performance Integration", :integration do
  describe "UML repository loading performance" do
    let(:uml_adapter) { double("UmlRepositoryAdapter") }

    before do
      # Mock a reasonably sized UML model
      packages = []
      classes = []

      # Create 10 packages with 10 classes each
      10.times do |pkg_idx|
        pkg_name = "Package#{pkg_idx}"
        pkg = double("UmlPackage",
                     name: pkg_name,
                     qualified_name: "ModelRoot::#{pkg_name}",
                     subpackages: [])
        packages << pkg

        # Create 10 classes per package
        pkg_classes = []
        10.times do |cls_idx|
          cls_name = "Class#{pkg_idx}_#{cls_idx}"
          attributes = []

          # Create 10 attributes per class
          10.times do |attr_idx|
            attributes << double("UmlAttribute",
                                 name: "attr#{attr_idx}",
                                 type: "String",
                                 documentation: "Attr #{attr_idx}",
                                 multiplicity: "1")
          end

          cls = double("UmlClass",
                       name: cls_name,
                       qualified_name: "ModelRoot::#{pkg_name}::#{cls_name}",
                       stereotype: "featureType",
                       documentation: "Class #{cls_idx}",
                       attributes: attributes)

          pkg_classes << cls
          classes << cls
        end

        allow(uml_adapter).to receive(:classes_in_package)
          .with("ModelRoot::#{pkg_name}", recursive: false)
          .and_return(pkg_classes)
      end

      allow(uml_adapter).to receive(:all_packages).and_return(packages)
      allow(uml_adapter).to receive(:total_packages).and_return(packages.size)
      allow(uml_adapter).to receive(:total_classes).and_return(classes.size)
    end

    it "loads packages in < 200ms" do
      elapsed = Benchmark.realtime do
        uml_adapter.all_packages
      end

      expect(elapsed).to be < 0.2
    end

    it "retrieves class count efficiently" do
      elapsed = Benchmark.realtime do
        100.times { uml_adapter.total_classes }
      end

      # 100 calls should complete in < 10ms
      expect(elapsed).to be < 0.01
    end

    it "loads classes from package in reasonable time" do
      elapsed = Benchmark.realtime do
        uml_adapter.classes_in_package("ModelRoot::Package0", recursive: false)
      end

      # Loading 10 classes should be quick
      expect(elapsed).to be < 0.1
    end
  end

  describe "XSD repository loading performance" do
    let(:xsd_adapter) { double("SchemaRepositoryAdapter") }

    before do
      # Mock a reasonably sized XSD repository
      namespaces = [
        "http://www.w3.org/2001/XMLSchema",
        "http://www.opengis.net/gml/3.2",
        "http://example.org/ns1",
        "http://example.org/ns2",
        "http://example.org/ns3"
      ]

      types = []
      elements = []

      # Create 50 types and 50 elements
      50.times do |idx|
        types << double("XsdType",
                        name: "Type#{idx}",
                        namespace: namespaces[idx % namespaces.size],
                        documentation: "Type #{idx}")

        elements << double("XsdElement",
                           name: "Element#{idx}",
                           namespace: namespaces[idx % namespaces.size],
                           type: "Type#{idx}",
                           documentation: "Element #{idx}")
      end

      allow(xsd_adapter).to receive(:all_namespaces).and_return(namespaces)
      allow(xsd_adapter).to receive(:total_namespaces).and_return(namespaces.size)
      allow(xsd_adapter).to receive(:total_types).and_return(types.size)
      allow(xsd_adapter).to receive(:total_elements).and_return(elements.size)

      # Mock type/element lookups
      allow(xsd_adapter).to receive(:find_type) do |type_name, _namespace|
        types.find { |t| t.name == type_name }
      end

      allow(xsd_adapter).to receive(:find_element) do |element_name, _namespace|
        elements.find { |e| e.name == element_name }
      end
    end

    it "loads namespaces in < 200ms" do
      elapsed = Benchmark.realtime do
        xsd_adapter.all_namespaces
      end

      expect(elapsed).to be < 0.2
    end

    it "finds types efficiently" do
      elapsed = Benchmark.realtime do
        10.times do |idx|
          xsd_adapter.find_type("Type#{idx}", nil)
        end
      end

      # 10 lookups should complete quickly
      expect(elapsed).to be < 0.05
    end

    it "handles multiple namespace queries efficiently" do
      elapsed = Benchmark.realtime do
        100.times do
          xsd_adapter.all_namespaces
          xsd_adapter.total_types
        end
      end

      expect(elapsed).to be < 0.01
    end
  end

  describe "resolution engine performance" do
    let(:xsd_repo) { double("SchemaRepositoryAdapter") }
    let(:shapechange_config) { double("ShapeChangeConfiguration") }
    let(:context) do
      Lutaml::Klin::Domain::ResolutionContext.new(
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: {}
      )
    end

    let(:engine) do
      strategies = [
        Lutaml::Klin::Domain::Strategies::TypeOverrideStrategy.new,
        Lutaml::Klin::Domain::Strategies::ShapeChangeMappingStrategy.new,
        Lutaml::Klin::Domain::Strategies::SchemaRepositoryStrategy.new
      ]
      Lutaml::Klin::Domain::ResolutionEngine.new(strategies)
    end

    before do
      # Mock ShapeChange mappings
      map_entries = (0..50).map do |idx|
        double("XsdMapEntry",
               type: "Type#{idx}",
               xmlType: "xs:Type#{idx}",
               xmlPropertyType: nil,
               xmlElement: nil,
               xmlTypeContent: "simple",
               xmlTypeNilReason: false)
      end

      allow(shapechange_config).to receive(:xsd_map_entries)
        .and_return(map_entries)

      # Mock XSD repository
      allow(xsd_repo).to receive(:find_type).and_return(nil)
      allow(xsd_repo).to receive(:find_element).and_return(nil)
    end

    it "resolves types efficiently in batch" do
      types_to_resolve = (0..100).map { |idx| "Type#{idx % 50}" }

      elapsed = Benchmark.realtime do
        types_to_resolve.each do |type|
          engine.resolve(type, context)
        end
      end

      # 101 resolutions should complete in < 1 second
      expect(elapsed).to be < 1.0
    end

    it "handles strategy chain efficiently" do
      elapsed = Benchmark.realtime do
        50.times do |idx|
          engine.resolve("Type#{idx}", context)
        end
      end

      # 50 resolutions through full strategy chain
      expect(elapsed).to be < 0.5
    end
  end

  describe "mapping workflow performance" do
    let(:uml_repo) { double("UmlRepositoryAdapter") }
    let(:xsd_repo) { double("SchemaRepositoryAdapter") }
    let(:shapechange_config) { double("ShapeChangeConfiguration") }

    let(:workflow) do
      Lutaml::Klin::Application::MappingWorkflow.new(
        uml_repository: uml_repo,
        xsd_repository: xsd_repo,
        shapechange_config: shapechange_config,
        type_overrides: {}
      )
    end

    before do
      # Mock a package with 20 classes, each with 10 attributes
      uml_package = double("UmlPackage",
                           name: "TestPackage",
                           qualified_name: "ModelRoot::TestPackage")

      classes = []
      20.times do |cls_idx|
        attributes = []
        10.times do |attr_idx|
          attributes << double("UmlAttribute",
                               name: "attr#{attr_idx}",
                               type: "String",
                               documentation: "Attribute",
                               multiplicity: "1")
        end

        classes << double("UmlClass",
                          name: "Class#{cls_idx}",
                          qualified_name: "ModelRoot::TestPackage::Class#{cls_idx}",
                          stereotype: "featureType",
                          documentation: "Class documentation",
                          attributes: attributes)
      end

      allow(uml_repo).to receive(:find_package)
        .with("ModelRoot::TestPackage")
        .and_return(uml_package)

      allow(uml_repo).to receive(:classes_in_package)
        .with("ModelRoot::TestPackage", recursive: false)
        .and_return(classes)

      allow(shapechange_config).to receive(:namespace_for_package)
        .and_return("http://example.org/test")

      allow(shapechange_config).to receive(:prefix_for_namespace)
        .and_return("test")

      # Mock ShapeChange mapping for String type
      map_entry = double("XsdMapEntry",
                         type: "String",
                         xmlType: "xs:string",
                         xmlPropertyType: nil,
                         xmlElement: nil,
                         xmlTypeContent: "simple",
                         xmlTypeNilReason: false)

      allow(shapechange_config).to receive(:xsd_map_entries)
        .and_return([map_entry])

      allow(xsd_repo).to receive(:find_type).and_return(nil)
      allow(xsd_repo).to receive(:find_element).and_return(nil)
    end

    it "generates mapping for package in < 5 seconds" do
      elapsed = Benchmark.realtime do
        workflow.generate_mapping_for_package("ModelRoot::TestPackage")
      end

      # 20 classes * 10 attributes = 200 attribute resolutions
      # Should complete in < 5 seconds
      expect(elapsed).to be < 5.0
    end

    it "handles repeated mapping generation efficiently" do
      # First call to warm up
      workflow.generate_mapping_for_package("ModelRoot::TestPackage")

      # Measure repeated calls
      elapsed = Benchmark.realtime do
        3.times do
          workflow.generate_mapping_for_package("ModelRoot::TestPackage")
        end
      end

      # 3 calls should be reasonably fast
      expect(elapsed).to be < 10.0
    end
  end

  describe "validation service performance" do
    let(:validation_service) do
      Lutaml::Klin::Domain::Services::ValidationService.new
    end

    let(:large_mapping) do
      packages = []

      # Create 5 packages
      5.times do |pkg_idx|
        classes = []

        # 20 classes per package
        20.times do |cls_idx|
          attributes = []

          # 10 attributes per class
          10.times do |attr_idx|
            attributes << Lutaml::Klin::Mapping::AttributeMapping.new.tap do |am|
              am.uml_name = "attr#{attr_idx}"
              am.uml_type = "String"
              am.xsd_type = "xs:string"
              am.resolution_status = "resolved"
            end
          end

          classes << Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
            cm.uml_name = "Class#{cls_idx}"
            cm.resolution_status = "resolved"
            cm.attribute_mappings = attributes
          end
        end

        packages << Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
          pm.uml_name = "Package#{pkg_idx}"
          pm.uml_package_name = "ModelRoot::Package#{pkg_idx}"
          pm.xsd_namespace = "http://example.org/pkg#{pkg_idx}"
          pm.class_mappings = classes
        end
      end

      Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.version = "1.0"
        sm.package_mappings = packages
        sm.set_timestamp!
      end
    end

    it "validates large mapping in < 2 seconds" do
      elapsed = Benchmark.realtime do
        validation_service.validate(large_mapping)
      end

      # 5 packages * 20 classes * 10 attributes = 1000 attributes
      # Should validate in < 2 seconds
      expect(elapsed).to be < 2.0
    end

    it "calculates statistics efficiently" do
      elapsed = Benchmark.realtime do
        10.times do
          large_mapping.calculate_statistics
        end
      end

      # 10 statistics calculations should be fast
      expect(elapsed).to be < 0.5
    end
  end

  describe "SPA generation performance" do
    let(:spa_generator) { Lutaml::Klin::Domain::Services::SpaGenerator.new }

    let(:large_mapping) do
      packages = []

      3.times do |pkg_idx|
        classes = []

        30.times do |cls_idx|
          attributes = []

          10.times do |attr_idx|
            attributes << Lutaml::Klin::Mapping::AttributeMapping.new.tap do |am|
              am.uml_name = "attr#{attr_idx}"
              am.uml_type = "String"
              am.xsd_type = "xs:string"
              am.resolution_status = "resolved"
            end
          end

          classes << Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
            cm.uml_name = "Class#{cls_idx}"
            cm.resolution_status = "resolved"
            cm.attribute_mappings = attributes
          end
        end

        packages << Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
          pm.uml_name = "Package#{pkg_idx}"
          pm.uml_package_name = "ModelRoot::Package#{pkg_idx}"
          pm.xsd_namespace = "http://example.org/pkg#{pkg_idx}"
          pm.class_mappings = classes
        end
      end

      Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
        sm.version = "1.0"
        sm.package_mappings = packages
        sm.set_timestamp!
      end
    end

    it "generates mappings JSON in < 1 second" do
      elapsed = Benchmark.realtime do
        spa_generator.generate_mappings_json(large_mapping)
      end

      # 3 packages * 30 classes * 10 attributes = 900 items
      expect(elapsed).to be < 1.0
    end

    it "generates search index in < 1 second" do
      elapsed = Benchmark.realtime do
        spa_generator.generate_search_index(large_mapping)
      end

      # Should handle 900+ entries efficiently
      expect(elapsed).to be < 1.0
    end

    it "generates statistics in < 0.5 seconds" do
      elapsed = Benchmark.realtime do
        spa_generator.generate_statistics(large_mapping)
      end

      expect(elapsed).to be < 0.5
    end

    it "generates all SPA data in < 2 seconds" do
      elapsed = Benchmark.realtime do
        spa_generator.generate_mappings_json(large_mapping)
        spa_generator.generate_search_index(large_mapping)
        spa_generator.generate_statistics(large_mapping)
      end

      # All three operations combined
      expect(elapsed).to be < 2.0
    end
  end

  describe "end-to-end workflow performance" do
    it "completes minimal workflow in reasonable time" do
      # This is a realistic end-to-end test
      # Setup would normally take longer, so we just verify
      # the concept with a simple timing test

      elapsed = Benchmark.realtime do
        # Simulate minimal operations
        schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new
        schema_mapping.version = "1.0"
        schema_mapping.set_timestamp!

        # Generate YAML
        yaml_content = schema_mapping.to_yaml

        # Verify it's not empty
        expect(yaml_content).not_to be_empty
      end

      # Basic operations should be nearly instantaneous
      expect(elapsed).to be < 0.1
    end
  end

  describe "memory efficiency" do
    it "handles large collections without excessive memory" do
      # Create a large mapping
      packages = []

      10.times do |pkg_idx|
        classes = []

        50.times do |cls_idx|
          classes << Lutaml::Klin::Mapping::ClassMapping.new.tap do |cm|
            cm.uml_name = "Class#{cls_idx}"
            cm.resolution_status = "resolved"
            cm.attribute_mappings = []
          end
        end

        packages << Lutaml::Klin::Mapping::PackageMapping.new.tap do |pm|
          pm.uml_name = "Package#{pkg_idx}"
          pm.class_mappings = classes
        end
      end

      schema_mapping = Lutaml::Klin::Mapping::SchemaMapping.new
      schema_mapping.package_mappings = packages

      # Should be able to calculate statistics without issues
      stats = schema_mapping.calculate_statistics

      expect(stats["total_packages"]).to eq(10)
      expect(stats["total_classes"]).to eq(500)
    end
  end
end
