# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Spa
      module Models
        # Pre-computed cross-reference index
        class CrossReferenceIndex < Lutaml::Model::Serializable
          attribute :element_to_type, :hash, default: -> { {} }
          attribute :type_hierarchy, :hash, default: -> { {} }
          attribute :type_dependencies, :hash, default: -> { {} }
          attribute :attribute_references, :hash, default: -> { {} }
          attribute :namespace_index, :hash, default: -> { {} }

          json do
            map "elementToType", to: :element_to_type
            map "typeHierarchy", to: :type_hierarchy
            map "typeDependencies", to: :type_dependencies
            map "attributeReferences", to: :attribute_references
            map "namespaceIndex", to: :namespace_index
          end

          yaml do
            map "elementToType", to: :element_to_type
            map "typeHierarchy", to: :type_hierarchy
            map "typeDependencies", to: :type_dependencies
            map "attributeReferences", to: :attribute_references
            map "namespaceIndex", to: :namespace_index
          end
        end
      end
    end
  end
end
