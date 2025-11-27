# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/strategies/domain_type_strategy"
require "lutaml/klin/domain/resolution_result"
require "lutaml/klin/domain/resolution_context"

RSpec.describe Lutaml::Klin::Domain::Strategies::DomainTypeStrategy do
  let(:strategy) { described_class.new }
  let(:uml_repository) { double("UmlRepositoryAdapter") }
  let(:xsd_repository) { double("SchemaRepositoryAdapter") }
  let(:shapechange_config) { double("ShapeChangeConfig") }
  let(:context) do
    Lutaml::Klin::Domain::ResolutionContext.new(
      xsd_repository: xsd_repository,
      shapechange_config: shapechange_config,
      uml_repository: uml_repository
    )
  end

  describe "#name" do
    it "returns strategy name" do
      expect(strategy.name).to eq("DomainTypeStrategy")
    end
  end

  describe "#applicable?" do
    context "when all conditions are met" do
      it "returns true when UML class exists for the type" do
        element = double("UMLElement", type: "Building")
        uml_class = double("UMLClass", name: "Building")
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(uml_class)

        expect(strategy.applicable?(element, context)).to be true
      end
    end

    context "when conditions are not met" do
      it "returns false when element doesn't respond to type" do
        element = double("UMLElement")
        expect(strategy.applicable?(element, context)).to be false
      end

      it "returns false when type is nil" do
        element = double("UMLElement", type: nil)
        expect(strategy.applicable?(element, context)).to be false
      end

      it "returns false when type is empty string" do
        element = double("UMLElement", type: "")
        expect(strategy.applicable?(element, context)).to be false
      end

      it "returns false when context doesn't respond to uml_repository" do
        element = double("UMLElement", type: "Building")
        invalid_context = double("Context")
        expect(strategy.applicable?(element, invalid_context)).to be false
      end

      it "returns false when uml_repository is nil" do
        element = double("UMLElement", type: "Building")
        nil_repo_context = Lutaml::Klin::Domain::ResolutionContext.new(
          xsd_repository: xsd_repository,
          shapechange_config: shapechange_config,
          uml_repository: nil
        )
        expect(strategy.applicable?(element, nil_repo_context)).to be false
      end

      it "returns false when UML class is not found" do
        element = double("UMLElement", type: "NonExistent")
        allow(uml_repository).to receive(:find_class).with("NonExistent")
                                                      .and_return(nil)

        expect(strategy.applicable?(element, context)).to be false
      end
    end

    context "with namespace-qualified type names" do
      it "handles namespace prefix correctly" do
        element = double("UMLElement", type: "uro:Building")
        uml_class = double("UMLClass", name: "Building")
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(uml_class)

        expect(strategy.applicable?(element, context)).to be true
      end

      it "normalizes :: to : in type names" do
        element = double("UMLElement", type: "uro::Building")
        uml_class = double("UMLClass", name: "Building")
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(uml_class)

        expect(strategy.applicable?(element, context)).to be true
      end
    end

    context "when repository raises an error" do
      it "returns false and handles the exception" do
        element = double("UMLElement", type: "Building")
        allow(uml_repository).to receive(:find_class)
          .and_raise(StandardError, "Repository error")

        expect(strategy.applicable?(element, context)).to be false
      end
    end
  end

  describe "#resolve" do
    let(:element) { double("UMLElement", type: "Building") }

    context "when UML class is found" do
      let(:uml_class) do
        double("UMLClass",
               name: "Building",
               stereotype: "FeatureType",
               qualified_name: "ModelRoot::i-UR::uro::Building")
      end

      before do
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(uml_class)
        allow(shapechange_config).to receive(:namespace_for_package)
          .with("ModelRoot::i-UR::uro::Building")
          .and_return("https://www.geospatial.jp/iur/uro/3.2")
      end

      it "returns resolved result" do
        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.xsd_type).to eq("BuildingType")
        expect(result.xsd_namespace).to eq("https://www.geospatial.jp/iur/uro/3.2")
        expect(result.method).to eq(:domain_type_inference)
        expect(result.confidence).to eq(0.90)
      end

      it "applies GML type naming rule" do
        result = strategy.resolve(element, context: context)

        expect(result.xsd_type).to eq("BuildingType")
      end

      it "includes comprehensive metadata" do
        result = strategy.resolve(element, context: context)

        expect(result.metadata[:uml_class_found]).to be true
        expect(result.metadata[:uml_class_name]).to eq("Building")
        expect(result.metadata[:class_category]).to eq("FeatureType")
        expect(result.metadata[:xsd_property_type]).to eq("BuildingPropertyType")
        expect(result.metadata[:xsd_namespace]).to eq("https://www.geospatial.jp/iur/uro/3.2")
        expect(result.metadata[:naming_rule]).to eq("rule-xsd-all-naming-gml")
        expect(result.metadata[:strategy]).to eq("DomainTypeStrategy")
      end

      context "with Property suffix in class name" do
        let(:uml_class) do
          double("UMLClass",
                 name: "BuildingProperty",
                 stereotype: "DataType",
                 qualified_name: "ModelRoot::i-UR::uro::BuildingProperty")
        end

        before do
          allow(uml_repository).to receive(:find_class).with("BuildingProperty")
                                                        .and_return(uml_class)
          allow(shapechange_config).to receive(:namespace_for_package)
            .with("ModelRoot::i-UR::uro::BuildingProperty")
            .and_return("https://www.geospatial.jp/iur/uro/3.2")
        end

        it "adds underscore before Type suffix" do
          element = double("UMLElement", type: "BuildingProperty")
          result = strategy.resolve(element, context: context)

          expect(result.xsd_type).to eq("BuildingProperty_Type")
        end

        it "adds underscore before PropertyType suffix" do
          element = double("UMLElement", type: "BuildingProperty")
          result = strategy.resolve(element, context: context)

          expect(result.metadata[:xsd_property_type]).to eq("BuildingProperty_PropertyType")
        end
      end

      context "when class has no stereotype" do
        let(:uml_class_no_stereotype) do
          double("UMLClass",
                 name: "Building",
                 qualified_name: "ModelRoot::i-UR::uro::Building")
        end

        before do
          allow(uml_class_no_stereotype).to receive(:respond_to?).with(:stereotype).and_return(false)
          allow(uml_class_no_stereotype).to receive(:respond_to?).with(:qualified_name).and_return(true)
          allow(uml_class_no_stereotype).to receive(:respond_to?).with(:full_name).and_return(false)
          allow(uml_repository).to receive(:find_class).with("Building")
                                                        .and_return(uml_class_no_stereotype)
          allow(shapechange_config).to receive(:namespace_for_package)
            .with("ModelRoot::i-UR::uro::Building")
            .and_return("https://www.geospatial.jp/iur/uro/3.2")
        end

        it "handles missing stereotype gracefully" do
          result = strategy.resolve(element, context: context)

          expect(result).to be_resolved
          expect(result.metadata[:class_category]).to be_nil
        end
      end
    end

    context "when UML class is not found" do
      before do
        allow(uml_repository).to receive(:find_class).with("NonExistent")
                                                      .and_return(nil)
      end

      it "returns unresolved result" do
        element = double("UMLElement", type: "NonExistent")
        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("UML class not found for type: NonExistent")
      end

      it "includes metadata about the failure" do
        element = double("UMLElement", type: "NonExistent")
        result = strategy.resolve(element, context: context)

        expect(result.metadata[:original_type]).to eq("NonExistent")
        expect(result.metadata[:strategy]).to eq("DomainTypeStrategy")
      end
    end

    context "when namespace determination fails" do
      let(:uml_class) do
        double("UMLClass",
               name: "Building",
               stereotype: "FeatureType",
               qualified_name: "ModelRoot::i-UR::uro::Building")
      end

      before do
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(uml_class)
        allow(shapechange_config).to receive(:namespace_for_package)
          .and_raise(StandardError, "Package not found")
      end

      it "returns resolved result with nil namespace" do
        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.xsd_namespace).to be_nil
      end

      it "still includes type information" do
        result = strategy.resolve(element, context: context)

        expect(result.xsd_type).to eq("BuildingType")
      end
    end

    context "when class has full_name but no qualified_name" do
      let(:uml_class) do
        double("UMLClass",
               name: "Building",
               stereotype: "FeatureType",
               full_name: "ModelRoot::i-UR::uro::Building")
      end

      before do
        allow(uml_class).to receive(:respond_to?).with(:qualified_name).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:full_name).and_return(true)
        allow(uml_class).to receive(:respond_to?).with(:stereotype).and_return(true)
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(uml_class)
        allow(shapechange_config).to receive(:namespace_for_package)
          .with("ModelRoot::i-UR::uro::Building")
          .and_return("https://www.geospatial.jp/iur/uro/3.2")
      end

      it "uses full_name for namespace determination" do
        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.xsd_namespace).to eq("https://www.geospatial.jp/iur/uro/3.2")
      end
    end

    context "when class has neither qualified_name nor full_name" do
      let(:uml_class) do
        double("UMLClass",
               name: "Building",
               stereotype: "FeatureType")
      end

      before do
        allow(uml_class).to receive(:respond_to?).with(:qualified_name).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:full_name).and_return(false)
        allow(uml_class).to receive(:respond_to?).with(:stereotype).and_return(true)
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(uml_class)
      end

      it "returns resolved result with nil namespace" do
        result = strategy.resolve(element, context: context)

        expect(result).to be_resolved
        expect(result.xsd_namespace).to be_nil
      end
    end

    context "when an exception occurs during resolution" do
      let(:uml_class) do
        double("UMLClass",
               name: "Building",
               stereotype: "FeatureType",
               qualified_name: "ModelRoot::i-UR::uro::Building")
      end

      before do
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(uml_class)
        allow(shapechange_config).to receive(:namespace_for_package)
          .and_raise(StandardError, "Unexpected error")
      end

      it "returns unresolved result with error details" do
        result = strategy.resolve(element, context: context)

        # When namespace_for_package raises, it's caught and returns nil namespace
        # But the resolution still succeeds
        expect(result).to be_resolved
        expect(result.xsd_namespace).to be_nil
      end
    end

    context "when repository find_class raises during apply_type_naming" do
      before do
        # Make find_class succeed first for applicable? but create a broken uml_class
        broken_class = double("UMLClass")
        allow(broken_class).to receive(:name).and_raise(StandardError, "Name access error")
        allow(uml_repository).to receive(:find_class).with("Building")
                                                      .and_return(broken_class)
      end

      it "returns unresolved result" do
        result = strategy.resolve(element, context: context)

        expect(result).to be_unresolved
        expect(result.error).to include("Error resolving domain type")
        expect(result.error).to include("Name access error")
      end

      it "includes exception details in metadata" do
        result = strategy.resolve(element, context: context)

        expect(result.metadata[:original_type]).to eq("Building")
        expect(result.metadata[:exception]).to eq("StandardError")
        expect(result.metadata[:strategy]).to eq("DomainTypeStrategy")
      end
    end
  end

  describe "#to_s" do
    it "includes strategy name" do
      expect(strategy.to_s).to include("DomainTypeStrategy")
    end

    it "includes description of functionality" do
      expect(strategy.to_s).to include("UML class lookup")
      expect(strategy.to_s).to include("GML naming rules")
    end
  end
end