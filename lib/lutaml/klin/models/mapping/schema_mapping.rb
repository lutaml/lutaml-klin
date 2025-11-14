# frozen_string_literal: true

require "lutaml/model"
require_relative "package_mapping"

module Lutaml
  module Klin
    module Mapping
      # Represents the complete mapping from UML model to XSD schemas
      # with full source tracking and resolution statistics
      class SchemaMapping < Lutaml::Model::Serializable
        # Version and metadata
        attribute :version, :string, default: -> { "1.0" }
        attribute :generated_at, :string

        # Source tracking
        attribute :source_lur, :string
        attribute :source_lxr, :string
        attribute :source_config, :string
        attribute :source_xmi, :string  # Legacy support

        # Enhanced traceability metadata (Phase 2)
        attribute :traceability, :string  # Will be serialized as Hash in YAML

        # Mappings and namespaces
        attribute :package_mappings, PackageMapping, collection: true
        attribute :namespaces, :string, collection: true

        yaml do
          map "version", to: :version
          map "generated_at", to: :generated_at
          map "source_lur", to: :source_lur
          map "source_lxr", to: :source_lxr
          map "source_config", to: :source_config
          map "source_xmi", to: :source_xmi
          map "traceability", to: :traceability
          map "package_mappings", to: :package_mappings
          map "namespaces", to: :namespaces
        end

        # Set traceability metadata
        #
        # @param metadata [Hash] Traceability information
        # @option metadata [Array<String>] :resolution_strategies Resolution strategies used
        # @option metadata [Hash] :lxr_package_info LXR package metadata
        # @option metadata [Hash] :lur_package_info LUR package metadata
        def set_traceability(metadata)
          self.traceability = metadata.to_yaml
        end

        # Get traceability metadata as hash
        #
        # @return [Hash] Traceability information
        def get_traceability
          return {} unless traceability

          YAML.safe_load(traceability, permitted_classes: [Symbol])
        rescue StandardError
          {}
        end

        # Calculate overall resolution statistics across all packages
        #
        # @return [Hash] comprehensive statistics hash
        def calculate_statistics
          return {} if package_mappings.nil? || package_mappings.empty?

          stats = {
            "total_packages" => package_mappings.size,
            "total_classes" => 0,
            "resolved_classes" => 0,
            "partial_classes" => 0,
            "unresolved_classes" => 0,
            "total_attributes" => 0,
            "resolved_attributes" => 0,
            "partial_attributes" => 0,
            "unresolved_attributes" => 0
          }

          package_mappings.each do |pkg|
            pkg_stats = pkg.calculate_statistics
            stats["total_classes"] += pkg_stats["total_classes"].to_i
            stats["resolved_classes"] += pkg_stats["resolved_classes"].to_i
            stats["partial_classes"] += pkg_stats["partial_classes"].to_i
            stats["unresolved_classes"] += pkg_stats["unresolved_classes"].to_i
            stats["total_attributes"] += pkg_stats["total_attributes"].to_i
            stats["resolved_attributes"] += pkg_stats["resolved_attributes"].to_i
            stats["partial_attributes"] += pkg_stats["partial_attributes"].to_i
            stats["unresolved_attributes"] += pkg_stats["unresolved_attributes"].to_i
          end

          stats
        end

        # Calculate the overall resolution rate
        #
        # @return [Float] resolution rate as a percentage (0-100)
        def resolution_rate
          stats = calculate_statistics
          total = stats["total_classes"].to_i
          return 0.0 if total.zero?

          resolved = stats["resolved_classes"].to_i
          (resolved.to_f / total * 100).round(2)
        end

        # Check if all mappings are fully resolved
        #
        # @return [Boolean] true if all packages are fully resolved
        def fully_resolved?
          return false if package_mappings.nil? || package_mappings.empty?

          package_mappings.all?(&:fully_resolved?)
        end

        # Get count of total packages
        #
        # @return [Integer] total number of packages
        def package_count
          package_mappings&.size || 0
        end

        # Get count of fully resolved packages
        #
        # @return [Integer] number of fully resolved packages
        def resolved_package_count
          return 0 if package_mappings.nil? || package_mappings.empty?

          package_mappings.count(&:fully_resolved?)
        end

        # Set generated timestamp to current time in ISO 8601 format
        def set_timestamp!
          self.generated_at = Time.now.utc.iso8601
        end
      end
    end
  end
end
