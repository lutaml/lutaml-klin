# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/lxr/auto_builder"
require "tempfile"
require "fileutils"

RSpec.describe Lutaml::Klin::Lxr::AutoBuilder do
  let(:temp_dir) { Dir.mktmpdir("auto_builder_spec") }
  let(:temp_config) { Tempfile.new(["shapechange_config", ".xml"], temp_dir) }
  let(:cache_dir) { File.join(temp_dir, "cache") }

  let(:mock_extractor) { instance_double(Lutaml::Klin::Shapechange::LxrExtractor) }
  let(:mock_cache_manager) { instance_double(Lutaml::Klin::Lxr::CacheManager) }
  let(:mock_package_builder) { instance_double(Lutaml::Klin::Lxr::PackageBuilder) }

  let(:schema_info) do
    {
      xsd_files: ["schema1.xsd", "schema2.xsd"],
      namespace_mappings: [
        { prefix: "urf", uri: "http://example.com/urf" },
        { prefix: "uro", uri: "http://example.com/uro" }
      ],
      schema_location_mappings: []
    }
  end

  after do
    temp_config.close
    temp_config.unlink
    FileUtils.rm_rf(temp_dir)
  end

  before do
    # Write minimal config content
    temp_config.write("<configuration/>")
    temp_config.flush
  end

  describe "#initialize" do
    it "creates AutoBuilder with config path" do
      builder = described_class.new(temp_config.path)
      expect(builder.config_path).to eq(temp_config.path)
    end

    it "accepts cache_dir option" do
      builder = described_class.new(temp_config.path, cache_dir: cache_dir)
      expect(builder.cache_manager.cache_dir).to eq(cache_dir)
    end

    it "accepts verbose option" do
      builder = described_class.new(temp_config.path, verbose: true)
      expect(builder.options[:verbose]).to be true
    end

    context "when config file doesn't exist" do
      it "raises InvalidInputError" do
        expect do
          described_class.new("nonexistent.xml")
        end.to raise_error(
          Lutaml::Klin::Lxr::InvalidInputError,
          /not found/
        )
      end
    end
  end

  describe "#build_or_use_existing" do
    let(:auto_builder) do
      builder = described_class.new(temp_config.path, cache_dir: cache_dir)
      allow(builder).to receive(:extractor).and_return(mock_extractor)
      allow(builder).to receive(:cache_manager).and_return(mock_cache_manager)
      builder
    end

    context "when cached LXR exists and force_rebuild is false" do
      let(:cached_lxr_path) { File.join(cache_dir, "cached.lxr") }

      before do
        allow(mock_cache_manager).to receive(:cached_lxr_path)
          .with(temp_config.path)
          .and_return(cached_lxr_path)
      end

      it "returns cached LXR path" do
        result = auto_builder.build_or_use_existing
        expect(result).to eq(cached_lxr_path)
      end

      it "does not build new LXR package" do
        expect(mock_extractor).not_to receive(:extract_schema_info)
        auto_builder.build_or_use_existing
      end
    end

    context "when force_rebuild is true" do
      let(:auto_builder) do
        builder = described_class.new(
          temp_config.path,
          cache_dir: cache_dir,
          force_rebuild: true
        )
        allow(builder).to receive(:extractor).and_return(mock_extractor)
        allow(builder).to receive(:cache_manager).and_return(mock_cache_manager)
        builder
      end

      let(:temp_lxr_path) { File.join(temp_dir, "new.lxr") }
      let(:cached_path) { File.join(cache_dir, "cached.lxr") }

      before do
        # Mock extraction
        allow(mock_extractor).to receive(:extract_schema_info)
          .and_return(schema_info)

        # Mock building
        allow(Lutaml::Klin::Lxr::InputStrategy).to receive(:from_shapechange)
          .and_return(double("input_strategy"))

        allow_any_instance_of(Lutaml::Klin::Lxr::ConfigBuilder)
          .to receive(:build)
          .and_return({ "name" => "test" })

        allow_any_instance_of(Lutaml::Klin::Lxr::PackageBuilder)
          .to receive(:build)
          .and_return({
                        success: true,
                        output_path: temp_lxr_path,
                        messages: ["Build successful"]
                      })

        # Mock caching
        allow(mock_cache_manager).to receive(:cache_lxr)
          .and_return(cached_path)
      end

      it "builds new LXR even if cache exists" do
        expect(mock_cache_manager).not_to receive(:cached_lxr_path)
        expect(mock_extractor).to receive(:extract_schema_info)
        auto_builder.build_or_use_existing
      end
    end

    context "when no cache exists" do
      let(:temp_lxr_path) { File.join(temp_dir, "new.lxr") }
      let(:cached_path) { File.join(cache_dir, "cached.lxr") }

      before do
        # No cache available
        allow(mock_cache_manager).to receive(:cached_lxr_path)
          .and_return(nil)

        # Mock extraction
        allow(mock_extractor).to receive(:extract_schema_info)
          .and_return(schema_info)

        # Mock input strategy and config builder
        mock_input_strategy = double("input_strategy")
        allow(Lutaml::Klin::Lxr::InputStrategy).to receive(:from_shapechange)
          .and_return(mock_input_strategy)

        mock_config_builder = instance_double(Lutaml::Klin::Lxr::ConfigBuilder)
        allow(Lutaml::Klin::Lxr::ConfigBuilder).to receive(:new)
          .and_return(mock_config_builder)
        allow(mock_config_builder).to receive(:build)
          .and_return({ "name" => "test_package" })

        # Mock package builder
        mock_builder = instance_double(Lutaml::Klin::Lxr::PackageBuilder)
        allow(Lutaml::Klin::Lxr::PackageBuilder).to receive(:new)
          .and_return(mock_builder)

        # Create temporary LXR file to simulate successful build
        File.write(temp_lxr_path, "lxr content")

        allow(mock_builder).to receive(:build).and_return({
                                                            success: true,
                                                            output_path: temp_lxr_path,
                                                            messages: ["Build successful"]
                                                          })

        # Mock caching
        allow(mock_cache_manager).to receive(:cache_lxr)
          .with(temp_lxr_path, temp_config.path)
          .and_return(cached_path)
      end

      it "builds new LXR package" do
        expect(mock_extractor).to receive(:extract_schema_info)
        auto_builder.build_or_use_existing
      end

      it "caches the built package" do
        expect(mock_cache_manager).to receive(:cache_lxr)
          .with(temp_lxr_path, temp_config.path)
        auto_builder.build_or_use_existing
      end

      it "returns cached path" do
        result = auto_builder.build_or_use_existing
        expect(result).to eq(cached_path)
      end
    end

    context "when build fails" do
      before do
        allow(mock_cache_manager).to receive(:cached_lxr_path)
          .and_return(nil)

        allow(mock_extractor).to receive(:extract_schema_info)
          .and_return(schema_info)

        mock_input_strategy = double("input_strategy")
        allow(Lutaml::Klin::Lxr::InputStrategy).to receive(:from_shapechange)
          .and_return(mock_input_strategy)

        mock_config_builder = instance_double(Lutaml::Klin::Lxr::ConfigBuilder)
        allow(Lutaml::Klin::Lxr::ConfigBuilder).to receive(:new)
          .and_return(mock_config_builder)
        allow(mock_config_builder).to receive(:build)
          .and_return({ "name" => "test" })

        mock_builder = instance_double(Lutaml::Klin::Lxr::PackageBuilder)
        allow(Lutaml::Klin::Lxr::PackageBuilder).to receive(:new)
          .and_return(mock_builder)
        allow(mock_builder).to receive(:build).and_return({
                                                            success: false,
                                                            messages: ["Build failed: missing XSD files"]
                                                          })
      end

      it "raises AutoLxrError" do
        expect do
          auto_builder.build_or_use_existing
        end.to raise_error(
          Lutaml::Klin::Lxr::AutoLxrError,
          /Build failed/
        )
      end
    end
  end

  describe "package name derivation" do
    it "derives name from config file basename" do
      builder = described_class.new(temp_config.path)
      name = builder.send(:derive_package_name)

      expect(name).to include(File.basename(temp_config.path, ".xml"))
    end

    it "sanitizes non-alphanumeric characters" do
      special_config = Tempfile.new(["config@special#name", ".xml"], temp_dir)
      special_config.write("<config/>")
      special_config.flush

      begin
        builder = described_class.new(special_config.path)
        name = builder.send(:derive_package_name)

        expect(name).to match(/^[a-zA-Z0-9_-]+$/)
      ensure
        special_config.close
        special_config.unlink
      end
    end
  end

  describe "package description derivation" do
    it "includes config filename in description" do
      builder = described_class.new(temp_config.path)
      description = builder.send(:derive_package_description)

      expect(description).to include(File.basename(temp_config.path))
      expect(description).to include("Auto-generated")
    end
  end

  describe "verbose logging" do
    context "when verbose is true" do
      let(:auto_builder) do
        described_class.new(temp_config.path, verbose: true)
      end

      it "outputs log messages" do
        expect { auto_builder.send(:log, "Test message") }
          .to output("Test message\n").to_stdout
      end
    end

    context "when verbose is false" do
      let(:auto_builder) do
        described_class.new(temp_config.path, verbose: false)
      end

      it "does not output log messages" do
        expect { auto_builder.send(:log, "Test message") }
          .not_to output.to_stdout
      end
    end
  end
end
