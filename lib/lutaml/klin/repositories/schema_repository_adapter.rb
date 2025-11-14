# frozen_string_literal: true

require "lutaml/xsd"

module Lutaml
  module Klin
    module Repositories
      # Adapter for Lutaml::Xsd::SchemaRepository
      #
      # Provides a thin wrapper around the SchemaRepository API from the
      # lutaml-xsd gem, adapting it for lutaml-klin's needs. This adapter is
      # purely for delegation - no business logic should be added here.
      #
      # @example Load and query XSD repository
      #   adapter = SchemaRepositoryAdapter.new("schemas.lxr")
      #   result = adapter.resolve_type("gml:CodeType")
      #   type = adapter.find_type("BuildingType", namespace: "http://...")
      class SchemaRepositoryAdapter
        # @return [Lutaml::Xsd::SchemaRepository] the underlying repository
        attr_reader :repository

        # Initialize adapter with an LXR package
        #
        # @param lxr_path [String] Path to .lxr package file
        # @raise [Errno::ENOENT] if LXR file not found
        # @raise [RuntimeError] if LXR package is invalid
        def initialize(lxr_path)
          @repository = Lutaml::Xsd::SchemaRepository.from_package(lxr_path)
        rescue Errno::ENOENT => e
          raise Errno::ENOENT,
                "LXR package not found: #{lxr_path} - #{e.message}"
        rescue StandardError => e
          raise "Failed to load LXR package '#{lxr_path}': #{e.message}"
        end

        # Resolve XSD type by qualified name
        #
        # Supports multiple name formats:
        # - Prefixed: "gml:CodeType"
        # - Clark notation: "{http://www.opengis.net/gml/3.2}CodeType"
        # - Unprefixed: "CodeType" (uses default namespace)
        #
        # @param qualified_name [String] Qualified type name
        # @return [Lutaml::Xsd::TypeResolutionResult] resolution result
        #   containing:
        #   - resolved: Boolean indicating success
        #   - qname: Original qualified name
        #   - namespace: Resolved namespace URI
        #   - local_name: Local name without prefix
        #   - definition: The type definition object (if found)
        #   - schema_file: Source XSD file
        #   - error_message: Error message (if not resolved)
        def resolve_type(qualified_name)
          repository.find_type(qualified_name)
        rescue StandardError => e
          raise "Error resolving type '#{qualified_name}': #{e.message}"
        end

        # Find type by name and optional namespace
        #
        # @param name [String] Type name (local name without prefix)
        # @param namespace [String, nil] Optional namespace URI to filter by
        # @return [Lutaml::Xsd::ComplexType, Lutaml::Xsd::SimpleType, nil]
        #   the type definition or nil if not found
        def find_type(name, namespace: nil)
          if namespace
            repository.find_type(name, namespace: namespace)
          else
            repository.find_type(name)
          end
        rescue StandardError => e
          raise "Error finding type '#{name}': #{e.message}"
        end

        # Get repository statistics
        #
        # @return [Hash] statistics including:
        #   - :total_schemas - number of loaded schemas
        #   - :total_types - number of type definitions
        #   - :total_elements - number of elements
        #   - :namespaces - list of namespaces
        def statistics
          repository.statistics
        rescue StandardError => e
          raise "Error retrieving repository statistics: #{e.message}"
        end
      end
    end
  end
end