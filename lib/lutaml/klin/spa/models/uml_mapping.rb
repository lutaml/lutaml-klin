# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Spa
      module Models
        # UML mapping information for schema components
        class UmlMapping < Lutaml::Model::Serializable
          attribute :uml_class, :string
          attribute :uml_package, :string
          attribute :stereotype, :string
          attribute :resolution_strategy, :string

          json do
            map "umlClass", to: :uml_class
            map "umlPackage", to: :uml_package
            map "stereotype", to: :stereotype
            map "resolutionStrategy", to: :resolution_strategy
          end

          yaml do
            map "umlClass", to: :uml_class
            map "umlPackage", to: :uml_package
            map "stereotype", to: :stereotype
            map "resolutionStrategy", to: :resolution_strategy
          end
        end
      end
    end
  end
end
