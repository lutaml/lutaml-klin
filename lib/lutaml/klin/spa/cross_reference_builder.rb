# frozen_string_literal: true

require_relative "errors"
require_relative "models/cross_reference_index"

module Lutaml
  module Klin
    module Spa
      # CrossReferenceBuilder builds comprehensive cross-reference index with
      # pre-computed relationships
      class CrossReferenceBuilder
        attr_reader :verbose

        def initialize(verbose: false)
          @verbose = verbose
        end

        # Build cross-reference index from unified schema
        # @param unified_schema [Models::UnifiedSchema] the schema to index
        # @return [Models::CrossReferenceIndex] the built index
        def build(unified_schema)
          log("Building cross-reference index")

          index = Models::CrossReferenceIndex.new

          # Build all cross-reference indexes
          index.element_to_type = build_element_type_map(
            unified_schema.elements
          )
          index.type_hierarchy = build_type_hierarchy(unified_schema)
          index.type_dependencies = build_dependency_graph(unified_schema)
          index.attribute_references = build_attribute_index(unified_schema)
          index.namespace_index = build_namespace_index(unified_schema)

          log("Cross-reference index built successfully")
          index
        rescue StandardError => e
          raise IndexBuildError,
                "Failed to build cross-reference index: #{e.message}"
        end

        private

        def log(message)
          puts(message) if verbose
        end

        # Build element to type mapping
        # Map: element qualified name => type qualified name
        def build_element_type_map(elements)
          log("Building element-to-type map")

          elements.each_with_object({}) do |elem, hash|
            hash[elem.qualified_name] = elem.type if elem.type
          end
        end

        # Build type hierarchy with inheritance information
        # Map: type name => { parents: [...], children: [...], depth: N }
        def build_type_hierarchy(schema)
          log("Building type hierarchy")

          all_types = schema.complex_types + schema.simple_types
          type_map = all_types.each_with_object({}) do |type, map|
            map[type.qualified_name] = type
          end

          all_types.each_with_object({}) do |type, hash|
            hash[type.qualified_name] = {
              "parents" => find_parent_types(type, type_map),
              "children" => find_child_types(type, all_types),
              "depth" => calculate_inheritance_depth(type, type_map)
            }
          end
        end

        # Build dependency graph
        # Map: type name => { requires: [...], required_by: [...] }
        def build_dependency_graph(schema)
          log("Building dependency graph")

          # First pass: build requires relationships
          requires_map = schema.complex_types.each_with_object({}) do |type, hash|
            hash[type.qualified_name] = extract_required_types(type)
          end

          # Second pass: build required_by relationships by inverting requires
          required_by_map = Hash.new { |h, k| h[k] = [] }
          requires_map.each do |type_name, required_types|
            required_types.each do |required_type|
              required_by_map[required_type] << type_name
            end
          end

          # Combine into final dependency graph
          all_type_names = (schema.complex_types + schema.simple_types)
                           .map(&:qualified_name)

          all_type_names.each_with_object({}) do |type_name, hash|
            hash[type_name] = {
              "requires" => requires_map[type_name] || [],
              "required_by" => required_by_map[type_name] || []
            }
          end
        end

        # Build attribute reference index
        # Map: attribute name => [list of types using it]
        def build_attribute_index(schema)
          log("Building attribute index")

          index = Hash.new { |h, k| h[k] = [] }

          schema.complex_types.each do |type|
            next unless type.attributes

            type.attributes.each do |attr|
              attr_name = if attr.is_a?(Hash)
                            attr["qualifiedName"] || attr["name"]
                          else
                            attr.qualified_name || attr.name
                          end
              index[attr_name] << type.qualified_name if attr_name
            end
          end

          index.to_h
        end

        # Build namespace index
        # Group elements and types by namespace
        def build_namespace_index(schema)
          log("Building namespace index")

          index = {}

          schema.schemas.each do |schema_info|
            ns = schema_info.namespace
            index[ns] = {
              "prefix" => schema_info.prefix,
              "schema_id" => schema_info.id,
              "elements" => find_by_namespace(schema.elements, ns)
                        .map(&:name),
              "complex_types" => find_by_namespace(schema.complex_types, ns)
                        .map(&:name),
              "simple_types" => find_by_namespace(schema.simple_types, ns)
                        .map(&:name)
            }
          end

          index
        end

        # Find parent types recursively
        def find_parent_types(type, type_map, visited = Set.new)
          parents = []
          base_type = type.base_type

          return parents unless base_type
          return parents if visited.include?(base_type)

          visited.add(base_type)
          parents << base_type

          # Recursively find parents of base type
          if type_map[base_type]
            parents.concat(
              find_parent_types(type_map[base_type], type_map, visited)
            )
          end

          parents
        end

        # Find direct child types
        def find_child_types(type, all_types)
          all_types.select do |t|
            t.base_type == type.qualified_name
          end.map(&:qualified_name)
        end

        # Calculate inheritance depth (distance from root)
        def calculate_inheritance_depth(type, type_map, visited = Set.new)
          return 0 unless type.base_type
          return 0 if visited.include?(type.qualified_name)

          visited.add(type.qualified_name)

          parent_type = type_map[type.base_type]
          return 1 unless parent_type

          1 + calculate_inheritance_depth(parent_type, type_map, visited)
        end

        # Extract all types required by a type's definition
        def extract_required_types(type)
          required = []

          # Add base type if present
          required << type.base_type if type.base_type

          # Extract types from elements
          type.elements&.each do |elem|
            elem_type = if elem.is_a?(Hash)
                          elem["type"]
                        else
                          elem.type
                        end
            required << elem_type if elem_type
          end

          # Extract types from attributes
          type.attributes&.each do |attr|
            attr_type = if attr.is_a?(Hash)
                          attr["type"]
                        else
                          attr.type
                        end
            required << attr_type if attr_type
          end

          required.compact.uniq
        end

        # Find items by namespace
        def find_by_namespace(items, namespace)
          items.select { |item| item.namespace == namespace }
        end
      end
    end
  end
end
