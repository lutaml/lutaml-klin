# frozen_string_literal: true

module Lutaml
  module Klin
    module Models
      module Uml
        class Attribute < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :type, :string
          attribute :type_id, :string
          attribute :multiplicity_min, :integer, default: -> { 1 }
          attribute :multiplicity_max, :string, default: -> { "1" }
          attribute :is_derived, :boolean, default: -> { false }
          attribute :initial_value, :string
          attribute :documentation, :string

          def required?
            multiplicity_min&.positive?
          end

          def multi_valued?
            multiplicity_max == "*" || multiplicity_max.to_i > 1
          end

          def optional?
            !required?
          end
        end
      end
    end
  end
end
