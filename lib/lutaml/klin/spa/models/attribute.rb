# frozen_string_literal: true

require "lutaml/model"
require_relative "uml_mapping"

module Lutaml
  module Klin
    module Spa
      module Models
        # Attribute model
        class Attribute < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :qualified_name, :string
          attribute :namespace, :string
          attribute :prefix, :string
          attribute :schema_id, :string
          attribute :type, :string
          attribute :documentation, :string
          attribute :category, :string, default: -> { "attributes" }
          attribute :use, :string, default: -> { "optional" }
          attribute :default_value, :string
          attribute :fixed_value, :string
          attribute :uml_mapping, UmlMapping

          json do
            map "id", to: :id
            map "name", to: :name
            map "qualifiedName", to: :qualified_name
            map "namespace", to: :namespace
            map "prefix", to: :prefix
            map "schemaId", to: :schema_id
            map "type", to: :type
            map "documentation", to: :documentation
            map "category", to: :category
            map "use", to: :use
            map "defaultValue", to: :default_value
            map "fixedValue", to: :fixed_value
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
            map "documentation", to: :documentation
            map "category", to: :category
            map "use", to: :use
            map "defaultValue", to: :default_value
            map "fixedValue", to: :fixed_value
            map "umlMapping", to: :uml_mapping
          end
        end
      end
    end
  end
end
