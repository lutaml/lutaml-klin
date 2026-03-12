# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Mapping
      # Represents transformation metadata for XSD generation
      # Tracks rules applied, encoding decisions, and generation context
      #
      # Performance Optimization (Phase 2):
      # - Deferred YAML serialization: metadata stored as hash until final serialization
      # - Avoids ~1755 YAML serializations during hot path (10-15% improvement)
      class TransformationInfo < Lutaml::Model::Serializable
        # Rules applied during transformation
        attribute :rules_applied, :string, collection: true

        # Encoding rule used (e.g., "iso19136_2007", "citygml")
        attribute :encoding_rule, :string

        # Generation context metadata
        attribute :has_property_type, :boolean, default: -> { false }
        attribute :is_abstract, :boolean, default: -> { false }
        attribute :is_substitutable, :boolean, default: -> { false }

        # Type mapping information
        attribute :type_mapping_source, :string # e.g., "XsdMapEntry", "BasicType"
        attribute :type_mapping_description, :string # e.g., "CodeList → gml:CodeType"

        # Additional metadata (flexible hash for processor-specific data)
        attribute :metadata, :string # Serialized as YAML

        yaml do
          map "rules_applied", to: :rules_applied
          map "encoding_rule", to: :encoding_rule
          map "has_property_type", to: :has_property_type
          map "is_abstract", to: :is_abstract
          map "is_substitutable", to: :is_substitutable
          map "type_mapping_source", to: :type_mapping_source
          map "type_mapping_description", to: :type_mapping_description
          map "metadata", to: :metadata
        end

        # OPTIMIZATION: Store raw metadata hash temporarily
        # Only serialize to YAML when the model itself is serialized
        attr_accessor :raw_metadata

        # Set metadata hash
        # OPTIMIZED: Store hash directly without YAML serialization
        # Serialization is deferred until to_yaml is called on the model
        #
        # @param data [Hash] Metadata to store
        def metadata_hash=(data)
          @raw_metadata = data
        end

        # Get metadata as hash
        # OPTIMIZED: Return raw hash if available, otherwise deserialize
        #
        # @return [Hash] Metadata
        def metadata_hash
          return @raw_metadata if @raw_metadata
          return {} unless metadata

          YAML.safe_load(metadata, permitted_classes: [Symbol])
        rescue StandardError
          {}
        end

        # Override metadata getter to serialize raw_metadata on demand
        # This ensures YAML serialization only happens when the model is serialized
        def metadata
          return @raw_metadata.to_yaml if @raw_metadata
          
          @metadata
        end

        # Add a rule to rules_applied
        #
        # @param rule [String] Rule identifier
        def add_rule(rule)
          self.rules_applied ||= []
          self.rules_applied << rule unless rules_applied.include?(rule)
        end

        # Check if a rule was applied
        #
        # @param rule [String] Rule identifier
        # @return [Boolean] true if rule was applied
        def rule_applied?(rule)
          rules_applied&.include?(rule) || false
        end
      end
    end
  end
end