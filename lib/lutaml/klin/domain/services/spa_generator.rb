# frozen_string_literal: true

require "json"
require_relative "xml_instance_generator"

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
          # suitable for client-side rendering with UML-centric navigation.
          #
          # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
          # @return [Hash] JSON-serializable mappings structure
          def generate_mappings_json(schema_mapping)
            xml_generator = XmlInstanceGenerator.new

            classes = generate_classes_json(schema_mapping)
            attributes = generate_attributes_json(schema_mapping)

            # Add XML instances to each class
            classes.each_value do |class_data|
              class_attributes = class_data[:attributes].map do |attr_id|
                attributes[attr_id]
              end

              class_data[:xml_instance] = xml_generator.generate_instance(
                class_data,
                class_attributes,
                include_comments: true,
                include_sample_values: true
              )
            end

            {
              metadata: {
                version: schema_mapping.version || "1.0",
                generated_at: schema_mapping.generated_at ||
                  Time.now.utc.iso8601,
                source_lur: schema_mapping.source_lur,
                source_lxr: schema_mapping.source_lxr,
                total_packages: schema_mapping.package_count,
                total_classes: count_total_classes(schema_mapping),
                total_attributes: count_total_attributes(schema_mapping)
              },
              packages: generate_packages_index(schema_mapping),
              classes: classes,
              attributes: attributes,
              associations: {} # TODO: Phase 2
            }
          end

          # Generate search index for fast client-side queries
          #
          # Builds a searchable index with keywords, types, and URLs
          # for quick filtering and navigation. Includes schema names
          # for multi-schema support.
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
                pkg.uml_package_name,
                nil
              )

              # Add class entries
              (pkg.class_mappings || []).each do |cls|
                # Extract schema names if multi-schema
                schema_names = if cls.schemas && !cls.schemas.empty?
                                 cls.schemas.map do |schema_yaml|
                                   data = YAML.safe_load(schema_yaml, permitted_classes: [Symbol])
                                   data["schema_name"]
                                 end
                               else
                                 []
                               end

                index_entries << build_search_entry(
                  cls,
                  "class",
                  "#{pkg.uml_package_name}::#{cls.uml_name}",
                  schema_names
                )

                # Add attribute entries (use first schema if multi-schema)
                attributes = if cls.schemas && !cls.schemas.empty?
                               data = YAML.safe_load(cls.schemas.first, permitted_classes: [Symbol])
                               data["attribute_mappings"] || []
                             else
                               cls.attribute_mappings || []
                             end

                attributes.each do |attr|
                  attr_name = attr.is_a?(Hash) ? attr["uml_name"] : attr.uml_name
                  index_entries << build_search_entry(
                    attr,
                    "attribute",
                    "#{pkg.uml_package_name}::#{cls.uml_name}::#{attr_name}",
                    schema_names
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

          # Generate packages index (ID-keyed hash)
          #
          # @param schema_mapping [Mapping::SchemaMapping] Schema mapping
          # @return [Hash] Packages indexed by ID
          def generate_packages_index(schema_mapping)
            packages = {}

            schema_mapping.package_mappings.each do |pkg|
              pkg_id = generate_package_id(pkg)
              packages[pkg_id] = {
                id: pkg_id,
                name: pkg.uml_name,
                qualified_name: pkg.uml_package_name,
                namespace: pkg.xsd_namespace,
                namespace_prefix: pkg.xsd_namespace_prefix,
                schema_location: pkg.xsd_schema_location,
                classes: (pkg.class_mappings || []).map do |cls|
                  generate_class_id(cls, pkg)
                end
              }
            end

            packages
          end

          # Generate classes JSON (ID-keyed hash with full class details)
          #
          # Supports both single-schema and multi-schema modes:
          # - Single: Traditional structure with direct XSD mapping
          # - Multi: schemas array with XSD mappings per schema
          #
          # @param schema_mapping [Mapping::SchemaMapping] Schema mapping
          # @return [Hash] Classes indexed by ID
          def generate_classes_json(schema_mapping)
            classes = {}
            xml_generator = XmlInstanceGenerator.new

            schema_mapping.package_mappings.each do |pkg|
              pkg_id = generate_package_id(pkg)

              (pkg.class_mappings || []).each do |cls|
                class_id = generate_class_id(cls, pkg)

                # Check for multi-schema data (schemas attribute populated)
                if cls.schemas && !cls.schemas.empty?
                  # Multi-schema mode: deserialize YAML schemas
                  schemas_data = cls.schemas.map do |schema_yaml|
                    YAML.safe_load(schema_yaml, permitted_classes: [Symbol])
                  end

                  classes[class_id] = {
                    id: class_id,
                    name: cls.uml_name,
                    qualified_name: cls.uml_qualified_name,
                    package_id: pkg_id,
                    stereotype: cls.uml_stereotype,
                    definition: cls.uml_documentation,
                    is_abstract: false,
                    
                    # Multi-schema structure
                    schemas: schemas_data.map do |schema|
                      {
                        schema_name: schema["schema_name"],
                        xsd_element_name: schema["xsd_element_name"],
                        xsd_type_name: schema["xsd_type_name"],
                        xsd_namespace: schema["xsd_namespace"],
                        xsd_documentation: schema["xsd_documentation"],
                        resolution_status: schema["resolution_status"],
                        resolution_method: schema["resolution_method"],
                        resolution_confidence: schema["resolution_confidence"],
                        
                        # Generate XML instance for this schema
                        xml_instance: generate_xml_for_schema(cls, schema, xml_generator),
                        
                        # Attributes specific to this schema
                        attributes: generate_attribute_ids_for_schema(
                          cls, schema, pkg
                        )
                      }
                    end
                  }
                else
                  # Single-schema mode (backward compatible)
                  classes[class_id] = {
                    id: class_id,
                    name: cls.uml_name,
                    qualified_name: cls.uml_qualified_name ||
                      "#{pkg.uml_package_name}::#{cls.uml_name}",
                    package_id: pkg_id,
                    stereotype: cls.uml_stereotype,
                    definition: cls.uml_documentation,
                    is_abstract: false,

                    # Collect attribute IDs
                    attributes: (cls.attribute_mappings || []).map do |attr|
                      generate_attribute_id(cls, attr, pkg)
                    end,

                    # TODO: Extract from UML model
                    generalizations: [],
                    specializations: [],
                    associations: [],

                    # XSD mapping data
                    xsd_element_name: cls.xsd_element_name,
                    xsd_type_name: cls.xsd_type_name,
                    xsd_namespace: cls.xsd_namespace,
                    resolution_status: cls.resolution_status,
                    resolution_method: cls.resolution_method,
                    resolution_confidence: cls.resolution_confidence
                  }
                end
              end
            end

            classes
          end

          # Generate XML instance for a specific schema variant
          #
          # @param cls [ClassMapping] Class mapping (for UML data)
          # @param schema [Hash] Schema-specific mapping data
          # @param xml_generator [XmlInstanceGenerator] XML generator
          # @return [String] XML instance
          def generate_xml_for_schema(cls, schema, xml_generator)
            # Convert schema hash to format expected by XML generator
            class_data = {
              name: cls.uml_name,
              xsd_element_name: schema["xsd_element_name"],
              xsd_type_name: schema["xsd_type_name"],
              xsd_namespace: schema["xsd_namespace"]
            }

            attributes = (schema["attribute_mappings"] || []).map do |attr|
              {
                name: attr["uml_name"],
                uml_type: attr["uml_type"],
                xsd_name: attr["xsd_name"],
                xsd_type: attr["xsd_type"],
                xsd_min_occurs: attr["xsd_min_occurs"],
                xsd_max_occurs: attr["xsd_max_occurs"]
              }
            end

            xml_generator.generate_instance(
              class_data,
              attributes,
              include_comments: true,
              include_sample_values: true
            )
          end

          # Generate attribute IDs for a specific schema variant
          #
          # @param cls [ClassMapping] Class mapping
          # @param schema [Hash] Schema-specific mapping data
          # @param pkg [PackageMapping] Package mapping
          # @return [Array<String>] Array of attribute IDs
          def generate_attribute_ids_for_schema(cls, schema, pkg)
            qualified_name = cls.uml_qualified_name ||
                             "#{pkg.uml_package_name}::#{cls.uml_name}"
            
            (schema["attribute_mappings"] || []).map do |attr|
              generate_id("attr", "#{qualified_name}::#{attr['uml_name']}")
            end
          end

          # Generate attributes JSON (ID-keyed hash with full attribute details)
          #
          # @param schema_mapping [Mapping::SchemaMapping] Schema mapping
          # @return [Hash] Attributes indexed by ID
          def generate_attributes_json(schema_mapping)
            attributes = {}

            schema_mapping.package_mappings.each do |pkg|
              (pkg.class_mappings || []).each do |cls|
                class_id = generate_class_id(cls, pkg)

                (cls.attribute_mappings || []).each do |attr|
                  attr_id = generate_attribute_id(cls, attr, pkg)

                  attributes[attr_id] = {
                    id: attr_id,
                    name: attr.uml_name,
                    class_id: class_id,

                    # UML data
                    uml_type: attr.uml_type,
                    uml_multiplicity: attr.uml_multiplicity,
                    visibility: "public", # Default
                    definition: attr.uml_documentation,
                    is_static: false, # TODO: Extract from UML model
                    is_readonly: false, # TODO: Extract from UML model

                    # XSD mapping data
                    xsd_name: attr.xsd_name,
                    xsd_type: attr.xsd_type,
                    xsd_min_occurs: attr.xsd_min_occurs,
                    xsd_max_occurs: attr.xsd_max_occurs,
                    resolution_status: attr.resolution_status,
                    resolution_method: attr.resolution_method,
                    resolution_error: attr.resolution_error
                  }
                end
              end
            end

            attributes
          end

          # Generate package ID
          #
          # @param package_mapping [Mapping::PackageMapping] Package mapping
          # @return [String] Package ID
          def generate_package_id(package_mapping)
            generate_id("pkg", package_mapping.uml_package_name)
          end

          # Generate class ID
          #
          # @param class_mapping [Mapping::ClassMapping] Class mapping
          # @param package_mapping [Mapping::PackageMapping] Package mapping
          # @return [String] Class ID
          def generate_class_id(class_mapping, package_mapping)
            qualified_name = class_mapping.uml_qualified_name ||
              "#{package_mapping.uml_package_name}::#{class_mapping.uml_name}"
            generate_id("class", qualified_name)
          end

          # Generate attribute ID
          #
          # @param class_mapping [Mapping::ClassMapping] Class mapping
          # @param attribute_mapping [Mapping::AttributeMapping] Attribute
          # @param package_mapping [Mapping::PackageMapping] Package mapping
          # @return [String] Attribute ID
          def generate_attribute_id(class_mapping, attribute_mapping,
                                     package_mapping)
            qualified_name = class_mapping.uml_qualified_name ||
              "#{package_mapping.uml_package_name}::#{class_mapping.uml_name}"
            generate_id("attr", "#{qualified_name}::#{attribute_mapping.uml_name}")
          end

          # Count total classes across all packages
          #
          # @param schema_mapping [Mapping::SchemaMapping] Schema mapping
          # @return [Integer] Total class count
          def count_total_classes(schema_mapping)
            schema_mapping.package_mappings.sum do |pkg|
              pkg.class_mappings&.size || 0
            end
          end

          # Count total attributes across all packages and classes
          #
          # @param schema_mapping [Mapping::SchemaMapping] Schema mapping
          # @return [Integer] Total attribute count
          def count_total_attributes(schema_mapping)
            schema_mapping.package_mappings.sum do |pkg|
              (pkg.class_mappings || []).sum do |cls|
                cls.attribute_mappings&.size || 0
              end
            end
          end

          # Convert PackageMapping to JSON structure (DEPRECATED)
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
          # @param schema_names [Array<String>, nil] Schema names for multi-schema
          # @return [Hash] Search entry
          def build_search_entry(item, type, qualified_name, schema_names = nil)
            base_keywords = if item.is_a?(Hash)
                              extract_keywords(item["uml_name"] || "")
                            else
                              extract_keywords(item.uml_name || "")
                            end

            # Add schema names to keywords for multi-schema search
            all_keywords = base_keywords
            if schema_names && !schema_names.empty?
              all_keywords += schema_names.map(&:downcase)
            end

            case type
            when "package"
              {
                id: generate_id("pkg", qualified_name),
                type: type,
                title: item.uml_name,
                qualified_name: qualified_name,
                keywords: all_keywords,
                url: "#/packages/#{generate_id('pkg', qualified_name)}",
                namespace: item.xsd_namespace
              }
            when "class"
              {
                id: generate_id("class", qualified_name),
                type: type,
                title: item.uml_name,
                qualified_name: qualified_name,
                keywords: all_keywords,
                url: "#/classes/#{generate_id('class', qualified_name)}",
                resolution_status: item.resolution_status,
                stereotype: item.uml_stereotype,
                schemas: schema_names
              }
            when "attribute"
              attr_name = item.is_a?(Hash) ? item["uml_name"] : item.uml_name
              uml_type = item.is_a?(Hash) ? item["uml_type"] : item.uml_type
              xsd_type = item.is_a?(Hash) ? item["xsd_type"] : item.xsd_type
              status = item.is_a?(Hash) ? item["resolution_status"] : item.resolution_status

              {
                id: generate_id("attr", qualified_name),
                type: type,
                title: attr_name,
                qualified_name: qualified_name,
                keywords: all_keywords,
                url: "#/attributes/#{generate_id('attr', qualified_name)}",
                resolution_status: status,
                uml_type: uml_type,
                xsd_type: xsd_type
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
