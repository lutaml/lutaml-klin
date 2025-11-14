# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/resolution_context"

RSpec.describe Lutaml::Klin::Domain::ResolutionContext do
  let(:xsd_repository) { double("SchemaRepositoryAdapter") }
  let(:shapechange_config) { double("ShapeChangeConfig") }
  let(:type_overrides) { { "CharacterString" => "xs:string" } }

  describe "#initialize" do
    it "creates a context with all required parameters" do
      context = described_class.new(
        xsd_repository: xsd_repository,
        shapechange_config: shapechange_config,
        type_overrides: type_overrides
      )

      expect(context.xsd_repository).to eq(xsd_repository)
      expect(context.shapechange_config).to eq(shapechange_config)
      expect(context.type_overrides).to eq(type_overrides)
    end

    it "creates a context with empty type_overrides by default" do
      context = described_class.new(
        xsd_repository: xsd_repository,
        shapechange_config: shapechange_config
      )

      expect(context.type_overrides).to eq({})
    end

    it "raises error if xsd_repository is nil" do
      expect do
        described_class.new(
          xsd_repository: nil,
          shapechange_config: shapechange_config
        )
      end.to raise_error(ArgumentError, /xsd_repository is required/)
    end

    it "raises error if shapechange_config is nil" do
      expect do
        described_class.new(
          xsd_repository: xsd_repository,
          shapechange_config: nil
        )
      end.to raise_error(ArgumentError, /shapechange_config is required/)
    end
  end

  describe "#has_type_override?" do
    let(:context) do
      described_class.new(
        xsd_repository: xsd_repository,
        shapechange_config: shapechange_config,
        type_overrides: type_overrides
      )
    end

    it "returns true for existing override" do
      expect(context.has_type_override?("CharacterString")).to be true
    end

    it "returns false for non-existing override" do
      expect(context.has_type_override?("NonExistent")).to be false
    end
  end

  describe "#get_type_override" do
    let(:context) do
      described_class.new(
        xsd_repository: xsd_repository,
        shapechange_config: shapechange_config,
        type_overrides: type_overrides
      )
    end

    it "returns the override value for existing override" do
      expect(context.get_type_override("CharacterString")).to eq("xs:string")
    end

    it "returns nil for non-existing override" do
      expect(context.get_type_override("NonExistent")).to be_nil
    end
  end

  describe "immutability" do
    it "freezes the context object" do
      context = described_class.new(
        xsd_repository: xsd_repository,
        shapechange_config: shapechange_config
      )

      expect(context).to be_frozen
    end

    it "freezes the type_overrides hash" do
      context = described_class.new(
        xsd_repository: xsd_repository,
        shapechange_config: shapechange_config,
        type_overrides: type_overrides
      )

      expect(context.type_overrides).to be_frozen
    end
  end

  describe "#to_s" do
    it "includes override count" do
      context = described_class.new(
        xsd_repository: xsd_repository,
        shapechange_config: shapechange_config,
        type_overrides: type_overrides
      )

      expect(context.to_s).to include("1 type override")
    end
  end
end