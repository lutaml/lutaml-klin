# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/xsd_gen/rule_processors/package_rules/dgiwgsp_processor"

RSpec.describe Lutaml::Klin::XsdGen::RuleProcessors::PackageRules::DgiwgspProcessor do
  let(:processor) { described_class }
  let(:dgiwg_namespace) { "http://www.dgiwg.org/gml/3.2/profiles/spatial/1.0/" }
  let(:dgiwg_schema_location) { "http://www.dgiwg.org/gml/3.2/profiles/spatial/1.0/profile.xsd" }
  let(:context) do
    double(
      "Context",
      rule_enabled?: true,
    )
  end

  describe ".applies_to?" do
    context "when rule is enabled" do
      context "with both DGIWG tagged values" do
        let(:package) do
          double(
            "Package",
          )
        end

        before do
          allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("1")
          allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(dgiwg_schema_location)
        end

        it "returns true" do
          expect(processor.applies_to?(package, context)).to be true
        end
      end

      context "with only compliance level" do
        let(:package) do
          double(
            "Package",
          )
        end

        before do
          allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("1")
          allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(nil)
        end

        it "returns false" do
          expect(processor.applies_to?(package, context)).to be false
        end
      end

      context "with only profile schema" do
        let(:package) do
          double(
            "Package",
          )
        end

        before do
          allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return(nil)
          allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(dgiwg_schema_location)
        end

        it "returns false" do
          expect(processor.applies_to?(package, context)).to be false
        end
      end

      context "with empty compliance level" do
        let(:package) do
          double(
            "Package",
          )
        end

        before do
          allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("  ")
          allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(dgiwg_schema_location)
        end

        it "returns false" do
          expect(processor.applies_to?(package, context)).to be false
        end
      end

      context "with empty profile schema" do
        let(:package) do
          double(
            "Package",
          )
        end

        before do
          allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("1")
          allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return("  ")
        end

        it "returns false" do
          expect(processor.applies_to?(package, context)).to be false
        end
      end

      context "with neither tagged value" do
        let(:package) do
          double(
            "Package",
          )
        end

        before do
          allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return(nil)
          allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(nil)
        end

        it "returns false" do
          expect(processor.applies_to?(package, context)).to be false
        end
      end
    end

    context "when rule is disabled" do
      let(:context) do
        double(
          "Context",
          rule_enabled?: false,
        )
      end
      let(:package) do
        double(
          "Package",
        )
      end

      before do
        allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("1")
        allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(dgiwg_schema_location)
      end

      it "returns false" do
        expect(processor.applies_to?(package, context)).to be false
      end
    end
  end

  describe ".process" do
    context "with valid DGIWG tagged values" do
      let(:package) do
        double(
          "Package",
        )
      end

      before do
        allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("1")
        allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(dgiwg_schema_location)
      end

      it "returns appinfo with DGIWG elements" do
        result = processor.process(package, context)

        expect(result[:appinfo]).to be_an(Array)
        expect(result[:appinfo].first[:source]).to eq(dgiwg_schema_location)
        expect(result[:appinfo].first[:elements]).to be_an(Array)
      end

      it "includes ComplianceLevel element" do
        result = processor.process(package, context)
        elements = result[:appinfo].first[:elements]

        compliance_level_element = elements.find { |e| e[:element] == "ComplianceLevel" }
        expect(compliance_level_element).to be_present
        expect(compliance_level_element[:namespace]).to eq(dgiwg_namespace)
        expect(compliance_level_element[:text]).to eq("1")
      end

      it "includes GMLProfileSchema element" do
        result = processor.process(package, context)
        elements = result[:appinfo].first[:elements]

        profile_schema_element = elements.find { |e| e[:element] == "GMLProfileSchema" }
        expect(profile_schema_element).to be_present
        expect(profile_schema_element[:namespace]).to eq(dgiwg_namespace)
        expect(profile_schema_element[:text]).to eq(dgiwg_schema_location)
      end

      it "includes DGIWG namespace import" do
        result = processor.process(package, context)

        expect(result[:imports]).to include(
          hash_including(
            prefix: "gmldgiwgsp",
            namespace: dgiwg_namespace,
          ),
        )
      end
    end

    context "with DGIWG Level 2 compliance" do
      let(:package) do
        double(
          "Package",
        )
      end
      let(:level_2_schema) { "http://www.dgiwg.org/gml/3.2/profiles/spatial/2.0/profile.xsd" }

      before do
        allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("2")
        allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(level_2_schema)
      end

      it "returns appinfo with level 2 compliance" do
        result = processor.process(package, context)
        elements = result[:appinfo].first[:elements]

        compliance_level_element = elements.find { |e| e[:element] == "ComplianceLevel" }
        expect(compliance_level_element[:text]).to eq("2")

        profile_schema_element = elements.find { |e| e[:element] == "GMLProfileSchema" }
        expect(profile_schema_element[:text]).to eq(level_2_schema)
      end
    end

    context "when only compliance level is present" do
      let(:package) do
        double(
          "Package",
        )
      end

      before do
        allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("1")
        allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(nil)
      end

      it "returns empty hash" do
        result = processor.process(package, context)

        expect(result).to eq({})
      end
    end

    context "when only profile schema is present" do
      let(:package) do
        double(
          "Package",
        )
      end

      before do
        allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return(nil)
        allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(dgiwg_schema_location)
      end

      it "returns empty hash" do
        result = processor.process(package, context)

        expect(result).to eq({})
      end
    end
  end

  describe ".get_compliance_level" do
    let(:package) do
      double(
        "Package",
      )
    end

    context "when tagged value exists" do
      before do
        allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return("1")
      end

      it "returns the compliance level" do
        value = processor.get_compliance_level(package)

        expect(value).to eq("1")
      end
    end

    context "when tagged value does not exist" do
      before do
        allow(package).to receive(:tagged_value).with("dgiwgComplianceLevel").and_return(nil)
      end

      it "returns nil" do
        value = processor.get_compliance_level(package)

        expect(value).to be_nil
      end
    end
  end

  describe ".get_profile_schema" do
    let(:package) do
      double(
        "Package",
      )
    end

    context "when tagged value exists" do
      before do
        allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(dgiwg_schema_location)
      end

      it "returns the profile schema URL" do
        value = processor.get_profile_schema(package)

        expect(value).to eq(dgiwg_schema_location)
      end
    end

    context "when tagged value does not exist" do
      before do
        allow(package).to receive(:tagged_value).with("dgiwgGMLProfileSchema").and_return(nil)
      end

      it "returns nil" do
        value = processor.get_profile_schema(package)

        expect(value).to be_nil
      end
    end
  end
end