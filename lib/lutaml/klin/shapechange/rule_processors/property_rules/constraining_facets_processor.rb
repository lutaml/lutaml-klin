# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds comprehensive constraining facets to property elements
          # Implements rule-xsd-prop-constrainingFacets
          # Based on addProperty() in XsdDocument.java lines 2300-2426
          #
          # Generate constraining facets based on tagged values:
          # length/maxLength/size, pattern, rangeMinimum, rangeMaximum
          #
          # NOTE: A facet is only created if the base type supports it
          class ConstrainingFacetsProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-constrainingFacets"

            # Base types that support totalDigits facet
            TOTAL_DIGITS_TYPES = %w[
              integer positiveInteger negativeInteger
              nonNegativeInteger nonPositiveInteger
              long unsignedLong int unsignedInt
              short unsignedShort byte unsignedByte
              decimal
            ].freeze

            # Base types that support maxLength facet
            MAX_LENGTH_TYPES = %w[
              string normalizedString token
              base64Binary hexBinary
              Name QName NCName anyURI language
              ID IDREF IDREFS ENTITY ENTITIES
              NOTATION NMTOKEN NMTOKENS
            ].freeze

            # Base types that support range facets (min/max Inclusive)
            RANGE_TYPES = %w[
              integer positiveInteger negativeInteger
              nonNegativeInteger nonPositiveInteger
              long unsignedLong int unsignedInt
              short unsignedShort byte unsignedByte
              decimal float double
              duration dateTime date time
              gYear gYearMonth gMonth gMonthDay gDay
            ].freeze

            protected

            def apply_rule(property, context)
              # Get the property element from context
              property_element = context[:property_element]
              return unless property_element

              # Skip if property category is CODELIST or ENUMERATION
              return if codelist_or_enumeration?(property, context)

              # Get all relevant tagged values
              facets = extract_facets(property)

              # Only proceed if at least one facet is present
              return if facets.values.all?(&:nil?)

              # Get base type for the property
              base_type = determine_base_type(property, context)
              return unless base_type

              # Determine type content (simple/simple or complex/simple)
              type_content = determine_type_content(property, context)

              # Add restriction with facets
              add_restriction_with_facets(property_element, base_type,
                                          type_content, facets, context)
            end

            private

            def codelist_or_enumeration?(property, _context)
              # Check if property value type is CODELIST or ENUMERATION
              return false unless property.respond_to?(:category_of_value)

              category = property.category_of_value
              %i[codelist enumeration].include?(category)
            rescue StandardError
              false
            end

            def extract_facets(property)
              {
                length: get_length_value(property),
                pattern: get_tagged_value(property, "pattern"),
                min: get_tagged_value(property, "rangeMinimum"),
                max: get_tagged_value(property, "rangeMaximum")
              }
            end

            def get_length_value(property)
              # Priority: length > maxLength > size
              get_tagged_value(property, "length") ||
                get_tagged_value(property, "maxLength") ||
                get_tagged_value(property, "size")
            end

            def get_tagged_value(property, tag_name)
              value = if property.respond_to?(:tagged_value)
                        property.tagged_value(tag_name)
                      end

              return nil if value.nil? || value.to_s.strip.empty?

              value.to_s.strip
            end

            def determine_base_type(property, context)
              # Try to get from map entry first
              type_info = property.respond_to?(:type_info) ? property.type_info : nil
              return nil unless type_info

              # Check if there's a map entry
              base_from_map = get_base_from_map(type_info, context)
              return base_from_map if base_from_map

              # Otherwise get from type class
              type_ci = get_type_class(type_info, context)

              # If we can't find the type class, try mapping by name directly
              if type_ci.nil? && type_info.respond_to?(:name)
                return map_type_name_to_base(type_info.name)
              end

              return nil unless type_ci

              # Get base type from supertype map entries
              find_base_in_supertypes(type_ci, context)
            end

            def map_type_name_to_base(type_name)
              # Direct mapping of type names to XSD base types
              case type_name
              when "CharacterString", "String"
                "string"
              when "Integer"
                "integer"
              when "Real", "Number", "Decimal"
                "decimal"
              when "Boolean"
                "boolean"
              when "DateTime"
                "dateTime"
              when "Date"
                "date"
              end
            end

            def get_base_from_map(_type_info, _context)
              # This would check configuration map entries
              # For now return nil to use type-based lookup
              nil
            end

            def get_type_class(type_info, context)
              # Try to get class by ID or name
              model = context[:model]
              return nil unless model

              type_ci = if type_info.respond_to?(:id)
                          model.class_by_id(type_info.id)
                        end

              if type_info.respond_to?(:name)
                type_ci ||= model.class_by_name(type_info.name)
              end
              type_ci
            end

            def find_base_in_supertypes(type_ci, _context)
              # Simple mapping of common types to XSD base types
              type_name = type_ci.respond_to?(:name) ? type_ci.name : nil
              return nil unless type_name

              # Common mappings
              case type_name
              when "CharacterString", "String"
                "string"
              when "Integer"
                "integer"
              when "Real", "Number"
                "decimal"
              when "Boolean"
                "boolean"
              when "DateTime"
                "dateTime"
              when "Date"
                "date"
              else
                # Default to string for unknown types
                "string"
              end
            end

            def determine_type_content(_property, _context)
              # For simplicity, assume simple/simple
              # In full implementation would check map entries
              "simple/simple"
            end

            def add_restriction_with_facets(element, base_type, type_content,
                                            facets, context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              # Remove existing type attribute
              element.remove_attribute("type") if element.has_attribute?("type")

              # Create appropriate structure based on type content
              if type_content == "complex/simple"
                add_complex_simple_restriction(element, base_type, facets,
                                               xsd_doc)
              elsif type_content == "simple/simple"
                add_simple_simple_restriction(element, base_type, facets,
                                              xsd_doc)
              else
                # complex/complex - use extension
                add_complex_complex_extension(element, base_type, xsd_doc)
              end
            end

            def add_complex_simple_restriction(element, base, facets, xsd_doc)
              complex_type = xsd_doc.create_element("complexType")
              simple_content = xsd_doc.create_element("simpleContent")
              restriction = xsd_doc.create_element("restriction")

              xsd_doc.add_attribute(restriction, "base", base)

              complex_type.append_child(simple_content)
              simple_content.append_child(restriction)
              element.append_child(complex_type)

              add_facets(restriction, base, facets, xsd_doc)
            end

            def add_simple_simple_restriction(element, base, facets, xsd_doc)
              simple_type = xsd_doc.create_element("simpleType")
              restriction = xsd_doc.create_element("restriction")

              xsd_doc.add_attribute(restriction, "base", base)

              simple_type.append_child(restriction)
              element.append_child(simple_type)

              add_facets(restriction, base, facets, xsd_doc)
            end

            def add_complex_complex_extension(element, base, xsd_doc)
              complex_type = xsd_doc.create_element("complexType")
              complex_content = xsd_doc.create_element("complexContent")
              extension = xsd_doc.create_element("extension")

              xsd_doc.add_attribute(extension, "base", base)

              complex_type.append_child(complex_content)
              complex_content.append_child(extension)
              element.append_child(complex_type)
            end

            def add_facets(restriction, base_type, facets, xsd_doc)
              # Add totalDigits if supported and length is present
              if facet_supported?("totalDigits", base_type) && facets[:length]
                facet = xsd_doc.create_element("totalDigits")
                xsd_doc.add_attribute(facet, "value", facets[:length])
                restriction.append_child(facet)
              end

              # Add maxLength if supported and length is present
              if facet_supported?("maxLength", base_type) && facets[:length]
                facet = xsd_doc.create_element("maxLength")
                xsd_doc.add_attribute(facet, "value", facets[:length])
                restriction.append_child(facet)
              end

              # Add pattern if present (always supported)
              if facets[:pattern]
                facet = xsd_doc.create_element("pattern")
                xsd_doc.add_attribute(facet, "value", facets[:pattern])
                restriction.append_child(facet)
              end

              # Add minInclusive if supported
              if facet_supported?("minInclusive", base_type) && facets[:min]
                facet = xsd_doc.create_element("minInclusive")
                xsd_doc.add_attribute(facet, "value", facets[:min])
                restriction.append_child(facet)
              end

              # Add maxInclusive if supported
              unless facet_supported?("maxInclusive", base_type) && facets[:max]
                return
              end

              facet = xsd_doc.create_element("maxInclusive")
              xsd_doc.add_attribute(facet, "value", facets[:max])
              restriction.append_child(facet)
            end

            def facet_supported?(facet, base_type)
              # Extract local name if qualified
              local_base = base_type.include?(":") ? base_type.split(":").last : base_type

              case facet
              when "totalDigits"
                TOTAL_DIGITS_TYPES.include?(local_base)
              when "maxLength"
                MAX_LENGTH_TYPES.include?(local_base)
              when "pattern"
                true # Pattern is always supported
              when "minInclusive", "maxInclusive", "minExclusive", "maxExclusive"
                RANGE_TYPES.include?(local_base)
              else
                # For non-XSD base types (qnames), assume supported
                base_type.include?(":")
              end
            end
          end
        end
      end
    end
  end
end
