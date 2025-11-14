# frozen_string_literal: true

require "yaml"
require "time"
require_relative "errors"
require_relative "models/unified_schema"

module Lutaml
  module Klin
    module Spa
      # DataLoader loads and merges data from LXR packages and YAML mappings
      class DataLoader
        attr_reader :verbose

        def initialize(verbose: false)
          @verbose = verbose
        end

        # Load LXR package via lutaml-xsd
        # @param lxr_path [String] path to LXR package file
        # @return [Hash] extracted LXR data
        def load_lxr(lxr_path)
          log("Loading LXR package from: #{lxr_path}")

          unless File.exist?(lxr_path)
            raise DataLoadError, "LXR package not found: #{lxr_path}"
          end

          begin
            # Load using lutaml-xsd (to be implemented with actual API)
            # repo = Lutaml::Xsd::SchemaRepository.from_package(lxr_path)

            # For now, return structured data that we'll populate
            # when integrating with lutaml-xsd
            {
              metadata: extract_lxr_metadata(lxr_path),
              namespaces: extract_namespaces_from_lxr(lxr_path),
              elements: extract_elements_from_lxr(lxr_path),
              complex_types: extract_complex_types_from_lxr(lxr_path),
              simple_types: extract_simple_types_from_lxr(lxr_path),
              attributes: extract_attributes_from_lxr(lxr_path),
              statistics: build_lxr_statistics(lxr_path)
            }
          rescue StandardError => e
            raise DataLoadError, "Failed to load LXR package: #{e.message}"
          end
        end

        # Load YAML mapping file
        # @param yaml_path [String] path to YAML mapping file
        # @return [Hash] extracted YAML data
        def load_yaml(yaml_path)
          log("Loading YAML mapping from: #{yaml_path}")

          unless File.exist?(yaml_path)
            raise DataLoadError, "YAML mapping file not found: #{yaml_path}"
          end

          begin
            content = YAML.load_file(yaml_path)

            {
              traceability: extract_traceability(content),
              source: extract_source_info(content),
              mappings: extract_uml_mappings(content)
            }
          rescue StandardError => e
            raise DataLoadError, "Failed to load YAML mapping: #{e.message}"
          end
        end

        # Merge LXR and YAML data into UnifiedSchema
        # @param lxr_data [Hash] LXR package data
        # @param yaml_data [Hash, nil] YAML mapping data (optional)
        # @return [Models::UnifiedSchema] merged unified schema
        def merge(lxr_data, yaml_data = nil)
          log("Merging LXR and YAML data into UnifiedSchema")

          begin
            schema = Models::UnifiedSchema.new

            # Build metadata
            schema.metadata = build_metadata(lxr_data, yaml_data)

            # Build schema info list
            schema.schemas = build_schema_list(lxr_data[:namespaces])

            # Enrich XSD components with UML mappings if available
            schema.elements = enrich_elements(
              lxr_data[:elements],
              yaml_data
            )
            schema.complex_types = enrich_types(
              lxr_data[:complex_types],
              yaml_data,
              "complex"
            )
            schema.simple_types = enrich_types(
              lxr_data[:simple_types],
              yaml_data,
              "simple"
            )
            schema.attributes = enrich_attributes(
              lxr_data[:attributes],
              yaml_data
            )

            # Copy statistics
            schema.statistics = lxr_data[:statistics]

            # Initialize empty indexes (to be populated by builders)
            schema.cross_references = Models::CrossReferenceIndex.new
            schema.search_index = Models::SearchIndex.new

            log("Successfully merged schema with #{schema.elements.size} " \
                "elements, #{schema.complex_types.size} complex types")

            schema
          rescue StandardError => e
            raise MergeError, "Failed to merge data: #{e.message}"
          end
        end

        private

        def log(message)
          puts(message) if verbose
        end

        # Extract metadata from LXR package
        def extract_lxr_metadata(lxr_path)
          {
            path: lxr_path,
            version: "1.0",
            created_at: Time.now.iso8601
          }
        end

        # Extract namespaces from LXR package
        def extract_namespaces_from_lxr(lxr_path)
          # Placeholder - will be implemented with lutaml-xsd integration
          []
        end

        # Extract elements from LXR package
        def extract_elements_from_lxr(lxr_path)
          # Placeholder - will be implemented with lutaml-xsd integration
          []
        end

        # Extract complex types from LXR package
        def extract_complex_types_from_lxr(lxr_path)
          # Placeholder - will be implemented with lutaml-xsd integration
          []
        end

        # Extract simple types from LXR package
        def extract_simple_types_from_lxr(lxr_path)
          # Placeholder - will be implemented with lutaml-xsd integration
          []
        end

        # Extract attributes from LXR package
        def extract_attributes_from_lxr(lxr_path)
          # Placeholder - will be implemented with lutaml-xsd integration
          []
        end

        # Build statistics from LXR data
        def build_lxr_statistics(lxr_path)
          Models::Statistics.new
        end

        # Extract traceability information from YAML
        def extract_traceability(content)
          return nil unless content.dig("schema_mapping", "traceability")

          traceability_data = content["schema_mapping"]["traceability"]
          Models::Traceability.new.tap do |t|
            t.resolution_strategies = traceability_data["resolution_strategies"] || []
            t.lxr_package_info = build_lxr_package_info(traceability_data)
            t.lur_package_info = build_lur_package_info(traceability_data)
          end
        end

        # Extract source information from YAML
        def extract_source_info(content)
          content.dig("schema_mapping", "source")
        end

        # Extract UML mappings from YAML
        def extract_uml_mappings(content)
          mappings = content["mapping"] || {}
          mappings.transform_values do |mapping_data|
            next nil unless mapping_data.is_a?(Hash)

            Models::UmlMapping.new.tap do |m|
              m.uml_class = mapping_data["uml_class"]
              m.uml_package = mapping_data["uml_package"]
              m.stereotype = mapping_data["stereotype"]
              m.resolution_strategy = mapping_data["resolution_strategy"]
            end
          end
        end

        # Build LXR package info from traceability data
        def build_lxr_package_info(traceability_data)
          return nil unless traceability_data["lxr_package"]

          lxr_data = traceability_data["lxr_package"]
          Models::LxrPackageInfo.new.tap do |info|
            info.path = lxr_data["path"]
            info.version = lxr_data["version"]
            info.created_at = lxr_data["created_at"]
          end
        end

        # Build LUR package info from traceability data
        def build_lur_package_info(traceability_data)
          return nil unless traceability_data["lur_package"]

          lur_data = traceability_data["lur_package"]
          Models::LurPackageInfo.new.tap do |info|
            info.path = lur_data["path"]
            info.version = lur_data["version"]
            info.created_at = lur_data["created_at"]
          end
        end

        # Build metadata combining LXR and YAML sources
        def build_metadata(lxr_data, yaml_data)
          Models::SchemaMetadata.new.tap do |metadata|
            metadata.name = yaml_data&.dig(:source, "name") || "Unified Schema"
            metadata.version = yaml_data&.dig(:source, "version") || "1.0"
            metadata.description = yaml_data&.dig(:source, "description") || ""
            metadata.source_lxr = lxr_data[:metadata][:path]
            metadata.source_yaml = yaml_data ? "provided" : nil
            metadata.generated_at = Time.now.iso8601
            metadata.generator_version = "1.0.0"
            metadata.traceability = yaml_data&.dig(:traceability)
          end
        end

        # Build schema list from namespaces
        def build_schema_list(namespaces)
          namespaces.map do |ns_data|
            Models::SchemaInfo.new.tap do |schema|
              schema.id = ns_data[:id] || ns_data[:prefix]
              schema.name = ns_data[:name] || ns_data[:prefix]
              schema.namespace = ns_data[:uri]
              schema.prefix = ns_data[:prefix]
              schema.description = ns_data[:description] || ""
              schema.version = ns_data[:version] || "1.0"
              schema.components = Models::ComponentCounts.new
            end
          end
        end

        # Enrich elements with UML mappings
        def enrich_elements(elements, yaml_data)
          mappings = yaml_data&.dig(:mappings) || {}

          elements.map do |elem|
            mapping = find_mapping_for_element(elem, mappings)
            elem.uml_mapping = mapping if mapping
            elem
          end
        end

        # Enrich types with UML mappings
        def enrich_types(types, yaml_data, type_kind)
          mappings = yaml_data&.dig(:mappings) || {}

          types.map do |type|
            mapping = find_mapping_for_type(type, mappings)
            type.uml_mapping = mapping if mapping
            type
          end
        end

        # Enrich attributes with UML mappings
        def enrich_attributes(attributes, yaml_data)
          mappings = yaml_data&.dig(:mappings) || {}

          attributes.map do |attr|
            mapping = find_mapping_for_attribute(attr, mappings)
            attr.uml_mapping = mapping if mapping
            attr
          end
        end

        # Find UML mapping for an element
        def find_mapping_for_element(elem, mappings)
          qualified_name = elem[:qualified_name] || "#{elem[:prefix]}:#{elem[:name]}"
          mappings[qualified_name]
        end

        # Find UML mapping for a type
        def find_mapping_for_type(type, mappings)
          qualified_name = type[:qualified_name] || "#{type[:prefix]}:#{type[:name]}"
          mappings[qualified_name]
        end

        # Find UML mapping for an attribute
        def find_mapping_for_attribute(attr, mappings)
          qualified_name = attr[:qualified_name] || "#{attr[:prefix]}:#{attr[:name]}"
          mappings[qualified_name]
        end
      end
    end
  end
end