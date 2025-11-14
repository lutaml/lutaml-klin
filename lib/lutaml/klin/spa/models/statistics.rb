# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Spa
      module Models
        # Statistics about the schema
        class Statistics < Lutaml::Model::Serializable
          attribute :total_schemas, :integer, default: -> { 0 }
          attribute :total_namespaces, :integer, default: -> { 0 }
          attribute :total_types, :integer, default: -> { 0 }
          attribute :total_elements, :integer, default: -> { 0 }
          attribute :types_by_category, :hash, default: -> { {} }
          attribute :namespaces, :string, collection: true, default: -> { [] }

          json do
            map "totalSchemas", to: :total_schemas
            map "totalNamespaces", to: :total_namespaces
            map "totalTypes", to: :total_types
            map "totalElements", to: :total_elements
            map "typesByCategory", to: :types_by_category
            map "namespaces", to: :namespaces
          end

          yaml do
            map "totalSchemas", to: :total_schemas
            map "totalNamespaces", to: :total_namespaces
            map "totalTypes", to: :total_types
            map "totalElements", to: :total_elements
            map "typesByCategory", to: :types_by_category
            map "namespaces", to: :namespaces
          end
        end
      end
    end
  end
end