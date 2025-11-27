# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/global_rules/no_documentation_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::GlobalRules::NoDocumentationProcessor do
  let(:config) { instance_double(Lutaml::Klin::XsdGeneratorConfiguration) }
  let(:model_element) { double("model_element") }
  let(:annotation_builder) { double("annotation_builder") }

  describe ".applies_to?" do
    context "when rule is enabled" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-no-documentation")
          .and_return(true)
      end

      it "returns true" do
        expect(described_class.applies_to?(model_element, config)).to be true
      end
    end

    context "when rule is disabled" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-no-documentation")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(model_element, config)).to be false
      end
    end
  end

  describe ".should_generate_documentation?" do
    context "when rule is enabled (suppress documentation)" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-no-documentation")
          .and_return(true)
      end

      it "returns false" do
        result = described_class.should_generate_documentation?(model_element,
                                                                config)
        expect(result).to be false
      end
    end

    context "when rule is disabled (allow documentation)" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-no-documentation")
          .and_return(false)
      end

      it "returns true" do
        result = described_class.should_generate_documentation?(model_element,
                                                                config)
        expect(result).to be true
      end
    end
  end

  describe ".add_documentation" do
    context "when rule is enabled (suppress documentation)" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-no-documentation")
          .and_return(true)
      end

      it "does not add documentation and returns false" do
        expect(annotation_builder).not_to receive(:add_documentation)

        result = described_class.add_documentation(
          annotation_builder,
          model_element,
          config,
          "Some documentation text"
        )

        expect(result).to be false
      end
    end

    context "when rule is disabled (allow documentation)" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-no-documentation")
          .and_return(false)
      end

      context "with valid documentation text" do
        it "adds documentation and returns true" do
          expect(annotation_builder).to receive(:add_documentation)
            .with("Some documentation text")

          result = described_class.add_documentation(
            annotation_builder,
            model_element,
            config,
            "Some documentation text"
          )

          expect(result).to be true
        end
      end

      context "with nil documentation text" do
        it "does not add documentation and returns false" do
          expect(annotation_builder).not_to receive(:add_documentation)

          result = described_class.add_documentation(
            annotation_builder,
            model_element,
            config,
            nil
          )

          expect(result).to be false
        end
      end

      context "with empty documentation text" do
        it "does not add documentation and returns false" do
          expect(annotation_builder).not_to receive(:add_documentation)

          result = described_class.add_documentation(
            annotation_builder,
            model_element,
            config,
            "   "
          )

          expect(result).to be false
        end
      end

      context "with whitespace-only documentation text" do
        it "does not add documentation and returns false" do
          expect(annotation_builder).not_to receive(:add_documentation)

          result = described_class.add_documentation(
            annotation_builder,
            model_element,
            config,
            "\n\t  \n"
          )

          expect(result).to be false
        end
      end
    end
  end
end
