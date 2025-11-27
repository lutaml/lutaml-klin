# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/cli"
require "tempfile"
require "fileutils"

RSpec.describe "Process command with auto-LXR", type: :integration do
  let(:temp_dir) { Dir.mktmpdir("auto_lxr_integration") }
  let(:cache_dir) { File.join(temp_dir, "cache") }
  let(:output_dir) { File.join(temp_dir, "output") }

  let(:shapechange_config_path) do
    File.join(temp_dir, "shapechange_config.xml")
  end
  let(:lur_package_path) { File.join(temp_dir, "test.lur") }

  # Minimal ShapeChange configuration
  let(:shapechange_config_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <ShapeChangeConfiguration>
        <input>
          <parameter name="inputModelType" value="EA7"/>
        </input>
        <log>
          <parameter name="reportLevel" value="INFO"/>
        </log>
        <targets>
          <TargetXmlSchema>
            <xi:include href="StandardNamespaces.xml"/>
            <xsdMapEntries>
              <XsdMapEntry type="CharacterString" xmlType="string"/>
            </xsdMapEntries>
          </TargetXmlSchema>
        </targets>
      </ShapeChangeConfiguration>
    XML
  end

  before do
    # Create ShapeChange config file
    File.write(shapechange_config_path, shapechange_config_xml)

    # Create dummy LUR package (would normally contain UML model)
    File.write(lur_package_path, "dummy lur content")
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "CLI validation" do
    it "requires --shapechange when using --auto-lxr" do
      cli = Lutaml::Klin::Cli.new

      expect do
        cli.invoke(
          :process,
          [],
          lur: lur_package_path,
          auto_lxr: true,
          output: output_dir
        )
      end.to raise_error(ArgumentError, /shapechange.*required/)
    end

    it "requires --lxr when not using --auto-lxr" do
      cli = Lutaml::Klin::Cli.new

      expect do
        cli.invoke(
          :process,
          [],
          lur: lur_package_path,
          config: shapechange_config_path,
          output: output_dir
        )
      end.to raise_error(ArgumentError, /lxr.*required/)
    end

    it "accepts either --config or --shapechange" do
      cli = Lutaml::Klin::Cli.new

      # Should not raise with --config
      expect do
        cli.send(:validate_process_options, {
                   lur: lur_package_path,
                   lxr: "test.lxr",
                   config: shapechange_config_path
                 })
      end.not_to raise_error

      # Should not raise with --shapechange
      expect do
        cli.send(:validate_process_options, {
                   lur: lur_package_path,
                   lxr: "test.lxr",
                   shapechange: shapechange_config_path
                 })
      end.not_to raise_error
    end
  end

  describe "Auto-LXR workflow" do
    let(:mock_auto_builder) { instance_double(Lutaml::Klin::Lxr::AutoBuilder) }
    let(:mock_lxr_path) { File.join(cache_dir, "auto_generated.lxr") }

    before do
      # Mock AutoBuilder to avoid actual LXR creation
      allow(Lutaml::Klin::Lxr::AutoBuilder).to receive(:new)
        .and_return(mock_auto_builder)
      allow(mock_auto_builder).to receive(:build_or_use_existing)
        .and_return(mock_lxr_path)

      # Mock ProcessCommand to avoid actual processing
      allow_any_instance_of(Lutaml::Klin::Commands::ProcessCommand)
        .to receive(:run)
    end

    it "creates AutoBuilder with correct options" do
      expect(Lutaml::Klin::Lxr::AutoBuilder).to receive(:new).with(
        shapechange_config_path,
        hash_including(
          cache_dir: cache_dir,
          force_rebuild: false,
          verbose: true
        )
      )

      cli = Lutaml::Klin::Cli.new
      cli.options = {
        lur: lur_package_path,
        shapechange: shapechange_config_path,
        auto_lxr: true,
        lxr_cache_dir: cache_dir,
        force_rebuild: false,
        output: output_dir,
        verbose: true
      }

      cli.process
    end

    it "uses built/cached LXR path for ProcessCommand" do
      process_command = instance_double(Lutaml::Klin::Commands::ProcessCommand)
      allow(Lutaml::Klin::Commands::ProcessCommand).to receive(:new)
        .and_return(process_command)
      allow(process_command).to receive(:run)

      expect(Lutaml::Klin::Commands::ProcessCommand).to receive(:new) do |options|
        expect(options[:lxr]).to eq(mock_lxr_path)
        process_command
      end

      cli = Lutaml::Klin::Cli.new
      cli.options = {
        lur: lur_package_path,
        shapechange: shapechange_config_path,
        auto_lxr: true,
        lxr_cache_dir: cache_dir,
        output: output_dir
      }

      cli.process
    end

    it "passes through force_rebuild option" do
      expect(Lutaml::Klin::Lxr::AutoBuilder).to receive(:new).with(
        shapechange_config_path,
        hash_including(force_rebuild: true)
      )

      cli = Lutaml::Klin::Cli.new
      cli.options = {
        lur: lur_package_path,
        shapechange: shapechange_config_path,
        auto_lxr: true,
        force_rebuild: true,
        output: output_dir
      }

      cli.process
    end
  end

  describe "Cache behavior" do
    let(:auto_builder) do
      Lutaml::Klin::Lxr::AutoBuilder.new(
        shapechange_config_path,
        cache_dir: cache_dir,
        verbose: false
      )
    end

    before do
      # Mock the actual LXR building process
      allow(auto_builder).to receive(:build_lxr_package) do
        temp_lxr = Tempfile.new(["auto_lxr", ".lxr"], temp_dir)
        temp_lxr.write("mock lxr content")
        temp_lxr.close
        temp_lxr.path
      end
    end

    it "caches LXR on first build" do
      result = auto_builder.build_or_use_existing

      expect(File.exist?(result)).to be true
      expect(result).to include(cache_dir)
      expect(result).to end_with(".lxr")
    end

    it "reuses cached LXR on second call" do
      # First call - builds and caches
      first_result = auto_builder.build_or_use_existing
      first_mtime = File.mtime(first_result)

      sleep 0.1

      # Second call - should use cache
      second_result = auto_builder.build_or_use_existing
      second_mtime = File.mtime(second_result)

      expect(first_result).to eq(second_result)
      expect(second_mtime).to eq(first_mtime) # File not regenerated
    end

    it "rebuilds when force_rebuild is true" do
      # First build
      first_builder = Lutaml::Klin::Lxr::AutoBuilder.new(
        shapechange_config_path,
        cache_dir: cache_dir
      )
      allow(first_builder).to receive(:build_lxr_package) do
        temp = Tempfile.new(["lxr1", ".lxr"], temp_dir)
        temp.write("first build")
        temp.close
        temp.path
      end

      first_result = first_builder.build_or_use_existing
      first_content = File.read(first_result)

      sleep 0.1

      # Second build with force_rebuild
      second_builder = Lutaml::Klin::Lxr::AutoBuilder.new(
        shapechange_config_path,
        cache_dir: cache_dir,
        force_rebuild: true
      )
      allow(second_builder).to receive(:build_lxr_package) do
        temp = Tempfile.new(["lxr2", ".lxr"], temp_dir)
        temp.write("second build")
        temp.close
        temp.path
      end

      second_result = second_builder.build_or_use_existing
      second_content = File.read(second_result)

      # Path should be same but content different (regenerated)
      expect(first_result).to eq(second_result)
      expect(first_content).not_to eq(second_content)
    end
  end

  describe "Error handling" do
    it "provides clear error when ShapeChange config is missing" do
      cli = Lutaml::Klin::Cli.new

      expect do
        cli.options = {
          lur: lur_package_path,
          shapechange: "nonexistent.xml",
          auto_lxr: true,
          output: output_dir
        }
        cli.process
      end.to output(/Error/).to_stdout
    end

    it "handles LXR build failures gracefully" do
      auto_builder = Lutaml::Klin::Lxr::AutoBuilder.new(
        shapechange_config_path,
        cache_dir: cache_dir
      )

      # Mock build failure
      allow(auto_builder).to receive(:build_lxr_package)
        .and_raise(Lutaml::Klin::Lxr::PackageBuildError, "Build failed")

      expect do
        auto_builder.build_or_use_existing
      end.to raise_error(
        Lutaml::Klin::Lxr::AutoLxrError,
        /Build failed/
      )
    end
  end
end
