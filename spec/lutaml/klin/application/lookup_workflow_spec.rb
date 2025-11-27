# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/application/lookup_workflow"
require "tempfile"

RSpec.describe Lutaml::Klin::Application::LookupWorkflow do
  let(:mapping_file) { Tempfile.new(["test_mapping", ".yaml"]) }
  let(:schema_mapping) { create_test_schema_mapping }

  before do
    mapping_file.write(schema_mapping.to_yaml)
    mapping_file.rewind
  end

  after { mapping_file.close! }

  describe "#initialize" do
    it "loads mapping from file" do
      workflow = described_class.new(mapping_file.path)

      expect(workflow.mapping).not_to be_nil
      expect(workflow.lookup_service).not_to be_nil
    end

    it "raises error when file does not exist" do
      expect {
        described_class.new("nonexistent.yaml")
      }.to raise_error(Lutaml::Klin::Error, /Mapping file not found/)
    end

    it "raises error when file is invalid" do
      invalid_file = Tempfile.new(["invalid", ".yaml"])
      invalid_file.write("invalid: yaml: content:")
      invalid_file.rewind

      expect {
        described_class.new(invalid_file.path)
      }.to raise_error(Lutaml::Klin::Error, /Failed to load mapping file/)

      invalid_file.close!
    end
  end

  describe "#lookup_uml_to_xsd" do
    let(:workflow) { described_class.new(mapping_file.path) }

    context "with class lookup" do
      it "finds XSD for UML class" do
        result = workflow.lookup_uml_to_xsd("Class0", type: :class)

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
      end

      it "supports fuzzy matching" do
        result = workflow.lookup_uml_to_xsd("class", type: :class, fuzzy: true)

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
      end
    end

    context "with attribute lookup" do
      it "finds XSD for UML attribute" do
        result = workflow.lookup_uml_to_xsd(
          "Class0::attr0",
          type: :attribute
        )

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
      end

      it "raises error for invalid attribute format" do
        expect {
          workflow.lookup_uml_to_xsd("InvalidFormat", type: :attribute)
        }.to raise_error(Lutaml::Klin::Error, /requires format/)
      end
    end

    context "with auto-detection" do
      it "auto-detects lookup type" do
        result = workflow.lookup_uml_to_xsd("Class0", type: :auto)

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
      end
    end

    it "raises error for unknown type" do
      expect {
        workflow.lookup_uml_to_xsd("Class0", type: :invalid)
      }.to raise_error(Lutaml::Klin::Error, /Unknown lookup type/)
    end
  end

  describe "#lookup_xsd_to_uml" do
    let(:workflow) { described_class.new(mapping_file.path) }

    context "with type lookup" do
      it "finds UML for XSD type" do
        result = workflow.lookup_xsd_to_uml("string", type: :type)

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
      end
    end

    context "with element lookup" do
      it "finds UML for XSD element" do
        result = workflow.lookup_xsd_to_uml("element", type: :element)

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
      end
    end

    context "with auto-detection" do
      it "auto-detects lookup type" do
        result = workflow.lookup_xsd_to_uml("string", type: :auto)

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
      end
    end

    it "raises error for unknown type" do
      expect {
        workflow.lookup_xsd_to_uml("string", type: :invalid)
      }.to raise_error(Lutaml::Klin::Error, /Unknown lookup type/)
    end
  end

  describe "#auto_lookup" do
    let(:workflow) { described_class.new(mapping_file.path) }

    it "performs auto-detection lookup" do
      result = workflow.auto_lookup("Class0")

      expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
    end

    it "supports fuzzy matching" do
      result = workflow.auto_lookup("class", fuzzy: true)

      expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
    end
  end

  describe "#format_result" do
    let(:workflow) { described_class.new(mapping_file.path) }
    let(:result) { workflow.auto_lookup("Class0") }

    it "formats as text by default" do
      output = workflow.format_result(result)

      expect(output).to be_a(String)
      expect(output).to include("Lookup Result")
    end

    it "formats as JSON" do
      output = workflow.format_result(result, format: :json)

      expect(output).to be_a(String)
      expect { JSON.parse(output) }.not_to raise_error
    end

    it "formats as YAML" do
      output = workflow.format_result(result, format: :yaml)

      expect(output).to be_a(String)
      expect { YAML.safe_load(output, permitted_classes: [Symbol]) }.not_to raise_error
    end

    it "raises error for unknown format" do
      expect {
        workflow.format_result(result, format: :invalid)
      }.to raise_error(Lutaml::Klin::Error, /Unknown format/)
    end
  end

  describe "#interactive_lookup" do
    let(:workflow) { described_class.new(mapping_file.path) }

    it "enters interactive mode" do
      allow($stdin).to receive(:gets).and_return("exit\n")

      expect { workflow.interactive_lookup }.to output(/Interactive Lookup/).to_stdout
    end

    it "handles help command" do
      allow($stdin).to receive(:gets).and_return("help\n", "exit\n")

      expect { workflow.interactive_lookup }.to output(/Usage/).to_stdout
    end

    it "handles quit command" do
      allow($stdin).to receive(:gets).and_return("quit\n")

      expect { workflow.interactive_lookup }.to output(/Goodbye/).to_stdout
    end
  end

  describe "private methods" do
    let(:workflow) { described_class.new(mapping_file.path) }

    describe "#load_mapping" do
      it "loads valid mapping file" do
        expect(workflow.mapping).to be_a(Lutaml::Klin::Mapping::SchemaMapping)
      end
    end

    describe "#format_json" do
      let(:result) { workflow.auto_lookup("Class0") }

      it "returns pretty JSON" do
        json = workflow.send(:format_json, result)

        expect(json).to include("\"query\"")
        parsed = JSON.parse(json)
        expect(parsed).to be_a(Hash)
      end
    end

    describe "#format_yaml" do
      let(:result) { workflow.auto_lookup("Class0") }

      it "returns YAML output" do
        yaml = workflow.send(:format_yaml, result)

        expect(yaml).to include("query:")
        parsed = YAML.safe_load(yaml, permitted_classes: [Symbol])
        expect(parsed).to be_a(Hash)
      end
    end

    describe "#format_text" do
      let(:result) { workflow.auto_lookup("Class0") }

      it "returns human-readable text" do
        text = workflow.send(:format_text, result)

        expect(text).to include("Lookup Result")
        expect(text).to include("Query:")
        expect(text).to include("Direction:")
      end

      it "shows matches when found" do
        text = workflow.send(:format_text, result)

        if result.found?
          expect(text).to include("Match")
        else
          expect(text).to include("No matches found")
        end
      end
    end

    describe "#format_match" do
      let(:match) do
        {
          uml_class: "TestClass",
          uml_package: "TestPackage",
          xsd_type: "TestType",
          xsd_namespace: "http://test.org"
        }
      end

      it "formats UML to XSD match" do
        lines = workflow.send(:format_match, match, :uml_to_xsd)

        expect(lines).to include(/UML Class: TestClass/)
        expect(lines).to include(/XSD Type: TestType/)
      end

      it "formats XSD to UML match" do
        lines = workflow.send(:format_match, match, :xsd_to_uml)

        expect(lines).to include(/XSD Type: TestType/)
        expect(lines).to include(/UML Class: TestClass/)
      end

      it "includes resolution information" do
        match[:resolution_status] = "resolved"
        match[:resolution_method] = "TypeOverride"

        lines = workflow.send(:format_match, match, :uml_to_xsd)

        expect(lines).to include(/Resolution Status: resolved/)
        expect(lines).to include(/Resolution Method: TypeOverride/)
      end
    end

    describe "#process_interactive_query" do
      it "processes query and displays result" do
        expect { workflow.send(:process_interactive_query, "Class0") }
          .to output(/Lookup Result/).to_stdout
      end

      it "handles fuzzy flag" do
        expect { workflow.send(:process_interactive_query, "class --fuzzy") }
          .to output(/Lookup Result/).to_stdout
      end

      it "handles errors gracefully" do
        allow(workflow).to receive(:auto_lookup).and_raise(StandardError, "Test error")

        expect { workflow.send(:process_interactive_query, "invalid") }
          .to output(/Error: Test error/).to_stdout
      end
    end

    describe "#print_help" do
      it "prints help message" do
        expect { workflow.send(:print_help) }
          .to output(/Interactive Lookup Help/).to_stdout
      end

      it "includes usage examples" do
        expect { workflow.send(:print_help) }
          .to output(/Examples:/).to_stdout
      end
    end
  end
end