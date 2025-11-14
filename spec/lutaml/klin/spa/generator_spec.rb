# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/generator"
require "tmpdir"
require "fileutils"

RSpec.describe Lutaml::Klin::Spa::Generator do
  let(:generator) { described_class.new(options) }
  let(:options) { { verbose: false } }
  let(:lxr_path) { "test.lxr" }
  let(:yaml_path) { nil }
  let(:output_path) { nil }

  describe "#initialize" do
    it "creates generator with default options" do
      gen = described_class.new
      expect(gen.options[:mode]).to eq(:multi_file)
      expect(gen.options[:theme]).to eq("default")
      expect(gen.options[:verbose]).to be false
    end

    it "normalizes options" do
      gen = described_class.new(mode: "embedded", theme: "dark")
      expect(gen.options[:mode]).to eq(:embedded)
      expect(gen.options[:theme]).to eq("dark")
    end

    it "initializes all components" do
      expect(generator.data_loader).to be_a(Lutaml::Klin::Spa::DataLoader)
      expect(generator.cross_ref_builder).to be_a(Lutaml::Klin::Spa::CrossReferenceBuilder)
      expect(generator.search_builder).to be_a(Lutaml::Klin::Spa::SearchIndexBuilder)
      expect(generator.template_renderer).to be_a(Lutaml::Klin::Spa::TemplateRenderer)
      expect(generator.asset_bundler).to be_a(Lutaml::Klin::Spa::AssetBundler)
    end
  end

  describe "#generate" do
    let(:mock_schema) do
      Lutaml::Klin::Spa::Models::UnifiedSchema.new.tap do |s|
        s.metadata = Lutaml::Klin::Spa::Models::SchemaMetadata.new.tap do |m|
          m.name = "Test Schema"
        end
        s.schemas = []
        s.elements = []
        s.complex_types = []
        s.simple_types = []
        s.attributes = []
        s.statistics = Lutaml::Klin::Spa::Models::Statistics.new
        s.cross_references = Lutaml::Klin::Spa::Models::CrossReferenceIndex.new
        s.search_index = Lutaml::Klin::Spa::Models::SearchIndex.new
      end
    end

    before do
      allow(generator.data_loader).to receive(:load_lxr).and_return({
        metadata: {},
        namespaces: [],
        elements: [],
        complex_types: [],
        simple_types: [],
        attributes: [],
        statistics: Lutaml::Klin::Spa::Models::Statistics.new
      })
      allow(generator.data_loader).to receive(:merge).and_return(mock_schema)
      allow(generator.cross_ref_builder).to receive(:build).and_return(
        Lutaml::Klin::Spa::Models::CrossReferenceIndex.new
      )
      allow(generator.search_builder).to receive(:build).and_return(
        Lutaml::Klin::Spa::Models::SearchIndex.new
      )
    end

    context "with multi-file mode" do
      let(:options) { { mode: :multi_file, verbose: false } }
      let(:output_dir) { Dir.mktmpdir }

      after { FileUtils.rm_rf(output_dir) }

      it "generates multi-file SPA structure" do
        allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")
        allow(generator.asset_bundler).to receive(:copy_assets)

        result = generator.generate(lxr_path, yaml_path, output_dir)

        expect(result).to be_a(Lutaml::Klin::Spa::Models::UnifiedSchema)
        expect(File.exist?(File.join(output_dir, "index.html"))).to be true
        expect(Dir.exist?(File.join(output_dir, "data"))).to be true
      end

      it "writes JSON data files" do
        allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")
        allow(generator.asset_bundler).to receive(:copy_assets)

        generator.generate(lxr_path, yaml_path, output_dir)

        expect(File.exist?(File.join(output_dir, "data/schema.json"))).to be true
        expect(File.exist?(File.join(output_dir, "data/cross_refs.json"))).to be true
        expect(File.exist?(File.join(output_dir, "data/search_index.json"))).to be true
      end

      it "copies assets to output directory" do
        allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")
        expect(generator.asset_bundler).to receive(:copy_assets).with(output_dir)

        generator.generate(lxr_path, yaml_path, output_dir)
      end
    end

    context "with embedded mode" do
      let(:options) { { mode: :embedded, verbose: false } }
      let(:output_file) { File.join(Dir.mktmpdir, "output.html") }

      after { FileUtils.rm_rf(File.dirname(output_file)) }

      it "generates single embedded HTML file" do
        allow(generator.template_renderer).to receive(:render_template).and_return("<html>embedded</html>")
        allow(generator.asset_bundler).to receive(:inline_css).and_return("css")
        allow(generator.asset_bundler).to receive(:inline_js).and_return("js")

        result = generator.generate(lxr_path, yaml_path, output_file)

        expect(result).to be_a(Lutaml::Klin::Spa::Models::UnifiedSchema)
        expect(File.exist?(output_file)).to be true
      end

      it "uses embedded template" do
        allow(generator.asset_bundler).to receive(:inline_css).and_return("css")
        allow(generator.asset_bundler).to receive(:inline_js).and_return("js")

        expect(generator.template_renderer).to receive(:render_template)
          .with("embedded.liquid", hash_including("css", "js", "schema_data"))
          .and_return("<html></html>")

        generator.generate(lxr_path, yaml_path, output_file)
      end

      it "inlines CSS and JavaScript" do
        allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")

        expect(generator.asset_bundler).to receive(:inline_css)
        expect(generator.asset_bundler).to receive(:inline_js)

        generator.generate(lxr_path, yaml_path, output_file)
      end
    end

    it "loads LXR data" do
      allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")
      allow(generator.asset_bundler).to receive(:copy_assets)

      expect(generator.data_loader).to receive(:load_lxr).with(lxr_path)

      generator.generate(lxr_path, yaml_path, Dir.mktmpdir)
    end

    it "builds cross-references" do
      allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")
      allow(generator.asset_bundler).to receive(:copy_assets)

      expect(generator.cross_ref_builder).to receive(:build).with(mock_schema)

      generator.generate(lxr_path, yaml_path, Dir.mktmpdir)
    end

    it "builds search index" do
      allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")
      allow(generator.asset_bundler).to receive(:copy_assets)

      expect(generator.search_builder).to receive(:build).with(mock_schema)

      generator.generate(lxr_path, yaml_path, Dir.mktmpdir)
    end

    context "with YAML mapping" do
      let(:yaml_path) { "mapping.yaml" }

      before do
        allow(File).to receive(:exist?).with(yaml_path).and_return(true)
        allow(generator.data_loader).to receive(:load_yaml).and_return({})
      end

      it "loads YAML mapping" do
        allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")
        allow(generator.asset_bundler).to receive(:copy_assets)

        expect(generator.data_loader).to receive(:load_yaml).with(yaml_path)

        generator.generate(lxr_path, yaml_path, Dir.mktmpdir)
      end

      it "merges LXR and YAML data" do
        allow(generator.template_renderer).to receive(:render_template).and_return("<html></html>")
        allow(generator.asset_bundler).to receive(:copy_assets)

        expect(generator.data_loader).to receive(:merge).with(anything, {})

        generator.generate(lxr_path, yaml_path, Dir.mktmpdir)
      end
    end
  end

  describe "option normalization" do
    it "converts string mode to symbol" do
      gen = described_class.new(mode: "embedded")
      expect(gen.options[:mode]).to eq(:embedded)
    end

    it "uses default theme" do
      gen = described_class.new
      expect(gen.options[:theme]).to eq("default")
    end

    it "accepts custom theme" do
      gen = described_class.new(theme: "dark")
      expect(gen.options[:theme]).to eq("dark")
    end

    it "accepts custom title" do
      gen = described_class.new(title: "My Schema")
      expect(gen.options[:title]).to eq("My Schema")
    end

    it "accepts custom template directory" do
      gen = described_class.new(template_dir: "/custom/templates")
      expect(gen.options[:template_dir]).to eq("/custom/templates")
    end

    it "accepts custom assets directory" do
      gen = described_class.new(assets_dir: "/custom/assets")
      expect(gen.options[:assets_dir]).to eq("/custom/assets")
    end
  end

  describe "default output paths" do
    it "uses default for embedded mode" do
      gen = described_class.new(mode: :embedded)
      allow(gen.data_loader).to receive(:load_lxr).and_return({
        metadata: {}, namespaces: [], elements: [], complex_types: [],
        simple_types: [], attributes: [], statistics: Lutaml::Klin::Spa::Models::Statistics.new
      })
      allow(gen.data_loader).to receive(:merge).and_return(
        Lutaml::Klin::Spa::Models::UnifiedSchema.new.tap do |s|
          s.metadata = Lutaml::Klin::Spa::Models::SchemaMetadata.new
          s.schemas = []
          s.elements = []
          s.complex_types = []
          s.simple_types = []
          s.attributes = []
          s.statistics = Lutaml::Klin::Spa::Models::Statistics.new
          s.cross_references = Lutaml::Klin::Spa::Models::CrossReferenceIndex.new
          s.search_index = Lutaml::Klin::Spa::Models::SearchIndex.new
        end
      )
      allow(gen.cross_ref_builder).to receive(:build).and_return(
        Lutaml::Klin::Spa::Models::CrossReferenceIndex.new
      )
      allow(gen.search_builder).to receive(:build).and_return(
        Lutaml::Klin::Spa::Models::SearchIndex.new
      )
      allow(gen.template_renderer).to receive(:render_template).and_return("<html></html>")
      allow(gen.asset_bundler).to receive(:inline_css).and_return("")
      allow(gen.asset_bundler).to receive(:inline_js).and_return("")

      gen.generate(lxr_path)
      expect(File.exist?("spa_output.html")).to be true
      FileUtils.rm_f("spa_output.html")
    end

    it "uses default for multi-file mode" do
      gen = described_class.new(mode: :multi_file)
      allow(gen.data_loader).to receive(:load_lxr).and_return({
        metadata: {}, namespaces: [], elements: [], complex_types: [],
        simple_types: [], attributes: [], statistics: Lutaml::Klin::Spa::Models::Statistics.new
      })
      allow(gen.data_loader).to receive(:merge).and_return(
        Lutaml::Klin::Spa::Models::UnifiedSchema.new.tap do |s|
          s.metadata = Lutaml::Klin::Spa::Models::SchemaMetadata.new
          s.schemas = []
          s.elements = []
          s.complex_types = []
          s.simple_types = []
          s.attributes = []
          s.statistics = Lutaml::Klin::Spa::Models::Statistics.new
          s.cross_references = Lutaml::Klin::Spa::Models::CrossReferenceIndex.new
          s.search_index = Lutaml::Klin::Spa::Models::SearchIndex.new
        end
      )
      allow(gen.cross_ref_builder).to receive(:build).and_return(
        Lutaml::Klin::Spa::Models::CrossReferenceIndex.new
      )
      allow(gen.search_builder).to receive(:build).and_return(
        Lutaml::Klin::Spa::Models::SearchIndex.new
      )
      allow(gen.template_renderer).to receive(:render_template).and_return("<html></html>")
      allow(gen.asset_bundler).to receive(:copy_assets)

      gen.generate(lxr_path)
      expect(Dir.exist?("spa_output")).to be true
      FileUtils.rm_rf("spa_output")
    end
  end
end