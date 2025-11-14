# frozen_string_literal: true

require "lutaml/model"
require_relative "traceability"

module Lutaml
  module Klin
    module Spa
      module Models
        # Metadata and traceability for the unified schema
        class SchemaMetadata < Lutaml::Model::Serializable
          attribute :name, :string
          attribute :version, :string
          attribute :description, :string
          attribute :source_lxr, :string
          attribute :source_yaml, :string
          attribute :generated_at, :string
          attribute :generator_version, :string
          attribute :traceability, Traceability

          json do
            map "name", to: :name
            map "version", to: :version
            map "description", to: :description
            map "sourceLxr", to: :source_lxr
            map "sourceYaml", to: :source_yaml
            map "generatedAt", to: :generated_at
            map "generatorVersion", to: :generator_version
            map "traceability", to: :traceability
          end

          yaml do
            map "name", to: :name
            map "version", to: :version
            map "description", to: :description
            map "sourceLxr", to: :source_lxr
            map "sourceYaml", to: :source_yaml
            map "generatedAt", to: :generated_at
            map "generatorVersion", to: :generator_version
            map "traceability", to: :traceability
          end
        end
      end
    end
  end
end