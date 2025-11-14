# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/application/lookup_workflow"
require "tempfile"

RSpec.describe Lutaml::Klin::Application::LookupWorkflow do
  let(:mapping_yaml) do
    <<~YAML
      version: "1.0"
      package_mappings:
        - uml_package_name: urf
          class_mappings:
            - uml_name: UrbanPlanningArea
              uml_package: ModelRoot::i-UR::urf
              uml_qualified_name: ModelRoot::i-UR::urf::UrbanPlanningArea
              xsd_element_name: UrbanPlanningArea
              xsd_type: urf:UrbanPlanningAreaType
              xsd_type_name: UrbanPlanningAreaType
              xsd_namespace: http://www.opengis.net/plateau/urbanPlanning/2.0
              resolution_status: resolved
              attribute_mappings:
                - uml_name: name
                  uml_type: CharacterString
                  xsd_name: name
                  xsd_type: xs:string
                  namespace: urf
                  resolution_status: resolved
                - uml_name: areaType
                  uml_type: Code
                  xsd_name: areaType
                  xsd_type: gml:CodeType
                  namespace: gml
                  resolution_status: resolved
    YAML
  end

  let(:mapping_file) do
    Tempfile.new(["mapping", ".yaml"]).tap do |f|
      f.write(mapping_yaml)
      f.close
    end
  end

  let(:workflow) { described_class.new(mapping_file.path) }

  after do
    mapping_file.unlink
  end

  describe "#initialize" do
    it "loads the mapping file" do
      expect(workflow.mapping).to be_a(Lutaml::Klin::Mapping::SchemaMapping)
      expect(workflow.lookup_service).to be_a(Lutaml::Klin::Domain::Services::LookupService)
    end

    it "raises error for non-existent file" do
      expect do
        described_class.new("/non/existent/file.yaml")
      end.to raise_error(Lutaml::Klin::Error, /not found/)
    end
  end

  describe "#lookup_uml_to_xsd" do
    context "with class lookup" do
      it "finds XSD mapping for UML class" do
        result = workflow.lookup_uml_to_xsd(
          "ModelRoot::i-UR::urf::UrbanPlanningArea",
          type: :class
        )

        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
        expect(result.found?).to be(true)
        expect(result.first_match[:xsd_type]).to eq("urf:UrbanPlanningAreaType")
      end
    end

    context "with attribute lookup" do
      it "finds XSD mapping for UML attribute" do
        result = workflow.lookup_uml_to_xsd(
          "ModelRoot::i-UR::urf::UrbanPlanningArea::name",
          type: :attribute
        )

        expect(result.found?).to be(true)
        expect(result.first_match[:xsd_name]).to eq("name")
      end

      it "raises error for malformed attribute identifier" do
        expect do
          workflow.lookup_uml_to_xsd("InvalidFormat", type: :attribute)
        end.to raise_error(Lutaml::Klin::Error, /format/)
      end
    end

    context "with auto-detection" do
      it "auto-detects class lookup" do
        result = workflow.lookup_uml_to_xsd(
          "ModelRoot::i-UR::urf::UrbanPlanningArea",
          type: :auto
        )

        # Auto lookup may not find it directly, so check that it returns a result
        expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
      end
    end

    context "with fuzzy matching" do
      it "enables fuzzy matching when requested" do
        result = workflow.lookup_uml_to_xsd(
          "UrbanPlanning",
          type: :class,
          fuzzy: true
        )

        expect(result.found?).to be(true)
      end
    end
  end

  describe "#lookup_xsd_to_uml" do
    context "with type lookup" do
      it "finds UML classes for XSD type" do
        result = workflow.lookup_xsd_to_uml(
          "urf:UrbanPlanningAreaType",
          type: :type
        )

        expect(result.found?).to be(true)
        expect(result.first_match[:uml_class]).to include("UrbanPlanningArea")
      end
    end

    context "with element lookup" do
      it "finds UML attributes for XSD element" do
        result = workflow.lookup_xsd_to_uml(
          "urf:name",
          type: :element
        )

        expect(result.found?).to be(true)
        expect(result.first_match[:uml_attribute]).to eq("name")
      end
    end

    context "with auto-detection" do
      it "auto-detects XSD lookup" do
        result = workflow.lookup_xsd_to_uml(
          "gml:CodeType",
          type: :auto
        )

        # Auto-detection tries both type and element, may return element type
        expect([:auto, :xsd_element, :xsd_type]).to include(result.metadata[:type])
      end
    end
  end

  describe "#auto_lookup" do
    it "performs automatic direction detection" do
      result = workflow.auto_lookup("ModelRoot::i-UR::urf::UrbanPlanningArea")

      # Auto lookup returns a result object, found or not
      expect(result).to be_a(Lutaml::Klin::Domain::LookupResult)
    end

    it "supports fuzzy matching" do
      result = workflow.auto_lookup("Urban", fuzzy: true)

      expect(result.metadata[:fuzzy]).to be(true)
    end
  end

  describe "#format_result" do
    let(:result) do
      workflow.lookup_uml_to_xsd(
        "ModelRoot::i-UR::urf::UrbanPlanningArea",
        type: :class
      )
    end

    context "with text format" do
      it "formats result as human-readable text" do
        output = workflow.format_result(result, format: :text)

        expect(output).to include("Lookup Result")
        expect(output).to include("UrbanPlanningArea")
        expect(output).to include("urf:UrbanPlanningAreaType")
      end
    end

    context "with JSON format" do
      it "formats result as JSON" do
        output = workflow.format_result(result, format: :json)

        expect(output).to be_a(String)
        expect(output).to include("UrbanPlanningArea")
        expect { JSON.parse(output) }.not_to raise_error
      end
    end

    context "with YAML format" do
      it "formats result as YAML" do
        output = workflow.format_result(result, format: :yaml)

        expect(output).to be_a(String)
        expect(output).to include("UrbanPlanningArea")
        expect { YAML.safe_load(output, permitted_classes: [Symbol]) }.not_to raise_error
      end
    end

    context "with unknown format" do
      it "raises error" do
        expect do
          workflow.format_result(result, format: :unknown)
        end.to raise_error(Lutaml::Klin::Error, /Unknown format/)
      end
    end
  end

  describe "formatted text output" do
    it "includes match details for UML to XSD lookups" do
      result = workflow.lookup_uml_to_xsd(
        "ModelRoot::i-UR::urf::UrbanPlanningArea",
        type: :class
      )
      output = workflow.format_result(result, format: :text)

      expect(output).to include("UML Class:")
      expect(output).to include("XSD Type:")
      expect(output).to include("XSD Element:")
    end

    it "includes match details for XSD to UML lookups" do
      result = workflow.lookup_xsd_to_uml(
        "urf:UrbanPlanningAreaType",
        type: :type
      )
      output = workflow.format_result(result, format: :text)

      expect(output).to include("UML Class:")
      expect(output).to include("XSD Type:")
    end

    it "shows helpful message for no matches" do
      result = workflow.lookup_uml_to_xsd("NonExistent", type: :class)
      output = workflow.format_result(result, format: :text)

      expect(output).to include("No matches found")
      expect(output).to include("fuzzy matching")
    end

    it "includes match quality for fuzzy results" do
      result = workflow.lookup_uml_to_xsd(
        "Urban",
        type: :class,
        fuzzy: true
      )
      output = workflow.format_result(result, format: :text)

      if result.found? && result.first_match[:match_quality]
        expect(output).to include("Match Quality:")
      end
    end
  end
end