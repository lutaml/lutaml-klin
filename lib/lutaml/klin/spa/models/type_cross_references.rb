# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Spa
      module Models
        # Cross-references for types
        class TypeCrossReferences < Lutaml::Model::Serializable
          attribute :base_type, :string
          attribute :derived_types, :string, collection: true, default: lambda {
            []
          }
          attribute :used_by_elements, :string, collection: true, default: lambda {
            []
          }
          attribute :used_by_types, :string, collection: true, default: lambda {
            []
          }
          attribute :required_types, :string, collection: true, default: lambda {
            []
          }

          json do
            map "baseType", to: :base_type
            map "derivedTypes", to: :derived_types
            map "usedByElements", to: :used_by_elements
            map "usedByTypes", to: :used_by_types
            map "requiredTypes", to: :required_types
          end

          yaml do
            map "baseType", to: :base_type
            map "derivedTypes", to: :derived_types
            map "usedByElements", to: :used_by_elements
            map "usedByTypes", to: :used_by_types
            map "requiredTypes", to: :required_types
          end
        end
      end
    end
  end
end
