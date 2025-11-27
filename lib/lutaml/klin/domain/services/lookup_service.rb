# frozen_string_literal: true

require_relative "../lookup_result"

module Lutaml
  module Klin
    module Domain
      module Services
        # Bidirectional lookup service for UML ↔ XSD mappings
        #
        # Provides efficient O(1) lookups in both directions by maintaining
        # bidirectional indexes. Supports fuzzy matching for partial names.
        class LookupService
          attr_reader :mapping, :index

          # Initialize the lookup service with a schema mapping
          #
          # @param schema_mapping [Lutaml::Klin::Mapping::SchemaMapping] the mapping to index
          def initialize(schema_mapping)
            @mapping = schema_mapping
            @index = build_bidirectional_index(schema_mapping)
          end

          # Find XSD mapping for a UML class
          #
          # @param uml_qualified_name [String] the qualified name of the UML class
          # @param fuzzy [Boolean] whether to enable fuzzy matching
          # @return [LookupResult] the lookup result
          def find_xsd_for_uml_class(uml_qualified_name, fuzzy: false)
            matches = []

            # Direct lookup
            if @index[:uml_class][uml_qualified_name]
              class_mapping = @index[:uml_class][uml_qualified_name]
              matches << format_class_match(class_mapping)
            elsif fuzzy
              # Fuzzy matching - find classes containing the query string
              matches = fuzzy_match_uml_class(uml_qualified_name)
            end

            LookupResult.new(
              query: uml_qualified_name,
              direction: :uml_to_xsd,
              matches: matches,
              metadata: { fuzzy: fuzzy, type: :class }
            )
          end

          # Find XSD mapping for a UML attribute
          #
          # @param uml_class_qname [String] the qualified name of the UML class
          # @param attribute_name [String] the name of the attribute
          # @param fuzzy [Boolean] whether to enable fuzzy matching
          # @return [LookupResult] the lookup result
          def find_xsd_for_uml_attribute(uml_class_qname, attribute_name,
                                         fuzzy: false)
            matches = []
            key = "#{uml_class_qname}::#{attribute_name}"

            # Direct lookup
            if @index[:uml_attr][key]
              attr_mapping = @index[:uml_attr][key]
              matches << format_attribute_match(attr_mapping, uml_class_qname)
            elsif fuzzy
              # Fuzzy matching
              matches = fuzzy_match_uml_attribute(uml_class_qname,
                                                  attribute_name)
            end

            LookupResult.new(
              query: "#{uml_class_qname}::#{attribute_name}",
              direction: :uml_to_xsd,
              matches: matches,
              metadata: { fuzzy: fuzzy, type: :attribute }
            )
          end

          # Find UML classes mapped to an XSD type
          #
          # @param xsd_type_qname [String] the qualified name of the XSD type
          # @param fuzzy [Boolean] whether to enable fuzzy matching
          # @return [LookupResult] the lookup result
          def find_uml_for_xsd_type(xsd_type_qname, fuzzy: false)
            matches = []

            # Direct lookup
            if @index[:xsd_type][xsd_type_qname]
              @index[:xsd_type][xsd_type_qname].each do |class_mapping|
                matches << format_class_match(class_mapping)
              end
            elsif fuzzy
              # Fuzzy matching
              matches = fuzzy_match_xsd_type(xsd_type_qname)
            end

            LookupResult.new(
              query: xsd_type_qname,
              direction: :xsd_to_uml,
              matches: matches,
              metadata: { fuzzy: fuzzy, type: :xsd_type }
            )
          end

          # Find UML attributes mapped to an XSD element
          #
          # @param xsd_element_qname [String] the qualified name of the XSD element
          # @param fuzzy [Boolean] whether to enable fuzzy matching
          # @return [LookupResult] the lookup result
          def find_uml_for_xsd_element(xsd_element_qname, fuzzy: false)
            matches = []

            # Direct lookup
            if @index[:xsd_element][xsd_element_qname]
              @index[:xsd_element][xsd_element_qname].each do |attr_info|
                matches << format_attribute_match(
                  attr_info[:attribute],
                  attr_info[:class_qname]
                )
              end
            elsif fuzzy
              # Fuzzy matching
              matches = fuzzy_match_xsd_element(xsd_element_qname)
            end

            LookupResult.new(
              query: xsd_element_qname,
              direction: :xsd_to_uml,
              matches: matches,
              metadata: { fuzzy: fuzzy, type: :xsd_element }
            )
          end

          # Perform automatic lookup based on identifier format
          #
          # @param identifier [String] the identifier to look up
          # @param fuzzy [Boolean] whether to enable fuzzy matching
          # @return [LookupResult] the lookup result
          def auto_lookup(identifier, fuzzy: false)
            # Try to detect the direction based on format
            if identifier.include?("::")
              # Likely UML qualified name
              if identifier.count("::") > 1
                # Has multiple :: - might be class::attribute
                parts = identifier.split("::")
                attr_name = parts.pop
                class_qname = parts.join("::")
                find_xsd_for_uml_attribute(class_qname, attr_name, fuzzy: fuzzy)
              else
                # Just a class name
                find_xsd_for_uml_class(identifier, fuzzy: fuzzy)
              end
            elsif identifier.include?(":")
              # Likely XSD qualified name (namespace:localName)
              # Try both type and element lookups
              type_result = find_uml_for_xsd_type(identifier, fuzzy: fuzzy)
              element_result = find_uml_for_xsd_element(identifier,
                                                        fuzzy: fuzzy)

              # Return the result with matches
              if type_result.found? && element_result.found?
                # Combine both results
                LookupResult.new(
                  query: identifier,
                  direction: :xsd_to_uml,
                  matches: type_result.matches + element_result.matches,
                  metadata: { fuzzy: fuzzy, type: :auto, ambiguous: true }
                )
              elsif type_result.found?
                type_result
              else
                element_result
              end
            else
              # Ambiguous - try all lookup types
              try_all_lookups(identifier, fuzzy: fuzzy)
            end
          end

          private

          # Build bidirectional indexes for efficient lookups
          #
          # @param schema_mapping [Lutaml::Klin::Mapping::SchemaMapping] the mapping to index
          # @return [Hash] the bidirectional index structure
          def build_bidirectional_index(schema_mapping)
            index = {
              uml_class: {},      # uml_qname → ClassMapping
              uml_attr: {},       # "uml_class_qname::attr_name" → AttributeMapping
              xsd_type: {},       # xsd_type_qname → [ClassMapping]
              xsd_element: {}     # xsd_element_qname → [{class_qname, attribute}]
            }

            return index if schema_mapping.package_mappings.nil?

            schema_mapping.package_mappings.each do |package|
              next if package.class_mappings.nil?

              package.class_mappings.each do |class_mapping|
                # Index UML class → XSD type
                if class_mapping.uml_qualified_name
                  index[:uml_class][class_mapping.uml_qualified_name] =
                    class_mapping
                end

                # Index XSD type → UML class (multiple classes can map to same XSD type)
                if class_mapping.xsd_type
                  index[:xsd_type][class_mapping.xsd_type] ||= []
                  index[:xsd_type][class_mapping.xsd_type] << class_mapping
                end

                # Index attributes
                next if class_mapping.attribute_mappings.nil?

                class_mapping.attribute_mappings.each do |attr|
                  # Index UML attribute
                  if class_mapping.uml_qualified_name && attr.uml_name
                    key = "#{class_mapping.uml_qualified_name}::#{attr.uml_name}"
                    index[:uml_attr][key] = attr
                  end

                  # Index XSD element → UML attribute
                  next unless attr.xsd_name

                  xsd_key = build_xsd_element_key(attr)
                  index[:xsd_element][xsd_key] ||= []
                  index[:xsd_element][xsd_key] << {
                    class_qname: class_mapping.uml_qualified_name,
                    attribute: attr
                  }
                end
              end
            end

            index
          end

          # Build XSD element key with namespace if present
          #
          # @param attr [Lutaml::Klin::Mapping::AttributeMapping] the attribute mapping
          # @return [String] the XSD element key
          def build_xsd_element_key(attr)
            if attr.namespace && !attr.namespace.empty?
              "#{attr.namespace}:#{attr.xsd_name}"
            else
              attr.xsd_name
            end
          end

          # Format a class mapping match
          #
          # @param class_mapping [Lutaml::Klin::Mapping::ClassMapping] the class mapping
          # @return [Hash] formatted match information
          def format_class_match(class_mapping)
            {
              uml_class: class_mapping.uml_qualified_name,
              uml_name: class_mapping.uml_name,
              uml_package: class_mapping.uml_package,
              uml_stereotype: class_mapping.uml_stereotype,
              xsd_element: class_mapping.xsd_element_name,
              xsd_type: class_mapping.xsd_type,
              xsd_type_name: class_mapping.xsd_type_name,
              xsd_namespace: class_mapping.xsd_namespace,
              resolution_status: class_mapping.resolution_status,
              resolution_method: class_mapping.resolution_method
            }
          end

          # Format an attribute mapping match
          #
          # @param attr_mapping [Lutaml::Klin::Mapping::AttributeMapping] the attribute mapping
          # @param class_qname [String] the qualified name of the containing class
          # @return [Hash] formatted match information
          def format_attribute_match(attr_mapping, class_qname)
            {
              uml_class: class_qname,
              uml_attribute: attr_mapping.uml_name,
              uml_type: attr_mapping.uml_type,
              uml_multiplicity: attr_mapping.uml_multiplicity,
              xsd_name: attr_mapping.xsd_name,
              xsd_type: attr_mapping.xsd_type,
              xsd_path: attr_mapping.xsd_path,
              xsd_namespace: attr_mapping.namespace,
              is_element: attr_mapping.is_element,
              min_occurs: attr_mapping.xsd_min_occurs,
              max_occurs: attr_mapping.xsd_max_occurs,
              resolution_status: attr_mapping.resolution_status
            }
          end

          # Fuzzy match UML class names
          #
          # @param query [String] the query string
          # @return [Array<Hash>] array of matches
          def fuzzy_match_uml_class(query)
            matches = []
            query_lower = query.downcase

            @index[:uml_class].each do |qname, class_mapping|
              next unless qname.downcase.include?(query_lower)

              matches << format_class_match(class_mapping).merge(
                match_quality: calculate_match_quality(query_lower,
                                                       qname.downcase)
              )
            end

            # Sort by match quality
            matches.sort_by { |m| -m[:match_quality] }
          end

          # Fuzzy match UML attributes
          #
          # @param class_qname [String] the class qualified name
          # @param attr_name [String] the attribute name
          # @return [Array<Hash>] array of matches
          def fuzzy_match_uml_attribute(class_qname, attr_name)
            matches = []
            class_lower = class_qname.downcase
            attr_lower = attr_name.downcase

            @index[:uml_attr].each do |key, attr_mapping|
              unless key.downcase.include?(class_lower) && key.downcase.include?(attr_lower)
                next
              end

              parts = key.split("::")
              match_class_qname = parts[0..-2].join("::")
              matches << format_attribute_match(attr_mapping,
                                                match_class_qname).merge(
                                                  match_quality: calculate_match_quality(attr_lower,
                                                                                         key.downcase)
                                                )
            end

            matches.sort_by { |m| -m[:match_quality] }
          end

          # Fuzzy match XSD types
          #
          # @param query [String] the query string
          # @return [Array<Hash>] array of matches
          def fuzzy_match_xsd_type(query)
            matches = []
            query_lower = query.downcase

            @index[:xsd_type].each do |type_qname, class_mappings|
              next unless type_qname.downcase.include?(query_lower)

              quality = calculate_match_quality(query_lower,
                                                type_qname.downcase)
              class_mappings.each do |class_mapping|
                matches << format_class_match(class_mapping).merge(
                  match_quality: quality
                )
              end
            end

            matches.sort_by { |m| -m[:match_quality] }
          end

          # Fuzzy match XSD elements
          #
          # @param query [String] the query string
          # @return [Array<Hash>] array of matches
          def fuzzy_match_xsd_element(query)
            matches = []
            query_lower = query.downcase

            @index[:xsd_element].each do |element_qname, attr_infos|
              next unless element_qname.downcase.include?(query_lower)

              quality = calculate_match_quality(query_lower,
                                                element_qname.downcase)
              attr_infos.each do |attr_info|
                matches << format_attribute_match(
                  attr_info[:attribute],
                  attr_info[:class_qname]
                ).merge(match_quality: quality)
              end
            end

            matches.sort_by { |m| -m[:match_quality] }
          end

          # Calculate match quality for fuzzy matching
          #
          # @param query [String] the query string (lowercase)
          # @param target [String] the target string (lowercase)
          # @return [Float] match quality score (0.0 to 1.0)
          def calculate_match_quality(query, target)
            # Exact match
            return 1.0 if query == target

            # Starts with query
            return 0.9 if target.start_with?(query)

            # Ends with query
            return 0.8 if target.end_with?(query)

            # Contains query - score based on position
            index = target.index(query)
            return 0.0 unless index

            # Earlier matches score higher
            0.7 * (1.0 - (index.to_f / target.length))
          end

          # Try all lookup types
          #
          # @param identifier [String] the identifier to look up
          # @param fuzzy [Boolean] whether to enable fuzzy matching
          # @return [LookupResult] combined lookup result
          def try_all_lookups(identifier, fuzzy: false)
            all_matches = []

            # Try UML class
            result = find_xsd_for_uml_class(identifier, fuzzy: fuzzy)
            all_matches.concat(result.matches) if result.found?

            # Try XSD type
            result = find_uml_for_xsd_type(identifier, fuzzy: fuzzy)
            all_matches.concat(result.matches) if result.found?

            # Try XSD element
            result = find_uml_for_xsd_element(identifier, fuzzy: fuzzy)
            all_matches.concat(result.matches) if result.found?

            LookupResult.new(
              query: identifier,
              direction: :auto,
              matches: all_matches,
              metadata: { fuzzy: fuzzy, type: :auto }
            )
          end
        end
      end
    end
  end
end
