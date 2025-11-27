# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Handles abstract classes - prevents object element creation
          # Implements rule-xsd-cls-no-abstract-classes
          # Based on pComplexType() and subtypes() in XsdDocument.java
          # lines 1159-1178 and 3159-3162
          #
          # Abstract classes are not instantiable in XML Schema.
          # This processor prevents their direct encoding and instead
          # creates choice-based property types referencing concrete subtypes.
          class NoAbstractClassesProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-cls-no-abstract-classes"

            protected

            def apply_rule(uml_class, context)
              # Check if this is an abstract class
              return unless abstract_class?(uml_class)

              # Mark in context that this class should not have
              # object element created
              context[:skip_object_element] = true

              # Mark in context that this class should not have
              # properties processed in the normal way
              context[:skip_property_processing] = true

              # Instead, when properties reference this abstract class,
              # they should use choice of subtypes
              # This is handled in property processing
            end

            private

            def abstract_class?(uml_class)
              return false unless uml_class.respond_to?(:is_abstract?)

              begin
                uml_class.is_abstract?
              rescue StandardError
                false
              end
            end

            # Find all concrete (instantiable) subtypes
            # Recursively walks the subtype tree, skipping:
            # - MIXIN classes
            # - Abstract classes (when this rule applies)
            def find_concrete_subtypes(uml_class, context)
              result = []

              return result unless uml_class.respond_to?(:subtypes)

              begin
                subtypes = uml_class.subtypes
                return result unless subtypes

                subtypes.each do |subtype_id|
                  subtype = get_class_by_id(subtype_id, context)
                  next unless subtype

                  if should_skip_subtype?(subtype)
                    # Recursively get subtypes of this skipped class
                    result.concat(find_concrete_subtypes(subtype, context))
                  else
                    # This is a concrete class - add it
                    result << subtype
                  end
                end
              rescue StandardError
                # Return what we have
              end

              result
            end

            def should_skip_subtype?(subtype)
              # Skip if it's a MIXIN
              return true if mixin_class?(subtype)

              # Skip if it's abstract and this rule applies
              return true if abstract_class?(subtype)

              false
            end

            def mixin_class?(uml_class)
              # Check if this is a mixin type
              return true if uml_class.respond_to?(:stereotype) &&
                             uml_class.stereotype("mixin")

              # Check category if available
              if uml_class.respond_to?(:category)
                category = uml_class.category
                return true if category.to_s.downcase == "mixin"
              end

              false
            end

            def get_class_by_id(class_id, context)
              model = context[:model]
              return nil unless model

              begin
                model.class_by_id(class_id)
              rescue StandardError
                nil
              end
            end
          end
        end
      end
    end
  end
end
