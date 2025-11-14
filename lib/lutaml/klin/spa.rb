# frozen_string_literal: true

require_relative "spa/errors"
require_relative "spa/models/uml_mapping"
require_relative "spa/models/statistics"
require_relative "spa/models/element_cross_references"
require_relative "spa/models/type_cross_references"
require_relative "spa/models/component_counts"
require_relative "spa/models/schema_info"
require_relative "spa/models/lxr_package_info"
require_relative "spa/models/lur_package_info"
require_relative "spa/models/traceability"
require_relative "spa/models/schema_metadata"
require_relative "spa/models/element"
require_relative "spa/models/complex_type"
require_relative "spa/models/simple_type"
require_relative "spa/models/attribute"
require_relative "spa/models/cross_reference_index"
require_relative "spa/models/search_index"
require_relative "spa/models/unified_schema"
require_relative "spa/data_loader"
require_relative "spa/cross_reference_builder"
require_relative "spa/search_index_builder"
require_relative "spa/template_renderer"
require_relative "spa/asset_bundler"
require_relative "spa/generator"

module Lutaml
  module Klin
    # SPA module for Single Page Application HTML documentation generation
    module Spa
      VERSION = "0.1.0"

      # Generate complete SPA from LXR package and optional YAML mapping
      # @param lxr_path [String] Path to LXR package file
      # @param yaml_path [String, nil] Path to YAML mapping file (optional)
      # @param output [String, nil] Output path (file or directory)
      # @param options [Hash] Additional generator options
      # @option options [Symbol] :mode Mode for generation (:embedded or :multi_file)
      # @option options [String] :theme UI theme (default, dark, plateau)
      # @option options [String] :title Custom website title
      # @option options [String] :template_dir Custom template directory
      # @option options [String] :assets_dir Custom assets directory
      # @option options [Boolean] :verbose Enable verbose output
      # @return [Models::UnifiedSchema] Generated unified schema
      def self.generate(lxr_path, yaml_path: nil, output: nil, **options)
        generator = Generator.new(options)
        generator.generate(lxr_path, yaml_path, output)
      end

      # Convenience method to process schema from LXR and YAML
      # @param lxr_path [String] path to LXR package file
      # @param yaml_path [String, nil] path to YAML mapping file (optional)
      # @param verbose [Boolean] enable verbose output
      # @return [Models::UnifiedSchema] processed unified schema
      def self.process(lxr_path, yaml_path: nil, verbose: false)
        loader = DataLoader.new(verbose: verbose)
        cross_ref_builder = CrossReferenceBuilder.new(verbose: verbose)
        search_builder = SearchIndexBuilder.new(verbose: verbose)

        # Load data
        lxr_data = loader.load_lxr(lxr_path)
        yaml_data = yaml_path ? loader.load_yaml(yaml_path) : nil

        # Merge into unified schema
        schema = loader.merge(lxr_data, yaml_data)

        # Build indexes
        schema.cross_references = cross_ref_builder.build(schema)
        schema.search_index = search_builder.build(schema)

        schema
      end
    end
  end
end