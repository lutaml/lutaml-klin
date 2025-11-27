# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Processes mixin supertype properties into class sequence
          # Implements rule-xsd-cls-mixin-classes
          # Based on pComplexType() and addMixinProperties()
          # in XsdDocument.java lines 938-945 and 1121-1135
          #
          # Mixin classes provide multiple inheritance simulation.
          # This processor flattens mixin properties into the
          # class's sequence element.
          class MixinClassesProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-cls-mixin-classes"

            protected

            def apply_rule(uml_class, context)
              # Get the sequence element from context
              sequence_element = context[:sequence_element]
              return unless sequence_element

              # Check if we should use group references instead
              # (that's a different rule: rule-xsd-cls-mixin-classes-as-group)
              return if use_groups?(uml_class)

              # Add mixin properties to the sequence
              add_mixin_properties(uml_class, sequence_element, context)
            end

            private

            def use_groups?(_uml_class)
              # Check if rule-xsd-cls-mixin-classes-as-group applies
              # For now, we only handle inline properties (not groups)
              false
            end

            def add_mixin_properties(uml_class, sequence_element, context)
              # Get supertypes
              supertypes = get_supertypes(uml_class)
              return if supertypes.empty?

              # Process each supertype
              supertypes.each do |supertype_id|
                supertype = get_class_by_id(supertype_id, context)
                next unless supertype

                # Check if this supertype is a mixin or abstract
                next unless mixin_or_abstract?(supertype, context)

                # Process this mixin's properties
                process_mixin_properties(supertype, sequence_element, context)

                # Recursively process mixin's own mixins
                add_mixin_properties(supertype, sequence_element, context)
              end
            end

            def get_supertypes(uml_class)
              return [] unless uml_class.respond_to?(:supertypes)

              begin
                st = uml_class.supertypes
                return [] unless st

                # Convert to array if it's a SortedSet or similar
                st.respond_to?(:to_a) ? st.to_a : Array(st)
              rescue StandardError
                []
              end
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

            def mixin_or_abstract?(uml_class, context)
              # Check if it's a MIXIN
              return true if mixin_class?(uml_class)

              # Check if it's abstract and no-abstract-classes rule applies
              if abstract_class?(uml_class)
                # Check if the class matches rule-xsd-cls-no-abstract-classes
                rule_checker = context[:rule_checker] || @rule_checker
                return true if rule_checker&.applies?(
                  "rule-xsd-cls-no-abstract-classes", uml_class
                )
              end

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

            def abstract_class?(uml_class)
              return false unless uml_class.respond_to?(:is_abstract?)

              begin
                uml_class.is_abstract?
              rescue StandardError
                false
              end
            end

            def process_mixin_properties(mixin_class, sequence_element,
                                         context)
              # Get properties of the mixin
              properties = get_properties(mixin_class)
              return if properties.empty?

              # Process each property
              # This delegates to the property processing infrastructure
              # which will add elements to the sequence
              properties.each do |property|
                add_property_to_sequence(property, sequence_element, context)
              end
            end

            def get_properties(uml_class)
              return [] unless uml_class.respond_to?(:properties)

              begin
                props = uml_class.properties
                # Handle both hash and array
                props = props.values if props.respond_to?(:values)
                props.to_a
              rescue StandardError
                []
              end
            end

            def add_property_to_sequence(property, _sequence_element, context)
              # This would typically call the property processor
              # to create the appropriate element
              # For now, we mark that mixin properties need processing
              mixin_properties = context[:mixin_properties] ||= []
              mixin_properties << property
            end
          end
        end
      end
    end
  end
end
