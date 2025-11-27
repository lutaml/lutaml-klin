# frozen_string_literal: true

require_relative "errors"
require_relative "models/search_index"

module Lutaml
  module Klin
    module Spa
      # SearchIndexBuilder builds optimized search index for basic text search
      class SearchIndexBuilder
        attr_reader :verbose

        def initialize(verbose: false)
          @verbose = verbose
        end

        # Build search index from unified schema
        # @param unified_schema [Models::UnifiedSchema] the schema to index
        # @return [Models::SearchIndex] the built search index
        def build(unified_schema)
          log("Building search index")

          index = Models::SearchIndex.new

          # Build term-based index
          index.terms = build_term_index(unified_schema)

          # Build namespace-based index
          index.by_namespace = build_namespace_index(unified_schema)

          # Build category-based index
          index.by_category = build_category_index(unified_schema)

          log("Search index built with #{index.terms.size} unique terms")
          index
        rescue StandardError => e
          raise IndexBuildError, "Failed to build search index: #{e.message}"
        end

        private

        def log(message)
          puts(message) if verbose
        end

        # Build term-based search index
        # Tokenize names and create term-to-item mappings
        def build_term_index(schema)
          log("Building term index")

          index = Hash.new { |h, k| h[k] = [] }

          # Index elements
          schema.elements.each do |elem|
            tokens = tokenize(elem.name)
            tokens.each do |token|
              unless index[token].include?(elem.qualified_name)
                index[token] << elem.qualified_name
              end
            end
          end

          # Index complex types
          schema.complex_types.each do |type|
            tokens = tokenize(type.name)
            tokens.each do |token|
              unless index[token].include?(type.qualified_name)
                index[token] << type.qualified_name
              end
            end
          end

          # Index simple types
          schema.simple_types.each do |type|
            tokens = tokenize(type.name)
            tokens.each do |token|
              unless index[token].include?(type.qualified_name)
                index[token] << type.qualified_name
              end
            end
          end

          # Index attributes
          schema.attributes.each do |attr|
            tokens = tokenize(attr.name)
            tokens.each do |token|
              unless index[token].include?(attr.qualified_name)
                index[token] << attr.qualified_name
              end
            end
          end

          # Convert to regular hash
          index.to_h
        end

        # Tokenize a name into searchable terms
        # Supports:
        # - Full name (lowercase)
        # - CamelCase word splitting
        # - Partial matching (3+ chars)
        def tokenize(name)
          return [] unless name

          tokens = []

          # Full name lowercase
          tokens << name.downcase

          # Split CamelCase: UrbanPlanningArea => urban, planning, area
          words = name.gsub(/([A-Z])/, ' \1').split.map(&:downcase)
          tokens.concat(words)

          # Partial matching (3+ chars)
          name_lower = name.downcase
          (3..name.length).each do |len|
            tokens << name_lower[0, len]
          end

          tokens.uniq
        end

        # Build namespace-based index
        # Group items by namespace prefix
        def build_namespace_index(schema)
          log("Building namespace index")

          index = Hash.new { |h, k| h[k] = [] }

          # Group elements by prefix
          schema.elements.each do |elem|
            index[elem.prefix] << elem.qualified_name if elem.prefix
          end

          # Group complex types by prefix
          schema.complex_types.each do |type|
            index[type.prefix] << type.qualified_name if type.prefix
          end

          # Group simple types by prefix
          schema.simple_types.each do |type|
            index[type.prefix] << type.qualified_name if type.prefix
          end

          # Group attributes by prefix
          schema.attributes.each do |attr|
            index[attr.prefix] << attr.qualified_name if attr.prefix
          end

          index.to_h
        end

        # Build category-based index
        # Group items by their category (elements, complex_types, etc.)
        def build_category_index(schema)
          log("Building category index")

          {
            "elements" => schema.elements.map(&:qualified_name),
            "complex_types" => schema.complex_types.map(&:qualified_name),
            "simple_types" => schema.simple_types.map(&:qualified_name),
            "attributes" => schema.attributes.map(&:qualified_name)
          }
        end
      end
    end
  end
end
