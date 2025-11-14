# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Determines inline vs by-reference encoding for properties
          # Implements rule-xsd-prop-inlineOrByReference
          # Based on mapPropertyType() and addAnonymousPropertyType()
          # in XsdDocument.java lines 3029-3156 and 3989-4097
          #
          # Properties can be encoded:
          # - inline: Full object structure embedded
          # - byreference: Reference via xlink:href
          # - standard: Automatic based on class identity
          class InlineOrByReferenceProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-inlineOrByReference"

            protected

            def apply_rule(property, context)
              # Get encoding mode
              encoding_mode = get_encoding_mode(property)

              # Store mode in context for other processors
              context[:encoding_mode] = encoding_mode
              context[:embed_property_type] = should_embed_property_type?(
                property,
                encoding_mode,
                context
              )
            end

            private

            def get_encoding_mode(property)
              # Read inlineOrByReference from property
              mode = nil

              if property.respond_to?(:inline_or_by_reference)
                mode = property.inline_or_by_reference
              elsif property.respond_to?(:inlineOrByReference)
                mode = property.inlineOrByReference
              end

              # Normalize to lowercase
              return mode.to_s.downcase if mode

              # Default is "standard" (automatic)
              "standard"
            end

            def should_embed_property_type?(property, mode, context)
              case mode
              when "byreference"
                # For by-reference, always embed (never use standard type)
                true
              when "inline"
                # For inline, check multiple conditions
                check_inline_embedding_conditions(property, context)
              when "standard"
                # For standard, check default conditions
                check_standard_embedding_conditions(property, context)
              else
                false
              end
            end

            def check_inline_embedding_conditions(property, context)
              # Based on lines 3040-3080 in XsdDocument.java
              embed = false

              # Condition 1: GML 3.2+ with AbstractMemberType
              embed = true if gml_32_with_member_type?(property, context)

              # Condition 2: Property needs nilReason attribute
              embed = true if needs_nil_reason?(property)

              # Condition 3: Property is array property
              embed = true if array_property?(property)

              # Condition 4: Value type identity vs property type
              value_ci = get_value_class(property, context)
              if value_ci
                if class_has_identity?(value_ci, context)
                  # Has identity but no by-value property type
                  embed = true unless include_by_value_property_type?(value_ci)
                else
                  # No identity and no regular property type
                  embed = true unless include_property_type?(value_ci)
                end
              end

              # Condition 5: Property has qualifiers
              embed = true if has_qualifiers?(property)

              # Condition 6: Property has metadata
              embed = true if has_metadata?(property, context)

              embed
            end

            def check_standard_embedding_conditions(property, context)
              # Similar to inline but with different defaults
              # Based on lines 3088-3137
              embed = false

              # GML 3.2+ cases
              if gml_32_with_member_type?(property, context)
                embed = true
              end

              # Older GML or special conditions
              value_ci = get_value_class(property, context)
              if value_ci
                embed = true unless include_property_type?(value_ci)
              end

              # Check for soft-typed, qualifiers, metadata
              if needs_nil_reason?(property) ||
                 has_qualifiers?(property) ||
                 has_metadata?(property, context)
                embed = true
              end

              embed
            end

            def gml_32_with_member_type?(property, context)
              # Check if GML 3.2 and property derives from AbstractMemberType
              gml_ns = context[:gml_namespace]
              return false unless gml_ns == "http://www.opengis.net/gml/3.2"

              # Check if property is aggregation/composition/metadata
              (aggregation_or_composition?(property) || metadata?(property)) &&
                (gmlobject_or_feature?(property, context))
            end

            def aggregation_or_composition?(property)
              aggregation = if property.respond_to?(:aggregation?)
                             property.aggregation?
                           else
                             false
                           end

              composition = if property.respond_to?(:composition?)
                             property.composition?
                           else
                             false
                           end

              aggregation || composition
            end

            def metadata?(property)
              if property.respond_to?(:metadata?)
                property.metadata?
              else
                false
              end
            end

            def gmlobject_or_feature?(property, context)
              # Check if value type is GML object or feature
              value_ci = get_value_class(property, context)
              return false unless value_ci
              return false unless value_ci.respond_to?(:category)

              category = value_ci.category.to_s.upcase
              category == "GMLOBJECT" || category == "FEATURE"
            end

            def needs_nil_reason?(property)
              nil_reason = if property.respond_to?(:nil_reason_allowed?)
                            property.nil_reason_allowed?
                          else
                            false
                          end

              voidable = if property.respond_to?(:voidable?)
                          property.voidable?
                        else
                          false
                        end

              nil_reason || voidable
            end

            def array_property?(property)
              # Check for gmlArrayProperty tagged value
              return false unless property.respond_to?(:tags)

              tags = begin
                      property.tags
                    rescue
                      nil
                    end
              return false unless tags

              tag = tags.find { |t| t.name == "gmlArrayProperty" }
              return false unless tag
              return false unless tag.respond_to?(:value)

              tag.value&.downcase == "true"
            end

            def has_qualifiers?(property)
              return false unless property.respond_to?(:qualifiers)
              qualifiers = property.qualifiers
              qualifiers && !qualifiers.empty?
            end

            def has_metadata?(property, context)
              return false unless property.respond_to?(:property_metadata?)
              property.property_metadata?
            end

            def get_value_class(property, context)
              return nil unless property.respond_to?(:type)

              type_info = begin
                           property.type
                         rescue
                           nil
                         end
              return nil unless type_info

              # Try to find class by ID or name
              model = context[:model]
              return nil unless model

              class_by_id = begin
                             model.class_by_id(type_info.id) if type_info.respond_to?(:id)
                           rescue
                             nil
                           end
              return class_by_id if class_by_id

              begin
                model.class_by_name(type_info.name) if type_info.respond_to?(:name)
              rescue
                nil
              end
            end

            def class_has_identity?(ci, context)
              return false unless ci.respond_to?(:category)

              category = ci.category.to_s.upcase
              %w[MIXIN FEATURE OBJECT OKSTRAFID].include?(category)
            end

            def include_by_value_property_type?(ci)
              if ci.respond_to?(:include_by_value_property_type?)
                ci.include_by_value_property_type?
              else
                false
              end
            rescue
              false
            end

            def include_property_type?(ci)
              if ci.respond_to?(:include_property_type?)
                ci.include_property_type?
              else
                true # Default to true if not specified
              end
            rescue
              true
            end
          end
        end
      end
    end
  end
end