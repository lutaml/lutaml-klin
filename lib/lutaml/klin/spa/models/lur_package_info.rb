# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Spa
      module Models
        # LUR package information for traceability
        class LurPackageInfo < Lutaml::Model::Serializable
          attribute :path, :string
          attribute :version, :string
          attribute :created_at, :string

          json do
            map "path", to: :path
            map "version", to: :version
            map "createdAt", to: :created_at
          end

          yaml do
            map "path", to: :path
            map "version", to: :version
            map "createdAt", to: :created_at
          end
        end
      end
    end
  end
end