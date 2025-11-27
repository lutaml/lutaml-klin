# frozen_string_literal: true

require "lutaml/model"
require_relative "element_mapping"

module Lutaml
  module Klin
    module Models
      module Xsd
        # Represents an XSD complex type and its structure
        class ComplexTypeMapping < Lutaml::Model::Serializable
          attribute :name, :string
          attribute :abstract, :boolean, default: -> { false }
          attribute :mixed, :boolean, default: -> { false }
          attribute :base_type, :string
          attribute :extension, :boolean, default: -> { false }
          attribute :elements, ElementMapping, collection: true, default: lambda {
            []
          }
          attribute :attributes, ElementMapping, collection: true, default: lambda {
            []
          }
          attribute :namespace, :string
          attribute :documentation, :string
        end
      end
    end
  end
end
