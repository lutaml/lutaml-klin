# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Shapechange
      # Represents metadata about a single encoding rule
      # Pure data structure - NO behavior
      class RuleDefinition < Lutaml::Model::Serializable
        attribute :id, :string              # e.g., "rule-xsd-cls-type"
        attribute :scope, :string           # "class", "property", "package", "all"
        attribute :category, :string        # "required", "optional"
        attribute :description, :string
        attribute :applies_to, :string, collection: true # ["FeatureType", "DataType"]

        yaml do
          map "id", to: :id
          map "scope", to: :scope
          map "category", to: :category
          map "description", to: :description
          map "applies_to", to: :applies_to
        end
      end
    end
  end
end
