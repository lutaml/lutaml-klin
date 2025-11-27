# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Handles direct union encoding where union has single navigable property
          # Implements rule-xsd-cls-union-direct
          # Based on mapPropertyType() in XsdDocument.java lines 2880-2921
          #
          # A union with exactly one navigable property (not implemented by
          # nilReason) is "flattened" - the property with the union as value
          # receives the type of the union's single property directly.
          # The property becomes nillable to handle the nilReason option.
          class UnionDirectProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-cls-union-direct"

            protected

            def apply_rule(union_class, context)
              # This processor operates on properties that have union types
              # It's called from property processing context
              property = context[:current_property]
              property_element = context[:property_element]

              return unless property && property_element

              # Check if the property's value type is a union that should be
              # processed directly
              return unless union_direct?(union_class)

              # Find the single navigable property in the union
              union_property = find_navigable_property(union_class)

              unless union_property
                log_union_direct_error(union_class, property, context)
                return
              end

              # Apply direct encoding
              apply_direct_encoding(property, property_element, union_class,
                                    union_property, context)
            end

            private

            def union_direct?(union_class)
              # Check if this is a union type
              return false unless union_class?(union_class)

              # Check if union has the isUnionDirect flag or
              # has exactly 2 properties where 1 is implementedByNilReason
              check_union_direct_conditions(union_class)
            end

            def union_class?(uml_class)
              # Check if this is a union type
              return true if uml_class.respond_to?(:stereotype) &&
                             uml_class.stereotype("union")

              # Check category if available
              if uml_class.respond_to?(:category)
                category = uml_class.category
                return true if category.to_s.downcase == "union"
              end

              false
            end

            def check_union_direct_conditions(union_class)
              # Check for isUnionDirect method
              if union_class.respond_to?(:is_union_direct?)
                return union_class.is_union_direct?
              elsif union_class.respond_to?(:isUnionDirect)
                return union_class.isUnionDirect
              end

              # Alternative: Check if union has properties where one is
              # implemented by nilReason
              properties = get_properties(union_class)
              return false if properties.empty?

              navigable_props = properties.select do |p|
                navigable?(p) && !restriction?(p)
              end

              # Should have exactly 1 non-nilReason property
              non_nil_props = navigable_props.reject do |p|
                implemented_by_nil_reason?(p)
              end

              non_nil_props.size == 1 && navigable_props.size > 1
            end

            def find_navigable_property(union_class)
              properties = get_properties(union_class)

              # Find the single property that:
              # 1. Is navigable
              # 2. Is not a restriction
              # 3. Is not implemented by nilReason
              navigable_props = properties.select do |p|
                navigable?(p) && !restriction?(p) &&
                  !implemented_by_nil_reason?(p)
              end

              # Should have exactly one
              return navigable_props.first if navigable_props.size == 1

              nil
            end

            def get_properties(uml_class)
              return [] unless uml_class.respond_to?(:properties)

              begin
                props = uml_class.properties
                props = props.values if props.respond_to?(:values)
                props.to_a
              rescue StandardError
                []
              end
            end

            def navigable?(property)
              # Check if navigable (default true)
              return true unless property.respond_to?(:navigable?)

              begin
                property.navigable?
              rescue StandardError
                true
              end
            end

            def restriction?(property)
              return false unless property.respond_to?(:is_restriction?)

              begin
                property.is_restriction?
              rescue StandardError
                false
              end
            end

            def implemented_by_nil_reason?(property)
              # Check implementedByNilReason flag or tagged value
              if property.respond_to?(:implemented_by_nil_reason?)
                begin
                  return property.implemented_by_nil_reason?
                rescue StandardError
                  # Fall through
                end
              end

              # Check tagged value
              if property.respond_to?(:tagged_value)
                begin
                  tv = property.tagged_value("gmlImplementedByNilReason")
                  return tv.to_s.downcase == "true" if tv
                rescue StandardError
                  # Fall through
                end
              end

              false
            end

            def apply_direct_encoding(property, element, union_class,
                                      union_property, context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              # Set nillable="true"
              xsd_doc.add_attribute(element, "nillable", "true")

              # Propagate nilReason from union to property if needed
              if has_nil_reason?(union_class)
                set_nil_reason_allowed(union_property)
              end

              # Map the union property's type as this element's type
              # This is done by modifying context to use union_property
              # instead of the original property for type mapping
              map_union_property_type(element, union_property, context)

              # Calculate and set combined multiplicity
              set_combined_multiplicity(element, property, union_property,
                                        xsd_doc)
            end

            def has_nil_reason?(union_class)
              if union_class.respond_to?(:has_nil_reason?)
                begin
                  return union_class.has_nil_reason?
                rescue StandardError
                  # Fall through
                end
              end

              false
            end

            def set_nil_reason_allowed(property)
              return unless property.respond_to?(:nil_reason_allowed=)

              begin
                property.nil_reason_allowed = true
              rescue StandardError
                # Ignore if can't set
              end
            end

            def map_union_property_type(element, union_property, context)
              # Get the type of the union property
              type_info = union_property.respond_to?(:type_info) ? union_property.type_info : nil
              return unless type_info

              # For simplicity, we'll get the type name and set it
              # In full implementation, this would delegate to type mapping
              type_name = get_type_name(type_info, context)
              return unless type_name

              xsd_doc = context[:xsd_document]
              xsd_doc.add_attribute(element, "type", type_name)
            end

            def get_type_name(type_info, _context)
              # Try to get from type_info
              type_name = type_info.respond_to?(:name) ? type_info.name : nil
              return "#{type_name}Type" if type_name

              nil
            end

            def set_combined_multiplicity(element, property, union_property,
                                          xsd_doc)
              # Get multiplicities
              prop_card = get_cardinality(property)
              union_card = get_cardinality(union_property)

              return unless prop_card && union_card

              # Combine: min = minimum of both, max = product (or unbounded)
              min_occurs = [prop_card[:min], union_card[:min]].min

              max_occurs = if prop_card[:max] == :unbounded ||
                              union_card[:max] == :unbounded
                             :unbounded
                           else
                             prop_card[:max] * union_card[:max]
                           end

              # Set minOccurs if not 1
              unless min_occurs == 1
                xsd_doc.add_attribute(element, "minOccurs", min_occurs.to_s)
              end

              # Set maxOccurs if not 1
              if max_occurs == :unbounded
                xsd_doc.add_attribute(element, "maxOccurs", "unbounded")
              elsif max_occurs != 1
                xsd_doc.add_attribute(element, "maxOccurs", max_occurs.to_s)
              end
            end

            def get_cardinality(property)
              return nil unless property.respond_to?(:cardinality)

              begin
                card = property.cardinality
                min = card.respond_to?(:min_occurs) ? card.min_occurs : 1
                max = card.respond_to?(:max_occurs) ? card.max_occurs : 1

                # Handle Integer::MAX_VALUE or similar
                max = :unbounded if max.is_a?(Integer) && max > 1000

                { min: min, max: max }
              rescue StandardError
                nil
              end
            end

            def log_union_direct_error(union_class, property, _context)
              property_name = property.respond_to?(:name) ? property.name : "unknown"
              union_name = union_class.respond_to?(:name) ? union_class.name : "unknown"

              puts "Error: Union '#{union_name}' as the value type of " \
                   "'#{property_name}' could not be mapped as it does not " \
                   "contain the expected number of exactly one property to " \
                   "be encoded in the application schema."
            end
          end
        end
      end
    end
  end
end
