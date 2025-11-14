# frozen_string_literal: true

require_relative "resolution_result"
require_relative "resolution_context"

module Lutaml
  module Klin
    module Domain
      # The Resolution Engine coordinates multiple strategies to resolve UML
      # types to XSD types.
      #
      # This is the core component of the resolution system. It implements
      # the Strategy Pattern by maintaining an ordered list of strategies and
      # trying each one in sequence until a resolution succeeds.
      #
      # The engine follows these principles:
      # - **Ordered execution**: Strategies are tried in the order provided
      # - **First success wins**: Resolution stops after first resolved result
      # - **Fail gracefully**: Returns unresolved result if all strategies
      #   fail
      # - **Immutable results**: All results are immutable value objects
      #
      # @example Basic usage
      #   strategies = [
      #     TypeOverrideStrategy.new,
      #     ShapeChangeMappingStrategy.new,
      #     SchemaRepositoryStrategy.new
      #   ]
      #   engine = ResolutionEngine.new(strategies)
      #   result = engine.resolve(uml_element, context: context)
      #
      # @example With custom strategies
      #   strategies = [
      #     CustomStrategy.new,
      #     TypeOverrideStrategy.new,
      #     SchemaRepositoryStrategy.new
      #   ]
      #   engine = ResolutionEngine.new(strategies)
      class ResolutionEngine
        # @return [Array<BaseStrategy>] The ordered list of strategies
        attr_reader :strategies

        # Initialize a new resolution engine.
        #
        # @param strategies [Array<BaseStrategy>] Ordered list of strategies
        #   to try
        #
        # @raise [ArgumentError] if strategies is nil or empty
        # @raise [ArgumentError] if any strategy doesn't respond to
        #   applicable? and resolve
        #
        # @example
        #   engine = ResolutionEngine.new([
        #     TypeOverrideStrategy.new,
        #     SchemaRepositoryStrategy.new
        #   ])
        def initialize(strategies)
          raise ArgumentError, "strategies cannot be nil or empty" if
            strategies.nil? || strategies.empty?

          validate_strategies(strategies)

          @strategies = strategies.freeze
        end

        # Resolve a UML element's type to an XSD type.
        #
        # This method tries each strategy in order:
        # 1. Check if strategy is applicable
        # 2. If yes, attempt resolution
        # 3. If resolved, return result immediately
        # 4. If unresolved, try next strategy
        # 5. If all strategies fail, return aggregate unresolved result
        #
        # @param uml_element [Object] The UML element to resolve (must
        #   respond to `#type`)
        # @param context [ResolutionContext] The resolution context
        # @return [ResolutionResult] The resolution result
        #
        # @raise [ArgumentError] if uml_element is nil
        # @raise [ArgumentError] if context is nil
        #
        # @example Successful resolution
        #   result = engine.resolve(element, context: context)
        #   result.resolved? # => true
        #   result.method    # => "TypeOverrideStrategy"
        #
        # @example Failed resolution
        #   result = engine.resolve(element, context: context)
        #   result.unresolved? # => true
        #   result.error       # => "Type not resolved by any strategy"
        def resolve(uml_element, context:)
          raise ArgumentError, "uml_element is required" if uml_element.nil?
          raise ArgumentError, "context is required" if context.nil?

          attempted_strategies = []
          errors = []

          strategies.each do |strategy|
            # Check if this strategy can handle the element
            next unless strategy.applicable?(uml_element, context)

            attempted_strategies << strategy.name

            # Attempt resolution
            result = strategy.resolve(uml_element, context: context)

            # If resolved, return immediately
            return result if result.resolved?

            # Track error for aggregate result
            errors << "#{strategy.name}: #{result.error}"
          end

          # All strategies failed
          create_aggregate_failure_result(
            uml_element,
            attempted_strategies,
            errors
          )
        end

        # Returns a human-readable description of the engine.
        #
        # @return [String] Description including strategy count
        def to_s
          "ResolutionEngine with #{strategies.size} strategies: " \
            "#{strategies.map(&:name).join(', ')}"
        end

        # Returns a detailed inspection string for debugging.
        #
        # @return [String] Engine information
        def inspect
          "#<#{self.class.name} strategies=[#{strategies.map(&:name).join(', ')}]>"
        end

        private

        # Validate that all strategies implement the required interface.
        #
        # @param strategies [Array] The strategies to validate
        # @raise [ArgumentError] if any strategy is invalid
        def validate_strategies(strategies)
          strategies.each_with_index do |strategy, index|
            unless strategy.respond_to?(:applicable?)
              raise ArgumentError,
                    "Strategy at index #{index} (#{strategy.class}) must " \
                    "respond to #applicable?"
            end

            unless strategy.respond_to?(:resolve)
              raise ArgumentError,
                    "Strategy at index #{index} (#{strategy.class}) must " \
                    "respond to #resolve"
            end
          end
        end

        # Create an aggregate failure result when all strategies fail.
        #
        # @param uml_element [Object] The UML element that failed to resolve
        # @param attempted_strategies [Array<String>] Names of tried
        #   strategies
        # @param errors [Array<String>] Error messages from each strategy
        # @return [ResolutionResult] An unresolved result
        def create_aggregate_failure_result(uml_element, attempted_strategies,
                                             errors)
          if attempted_strategies.empty?
            error_msg = "No applicable strategies found for type " \
                        "'#{uml_element.type}'"
          else
            error_msg = "Type '#{uml_element.type}' not resolved by any " \
                        "strategy"
          end

          ResolutionResult.unresolved(
            error: error_msg,
            metadata: {
              original_type: uml_element.type,
              attempted_strategies: attempted_strategies,
              strategy_errors: errors,
              total_strategies: strategies.size,
              applicable_strategies: attempted_strategies.size,
            }
          )
        end
      end
    end
  end
end