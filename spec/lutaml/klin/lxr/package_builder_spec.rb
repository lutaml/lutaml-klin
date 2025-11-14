# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/lxr/package_builder"
require "lutaml/klin/lxr/errors"

RSpec.describe Lutaml::Klin::Lxr::PackageBuilder do
  let(:builder) { described_class.new(verbose: false) }
  let(:config_hash) do
    {
      "package" => { "name" => "test", "version" => "1.0.0" },
      "schemas" => { "files" => ["schema.xsd"] },
      "options" => { "xsd_mode" => "include_all" }
    }
  end
  let(:output_path) { "tmp/test_package.lxr" }

  before do
    FileUtils.mkdir_p("tmp")
  end

  after do
    FileUtils.rm_f(output_path)
  end

  describe "#initialize" do
    it "sets verbose flag" do
      builder = described_class.new(verbose: true)
      expect(builder.verbose).to be true
    end

    it "defaults verbose to false" do
      expect(builder.verbose).to be false
    end
  end

  describe "#build" do
    context "when lutaml-xsd is not available" do
      before do
        allow(builder).to receive(:system)
          .with("which lutaml-xsd > /dev/null 2>&1")
          .and_return(false)
      end

      it "raises PackageBuildError" do
        expect do
          builder.build(config_hash, output_path)
        end.to raise_error(
          Lutaml::Klin::Lxr::PackageBuildError,
          /lutaml-xsd command not found/
        )
      end
    end

    context "when lutaml-xsd is available" do
      before do
        allow(builder).to receive(:system)
          .with("which lutaml-xsd > /dev/null 2>&1")
          .and_return(true)
      end

      it "creates temporary config file" do
        allow(IO).to receive(:popen).and_yield(StringIO.new(""))
        allow($?).to receive(:success?).and_return(true)

        builder.build(config_hash, output_path)

        # Temporary file should be cleaned up after execution
        temp_files = Dir.glob("tmp/lxr_config*.yaml")
        expect(temp_files).to be_empty
      end

      it "executes lutaml-xsd command with correct arguments" do
        allow(IO).to receive(:popen) do |cmd, **_opts|
          expect(cmd).to include("lutaml-xsd")
          expect(cmd).to include("package")
          expect(cmd).to include("build")
          expect(cmd).to include("--output", output_path)
          StringIO.new("")
        end
        allow($?).to receive(:success?).and_return(true)

        builder.build(config_hash, output_path)
      end

      it "returns success result when build succeeds" do
        allow(IO).to receive(:popen).and_yield(StringIO.new("Build successful\n"))
        allow($?).to receive(:success?).and_return(true)

        result = builder.build(config_hash, output_path)

        expect(result[:success]).to be true
        expect(result[:output_path]).to eq(output_path)
        expect(result[:messages]).to include("Build successful")
      end

      it "returns failure result when build fails" do
        allow(IO).to receive(:popen).and_yield(StringIO.new("Build failed\n"))
        allow($?).to receive(:success?).and_return(false)

        result = builder.build(config_hash, output_path)

        expect(result[:success]).to be false
        expect(result[:messages].join).to match(/Build failed/)
      end

      context "with custom build options" do
        let(:options) do
          {
            name: "Custom Package",
            version: "2.0.0",
            description: "Custom description"
          }
        end

        it "includes custom options in command" do
          allow(IO).to receive(:popen) do |cmd, **_opts|
            expect(cmd).to include("--name", "Custom Package")
            expect(cmd).to include("--version", "2.0.0")
            expect(cmd).to include("--description", "Custom description")
            StringIO.new("")
          end
          allow($?).to receive(:success?).and_return(true)

          builder.build(config_hash, output_path, options)
        end
      end

      context "with validation option" do
        before do
          allow(IO).to receive(:popen).and_yield(StringIO.new(""))
          allow($?).to receive(:success?).and_return(true)
        end

        it "validates package after creation when validate option is true" do
          File.write(output_path, "test content")

          result = builder.build(config_hash, output_path, validate: true)

          expect(result[:validation]).to be_a(Hash)
          expect(result[:validation][:valid]).to be true
        end

        it "does not validate when validate option is false" do
          result = builder.build(config_hash, output_path, validate: false)

          expect(result).not_to have_key(:validation)
        end

        it "sets success to false if validation fails" do
          allow(File).to receive(:exist?).with(output_path).and_return(true)
          allow(File).to receive(:size).with(output_path).and_return(0)

          result = builder.build(config_hash, output_path, validate: true)

          expect(result[:success]).to be false
          expect(result[:validation][:valid]).to be false
        end
      end

      context "with verbose mode" do
        let(:builder) { described_class.new(verbose: true) }

        it "includes verbose flag in command" do
          allow(IO).to receive(:popen) do |cmd, **_opts|
            expect(cmd).to include("--verbose")
            StringIO.new("")
          end
          allow($?).to receive(:success?).and_return(true)

          builder.build(config_hash, output_path)
        end
      end

      context "when execution raises an error" do
        before do
          allow(IO).to receive(:popen).and_raise(StandardError, "Execution failed")
        end

        it "returns failure result with error information" do
          result = builder.build(config_hash, output_path)

          expect(result[:success]).to be false
          expect(result[:messages].join).to match(/Execution failed/)
          expect(result[:error]).to be_a(StandardError)
        end
      end
    end
  end

  describe "#validate_package" do
    context "when package file does not exist" do
      it "returns invalid result" do
        result = builder.validate_package("nonexistent.lxr")

        expect(result[:valid]).to be false
        expect(result[:messages].join).to match(/not found/)
      end
    end

    context "when package file is empty" do
      let(:empty_file) { "tmp/empty.lxr" }

      before do
        File.write(empty_file, "")
      end

      after do
        FileUtils.rm_f(empty_file)
      end

      it "returns invalid result" do
        result = builder.validate_package(empty_file)

        expect(result[:valid]).to be false
        expect(result[:messages].join).to match(/empty/)
      end
    end

    context "when package file exists and has content" do
      let(:valid_file) { "tmp/valid.lxr" }

      before do
        File.write(valid_file, "valid content")
      end

      after do
        FileUtils.rm_f(valid_file)
      end

      it "returns valid result" do
        result = builder.validate_package(valid_file)

        expect(result[:valid]).to be true
        expect(result[:messages].join).to match(/created successfully/)
      end

      it "includes file size in validation message" do
        result = builder.validate_package(valid_file)

        expect(result[:messages].join).to match(/\d+ bytes/)
      end
    end
  end
end