# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/xsd_gen/rule_processors/tagged_values_processor"

RSpec.describe Lutaml::Klin::XsdGen::RuleProcessors::TaggedValuesProcessor do
  let(:processor) { described_class }
  let(:scai_namespace) { "http://www.interactive-instruments.de/ShapeChange/AppInfo" }
  let(:context) do
    double(
      "Context",
      rule_enabled?: true,
      config: { "representTaggedValues" => "author,version,status" }
    )
  end

  describe ".applies_to?" do
    context "when rule is enabled" do
      context "with element having configured tagged values" do
        let(:element) do
          double(
            "Class"
          )
        end

        before do
          allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
          allow(element).to receive(:tagged_value).with("author").and_return("John Doe")
          allow(element).to receive(:tagged_value).with("version").and_return(nil)
          allow(element).to receive(:tagged_value).with("status").and_return(nil)
        end

        it "returns true" do
          expect(processor.applies_to?(element, context)).to be true
        end
      end

      context "with no configured tags" do
        let(:context) do
          double(
            "Context",
            rule_enabled?: true,
            config: { "representTaggedValues" => "" }
          )
        end
        let(:element) do
          double(
            "Class"
          )
        end

        it "returns false" do
          expect(processor.applies_to?(element, context)).to be false
        end
      end

      context "with no matching tagged values" do
        let(:element) do
          double(
            "Class"
          )
        end

        before do
          allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
          allow(element).to receive(:tagged_value).with("author").and_return(nil)
          allow(element).to receive(:tagged_value).with("version").and_return(nil)
          allow(element).to receive(:tagged_value).with("status").and_return(nil)
        end

        it "returns false" do
          expect(processor.applies_to?(element, context)).to be false
        end
      end
    end

    context "when rule is disabled" do
      let(:context) do
        double(
          "Context",
          rule_enabled?: false,
          config: { "representTaggedValues" => "author,version" }
        )
      end
      let(:element) do
        double(
          "Class"
        )
      end

      it "returns false" do
        expect(processor.applies_to?(element, context)).to be false
      end
    end
  end

  describe ".process" do
    context "with single tagged value" do
      let(:element) do
        double(
          "Class"
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(element).to receive(:tagged_value).with("author").and_return("Transport Team")
        allow(element).to receive(:tagged_value).with("version").and_return(nil)
        allow(element).to receive(:tagged_value).with("status").and_return(nil)
      end

      it "returns appinfo with taggedValue element" do
        result = processor.process(element, context)

        expect(result[:appinfo]).to include(
          hash_including(
            namespace: scai_namespace,
            element: "taggedValue",
            attributes: { tag: "author" },
            text: "Transport Team"
          )
        )
      end

      it "includes ShapeChange AppInfo namespace import" do
        result = processor.process(element, context)

        expect(result[:imports]).to include(
          hash_including(
            prefix: "sc",
            namespace: scai_namespace
          )
        )
      end
    end

    context "with multiple tagged values" do
      let(:element) do
        double(
          "Class"
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(element).to receive(:tagged_value).with("author").and_return("City Planning")
        allow(element).to receive(:tagged_value).with("version").and_return("2.0")
        allow(element).to receive(:tagged_value).with("status").and_return("approved")
      end

      it "returns appinfo with all tagged values" do
        result = processor.process(element, context)

        expect(result[:appinfo].length).to eq(3)
      end

      it "sorts tagged values alphabetically by tag name" do
        result = processor.process(element, context)
        tags = result[:appinfo].map { |tv| tv[:attributes][:tag] }

        expect(tags).to eq(%w[author status version])
      end
    end

    context "with multi-valued tagged value" do
      let(:context) do
        double(
          "Context",
          rule_enabled?: true,
          config: { "representTaggedValues" => "example" }
        )
      end
      let(:element) do
        double(
          "Property"
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(element).to receive(:tagged_value).with("example").and_return(
          ["POINT(0 0)", "LINESTRING(0 0, 1 1)",
           "POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))"]
        )
      end

      it "returns appinfo with multiple elements for same tag" do
        result = processor.process(element, context)

        expect(result[:appinfo].length).to eq(3)
        expect(result[:appinfo].all? do |tv|
          tv[:attributes][:tag] == "example"
        end).to be true
      end

      it "sorts values alphabetically" do
        result = processor.process(element, context)
        values = result[:appinfo].map { |tv| tv[:text] }

        expect(values).to eq([
                               "LINESTRING(0 0, 1 1)",
                               "POINT(0 0)",
                               "POLYGON((0 0, 1 0, 1 1, 0 1, 0 0))"
                             ])
      end
    end

    context "with empty tagged value" do
      let(:element) do
        double(
          "Class"
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(element).to receive(:tagged_value).with("author").and_return("  ")
        allow(element).to receive(:tagged_value).with("version").and_return(nil)
        allow(element).to receive(:tagged_value).with("status").and_return("")
      end

      it "skips empty values" do
        result = processor.process(element, context)

        expect(result).to eq({})
      end
    end

    context "when rule does not apply" do
      let(:element) do
        double(
          "Class"
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(element).to receive(:tagged_value).with("author").and_return(nil)
        allow(element).to receive(:tagged_value).with("version").and_return(nil)
        allow(element).to receive(:tagged_value).with("status").and_return(nil)
      end

      it "returns empty hash" do
        result = processor.process(element, context)

        expect(result).to eq({})
      end
    end
  end

  describe ".get_represent_tags" do
    context "with comma-separated tags" do
      let(:context) do
        double(
          "Context",
          config: { "representTaggedValues" => "author,version,status" }
        )
      end

      it "returns array of tag names" do
        tags = processor.get_represent_tags(context)

        expect(tags).to eq(%w[author version status])
      end
    end

    context "with tags containing whitespace" do
      let(:context) do
        double(
          "Context",
          config: { "representTaggedValues" => " author , version , status " }
        )
      end

      it "returns trimmed tag names" do
        tags = processor.get_represent_tags(context)

        expect(tags).to eq(%w[author version status])
      end
    end

    context "with no configuration" do
      let(:context) do
        double(
          "Context",
          config: {}
        )
      end

      it "returns empty array" do
        tags = processor.get_represent_tags(context)

        expect(tags).to eq([])
      end
    end

    context "with empty configuration" do
      let(:context) do
        double(
          "Context",
          config: { "representTaggedValues" => "" }
        )
      end

      it "returns empty array" do
        tags = processor.get_represent_tags(context)

        expect(tags).to eq([])
      end
    end
  end

  describe ".get_tagged_values_for_tags" do
    context "with element having tagged_value method" do
      let(:element) do
        double(
          "Class"
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(true)
        allow(element).to receive(:tagged_value).with("author").and_return("John Doe")
        allow(element).to receive(:tagged_value).with("version").and_return("1.0")
        allow(element).to receive(:tagged_value).with("status").and_return(nil)
      end

      it "returns hash of tag to values" do
        result = processor.get_tagged_values_for_tags(element,
                                                      %w[author version status])

        expect(result).to eq({
                               "author" => ["John Doe"],
                               "version" => ["1.0"]
                             })
      end
    end

    context "with element having tagged_values hash" do
      let(:element) do
        double(
          "Class",
          tagged_values: {
            "author" => "Jane Smith",
            "version" => "2.0"
          }
        )
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(false)
        allow(element).to receive(:respond_to?).with(:tagged_values).and_return(true)
      end

      it "returns hash of tag to values" do
        result = processor.get_tagged_values_for_tags(element,
                                                      %w[author version
                                                         deprecated])

        expect(result).to eq({
                               "author" => ["Jane Smith"],
                               "version" => ["2.0"]
                             })
      end
    end

    context "with element having no tagged values" do
      let(:element) do
        double("Class")
      end

      before do
        allow(element).to receive(:respond_to?).with(:tagged_value).and_return(false)
        allow(element).to receive(:respond_to?).with(:tagged_values).and_return(false)
      end

      it "returns empty hash" do
        result = processor.get_tagged_values_for_tags(element,
                                                      %w[author version])

        expect(result).to eq({})
      end
    end
  end
end
