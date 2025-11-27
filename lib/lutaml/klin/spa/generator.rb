# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "data_loader"
require_relative "cross_reference_builder"
require_relative "search_index_builder"
require_relative "template_renderer"
require_relative "asset_bundler"

module Lutaml
  module Klin
    module Spa
      # Orchestrates complete SPA generation workflow
      # Coordinates all SPA components to generate interactive documentation
      class Generator
        attr_reader :options, :data_loader, :cross_ref_builder,
                    :search_builder, :template_renderer, :asset_bundler

        # @param options [Hash] Generator configuration options
        # @option options [Symbol] :mode Mode for generation (:embedded or :multi_file)
        # @option options [String] :theme UI theme (default, dark, plateau)
        # @option options [String] :title Custom website title
        # @option options [String] :template_dir Custom template directory
        # @option options [String] :assets_dir Custom assets directory
        # @option options [Boolean] :verbose Enable verbose output
        def initialize(options = {})
          @options = normalize_options(options)

          # Initialize components with dependency injection
          @data_loader = DataLoader.new(verbose: @options[:verbose])
          @cross_ref_builder = CrossReferenceBuilder.new(
            verbose: @options[:verbose]
          )
          @search_builder = SearchIndexBuilder.new(
            verbose: @options[:verbose]
          )
          @template_renderer = TemplateRenderer.new(@options[:template_dir])
          @asset_bundler = AssetBundler.new(@options[:assets_dir])
        end

        # Generate complete SPA from data sources
        # @param lxr_path [String] Path to LXR package file
        # @param yaml_path [String, nil] Path to YAML mapping file (optional)
        # @param output_path [String, nil] Output path (file or directory)
        # @return [Models::UnifiedSchema] Generated unified schema
        def generate(lxr_path, yaml_path = nil, output_path = nil)
          log "Starting SPA generation..."

          # Step 1: Load and merge data sources
          log "Loading data sources..."
          unified_schema = load_and_merge_data(lxr_path, yaml_path)

          # Step 2: Build cross-references
          log "Building cross-reference index..."
          cross_refs = @cross_ref_builder.build(unified_schema)
          unified_schema.cross_references = cross_refs

          # Step 3: Build search index
          log "Building search index..."
          search_index = @search_builder.build(unified_schema)
          unified_schema.search_index = search_index

          # Step 4: Generate SPA based on mode
          log "Generating #{@options[:mode]} mode SPA..."
          if @options[:mode] == :embedded
            generate_embedded(unified_schema, output_path)
          else
            generate_multi_file(unified_schema, output_path)
          end

          log_statistics(unified_schema)
          log "✓ SPA generation complete: #{output_path || default_output_path(@options[:mode])}"

          unified_schema
        end

        private

        # Load and merge LXR and YAML data
        # @param lxr_path [String] Path to LXR package
        # @param yaml_path [String, nil] Path to YAML mapping
        # @return [Models::UnifiedSchema] Merged schema
        def load_and_merge_data(lxr_path, yaml_path)
          lxr_data = @data_loader.load_lxr(lxr_path)

          yaml_data = nil
          if yaml_path && File.exist?(yaml_path)
            yaml_data = @data_loader.load_yaml(yaml_path)
          end

          @data_loader.merge(lxr_data, yaml_data)
        end

        # Generate embedded mode (single HTML file)
        # @param schema [Models::UnifiedSchema] Unified schema data
        # @param output_path [String, nil] Output file path
        def generate_embedded(schema, output_path)
          output_path ||= default_output_path(:embedded)

          html = @template_renderer.render_template(
            "embedded.liquid",
            {
              "theme" => @options[:theme],
              "title" => @options[:title] || schema.metadata.name,
              "metadata" => model_to_hash(schema.metadata),
              "schemas" => schema.schemas.map { |s| model_to_hash(s) },
              "css" => @asset_bundler.inline_css,
              "js" => @asset_bundler.inline_js,
              "schema_data" => JSON.parse(schema.to_json)
            }
          )

          FileUtils.mkdir_p(File.dirname(output_path))
          File.write(output_path, html)
        end

        # Generate multi-file mode (directory with assets)
        # @param schema [Models::UnifiedSchema] Unified schema data
        # @param output_dir [String, nil] Output directory path
        def generate_multi_file(schema, output_dir)
          output_dir ||= default_output_path(:multi_file)

          # Create directory structure
          FileUtils.mkdir_p(output_dir)
          FileUtils.mkdir_p(File.join(output_dir, "data"))

          # Write index.html
          html = @template_renderer.render_template(
            "multi_file/index.liquid",
            {
              "theme" => @options[:theme],
              "title" => @options[:title] || schema.metadata.name,
              "metadata" => model_to_hash(schema.metadata),
              "schemas" => schema.schemas.map { |s| model_to_hash(s) },
              "statistics" => schema.statistics ? model_to_hash(schema.statistics) : nil,
              "index_content" => render_index_content(schema)
            }
          )

          File.write(File.join(output_dir, "index.html"), html)

          # Write JSON data files
          write_json_files(schema, output_dir)

          # Copy assets
          @asset_bundler.copy_assets(output_dir)
        end

        # Write JSON data files for multi-file mode
        # @param schema [Models::UnifiedSchema] Unified schema data
        # @param output_dir [String] Output directory
        def write_json_files(schema, output_dir)
          data_dir = File.join(output_dir, "data")

          # Main schema data
          File.write(
            File.join(data_dir, "schema.json"),
            schema.to_json(pretty: true)
          )

          # Cross-references
          File.write(
            File.join(data_dir, "cross_refs.json"),
            schema.cross_references.to_json(pretty: true)
          )

          # Search index
          File.write(
            File.join(data_dir, "search_index.json"),
            schema.search_index.to_json(pretty: true)
          )
        end

        # Render index content partial
        # @param schema [Models::UnifiedSchema] Unified schema data
        # @return [String] Rendered HTML content
        def render_index_content(schema)
          @template_renderer.render_template(
            "multi_file/index_content.liquid",
            {
              "schemas" => schema.schemas.map { |s| model_to_hash(s) },
              "statistics" => schema.statistics ? model_to_hash(schema.statistics) : nil,
              "metadata" => model_to_hash(schema.metadata)
            }
          )
        end

        # Convert Lutaml::Model::Serializable to hash
        # @param model [Lutaml::Model::Serializable] Model object
        # @return [Hash] Hash representation
        def model_to_hash(model)
          return nil unless model

          JSON.parse(model.to_json)
        end

        # Normalize options with defaults
        # @param options [Hash] Raw options
        # @return [Hash] Normalized options
        def normalize_options(options)
          {
            mode: (options[:mode] || :multi_file).to_sym,
            theme: options[:theme] || "default",
            title: options[:title],
            template_dir: options[:template_dir],
            assets_dir: options[:assets_dir],
            verbose: options[:verbose] || false
          }
        end

        # Get default output path based on mode
        # @param mode [Symbol] Generation mode
        # @return [String] Default output path
        def default_output_path(mode)
          if mode == :embedded
            "spa_output.html"
          else
            "spa_output"
          end
        end

        # Log message if verbose mode enabled
        # @param message [String] Message to log
        def log(message)
          puts message if @options[:verbose]
        end

        # Log generation statistics
        # @param schema [Models::UnifiedSchema] Unified schema
        def log_statistics(schema)
          return unless @options[:verbose]

          puts "\n=== SPA Generation Statistics ==="
          puts "Schemas: #{schema.schemas.size}"
          puts "Elements: #{schema.elements.size}"
          puts "Complex Types: #{schema.complex_types.size}"
          puts "Simple Types: #{schema.simple_types.size}"
          puts "Attributes: #{schema.attributes.size}"
          puts "Cross-references: #{schema.cross_references.element_to_type.size}"
          puts "Search terms: #{schema.search_index.terms.size}"
          puts "================================"
        end
      end
    end
  end
end
