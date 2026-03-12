# frozen_string_literal: true

require "lutaml/model"
require_relative "attribute_mapping"
require_relative "transformation_info"

module Lutaml
  module Klin
    module Mapping
      # Represents the mapping of a UML class to an XSD complex type
      # with full resolution tracking and documentation
      class ClassMapping < Lutaml::Model::Serializable
        # UML class information
        attribute :uml_name, :string
        attribute :uml_package, :string
        attribute :uml_qualified_name, :string
        attribute :uml_stereotype, :string
        attribute :uml_documentation, :string
        attribute :stereotypes, :string, collection: true

        # XSD type information
        attribute :xsd_name, :string
        attribute :xsd_namespace, :string
        attribute :xsd_type, :string
        attribute :xsd_element_name, :string
        attribute :xsd_type_name, :string
        attribute :xsd_documentation, :string

        # Resolution tracking
        attribute :resolution_status, :string
        attribute :resolution_method, :string
        attribute :resolution_confidence, :float

        # Attribute mappings
        attribute :attribute_mappings, AttributeMapping, collection: true

        # Transformation tracking (XSD generation metadata)
        attribute :transformation_info, TransformationInfo

        # Multi-schema support: array of schema-specific mappings
        # Used when merging multiple schema mappings for SPA generation
        attribute :schemas, :string, collection: true, default: -> { [] }

        yaml do
          map "uml_name", to: :uml_name
          map "uml_package", to: :uml_package
          map "uml_qualified_name", to: :uml_qualified_name
          map "uml_stereotype", to: :uml_stereotype
          map "uml_documentation", to: :uml_documentation
          map "stereotypes", to: :stereotypes
          map "xsd_name", to: :xsd_name
          map "xsd_namespace", to: :xsd_namespace
          map "xsd_type", to: :xsd_type
          map "xsd_element_name", to: :xsd_element_name
          map "xsd_type_name", to: :xsd_type_name
          map "xsd_documentation", to: :xsd_documentation
          map "resolution_status", to: :resolution_status
          map "resolution_method", to: :resolution_method
          map "resolution_confidence", to: :resolution_confidence
          map "attribute_mappings", to: :attribute_mappings
          map "transformation_info", to: :transformation_info
          map "schemas", to: :schemas
        end

        # Check if the class mapping and all its attributes are fully resolved
        #
        # @return [Boolean] true if class is resolved/inferred and all attributes are resolved
        def fully_resolved?
          %w[resolved inferred].include?(resolution_status) &&
            (attribute_mappings.nil? || attribute_mappings.empty? ||
             attribute_mappings.all?(&:resolved?))
        end

        # Count the number of unresolved attributes
        #
        # @return [Integer] count of unresolved attributes
        def unresolved_attribute_count
          return 0 if attribute_mappings.nil? || attribute_mappings.empty?

          attribute_mappings.count(&:unresolved?)
        end

        # Count the number of resolved attributes
        #
        # @return [Integer] count of resolved attributes
        def resolved_attribute_count
          return 0 if attribute_mappings.nil? || attribute_mappings.empty?

          attribute_mappings.count(&:resolved?)
        end

        # Count the number of partially resolved attributes
        #
        # @return [Integer] count of partially resolved attributes
        def partial_attribute_count
          return 0 if attribute_mappings.nil? || attribute_mappings.empty?

          attribute_mappings.count(&:partial?)
        end

        # Get total attribute count
        #
        # @return [Integer] total number of attributes
        def attribute_count
          attribute_mappings&.size || 0
        end
      end
    end
  end
end
