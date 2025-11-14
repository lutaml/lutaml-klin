# frozen_string_literal: true

require "lutaml/model"
require_relative "schema_metadata"
require_relative "schema_info"
require_relative "element"
require_relative "complex_type"
require_relative "simple_type"
require_relative "attribute"
require_relative "cross_reference_index"
require_relative "search_index"
require_relative "statistics"

module Lutaml
  module Klin
    module Spa
      module Models
        # Top-level unified schema container
        class UnifiedSchema < Lutaml::Model::Serializable
          attribute :metadata, SchemaMetadata
          attribute :schemas, SchemaInfo, collection: true, default: -> { [] }
          attribute :elements, Element, collection: true, default: -> { [] }
          attribute :complex_types, ComplexType, collection: true,
                    default: -> { [] }
          attribute :simple_types, SimpleType, collection: true,
                    default: -> { [] }
          attribute :attributes, Attribute, collection: true, default: -> { [] }
          attribute :cross_references, CrossReferenceIndex
          attribute :search_index, SearchIndex
          attribute :statistics, Statistics

          json do
            map "metadata", to: :metadata
            map "schemas", to: :schemas
            map "elements", to: :elements
            map "complexTypes", to: :complex_types
            map "simpleTypes", to: :simple_types
            map "attributes", to: :attributes
            map "crossReferences", to: :cross_references
            map "searchIndex", to: :search_index
            map "statistics", to: :statistics
          end

          yaml do
            map "metadata", to: :metadata
            map "schemas", to: :schemas
            map "elements", to: :elements
            map "complexTypes", to: :complex_types
            map "simpleTypes", to: :simple_types
            map "attributes", to: :attributes
            map "crossReferences", to: :cross_references
            map "searchIndex", to: :search_index
            map "statistics", to: :statistics
          end
        end
      end
    end
  end
end