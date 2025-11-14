# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/commands/spa_command"
require "tmpdir"

RSpec.describe Lutaml::Klin::Commands::SpaCommand do
  let(:command) { described_class.new(options) }
  let(:lxr_file) { File.join(Dir.tmpdir, "test.lxr") }
  let(:yaml_file) { File.join(Dir.tmpdir, "test.yaml") }
  let(:output_path) { File.join(Dir.tmpdir, "output") }
  let(:options) do
    {
      lxr: lxr_file,
      output: output_path,
      verbose: false
    }
  end

  before do
    # Create temporary LXR file
    FileUtils.touch(lxr_file)
  end

  after do
    FileUtils.rm_f(lxr_file)
    FileUtils.rm_f(yaml_file)
    FileUtils.rm_rf(output_path)
  end

  describe "#initialize" do
    it "normalizes options" do
      cmd = described_class.new("lxr" => lxr_file, "output" => output_path)
      expect(cmd.options[:lxr]).to eq(lxr_file)
      expect(cmd.options[:output]).to eq(output_path)
    end

    it "raises error if LXR path not provided" do
      expect {
        described_class.new(output: output_path)
      }.to raise_error(ArgumentError, /--lxr.*required/)
    end

    it "raises error if LXR file does not exist" do
      expect {
        described_class.new(lxr: "nonexistent.lxr", output: output_path)
      }.to raise_error(ArgumentError, /LXR package not found/)
    end

    it "raises error if YAML file specified but does not exist" do
      expect {
        described_class.new(
          lxr: lxr_file,
          yaml: "nonexistent.yaml",
          output: output_path
        )
      }.to raise_error(ArgumentError, /YAML mapping not found/)
    end
  end

  describe "#run" do
    let(:mock_generator) { instance_double(Lutaml::Klin::Spa::Generator) }
    let(:mock_schema) do
      instance_double(
        Lutaml::Klin::Spa::Models::UnifiedSchema,
        schemas: [],
        elements: [{}, {}],
        complex_types: [{}],
        simple_types: [],
        attributes: []
      )
    end

    before do
      allow(Lutaml::Klin::Spa::Generator).to receive(:new).and_return(mock_generator)
      allow(mock_generator).to receive(:generate).and_return(mock_schema)
    end

    it "creates generator with correct options" do
      expect(Lutaml::Klin::Spa::Generator).to receive(:new).with(
        hash_including(
          mode: :multi_file,
          theme: "default",
          verbose: false
        )
      )

      command.run
    end

    it "calls generator with LXR path" do
      expect(mock_generator).to receive(:generate).with(
        lxr_file,
        nil,
        output_path
      )

      command.run
    end

    it "calls generator with YAML path when provided" do
      FileUtils.touch(yaml_file)
      cmd = described_class.new(
        lxr: lxr_file,
        yaml: yaml_file,
        output: output_path
      )

      generator = instance_double(Lutaml::Klin::Spa::Generator)
      allow(Lutaml::Klin::Spa::Generator).to receive(:new).and_return(generator)
      allow(generator).to receive(:generate).and_return(mock_schema)

      expect(generator).to receive(:generate).with(
        lxr_file,
        yaml_file,
        output_path
      )

      cmd.run
    end

    it "reports success" do
      expect { command.run }.to output(/SPA generated successfully/).to_stdout
    end

    it "handles errors gracefully" do
      allow(mock_generator).to receive(:generate).and_raise(StandardError, "Test error")

      expect {
        command.run
      }.to raise_error(StandardError).and output(/SPA generation failed/).to_stdout
    end
  end

  describe "mode validation" do
    it "accepts embedded mode" do
      expect {
        described_class.new(
          lxr: lxr_file,
          mode: "embedded",
          output: output_path
        )
      }.not_to raise_error
    end

    it "accepts multi-file mode" do
      expect {
        described_class.new(
          lxr: lxr_file,
          mode: "multi-file",
          output: output_path
        )
      }.not_to raise_error
    end

    it "accepts multi_file mode (underscore variant)" do
      expect {
        described_class.new(
          lxr: lxr_file,
          mode: "multi_file",
          output: output_path
        )
      }.not_to raise_error
    end

    it "raises error for invalid mode" do
      expect {
        described_class.new(
          lxr: lxr_file,
          mode: "invalid",
          output: output_path
        )
      }.to raise_error(ArgumentError, /Invalid mode/)
    end
  end

  describe "theme validation" do
    it "accepts default theme" do
      expect {
        described_class.new(
          lxr: lxr_file,
          theme: "default",
          output: output_path
        )
      }.not_to raise_error
    end

    it "accepts dark theme" do
      expect {
        described_class.new(
          lxr: lxr_file,
          theme: "dark",
          output: output_path
        )
      }.not_to raise_error
    end

    it "accepts plateau theme" do
      expect {
        described_class.new(
          lxr: lxr_file,
          theme: "plateau",
          output: output_path
        )
      }.not_to raise_error
    end

    it "raises error for invalid theme" do
      expect {
        described_class.new(
          lxr: lxr_file,
          theme: "invalid",
          output: output_path
        )
      }.to raise_error(ArgumentError, /Invalid theme/)
    end
  end

  describe "output reporting" do
    let(:mock_generator) { instance_double(Lutaml::Klin::Spa::Generator) }
    let(:mock_schema) do
      schema = instance_double(Lutaml::Klin::Spa::Models::UnifiedSchema)
      allow(schema).to receive(:schemas).and_return([{}, {}])
      allow(schema).to receive(:elements).and_return([{}, {}, {}])
      allow(schema).to receive(:complex_types).and_return([{}])
      allow(schema).to receive(:simple_types).and_return([])
      allow(schema).to receive(:attributes).and_return([{}, {}])
      schema
    end

    before do
      allow(Lutaml::Klin::Spa::Generator).to receive(:new).and_return(mock_generator)
      allow(mock_generator).to receive(:generate).and_return(mock_schema)
    end

    it "displays schema count" do
      expect { command.run }.to output(/Schemas: 2/).to_stdout
    end

    it "displays total component count" do
      expect { command.run }.to output(/Total components: 6/).to_stdout
    end

    it "displays UML-mapped count when YAML provided" do
      FileUtils.touch(yaml_file)
      cmd = described_class.new(
        lxr: lxr_file,
        yaml: yaml_file,
        output: output_path
      )

      # Mock elements with UML mappings
      elem_with_mapping = instance_double("Element", uml_mapping: {})
      elem_without_mapping = instance_double("Element", uml_mapping: nil)
      allow(mock_schema).to receive(:elements).and_return([elem_with_mapping, elem_without_mapping])
      allow(mock_schema).to receive(:complex_types).and_return([])
      allow(mock_schema).to receive(:simple_types).and_return([])
      allow(mock_schema).to receive(:attributes).and_return([])

      expect { cmd.run }.to output(/UML-mapped components: 1/).to_stdout
    end
  end
end