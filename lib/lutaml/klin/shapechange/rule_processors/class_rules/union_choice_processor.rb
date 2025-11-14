# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Generates choice elements for union types
          # Implements rule-xsd-cls-union-as-choice
          # Based on pComplexType() in XsdDocument.java lines 903-936
          #
          # Union types represent a choice between multiple options.
          # This processor creates <xs:choice> containers to enforce
          # that exactly one option is selected in XML instances.
          class UnionChoiceProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-cls-union-as-choice"

            protected

            def apply_rule(uml_class, context)
              xsd_doc = context[:xsd_document]

              # Only process UNION category classes
              return unless union_class?(uml_class)

              # Get the sequence or choice container from context
              # This is the element returned by pComplexType
              container = context[:container_element]
              return unless container

              # Determine if we should create a choice element
              choice_element = determine_choice_element(uml_class, xsd_doc, context)

              # Add choice to container if generated
              if choice_element
                context[:choice_element] = choice_element
              end
            end

            private

            def union_class?(uml_class)
              # Check if this is a union type
              # In UML, check stereotype or category
              return true if uml_class.respond_to?(:stereotype) &&
                           uml_class.stereotype("union")

              # Check category if available
              if uml_class.respond_to?(:category)
                category = uml_class.category
                return true if category.to_s.downcase == "union"
              end

              false
            end

            def determine_choice_element(uml_class, xsd_doc, context)
              # Get supertype if exists
              cibase = find_union_supertype(uml_class, context)

              # Check properties count
              properties_count = count_properties(uml_class)

              # Apply algorithm from XsdDocument.java lines 903-936
              if cibase.nil? && properties_count > 0
                # Case 1: Union has no supertype and has properties
                # Create a <choice> element
                create_choice_element(xsd_doc)

              elsif cibase && properties_count > 0 && count_properties(cibase) > 0
                # Case 2: Both supertype and subtype unions have properties
                # This is an error condition
                log_union_inheritance_error(uml_class, cibase)
                nil

              else
                # Case 3: Subtype union has no properties, or only supertype has properties
                # Do not create a choice (inherit from supertype)
                nil
              end
            end

            def find_union_supertype(uml_class, context)
              return nil unless uml_class.respond_to?(:generalizations)

              generalizations = begin
                                  uml_class.generalizations
                                rescue
                                  nil
                                end
              return nil unless generalizations

              # Find first supertype that is also a union
              generalizations.each do |gen|
                supertype = begin
                             gen.general
                           rescue
                             nil
                           end
                next unless supertype

                if union_class?(supertype)
                  return supertype
                end
              end

              nil
            end

            def count_properties(uml_class)
              return 0 unless uml_class.respond_to?(:attributes)
              return 0 unless uml_class.attributes

              # Count navigable properties
              uml_class.attributes.count do |attr|
                # Include if navigable (default true if not specified)
                attr.respond_to?(:navigable?) ? attr.navigable? : true
              end
            end

            def create_choice_element(xsd_doc)
              # Create xs:choice element
              # Note: The actual creation is handled by XsdDocument
              # This processor just signals that choice should be used
              xsd_doc.create_element("choice")
            end

            def log_union_inheritance_error(uml_class, cibase)
              # Log error message matching Java implementation (message 2000)
              puts "Error: Union '#{uml_class.name}' is subtype of union " \
                   "'#{cibase.name}'. Both have attributes. This would lead " \
                   "to an XML Schema that requires choices of both unions to " \
                   "be encoded via two XML elements. This is contrary to the " \
                   "modeling intent of a union (where a single element would " \
                   "be encoded). The attributes of the subtype will be ignored."
            end
          end
        end
      end
    end
  end
end