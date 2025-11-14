# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/asset_bundler"
require "fileutils"
require "tmpdir"

RSpec.describe Lutaml::Klin::Spa::AssetBundler do
  let(:fixture_dir) { File.join(__dir__, "../../../fixtures/spa/assets") }
  let(:bundler) { described_class.new(fixture_dir) }

  before(:all) do
    # Create fixture assets for testing
    @fixture_dir = File.join(__dir__, "../../../fixtures/spa/assets")
    @css_dir = File.join(@fixture_dir, "css")
    @js_dir = File.join(@fixture_dir, "js")
    @icons_dir = File.join(@fixture_dir, "icons")

    FileUtils.mkdir_p(@css_dir)
    FileUtils.mkdir_p(@js_dir)
    FileUtils.mkdir_p(@icons_dir)

    # Create CSS files
    File.write(File.join(@css_dir, "main.css"), <<~CSS)
      body { margin: 0; }
    CSS

    File.write(File.join(@css_dir, "navigation.css"), <<~CSS)
      .nav { display: flex; }
    CSS

    File.write(File.join(@css_dir, "content.css"), <<~CSS)
      .content { padding: 1rem; }
    CSS

    File.write(File.join(@css_dir, "responsive.css"), <<~CSS)
      @media (max-width: 768px) { body { font-size: 14px; } }
    CSS

    # Create JS files
    File.write(File.join(@js_dir, "utils.js"), <<~JS)
      const utils = { log: console.log };
    JS

    File.write(File.join(@js_dir, "navigation.js"), <<~JS)
      const navigation = { init: () => {} };
    JS

    File.write(File.join(@js_dir, "search.js"), <<~JS)
      const search = { query: '' };
    JS

    File.write(File.join(@js_dir, "renderer.js"), <<~JS)
      const renderer = { render: () => {} };
    JS

    File.write(File.join(@js_dir, "router.js"), <<~JS)
      const router = { navigate: () => {} };
    JS

    File.write(File.join(@js_dir, "app.js"), <<~JS)
      const app = { init: () => {} };
    JS

    # Create an icon file
    File.write(File.join(@icons_dir, "logo.svg"), <<~SVG)
      <svg></svg>
    SVG
  end

  after(:all) do
    # Clean up fixture files
    FileUtils.rm_rf(@fixture_dir) if @fixture_dir && Dir.exist?(@fixture_dir)
  end

  describe "#initialize" do
    it "uses the provided assets directory" do
      expect(bundler.assets_dir).to eq(fixture_dir)
    end

    it "uses default assets directory when none provided" do
      default_bundler = described_class.new
      expect(default_bundler.assets_dir).to include("spa/assets")
    end
  end

  describe "#inline_css" do
    it "combines all CSS files into a single string" do
      result = bundler.inline_css

      expect(result).to include("body { margin: 0; }")
      expect(result).to include(".nav { display: flex; }")
      expect(result).to include(".content { padding: 1rem; }")
      expect(result).to include("@media (max-width: 768px)")
    end

    it "separates CSS files with double newlines" do
      result = bundler.inline_css
      expect(result).to include("\n\n")
    end

    it "handles missing CSS files gracefully" do
      temp_dir = Dir.mktmpdir
      temp_bundler = described_class.new(temp_dir)

      expect { temp_bundler.inline_css }.not_to raise_error
      result = temp_bundler.inline_css
      expect(result).to be_a(String)

      FileUtils.rm_rf(temp_dir)
    end

    it "warns about missing CSS files" do
      temp_dir = Dir.mktmpdir
      temp_bundler = described_class.new(temp_dir)

      expect(temp_bundler).to receive(:warn).at_least(:once)
      temp_bundler.inline_css

      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "#inline_js" do
    it "combines all JS files into a single string" do
      result = bundler.inline_js

      expect(result).to include("const utils =")
      expect(result).to include("const navigation =")
      expect(result).to include("const search =")
      expect(result).to include("const renderer =")
      expect(result).to include("const router =")
      expect(result).to include("const app =")
    end

    it "separates JS files with double newlines" do
      result = bundler.inline_js
      expect(result).to include("\n\n")
    end

    it "handles missing JS files gracefully" do
      temp_dir = Dir.mktmpdir
      temp_bundler = described_class.new(temp_dir)

      expect { temp_bundler.inline_js }.not_to raise_error
      result = temp_bundler.inline_js
      expect(result).to be_a(String)

      FileUtils.rm_rf(temp_dir)
    end

    it "warns about missing JS files" do
      temp_dir = Dir.mktmpdir
      temp_bundler = described_class.new(temp_dir)

      expect(temp_bundler).to receive(:warn).at_least(:once)
      temp_bundler.inline_js

      FileUtils.rm_rf(temp_dir)
    end
  end

  describe "#copy_assets" do
    let(:output_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(output_dir)
    end

    it "creates assets directory in output" do
      bundler.copy_assets(output_dir)
      expect(Dir.exist?(File.join(output_dir, "assets"))).to be true
    end

    it "copies CSS directory" do
      bundler.copy_assets(output_dir)
      css_output = File.join(output_dir, "assets", "css")

      expect(Dir.exist?(css_output)).to be true
      expect(File.exist?(File.join(css_output, "main.css"))).to be true
      expect(File.exist?(File.join(css_output, "navigation.css"))).to be true
      expect(File.exist?(File.join(css_output, "content.css"))).to be true
      expect(File.exist?(File.join(css_output, "responsive.css"))).to be true
    end

    it "copies JS directory" do
      bundler.copy_assets(output_dir)
      js_output = File.join(output_dir, "assets", "js")

      expect(Dir.exist?(js_output)).to be true
      expect(File.exist?(File.join(js_output, "utils.js"))).to be true
      expect(File.exist?(File.join(js_output, "navigation.js"))).to be true
      expect(File.exist?(File.join(js_output, "app.js"))).to be true
    end

    it "copies icons directory if it exists" do
      bundler.copy_assets(output_dir)
      icons_output = File.join(output_dir, "assets", "icons")

      expect(Dir.exist?(icons_output)).to be true
      expect(File.exist?(File.join(icons_output, "logo.svg"))).to be true
    end

    it "handles missing directories gracefully" do
      temp_dir = Dir.mktmpdir
      temp_bundler = described_class.new(temp_dir)

      expect { temp_bundler.copy_assets(output_dir) }.not_to raise_error

      FileUtils.rm_rf(temp_dir)
    end

    it "preserves file contents when copying" do
      bundler.copy_assets(output_dir)

      css_file = File.join(output_dir, "assets", "css", "main.css")
      expect(File.read(css_file)).to include("body { margin: 0; }")

      js_file = File.join(output_dir, "assets", "js", "app.js")
      expect(File.read(js_file)).to include("const app =")
    end
  end

  describe "#css_files" do
    it "returns list of CSS file paths" do
      files = bundler.css_files

      expect(files).to be_an(Array)
      expect(files).to include("css/main.css")
      expect(files).to include("css/navigation.css")
      expect(files).to include("css/content.css")
      expect(files).to include("css/responsive.css")
    end

    it "returns files in correct order" do
      files = bundler.css_files

      expect(files[0]).to eq("css/main.css")
      expect(files[1]).to eq("css/navigation.css")
      expect(files[2]).to eq("css/content.css")
      expect(files[3]).to eq("css/responsive.css")
    end
  end

  describe "#js_files" do
    it "returns list of JS file paths" do
      files = bundler.js_files

      expect(files).to be_an(Array)
      expect(files).to include("js/utils.js")
      expect(files).to include("js/navigation.js")
      expect(files).to include("js/search.js")
      expect(files).to include("js/renderer.js")
      expect(files).to include("js/router.js")
      expect(files).to include("js/app.js")
    end

    it "returns files in correct order" do
      files = bundler.js_files

      expect(files[0]).to eq("js/utils.js")
      expect(files[-1]).to eq("js/app.js")
    end
  end

  describe "integration scenarios" do
    context "embedded mode" do
      it "provides all necessary inline assets" do
        css = bundler.inline_css
        js = bundler.inline_js

        expect(css).not_to be_empty
        expect(js).not_to be_empty

        # Check that essential styles are present
        expect(css).to include("body")
        expect(css).to include(".nav")
        expect(css).to include(".content")

        # Check that essential scripts are present
        expect(js).to include("const utils")
        expect(js).to include("const app")
      end
    end

    context "multi-file mode" do
      let(:output_dir) { Dir.mktmpdir }

      after do
        FileUtils.rm_rf(output_dir)
      end

      it "creates complete asset structure" do
        bundler.copy_assets(output_dir)

        # Verify structure
        expect(Dir.exist?(File.join(output_dir, "assets", "css"))).to be true
        expect(Dir.exist?(File.join(output_dir, "assets", "js"))).to be true

        # Count files
        css_files = Dir.glob(File.join(output_dir, "assets", "css", "*"))
        js_files = Dir.glob(File.join(output_dir, "assets", "js", "*"))

        expect(css_files.length).to eq(4)
        expect(js_files.length).to eq(6)
      end
    end
  end

  describe "edge cases" do
    it "handles empty CSS files" do
      temp_dir = Dir.mktmpdir
      temp_css_dir = File.join(temp_dir, "css")
      FileUtils.mkdir_p(temp_css_dir)

      File.write(File.join(temp_css_dir, "main.css"), "")
      File.write(File.join(temp_css_dir, "navigation.css"), "")
      File.write(File.join(temp_css_dir, "content.css"), "")
      File.write(File.join(temp_css_dir, "responsive.css"), "")

      temp_bundler = described_class.new(temp_dir)
      result = temp_bundler.inline_css

      expect(result).to be_a(String)
      # Empty files joined with "\n\n" creates separators between them
      expect(result).to eq("\n\n\n\n\n\n")

      FileUtils.rm_rf(temp_dir)
    end

    it "handles empty JS files" do
      temp_dir = Dir.mktmpdir
      temp_js_dir = File.join(temp_dir, "js")
      FileUtils.mkdir_p(temp_js_dir)

      %w[utils navigation search renderer router app].each do |name|
        File.write(File.join(temp_js_dir, "#{name}.js"), "")
      end

      temp_bundler = described_class.new(temp_dir)
      result = temp_bundler.inline_js

      expect(result).to be_a(String)

      FileUtils.rm_rf(temp_dir)
    end

    it "handles special characters in file contents" do
      temp_dir = Dir.mktmpdir
      temp_css_dir = File.join(temp_dir, "css")
      FileUtils.mkdir_p(temp_css_dir)

      File.write(File.join(temp_css_dir, "main.css"), "/* Special: © ™ €  */")
      File.write(File.join(temp_css_dir, "navigation.css"), "")
      File.write(File.join(temp_css_dir, "content.css"), "")
      File.write(File.join(temp_css_dir, "responsive.css"), "")

      temp_bundler = described_class.new(temp_dir)
      result = temp_bundler.inline_css

      expect(result).to include("©")
      expect(result).to include("™")
      expect(result).to include("€")

      FileUtils.rm_rf(temp_dir)
    end
  end
end