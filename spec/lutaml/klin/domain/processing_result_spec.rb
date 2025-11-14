# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/processing_result"
require "lutaml/klin/domain/validation_result"
require "lutaml/klin/models/mapping/schema_mapping"

RSpec.describe Lutaml::Klin::Domain::ProcessingResult do
  let(:schema_mapping) do
    Lutaml::Klin::Mapping::SchemaMapping.new.tap do |sm|
      sm.version = "1.0"
      sm.generated_at = "2025-01-01T00:00:00Z"
    end
  end

  let(:validation_result) do
    Lutaml::Klin::Domain::ValidationResult.new(
      summary: {
        total_packages: 3,
        total_classes: 100,
        resolved_classes: 96,
        total_attributes: 500,
        resolved_attributes: 480,
        resolution_rate: 96.0
      },
      unresolved_items: [],
      packages: []
    )
  end

  let(:output_paths) do
    {
      mappings: ["output/mappings/schema.yaml"],
      validation: ["output/validation/report.json"],
      spa: "output/spa"
    }
  end

  let(:statistics) do
    {
      total_packages: 3,
      total_classes: 100,
      resolved_classes: 96,
      resolution_rate: 96.0,
      processing_time: 5.23
    }
  end

  let(:metadata) do
    {
      lur_path: "model.lur",
      lxr_path: "schemas.lxr",
      config_path: "config.xml"
    }
  end

  describe "#initialize" do
    it "creates a processing result with all attributes" do
      result = described_class.new(
        schema_mapping: schema_mapping,
        validation_result: validation_result,
        output_paths: output_paths,
        statistics: statistics,
        metadata: metadata
      )

      expect(result.schema_mapping).to eq(schema_mapping)
      expect(result.validation_result).to eq(validation_result)
      expect(result.output_paths).to eq(output_paths)
      expect(result.statistics).to eq(statistics)
      expect(result.metadata).to eq(metadata)
      expect(result.completed_at).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it "sets default values for optional parameters" do
      result = described_class.new(schema_mapping: schema_mapping)

      expect(result.validation_result).to be_nil
      expect(result.output_paths).to eq({})
      expect(result.statistics).to eq({})
      expect(result.metadata).to eq({})
    end

    it "freezes the result making it immutable" do
      result = described_class.new(schema_mapping: schema_mapping)

      expect(result).to be_frozen
      expect(result.output_paths).to be_frozen
      expect(result.statistics).to be_frozen
      expect(result.metadata).to be_frozen
    end
  end

  describe "#success?" do
    it "returns true when schema mapping exists and no validation" do
      result = described_class.new(schema_mapping: schema_mapping)

      expect(result.success?).to be true
    end

    it "returns true when validation passed" do
      result = described_class.new(
        schema_mapping: schema_mapping,
        validation_result: validation_result
      )

      expect(result.success?).to be true
    end

    it "returns false when validation failed" do
      failed_validation = Lutaml::Klin::Domain::ValidationResult.new(
        summary: { resolution_rate: 50.0 },
        unresolved_items: [{ type: "class", name: "Foo" }],
        packages: []
      )

      result = described_class.new(
        schema_mapping: schema_mapping,
        validation_result: failed_validation
      )

      expect(result.success?).to be false
    end
  end

  describe "#validation_enabled?" do
    it "returns true when validation result is present" do
      result = described_class.new(
        schema_mapping: schema_mapping,
        validation_result: validation_result
      )

      expect(result.validation_enabled?).to be true
    end

    it "returns false when validation result is nil" do
      result = described_class.new(schema_mapping: schema_mapping)

      expect(result.validation_enabled?).to be false
    end
  end

  describe "#validation_passed?" do
    it "returns true when validation is disabled" do
      result = described_class.new(schema_mapping: schema_mapping)

      expect(result.validation_passed?).to be true
    end

    it "returns true when validation passed" do
      result = described_class.new(
        schema_mapping: schema_mapping,
        validation_result: validation_result
      )

      expect(result.validation_passed?).to be true
    end
  end

  describe "statistics accessors" do
    let(:result) do
      described_class.new(
        schema_mapping: schema_mapping,
        statistics: statistics
      )
    end

    it "provides resolution_rate" do
      expect(result.resolution_rate).to eq(96.0)
    end

    it "provides total_packages" do
      expect(result.total_packages).to eq(3)
    end

    it "provides total_classes" do
      expect(result.total_classes).to eq(100)
    end

    it "provides resolved_classes" do
      expect(result.resolved_classes).to eq(96)
    end

    it "returns 0 for missing statistics" do
      empty_result = described_class.new(schema_mapping: schema_mapping)

      expect(empty_result.resolution_rate).to eq(0.0)
      expect(empty_result.total_packages).to eq(0)
    end
  end

  describe "output path accessors" do
    let(:result) do
      described_class.new(
        schema_mapping: schema_mapping,
        output_paths: output_paths
      )
    end

    it "provides mapping_paths as array" do
      expect(result.mapping_paths).to eq(["output/mappings/schema.yaml"])
    end

    it "provides validation_paths as array" do
      expect(result.validation_paths).to eq(["output/validation/report.json"])
    end

    it "provides spa_path as string" do
      expect(result.spa_path).to eq("output/spa")
    end

    it "returns empty arrays for missing paths" do
      empty_result = described_class.new(schema_mapping: schema_mapping)

      expect(empty_result.mapping_paths).to eq([])
      expect(empty_result.validation_paths).to eq([])
      expect(empty_result.spa_path).to be_nil
    end
  end

  describe "#summary" do
    it "generates a comprehensive summary" do
      result = described_class.new(
        schema_mapping: schema_mapping,
        validation_result: validation_result,
        output_paths: output_paths,
        statistics: statistics
      )

      summary = result.summary

      expect(summary).to include("Processing completed at")
      expect(summary).to include("Status: SUCCESS")
      expect(summary).to include("Packages: 3")
      expect(summary).to include("Classes: 96/100")
      expect(summary).to include("Validation: PASSED")
      expect(summary).to include("Mappings:")
      expect(summary).to include("Validation:")
      expect(summary).to include("Spa:")
    end
  end

  describe "#inspect" do
    it "provides detailed debugging information" do
      result = described_class.new(
        schema_mapping: schema_mapping,
        statistics: statistics
      )

      inspect_str = result.inspect

      expect(inspect_str).to include("ProcessingResult")
      expect(inspect_str).to include("success=true")
      expect(inspect_str).to include("resolution_rate=96.0%")
      expect(inspect_str).to include("packages=3")
      expect(inspect_str).to include("classes=96/100")
    end
  end
end