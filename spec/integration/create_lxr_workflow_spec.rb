# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/commands/create_lxr_command"
require "lutaml/klin/lxr/input_strategy"
require "lutaml/klin/lxr/config_builder"
require "lutaml/klin/lxr/package_builder"

RSpec.describe "Create LXR Workflow Integration" do
  let(:tmp_dir) { "tmp/integration_test" }
  let(:output_path) { File.join(tmp_dir, "test_package.lxr") }

  before do
    FileUtils.mkdir_p(tmp_dir)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe "End-to-end workflow with manual input strategy" do
    let(:xsd_dir) { File.join(tmp_dir, "schemas") }
    let(:namespaces_file) { File.join(tmp_dir, "namespaces.yaml") }

    before do
      # Create test XSD files
      FileUtils.mkdir_p(xsd_dir)
      File.write(File.join(xsd_dir, "test1.xsd"), <<~XSD)
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
                   targetNamespace="http://test.com/test1"
                   xmlns:test1="http://test.com/test1">
          <xs:element name="TestElement" type="xs:string"/>
        </xs:schema>
      XSD

      File.write(File.join(xsd_dir, "test2.xsd"), <<~XSD)
        <?xml version="1.0" encoding="UTF-8"?>
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
                   targetNamespace="http://test.com/test2"
                   xmlns:test2="http://test.com/test2">
          <xs:element name="AnotherElement" type="xs:string"/>
        </xs:schema>
      XSD

      # Create namespace configuration
      File.write(namespaces_file, <<~YAML)
        namespace_mappings:
          - prefix: test1
            uri: http://test.com/test1
          - prefix: test2
            uri: http://test.com/test2
      YAML
    end

    it "completes the full workflow from input extraction to package creation" do
      # Step 1: Create input strategy
      strategy = Lutaml::Klin::Lxr::ManualInputStrategy.new(
        xsd_dir: xsd_dir,
        namespaces_config: namespaces_file
      )

      # Step 2: Validate and extract schema info
      expect { strategy.validate! }.not_to raise_error
      schema_info = strategy.extract_schema_info

      expect(schema_info[:xsd_files]).to include(
        match(/test1\.xsd$/),
        match(/test2\.xsd$/)
      )
      expect(schema_info[:namespace_mappings]).to contain_exactly(
        { prefix: "test1", uri: "http://test.com/test1" },
        { prefix: "test2", uri: "http://test.com/test2" }
      )

      # Step 3: Build configuration
      config_builder = Lutaml::Klin::Lxr::ConfigBuilder.new(
        xsd_mode: "include_all",
        resolution_mode: "resolved",
        serialization_format: "marshal"
      )

      metadata = {
        name: "Integration Test Package",
        version: "1.0.0",
        description: "Package created during integration test"
      }

      config = config_builder.build(schema_info, metadata)

      expect(config["package"]["name"]).to eq("Integration Test Package")
      expect(config["schemas"]["files"].size).to eq(2)
      expect(config["namespaces"].size).to eq(2)

      # Step 4: Write configuration to file
      config_file = File.join(tmp_dir, "package_config.yaml")
      config_builder.build_and_write(schema_info, config_file, metadata)

      expect(File.exist?(config_file)).to be true
      loaded_config = YAML.load_file(config_file)
      expect(loaded_config["package"]["name"]).to eq("Integration Test Package")
    end

    it "handles the complete workflow through CreateLxrCommand" do
      # Mock lutaml-xsd availability and execution
      allow_any_instance_of(Lutaml::Klin::Lxr::PackageBuilder)
        .to receive(:system).with("which lutaml-xsd > /dev/null 2>&1").and_return(true)

      allow(IO).to receive(:popen).and_yield(StringIO.new("Package created successfully\n"))
      allow($?).to receive(:success?).and_return(true)

      # Create a mock package file to simulate successful build
      allow(File).to receive(:write) do |path, content|
        File.write(path, content) unless path.end_with?(".lxr")
      end

      # Execute command
      options = {
        output: output_path,
        xsd_dir: xsd_dir,
        namespaces: namespaces_file,
        name: "Test Package",
        version: "2.0.0",
        verbose: false
      }

      command = Lutaml::Klin::Commands::CreateLxrCommand.new(options)

      # Run should exit with status 0 (success)
      expect { command.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(0)
      end
    end
  end

  describe "Workflow with ShapeChange input strategy" do
    let(:config_file) { File.join(tmp_dir, "shapechange_config.xml") }

    before do
      # Create minimal ShapeChange configuration
      File.write(config_file, <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <ShapeChangeConfiguration>
          <input>
            <PackageInfo>
              <ns>http://test.com/package1</ns>
              <nsabr>pkg1</nsabr>
              <xsdDocument>schemas/package1.xsd</xsdDocument>
            </PackageInfo>
          </input>
          <xmlNamespaces>
            <XmlNamespace ns="http://www.opengis.net/gml/3.2" nsabr="gml"/>
          </xmlNamespaces>
        </ShapeChangeConfiguration>
      XML
    end

    it "extracts schema information from ShapeChange config" do
      strategy = Lutaml::Klin::Lxr::ShapeChangeInputStrategy.new(
        config_path: config_file
      )

      expect { strategy.validate! }.not_to raise_error
      schema_info = strategy.extract_schema_info

      expect(schema_info[:xsd_files]).to include("schemas/package1.xsd")
      expect(schema_info[:namespace_mappings]).to include(
        hash_including(prefix: "pkg1", uri: "http://test.com/package1")
      )
    end

    it "completes workflow with ShapeChange strategy through command" do
      allow_any_instance_of(Lutaml::Klin::Lxr::PackageBuilder)
        .to receive(:system).with("which lutaml-xsd > /dev/null 2>&1").and_return(true)

      allow(IO).to receive(:popen).and_yield(StringIO.new("Success\n"))
      allow($?).to receive(:success?).and_return(true)

      options = {
        output: output_path,
        shapechange: config_file,
        xsd_mode: "include_all",
        verbose: false
      }

      command = Lutaml::Klin::Commands::CreateLxrCommand.new(options)

      expect { command.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(0)
      end
    end
  end

  describe "Error handling throughout workflow" do
    it "handles invalid input gracefully" do
      options = {
        output: output_path,
        xsd_dir: "nonexistent_directory",
        namespaces: "nonexistent_file.yaml"
      }

      command = Lutaml::Klin::Commands::CreateLxrCommand.new(options)

      expect { command.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it "handles missing output path" do
      options = {
        xsd_dir: tmp_dir,
        namespaces: File.join(tmp_dir, "ns.yaml")
      }

      # Create minimal namespace file
      File.write(options[:namespaces], "namespace_mappings: []")

      command = Lutaml::Klin::Commands::CreateLxrCommand.new(options)

      expect { command.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end

    it "handles package build failures" do
      xsd_dir = File.join(tmp_dir, "schemas")
      namespaces_file = File.join(tmp_dir, "ns.yaml")

      FileUtils.mkdir_p(xsd_dir)
      File.write(File.join(xsd_dir, "test.xsd"), "<xs:schema/>")
      File.write(namespaces_file, "namespace_mappings:\n  - prefix: test\n    uri: http://test.com")

      allow_any_instance_of(Lutaml::Klin::Lxr::PackageBuilder)
        .to receive(:system).with("which lutaml-xsd > /dev/null 2>&1").and_return(true)

      allow(IO).to receive(:popen).and_yield(StringIO.new("Build failed\n"))
      allow($?).to receive(:success?).and_return(false)

      options = {
        output: output_path,
        xsd_dir: xsd_dir,
        namespaces: namespaces_file,
        verbose: false
      }

      command = Lutaml::Klin::Commands::CreateLxrCommand.new(options)

      expect { command.run }.to raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    end
  end

  describe "Configuration options propagation" do
    let(:xsd_dir) { File.join(tmp_dir, "schemas") }
    let(:namespaces_file) { File.join(tmp_dir, "ns.yaml") }

    before do
      FileUtils.mkdir_p(xsd_dir)
      File.write(File.join(xsd_dir, "test.xsd"), "<xs:schema/>")
      File.write(namespaces_file, <<~YAML)
        namespace_mappings:
          - prefix: test
            uri: http://test.com
      YAML
    end

    it "propagates all configuration options correctly" do
      strategy = Lutaml::Klin::Lxr::ManualInputStrategy.new(
        xsd_dir: xsd_dir,
        namespaces_config: namespaces_file
      )

      schema_info = strategy.extract_schema_info

      builder = Lutaml::Klin::Lxr::ConfigBuilder.new(
        xsd_mode: "allow_external",
        resolution_mode: "bare",
        serialization_format: "json"
      )

      metadata = {
        name: "Custom Package",
        version: "3.0.0",
        description: "Custom description"
      }

      config = builder.build(schema_info, metadata)

      # Verify all options are correctly set
      expect(config["package"]["name"]).to eq("Custom Package")
      expect(config["package"]["version"]).to eq("3.0.0")
      expect(config["package"]["description"]).to eq("Custom description")
      expect(config["options"]["xsd_mode"]).to eq("allow_external")
      expect(config["options"]["resolution_mode"]).to eq("bare")
      expect(config["options"]["serialization_format"]).to eq("json")
    end
  end
end