# frozen_string_literal: true

require "lutaml/model"
require_relative "class_mapping"

module Lutaml
  module Klin
    module Mapping
      # Represents the mapping of a UML package to XSD namespaces
      # with resolution statistics and tracking
      class PackageMapping < Lutaml::Model::Serializable
        # UML package information
        attribute :uml_name, :string
        attribute :uml_package_name, :string

        # XSD namespace information
        attribute :xsd_namespace, :string
        attribute :xsd_namespace_prefix, :string
        attribute :xsd_schema_location, :string

        # Class mappings
        attribute :class_mappings, ClassMapping, collection: true

        # Metadata
        attribute :created_at, :string

        # Resolution statistics (hash with counts)
        attribute :resolution_statistics, :string

        yaml do
          map "uml_name", to: :uml_name
          map "uml_package_name", to: :uml_package_name
          map "xsd_namespace", to: :xsd_namespace
          map "xsd_namespace_prefix", to: :xsd_namespace_prefix
          map "xsd_schema_location", to: :xsd_schema_location
          map "class_mappings", to: :class_mappings
          map "created_at", to: :created_at
          map "resolution_statistics", to: :resolution_statistics
        end

        # Calculate resolution statistics for this package
        #
        # @return [Hash] statistics hash with counts
        def calculate_statistics
          return {} if class_mappings.nil? || class_mappings.empty?

          total_classes = class_mappings.size
          # Count both "resolved" and "inferred" as successfully resolved
          resolved_classes = class_mappings.count do |cm|
            %w[resolved inferred].include?(cm.resolution_status)
          end
          partial_classes = class_mappings.count do |cm|
            cm.resolution_status == "partial"
          end
          unresolved_classes = class_mappings.count do |cm|
            cm.resolution_status == "unresolved"
          end

          total_attributes = class_mappings.sum(&:attribute_count)
          resolved_attributes = class_mappings.sum(&:resolved_attribute_count)
          partial_attributes = class_mappings.sum(&:partial_attribute_count)
          unresolved_attributes = class_mappings.sum(&:unresolved_attribute_count)

          {
            "total_classes" => total_classes,
            "resolved_classes" => resolved_classes,
            "partial_classes" => partial_classes,
            "unresolved_classes" => unresolved_classes,
            "total_attributes" => total_attributes,
            "resolved_attributes" => resolved_attributes,
            "partial_attributes" => partial_attributes,
            "unresolved_attributes" => unresolved_attributes
          }
        end

        # Calculate the resolution rate for this package
        #
        # @return [Float] resolution rate as a percentage (0-100)
        def resolution_rate
          stats = calculate_statistics
          total = stats["total_classes"].to_i
          return 0.0 if total.zero?

          resolved = stats["resolved_classes"].to_i
          (resolved.to_f / total * 100).round(2)
        end

        # Check if all classes in this package are fully resolved
        #
        # @return [Boolean] true if all classes are fully resolved
        def fully_resolved?
          return false if class_mappings.nil? || class_mappings.empty?

          class_mappings.all?(&:fully_resolved?)
        end

        # Get count of total classes
        #
        # @return [Integer] total number of classes
        def class_count
          class_mappings&.size || 0
        end

        # Get count of fully resolved classes
        #
        # @return [Integer] number of fully resolved classes
        def resolved_class_count
          return 0 if class_mappings.nil? || class_mappings.empty?

          class_mappings.count(&:fully_resolved?)
        end
      end
    end
  end
end
