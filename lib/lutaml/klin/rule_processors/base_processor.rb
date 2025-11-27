# frozen_string_literal: true

module Lutaml
  module Klin
    module RuleProcessors
      # Base class for all rule processors
      # Provides common functionality for rule processing
      class BaseProcessor
        attr_reader :rule_id, :config

        def initialize(config)
          @config = config
        end

        # Check if this processor's rule applies to the element
        # @param element [Object] UML element
        # @param config [Object] Configuration
        # @return [Boolean] true if rule applies
        def self.applies_to?(element, config)
          raise NotImplementedError, "#{self} must implement applies_to?"
        end

        # Process the element according to the rule
        # @param element [Object] UML element
        # @param context [Hash] Processing context
        # @return [Object] Processing result
        def self.process(element, context)
          raise NotImplementedError, "#{self} must implement process"
        end
      end
    end
  end
end
