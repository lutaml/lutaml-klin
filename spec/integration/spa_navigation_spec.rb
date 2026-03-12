# frozen_string_literal: true

require "spec_helper"
require "json"
require "fileutils"

RSpec.describe "SPA Navigation", type: :integration do
  let(:mapping_file) { "test_workflow/step1_uro/urbanObject_mapping.yaml" }
  let(:output_dir) { "tmp/spa_navigation_test" }
  let(:index_html) { File.join(output_dir, "index.html") }
  let(:mappings_json) { File.join(output_dir, "data", "mappings.json") }
  let(:search_index_json) { File.join(output_dir, "data", "search_index.json") }
  let(:statistics_json) { File.join(output_dir, "data", "statistics.json") }

  before do
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)

    # Generate SPA
    cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
          "--mapping #{mapping_file} --output #{output_dir} 2>&1"
    output = `#{cmd}`
    expect($CHILD_STATUS.exitstatus).to eq(0),
                                         "SPA generation failed: #{output}"
  end

  after do
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
  end

  describe "HTML Structure" do
    it "generates index.html with complete structure" do
      expect(File).to exist(index_html)

      html = File.read(index_html)

      # Check essential HTML elements
      expect(html).to include("<!DOCTYPE html>")
      expect(html).to include("<html lang=\"en\">")
      expect(html).to include("UML-XSD Mapping Browser")

      # Check Alpine.js integration
      expect(html).to include("alpinejs")
      expect(html).to include("x-data=\"mappingBrowser\"")

      # Check Prism.js for syntax highlighting
      expect(html).to include("prismjs")
      expect(html).to include("language-markup")
    end

    it "embeds data correctly" do
      html = File.read(index_html)

      # Check embedded data is present (not placeholders)
      expect(html).to include("window.MAPPING_DATA = {")
      expect(html).to include("window.SEARCH_INDEX = {")
      expect(html).to include("window.STATISTICS = {")

      # Should NOT contain placeholder strings
      expect(html).not_to include("%{MAPPINGS_JSON}")
      expect(html).not_to include("%{SEARCH_INDEX_JSON}")
      expect(html).not_to include("%{STATISTICS_JSON}")
    end
  end

  describe "Data Files" do
    it "generates mappings.json with hash-based structure" do
      expect(File).to exist(mappings_json)

      data = JSON.parse(File.read(mappings_json))

      # Check top-level structure
      expect(data).to have_key("metadata")
      expect(data).to have_key("packages")
      expect(data).to have_key("classes")
      expect(data).to have_key("attributes")

      # Verify hash-based structure (not arrays)
      expect(data["packages"]).to be_a(Hash)
      expect(data["classes"]).to be_a(Hash)
      expect(data["attributes"]).to be_a(Hash)
    end

    it "includes metadata in mappings.json" do
      data = JSON.parse(File.read(mappings_json))
      metadata = data["metadata"]

      expect(metadata).to include("version")
      expect(metadata).to include("generated_at")
      expect(metadata).to include("total_packages")
      expect(metadata).to include("total_classes")
      expect(metadata).to include("total_attributes")
    end

    it "includes packages with class references" do
      data = JSON.parse(File.read(mappings_json))
      packages = data["packages"]

      expect(packages).not_to be_empty

      # Check first package structure
      first_pkg = packages.values.first
      expect(first_pkg).to include("id", "name", "qualified_name", "classes")
      expect(first_pkg["classes"]).to be_an(Array)
      expect(first_pkg["classes"]).not_to be_empty
    end

    it "includes classes with attributes and XML instances" do
      data = JSON.parse(File.read(mappings_json))
      classes = data["classes"]

      expect(classes).not_to be_empty

      # Check first class structure
      first_class = classes.values.first
      expect(first_class).to include(
        "id", "name", "qualified_name", "attributes",
        "xsd_element_name", "xsd_type_name", "xml_instance"
      )

      # Verify XML instance is present and valid
      xml_instance = first_class["xml_instance"]
      expect(xml_instance).to be_a(String)
      expect(xml_instance).to include("<?xml version")
      expect(xml_instance).to include("xmlns:")
    end

    it "includes attributes with UML and XSD data" do
      data = JSON.parse(File.read(mappings_json))
      attributes = data["attributes"]

      expect(attributes).not_to be_empty

      # Check first attribute structure
      first_attr = attributes.values.first
      expect(first_attr).to include(
        "id", "name", "uml_type", "xsd_type",
        "resolution_status"
      )
    end

    it "generates search_index.json with searchable entries" do
      expect(File).to exist(search_index_json)

      data = JSON.parse(File.read(search_index_json))
      expect(data).to have_key("index")
      expect(data["index"]).to be_an(Array)
      expect(data["index"]).not_to be_empty

      # Check first entry structure
      first_entry = data["index"].first
      expect(first_entry).to include(
        "id", "type", "title", "qualified_name", "keywords"
      )
    end

    it "generates statistics.json with summary data" do
      expect(File).to exist(statistics_json)

      data = JSON.parse(File.read(statistics_json))
      expect(data).to have_key("summary")
      expect(data).to have_key("packages")

      summary = data["summary"]
      expect(summary).to include(
        "total_packages", "total_classes", "total_attributes",
        "resolution_rate"
      )
    end
  end

  describe "Asset Files" do
    it "copies CSS file" do
      css_file = File.join(output_dir, "assets", "css", "style.css")
      expect(File).to exist(css_file)

      css = File.read(css_file)
      expect(css).to include(":root")
      expect(css).to include("--color-resolved")
      expect(css).to include(".package-tree")
      expect(css).to include(".class-detail")
    end

    it "copies JavaScript file" do
      js_file = File.join(output_dir, "assets", "js", "app.js")
      expect(File).to exist(js_file)

      js = File.read(js_file)
      expect(js).to include("Alpine.data('mappingBrowser'")
      expect(js).to include("getPackageClasses")
      expect(js).to include("getClassAttributes")
    end
  end

  describe "Data Consistency" do
    it "has consistent package-class-attribute relationships" do
      data = JSON.parse(File.read(mappings_json))

      # Pick a package
      package = data["packages"].values.first
      class_ids = package["classes"]

      expect(class_ids).not_to be_empty

      # Verify all class IDs exist in classes hash
      class_ids.each do |class_id|
        expect(data["classes"]).to have_key(class_id)
      end

      # Pick a class and verify its attributes
      first_class = data["classes"][class_ids.first]
      attr_ids = first_class["attributes"]

      # Verify all attribute IDs exist in attributes hash
      attr_ids.each do |attr_id|
        expect(data["attributes"]).to have_key(attr_id)
      end
    end

    it "has searchable entries for all packages and classes" do
      mappings = JSON.parse(File.read(mappings_json))
      search_index = JSON.parse(File.read(search_index_json))

      package_count = mappings["packages"].size
      class_count = mappings["classes"].size

      # Search index should have at least one entry per package and class
      package_entries = search_index["index"].count do |e|
        e["type"] == "package"
      end
      class_entries = search_index["index"].count { |e| e["type"] == "class" }

      expect(package_entries).to eq(package_count)
      expect(class_entries).to eq(class_count)
    end
  end

  describe "XML Instance Generation" do
    it "generates XML instances with proper namespaces" do
      data = JSON.parse(File.read(mappings_json))

      # Find a class with attributes
      class_with_attrs = data["classes"].values.find do |cls|
        cls["attributes"] && cls["attributes"].size.positive?
      end

      expect(class_with_attrs).not_to be_nil

      xml = class_with_attrs["xml_instance"]

      # Check XML header
      expect(xml).to include('<?xml version="1.0" encoding="UTF-8"?>')

      # Check namespace declaration
      expect(xml).to match(/xmlns:\w+="https?:\/\//)

      # Check root element uses namespace prefix
      expect(xml).to match(/<\w+:\w+/)
    end

    it "includes UML-to-XSD mapping comments in XML instances" do
      data = JSON.parse(File.read(mappings_json))

      class_with_attrs = data["classes"].values.find do |cls|
        cls["attributes"] && cls["attributes"].size.positive?
      end

      xml = class_with_attrs["xml_instance"]

      # Check for mapping comments
      expect(xml).to include("<!-- UML:")
      expect(xml).to include("<!-- XSD:")
    end
  end

  describe "Statistics" do
    it "calculates resolution rates correctly" do
      statistics = JSON.parse(File.read(statistics_json))
      summary = statistics["summary"]

      total_classes = summary["total_classes"]
      resolved_classes = summary["resolved_classes"]

      expect(total_classes).to be > 0
      expect(resolved_classes).to be <= total_classes

      expected_rate = (resolved_classes.to_f / total_classes * 100).round(1)
      expect(summary["resolution_rate"]).to eq(expected_rate)
    end

    it "has per-package statistics" do
      statistics = JSON.parse(File.read(statistics_json))
      packages = statistics["packages"]

      expect(packages).to be_an(Array)
      expect(packages).not_to be_empty

      first_pkg = packages.first
      expect(first_pkg).to include(
        "name", "qualified_name", "resolution_rate", "statistics"
      )
    end
  end
end