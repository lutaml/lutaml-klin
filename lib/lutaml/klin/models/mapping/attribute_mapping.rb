# frozen_string_literal: true

require "lutaml/model"
require_relative "transformation_info"

module Lutaml
  module Klin
    module Mapping
      # Represents the mapping of a UML attribute to an XSD element or attribute
      # with full resolution tracking and documentation
      class AttributeMapping < Lutaml::Model::Serializable
        # UML attribute information
        attribute :uml_name, :string
        attribute :uml_type, :string
        attribute :uml_documentation, :string
        attribute :uml_multiplicity, :string

        # XSD element/attribute information
        attribute :xsd_name, :string
        attribute :xsd_type, :string
        attribute :xsd_path, :string
        attribute :xsd_documentation, :string
        attribute :xsd_min_occurs, :string
        attribute :xsd_max_occurs, :string
        attribute :is_element, :boolean, default: -> { true }
        attribute :namespace, :string

        # Legacy support (deprecated)
        attribute :min_occurs, :string
        attribute :max_occurs, :string

        # Resolution tracking
        attribute :resolution_status, :string
        attribute :resolution_method, :string
        attribute :resolution_error, :string

        # Transformation tracking (XSD generation metadata)
        attribute :transformation_info, TransformationInfo

        yaml do
          map "uml_name", to: :uml_name
          map "uml_type", to: :uml_type
          map "uml_documentation", to: :uml_documentation
          map "uml_multiplicity", to: :uml_multiplicity
          map "xsd_name", to: :xsd_name
          map "xsd_type", to: :xsd_type
          map "xsd_path", to: :xsd_path
          map "xsd_documentation", to: :xsd_documentation
          map "xsd_min_occurs", to: :xsd_min_occurs
          map "xsd_max_occurs", to: :xsd_max_occurs
          map "is_element", to: :is_element
          map "min_occurs", to: :min_occurs
          map "max_occurs", to: :max_occurs
          map "namespace", to: :namespace
          map "resolution_status", to: :resolution_status
          map "resolution_method", to: :resolution_method
          map "resolution_error", to: :resolution_error
          map "transformation_info", to: :transformation_info
        end

        # Check if the attribute mapping is fully resolved
        #
        # @return [Boolean] true if resolution_status is 'resolved' or 'inferred'
        def resolved?
          %w[resolved inferred].include?(resolution_status)
        end

        # Check if the attribute mapping is unresolved
        #
        # @return [Boolean] true if resolution_status is 'unresolved'
        def unresolved?
          resolution_status == "unresolved"
        end

        # Check if the attribute mapping is partially resolved
        #
        # @return [Boolean] true if resolution_status is 'partial'
        def partial?
          resolution_status == "partial"
        end
      end
    end
  end
end
