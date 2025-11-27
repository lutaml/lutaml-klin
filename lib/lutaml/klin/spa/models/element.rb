# frozen_string_literal: true

require "lutaml/model"
require_relative "element_cross_references"
require_relative "uml_mapping"

module Lutaml
  module Klin
    module Spa
      module Models
        # Element model with cross-references
        class Element < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :qualified_name, :string
          attribute :namespace, :string
          attribute :prefix, :string
          attribute :schema_id, :string
          attribute :type, :string
          attribute :substitution_group, :string
          attribute :abstract, :boolean, default: -> { false }
          attribute :documentation, :string
          attribute :category, :string, default: -> { "elements" }
          attribute :min_occurs, :integer, default: -> { 1 }
          attribute :max_occurs, :string, default: -> { "1" }
          attribute :cross_references, ElementCrossReferences
          attribute :uml_mapping, UmlMapping

          json do
            map "id", to: :id
            map "name", to: :name
            map "qualifiedName", to: :qualified_name
            map "namespace", to: :namespace
            map "prefix", to: :prefix
            map "schemaId", to: :schema_id
            map "type", to: :type
            map "substitutionGroup", to: :substitution_group
            map "abstract", to: :abstract
            map "documentation", to: :documentation
            map "category", to: :category
            map "minOccurs", to: :min_occurs
            map "maxOccurs", to: :max_occurs
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
            map "type", to: :type
            map "substitutionGroup", to: :substitution_group
            map "abstract", to: :abstract
            map "documentation", to: :documentation
            map "category", to: :category
            map "minOccurs", to: :min_occurs
            map "maxOccurs", to: :max_occurs
            map "crossReferences", to: :cross_references
            map "umlMapping", to: :uml_mapping
          end
        end
      end
    end
  end
end
