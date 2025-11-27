# frozen_string_literal: true

require "json"

module Lutaml
  module Klin
    module Domain
      module Services
        # SpaGenerator provides pure domain logic for generating SPA data files.
        #
        # This service converts SchemaMapping objects into JSON data structures
        # optimized for client-side rendering in a Single Page Application.
        #
        # Responsibilities:
        # - Convert SchemaMapping to JSON-serializable structures
        # - Build search indexes with keywords
        # - Extract and aggregate statistics
        # - Generate navigation trees
        #
        # @example Using SpaGenerator
        #   generator = SpaGenerator.new
        #   mappings_json = generator.generate_mappings_json(schema_mapping)
        #   search_index = generator.generate_search_index(schema_mapping)
        #   statistics = generator.generate_statistics(schema_mapping)
        class SpaGenerator
          # Generate mappings JSON data structure
          #
          # Converts the complete SchemaMapping into a JSON structure
          # suitable for client-side rendering.
          #
          # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
          # @return [Hash] JSON-serializable mappings structure
          def generate_mappings_json(schema_mapping)
            {
              version: schema_mapping.version || "1.0",
              generated_at: schema_mapping.generated_at ||
                Time.now.utc.iso8601,
              packages: schema_mapping.package_mappings.map do |pkg|
                package_to_json(pkg)
              end
            }
          end

          # Generate search index for fast client-side queries
          #
          # Builds a searchable index with keywords, types, and URLs
          # for quick filtering and navigation.
          #
          # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
          # @return [Hash] Search index structure
          def generate_search_index(schema_mapping)
            index_entries = []

            schema_mapping.package_mappings.each do |pkg|
              # Add package entry
              index_entries << build_search_entry(
                pkg,
                "package",
                pkg.uml_package_name
              )

              # Add class entries
              (pkg.class_mappings || []).each do |cls|
                index_entries << build_search_entry(
                  cls,
                  "class",
                  "#{pkg.uml_package_name}::#{cls.uml_name}"
                )

                # Add attribute entries
                (cls.attribute_mappings || []).each do |attr|
                  index_entries << build_search_entry(
                    attr,
                    "attribute",
                    "#{pkg.uml_package_name}::#{cls.uml_name}::#{attr.uml_name}"
                  )
                end
              end
            end

            { index: index_entries }
          end

          # Generate statistics summary
          #
          # Extracts and aggregates statistics for dashboard display.
          #
          # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
          # @return [Hash] Statistics structure
          def generate_statistics(schema_mapping)
            stats = schema_mapping.calculate_statistics
            resolution_rate = schema_mapping.resolution_rate

            {
              summary: {
                total_packages: stats["total_packages"] || 0,
                total_classes: stats["total_classes"] || 0,
                resolved_classes: stats["resolved_classes"] || 0,
                partial_classes: stats["partial_classes"] || 0,
                unresolved_classes: stats["unresolved_classes"] || 0,
                total_attributes: stats["total_attributes"] || 0,
                resolved_attributes: stats["resolved_attributes"] || 0,
                partial_attributes: stats["partial_attributes"] || 0,
                unresolved_attributes: stats["unresolved_attributes"] || 0,
                resolution_rate: resolution_rate
              },
              packages: schema_mapping.package_mappings.map do |pkg|
                pkg_stats = pkg.calculate_statistics
                {
                  name: pkg.uml_name,
                  qualified_name: pkg.uml_package_name,
                  resolution_rate: pkg.resolution_rate,
                  statistics: pkg_stats
                }
              end
            }
          end

          private

          # Convert PackageMapping to JSON structure
          #
          # @param package_mapping [Mapping::PackageMapping] Package mapping
          # @return [Hash] JSON structure
          def package_to_json(package_mapping)
            {
              id: generate_id("pkg", package_mapping.uml_package_name),
              name: package_mapping.uml_name,
              qualified_name: package_mapping.uml_package_name,
              namespace: package_mapping.xsd_namespace,
              namespace_prefix: package_mapping.xsd_namespace_prefix,
              schema_location: package_mapping.xsd_schema_location,
              classes: (package_mapping.class_mappings || []).map do |cls|
                class_to_json(cls, package_mapping.uml_package_name)
              end
            }
          end

          # Convert ClassMapping to JSON structure
          #
          # @param class_mapping [Mapping::ClassMapping] Class mapping
          # @param package_name [String] Package qualified name
          # @return [Hash] JSON structure
          def class_to_json(class_mapping, package_name)
            {
              id: generate_id("class", class_mapping.uml_qualified_name ||
                             "#{package_name}::#{class_mapping.uml_name}"),
              uml_name: class_mapping.uml_name,
              uml_qualified_name: class_mapping.uml_qualified_name,
              uml_stereotype: class_mapping.uml_stereotype,
              uml_documentation: class_mapping.uml_documentation,
              xsd_namespace: class_mapping.xsd_namespace,
              xsd_element_name: class_mapping.xsd_element_name,
              xsd_type_name: class_mapping.xsd_type_name,
              xsd_documentation: class_mapping.xsd_documentation,
              resolution_status: class_mapping.resolution_status,
              resolution_method: class_mapping.resolution_method,
              resolution_confidence: class_mapping.resolution_confidence,
              attributes: (class_mapping.attribute_mappings || []).map do |attr|
                attribute_to_json(attr)
              end
            }
          end

          # Convert AttributeMapping to JSON structure
          #
          # @param attribute_mapping [Mapping::AttributeMapping] Attribute
          # @return [Hash] JSON structure
          def attribute_to_json(attribute_mapping)
            {
              id: generate_id("attr", attribute_mapping.uml_name),
              uml_name: attribute_mapping.uml_name,
              uml_type: attribute_mapping.uml_type,
              uml_documentation: attribute_mapping.uml_documentation,
              uml_multiplicity: attribute_mapping.uml_multiplicity,
              xsd_name: attribute_mapping.xsd_name,
              xsd_type: attribute_mapping.xsd_type,
              xsd_documentation: attribute_mapping.xsd_documentation,
              xsd_min_occurs: attribute_mapping.xsd_min_occurs,
              xsd_max_occurs: attribute_mapping.xsd_max_occurs,
              resolution_status: attribute_mapping.resolution_status,
              resolution_method: attribute_mapping.resolution_method,
              resolution_error: attribute_mapping.resolution_error
            }
          end

          # Build search index entry
          #
          # @param item [Object] The item to index (package, class, or attribute)
          # @param type [String] Item type ("package", "class", "attribute")
          # @param qualified_name [String] Fully qualified name
          # @return [Hash] Search entry
          def build_search_entry(item, type, qualified_name)
            case type
            when "package"
              {
                id: generate_id("pkg", qualified_name),
                type: type,
                title: item.uml_name,
                qualified_name: qualified_name,
                keywords: extract_keywords(item.uml_name),
                url: "#/packages/#{generate_id('pkg', qualified_name)}",
                namespace: item.xsd_namespace
              }
            when "class"
              {
                id: generate_id("class", qualified_name),
                type: type,
                title: item.uml_name,
                qualified_name: qualified_name,
                keywords: extract_keywords(item.uml_name),
                url: "#/classes/#{generate_id('class', qualified_name)}",
                resolution_status: item.resolution_status,
                stereotype: item.uml_stereotype
              }
            when "attribute"
              {
                id: generate_id("attr", qualified_name),
                type: type,
                title: item.uml_name,
                qualified_name: qualified_name,
                keywords: extract_keywords(item.uml_name),
                url: "#/attributes/#{generate_id('attr', qualified_name)}",
                resolution_status: item.resolution_status,
                uml_type: item.uml_type,
                xsd_type: item.xsd_type
              }
            end
          end

          # Extract keywords from a name for searching
          #
          # @param name [String] Name to extract keywords from
          # @return [Array<String>] Array of lowercase keywords
          def extract_keywords(name)
            return [] if name.nil? || name.empty?

            # Split on camelCase and underscore
            words = name.gsub(/([A-Z])/, ' \1')
                        .split(/[\s_:]+/)
                        .map(&:downcase)
                        .reject(&:empty?)

            words.uniq
          end

          # Generate a stable ID from a type and name
          #
          # @param type [String] Type prefix ("pkg", "class", "attr")
          # @param name [String] Full name
          # @return [String] Stable ID
          def generate_id(type, name)
            # Create a URL-safe ID
            safe_name = name.to_s
                            .gsub("::", "_")
                            .gsub(/[^a-zA-Z0-9_-]/, "_")
                            .downcase

            "#{type}_#{safe_name}"
          end
        end
      end
    end
  end
end
