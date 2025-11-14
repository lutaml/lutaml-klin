# frozen_string_literal: true

require "spec_helper"

RSpec.describe "LUR and LXR Package Loading Integration", :integration do
  let(:fixtures_dir) { File.join(__dir__, "../fixtures/integration") }

  describe "UML Repository (LUR) loading" do
    context "when LUR package exists" do
      let(:uml_adapter) { double("UmlRepositoryAdapter") }

      before do
        # Mock a simple UML package structure
        root_package = double("UmlPackage",
                              name: "ModelRoot",
                              qualified_name: "ModelRoot",
                              subpackages: [])

        test_package = double("UmlPackage",
                              name: "TestPackage",
                              qualified_name: "ModelRoot::TestPackage",
                              subpackages: [])

        test_class = double("UmlClass",
                            name: "TestClass",
                            qualified_name: "ModelRoot::TestPackage::TestClass",
                            stereotype: "featureType",
                            documentation: "Test class",
                            attributes: [
                              double("UmlAttribute",
                                     name: "id",
                                     type: "Integer",
                                     documentation: "ID",
                                     multiplicity: "1"),
                              double("UmlAttribute",
                                     name: "name",
                                     type: "String",
                                     documentation: "Name",
                                     multiplicity: "1"),
                            ])

        allow(uml_adapter).to receive(:all_packages)
          .and_return([root_package, test_package])

        allow(uml_adapter).to receive(:find_package)
          .with("ModelRoot::TestPackage")
          .and_return(test_package)

        allow(uml_adapter).to receive(:classes_in_package)
          .with("ModelRoot::TestPackage", recursive: false)
          .and_return([test_class])

        allow(uml_adapter).to receive(:total_packages).and_return(2)
        allow(uml_adapter).to receive(:total_classes).and_return(1)
      end

      it "loads UML repository successfully" do
        packages = uml_adapter.all_packages
        expect(packages).not_to be_empty
        expect(packages.size).to eq(2)

        # Verify package structure
        test_pkg = uml_adapter.find_package("ModelRoot::TestPackage")
        expect(test_pkg).not_to be_nil
        expect(test_pkg.name).to eq("TestPackage")
        expect(test_pkg.qualified_name).to eq("ModelRoot::TestPackage")
      end

      it "loads classes from package" do
        classes = uml_adapter.classes_in_package(
          "ModelRoot::TestPackage",
          recursive: false
        )

        expect(classes).not_to be_empty
        expect(classes.size).to eq(1)

        test_class = classes.first
        expect(test_class.name).to eq("TestClass")
        expect(test_class.stereotype).to eq("featureType")
        expect(test_class.attributes.size).to eq(2)
      end

      it "reports statistics correctly" do
        expect(uml_adapter.total_packages).to eq(2)
        expect(uml_adapter.total_classes).to eq(1)
      end

      it "loads attributes with correct types" do
        classes = uml_adapter.classes_in_package(
          "ModelRoot::TestPackage",
          recursive: false
        )

        test_class = classes.first
        id_attr = test_class.attributes.find { |a| a.name == "id" }
        name_attr = test_class.attributes.find { |a| a.name == "name" }

        expect(id_attr.type).to eq("Integer")
        expect(name_attr.type).to eq("String")
      end
    end

    context "when LUR package is invalid" do
      let(:uml_adapter) { double("UmlRepositoryAdapter") }

      it "provides clear error when package not found" do
        allow(uml_adapter).to receive(:find_package)
          .with("NonExistent::Package")
          .and_return(nil)

        package = uml_adapter.find_package("NonExistent::Package")
        expect(package).to be_nil
      end

      it "handles empty package gracefully" do
        empty_package = double("UmlPackage",
                               name: "EmptyPackage",
                               qualified_name: "ModelRoot::EmptyPackage",
                               subpackages: [])

        allow(uml_adapter).to receive(:find_package)
          .with("ModelRoot::EmptyPackage")
          .and_return(empty_package)

        allow(uml_adapter).to receive(:classes_in_package)
          .with("ModelRoot::EmptyPackage", recursive: false)
          .and_return([])

        package = uml_adapter.find_package("ModelRoot::EmptyPackage")
        expect(package).not_to be_nil

        classes = uml_adapter.classes_in_package(
          "ModelRoot::EmptyPackage",
          recursive: false
        )
        expect(classes).to be_empty
      end
    end
  end

  describe "XSD Repository (LXR) loading" do
    context "when LXR package exists" do
      let(:xsd_adapter) { double("SchemaRepositoryAdapter") }

      before do
        # Mock XSD namespace structure
        gml_namespace = "http://www.opengis.net/gml/3.2"
        test_namespace = "http://example.org/test"

        # Mock XSD types
        string_type = double("XsdType",
                             name: "string",
                             namespace: "http://www.w3.org/2001/XMLSchema",
                             documentation: "String type")

        integer_type = double("XsdType",
                              name: "integer",
                              namespace: "http://www.w3.org/2001/XMLSchema",
                              documentation: "Integer type")

        test_type = double("XsdType",
                           name: "TestClassType",
                           namespace: test_namespace,
                           documentation: "Test complex type")

        # Mock XSD elements
        test_element = double("XsdElement",
                              name: "TestClass",
                              namespace: test_namespace,
                              type: "TestClassType",
                              documentation: "Test element")

        allow(xsd_adapter).to receive(:all_namespaces)
          .and_return([
                        "http://www.w3.org/2001/XMLSchema",
                        gml_namespace,
                        test_namespace,
                      ])

        allow(xsd_adapter).to receive(:find_type) do |type_name, namespace|
          case type_name
          when "string"
            string_type
          when "integer"
            integer_type
          when "TestClassType"
            test_type
          else
            nil
          end
        end

        allow(xsd_adapter).to receive(:find_element) do |element_name, namespace|
          element_name == "TestClass" ? test_element : nil
        end

        allow(xsd_adapter).to receive(:types_in_namespace)
          .with(test_namespace)
          .and_return([test_type])

        allow(xsd_adapter).to receive(:elements_in_namespace)
          .with(test_namespace)
          .and_return([test_element])

        allow(xsd_adapter).to receive(:total_namespaces).and_return(3)
        allow(xsd_adapter).to receive(:total_types).and_return(3)
        allow(xsd_adapter).to receive(:total_elements).and_return(1)
      end

      it "loads XSD repository successfully" do
        namespaces = xsd_adapter.all_namespaces
        expect(namespaces).not_to be_empty
        expect(namespaces.size).to eq(3)

        # Verify standard namespaces included
        expect(namespaces).to include("http://www.w3.org/2001/XMLSchema")
        expect(namespaces).to include("http://www.opengis.net/gml/3.2")
      end

      it "finds types by name and namespace" do
        string_type = xsd_adapter.find_type("string", nil)
        expect(string_type).not_to be_nil
        expect(string_type.name).to eq("string")

        test_type = xsd_adapter.find_type("TestClassType", nil)
        expect(test_type).not_to be_nil
        expect(test_type.namespace).to eq("http://example.org/test")
      end

      it "finds elements by name" do
        test_element = xsd_adapter.find_element("TestClass", nil)
        expect(test_element).not_to be_nil
        expect(test_element.name).to eq("TestClass")
        expect(test_element.type).to eq("TestClassType")
      end

      it "reports statistics correctly" do
        expect(xsd_adapter.total_namespaces).to eq(3)
        expect(xsd_adapter.total_types).to eq(3)
        expect(xsd_adapter.total_elements).to eq(1)
      end

      it "lists types in namespace" do
        test_namespace = "http://example.org/test"
        types = xsd_adapter.types_in_namespace(test_namespace)

        expect(types).not_to be_empty
        expect(types.size).to eq(1)
        expect(types.first.name).to eq("TestClassType")
      end

      it "lists elements in namespace" do
        test_namespace = "http://example.org/test"
        elements = xsd_adapter.elements_in_namespace(test_namespace)

        expect(elements).not_to be_empty
        expect(elements.size).to eq(1)
        expect(elements.first.name).to eq("TestClass")
      end
    end

    context "when LXR package is invalid" do
      let(:xsd_adapter) { double("SchemaRepositoryAdapter") }

      it "returns nil for non-existent types" do
        allow(xsd_adapter).to receive(:find_type)
          .with("NonExistentType", nil)
          .and_return(nil)

        type = xsd_adapter.find_type("NonExistentType", nil)
        expect(type).to be_nil
      end

      it "returns nil for non-existent elements" do
        allow(xsd_adapter).to receive(:find_element)
          .with("NonExistentElement", nil)
          .and_return(nil)

        element = xsd_adapter.find_element("NonExistentElement", nil)
        expect(element).to be_nil
      end

      it "handles empty namespace gracefully" do
        allow(xsd_adapter).to receive(:types_in_namespace)
          .with("http://example.org/empty")
          .and_return([])

        allow(xsd_adapter).to receive(:elements_in_namespace)
          .with("http://example.org/empty")
          .and_return([])

        types = xsd_adapter.types_in_namespace("http://example.org/empty")
        elements = xsd_adapter.elements_in_namespace("http://example.org/empty")

        expect(types).to be_empty
        expect(elements).to be_empty
      end
    end
  end

  describe "Combined LUR and LXR loading" do
    let(:uml_adapter) { double("UmlRepositoryAdapter") }
    let(:xsd_adapter) { double("SchemaRepositoryAdapter") }

    before do
      # Setup UML side
      uml_package = double("UmlPackage",
                           name: "TestPackage",
                           qualified_name: "ModelRoot::TestPackage")

      uml_class = double("UmlClass",
                         name: "TestClass",
                         qualified_name: "ModelRoot::TestPackage::TestClass",
                         stereotype: "featureType",
                         attributes: [
                           double("UmlAttribute",
                                  name: "property",
                                  type: "PropertyType",
                                  multiplicity: "1"),
                         ])

      allow(uml_adapter).to receive(:find_package)
        .with("ModelRoot::TestPackage")
        .and_return(uml_package)

      allow(uml_adapter).to receive(:classes_in_package)
        .with("ModelRoot::TestPackage", recursive: false)
        .and_return([uml_class])

      # Setup XSD side - matching types
      xsd_type = double("XsdType",
                        name: "PropertyType",
                        namespace: "http://example.org/test")

      allow(xsd_adapter).to receive(:find_type)
        .with("PropertyType", anything)
        .and_return(xsd_type)
    end

    it "correlates UML types with XSD types" do
      # Get UML package
      uml_pkg = uml_adapter.find_package("ModelRoot::TestPackage")
      expect(uml_pkg).not_to be_nil

      # Get UML classes
      uml_classes = uml_adapter.classes_in_package(
        "ModelRoot::TestPackage",
        recursive: false
      )
      expect(uml_classes).not_to be_empty

      # Get attribute type
      test_class = uml_classes.first
      property_attr = test_class.attributes.first
      uml_type = property_attr.type

      # Resolve in XSD
      xsd_type = xsd_adapter.find_type(uml_type, nil)
      expect(xsd_type).not_to be_nil
      expect(xsd_type.name).to eq("PropertyType")

      # This demonstrates the correlation
      expect(uml_type).to eq(xsd_type.name)
    end
  end
end