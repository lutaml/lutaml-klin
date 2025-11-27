# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      module Services
        # Service for filtering UML packages based on pattern matching.
        #
        # PackageFilter supports wildcard patterns for flexible package
        # selection:
        # - `**` matches any number of package levels
        # - `*` matches a single package name
        # - Exact names match specific packages
        #
        # @example Basic usage
        #   filter = PackageFilter.new("ModelRoot::i-UR::**")
        #   filter.matches?("ModelRoot::i-UR::urf")  # => true
        #   filter.matches?("ModelRoot::Core")       # => false
        #
        # @example Match all packages
        #   filter = PackageFilter.new("**")
        #   filter.matches?("any::package::path")    # => true
        #
        # @example Match specific ending
        #   filter = PackageFilter.new("**::urf")
        #   filter.matches?("ModelRoot::i-UR::urf")  # => true
        #   filter.matches?("Other::Path::urf")      # => true
        class PackageFilter
          # @return [String] The original filter pattern
          attr_reader :pattern_string

          # @return [Regexp] The compiled regex pattern
          attr_reader :pattern_regex

          # Create a new PackageFilter.
          #
          # @param filter_string [String] The filter pattern
          #   (e.g., "ModelRoot::i-UR::**")
          def initialize(filter_string)
            @pattern_string = filter_string
            @pattern_regex = parse_filter(filter_string)
          end

          # Check if a package path matches the filter pattern.
          #
          # @param package_path [String] The package path to test
          #   (e.g., "ModelRoot::i-UR::urf::Building")
          # @return [Boolean] true if the package path matches
          def matches?(package_path)
            return false if package_path.nil? || package_path.empty?

            pattern_regex.match?(package_path)
          end

          # Filter a collection of packages.
          #
          # @param packages [Array] Collection of package objects
          # @param path_method [Symbol] Method to call to get package path
          #   (default: :qualified_name)
          # @return [Array] Filtered packages that match the pattern
          def filter_packages(packages, path_method: :qualified_name)
            # If pattern is "**", return all packages
            return packages if pattern_string == "**"

            # Split comma-separated patterns
            patterns = pattern_string.split(",").map(&:strip)

            packages.select do |pkg|
              path = pkg.respond_to?(path_method) ? pkg.send(path_method) : pkg.to_s
              simple_name = path.split("::").last

              # Try multiple matching strategies for each pattern
              patterns.any? do |pattern|
                matches_package?(path, simple_name, pattern)
              end
            end
          end

          private

          # Check if a package matches a single pattern using multiple strategies
          #
          # @param full_path [String] Full qualified package path
          # @param simple_name [String] Simple package name (last segment)
          # @param pattern [String] Pattern to match against
          # @return [Boolean] true if package matches pattern
          def matches_package?(full_path, simple_name, pattern)
            # Strategy 1: Exact match (full path)
            return true if full_path == pattern

            # Strategy 2: Exact match (simple name)
            return true if simple_name == pattern

            # Strategy 3: Case-insensitive simple name
            return true if simple_name.downcase == pattern.downcase

            # Strategy 4: Substring match in full path
            return true if full_path.downcase.include?(pattern.downcase)

            # Strategy 5: Regex match (if pattern starts and ends with /)
            if pattern.start_with?("/") && pattern.end_with?("/")
              begin
                regex = Regexp.new(pattern[1..-2])
                return true if regex.match?(full_path)
              rescue RegexpError
                # Invalid regex, continue to other strategies
              end
            end

            # Strategy 6: Original wildcard pattern matching
            matches?(full_path)
          end

          # Returns a human-readable description of the filter.
          #
          # @return [String] Description
          def to_s
            "PackageFilter[#{pattern_string}]"
          end

          # Returns detailed inspection string for debugging.
          #
          # @return [String] Detailed filter information
          def inspect
            "#<#{self.class.name} pattern=#{pattern_string.inspect} " \
              "regex=#{pattern_regex.inspect}>"
          end

          # Parse a filter string into a regex pattern.
          #
          # Converts filter syntax to regex:
          # - `**` => match any number of path segments (including none)
          # - `*` => match single path segment
          # - Literal text => exact match
          #
          # @param filter_string [String] The filter pattern
          # @return [Regexp] Compiled regex pattern
          def parse_filter(filter_string)
            # Handle special case: match everything
            return /.*/ if filter_string == "**"

            # Escape special regex characters except our wildcards
            escaped = Regexp.escape(filter_string)

            # Replace escaped wildcards with regex equivalents
            # ** => match zero or more characters (greedy)
            # * => match one package segment (no ::)
            regex_pattern = escaped
                            .gsub(Regexp.escape("**"), ".*")
                            .gsub(Regexp.escape("*"), "[^:]+")

            # Anchor the pattern to match the full path
            Regexp.new("\\A#{regex_pattern}\\z")
          end
        end
      end
    end
  end
end
