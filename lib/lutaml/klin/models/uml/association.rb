# frozen_string_literal: true

module Lutaml
  module Klin
    module Models
      module Uml
        class Association < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :name, :string
          attribute :source_class_id, :string
          attribute :target_class_id, :string
          attribute :source_role, :string
          attribute :target_role, :string
          attribute :source_multiplicity_min, :integer
          attribute :source_multiplicity_max, :string
          attribute :target_multiplicity_min, :integer
          attribute :target_multiplicity_max, :string
          attribute :is_navigable, :boolean, default: -> { true }
          attribute :is_composition, :boolean, default: -> { false }
          attribute :is_aggregation, :boolean, default: -> { false }
          attribute :documentation, :string

          def bidirectional?
            source_role && target_role
          end

          def composition?
            is_composition
          end

          def aggregation?
            is_aggregation
          end
        end
      end
    end
  end
end
