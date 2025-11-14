# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      module Strategies
        # Abstract base class for all type resolution strategies.
        #
        # The Strategy Pattern allows different type resolution algorithms to
        # be encapsulated in separate classes that share a common interface.
        # Each strategy implements two core methods:
        #
        # 1. {#applicable?} - Determines if this strategy can handle a given
        #    UML element
        # 2. {#resolve} - Performs the actual type resolution
        #
        # Strategies are tried in order by the ResolutionEngine until one
        # returns a resolved result.
        #
        # @abstract Subclasses must implement {#applicable?} and {#resolve}
        #
        # @example Implementing a custom strategy
        #   class CustomStrategy < BaseStrategy
        #     def applicable?(uml_element, context)
        #       uml_element.type.start_with?("Custom")
        #     end
        #
        #     def resolve(uml_element, context:)
        #       # Resolution logic here
        #       ResolutionResult.resolved(
        #         xsd_type: "string",
        #         namespace: "http://example.com",
        #         method: name
        #       )
        #     end
        #   end
        class BaseStrategy
          # Determine if this strategy can handle the given UML element.
          #
          # This method should quickly check if the strategy has the
          # necessary information to attempt resolution. It should not
          # perform expensive operations or make external calls.
          #
          # @param uml_element [Object] The UML element to check (typically
          #   has a `type` attribute)
          # @param context [ResolutionContext] The resolution context
          # @return [Boolean] true if this strategy can attempt resolution
          #
          # @abstract Subclasses must implement this method
          # @raise [NotImplementedError] if called on base class
          def applicable?(uml_element, context)
            raise NotImplementedError,
                  "#{self.class.name} must implement #applicable?"
          end

          # Attempt to resolve the UML element's type to an XSD type.
          #
          # This method performs the actual resolution logic. It should
          # return a ResolutionResult indicating success or failure.
          #
          # @param uml_element [Object] The UML element to resolve
          # @param context [ResolutionContext] The resolution context
          # @return [ResolutionResult] The resolution result
          #
          # @abstract Subclasses must implement this method
          # @raise [NotImplementedError] if called on base class
          def resolve(uml_element, context:)
            raise NotImplementedError,
                  "#{self.class.name} must implement #resolve"
          end

          # Returns the simple name of this strategy.
          #
          # This is used for logging and debugging to identify which strategy
          # performed a resolution.
          #
          # @return [String] The strategy name (e.g., "TypeOverrideStrategy")
          #
          # @example
          #   strategy = TypeOverrideStrategy.new
          #   strategy.name # => "TypeOverrideStrategy"
          def name
            self.class.name.split("::").last
          end

          # Returns a human-readable description of the strategy.
          #
          # @return [String] Strategy description
          def to_s
            name
          end

          # Returns a detailed inspection string for debugging.
          #
          # @return [String] Strategy information
          def inspect
            "#<#{self.class.name}>"
          end

          protected

          # Helper method to normalize EA-style type names.
          #
          # Enterprise Architect exports types with "::" separator (e.g.,
          # "xs::string") but XSD uses ":" (e.g., "xs:string"). This method
          # normalizes the format.
          #
          # @param type_name [String] The type name to normalize
          # @return [String] The normalized type name
          #
          # @example
          #   normalize_type_name("xs::string") # => "xs:string"
          #   normalize_type_name("xs:string")  # => "xs:string"
          def normalize_type_name(type_name)
            return type_name unless type_name

            # Replace EA's :: with standard :
            type_name.gsub("::", ":")
          end

          # Helper method to extract namespace prefix from a qualified type.
          #
          # @param type_name [String] The qualified type name (e.g.,
          #   "xs:string")
          # @return [String, nil] The namespace prefix, or nil if not
          #   qualified
          #
          # @example
          #   extract_namespace_prefix("xs:string") # => "xs"
          #   extract_namespace_prefix("string")    # => nil
          def extract_namespace_prefix(type_name)
            return nil unless type_name&.include?(":")

            type_name.split(":").first
          end

          # Helper method to extract local name from a qualified type.
          #
          # @param type_name [String] The qualified type name (e.g.,
          #   "xs:string")
          # @return [String] The local name
          #
          # @example
          #   extract_local_name("xs:string") # => "string"
          #   extract_local_name("string")    # => "string"
          def extract_local_name(type_name)
            return type_name unless type_name&.include?(":")

            type_name.split(":").last
          end
        end
      end
    end
  end
end