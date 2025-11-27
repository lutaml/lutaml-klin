# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/repositories/uml_repository_adapter"

RSpec.describe Lutaml::Klin::Repositories::UmlRepositoryAdapter do
  let(:valid_lur_path) { "spec/fixtures/test.lur" }
  let(:mock_repository) { double("Lutaml::UmlRepository::Repository") }

  describe "#initialize" do
    context "with valid LUR package" do
      it "successfully loads the repository" do
        allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
          .with(valid_lur_path)
          .and_return(mock_repository)

        adapter = described_class.new(valid_lur_path)

        expect(adapter.repository).to eq(mock_repository)
      end
    end

    context "with invalid inputs" do
      it "raises Errno::ENOENT when LUR file does not exist" do
        non_existent_path = "non_existent.lur"
        allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
          .with(non_existent_path)
          .and_raise(Errno::ENOENT, "No such file or directory")

        expect do
          described_class.new(non_existent_path)
        end.to raise_error(Errno::ENOENT, /LUR package not found/)
      end

      it "raises error when LUR package is invalid" do
        invalid_lur_path = "spec/fixtures/invalid.lur"
        allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
          .with(invalid_lur_path)
          .and_raise(StandardError, "Invalid package format")

        expect do
          described_class.new(invalid_lur_path)
        end.to raise_error(/Failed to load LUR package/)
      end

      it "raises error when LUR package is corrupt" do
        corrupt_lur_path = "spec/fixtures/corrupt.lur"
        allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
          .with(corrupt_lur_path)
          .and_raise(StandardError, "Marshal data too short")

        expect do
          described_class.new(corrupt_lur_path)
        end.to raise_error(/Failed to load LUR package/)
      end
    end
  end

  describe "#find_package" do
    let(:adapter) do
      allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
        .with(valid_lur_path)
        .and_return(mock_repository)
      described_class.new(valid_lur_path)
    end

    context "when package exists" do
      it "returns the package" do
        package_path = "ModelRoot::i-UR::uro"
        mock_package = double("Package", name: "uro", qualified_name: package_path)
        allow(mock_repository).to receive(:find_package)
          .with(package_path)
          .and_return(mock_package)

        result = adapter.find_package(package_path)

        expect(result).to eq(mock_package)
        expect(result.name).to eq("uro")
      end

      it "handles nested package paths" do
        package_path = "ModelRoot::i-UR::uro::Building"
        mock_package = double("Package", name: "Building")
        allow(mock_repository).to receive(:find_package)
          .with(package_path)
          .and_return(mock_package)

        result = adapter.find_package(package_path)

        expect(result).to eq(mock_package)
      end
    end

    context "when package does not exist" do
      it "returns nil" do
        package_path = "NonExistent::Package"
        allow(mock_repository).to receive(:find_package)
          .with(package_path)
          .and_return(nil)

        result = adapter.find_package(package_path)

        expect(result).to be_nil
      end
    end

    context "with invalid inputs" do
      it "handles empty package path" do
        allow(mock_repository).to receive(:find_package)
          .with("")
          .and_return(nil)

        result = adapter.find_package("")

        expect(result).to be_nil
      end
    end

    context "when repository raises an error" do
      it "re-raises with context" do
        package_path = "ModelRoot::i-UR::uro"
        allow(mock_repository).to receive(:find_package)
          .with(package_path)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.find_package(package_path)
        end.to raise_error(/Error finding package 'ModelRoot::i-UR::uro'/)
      end
    end
  end

  describe "#find_class" do
    let(:adapter) do
      allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
        .with(valid_lur_path)
        .and_return(mock_repository)
      described_class.new(valid_lur_path)
    end

    context "when class exists" do
      it "returns the class by qualified name" do
        qualified_name = "ModelRoot::i-UR::uro::Building"
        mock_class = double("UmlClass", 
                           name: "Building",
                           qualified_name: qualified_name)
        allow(mock_repository).to receive(:find_class)
          .with(qualified_name)
          .and_return(mock_class)

        result = adapter.find_class(qualified_name)

        expect(result).to eq(mock_class)
        expect(result.name).to eq("Building")
      end

      it "finds classes with simple names" do
        class_name = "Building"
        mock_class = double("UmlClass", name: "Building")
        allow(mock_repository).to receive(:find_class)
          .with(class_name)
          .and_return(mock_class)

        result = adapter.find_class(class_name)

        expect(result).to eq(mock_class)
      end
    end

    context "when class does not exist" do
      it "returns nil" do
        qualified_name = "ModelRoot::NonExistent::Class"
        allow(mock_repository).to receive(:find_class)
          .with(qualified_name)
          .and_return(nil)

        result = adapter.find_class(qualified_name)

        expect(result).to be_nil
      end
    end

    context "with ambiguous class names" do
      it "handles multiple classes with same simple name" do
        # When looking up by simple name, repository returns first match
        class_name = "Building"
        mock_class = double("UmlClass", name: "Building")
        allow(mock_repository).to receive(:find_class)
          .with(class_name)
          .and_return(mock_class)

        result = adapter.find_class(class_name)

        expect(result).to eq(mock_class)
      end
    end

    context "when repository raises an error" do
      it "re-raises with context" do
        qualified_name = "ModelRoot::i-UR::uro::Building"
        allow(mock_repository).to receive(:find_class)
          .with(qualified_name)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.find_class(qualified_name)
        end.to raise_error(/Error finding class 'ModelRoot::i-UR::uro::Building'/)
      end
    end
  end

  describe "#classes_in_package" do
    let(:adapter) do
      allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
        .with(valid_lur_path)
        .and_return(mock_repository)
      described_class.new(valid_lur_path)
    end

    context "when package contains classes" do
      it "returns classes for non-recursive query" do
        package_path = "ModelRoot::i-UR::uro"
        mock_classes = [
          double("UmlClass", name: "Building"),
          double("UmlClass", name: "Road")
        ]
        allow(mock_repository).to receive(:classes_in_package)
          .with(package_path, recursive: false)
          .and_return(mock_classes)

        result = adapter.classes_in_package(package_path, recursive: false)

        expect(result).to eq(mock_classes)
        expect(result.size).to eq(2)
      end

      it "returns classes for recursive query" do
        package_path = "ModelRoot::i-UR::uro"
        mock_classes = [
          double("UmlClass", name: "Building"),
          double("UmlClass", name: "Road"),
          double("UmlClass", name: "SubpackageClass")
        ]
        allow(mock_repository).to receive(:classes_in_package)
          .with(package_path, recursive: true)
          .and_return(mock_classes)

        result = adapter.classes_in_package(package_path, recursive: true)

        expect(result).to eq(mock_classes)
        expect(result.size).to eq(3)
      end
    end

    context "when package is empty" do
      it "returns empty array" do
        package_path = "ModelRoot::Empty::Package"
        allow(mock_repository).to receive(:classes_in_package)
          .with(package_path, recursive: false)
          .and_return([])

        result = adapter.classes_in_package(package_path, recursive: false)

        expect(result).to eq([])
        expect(result).to be_empty
      end
    end

    context "with recursive flag" do
      it "defaults to non-recursive when not specified" do
        package_path = "ModelRoot::i-UR::uro"
        allow(mock_repository).to receive(:classes_in_package)
          .with(package_path, recursive: false)
          .and_return([])

        adapter.classes_in_package(package_path)

        expect(mock_repository).to have_received(:classes_in_package)
          .with(package_path, recursive: false)
      end
    end

    context "when repository raises an error" do
      it "re-raises with context" do
        package_path = "ModelRoot::i-UR::uro"
        allow(mock_repository).to receive(:classes_in_package)
          .with(package_path, recursive: false)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.classes_in_package(package_path, recursive: false)
        end.to raise_error(/Error getting classes in package 'ModelRoot::i-UR::uro'/)
      end
    end
  end

  describe "#enums_in_package" do
    let(:adapter) do
      allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
        .with(valid_lur_path)
        .and_return(mock_repository)
      described_class.new(valid_lur_path)
    end

    context "when package contains enums" do
      it "returns enums for non-recursive query" do
        package_path = "ModelRoot::i-UR::uro"
        mock_enums = [
          double("UmlEnum", name: "BuildingType"),
          double("UmlEnum", name: "RoadType")
        ]
        allow(mock_repository).to receive(:enums_in_package)
          .with(package_path, recursive: false)
          .and_return(mock_enums)

        result = adapter.enums_in_package(package_path, recursive: false)

        expect(result).to eq(mock_enums)
        expect(result.size).to eq(2)
      end

      it "returns enums for recursive query" do
        package_path = "ModelRoot::i-UR::uro"
        mock_enums = [
          double("UmlEnum", name: "BuildingType"),
          double("UmlEnum", name: "RoadType"),
          double("UmlEnum", name: "SubpackageEnum")
        ]
        allow(mock_repository).to receive(:enums_in_package)
          .with(package_path, recursive: true)
          .and_return(mock_enums)

        result = adapter.enums_in_package(package_path, recursive: true)

        expect(result).to eq(mock_enums)
        expect(result.size).to eq(3)
      end
    end

    context "when package has no enums" do
      it "returns empty array" do
        package_path = "ModelRoot::No::Enums"
        allow(mock_repository).to receive(:enums_in_package)
          .with(package_path, recursive: false)
          .and_return([])

        result = adapter.enums_in_package(package_path, recursive: false)

        expect(result).to eq([])
        expect(result).to be_empty
      end
    end

    context "with recursive flag" do
      it "defaults to non-recursive when not specified" do
        package_path = "ModelRoot::i-UR::uro"
        allow(mock_repository).to receive(:enums_in_package)
          .with(package_path, recursive: false)
          .and_return([])

        adapter.enums_in_package(package_path)

        expect(mock_repository).to have_received(:enums_in_package)
          .with(package_path, recursive: false)
      end
    end

    context "when repository raises an error" do
      it "re-raises with context" do
        package_path = "ModelRoot::i-UR::uro"
        allow(mock_repository).to receive(:enums_in_package)
          .with(package_path, recursive: false)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.enums_in_package(package_path, recursive: false)
        end.to raise_error(/Error getting enums in package 'ModelRoot::i-UR::uro'/)
      end
    end
  end

  describe "#find_classes_by_stereotype" do
    let(:adapter) do
      allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
        .with(valid_lur_path)
        .and_return(mock_repository)
      described_class.new(valid_lur_path)
    end

    context "when classes with stereotype exist" do
      it "returns matching classes" do
        stereotype = "FeatureType"
        mock_classes = [
          double("UmlClass", name: "Building", stereotype: "FeatureType"),
          double("UmlClass", name: "Road", stereotype: "FeatureType")
        ]
        allow(mock_repository).to receive(:find_classes_by_stereotype)
          .with(stereotype)
          .and_return(mock_classes)

        result = adapter.find_classes_by_stereotype(stereotype)

        expect(result).to eq(mock_classes)
        expect(result.size).to eq(2)
      end

      it "handles different stereotypes" do
        stereotype = "DataType"
        mock_class = double("UmlClass", name: "Measure", stereotype: "DataType")
        allow(mock_repository).to receive(:find_classes_by_stereotype)
          .with(stereotype)
          .and_return([mock_class])

        result = adapter.find_classes_by_stereotype(stereotype)

        expect(result).to eq([mock_class])
      end
    end

    context "when no classes match stereotype" do
      it "returns empty array" do
        stereotype = "NonExistentStereotype"
        allow(mock_repository).to receive(:find_classes_by_stereotype)
          .with(stereotype)
          .and_return([])

        result = adapter.find_classes_by_stereotype(stereotype)

        expect(result).to eq([])
        expect(result).to be_empty
      end
    end

    context "with case sensitivity" do
      it "respects case in stereotype matching" do
        # Repository behavior may vary, but adapter passes through as-is
        stereotype = "featureType"
        mock_classes = [double("UmlClass", name: "Building")]
        allow(mock_repository).to receive(:find_classes_by_stereotype)
          .with(stereotype)
          .and_return(mock_classes)

        result = adapter.find_classes_by_stereotype(stereotype)

        expect(result).to eq(mock_classes)
      end
    end

    context "when repository raises an error" do
      it "re-raises with context" do
        stereotype = "FeatureType"
        allow(mock_repository).to receive(:find_classes_by_stereotype)
          .with(stereotype)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.find_classes_by_stereotype(stereotype)
        end.to raise_error(/Error finding classes by stereotype 'FeatureType'/)
      end
    end
  end

  describe "#all_packages" do
    let(:adapter) do
      allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
        .with(valid_lur_path)
        .and_return(mock_repository)
      described_class.new(valid_lur_path)
    end

    context "when repository contains packages" do
      it "returns all packages recursively" do
        mock_packages = [
          double("Package", name: "uro", qualified_name: "ModelRoot::i-UR::uro"),
          double("Package", name: "urf", qualified_name: "ModelRoot::i-UR::urf"),
          double("Package", name: "core", qualified_name: "ModelRoot::core")
        ]
        allow(mock_repository).to receive(:list_packages)
          .with("ModelRoot", recursive: true)
          .and_return(mock_packages)

        result = adapter.all_packages

        expect(result).to eq(mock_packages)
        expect(result.size).to eq(3)
      end

      it "calls repository with correct parameters" do
        allow(mock_repository).to receive(:list_packages)
          .with("ModelRoot", recursive: true)
          .and_return([])

        adapter.all_packages

        expect(mock_repository).to have_received(:list_packages)
          .with("ModelRoot", recursive: true)
      end
    end

    context "when repository is empty" do
      it "returns empty array" do
        allow(mock_repository).to receive(:list_packages)
          .with("ModelRoot", recursive: true)
          .and_return([])

        result = adapter.all_packages

        expect(result).to eq([])
        expect(result).to be_empty
      end
    end

    context "when repository raises an error" do
      it "re-raises with context" do
        allow(mock_repository).to receive(:list_packages)
          .with("ModelRoot", recursive: true)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.all_packages
        end.to raise_error(/Error retrieving packages/)
      end
    end
  end

  describe "#statistics" do
    let(:adapter) do
      allow(Lutaml::UmlRepository::Repository).to receive(:from_package)
        .with(valid_lur_path)
        .and_return(mock_repository)
      described_class.new(valid_lur_path)
    end

    context "when repository has statistics" do
      it "returns complete statistics hash" do
        mock_stats = {
          total_packages: 58,
          total_classes: 662,
          classes_by_stereotype: {
            "FeatureType" => 174,
            "DataType" => 210,
            "CodeList" => 86
          }
        }
        allow(mock_repository).to receive(:statistics)
          .and_return(mock_stats)

        result = adapter.statistics

        expect(result).to eq(mock_stats)
        expect(result[:total_packages]).to eq(58)
        expect(result[:total_classes]).to eq(662)
      end

      it "includes classes broken down by stereotype" do
        mock_stats = {
          total_packages: 10,
          total_classes: 50,
          classes_by_stereotype: {
            "FeatureType" => 20,
            "DataType" => 30
          }
        }
        allow(mock_repository).to receive(:statistics)
          .and_return(mock_stats)

        result = adapter.statistics

        expect(result[:classes_by_stereotype]).to be_a(Hash)
        expect(result[:classes_by_stereotype]["FeatureType"]).to eq(20)
      end
    end

    context "when repository is empty" do
      it "returns statistics with zero counts" do
        mock_stats = {
          total_packages: 0,
          total_classes: 0,
          classes_by_stereotype: {}
        }
        allow(mock_repository).to receive(:statistics)
          .and_return(mock_stats)

        result = adapter.statistics

        expect(result[:total_packages]).to eq(0)
        expect(result[:total_classes]).to eq(0)
      end
    end

    context "when repository raises an error" do
      it "re-raises with context" do
        allow(mock_repository).to receive(:statistics)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.statistics
        end.to raise_error(/Error retrieving repository statistics/)
      end
    end
  end
end