# frozen_string_literal: true

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Base class for all rule processors
        # Implements Template Method pattern
        class BaseRuleProcessor
          attr_reader :rule_id, :rule_checker, :config

          def initialize(rule_checker, config)
            @rule_checker = rule_checker
            @config = config
          end

          # Process element if rule applies
          # @param element [Object] UML element
          # @param context [Hash] Processing context
          # @return [Boolean] true if rule was applied
          def process(element, context)
            return false unless applicable?(element)

            apply_rule(element, context)
            true
          rescue StandardError => e
            puts "Error in #{self.class.name}: #{e.message}"
            false
          end

          protected

          # Check if this processor's rule applies to the element
          def applicable?(element)
            rule_checker.applies?(self.class::RULE_ID, element)
          end

          # Apply the rule (must be implemented by subclasses)
          def apply_rule(element, context)
            raise NotImplementedError, "#{self.class} must implement apply_rule"
          end
        end
      end
    end
  end
end