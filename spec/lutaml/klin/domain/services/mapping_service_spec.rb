# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/services/mapping_service"
require "lutaml/klin/domain/resolution_engine"
require "lutaml/klin/domain/resolution_result"
require "lutaml/klin/domain/resolution_context"
require "ostruct"

RSpec.describe Lutaml::Klin::Domain::Services::MappingService do
  let(:mock_strategy) do
    double("strategy",
           applicable?: true,
           name: "MockStrategy")
  end

  let(:resolution_engine) do
    Lutaml::Klin::Domain::ResolutionEngine.new([mock_strategy])
  end

  let(:service) { described_class.new(resolution_engine) }

  describe "#initialize" do
    it "requires a resolution engine" do
      expect { described_class.new(resolution_engine) }.not_to raise_error
    end

    it "stores the resolution engine" do
      expect(service.resolution_engine).to eq(resolution_engine)
    end
  end

  describe "#map_class_to_xsd" do
    let(:uml_class) do
      OpenStruct.new(
        name: "Building",
        qualified_name: "ModelRoot::Core::Building",
        stereotype: "featureType",
        documentation: "Represents a building feature",
        attributes: []
      )
    end

    let(:xsd_namespace) { "http://example.org/core" }
    let(:context) do
      Lutaml::Klin::Domain::ResolutionContext.new(
        uml_package: "ModelRoot::Core",
        xsd_namespace: xsd_namespace
      )
    end

    context "when class is resolved" do
      let(:xsd_element) do
        OpenStruct.new(
          name: "Building",
          documentation: "Building element type"
        )
      end

      let(:resolved_result) do
        Lutaml::Klin::Domain::ResolutionResult.resolved(
          xsd_type: "BuildingType",
          method: "MockStrategy",
          xsd_element: xsd_element,
          metadata: { confidence: 0.95 }
        )
      end

      before do
        allow(mock_strategy).to receive(:resolve).and_return(resolved_result)
      end

      it "returns complete mapping details" do
        result = service.map_class_to_xsd(uml_class, xsd_namespace, context)

        expect(result[:uml_name]).to eq("Building")
        expect(result[:uml_qualified_name]).to eq("ModelRoot::Core::Building")
        expect(result[:uml_stereotype]).to eq("featureType")
        expect(result[:uml_documentation]).to eq("Represents a building feature")
        expect(result[:xsd_namespace]).to eq(xsd_namespace)
        expect(result[:resolution_status]).to eq("resolved")
        expect(result[:resolution_method]).to eq("MockStrategy")
        expect(result[:resolution_confidence]).to eq(0.95)
        expect(result[:xsd_element_name]).to eq("Building")
        expect(result[:xsd_type_name]).to eq("BuildingType")
        expect(result[:xsd_documentation]).to eq("Building element type")
      end
    end

    context "when class is unresolved" do
      let(:unresolved_result) do
        Lutaml::Klin::Domain::ResolutionResult.unresolved(
          error: "Type not found"
        )
      end

      before do
        allow(mock_strategy).to receive(:resolve).and_return(unresolved_result)
      end

      it "returns unresolved mapping details" do
        result = service.map_class_to_xsd(uml_class, xsd_namespace, context)

        expect(result[:uml_name]).to eq("Building")
        expect(result[:resolution_status]).to eq("unresolved")
        expect(result[:resolution_method]).to be_nil
        expect(result[:resolution_confidence]).to eq(0.0)
      end
    end
  end

  describe "#map_attribute_to_xsd" do
    let(:uml_attribute) do
      OpenStruct.new(
        name: "height",
        type: "Real",
        documentation: "Building height in meters",
        multiplicity: "0..1"
      )
    end

    let(:context) do
      Lutaml::Klin::Domain::ResolutionContext.new(
        uml_package: "ModelRoot::Core",
        xsd_namespace: "http://example.org/core"
      )
    end

    context "when attribute is resolved" do
      let(:xsd_element) do
        OpenStruct.new(
          name: "height",
          documentation: "Height element"
        )
      end

      let(:resolved_result) do
        Lutaml::Klin::Domain::ResolutionResult.resolved(
          xsd_type: "xs:double",
          method: "MockStrategy",
          xsd_element: xsd_element
        )
      end

      before do
        allow(mock_strategy).to receive(:resolve).and_return(resolved_result)
      end

      it "returns complete attribute mapping details" do
        result = service.map_attribute_to_xsd(uml_attribute, context)

        expect(result[:uml_name]).to eq("height")
        expect(result[:uml_type]).to eq("Real")
        expect(result[:uml_documentation]).to eq("Building height in meters")
        expect(result[:uml_multiplicity]).to eq("0..1")
        expect(result[:xsd_name]).to eq("height")
        expect(result[:xsd_type]).to eq("xs:double")
        expect(result[:xsd_documentation]).to eq("Height element")
        expect(result[:xsd_min_occurs]).to eq("0")
        expect(result[:xsd_max_occurs]).to eq("1")
        expect(result[:resolution_status]).to eq("resolved")
        expect(result[:resolution_method]).to eq("MockStrategy")
        expect(result[:resolution_error]).to be_nil
      end
    end

    context "when attribute is partially resolved" do
      let(:partial_result) do
        Lutaml::Klin::Domain::ResolutionResult.partial(
          xsd_type: "xs:string",
          method: "MockStrategy",
          error: "Documentation not available"
        )
      end

      before do
        allow(mock_strategy).to receive(:resolve).and_return(partial_result)
      end

      it "returns partial mapping details" do
        result = service.map_attribute_to_xsd(uml_attribute, context)

        expect(result[:xsd_type]).to eq("xs:string")
        expect(result[:resolution_status]).to eq("partial")
        expect(result[:resolution_method]).to eq("MockStrategy")
        expect(result[:resolution_error]).to eq("Documentation not available")
      end
    end

    context "when attribute is unresolved" do
      let(:unresolved_result) do
        Lutaml::Klin::Domain::ResolutionResult.unresolved(
          error: "Type not found"
        )
      end

      before do
        allow(mock_strategy).to receive(:resolve).and_return(unresolved_result)
      end

      it "returns unresolved mapping details" do
        result = service.map_attribute_to_xsd(uml_attribute, context)

        expect(result[:xsd_type]).to be_nil
        expect(result[:resolution_status]).to eq("unresolved")
        expect(result[:resolution_method]).to be_nil
        expect(result[:resolution_error]).to eq("Type not found")
      end
    end
  end

  describe "#derive_xsd_element_name" do
    it "uses the UML attribute name as-is" do
      attr = OpenStruct.new(name: "buildingHeight")
      expect(service.derive_xsd_element_name(attr)).to eq("buildingHeight")
    end
  end

  describe "#map_multiplicity" do
    it 'maps "1" to {min: "1", max: "1"}' do
      expect(service.map_multiplicity("1")).to eq(min: "1", max: "1")
    end

    it 'maps "0..1" to {min: "0", max: "1"}' do
      expect(service.map_multiplicity("0..1")).to eq(min: "0", max: "1")
    end

    it 'maps "1..*" to {min: "1", max: "unbounded"}' do
      expect(service.map_multiplicity("1..*")).to eq(min: "1", max: "unbounded")
    end

    it 'maps "0..*" to {min: "0", max: "unbounded"}' do
      expect(service.map_multiplicity("0..*")).to eq(min: "0", max: "unbounded")
    end

    it 'maps "*" to {min: "1", max: "unbounded"}' do
      expect(service.map_multiplicity("*")).to eq(min: "1", max: "unbounded")
    end

    it 'maps "2..5" to {min: "2", max: "5"}' do
      expect(service.map_multiplicity("2..5")).to eq(min: "2", max: "5")
    end

    it 'maps "3..*" to {min: "3", max: "unbounded"}' do
      expect(service.map_multiplicity("3..*")).to eq(min: "3", max: "unbounded")
    end

    it 'maps nil to {min: "1", max: "1"}' do
      expect(service.map_multiplicity(nil)).to eq(min: "1", max: "1")
    end

    it 'maps empty string to {min: "1", max: "1"}' do
      expect(service.map_multiplicity("")).to eq(min: "1", max: "1")
    end

    it 'maps unrecognized format to {min: "1", max: "1"}' do
      expect(service.map_multiplicity("invalid")).to eq(min: "1", max: "1")
    end
  end
end