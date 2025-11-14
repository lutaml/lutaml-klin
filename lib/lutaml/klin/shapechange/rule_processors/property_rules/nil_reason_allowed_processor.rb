# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds nilReason attribute to property types
          # Implements rule-xsd-prop-nilReasonAllowed
          # Based on addAnonymousPropertyType() in XsdDocument.java
          # lines 3948-3955 and 4213-4222
          #
          # When a property is voidable or nilReasonAllowed,
          # adds a nilReason attribute to the property type for GML compliance
          class NilReasonAllowedProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-prop-nilReasonAllowed"

            def self.rule_name
              RULE_NAME
            end

            # Process property to add nilReason attribute if needed
            #
            # @param property [Object] The UML property
            # @param context [Hash] Processing context
            # @return [Hash] Processing result
            def process(property, context = {})
              return default_result unless applies_to?(property)

              gml_version = context[:gml_version] || "3.2"

              {
                applies: true,
                result: {
                  add_nil_reason: true,
                  nil_reason_type: determine_nil_reason_type(gml_version),
                  gml_version: gml_version
                },
                message: "Property allows nil reason, will add nilReason attribute"
              }
            end

            protected

            # Apply the rule to add nilReason attribute
            #
            # @param property [Object] The property
            # @param context [Hash] Processing context with :property_type_element
            def apply_rule(property, context)
              property_type = context[:property_type_element]
              return unless property_type

              if should_add_nil_reason?(property)
                add_nil_reason_attribute(property_type, context)
              end
            end

            private

            # Check if nilReason attribute should be added
            #
            # @param property [Object] The property
            # @return [Boolean] True if nilReason should be added
            def should_add_nil_reason?(property)
              nil_reason_allowed?(property) ||
                (voidable?(property) && has_nillable_rule?(property))
            end

            # Check if property explicitly allows nil reason
            #
            # @param property [Object] The property
            # @return [Boolean] True if nil reason is allowed
            def nil_reason_allowed?(property)
              # Try nil_reason_allowed? first
              if property.respond_to?(:nil_reason_allowed?)
                begin
                  return property.nil_reason_allowed?
                rescue StandardError
                  # Fall through to try alternative
                end
              end

              # Try alternative method name
              if property.respond_to?(:nilReasonAllowed)
                begin
                  return property.nilReasonAllowed
                rescue StandardError
                  return false
                end
              end

              false
            end

            # Check if property is voidable
            #
            # @param property [Object] The property
            # @return [Boolean] True if voidable
            def voidable?(property)
              # Try voidable? first
              if property.respond_to?(:voidable?)
                begin
                  return property.voidable?
                rescue StandardError
                  # Fall through to try alternative
                end
              end

              # Try alternative method name
              if property.respond_to?(:voidable)
                begin
                  return property.voidable
                rescue StandardError
                  return false
                end
              end

              false
            end

            # Check if nillable rule applies to property
            #
            # @param property [Object] The property
            # @return [Boolean] True if nillable rule is active
            def has_nillable_rule?(property)
              return false unless property.respond_to?(:matches?)

              property.matches?("rule-xsd-prop-nillable")
            rescue StandardError
              true # Assume true if can't check
            end

            # Add nilReason attribute to property type
            #
            # @param element [Object] The property type element
            # @param context [Hash] Processing context
            def add_nil_reason_attribute(element, context)
              xsd_doc = context[:xsd_document]
              return unless xsd_doc

              gml_version = context[:gml_version] || "3.2"
              nil_reason_type = determine_nil_reason_type(gml_version)

              # Create attribute element
              attribute = xsd_doc.create_attribute_element(
                name: "nilReason",
                type: nil_reason_type
              )

              # Add to property type
              xsd_doc.add_child(element, attribute)

              # Ensure GML namespace is imported
              gml_namespace = determine_gml_namespace(gml_version)
              xsd_doc.add_import("gml", gml_namespace) if gml_namespace
            end

            # Determine the appropriate nilReason type based on GML version
            #
            # @param gml_version [String] GML version
            # @return [String] The nilReason type name
            def determine_nil_reason_type(gml_version)
              case gml_version
              when "3.2"
                "gml:NilReasonType"
              when "3.1", "3.0"
                "gml:NullType"
              else
                "gml:NilReasonType" # Default to 3.2
              end
            end

            # Determine GML namespace based on version
            #
            # @param gml_version [String] GML version
            # @return [String, nil] GML namespace URI
            def determine_gml_namespace(gml_version)
              case gml_version
              when "3.2"
                "http://www.opengis.net/gml/3.2"
              when "3.1", "3.0"
                "http://www.opengis.net/gml"
              else
                "http://www.opengis.net/gml/3.2"
              end
            end

            # Check if rule applies to the property
            #
            # @param property [Object] The property
            # @return [Boolean] True if should add nilReason
            def applies_to?(property)
              should_add_nil_reason?(property)
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: nil,
                message: "Property does not allow nil reason"
              }
            end
          end
        end
      end
    end
  end
end