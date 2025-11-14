# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Models
      module Xsd
        # Represents an XSD element and its mapping details
        class ElementMapping < Lutaml::Model::Serializable
          attribute :name, :string
          attribute :type, :string
          attribute :min_occurs, :string, default: -> { "1" }
          attribute :max_occurs, :string, default: -> { "1" }
          attribute :namespace, :string
          attribute :documentation, :string
        end
      end
    end
  end
end
