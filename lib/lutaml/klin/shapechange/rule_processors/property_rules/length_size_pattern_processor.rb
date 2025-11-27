# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds length/size/pattern restriction facets to property elements
          # Implements rule-xsd-prop-length-size-pattern
          # Based on addProperty() in XsdDocument.java lines 2267-2298
          #
          # CharacterString valued properties that carry tagged values
          # 'length', 'size', or 'pattern' are converted to anonymous types
          # with restricting facets
          class LengthSizePatternProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-length-size-pattern"

            protected

            def apply_rule(property, context)
              # Get the property element from context
              property_element = context[:property_element]
              return unless property_element

              # Get tagged values
              length_tv = get_tagged_value(property, "length")
              size_tv = get_tagged_value(property, "size")
              pattern_tv = get_tagged_value(property, "pattern")

              # Check if we should add restrictions
              # Need either 'length' OR both 'size' AND 'pattern'
              return unless should_add_restriction?(length_tv, size_tv,
                                                    pattern_tv)

              add_restriction(property_element, length_tv, size_tv,
                              pattern_tv, context)
            end

            private

            def get_tagged_value(property, tag_name)
              value = if property.respond_to?(:tagged_value)
                        property.tagged_value(tag_name)
                      end

              return nil if value.nil? || value.to_s.strip.empty?

              value.to_s.strip
            end

            def should_add_restriction?(length_tv, size_tv, pattern_tv)
              # Has 'length' tag
              return true if length_tv

              # Has both 'size' AND 'pattern'
              size_tv && pattern_tv
            end

            def add_restriction(element, length_tv, size_tv, pattern_tv,
                                context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              # Create simpleType element
              simple_type = xsd_doc.create_element("simpleType")

              # Create restriction with base="string"
              restriction = xsd_doc.create_element("restriction")
              xsd_doc.add_attribute(restriction, "base", "string")

              # Remove existing type attribute if present
              element.remove_attribute("type") if element.has_attribute?("type")

              # Append to structure
              simple_type.append_child(restriction)
              element.append_child(simple_type)

              # Add the appropriate facet
              if length_tv
                # maxLength facet
                facet = xsd_doc.create_element("maxLength")
                xsd_doc.add_attribute(facet, "value", length_tv)
                restriction.append_child(facet)
              elsif size_tv && pattern_tv
                # pattern facet with size repetition
                facet = xsd_doc.create_element("pattern")
                pattern_value = "#{pattern_tv}{#{size_tv}}"
                xsd_doc.add_attribute(facet, "value", pattern_value)
                restriction.append_child(facet)
              end
            end
          end
        end
      end
    end
  end
end
