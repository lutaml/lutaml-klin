# frozen_string_literal: true

require_relative "base_strategy"

module Lutaml
  module Klin
    module Domain
      module Strategies
        # Strategy for resolving types via direct XSD repository lookup.
        #
        # This is the fallback strategy that attempts direct resolution using
        # the XSD repository. It's always applicable and should be placed
        # last in the strategy chain.
        #
        # This strategy:
        # 1. Normalizes the type name (fixes EA's :: to :)
        # 2. Attempts direct lookup in the XSD repository
        # 3. Returns success if found, failure otherwise
        #
        # This works for:
        # - Built-in XSD types (xs:string, xs:int, etc.)
        # - Types already in namespace:localName format
        # - Types defined in loaded XSD schemas
        #
        # @example Direct XSD type lookup
        #   "xs:string" -> Resolved to XSD string type
        #   "gml:CodeType" -> Resolved if GML schema loaded
        class SchemaRepositoryStrategy < BaseStrategy
          # Always applicable as this is the fallback strategy.
          #
          # This strategy should be placed last in the chain so it catches
          # any types that weren't handled by higher-priority strategies.
          #
          # @param uml_element [Object] The UML element (must respond to
          #   `#type`)
          # @param context [ResolutionContext] The resolution context
          # @return [Boolean] true if element has a type
          #
          # @example
          #   strategy.applicable?(element, context) # => true (always, if
          #   type present)
          def applicable?(uml_element, _context)
            return false unless uml_element.respond_to?(:type)

            !uml_element.type.nil? && !uml_element.type.empty?
          end

          # Resolve the type via direct XSD repository lookup.
          #
          # This method:
          # 1. Normalizes the type name (fixes :: to :)
          # 2. Attempts resolution via the XSD repository
          # 3. Returns resolved result if found
          # 4. Returns unresolved result if not found
          #
          # @param uml_element [Object] The UML element to resolve
          # @param context [ResolutionContext] The resolution context
          # @return [ResolutionResult] The resolution result
          #
          # @example Successful resolution
          #   result = strategy.resolve(element, context: context)
          #   result.resolved? # => true
          #   result.xsd_type  # => "string"
          #
          # @example Failed resolution
          #   result = strategy.resolve(element, context: context)
          #   result.unresolved? # => true
          #   result.error       # => "Type not found..."
          def resolve(uml_element, context:)
            original_type = uml_element.type
            normalized_type = normalize_type_name(original_type)

            # Try direct resolution via XSD repository
            xsd_result = context.xsd_repository.resolve_type(normalized_type)

            # Check if resolution was successful
            if xsd_result.nil? || !xsd_result.resolved
              error_msg = xsd_result&.error_message ||
                          "Type '#{normalized_type}' not found in XSD repository"
              return ResolutionResult.unresolved(
                error: error_msg,
                metadata: {
                  original_type: original_type,
                  normalized_type: normalized_type,
                  strategy: name,
                  resolution_path: xsd_result&.resolution_path,
                  note: "This is the fallback strategy - all other " \
                        "strategies were unable to resolve"
                }
              )
            end

            ResolutionResult.resolved(
              xsd_type: xsd_result.local_name,
              namespace: xsd_result.namespace,
              method: name,
              confidence: 0.8, # Lower confidence as this is fallback
              metadata: {
                original_type: original_type,
                normalized_type: normalized_type,
                resolution_method: "direct_lookup",
                schema_file: xsd_result.schema_file
              }
            )
          rescue StandardError => e
            ResolutionResult.unresolved(
              error: "Error during XSD repository lookup: #{e.message}",
              metadata: {
                original_type: original_type,
                normalized_type: normalized_type,
                exception: e.class.name,
                backtrace: e.backtrace&.first(3),
                strategy: name
              }
            )
          end

          # Returns a description of this strategy.
          #
          # @return [String] Strategy description
          def to_s
            "#{name} (fallback: direct XSD repository lookup)"
          end
        end
      end
    end
  end
end
