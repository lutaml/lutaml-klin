# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/xsd_gen/rule_processors/package_rules/gml_profile_schema_processor"

RSpec.describe Lutaml::Klin::XsdGen::RuleProcessors::PackageRules::GmlProfileSchemaProcessor do
  let(:processor) { described_class }
  let(:gml_32_namespace) { "http://www.opengis.net/gml/3.2" }
  let(:context) do
    double(
      "Context",
      rule_enabled?: true,
      gml_namespace: gml_32_namespace,
    )
  end

  describe ".applies_to?" do
    context "when rule is enabled and GML 3.2" do
      context "with gmlProfileSchema tagged value" do
        let(:package) do
          double(
            "Package",
            tagged_value: "http://www.opengis.net/gml/3.2",
          )
        end

        it "returns true" do
          expect(processor.applies_to?(package, context)).to be true
        end
      end

      context "with gml_profile_schema property" do
        let(:package) do
          double(
            "Package",
            tagged_value: nil,
            gml_profile_schema: "http://www.opengis.net/def/profile/gml/2.0/gml-sf0",
          )
        end

        before do
          allow(package).to receive(:respond_to?)
            .with(:gml_profile_schema)
            .and_return(true)
        end

        it "returns true" do
          expect(processor.applies_to?(package, context)).to be true
        end
      end

      context "with empty profile value" do
        let(:package) do
          double(
            "Package",
            tagged_value: "  ",
          )
        end

        it "returns false" do
          expect(processor.applies_to?(package, context)).to be false
        end
      end

      context "with nil profile value" do
        let(:package) do
          double(
            "Package",
            tagged_value: nil,
          )
        end

        before do
          allow(package).to receive(:respond_to?)
            .with(:gml_profile_schema)
            .and_return(false)
        end

        it "returns false" do
          expect(processor.applies_to?(package, context)).to be false
        end
      end
    end

    context "when GML version is not 3.2" do
      let(:context) do
        double(
          "Context",
          rule_enabled?: true,
          gml_namespace: "http://www.opengis.net/gml",
        )
      end
      let(:package) do
        double(
          "Package",
          tagged_value: "http://www.opengis.net/gml/3.2",
        )
      end

      it "returns false" do
        expect(processor.applies_to?(package, context)).to be false
      end
    end

    context "when rule is disabled" do
      let(:context) do
        double(
          "Context",
          rule_enabled?: false,
          gml_namespace: gml_32_namespace,
        )
      end
      let(:package) do
        double(
          "Package",
          tagged_value: "http://www.opengis.net/gml/3.2",
        )
      end

      it "returns false" do
        expect(processor.applies_to?(package, context)).to be false
      end
    end
  end

  describe ".process" do
    context "with valid GML profile schema" do
      let(:package) do
        double(
          "Package",
          tagged_value: "http://www.opengis.net/gml/3.2",
        )
      end

      it "returns appinfo with gmlProfileSchema element" do
        result = processor.process(package, context)

        expect(result[:appinfo]).to include(
          hash_including(
            namespace: gml_32_namespace,
            element: "gmlProfileSchema",
            text: "http://www.opengis.net/gml/3.2",
          ),
        )
      end

      it "includes GML namespace import" do
        result = processor.process(package, context)

        expect(result[:imports]).to include(
          hash_including(
            prefix: "gml",
            namespace: gml_32_namespace,
          ),
        )
      end
    end

    context "with GMLSF Level 0 profile" do
      let(:package) do
        double(
          "Package",
          tagged_value: "http://www.opengis.net/def/profile/gml/2.0/gml-sf0",
        )
      end

      it "returns appinfo with GMLSF profile URL" do
        result = processor.process(package, context)

        expect(result[:appinfo]).to include(
          hash_including(
            text: "http://www.opengis.net/def/profile/gml/2.0/gml-sf0",
          ),
        )
      end
    end

    context "with custom profile URL" do
      let(:package) do
        double(
          "Package",
          tagged_value: "http://example.org/profiles/custom/1.0",
        )
      end

      it "returns appinfo with custom profile URL" do
        result = processor.process(package, context)

        expect(result[:appinfo]).to include(
          hash_including(
            text: "http://example.org/profiles/custom/1.0",
          ),
        )
      end
    end

    context "when rule does not apply" do
      let(:package) do
        double(
          "Package",
          tagged_value: nil,
        )
      end

      before do
        allow(package).to receive(:respond_to?)
          .with(:gml_profile_schema)
          .and_return(false)
      end

      it "returns empty hash" do
        result = processor.process(package, context)

        expect(result).to eq({})
      end
    end

    context "with property instead of tagged value" do
      let(:package) do
        double(
          "Package",
          tagged_value: nil,
          gml_profile_schema: "http://www.opengis.net/def/profile/gml/2.0/gml-sf1",
        )
      end

      before do
        allow(package).to receive(:respond_to?)
          .with(:gml_profile_schema)
          .and_return(true)
      end

      it "returns appinfo using property value" do
        result = processor.process(package, context)

        expect(result[:appinfo]).to include(
          hash_including(
            text: "http://www.opengis.net/def/profile/gml/2.0/gml-sf1",
          ),
        )
      end
    end
  end

  describe ".get_profile_value" do
    context "when tagged value exists" do
      let(:package) do
        double(
          "Package",
          tagged_value: "http://www.opengis.net/gml/3.2",
        )
      end

      it "returns tagged value" do
        value = processor.get_profile_value(package)

        expect(value).to eq("http://www.opengis.net/gml/3.2")
      end
    end

    context "when tagged value is nil but property exists" do
      let(:package) do
        double(
          "Package",
          tagged_value: nil,
          gml_profile_schema: "http://example.org/profile",
        )
      end

      before do
        allow(package).to receive(:respond_to?)
          .with(:gml_profile_schema)
          .and_return(true)
      end

      it "returns property value" do
        value = processor.get_profile_value(package)

        expect(value).to eq("http://example.org/profile")
      end
    end

    context "when neither tagged value nor property exists" do
      let(:package) do
        double(
          "Package",
          tagged_value: nil,
        )
      end

      before do
        allow(package).to receive(:respond_to?)
          .with(:gml_profile_schema)
          .and_return(false)
      end

      it "returns nil" do
        value = processor.get_profile_value(package)

        expect(value).to be_nil
      end
    end
  end
end