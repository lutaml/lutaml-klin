# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/repositories/schema_repository_adapter"

RSpec.describe Lutaml::Klin::Repositories::SchemaRepositoryAdapter do
  let(:valid_lxr_path) { "spec/fixtures/test.lxr" }
  let(:mock_repository) { double("Lutaml::Xsd::SchemaRepository") }

  describe "#initialize" do
    context "with valid LXR package" do
      it "successfully loads the repository" do
        allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
          .with(valid_lxr_path)
          .and_return(mock_repository)

        adapter = described_class.new(valid_lxr_path)

        expect(adapter.repository).to eq(mock_repository)
      end
    end

    context "with invalid inputs" do
      it "raises Errno::ENOENT when LXR file does not exist" do
        non_existent_path = "non_existent.lxr"
        allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
          .with(non_existent_path)
          .and_raise(Errno::ENOENT, "No such file or directory")

        expect do
          described_class.new(non_existent_path)
        end.to raise_error(Errno::ENOENT, /LXR package not found/)
      end

      it "raises error when LXR package is invalid" do
        invalid_lxr_path = "spec/fixtures/invalid.lxr"
        allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
          .with(invalid_lxr_path)
          .and_raise(StandardError, "Invalid package format")

        expect do
          described_class.new(invalid_lxr_path)
        end.to raise_error(/Failed to load LXR package/)
      end

      it "raises error when LXR package is corrupt" do
        corrupt_lxr_path = "spec/fixtures/corrupt.lxr"
        allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
          .with(corrupt_lxr_path)
          .and_raise(StandardError, "Marshal data too short")

        expect do
          described_class.new(corrupt_lxr_path)
        end.to raise_error(/Failed to load LXR package/)
      end
    end
  end

  describe "#resolve_type" do
    let(:adapter) do
      allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
        .with(valid_lxr_path)
        .and_return(mock_repository)
      described_class.new(valid_lxr_path)
    end

    context "with prefixed qualified names" do
      it "resolves types with namespace prefix" do
        qualified_name = "gml:CodeType"
        mock_result = double("TypeResolutionResult",
                            resolved: true,
                            qname: qualified_name,
                            namespace: "http://www.opengis.net/gml/3.2",
                            local_name: "CodeType")
        allow(mock_repository).to receive(:find_type)
          .with(qualified_name)
          .and_return(mock_result)

        result = adapter.resolve_type(qualified_name)

        expect(result).to eq(mock_result)
        expect(result.resolved).to be true
        expect(result.local_name).to eq("CodeType")
      end

      it "resolves types with different prefixes" do
        qualified_name = "xs:string"
        mock_result = double("TypeResolutionResult",
                            resolved: true,
                            namespace: "http://www.w3.org/2001/XMLSchema")
        allow(mock_repository).to receive(:find_type)
          .with(qualified_name)
          .and_return(mock_result)

        result = adapter.resolve_type(qualified_name)

        expect(result).to eq(mock_result)
      end
    end

    context "with Clark notation" do
      it "resolves types in Clark notation" do
        qualified_name = "{http://www.opengis.net/gml/3.2}CodeType"
        mock_result = double("TypeResolutionResult",
                            resolved: true,
                            qname: qualified_name,
                            namespace: "http://www.opengis.net/gml/3.2",
                            local_name: "CodeType")
        allow(mock_repository).to receive(:find_type)
          .with(qualified_name)
          .and_return(mock_result)

        result = adapter.resolve_type(qualified_name)

        expect(result).to eq(mock_result)
        expect(result.local_name).to eq("CodeType")
      end
    end

    context "with unprefixed names" do
      it "resolves unprefixed types using default namespace" do
        qualified_name = "BuildingType"
        mock_result = double("TypeResolutionResult",
                            resolved: true,
                            local_name: "BuildingType")
        allow(mock_repository).to receive(:find_type)
          .with(qualified_name)
          .and_return(mock_result)

        result = adapter.resolve_type(qualified_name)

        expect(result).to eq(mock_result)
      end
    end

    context "when type not found" do
      it "returns unresolved result" do
        qualified_name = "NonExistent:Type"
        mock_result = double("TypeResolutionResult",
                            resolved: false,
                            error_message: "Type not found")
        allow(mock_repository).to receive(:find_type)
          .with(qualified_name)
          .and_return(mock_result)

        result = adapter.resolve_type(qualified_name)

        expect(result.resolved).to be false
        expect(result.error_message).to eq("Type not found")
      end
    end

    context "when repository raises an error" do
      it "re-raises with context" do
        qualified_name = "gml:CodeType"
        allow(mock_repository).to receive(:find_type)
          .with(qualified_name)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.resolve_type(qualified_name)
        end.to raise_error(/Error resolving type 'gml:CodeType'/)
      end
    end
  end

  describe "#find_type" do
    let(:adapter) do
      allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
        .with(valid_lxr_path)
        .and_return(mock_repository)
      described_class.new(valid_lxr_path)
    end

    context "without namespace filter" do
      it "finds type by name alone" do
        type_name = "BuildingType"
        mock_type = double("ComplexType",
                          name: "BuildingType",
                          namespace: "http://example.com/buildings")
        allow(mock_repository).to receive(:find_type)
          .with(type_name)
          .and_return(mock_type)

        result = adapter.find_type(type_name)

        expect(result).to eq(mock_type)
        expect(result.name).to eq("BuildingType")
      end

      it "returns first match when multiple types have same name" do
        type_name = "CodeType"
        mock_type = double("ComplexType", name: "CodeType")
        allow(mock_repository).to receive(:find_type)
          .with(type_name)
          .and_return(mock_type)

        result = adapter.find_type(type_name)

        expect(result).to eq(mock_type)
      end
    end

    context "with namespace filter" do
      it "finds type by name and namespace" do
        type_name = "BuildingType"
        namespace = "http://example.com/buildings"
        mock_type = double("ComplexType",
                          name: "BuildingType",
                          namespace: namespace)
        allow(mock_repository).to receive(:find_type)
          .with(type_name, namespace: namespace)
          .and_return(mock_type)

        result = adapter.find_type(type_name, namespace: namespace)

        expect(result).to eq(mock_type)
        expect(result.namespace).to eq(namespace)
      end

      it "filters by namespace to disambiguate types" do
        type_name = "CodeType"
        gml_namespace = "http://www.opengis.net/gml/3.2"
        mock_type = double("ComplexType",
                          name: "CodeType",
                          namespace: gml_namespace)
        allow(mock_repository).to receive(:find_type)
          .with(type_name, namespace: gml_namespace)
          .and_return(mock_type)

        result = adapter.find_type(type_name, namespace: gml_namespace)

        expect(result).to eq(mock_type)
      end
    end

    context "when type not found" do
      it "returns nil when type does not exist" do
        type_name = "NonExistentType"
        allow(mock_repository).to receive(:find_type)
          .with(type_name)
          .and_return(nil)

        result = adapter.find_type(type_name)

        expect(result).to be_nil
      end

      it "returns nil when namespace does not match" do
        type_name = "BuildingType"
        wrong_namespace = "http://wrong.namespace.com"
        allow(mock_repository).to receive(:find_type)
          .with(type_name, namespace: wrong_namespace)
          .and_return(nil)

        result = adapter.find_type(type_name, namespace: wrong_namespace)

        expect(result).to be_nil
      end
    end

    context "with different type kinds" do
      it "finds complex types" do
        type_name = "BuildingType"
        mock_type = double("ComplexType",
                          name: "BuildingType",
                          kind: :complex)
        allow(mock_repository).to receive(:find_type)
          .with(type_name)
          .and_return(mock_type)

        result = adapter.find_type(type_name)

        expect(result).to eq(mock_type)
      end

      it "finds simple types" do
        type_name = "CodeType"
        mock_type = double("SimpleType",
                          name: "CodeType",
                          kind: :simple)
        allow(mock_repository).to receive(:find_type)
          .with(type_name)
          .and_return(mock_type)

        result = adapter.find_type(type_name)

        expect(result).to eq(mock_type)
      end
    end

    context "with edge case inputs" do
      it "handles empty type name" do
        allow(mock_repository).to receive(:find_type)
          .with("")
          .and_return(nil)

        result = adapter.find_type("")

        expect(result).to be_nil
      end

      it "handles type names with special characters" do
        type_name = "Building-Type_v2"
        mock_type = double("ComplexType", name: type_name)
        allow(mock_repository).to receive(:find_type)
          .with(type_name)
          .and_return(mock_type)

        result = adapter.find_type(type_name)

        expect(result).to eq(mock_type)
      end
    end

    context "when repository raises an error" do
      it "re-raises with context for name-only lookup" do
        type_name = "BuildingType"
        allow(mock_repository).to receive(:find_type)
          .with(type_name)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.find_type(type_name)
        end.to raise_error(/Error finding type 'BuildingType'/)
      end

      it "re-raises with context for namespace lookup" do
        type_name = "BuildingType"
        namespace = "http://example.com"
        allow(mock_repository).to receive(:find_type)
          .with(type_name, namespace: namespace)
          .and_raise(StandardError, "Repository error")

        expect do
          adapter.find_type(type_name, namespace: namespace)
        end.to raise_error(/Error finding type 'BuildingType'/)
      end
    end
  end

  describe "#statistics" do
    let(:adapter) do
      allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
        .with(valid_lxr_path)
        .and_return(mock_repository)
      described_class.new(valid_lxr_path)
    end

    context "when repository has statistics" do
      it "returns complete statistics hash" do
        mock_stats = {
          total_schemas: 15,
          total_types: 2764,
          total_elements: 1628,
          namespaces: [
            "http://www.opengis.net/gml/3.2",
            "http://www.opengis.net/citygml/building/3.0",
            "http://www.w3.org/2001/XMLSchema"
          ]
        }
        allow(mock_repository).to receive(:statistics)
          .and_return(mock_stats)

        result = adapter.statistics

        expect(result).to eq(mock_stats)
        expect(result[:total_schemas]).to eq(15)
        expect(result[:total_types]).to eq(2764)
        expect(result[:total_elements]).to eq(1628)
      end

      it "includes namespace list" do
        mock_stats = {
          total_schemas: 5,
          total_types: 100,
          total_elements: 50,
          namespaces: [
            "http://www.opengis.net/gml/3.2",
            "http://www.w3.org/2001/XMLSchema"
          ]
        }
        allow(mock_repository).to receive(:statistics)
          .and_return(mock_stats)

        result = adapter.statistics

        expect(result[:namespaces]).to be_a(Array)
        expect(result[:namespaces].size).to eq(2)
        expect(result[:namespaces]).to include("http://www.opengis.net/gml/3.2")
      end
    end

    context "when repository is empty" do
      it "returns statistics with zero counts" do
        mock_stats = {
          total_schemas: 0,
          total_types: 0,
          total_elements: 0,
          namespaces: []
        }
        allow(mock_repository).to receive(:statistics)
          .and_return(mock_stats)

        result = adapter.statistics

        expect(result[:total_schemas]).to eq(0)
        expect(result[:total_types]).to eq(0)
        expect(result[:total_elements]).to eq(0)
        expect(result[:namespaces]).to be_empty
      end
    end

    context "with various statistics formats" do
      it "handles statistics with minimal data" do
        mock_stats = {
          total_schemas: 1,
          total_types: 10,
          total_elements: 5,
          namespaces: ["http://example.com"]
        }
        allow(mock_repository).to receive(:statistics)
          .and_return(mock_stats)

        result = adapter.statistics

        expect(result).to be_a(Hash)
        expect(result.keys).to include(:total_schemas, :total_types, :total_elements, :namespaces)
      end

      it "handles statistics with additional metadata" do
        mock_stats = {
          total_schemas: 10,
          total_types: 500,
          total_elements: 300,
          namespaces: ["http://example.com"],
          types_by_namespace: {
            "http://example.com" => 500
          }
        }
        allow(mock_repository).to receive(:statistics)
          .and_return(mock_stats)

        result = adapter.statistics

        expect(result[:types_by_namespace]).to be_a(Hash)
        expect(result[:types_by_namespace]["http://example.com"]).to eq(500)
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

  describe "integration with lutaml-xsd API" do
    let(:adapter) do
      allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
        .with(valid_lxr_path)
        .and_return(mock_repository)
      described_class.new(valid_lxr_path)
    end

    it "properly delegates all calls to underlying repository" do
      # Test that adapter is truly a thin wrapper
      type_name = "TestType"
      mock_type = double("ComplexType")
      
      allow(mock_repository).to receive(:find_type)
        .with(type_name)
        .and_return(mock_type)

      result = adapter.find_type(type_name)

      expect(mock_repository).to have_received(:find_type).with(type_name)
      expect(result).to eq(mock_type)
    end

    it "exposes repository for advanced usage" do
      # Some code may need direct repository access
      expect(adapter.repository).to eq(mock_repository)
    end
  end
end