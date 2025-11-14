# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Shapechange
      class XmlNamespace < Lutaml::Model::Serializable
        attribute :nsabr, :string
        attribute :ns, :string
        attribute :location, :string

        xml do
          root "XmlNamespace"
          map_attribute "nsabr", to: :nsabr
          map_attribute "ns", to: :ns
          map_attribute "location", to: :location
        end
      end
    end
  end
end
