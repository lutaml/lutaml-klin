# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Processor for rule-xsd-prop-xsdAsAttribute
          #
          # Generates XML attributes instead of elements for properties
          # when tagged value xsdAsAttribute="true".
          #
          # Based on XsdDocument.java:addProperty() lines 2125-2151
          class XsdAsAttributeProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-prop-xsdAsAttribute"

            def self.rule_name
              RULE_NAME
            end

            # Process property to determine encoding as attribute
            #
            # @param property [Object] The UML property
            # @param context [Hash] Processing context
            # @return [Hash] Processing result
            def process(property, context = {})
              context ||= {}
              in_assoc_class = context[:in_association_class] || false

              as_attribute = get_xsd_as_attribute(property)
              should_encode = should_encode_as_attribute?(property,
                                                          as_attribute, in_assoc_class)

              {
                applies: true,
                result: {
                  encode_as_attribute: should_encode,
                  tagged_value: as_attribute,
                  constraints_met: should_encode,
                  use_required: should_encode && is_required?(property)
                },
                message: generate_message(should_encode, as_attribute,
                                          in_assoc_class)
              }
            end

            private

            # Get xsdAsAttribute tagged value
            #
            # @param property [Object] The property
            # @return [String, nil] Tagged value
            def get_xsd_as_attribute(property)
              # Try xsdAsAttribute first
              value = get_tagged_value(property, "xsdAsAttribute")
              return value if value

              # Try alternative name
              get_tagged_value(property, "asXMLAttribute")
            end

            # Get tagged value from property
            #
            # @param property [Object] The property
            # @param tag_name [String] Tag name
            # @return [String, nil] Tag value
            def get_tagged_value(property, tag_name)
              return nil unless property.respond_to?(:tagged_value)

              begin
                value = property.tagged_value(tag_name)
                return nil if value.nil? || value.to_s.strip.empty?

                value.to_s.strip
              rescue StandardError
                nil
              end
            end

            # Check if property should be encoded as attribute
            #
            # @param property [Object] The property
            # @param as_attribute [String, nil] Tagged value
            # @param in_assoc_class [Boolean] In association class
            # @return [Boolean] True if should encode as attribute
            def should_encode_as_attribute?(property, as_attribute,
                                            in_assoc_class)
              # Must have tagged value set to "true"
              return false unless as_attribute&.casecmp("true")&.zero?

              # Cannot be in association class
              return false if in_assoc_class

              # Check multiplicity constraints
              multiplicity_valid?(property)
            end

            # Check if multiplicity allows attribute encoding
            #
            # @param property [Object] The property
            # @return [Boolean] True if multiplicity is valid
            def multiplicity_valid?(property)
              cardinality = get_cardinality(property)
              return true unless cardinality # Unknown, assume valid

              max_occurs = cardinality[:max_occurs]

              # Must be single occurrence or encoded as list
              max_occurs == 1 || is_list_property?(property)
            end

            # Get property cardinality
            #
            # @param property [Object] The property
            # @return [Hash, nil] Cardinality with :min_occurs and :max_occurs
            def get_cardinality(property)
              return nil unless property.respond_to?(:cardinality)

              begin
                card = property.cardinality
                return nil unless card

                {
                  min_occurs: get_min_occurs(card),
                  max_occurs: get_max_occurs(card)
                }
              rescue StandardError
                nil
              end
            end

            # Get minOccurs from cardinality
            #
            # @param cardinality [Object] Cardinality object
            # @return [Integer] Minimum occurrences
            def get_min_occurs(cardinality)
              if cardinality.respond_to?(:min_occurs)
                cardinality.min_occurs
              elsif cardinality.respond_to?(:minOccurs)
                cardinality.minOccurs
              else
                1
              end
            rescue StandardError
              1
            end

            # Get maxOccurs from cardinality
            #
            # @param cardinality [Object] Cardinality object
            # @return [Integer] Maximum occurrences
            def get_max_occurs(cardinality)
              if cardinality.respond_to?(:max_occurs)
                cardinality.max_occurs
              elsif cardinality.respond_to?(:maxOccurs)
                cardinality.maxOccurs
              else
                1
              end
            rescue StandardError
              1
            end

            # Check if property is encoded as list
            #
            # @param property [Object] The property
            # @return [Boolean] True if encoded as xs:list
            def is_list_property?(property)
              return false unless property.respond_to?(:matches?)

              begin
                # Check for gmlListProperty rule
                unless property.matches?("rule-xsd-prop-gmlListProperty")
                  return false
                end

                # Check tagged value
                list_value = get_tagged_value(property, "gmlListProperty")
                list_value&.casecmp("true")&.zero? || false
              rescue StandardError
                false
              end
            end

            # Check if property is required
            #
            # @param property [Object] The property
            # @return [Boolean] True if minOccurs >= 1
            def is_required?(property)
              cardinality = get_cardinality(property)
              return false unless cardinality

              cardinality[:min_occurs] >= 1
            end

            # Generate processing message
            #
            # @param should_encode [Boolean] Encode as attribute
            # @param tagged_value [String, nil] Tagged value
            # @param in_assoc_class [Boolean] In association class
            # @return [String] Processing message
            def generate_message(should_encode, tagged_value, in_assoc_class)
              if should_encode
                "Property will be encoded as XML attribute"
              elsif in_assoc_class
                "Cannot encode as attribute: in association class"
              elsif tagged_value&.casecmp("true")&.zero?
                "Cannot encode as attribute: multiplicity constraint"
              else
                "Property will be encoded as XML element"
              end
            end

            # Check if rule applies to the property
            #
            # This rule always applies (it's a conditional rule)
            #
            # @param property [Object] The property
            # @return [Boolean] Always true
            def applies_to?(_property)
              true
            end
          end
        end
      end
    end
  end
end
