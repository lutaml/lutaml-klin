module Lutaml
  module Klin
    module Models
      module Uml
        class Package < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :stereotype, :string
          attribute :classes, Class, collection: true, default: -> { [] }
          attribute :sub_packages, Package, collection: true, default: -> { [] }
        end
      end
    end
  end
end
