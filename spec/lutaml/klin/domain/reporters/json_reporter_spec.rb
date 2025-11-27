# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/domain/reporters/json_reporter"
require "lutaml/klin/domain/validation_result"
require "json"
require "tempfile"

RSpec.describe Lutaml::Klin::Domain::Reporters::JsonReporter do
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
          "resolved_classes" => 48
        },
        resolution_rate: 96.0,
        fully_resolved: false,
        classes: [
          {
            name: "Class1",
            status: "resolved",
            method: "ShapeChange",
            xsd_name: "Class1Type",
            attributes: [
              {
                name: "prop1",
                status: "unresolved",
                method: nil,
                uml_type: "CustomType",
                xsd_type: nil,
                error: "Type not found"
              }
            ]
          }
        ]
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

  describe "#generate" do
    it "generates a JSON file at the specified path" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        result_path = reporter.generate(validation_result, output_path)

        expect(result_path).to eq(output_path)
        expect(File.exist?(output_path)).to be true
      end
    end

    it "generates valid JSON content" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)
        parsed = JSON.parse(content)

        expect(parsed).to be_a(Hash)
      end
    end

    it "includes version in output" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        parsed = JSON.parse(File.read(output_path))

        expect(parsed["version"]).to eq("1.0")
      end
    end

    it "includes generated_at timestamp" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        parsed = JSON.parse(File.read(output_path))

        expect(parsed["generated_at"]).to eq("2025-10-25T16:00:00Z")
      end
    end

    it "includes validation status" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        parsed = JSON.parse(File.read(output_path))

        expect(parsed["validation_status"]).to eq("invalid")
      end
    end

    it "includes complete summary section" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        parsed = JSON.parse(File.read(output_path))
        summary_section = parsed["summary"]

        expect(summary_section["total_packages"]).to eq(2)
        expect(summary_section["total_classes"]).to eq(100)
        expect(summary_section["resolved_classes"]).to eq(95)
        expect(summary_section["partial_classes"]).to eq(3)
        expect(summary_section["unresolved_classes"]).to eq(2)
        expect(summary_section["total_attributes"]).to eq(500)
        expect(summary_section["resolved_attributes"]).to eq(480)
        expect(summary_section["resolution_rate"]).to eq(95.0)
        expect(summary_section["attribute_resolution_rate"]).to eq(96.0)
      end
    end

    it "includes unresolved items" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        parsed = JSON.parse(File.read(output_path))
        items = parsed["unresolved_items"]

        expect(items).to be_an(Array)
        expect(items.size).to eq(1)
        expect(items.first["type"]).to eq("attribute")
        expect(items.first["package"]).to eq("Package1")
        expect(items.first["suggestions"]).to be_an(Array)
      end
    end

    it "includes package details" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        parsed = JSON.parse(File.read(output_path))
        packages_section = parsed["packages"]

        expect(packages_section).to be_an(Array)
        expect(packages_section.size).to eq(1)

        pkg = packages_section.first
        expect(pkg["name"]).to eq("Package1")
        expect(pkg["namespace"]).to eq("http://example.com/1")
        expect(pkg["statistics"]).to be_a(Hash)
        expect(pkg["resolution_rate"]).to eq(96.0)
        expect(pkg["fully_resolved"]).to be false
        expect(pkg["classes"]).to be_an(Array)
      end
    end

    it "includes class details within packages" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        parsed = JSON.parse(File.read(output_path))
        classes = parsed["packages"].first["classes"]

        expect(classes.size).to eq(1)
        cls = classes.first
        expect(cls["name"]).to eq("Class1")
        expect(cls["status"]).to eq("resolved")
        expect(cls["method"]).to eq("ShapeChange")
        expect(cls["xsd_name"]).to eq("Class1Type")
        expect(cls["attributes"]).to be_an(Array)
      end
    end

    it "includes attribute details within classes" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        parsed = JSON.parse(File.read(output_path))
        attributes = parsed["packages"].first["classes"].first["attributes"]

        expect(attributes.size).to eq(1)
        attr = attributes.first
        expect(attr["name"]).to eq("prop1")
        expect(attr["status"]).to eq("unresolved")
        expect(attr["uml_type"]).to eq("CustomType")
        expect(attr["error"]).to eq("Type not found")
      end
    end

    it "includes global issues" do
      result_with_issues = Lutaml::Klin::Domain::ValidationResult.new(
        summary: summary,
        unresolved_items: [],
        packages: [],
        global_issues: [{ issue: "Missing namespace" }]
      )

      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(result_with_issues, output_path)
        parsed = JSON.parse(File.read(output_path))

        expect(parsed["global_issues"]).to be_an(Array)
        expect(parsed["global_issues"].size).to eq(1)
      end
    end

    it "generates pretty-printed JSON" do
      Dir.mktmpdir do |dir|
        output_path = File.join(dir, "report.json")

        reporter.generate(validation_result, output_path)
        content = File.read(output_path)

        # Pretty-printed JSON should have multiple lines
        expect(content.lines.count).to be > 10
        expect(content).to include("  ") # Should have indentation
      end
    end
  end
end
