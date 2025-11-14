# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      # Value object representing the result of a bidirectional lookup query
      #
      # Encapsulates lookup results with metadata about the query and matches found.
      # Supports both UML → XSD and XSD → UML lookup directions.
      class LookupResult
        attr_reader :query, :direction, :matches, :metadata

        # @param attributes [Hash] the result attributes
        # @option attributes [String] :query the lookup query string
        # @option attributes [Symbol] :direction the lookup direction (:uml_to_xsd or :xsd_to_uml)
        # @option attributes [Array<Hash>] :matches array of matching results
        # @option attributes [Hash] :metadata additional metadata about the lookup
        def initialize(attributes)
          @query = attributes[:query]
          @direction = attributes[:direction]
          @matches = attributes[:matches] || []
          @metadata = attributes[:metadata] || {}
        end

        # Check if any matches were found
        #
        # @return [Boolean] true if matches array is not empty
        def found?
          matches.any?
        end

        # Check if exactly one match was found
        #
        # @return [Boolean] true if matches array contains exactly one item
        def single_match?
          matches.size == 1
        end

        # Check if multiple matches were found
        #
        # @return [Boolean] true if matches array contains more than one item
        def multiple_matches?
          matches.size > 1
        end

        # Get the first match (useful for single match results)
        #
        # @return [Hash, nil] the first match or nil if no matches
        def first_match
          matches.first
        end

        # Get the count of matches
        #
        # @return [Integer] number of matches found
        def match_count
          matches.size
        end

        # Check if the lookup was in the UML to XSD direction
        #
        # @return [Boolean] true if direction is :uml_to_xsd
        def uml_to_xsd?
          direction == :uml_to_xsd
        end

        # Check if the lookup was in the XSD to UML direction
        #
        # @return [Boolean] true if direction is :xsd_to_uml
        def xsd_to_uml?
          direction == :xsd_to_uml
        end

        # Convert the result to a hash for serialization
        #
        # @return [Hash] hash representation of the lookup result
        def to_h
          {
            query: query,
            direction: direction,
            match_count: match_count,
            matches: matches,
            metadata: metadata
          }
        end

        # Convert the result to JSON
        #
        # @return [String] JSON representation of the lookup result
        def to_json(*args)
          require "json"
          to_h.to_json(*args)
        end

        # Convert the result to YAML
        #
        # @return [String] YAML representation of the lookup result
        def to_yaml
          require "yaml"
          to_h.to_yaml
        end
      end
    end
  end
end