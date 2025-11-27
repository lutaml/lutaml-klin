# frozen_string_literal: true

require "lutaml/model"
require_relative "type_cross_references"
require_relative "uml_mapping"

module Lutaml
  module Klin
    module Spa
      module Models
        # Simple type model with cross-references
        class SimpleType < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :qualified_name, :string
          attribute :namespace, :string
          attribute :prefix, :string
          attribute :schema_id, :string
          attribute :base_type, :string
          attribute :documentation, :string
          attribute :category, :string, default: -> { "simple_types" }
          attribute :variety, :string
          attribute :restrictions, :hash, default: -> { {} }
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
            map "documentation", to: :documentation
            map "category", to: :category
            map "variety", to: :variety
            map "restrictions", to: :restrictions
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
            map "documentation", to: :documentation
            map "category", to: :category
            map "variety", to: :variety
            map "restrictions", to: :restrictions
            map "crossReferences", to: :cross_references
            map "umlMapping", to: :uml_mapping
          end
        end
      end
    end
  end
end
