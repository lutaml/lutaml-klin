# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Processor for rule-xsd-rel-association-classes
          #
          # Processes association class ends as additional properties
          # in XML Schema generation.
          class AssociationClassesProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-rel-association-classes"

            def self.rule_name
              RULE_NAME
            end

            # Process association class ends as properties
            #
            # @param uml_class [Lutaml::Uml::Class] The class to process
            # @param context [Hash] Processing context
            # @return [Hash] Processing result with association end properties
            def process(uml_class, context = {})
              return default_result unless applies_to?(uml_class)

              association = uml_class.is_association_class
              return default_result unless association

              {
                applies: true,
                result: {
                  association_ends: extract_association_ends(association),
                  end1: association.member_end&.first,
                  end2: association.member_end&.last
                },
                message: "Processing association class ends for #{uml_class.name}"
              }
            end

            private

            # Extract association end information
            #
            # @param association [Lutaml::Uml::Association] The association
            # @return [Array<Hash>] Association end details
            def extract_association_ends(association)
              return [] unless association.member_end

              association.member_end.map do |end_property|
                {
                  name: end_property.name,
                  type: end_property.type,
                  multiplicity: extract_multiplicity(end_property),
                  navigable: end_property.navigable?
                }
              end
            end

            # Extract multiplicity from property
            #
            # @param property [Object] The property
            # @return [Hash] Multiplicity information
            def extract_multiplicity(property)
              {
                min: property.lower_value&.value || 0,
                max: property.upper_value&.value || "*"
              }
            end

            # Check if rule applies to the class
            #
            # @param uml_class [Lutaml::Uml::Class] The class
            # @return [Boolean] True if class is an association class
            def applies_to?(uml_class)
              uml_class.is_association_class != nil
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: nil,
                message: "Not an association class"
              }
            end
          end
        end
      end
    end
  end
end