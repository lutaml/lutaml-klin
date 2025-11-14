# frozen_string_literal: true

require "lutaml/model"
require_relative "component_counts"

module Lutaml
  module Klin
    module Spa
      module Models
        # Individual schema information
        class SchemaInfo < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :namespace, :string
          attribute :prefix, :string
          attribute :description, :string
          attribute :version, :string
          attribute :components, ComponentCounts

          json do
            map "id", to: :id
            map "name", to: :name
            map "namespace", to: :namespace
            map "prefix", to: :prefix
            map "description", to: :description
            map "version", to: :version
            map "components", to: :components
          end

          yaml do
            map "id", to: :id
            map "name", to: :name
            map "namespace", to: :namespace
            map "prefix", to: :prefix
            map "description", to: :description
            map "version", to: :version
            map "components", to: :components
          end
        end
      end
    end
  end
end