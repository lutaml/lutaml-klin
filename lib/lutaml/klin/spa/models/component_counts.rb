# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Spa
      module Models
        # Component counts for a schema
        class ComponentCounts < Lutaml::Model::Serializable
          attribute :elements, :integer, default: -> { 0 }
          attribute :complex_types, :integer, default: -> { 0 }
          attribute :simple_types, :integer, default: -> { 0 }
          attribute :attributes, :integer, default: -> { 0 }

          json do
            map "elements", to: :elements
            map "complexTypes", to: :complex_types
            map "simpleTypes", to: :simple_types
            map "attributes", to: :attributes
          end

          yaml do
            map "elements", to: :elements
            map "complexTypes", to: :complex_types
            map "simpleTypes", to: :simple_types
            map "attributes", to: :attributes
          end
        end
      end
    end
  end
end
