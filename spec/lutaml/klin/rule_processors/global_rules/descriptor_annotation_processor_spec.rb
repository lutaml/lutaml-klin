# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/global_rules/descriptor_annotation_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::GlobalRules::DescriptorAnnotationProcessor do
  let(:config) { instance_double(Lutaml::Klin::XsdGeneratorConfiguration) }
  let(:xsd_builder) { instance_double(Lutaml::Klin::Builders::XsdDocumentBuilder) }
  let(:annotation_builder) { double("annotation_builder") }

  describe ".applies_to?" do
    let(:model_element) { double("model_element") }

    context "when rule is enabled and descriptors configured" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-descriptorAnnotation")
          .and_return(true)
        allow(config).to receive(:parameter)
          .with("representDescriptors")
          .and_return("alias,definition")
      end

      it "returns true" do
        expect(described_class.applies_to?(model_element, config)).to be true
      end
    end

    context "when rule is disabled" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-descriptorAnnotation")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(model_element, config)).to be false
      end
    end

    context "when no descriptors configured" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-all-descriptorAnnotation")
          .and_return(true)
        allow(config).to receive(:parameter)
          .with("representDescriptors")
          .and_return("")
      end

      it "returns false" do
        expect(described_class.applies_to?(model_element, config)).to be false
      end
    end
  end

  describe ".add_descriptor_annotations" do
    let(:model_element) { double("model_element") }

    before do
      allow(config).to receive(:rule_enabled?)
        .with("rule-xsd-all-descriptorAnnotation")
        .and_return(true)
      allow(config).to receive(:parameter)
        .with("representDescriptors")
        .and_return("alias,definition")
    end

    context "when model element has no descriptors method" do
      before do
        allow(model_element).to receive(:respond_to?).with(:descriptors).and_return(false)
      end

      it "does not add annotations" do
        expect(annotation_builder).not_to receive(:add_element)
        described_class.add_descriptor_annotations(
          annotation_builder,
          model_element,
          config,
          xsd_builder
        )
      end
    end

    context "when model element has descriptors" do
      before do
        allow(model_element).to receive(:respond_to?).with(:descriptors).and_return(true)
        allow(xsd_builder).to receive(:add_import)
      end

      context "with single descriptor value" do
        before do
          allow(model_element).to receive(:descriptors).and_return({
                                                                     "alias" => [{ value: "Building" }]
                                                                   })
          allow(annotation_builder).to receive(:appinfo).and_return(nil)
          allow(annotation_builder).to receive(:add_appinfo).and_return(annotation_builder)
        end

        it "adds descriptor element" do
          expect(annotation_builder).to receive(:add_element).with("sc:descriptor") do |&block|
            element = double("element")
            expect(element).to receive(:add_attribute).with("name", "alias")
            expect(element).to receive(:text=).with("Building")
            block.call(element)
          end

          described_class.add_descriptor_annotations(
            annotation_builder,
            model_element,
            config,
            xsd_builder
          )
        end

        it "imports sc namespace" do
          allow(annotation_builder).to receive(:add_element)
          expect(xsd_builder).to receive(:add_import).with("sc",
                                                           described_class::SCAI_NS)

          described_class.add_descriptor_annotations(
            annotation_builder,
            model_element,
            config,
            xsd_builder
          )
        end
      end

      context "with descriptor value and language" do
        before do
          allow(model_element).to receive(:descriptors).and_return({
                                                                     "alias" => [{
                                                                       value: "Bâtiment", lang: "fr"
                                                                     }]
                                                                   })
          allow(annotation_builder).to receive(:appinfo).and_return(nil)
          allow(annotation_builder).to receive(:add_appinfo).and_return(annotation_builder)
        end

        it "adds descriptor element with lang attribute" do
          expect(annotation_builder).to receive(:add_element).with("sc:descriptor") do |&block|
            element = double("element")
            expect(element).to receive(:add_attribute).with("name", "alias")
            expect(element).to receive(:add_attribute).with("lang", "fr")
            expect(element).to receive(:text=).with("Bâtiment")
            block.call(element)
          end

          described_class.add_descriptor_annotations(
            annotation_builder,
            model_element,
            config,
            xsd_builder
          )
        end
      end

      context "with multiple descriptor values" do
        before do
          allow(model_element).to receive(:descriptors).and_return({
                                                                     "alias" => [
                                                                       { value: "Building" },
                                                                       {
                                                                         value: "Bâtiment", lang: "fr"
                                                                       },
                                                                       {
                                                                         value: "Gebäude", lang: "de"
                                                                       }
                                                                     ],
                                                                     "definition" => [
                                                                       { value: "A permanent structure" }
                                                                     ]
                                                                   })
          allow(annotation_builder).to receive(:appinfo).and_return(nil)
          allow(annotation_builder).to receive(:add_appinfo).and_return(annotation_builder)
        end

        it "adds all descriptor elements in sorted order" do
          call_count = 0
          expected_values = ["Building", "Gebäude", "Bâtiment",
                             "A permanent structure"]

          expect(annotation_builder).to receive(:add_element).exactly(4).times.with("sc:descriptor") do |&block|
            element = double("element_#{call_count}")
            allow(element).to receive(:add_attribute)
            allow(element).to receive(:text=) do |text|
              expect(expected_values).to include(text)
            end
            block.call(element)
            call_count += 1
          end

          described_class.add_descriptor_annotations(
            annotation_builder,
            model_element,
            config,
            xsd_builder
          )
        end
      end

      context "with empty descriptor values" do
        before do
          allow(model_element).to receive(:descriptors).and_return({
                                                                     "alias" => [
                                                                       { value: "" },
                                                                       { value: "  " },
                                                                       { value: nil }
                                                                     ]
                                                                   })
          allow(annotation_builder).to receive(:appinfo).and_return(nil)
          allow(annotation_builder).to receive(:add_appinfo).and_return(annotation_builder)
        end

        it "skips empty values" do
          expect(annotation_builder).not_to receive(:add_element)

          described_class.add_descriptor_annotations(
            annotation_builder,
            model_element,
            config,
            xsd_builder
          )
        end
      end

      context "with unconfigured descriptors" do
        before do
          allow(model_element).to receive(:descriptors).and_return({
                                                                     "example" => [{ value: "Example text" }],
                                                                     "legalBasis" => [{ value: "Legal text" }]
                                                                   })
        end

        it "skips unconfigured descriptors" do
          expect(annotation_builder).not_to receive(:add_element)

          described_class.add_descriptor_annotations(
            annotation_builder,
            model_element,
            config,
            xsd_builder
          )
        end
      end
    end
  end

  describe ".descriptors_to_represent" do
    context "with configured descriptors" do
      before do
        allow(config).to receive(:parameter)
          .with("representDescriptors")
          .and_return("alias, definition, description")
      end

      it "returns array of descriptor names" do
        result = described_class.descriptors_to_represent(config)
        expect(result).to eq(%w[alias definition description])
      end
    end

    context "with empty configuration" do
      before do
        allow(config).to receive(:parameter)
          .with("representDescriptors")
          .and_return("")
      end

      it "returns empty array" do
        result = described_class.descriptors_to_represent(config)
        expect(result).to eq([])
      end
    end

    context "with nil configuration" do
      before do
        allow(config).to receive(:parameter)
          .with("representDescriptors")
          .and_return(nil)
      end

      it "returns empty array" do
        result = described_class.descriptors_to_represent(config)
        expect(result).to eq([])
      end
    end
  end
end
