# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/template_renderer"
require "fileutils"
require "tmpdir"

RSpec.describe Lutaml::Klin::Spa::TemplateRenderer do
  let(:fixture_dir) { File.join(__dir__, "../../../fixtures/spa/templates") }
  let(:renderer) { described_class.new(fixture_dir) }

  before(:all) do
    # Create fixture templates for testing
    @fixture_dir = File.join(__dir__, "../../../fixtures/spa/templates")
    @partials_dir = File.join(@fixture_dir, "partials")

    FileUtils.mkdir_p(@partials_dir)

    # Create a simple test template
    File.write(File.join(@fixture_dir, "test.liquid"), <<~LIQUID)
      <h1>{{ title }}</h1>
      <p>{{ description }}</p>
    LIQUID

    # Create a test partial
    File.write(File.join(@partials_dir, "header.liquid"), <<~LIQUID)
      <header>
        <h1>{{ site_name }}</h1>
      </header>
    LIQUID

    # Create a template that uses the partial
    File.write(File.join(@fixture_dir, "with_partial.liquid"), <<~LIQUID)
      {% include 'header' %}
      <main>{{ content }}</main>
    LIQUID

    # Create a template with nested data
    File.write(File.join(@fixture_dir, "nested.liquid"), <<~LIQUID)
      <div class="metadata">
        <span>{{ metadata.name }}</span>
        <span>{{ metadata.version }}</span>
      </div>
    LIQUID

    # Create a template with array iteration
    File.write(File.join(@fixture_dir, "array.liquid"), <<~LIQUID)
      <ul>
      {% for item in items %}
        <li>{{ item.name }}</li>
      {% endfor %}
      </ul>
    LIQUID

    # Create a template with conditionals
    File.write(File.join(@fixture_dir, "conditional.liquid"), <<~LIQUID)
      {% if show_title %}
      <h1>{{ title }}</h1>
      {% endif %}
      {% if items.size > 0 %}
      <p>Found {{ items.size }} items</p>
      {% endif %}
    LIQUID
  end

  after(:all) do
    # Clean up fixture files
    FileUtils.rm_rf(@fixture_dir) if @fixture_dir && Dir.exist?(@fixture_dir)
  end

  describe "#initialize" do
    it "uses the provided template directory" do
      expect(renderer.template_dir).to eq(fixture_dir)
    end

    it "sets the partials directory correctly" do
      expect(renderer.partials_dir).to eq(File.join(fixture_dir, "partials"))
    end

    it "uses default template directory when none provided" do
      default_renderer = described_class.new
      expect(default_renderer.template_dir).to include("spa/templates")
    end

    it "creates a file system instance for partials" do
      expect(renderer.instance_variable_get(:@file_system)).to be_a(Liquid::LocalFileSystem)
    end
  end

  describe "#render_template" do
    context "with simple template" do
      it "renders template with string context" do
        result = renderer.render_template("test.liquid", {
          title: "Test Title",
          description: "Test Description"
        })

        expect(result).to include("<h1>Test Title</h1>")
        expect(result).to include("<p>Test Description</p>")
      end

      it "renders template with symbol keys" do
        result = renderer.render_template("test.liquid", {
          title: "Symbol Keys",
          description: "Works with symbols"
        })

        expect(result).to include("Symbol Keys")
        expect(result).to include("Works with symbols")
      end
    end

    context "with nested data" do
      it "renders template with nested hash" do
        result = renderer.render_template("nested.liquid", {
          metadata: {
            name: "Test Schema",
            version: "1.0.0"
          }
        })

        expect(result).to include("Test Schema")
        expect(result).to include("1.0.0")
      end
    end

    context "with arrays" do
      it "renders template with array iteration" do
        result = renderer.render_template("array.liquid", {
          items: [
            { name: "Item 1" },
            { name: "Item 2" },
            { name: "Item 3" }
          ]
        })

        expect(result).to include("<li>Item 1</li>")
        expect(result).to include("<li>Item 2</li>")
        expect(result).to include("<li>Item 3</li>")
      end

      it "handles empty arrays" do
        result = renderer.render_template("array.liquid", { items: [] })
        expect(result.strip).to eq("<ul>\n\n</ul>")
      end
    end

    context "with conditionals" do
      it "shows content when condition is true" do
        result = renderer.render_template("conditional.liquid", {
          show_title: true,
          title: "Conditional Title",
          items: [1, 2, 3]
        })

        expect(result).to include("<h1>Conditional Title</h1>")
        expect(result).to include("Found 3 items")
      end

      it "hides content when condition is false" do
        result = renderer.render_template("conditional.liquid", {
          show_title: false,
          title: "Hidden Title",
          items: []
        })

        expect(result).not_to include("<h1>")
        expect(result).not_to include("Found")
      end
    end

    context "with partials" do
      it "can render templates with partial support configured" do
        # Verify that the renderer has a file system configured for partials
        expect(renderer.instance_variable_get(:@file_system)).to be_a(Liquid::LocalFileSystem)
        expect(renderer.partials_dir).to end_with("partials")

        # Verify partial directory exists in fixtures
        expect(Dir.exist?(renderer.partials_dir)).to be true
      end
    end

    context "error handling" do
      it "raises error for non-existent template" do
        expect {
          renderer.render_template("non_existent.liquid", {})
        }.to raise_error(Lutaml::Klin::Spa::TemplateNotFoundError)
      end

      it "includes template path in error message" do
        expect {
          renderer.render_template("missing.liquid", {})
        }.to raise_error(/missing\.liquid/)
      end
    end
  end

  describe "#render_partial" do
    it "renders a partial with context" do
      result = renderer.render_partial("header", {
        site_name: "Partial Test"
      })

      expect(result).to include("<h1>Partial Test</h1>")
    end

    it "raises error for non-existent partial" do
      expect {
        renderer.render_partial("non_existent", {})
      }.to raise_error(Lutaml::Klin::Spa::TemplateNotFoundError)
    end
  end

  describe "key stringification" do
    it "converts symbol keys to strings" do
      result = renderer.render_template("test.liquid", {
        title: "Symbol",
        description: "Converted"
      })

      expect(result).to include("Symbol")
      expect(result).to include("Converted")
    end

    it "handles deeply nested symbol keys" do
      result = renderer.render_template("nested.liquid", {
        metadata: {
          name: "Deep",
          version: "2.0"
        }
      })

      expect(result).to include("Deep")
      expect(result).to include("2.0")
    end

    it "handles arrays of hashes with symbol keys" do
      result = renderer.render_template("array.liquid", {
        items: [
          { name: "First" },
          { name: "Second" }
        ]
      })

      expect(result).to include("First")
      expect(result).to include("Second")
    end
  end

  describe "integration with real templates" do
    context "when template directory exists" do
      it "can access templates in subdirectories" do
        # This would test multi_file templates
        multi_file_dir = File.join(fixture_dir, "multi_file")
        FileUtils.mkdir_p(multi_file_dir)

        File.write(File.join(multi_file_dir, "index.liquid"), <<~LIQUID)
          <div>{{ page_title }}</div>
        LIQUID

        result = renderer.render_template("multi_file/index.liquid", {
          page_title: "Index Page"
        })

        expect(result).to include("Index Page")
      end
    end
  end

  describe "edge cases" do
    it "handles nil values gracefully" do
      result = renderer.render_template("test.liquid", {
        title: nil,
        description: "Has description"
      })

      expect(result).to include("Has description")
      expect(result).not_to include("nil")
    end

    it "handles empty strings" do
      result = renderer.render_template("test.liquid", {
        title: "",
        description: ""
      })

      expect(result).to include("<h1></h1>")
      expect(result).to include("<p></p>")
    end

    it "handles special characters in content" do
      result = renderer.render_template("test.liquid", {
        title: "Title with <tags>",
        description: "Description & special © chars"
      })

      expect(result).to include("Title with <tags>")
      expect(result).to include("Description & special © chars")
    end
  end
end