# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Generates basic types with facet restrictions
          # Implements rule-xsd-cls-basictype and rule-xsd-cls-basictype-list
          # Based on pAnonymousBasicType() in XsdDocument.java lines 1438-1631
          #
          # Basic types may be restricted with facets such as:
          # - length/maxLength for string types
          # - totalDigits for numeric types
          # - pattern for regex restrictions
          # - minInclusive/maxInclusive for numeric ranges
          class BasicTypeProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-cls-basictype"

            # Facet support matrix for different base types
            NUMERIC_TYPES = %w[
              integer positiveInteger negativeInteger
              nonNegativeInteger nonPositiveInteger
              long unsignedLong
              int unsignedInt
              short unsignedShort
              byte unsignedByte
              decimal float double
            ].freeze

            STRING_TYPES = %w[string normalizedString token].freeze

            protected

            def apply_rule(uml_class, context)
              xsd_doc = context[:xsd_document]

              # Check for list-based basic type first
              if list_based_type?(uml_class)
                create_list_based_type(uml_class, xsd_doc, context)
                return
              end

              # Regular faceted basic type
              create_faceted_basic_type(uml_class, xsd_doc, context)
            end

            private

            def list_based_type?(uml_class)
              # Check if rule-xsd-cls-basictype-list applies
              return false unless rule_checker.applies?(
                "rule-xsd-cls-basictype-list",
                uml_class
              )

              # Must have exactly one property with max multiplicity > 1
              return false unless uml_class.respond_to?(:attributes)
              return false unless uml_class.attributes&.size == 1

              attr = uml_class.attributes.first
              return false unless attr.respond_to?(:max_occurs)

              # Check if max_occurs > 1 (handle both integer and string "*")
              max = attr.max_occurs
              if max == "*"
                true
              else
                max.to_i > 1
              end
            end

            def create_list_based_type(uml_class, xsd_doc, context)
              # Get the single property
              property = uml_class.attributes.first
              item_type = resolve_item_type(property, context)

              # Create simpleType
              simple_type = xsd_doc.add_simple_type(
                name: type_name(uml_class, context)
              )

              # Determine if we need length restrictions
              min_occurs = property.min_occurs.to_i
              max_occurs = property.max_occurs
              max_occurs_int = max_occurs == "*" ? Float::INFINITY : max_occurs.to_i

              if min_occurs.zero? && max_occurs_int == Float::INFINITY
                # No length restriction - just list
                xsd_doc.add_list(simple_type, item_type: item_type)
              else
                # Add restriction with length constraints
                restriction = xsd_doc.add_restriction(simple_type)

                # Add nested simpleType with list
                list_simple_type = xsd_doc.add_simple_type_child(restriction)
                xsd_doc.add_list(list_simple_type, item_type: item_type)

                # Add length facets
                if min_occurs == max_occurs_int
                  xsd_doc.add_facet(restriction, "length", min_occurs.to_s)
                else
                  if min_occurs.positive?
                    xsd_doc.add_facet(restriction, "minLength", min_occurs.to_s)
                  end
                  if max_occurs_int != Float::INFINITY
                    xsd_doc.add_facet(restriction, "maxLength",
                                      max_occurs_int.to_s)
                  end
                end
              end
            end

            def create_faceted_basic_type(uml_class, xsd_doc, context)
              # Read tagged values
              base = read_tagged_value(uml_class, "base")
              length = read_tagged_value(uml_class, "length") ||
                       read_tagged_value(uml_class, "maxLength")
              pattern = read_tagged_value(uml_class, "pattern")
              min_value = read_tagged_value(uml_class, "rangeMinimum")
              max_value = read_tagged_value(uml_class, "rangeMaximum")

              # Determine base type and content type
              base_type, type_content = determine_base_type(
                uml_class,
                base,
                context
              )

              if base_type.nil? || base_type.empty?
                puts "Warning: No base type found for basic type #{uml_class.name}"
                return
              end

              # Create appropriate type structure
              case type_content
              when "simple/simple"
                create_simple_type_with_facets(
                  uml_class, xsd_doc, context,
                  base_type, length, pattern, min_value, max_value
                )
              when "complex/simple"
                create_complex_simple_content_type(
                  uml_class, xsd_doc, context,
                  base_type, length, pattern, min_value, max_value
                )
              else
                create_complex_type_with_extension(
                  uml_class, xsd_doc, context, base_type
                )
              end
            end

            def create_simple_type_with_facets(uml_class, xsd_doc, context,
                                               base_type, length, pattern,
                                               min_value, max_value)
              simple_type = xsd_doc.add_simple_type(
                name: type_name(uml_class, context)
              )

              restriction = xsd_doc.add_restriction(
                simple_type,
                base: base_type
              )

              add_facets(restriction, xsd_doc, base_type, length, pattern,
                         min_value, max_value)
            end

            def create_complex_simple_content_type(uml_class, xsd_doc, context,
                                                   base_type, length, pattern,
                                                   min_value, max_value)
              complex_type = xsd_doc.add_complex_type(
                name: type_name(uml_class, context)
              )

              simple_content = xsd_doc.add_simple_content(complex_type)
              restriction = xsd_doc.add_restriction(
                simple_content,
                base: base_type
              )

              add_facets(restriction, xsd_doc, base_type, length, pattern,
                         min_value, max_value)
            end

            def create_complex_type_with_extension(uml_class, xsd_doc, context,
                                                   base_type)
              complex_type = xsd_doc.add_complex_type(
                name: type_name(uml_class, context)
              )

              complex_content = xsd_doc.add_complex_content(complex_type)
              xsd_doc.add_extension(complex_content, base: base_type)
            end

            def add_facets(restriction, xsd_doc, base_type, length, pattern,
                           min_value, max_value)
              # Add totalDigits for numeric types with length
              if facet_supported?("totalDigits", base_type) && length
                xsd_doc.add_facet(restriction, "totalDigits", length)
              end

              # Add maxLength for string types with length
              if facet_supported?("maxLength", base_type) && length
                xsd_doc.add_facet(restriction, "maxLength", length)
              end

              # Add pattern restriction
              if facet_supported?("pattern", base_type) && pattern
                xsd_doc.add_facet(restriction, "pattern", pattern)
              end

              # Add min/max inclusive for numeric ranges
              if facet_supported?("minInclusive", base_type) && min_value
                xsd_doc.add_facet(restriction, "minInclusive", min_value)
              end

              if facet_supported?("maxInclusive", base_type) && max_value
                xsd_doc.add_facet(restriction, "maxInclusive", max_value)
              end
            end

            def determine_base_type(uml_class, base_tagged_value, context)
              base_type = base_tagged_value
              type_content = "simple/simple"

              # Always check supertypes for type content determination
              # even if base is specified via tagged value
              if uml_class.respond_to?(:generalizations) && uml_class.generalizations
                uml_class.generalizations.each do |gen|
                  supertype = gen.general
                  next unless supertype

                  # Check for map entry to determine type content
                  map_entry = find_map_entry(supertype.name, context)
                  next unless map_entry

                  # Use base from map entry if not specified
                  base_type ||= map_entry[:type]
                  # Always use content from map entry
                  type_content = map_entry[:content] || "simple/simple"
                  break
                end
              end

              # If base is still not specified, search supertypes
              if base_type.nil? || base_type.empty?
                base_type, type_content = find_base_from_supertypes(
                  uml_class,
                  context
                )
              end

              [base_type, type_content]
            end

            def find_base_from_supertypes(uml_class, context)
              unless uml_class.respond_to?(:generalizations)
                return [nil,
                        "simple/simple"]
              end
              return [nil, "simple/simple"] unless uml_class.generalizations

              base_type = nil
              type_content = "simple/simple"

              uml_class.generalizations.each do |gen|
                supertype = gen.general
                next unless supertype

                # Check for map entry in config
                map_entry = find_map_entry(supertype.name, context)
                if map_entry
                  base_type = map_entry[:type]
                  type_content = map_entry[:content] || "simple/simple"
                  break
                end

                # Use qname as fallback (assume simple if no map entry)
                unless base_type
                  base_type = "#{supertype.name}Type"
                  type_content = "simple/simple"
                end
              end

              [base_type, type_content]
            end

            def find_map_entry(type_name, context)
              # Look for map entries in config
              map_entries = context[:config]&.dig("mapEntries") || {}
              map_entries[type_name]
            end

            def resolve_item_type(property, context)
              # Get the type of the property
              type_name = property.type&.name
              return "string" unless type_name

              # Check for map entry
              map_entry = find_map_entry(type_name, context)
              return map_entry[:type] if map_entry

              # Default mapping for common types
              case type_name
              when "Real", "Double"
                "double"
              when "Integer"
                "integer"
              when "String"
                "string"
              when "Boolean"
                "boolean"
              else
                "#{type_name}Type"
              end
            end

            def facet_supported?(facet, base_type)
              # Remove namespace prefix if present
              base = base_type.split(":").last

              case facet
              when "minInclusive", "maxInclusive", "minExclusive", "maxExclusive"
                NUMERIC_TYPES.include?(base)
              when "totalDigits"
                NUMERIC_TYPES.include?(base)
              when "maxLength", "minLength", "length"
                STRING_TYPES.include?(base) || base.include?("string")
              when "pattern"
                # Most types support pattern
                true
              else
                false
              end
            end

            def read_tagged_value(uml_class, tag_name)
              return nil unless uml_class.respond_to?(:tags)
              return nil unless uml_class.tags

              tag = uml_class.tags.find { |t| t.name == tag_name }
              tag&.value
            end

            def type_name(uml_class, _context)
              # Check if local-basictype rule applies for anonymous types
              if rule_checker.applies?("rule-xsd-cls-local-basictype",
                                       uml_class)
                nil # Anonymous type
              else
                "#{uml_class.name}Type"
              end
            end
          end
        end
      end
    end
  end
end
