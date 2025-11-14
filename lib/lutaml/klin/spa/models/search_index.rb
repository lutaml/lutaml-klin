# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Spa
      module Models
        # Search index structure for fast text-based search
        class SearchIndex < Lutaml::Model::Serializable
          attribute :terms, :hash, default: -> { {} }
          attribute :by_namespace, :hash, default: -> { {} }
          attribute :by_category, :hash, default: -> { {} }

          json do
            map "terms", to: :terms
            map "byNamespace", to: :by_namespace
            map "byCategory", to: :by_category
          end

          yaml do
            map "terms", to: :terms
            map "byNamespace", to: :by_namespace
            map "byCategory", to: :by_category
          end
        end
      end
    end
  end
end