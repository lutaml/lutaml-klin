# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/reporters/markdown_reporter"
require "lutaml/klin/domain/validation_result"

RSpec.describe Lutaml::Klin::Domain::Reporters::MarkdownReporter do
  let(:reporter) { described_class.new }

  let(:summary) do
    {
      total_packages: 2,
      total_classes: 100,
      resolved_classes: 95,
      partial_classes: 3,
      unresolved_classes: 2,
      total_attributes: 500,
      resolved_attributes: 480,
      partial_attributes: 15,
      unresolved_attributes: 5,
      resolution_rate: 95.0,
      attribute_resolution_rate: 96.0
    }
  end

  let(:unresolved_items) do
    [
      {
        type: "attribute",
        package: "Package1",
        class: "Class1",
        attribute: "prop1",
        uml_type: "CustomType",
        status: "unresolved",
        error: "Type not found",
        suggestions: ["Check namespace", "Verify type"]
      }
    ]
  end

  let(:packages) do
    [
      {
        name: "Package1",
        namespace: "http://example.com/1",
        statistics: {
          "total_classes" => 50,
          "resolved_classes" => 48,
          "total_attributes" => 250,
          "resolved_attributes" => 240
        },
        resolution_rate: 96.0,
        fully_resolved: false,
        classes: []
      }
    ]
  end

  let(:validation_result) do
    Lutaml::Klin::Domain::ValidationResult.new(
      summary: summary,
      unresolved_items: unresolved_items,
      packages: packages,
      generated_at: "2025-10-25T16:00:00Z"
    )
  end

  let(:valid_result) do
    Lutaml::Klin::Domain::ValidationResult.new(
      summary: summary.merge(
        total_classes: 100,
        resolved_classes: 100,
        resolution_rate: 100.0
      ),
      unresolved_items: [],
      packages: packages,
      generated_at: "2025-10-25T16:00:00Z"
    )
  end

  describe "#generate" do
    it "generates a Markdown file at the specified path" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        result_path = reporter.generate(validation_result, output_path)

        expect(result_path).to eq(output_path)
        expect(File.exist?(output_path)).to be true
      end
    end

    it "includes document header with title" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("# UML-to-XSD Validation Report")
      end
    end

    it "includes status indicator in header" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("**Status:** ⚠️ Invalid")
      end
    end

    it "shows valid status for fully resolved mapping" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(valid_result, output_path)
        content = File.read(output_path)

        expect(content).to include("**Status:** ✅ Valid")
      end
    end

    it "includes generated timestamp" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("**Generated:** 2025-10-25T16:00:00Z")
      end
    end

    it "includes summary section with table" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("## Summary")
        expect(content).to include("| Metric | Value | Status |")
        expect(content).to include("Resolution Rate")
        expect(content).to include("95.0%")
      end
    end

    it "includes unresolved items section when items exist" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("## Unresolved Items")
        expect(content).to include("Found 1 unresolved items")
        expect(content).to include("Package1::Class1::prop1")
        expect(content).to include("CustomType")
        expect(content).to include("Type not found")
      end
    end

    it "omits unresolved section when no unresolved items" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(valid_result, output_path)
        content = File.read(output_path)

        expect(content).not_to include("## Unresolved Items")
      end
    end

    it "includes suggestions for unresolved items" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("**Suggestions:**")
        expect(content).to include("Check namespace")
        expect(content).to include("Verify type")
      end
    end

    it "includes package details section" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("## Package Details")
        expect(content).to include("### Package1")
        expect(content).to include("http://example.com/1")
        expect(content).to include("96.0%")
      end
    end

    it "shows fully resolved status for resolved packages" do
      fully_resolved_packages = [
        packages.first.merge(fully_resolved: true)
      ]
      result = Lutaml::Klin::Domain::ValidationResult.new(
        summary: summary,
        unresolved_items: [],
        packages: fully_resolved_packages
      )

      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(result, output_path)
        content = File.read(output_path)

        expect(content).to include("✅ Fully Resolved")
      end
    end

    it "shows partial status for partially resolved packages" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("⚠️ Partial")
      end
    end

    it "includes package statistics table" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        expect(content).to include("| Metric | Count |")
        expect(content).to include("Total Classes")
        expect(content).to include("Resolved Classes")
        expect(content).to include("Total Attributes")
        expect(content).to include("Resolved Attributes")
      end
    end

    it "uses appropriate status indicators for resolution rates" do
      # Test various resolution rates
      test_cases = [
        { rate: 100.0, expected: "✅ Complete" },
        { rate: 95.0, expected: "⚠️ Near Complete" },
        { rate: 75.0, expected: "⚠️ Partial" },
        { rate: 25.0, expected: "❌ Incomplete" }
      ]

      test_cases.each do |test_case|
        result = Lutaml::Klin::Domain::ValidationResult.new(
          summary: summary.merge(resolution_rate: test_case[:rate]),
          unresolved_items: [],
          packages: []
        )

        Dir.mktmpdir do |dir|
          output_path = File.join(dir, "report.md")

          reporter.generate(result, output_path)
          content = File.read(output_path)

          expect(content).to include(test_case[:expected])
        end
      end
    end

    it "handles empty packages gracefully" do
      empty_result = Lutaml::Klin::Domain::ValidationResult.new(
        summary: summary.merge(total_packages: 0),
        unresolved_items: [],
        packages: []
      )

      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(empty_result, output_path)
        content = File.read(output_path)

        expect(content).to include("## Packages")
        expect(content).to include("_No packages found_")
      end
    end

    it "handles items with no suggestions" do
      items_without_suggestions = [
        unresolved_items.first.merge(suggestions: [])
      ]
      result = Lutaml::Klin::Domain::ValidationResult.new(
        summary: summary,
        unresolved_items: items_without_suggestions,
        packages: []
      )

      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(result, output_path)
        content = File.read(output_path)

        expect(content).to include("_No suggestions available_")
      end
    end

    it "generates well-formatted Markdown" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.md")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        # Check for proper Markdown formatting
        expect(content).to match(/^# /)  # Top-level heading
        expect(content).to match(/^## /)  # Second-level heading
        expect(content).to match(/^\| .* \|/)  # Table rows
        expect(content).to include("**")  # Bold text
        expect(content).to include("`")  # Code formatting
      end
    end
  end
end