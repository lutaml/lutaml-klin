require_relative "attribute"
require_relative "association"

module Lutaml
  module Klin
    module Models
      module Uml
        class Class < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :stereotype, :string
          attribute :package_id, :string
          attribute :attributes, Attribute, collection: true, default: -> { [] }
          attribute :associations, Association, collection: true, default: -> { [] }
          attribute :is_abstract, :boolean, default: -> { false }
          attribute :documentation, :string

          def feature_type?
            stereotype&.downcase == "featuretype"
          end

          def data_type?
            stereotype&.downcase == "datatype"
          end

          def code_list?
            stereotype&.downcase == "codelist"
          end

          def enumeration?
            stereotype&.downcase == "enumeration"
          end
        end
      end
    end
  end
end
