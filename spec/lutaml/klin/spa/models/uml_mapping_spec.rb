# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/models/uml_mapping"

RSpec.describe Lutaml::Klin::Spa::Models::UmlMapping do
  describe "serialization" do
    let(:mapping) do
      described_class.new.tap do |m|
        m.uml_class = "BuildingClass"
        m.uml_package = "uro"
        m.stereotype = "featureType"
        m.resolution_strategy = "type_override"
      end
    end

    it "serializes to JSON" do
      json = mapping.to_json
      expect(json).to include('"umlClass":"BuildingClass"')
      expect(json).to include('"umlPackage":"uro"')
      expect(json).to include('"stereotype":"featureType"')
      expect(json).to include('"resolutionStrategy":"type_override"')
    end

    it "deserializes from JSON" do
      json_str = mapping.to_json
      deserialized = described_class.from_json(json_str)

      expect(deserialized.uml_class).to eq("BuildingClass")
      expect(deserialized.uml_package).to eq("uro")
      expect(deserialized.stereotype).to eq("featureType")
      expect(deserialized.resolution_strategy).to eq("type_override")
    end

    it "serializes to YAML" do
      yaml = mapping.to_yaml
      expect(yaml).to include("umlClass: BuildingClass")
      expect(yaml).to include("umlPackage: uro")
    end

    it "deserializes from YAML" do
      yaml_str = mapping.to_yaml
      deserialized = described_class.from_yaml(yaml_str)

      expect(deserialized.uml_class).to eq("BuildingClass")
      expect(deserialized.resolution_strategy).to eq("type_override")
    end
  end

  describe "initialization" do
    it "creates an empty mapping" do
      mapping = described_class.new

      expect(mapping.uml_class).to be_nil
      expect(mapping.uml_package).to be_nil
      expect(mapping.stereotype).to be_nil
      expect(mapping.resolution_strategy).to be_nil
    end
  end
end
