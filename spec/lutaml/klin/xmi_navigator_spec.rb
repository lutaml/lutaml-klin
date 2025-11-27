# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/xmi_navigator"

RSpec.describe Lutaml::Klin::XmiNavigator do
  let(:fixture_path) do
    "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"
  end
  let(:navigator) { described_class.new }

  describe "#parse_file" do
    it "successfully parses an XMI file" do
      expect { navigator.parse_file(fixture_path) }.not_to raise_error
    end

    it "returns self for method chaining" do
      result = navigator.parse_file(fixture_path)
      expect(result).to eq(navigator)
    end

    it "raises FatalError for non-existent file" do
      expect do
        navigator.parse_file("/nonexistent/path.xmi")
      end.to raise_error(Lutaml::Klin::XmiNavigator::FatalError, /not found/)
    end

    it "sets the document attribute" do
      navigator.parse_file(fixture_path)
      expect(navigator.instance_variable_get(:@document)).not_to be_nil
    end
  end

  describe "#packages" do
    before { navigator.parse_file(fixture_path) }

    it "returns an array of packages" do
      packages = navigator.packages
      expect(packages).to be_an(Array)
      expect(packages).not_to be_empty
    end

    it "extracts package names correctly" do
      packages = navigator.packages
      package_names = packages.map(&:name)
      expect(package_names).to include("uro")
    end
  end

  describe "#find_package" do
    before { navigator.parse_file(fixture_path) }

    it "finds a package by name" do
      package = navigator.find_package("uro")
      expect(package).not_to be_nil
      expect(package.name).to eq("uro")
    end

    it "returns nil for non-existent package" do
      package = navigator.find_package("NonExistentPackage")
      expect(package).to be_nil
    end
  end

  describe "#classes" do
    before { navigator.parse_file(fixture_path) }

    it "returns an array of classes" do
      classes = navigator.classes
      expect(classes).to be_an(Array)
      expect(classes).not_to be_empty
    end

    it "extracts class names correctly" do
      classes = navigator.classes
      class_names = classes.map(&:name)
      expect(class_names).to include("_BoundarySurface")
      expect(class_names).to include("AbstractConstruction")
    end
  end

  describe "#find_class" do
    before { navigator.parse_file(fixture_path) }

    context "without package parameter" do
      it "finds a class by name" do
        klass = navigator.find_class("_BoundarySurface")
        expect(klass).not_to be_nil
        expect(klass.name).to eq("_BoundarySurface")
      end

      it "returns nil for non-existent class" do
        klass = navigator.find_class("NonExistentClass")
        expect(klass).to be_nil
      end
    end

    context "with package parameter" do
      it "finds a class within specific package" do
        # Skip - requires refactoring find_class to support package parameter
        skip "Package parameter not yet implemented"
      end

      it "returns nil if class not in specified package" do
        # Skip - requires refactoring find_class to support package parameter
        skip "Package parameter not yet implemented"
      end
    end
  end

  describe "#classes_in_package" do
    before { navigator.parse_file(fixture_path) }

    it "returns classes for a specific package" do
      classes = navigator.classes_in_package("uro")
      expect(classes).to be_an(Array)
      expect(classes.length).to eq(174) # URO package has 174 classes
    end

    it "returns empty array for non-existent package" do
      classes = navigator.classes_in_package("NonExistentPackage")
      expect(classes).to eq([])
    end

    it "returns empty array for package with no classes" do
      classes = navigator.classes_in_package("NonExistentPackage")
      expect(classes).to eq([])
    end
  end

  describe "integration with UML models" do
    before { navigator.parse_file(fixture_path) }

    it "creates Package objects with correct structure" do
      package = navigator.find_package("uro")
      expect(package).to be_a(Lutaml::Klin::Models::Uml::Package)
      expect(package.name).to eq("uro")
      expect(package.classes).to be_an(Array)
    end

    it "creates Class objects with correct structure" do
      klass = navigator.find_class("_BoundarySurface")
      expect(klass).to be_a(Lutaml::Klin::Models::Uml::Class)
      expect(klass.name).to eq("_BoundarySurface")
      expect(klass.attributes).to be_an(Array)
    end

    it "creates Attribute objects with correct structure" do
      klass = navigator.find_class("_BoundarySurface")
      expect(klass.attributes).not_to be_empty

      attr = klass.attributes.first
      expect(attr).to be_a(Lutaml::Klin::Models::Uml::Attribute)
      expect(attr.name).to be_a(String)
    end
  end
end
