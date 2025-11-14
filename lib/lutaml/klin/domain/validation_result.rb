# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      # Value object representing the result of a validation operation.
      #
      # A ValidationResult encapsulates comprehensive validation analysis
      # including statistics, unresolved items, and detailed package-level
      # information.
      #
      # This is an immutable value object - all attributes are read-only and
      # set at construction time.
      #
      # @example Creating a validation result
      #   result = ValidationResult.new(
      #     summary: {
      #       total_packages: 3,
      #       total_classes: 174,
      #       resolved_classes: 170,
      #       total_attributes: 1250,
      #       resolved_attributes: 1200,
      #       resolution_rate: 96.0
      #     },
      #     unresolved_items: [...],
      #     packages: [...]
      #   )
      class ValidationResult
        # @return [Hash] Summary statistics of validation
        attr_reader :summary

        # @return [Array<Hash>] List of unresolved items with details
        attr_reader :unresolved_items

        # @return [Array<Hash>] Package-level validation details
        attr_reader :packages

        # @return [Array<Hash>] Global issues not specific to any package
        attr_reader :global_issues

        # @return [String] ISO 8601 timestamp when result was generated
        attr_reader :generated_at

        # Create a new ValidationResult.
        #
        # @param summary [Hash] Summary statistics
        # @param unresolved_items [Array<Hash>] List of unresolved items
        # @param packages [Array<Hash>] Package-level details
        # @param global_issues [Array<Hash>] Global issues (default: [])
        # @param generated_at [String] ISO 8601 timestamp (default: now)
        def initialize(summary:, unresolved_items:, packages:,
                       global_issues: [], generated_at: nil)
          @summary = summary.freeze
          @unresolved_items = unresolved_items.freeze
          @packages = packages.freeze
          @global_issues = global_issues.freeze
          @generated_at = generated_at || Time.now.utc.iso8601
          freeze
        end

        # Check if validation passed (no unresolved items).
        #
        # @return [Boolean] true if all mappings are resolved
        def valid?
          unresolved_items.empty?
        end

        # Get the overall resolution rate.
        #
        # @return [Float] resolution rate as percentage (0-100)
        def resolution_rate
          summary[:resolution_rate] || 0.0
        end

        # Get total number of packages.
        #
        # @return [Integer] total packages
        def total_packages
          summary[:total_packages] || 0
        end

        # Get total number of classes.
        #
        # @return [Integer] total classes
        def total_classes
          summary[:total_classes] || 0
        end

        # Get number of resolved classes.
        #
        # @return [Integer] resolved classes
        def resolved_classes
          summary[:resolved_classes] || 0
        end

        # Get total number of attributes.
        #
        # @return [Integer] total attributes
        def total_attributes
          summary[:total_attributes] || 0
        end

        # Get number of resolved attributes.
        #
        # @return [Integer] resolved attributes
        def resolved_attributes
          summary[:resolved_attributes] || 0
        end

        # Get unresolved item count.
        #
        # @return [Integer] count of unresolved items
        def unresolved_count
          unresolved_items.size
        end

        # Returns a human-readable description of the validation result.
        #
        # @return [String] Description of the result
        def to_s
          if valid?
            "Valid: All #{total_classes} classes resolved (100%)"
          else
            "Invalid: #{resolved_classes}/#{total_classes} classes " \
              "resolved (#{resolution_rate.round(2)}%), " \
              "#{unresolved_count} unresolved items"
          end
        end

        # Returns a detailed inspection string for debugging.
        #
        # @return [String] Detailed result information
        def inspect
          "#<#{self.class.name} " \
            "valid=#{valid?} " \
            "resolution_rate=#{resolution_rate}% " \
            "packages=#{total_packages} " \
            "classes=#{resolved_classes}/#{total_classes} " \
            "attributes=#{resolved_attributes}/#{total_attributes} " \
            "unresolved=#{unresolved_count}>"
        end
      end
    end
  end
end