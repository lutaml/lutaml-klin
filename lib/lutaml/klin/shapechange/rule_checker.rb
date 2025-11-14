# frozen_string_literal: true

module Lutaml
  module Klin
    module Shapechange
      # Checks if encoding rules apply to UML elements
      # Single Responsibility: Determine rule applicability
      class RuleChecker
        def initialize(rule_registry, encoding_rule_name)
          @registry = rule_registry
          @encoding_rule = encoding_rule_name
        end

        # Check if a rule applies to a UML element
        # @param rule_id [String] Rule identifier
        # @param element [Object] UML element (class, property, package)
        # @return [Boolean] true if rule applies
        def applies?(rule_id, element)
          # 1. Check if rule is in encoding rule set
          return false unless @registry.has_rule?(rule_id, @encoding_rule)

          # 2. Check if rule definition exists
          rule_def = @registry.rule_definition(rule_id)
          return true unless rule_def  # If no definition, assume applies

          # 3. Check element-specific conditions
          applies_to_element?(rule_def, element)
        end

        private

        def applies_to_element?(rule_def, element)
          case rule_def.scope
          when "class"
            applies_to_class?(rule_def, element)
          when "property"
            applies_to_property?(rule_def, element)
          when "package"
            applies_to_package?(rule_def, element)
          else
            true  # Universal rules ("all" scope)
          end
        end

        def applies_to_class?(rule_def, uml_class)
          return true if rule_def.applies_to.nil? || rule_def.applies_to.empty?

          # Check if class stereotype matches
          # UML classes can have multiple stereotypes
          return false unless uml_class.respond_to?(:stereotype)

          class_stereotypes = Array(uml_class.stereotype)
          rule_def.applies_to.any? { |required| class_stereotypes.include?(required) }
        end

        def applies_to_property?(rule_def, uml_property)
          true  # Property rules typically check other conditions
        end

        def applies_to_package?(rule_def, uml_package)
          true  # Package rules typically universal
        end
      end
    end
  end
end