# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/lxr/input_strategy"
require "lutaml/klin/lxr/errors"

RSpec.describe Lutaml::Klin::Lxr::InputStrategy do
  describe "#extract_schema_info" do
    it "raises NotImplementedError" do
      strategy = described_class.new
      expect { strategy.extract_schema_info }.to raise_error(NotImplementedError)
    end
  end

  describe "#validate!" do
    it "raises NotImplementedError" do
      strategy = described_class.new
      expect { strategy.validate! }.to raise_error(NotImplementedError)
    end
  end
end

RSpec.describe Lutaml::Klin::Lxr::ShapeChangeInputStrategy do
  let(:config_path) { "spec/fixtures/shapechange/test_config.xml" }
  let(:extractor) { instance_double(Lutaml::Klin::Shapechange::LxrExtractor) }
  let(:strategy) { described_class.new(config_path: config_path, extractor: extractor) }

  describe "#initialize" do
    it "stores config_path" do
      expect(strategy.config_path).to eq(config_path)
    end

    it "uses provided extractor" do
      expect(strategy.extractor).to eq(extractor)
    end

    it "creates default extractor if not provided" do
      strategy = described_class.new(config_path: config_path)
      expect(strategy.extractor).to be_a(Lutaml::Klin::Shapechange::LxrExtractor)
    end
  end

  describe "#validate!" do
    context "when config_path is nil" do
      let(:strategy) { described_class.new(config_path: nil) }

      it "raises InvalidInputError" do
        expect { strategy.validate! }.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /configuration path is required/
        )
      end
    end

    context "when config file does not exist" do
      let(:config_path) { "nonexistent_config.xml" }

      it "raises InvalidInputError" do
        expect { strategy.validate! }.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /not found/
        )
      end
    end

    context "when config file exists" do
      before do
        allow(File).to receive(:exist?).with(config_path).and_return(true)
      end

      it "does not raise error" do
        expect { strategy.validate! }.not_to raise_error
      end
    end
  end

  describe "#extract_schema_info" do
    let(:schema_info) do
      {
        xsd_files: ["schema1.xsd", "schema2.xsd"],
        namespace_mappings: [
          { prefix: "urf", uri: "https://example.com/urf" }
        ],
        schema_location_mappings: []
      }
    end

    before do
      allow(File).to receive(:exist?).with(config_path).and_return(true)
      allow(extractor).to receive(:extract_schema_info).with(config_path).and_return(schema_info)
    end

    it "validates before extraction" do
      expect(strategy).to receive(:validate!)
      strategy.extract_schema_info
    end

    it "calls extractor with config_path" do
      expect(extractor).to receive(:extract_schema_info).with(config_path)
      strategy.extract_schema_info
    end

    it "returns schema information" do
      result = strategy.extract_schema_info
      expect(result).to eq(schema_info)
      expect(result[:xsd_files]).to contain_exactly("schema1.xsd", "schema2.xsd")
      expect(result[:namespace_mappings].first[:prefix]).to eq("urf")
    end
  end
end

RSpec.describe Lutaml::Klin::Lxr::ManualInputStrategy do
  let(:xsd_dir) { "spec/fixtures/xsd" }
  let(:namespaces_config) { "spec/fixtures/namespaces.yaml" }
  let(:strategy) { described_class.new(xsd_dir: xsd_dir, namespaces_config: namespaces_config) }

  describe "#initialize" do
    it "stores xsd_dir" do
      expect(strategy.xsd_dir).to eq(xsd_dir)
    end

    it "stores namespaces_config" do
      expect(strategy.namespaces_config).to eq(namespaces_config)
    end

    it "accepts xsd_files array" do
      strategy = described_class.new(
        xsd_files: ["schema1.xsd"],
        namespaces_config: namespaces_config
      )
      expect(strategy.xsd_files).to eq(["schema1.xsd"])
    end
  end

  describe "#validate!" do
    context "when neither xsd_dir nor xsd_files provided" do
      let(:strategy) { described_class.new(namespaces_config: namespaces_config) }

      it "raises InvalidInputError" do
        expect { strategy.validate! }.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /xsd_dir or xsd_files must be provided/
        )
      end
    end

    context "when xsd_dir does not exist" do
      before do
        allow(Dir).to receive(:exist?).with(xsd_dir).and_return(false)
      end

      it "raises InvalidInputError" do
        expect { strategy.validate! }.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /xsd_dir or xsd_files must be provided/
        )
      end
    end

    context "when namespaces_config is missing" do
      let(:strategy) { described_class.new(xsd_dir: xsd_dir) }

      before do
        allow(Dir).to receive(:exist?).with(xsd_dir).and_return(true)
      end

      it "raises InvalidInputError" do
        expect { strategy.validate! }.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /Namespace configuration is required/
        )
      end
    end

    context "when namespaces_config file does not exist" do
      before do
        allow(Dir).to receive(:exist?).with(xsd_dir).and_return(true)
        allow(File).to receive(:exist?).with(namespaces_config).and_return(false)
      end

      it "raises InvalidInputError" do
        expect { strategy.validate! }.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /Namespace configuration file not found/
        )
      end
    end

    context "when all inputs are valid" do
      before do
        allow(Dir).to receive(:exist?).with(xsd_dir).and_return(true)
        allow(File).to receive(:exist?).with(namespaces_config).and_return(true)
      end

      it "does not raise error" do
        expect { strategy.validate! }.not_to raise_error
      end
    end

    context "when xsd_files provided instead of xsd_dir" do
      let(:strategy) do
        described_class.new(
          xsd_files: ["schema1.xsd"],
          namespaces_config: { "namespace_mappings" => [] }
        )
      end

      it "does not raise error" do
        expect { strategy.validate! }.not_to raise_error
      end
    end
  end

  describe "#extract_schema_info" do
    let(:namespace_config_data) do
      {
        "namespace_mappings" => [
          { "prefix" => "urf", "uri" => "https://example.com/urf" },
          { "prefix" => "gml", "uri" => "http://www.opengis.net/gml/3.2" }
        ]
      }
    end

    before do
      allow(Dir).to receive(:exist?).with(xsd_dir).and_return(true)
      allow(File).to receive(:exist?).with(namespaces_config).and_return(true)
      allow(YAML).to receive(:load_file).with(namespaces_config).and_return(namespace_config_data)
      allow(Dir).to receive(:glob).with(File.join(xsd_dir, "**", "*.xsd"))
                                   .and_return(["schema1.xsd", "schema2.xsd"])
    end

    it "returns schema information with collected XSD files" do
      result = strategy.extract_schema_info
      expect(result[:xsd_files]).to contain_exactly("schema1.xsd", "schema2.xsd")
    end

    it "returns namespace mappings with symbol keys" do
      result = strategy.extract_schema_info
      expect(result[:namespace_mappings]).to all(have_key(:prefix))
      expect(result[:namespace_mappings]).to all(have_key(:uri))
      expect(result[:namespace_mappings].first[:prefix]).to eq("urf")
    end

    it "returns empty schema location mappings" do
      result = strategy.extract_schema_info
      expect(result[:schema_location_mappings]).to eq([])
    end

    context "when namespaces_config is a Hash" do
      let(:strategy) do
        described_class.new(
          xsd_dir: xsd_dir,
          namespaces_config: namespace_config_data
        )
      end

      before do
        allow(Dir).to receive(:exist?).with(xsd_dir).and_return(true)
        allow(Dir).to receive(:glob).with(File.join(xsd_dir, "**", "*.xsd"))
                                     .and_return(["schema1.xsd"])
      end

      it "uses Hash directly without loading file" do
        expect(YAML).not_to receive(:load_file)
        result = strategy.extract_schema_info
        expect(result[:namespace_mappings]).not_to be_empty
      end
    end

    context "when xsd_files provided explicitly" do
      let(:strategy) do
        described_class.new(
          xsd_files: ["explicit_schema.xsd"],
          namespaces_config: namespace_config_data
        )
      end

      it "uses explicit xsd_files instead of scanning directory" do
        expect(Dir).not_to receive(:glob)
        result = strategy.extract_schema_info
        expect(result[:xsd_files]).to eq(["explicit_schema.xsd"])
      end
    end

    context "when namespace mappings are invalid" do
      let(:invalid_config) do
        { "namespace_mappings" => [{ "prefix" => "urf" }] }
      end

      before do
        allow(YAML).to receive(:load_file).with(namespaces_config).and_return(invalid_config)
      end

      it "raises InvalidInputError for missing uri" do
        expect { strategy.extract_schema_info }.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /must have a 'uri' field/
        )
      end
    end
  end
end