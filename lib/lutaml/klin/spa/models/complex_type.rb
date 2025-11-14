# frozen_string_literal: true

require "lutaml/model"
require_relative "type_cross_references"
require_relative "uml_mapping"

module Lutaml
  module Klin
    module Spa
      module Models
        # Complex type model with cross-references
        class ComplexType < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :qualified_name, :string
          attribute :namespace, :string
          attribute :prefix, :string
          attribute :schema_id, :string
          attribute :base_type, :string
          attribute :abstract, :boolean, default: -> { false }
          attribute :documentation, :string
          attribute :category, :string, default: -> { "complex_types" }
          attribute :content_model, :string
          attribute :attributes, :hash, collection: true, default: -> { [] }
          attribute :elements, :hash, collection: true, default: -> { [] }
          attribute :cross_references, TypeCrossReferences
          attribute :uml_mapping, UmlMapping

          json do
            map "id", to: :id
            map "name", to: :name
            map "qualifiedName", to: :qualified_name
            map "namespace", to: :namespace
            map "prefix", to: :prefix
            map "schemaId", to: :schema_id
            map "baseType", to: :base_type
            map "abstract", to: :abstract
            map "documentation", to: :documentation
            map "category", to: :category
            map "contentModel", to: :content_model
            map "attributes", to: :attributes
            map "elements", to: :elements
            map "crossReferences", to: :cross_references
            map "umlMapping", to: :uml_mapping
          end

          yaml do
            map "id", to: :id
            map "name", to: :name
            map "qualifiedName", to: :qualified_name
            map "namespace", to: :namespace
            map "prefix", to: :prefix
            map "schemaId", to: :schema_id
            map "baseType", to: :base_type
            map "abstract", to: :abstract
            map "documentation", to: :documentation
            map "category", to: :category
            map "contentModel", to: :content_model
            map "attributes", to: :attributes
            map "elements", to: :elements
            map "crossReferences", to: :cross_references
            map "umlMapping", to: :uml_mapping
          end
        end
      end
    end
  end
end