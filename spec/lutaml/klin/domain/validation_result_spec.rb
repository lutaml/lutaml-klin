# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/validation_result"

RSpec.describe Lutaml::Klin::Domain::ValidationResult do
  let(:summary) do
    {
      total_packages: 3,
      total_classes: 174,
      resolved_classes: 170,
      partial_classes: 2,
      unresolved_classes: 2,
      total_attributes: 1250,
      resolved_attributes: 1200,
      partial_attributes: 30,
      unresolved_attributes: 20,
      resolution_rate: 97.7,
      attribute_resolution_rate: 96.0
    }
  end

  let(:unresolved_items) do
    [
      {
        type: "attribute",
        package: "ModelRoot::i-UR::urf",
        class: "UrbanPlanningArea",
        attribute: "customProperty",
        uml_type: "CustomType",
        status: "unresolved",
        error: "Type not found in XSD repository",
        suggestions: ["Check namespace mappings", "Verify type exists"]
      }
    ]
  end

  let(:packages) do
    [
      {
        name: "ModelRoot::i-UR::urf",
        namespace: "http://www.opengis.net/citygml/urbanplanning/2.0",
        statistics: {
          "total_classes" => 58,
          "resolved_classes" => 57,
          "total_attributes" => 420,
          "resolved_attributes" => 410
        },
        resolution_rate: 98.3,
        fully_resolved: false,
        classes: []
      }
    ]
  end

  describe "#initialize" do
    it "creates a validation result with all attributes" do
      result = described_class.new(
        summary: summary,
        unresolved_items: unresolved_items,
        packages: packages
      )

      expect(result.summary).to eq(summary)
      expect(result.unresolved_items).to eq(unresolved_items)
      expect(result.packages).to eq(packages)
      expect(result.global_issues).to eq([])
      expect(result.generated_at).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end

    it "accepts custom generated_at timestamp" do
      timestamp = "2025-10-25T16:00:00Z"
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: [],
        generated_at: timestamp
      )

      expect(result.generated_at).to eq(timestamp)
    end

    it "accepts global issues" do
      global_issues = [{ issue: "Missing namespace" }]
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: [],
        global_issues: global_issues
      )

      expect(result.global_issues).to eq(global_issues)
    end

    it "freezes all attributes" do
      result = described_class.new(
        summary: summary,
        unresolved_items: unresolved_items,
        packages: packages
      )

      expect(result).to be_frozen
      expect(result.summary).to be_frozen
      expect(result.unresolved_items).to be_frozen
      expect(result.packages).to be_frozen
    end
  end

  describe "#valid?" do
    it "returns true when no unresolved items" do
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: packages
      )

      expect(result.valid?).to be true
    end

    it "returns false when there are unresolved items" do
      result = described_class.new(
        summary: summary,
        unresolved_items: unresolved_items,
        packages: packages
      )

      expect(result.valid?).to be false
    end
  end

  describe "#resolution_rate" do
    it "returns the resolution rate from summary" do
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: []
      )

      expect(result.resolution_rate).to eq(97.7)
    end

    it "returns 0.0 when resolution_rate not in summary" do
      result = described_class.new(
        summary: {},
        unresolved_items: [],
        packages: []
      )

      expect(result.resolution_rate).to eq(0.0)
    end
  end

  describe "#total_packages" do
    it "returns total packages from summary" do
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: []
      )

      expect(result.total_packages).to eq(3)
    end
  end

  describe "#total_classes" do
    it "returns total classes from summary" do
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: []
      )

      expect(result.total_classes).to eq(174)
    end
  end

  describe "#resolved_classes" do
    it "returns resolved classes from summary" do
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: []
      )

      expect(result.resolved_classes).to eq(170)
    end
  end

  describe "#total_attributes" do
    it "returns total attributes from summary" do
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: []
      )

      expect(result.total_attributes).to eq(1250)
    end
  end

  describe "#resolved_attributes" do
    it "returns resolved attributes from summary" do
      result = described_class.new(
        summary: summary,
        unresolved_items: [],
        packages: []
      )

      expect(result.resolved_attributes).to eq(1200)
    end
  end

  describe "#unresolved_count" do
    it "returns count of unresolved items" do
      result = described_class.new(
        summary: summary,
        unresolved_items: unresolved_items,
        packages: []
      )

      expect(result.unresolved_count).to eq(1)
    end
  end

  describe "#to_s" do
    it "returns valid message when all resolved" do
      result = described_class.new(
        summary: summary.merge(
          total_classes: 100,
          resolved_classes: 100,
          resolution_rate: 100.0
        ),
        unresolved_items: [],
        packages: []
      )

      expect(result.to_s).to eq("Valid: All 100 classes resolved (100%)")
    end

    it "returns invalid message with details when unresolved" do
      result = described_class.new(
        summary: summary,
        unresolved_items: unresolved_items,
        packages: []
      )

      expect(result.to_s).to include("Invalid")
      expect(result.to_s).to include("170/174")
      expect(result.to_s).to include("97.7%")
      expect(result.to_s).to include("1 unresolved items")
    end
  end

  describe "#inspect" do
    it "returns detailed inspection string" do
      result = described_class.new(
        summary: summary,
        unresolved_items: unresolved_items,
        packages: packages
      )

      inspection = result.inspect

      expect(inspection).to include("ValidationResult")
      expect(inspection).to include("valid=false")
      expect(inspection).to include("resolution_rate=97.7%")
      expect(inspection).to include("packages=3")
      expect(inspection).to include("classes=170/174")
      expect(inspection).to include("attributes=1200/1250")
      expect(inspection).to include("unresolved=1")
    end
  end
end
