# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Spa
      module Models
        # Cross-references for elements
        class ElementCrossReferences < Lutaml::Model::Serializable
          attribute :type_ref, :string
          attribute :substitution_group_ref, :string
          attribute :used_by, :string, collection: true, default: -> { [] }
          attribute :related_elements, :string, collection: true, default: lambda {
            []
          }

          json do
            map "typeRef", to: :type_ref
            map "substitutionGroupRef", to: :substitution_group_ref
            map "usedBy", to: :used_by
            map "relatedElements", to: :related_elements
          end

          yaml do
            map "typeRef", to: :type_ref
            map "substitutionGroupRef", to: :substitution_group_ref
            map "usedBy", to: :used_by
            map "relatedElements", to: :related_elements
          end
        end
      end
    end
  end
end
