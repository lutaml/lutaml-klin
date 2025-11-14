# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/commands/create_lxr_command"
require "lutaml/klin/lxr/errors"

RSpec.describe Lutaml::Klin::Commands::CreateLxrCommand do
  let(:options) do
    {
      output: "tmp/test.lxr",
      shapechange: "spec/fixtures/shapechange/test_config.xml",
      verbose: false
    }
  end
  let(:command) { described_class.new(options) }

  describe "#initialize" do
    it "normalizes options to symbol keys" do
      command = described_class.new("output" => "test.lxr", "verbose" => true)
      expect(command.options[:output]).to eq("test.lxr")
      expect(command.options[:verbose]).to be true
    end

    it "creates ShapeChange input strategy when shapechange option provided" do
      expect(command.input_strategy).to be_a(Lutaml::Klin::Lxr::ShapeChangeInputStrategy)
    end

    it "creates Manual input strategy when xsd_dir and namespaces provided" do
      command = described_class.new(
        output: "test.lxr",
        xsd_dir: "schemas",
        namespaces: "ns.yaml"
      )
      expect(command.input_strategy).to be_a(Lutaml::Klin::Lxr::ManualInputStrategy)
    end

    it "creates config builder with specified options" do
      command = described_class.new(
        output: "test.lxr",
        shapechange: "config.xml",
        xsd_mode: "allow_external",
        resolution_mode: "bare",
        format: "json"
      )
      expect(command.config_builder.xsd_mode).to eq("allow_external")
      expect(command.config_builder.resolution_mode).to eq("bare")
      expect(command.config_builder.serialization_format).to eq("json")
    end

    it "creates package builder with verbose setting" do
      command = described_class.new(output: "test.lxr", shapechange: "config.xml", verbose: true)
      expect(command.package_builder.verbose).to be true
    end
  end

  describe "#run" do
    let(:schema_info) do
      {
        xsd_files: ["schema1.xsd", "schema2.xsd"],
        namespace_mappings: [
          { prefix: "test", uri: "http://test.com" }
        ],
        schema_location_mappings: []
      }
    end

    let(:config) do
      {
        "package" => { "name" => "test" },
        "schemas" => { "files" => ["schema1.xsd"] }
      }
    end

    let(:build_result) do
      {
        success: true,
        output_path: "tmp/test.lxr",
        messages: ["Package created successfully"]
      }
    end

    before do
      allow(command.input_strategy).to receive(:validate!)
      allow(command.input_strategy).to receive(:extract_schema_info).and_return(schema_info)
      allow(command.config_builder).to receive(:build).and_return(config)
      allow(command.package_builder).to receive(:build).and_return(build_result)
    end

    it "validates options" do
      expect(command.input_strategy).to receive(:validate!)
      expect { command.run }.to raise_error(SystemExit)
    end

    it "extracts schema information" do
      expect(command.input_strategy).to receive(:extract_schema_info)
      expect { command.run }.to raise_error(SystemExit)
    end

    it "builds configuration" do
      expect(command.config_builder).to receive(:build).with(schema_info, anything)
      expect { command.run }.to raise_error(SystemExit)
    end

    it "creates package" do
      expect(command.package_builder).to receive(:build).with(config, "tmp/test.lxr", anything)
      expect { command.run }.to raise_error(SystemExit)
    end

    it "exits with 0 on success" do
      expect { command.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(0)
      end
    end

    context "when build fails" do
      let(:build_result) do
        {
          success: false,
          output_path: "tmp/test.lxr",
          messages: ["Build failed"]
        }
      end

      it "exits with 1 on failure" do
        expect { command.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context "when validation is requested" do
      let(:options) do
        {
          output: "tmp/test.lxr",
          shapechange: "config.xml",
          validate: true
        }
      end

      let(:build_result) do
        {
          success: true,
          output_path: "tmp/test.lxr",
          messages: ["Package created"],
          validation: { valid: true, messages: ["Validation passed"] }
        }
      end

      it "includes validation option in build call" do
        expect(command.package_builder).to receive(:build)
          .with(anything, anything, hash_including(validate: true))
        expect { command.run }.to raise_error(SystemExit)
      end
    end

    context "when package metadata is provided" do
      let(:options) do
        {
          output: "tmp/test.lxr",
          shapechange: "config.xml",
          name: "Test Package",
          version: "1.0.0",
          description: "Test description"
        }
      end

      it "passes metadata to config builder" do
        expect(command.config_builder).to receive(:build).with(
          anything,
          hash_including(
            name: "Test Package",
            version: "1.0.0",
            description: "Test description"
          )
        )
        expect { command.run }.to raise_error(SystemExit)
      end
    end

    context "when neither shapechange nor xsd_dir/namespaces provided" do
      let(:options) { { output: "test.lxr" } }

      it "raises InvalidInputError" do
        expect do
          described_class.new(options)
        end.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /Either --shapechange or --xsd-dir/
        )
      end
    end

    context "when output path is missing" do
      let(:options) { { shapechange: "config.xml" } }

      it "raises InvalidInputError during run" do
        command = described_class.new(options)
        expect { command.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context "when LxrCreationError occurs" do
      before do
        allow(command.input_strategy).to receive(:extract_schema_info)
          .and_raise(Lutaml::Klin::Lxr::PackageBuildError, "Build error")
      end

      it "catches error and exits with 1" do
        expect { command.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(command.input_strategy).to receive(:extract_schema_info)
          .and_raise(StandardError, "Unexpected error")
      end

      it "catches error and exits with 1" do
        expect { command.run }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end
  end

  describe "verbose mode" do
    let(:options) do
      {
        output: "tmp/test.lxr",
        shapechange: "config.xml",
        verbose: true
      }
    end

    let(:schema_info) do
      {
        xsd_files: ["schema1.xsd"],
        namespace_mappings: [],
        schema_location_mappings: []
      }
    end

    let(:config) { { "package" => { "name" => "test" } } }
    let(:build_result) { { success: true, output_path: "tmp/test.lxr", messages: [] } }

    before do
      allow(command.input_strategy).to receive(:validate!)
      allow(command.input_strategy).to receive(:extract_schema_info).and_return(schema_info)
      allow(command.config_builder).to receive(:build).and_return(config)
      allow(command.package_builder).to receive(:build).and_return(build_result)
    end

    it "outputs verbose messages" do
      expect { command.run }.to output(/Extracting schema information/).to_stdout
                                                                         .and raise_error(SystemExit)
    end
  end

  describe "integration with components" do
    context "using ShapeChange strategy" do
      let(:options) do
        {
          output: "tmp/test.lxr",
          shapechange: "config.xml",
          xsd_mode: "include_all",
          resolution_mode: "resolved",
          format: "marshal"
        }
      end

      it "creates all components correctly" do
        command = described_class.new(options)

        expect(command.input_strategy).to be_a(Lutaml::Klin::Lxr::ShapeChangeInputStrategy)
        expect(command.config_builder).to be_a(Lutaml::Klin::Lxr::ConfigBuilder)
        expect(command.package_builder).to be_a(Lutaml::Klin::Lxr::PackageBuilder)
      end
    end

    context "using Manual strategy" do
      let(:options) do
        {
          output: "tmp/test.lxr",
          xsd_dir: "schemas",
          namespaces: "ns.yaml"
        }
      end

      it "creates all components correctly" do
        command = described_class.new(options)

        expect(command.input_strategy).to be_a(Lutaml::Klin::Lxr::ManualInputStrategy)
        expect(command.config_builder).to be_a(Lutaml::Klin::Lxr::ConfigBuilder)
        expect(command.package_builder).to be_a(Lutaml::Klin::Lxr::PackageBuilder)
      end
    end
  end
end