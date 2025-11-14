# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/rule_processors/class_rules/union_as_character_string_processor"

RSpec.describe Lutaml::Klin::RuleProcessors::ClassRules::UnionAsCharacterStringProcessor do
  let(:config) { instance_double(Lutaml::Klin::XsdGeneratorConfiguration) }
  let(:xsd_builder) { instance_double(Lutaml::Klin::Builders::XsdDocumentBuilder) }

  describe ".applies_to?" do
    let(:uml_class) { instance_double(Lutaml::Uml::Class) }

    context "when rule enabled and class is union with asCharacterString" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(true)
        allow(uml_class).to receive(:category).and_return(:union)
        allow(uml_class).to receive(:as_character_string?).and_return(true)
      end

      it "returns true" do
        expect(described_class.applies_to?(uml_class, config)).to be true
      end
    end

    context "when rule is disabled" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end

    context "when class is not a union" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(true)
        allow(uml_class).to receive(:category).and_return(:feature)
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end

    context "when asCharacterString is false" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(true)
        allow(uml_class).to receive(:category).and_return(:union)
        allow(uml_class).to receive(:as_character_string?).and_return(false)
      end

      it "returns false" do
        expect(described_class.applies_to?(uml_class, config)).to be false
      end
    end
  end

  describe ".map_property_type" do
    let(:element) { double("element") }
    let(:property) { instance_double(Lutaml::Uml::Attribute) }
    let(:type_class) { instance_double(Lutaml::Uml::Class) }

    context "when applies to type class" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(true)
        allow(type_class).to receive(:category).and_return(:union)
        allow(type_class).to receive(:as_character_string?).and_return(true)
      end

      it "sets type to xs:string" do
        expect(element).to receive(:type=).with("xs:string")

        result = described_class.map_property_type(
          element,
          property,
          type_class,
          xsd_builder,
          config
        )

        expect(result).to be true
      end
    end

    context "when does not apply to type class" do
      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(true)
        allow(type_class).to receive(:category).and_return(:union)
        allow(type_class).to receive(:as_character_string?).and_return(false)
      end

      it "does not set type and returns false" do
        expect(element).not_to receive(:type=)

        result = described_class.map_property_type(
          element,
          property,
          type_class,
          xsd_builder,
          config
        )

        expect(result).to be false
      end
    end
  end

  describe ".encode_as_string?" do
    context "when type class is nil" do
      it "returns false" do
        expect(described_class.encode_as_string?(nil, config)).to be false
      end
    end

    context "when type class is union with asCharacterString" do
      let(:type_class) { instance_double(Lutaml::Uml::Class) }

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(true)
        allow(type_class).to receive(:category).and_return(:union)
        allow(type_class).to receive(:as_character_string?).and_return(true)
      end

      it "returns true" do
        expect(described_class.encode_as_string?(type_class, config)).to be true
      end
    end

    context "when type class is union without asCharacterString" do
      let(:type_class) { instance_double(Lutaml::Uml::Class) }

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(true)
        allow(type_class).to receive(:category).and_return(:union)
        allow(type_class).to receive(:as_character_string?).and_return(false)
      end

      it "returns false" do
        expect(described_class.encode_as_string?(type_class, config)).to be false
      end
    end

    context "when type class is not a union" do
      let(:type_class) { instance_double(Lutaml::Uml::Class) }

      before do
        allow(config).to receive(:rule_enabled?)
          .with("rule-xsd-cls-union-asCharacterString")
          .and_return(true)
        allow(type_class).to receive(:category).and_return(:datatype)
      end

      it "returns false" do
        expect(described_class.encode_as_string?(type_class, config)).to be false
      end
    end
  end
end