# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      # Value object representing the result of a type resolution operation.
      #
      # A ResolutionResult encapsulates all information about a resolution
      # attempt, including success/failure status, resolved type information,
      # and metadata about how the resolution was performed.
      #
      # This is an immutable value object - all attributes are read-only and
      # set at construction time.
      #
      # @example Creating a successful resolution
      #   result = ResolutionResult.resolved(
      #     xsd_type: "string",
      #     namespace: "http://www.w3.org/2001/XMLSchema",
      #     method: "TypeOverrideStrategy",
      #     confidence: 1.0,
      #     metadata: { override_key: "CharacterString" }
      #   )
      #
      # @example Creating a failed resolution
      #   result = ResolutionResult.unresolved(
      #     error: "Type not found in any strategy",
      #     metadata: { attempted_strategies: ["TypeOverride", "ShapeChange"] }
      #   )
      class ResolutionResult
        # @return [Symbol] Resolution status (:resolved, :partial, or :unresolved)
        attr_reader :status

        # @return [String, nil] The resolved XSD type name (e.g., "string")
        attr_reader :xsd_type

        # @return [String, nil] The XSD namespace URI
        attr_reader :xsd_namespace

        # @return [Object, nil] The XSD element object (if available)
        attr_reader :xsd_element

        # @return [String, nil] The strategy that performed the resolution
        attr_reader :method

        # @return [Float] Confidence level of the resolution (0.0 to 1.0)
        attr_reader :confidence

        # @return [String, nil] Error message if resolution failed
        attr_reader :error

        # @return [Hash] Additional metadata about the resolution
        attr_reader :metadata

        # Factory method to create a successful resolution result.
        #
        # @param xsd_type [String] The resolved XSD type name
        # @param namespace [String] The XSD namespace URI
        # @param method [String] The strategy that performed the resolution
        # @param confidence [Float] Confidence level (default: 1.0)
        # @param metadata [Hash] Additional metadata (default: {})
        # @return [ResolutionResult] A resolved result
        #
        # @example
        #   ResolutionResult.resolved(
        #     xsd_type: "string",
        #     namespace: "http://www.w3.org/2001/XMLSchema",
        #     method: "TypeOverrideStrategy"
        #   )
        def self.resolved(xsd_type:, namespace:, method:, confidence: 1.0,
                          metadata: {}, xsd_element: nil)
          new(
            status: :resolved,
            xsd_type: xsd_type,
            xsd_namespace: namespace,
            xsd_element: xsd_element,
            method: method,
            confidence: confidence,
            metadata: metadata.freeze
          )
        end

        # Factory method to create a partially resolved result.
        #
        # @param xsd_type [String] The partially resolved XSD type name
        # @param method [String] The strategy that performed the resolution
        # @param error [String] Description of what's missing
        # @param metadata [Hash] Additional metadata (default: {})
        # @return [ResolutionResult] A partial result
        #
        # @example
        #   ResolutionResult.partial(
        #     xsd_type: "string",
        #     method: "ShapeChangeStrategy",
        #     error: "Documentation not available"
        #   )
        def self.partial(xsd_type:, method:, error:, metadata: {})
          new(
            status: :partial,
            xsd_type: xsd_type,
            method: method,
            error: error,
            confidence: 0.5,
            metadata: metadata.freeze
          )
        end

        # Factory method to create an unresolved (failed) resolution result.
        #
        # @param error [String] Description of why resolution failed
        # @param metadata [Hash] Additional metadata (default: {})
        # @return [ResolutionResult] An unresolved result
        #
        # @example
        #   ResolutionResult.unresolved(
        #     error: "Type not found",
        #     metadata: { attempted_type: "CustomType" }
        #   )
        def self.unresolved(error:, metadata: {})
          new(
            status: :unresolved,
            error: error,
            confidence: 0.0,
            metadata: metadata.freeze
          )
        end

        # Check if the resolution was successful.
        #
        # @return [Boolean] true if status is :resolved
        def resolved?
          status == :resolved
        end

        # Check if the resolution was partial.
        #
        # @return [Boolean] true if status is :partial
        def partial?
          status == :partial
        end

        # Check if the resolution failed.
        #
        # @return [Boolean] true if status is :unresolved
        def unresolved?
          status == :unresolved
        end

        # Returns a human-readable description of the resolution result.
        #
        # @return [String] Description of the result
        def to_s
          if resolved?
            "Resolved: #{xsd_type} (#{xsd_namespace}) via #{method} " \
              "(confidence: #{confidence})"
          else
            "Unresolved: #{error}"
          end
        end

        # Returns a detailed inspection string for debugging.
        #
        # @return [String] Detailed result information
        def inspect
          "#<#{self.class.name} status=#{status} " \
            "xsd_type=#{xsd_type.inspect} " \
            "namespace=#{xsd_namespace.inspect} " \
            "method=#{method.inspect} " \
            "confidence=#{confidence} " \
            "error=#{error.inspect} " \
            "metadata=#{metadata.inspect}>"
        end

        private

        # Private constructor - use factory methods instead.
        #
        # @param status [Symbol] Resolution status
        # @param xsd_type [String, nil] Resolved XSD type
        # @param xsd_namespace [String, nil] XSD namespace
        # @param method [String, nil] Resolution method
        # @param confidence [Float] Confidence level
        # @param error [String, nil] Error message
        # @param metadata [Hash] Additional metadata
        def initialize(status:, xsd_type: nil, xsd_namespace: nil,
                       xsd_element: nil, method: nil, confidence: 0.0,
                       error: nil, metadata: {})
          @status = status
          @xsd_type = xsd_type
          @xsd_namespace = xsd_namespace
          @xsd_element = xsd_element
          @method = method
          @confidence = confidence
          @error = error
          @metadata = metadata
          freeze
        end
      end
    end
  end
end
