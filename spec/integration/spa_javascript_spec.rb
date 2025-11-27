# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/spa/asset_bundler"

RSpec.describe "SPA JavaScript Assets", :integration do
  let(:bundler) { Lutaml::Klin::Spa::AssetBundler.new }
  let(:assets_dir) { bundler.assets_dir }

  describe "JavaScript file structure" do
    it "has all required JavaScript modules" do
      expected_files = [
        "js/utils.js",
        "js/router.js",
        "js/renderer.js",
        "js/search.js",
        "js/navigation.js",
        "js/app.js"
      ]

      expected_files.each do |file|
        file_path = File.join(assets_dir, file)
        expect(File.exist?(file_path)).to be(true), "Missing file: #{file}"
      end
    end

    it "JavaScript files are non-empty" do
      bundler.js_files.each do |file|
        file_path = File.join(assets_dir, file)
        content = File.read(file_path)
        expect(content.length).to be > 0, "Empty file: #{file}"
      end
    end
  end

  describe "ES6 module exports" do
    it "utils.js exports Utils class" do
      content = File.read(File.join(assets_dir, "js/utils.js"))
      expect(content).to include("class Utils")
      expect(content).to include("export { Utils }")
    end

    it "router.js exports Router class" do
      content = File.read(File.join(assets_dir, "js/router.js"))
      expect(content).to include("class Router")
      expect(content).to include("export { Router }")
    end

    it "renderer.js exports ContentRenderer class" do
      content = File.read(File.join(assets_dir, "js/renderer.js"))
      expect(content).to include("class ContentRenderer")
      expect(content).to include("export { ContentRenderer }")
    end

    it "search.js exports SearchController class" do
      content = File.read(File.join(assets_dir, "js/search.js"))
      expect(content).to include("class SearchController")
      expect(content).to include("export { SearchController }")
    end

    it "navigation.js exports NavigationController class" do
      content = File.read(File.join(assets_dir, "js/navigation.js"))
      expect(content).to include("class NavigationController")
      expect(content).to include("export { NavigationController }")
    end

    it "app.js exports SchemaDocApp class" do
      content = File.read(File.join(assets_dir, "js/app.js"))
      expect(content).to include("class SchemaDocApp")
      expect(content).to include("export { SchemaDocApp }")
    end
  end

  describe "ES6 module imports" do
    it "app.js imports all required modules" do
      content = File.read(File.join(assets_dir, "js/app.js"))
      expect(content).to include("import { NavigationController } from './navigation.js'")
      expect(content).to include("import { SearchController } from './search.js'")
      expect(content).to include("import { ContentRenderer } from './renderer.js'")
      expect(content).to include("import { Router } from './router.js'")
      expect(content).to include("import { Utils } from './utils.js'")
    end

    it "renderer.js imports Utils" do
      content = File.read(File.join(assets_dir, "js/renderer.js"))
      expect(content).to include("import { Utils } from './utils.js'")
    end

    it "search.js imports Utils" do
      content = File.read(File.join(assets_dir, "js/search.js"))
      expect(content).to include("import { Utils } from './utils.js'")
    end

    it "navigation.js imports Utils" do
      content = File.read(File.join(assets_dir, "js/navigation.js"))
      expect(content).to include("import { Utils } from './utils.js'")
    end
  end

  describe "class implementations" do
    describe "Utils class" do
      let(:content) { File.read(File.join(assets_dir, "js/utils.js")) }

      it "has escapeHtml method" do
        expect(content).to include("static escapeHtml(")
      end

      it "has highlightMatch method" do
        expect(content).to include("static highlightMatch(")
      end

      it "has escapeRegex method" do
        expect(content).to include("static escapeRegex(")
      end

      it "has debounce method" do
        expect(content).to include("static debounce(")
      end
    end

    describe "Router class" do
      let(:content) { File.read(File.join(assets_dir, "js/router.js")) }

      it "has constructor" do
        expect(content).to include("constructor(app)")
      end

      it "has defineRoutes method" do
        expect(content).to include("defineRoutes()")
      end

      it "has handleRoute method" do
        expect(content).to include("handleRoute(")
      end

      it "has updateURL method" do
        expect(content).to include("updateURL()")
      end

      it "defines route patterns" do
        expect(content).to include("pattern:")
        expect(content).to include("handler:")
      end
    end

    describe "ContentRenderer class" do
      let(:content) { File.read(File.join(assets_dir, "js/renderer.js")) }

      it "has constructor" do
        expect(content).to include("constructor(schema, app)")
      end

      it "has renderItem method" do
        expect(content).to include("renderItem(")
      end

      it "has renderElement method" do
        expect(content).to include("renderElement(")
      end

      it "has renderComplexType method" do
        expect(content).to include("renderComplexType(")
      end

      it "has renderSimpleType method" do
        expect(content).to include("renderSimpleType(")
      end

      it "has renderCrossReferences method" do
        expect(content).to include("renderCrossReferences(")
      end

      it "has renderUmlMapping method" do
        expect(content).to include("renderUmlMapping(")
      end

      it "has attachEventHandlers method" do
        expect(content).to include("attachEventHandlers()")
      end
    end

    describe "SearchController class" do
      let(:content) { File.read(File.join(assets_dir, "js/search.js")) }

      it "has constructor" do
        expect(content).to include("constructor(searchIndex, navigationController)")
      end

      it "has setupSearch method" do
        expect(content).to include("setupSearch()")
      end

      it "has performSearch method" do
        expect(content).to include("performSearch(")
      end

      it "has debouncing logic" do
        expect(content).to include("debounceTimer")
        expect(content).to include("debounceDelay")
      end

      it "has clearSearch method" do
        expect(content).to include("clearSearch()")
      end
    end

    describe "NavigationController class" do
      let(:content) { File.read(File.join(assets_dir, "js/navigation.js")) }

      it "has constructor" do
        expect(content).to include("constructor(schema, app)")
      end

      it "has three-tier navigation state" do
        expect(content).to include("currentSchema")
        expect(content).to include("currentCategory")
        expect(content).to include("currentItem")
      end

      it "has selectSchema method" do
        expect(content).to include("selectSchema(")
      end

      it "has selectCategory method" do
        expect(content).to include("selectCategory(")
      end

      it "has selectItem method" do
        expect(content).to include("selectItem(")
      end

      it "has navigateToReference method" do
        expect(content).to include("navigateToReference(")
      end

      it "has updateBreadcrumbs method" do
        expect(content).to include("updateBreadcrumbs()")
      end
    end

    describe "SchemaDocApp class" do
      let(:content) { File.read(File.join(assets_dir, "js/app.js")) }

      it "has constructor" do
        expect(content).to include("constructor()")
      end

      it "has init method" do
        expect(content).to include("async init()")
      end

      it "has loadSchema method" do
        expect(content).to include("async loadSchema()")
      end

      it "handles embedded data source" do
        expect(content).to include("embedded")
        expect(content).to include("schema-data")
      end

      it "handles external data source" do
        expect(content).to include("external")
        expect(content).to include("fetch")
      end

      it "initializes all controllers" do
        expect(content).to include("new NavigationController")
        expect(content).to include("new SearchController")
        expect(content).to include("new ContentRenderer")
        expect(content).to include("new Router")
      end
    end
  end

  describe "security features" do
    it "Utils.escapeHtml prevents XSS" do
      content = File.read(File.join(assets_dir, "js/utils.js"))
      # Check for HTML escaping implementation
      expect(content).to include("escapeHtml")
      expect(content).to include("textContent")
    end

    it "renderer uses escapeHtml for user content" do
      content = File.read(File.join(assets_dir, "js/renderer.js"))
      expect(content).to include("Utils.escapeHtml")
    end
  end

  describe "accessibility features" do
    it "navigation supports keyboard events" do
      content = File.read(File.join(assets_dir, "js/navigation.js"))
      expect(content).to include("keydown")
      expect(content).to include("Enter")
    end

    it "search supports keyboard shortcuts" do
      content = File.read(File.join(assets_dir, "js/search.js"))
      expect(content).to include("Ctrl+K")
      expect(content).to include("Escape")
    end

    it "elements have ARIA attributes" do
      content = File.read(File.join(assets_dir, "js/navigation.js"))
      expect(content).to include("aria-")
    end
  end

  describe "mobile support" do
    it "has mobile navigation handlers" do
      content = File.read(File.join(assets_dir, "js/app.js"))
      expect(content).to include("hamburger-menu")
      expect(content).to include("nav-overlay")
    end

    it "navigation closes on mobile" do
      content = File.read(File.join(assets_dir, "js/navigation.js"))
      expect(content).to include("closeMobileNav")
    end
  end

  describe "bundled JavaScript" do
    it "includes all required JavaScript modules" do
      js_content = bundler.inline_js

      expect(js_content).to include("class Utils")
      expect(js_content).to include("class Router")
      expect(js_content).to include("class ContentRenderer")
      expect(js_content).to include("class SearchController")
      expect(js_content).to include("class NavigationController")
      expect(js_content).to include("class SchemaDocApp")
    end

    it "includes all exports" do
      js_content = bundler.inline_js

      expect(js_content).to include("export { Utils }")
      expect(js_content).to include("export { Router }")
      expect(js_content).to include("export { ContentRenderer }")
      expect(js_content).to include("export { SearchController }")
      expect(js_content).to include("export { NavigationController }")
      expect(js_content).to include("export { SchemaDocApp }")
    end

    it "includes all imports" do
      js_content = bundler.inline_js

      expect(js_content).to include("import { NavigationController }")
      expect(js_content).to include("import { SearchController }")
      expect(js_content).to include("import { ContentRenderer }")
      expect(js_content).to include("import { Router }")
      expect(js_content).to include("import { Utils }")
    end
  end

  describe "code quality" do
    it "uses ES6+ features" do
      js_content = bundler.inline_js

      # Check for ES6 classes
      expect(js_content).to include("class ")

      # Check for arrow functions
      expect(js_content).to include(" => ")

      # Check for template literals
      expect(js_content).to include("`")

      # Check for const/let
      expect(js_content).to match(/\b(const|let)\b/)
    end

    it "has proper JSDoc comments" do
      bundler.js_files.each do |file|
        content = File.read(File.join(assets_dir, file))
        expect(content).to include("/**"), "Missing JSDoc in #{file}"
        expect(content).to include("@param"), "Missing @param in #{file}"
      end
    end

    it "has error handling" do
      content = File.read(File.join(assets_dir, "js/app.js"))
      expect(content).to include("try")
      expect(content).to include("catch")
      expect(content).to include("console.error")
    end
  end
end
