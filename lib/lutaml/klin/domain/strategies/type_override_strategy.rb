# frozen_string_literal: true

require_relative "base_strategy"

module Lutaml
  module Klin
    module Domain
      module Strategies
        # Strategy for resolving types using explicit type overrides from
        # configuration.
        #
        # This is the highest priority strategy. It allows manual correction
        # of malformed types or custom mappings that override any other
        # resolution method.
        #
        # Type overrides are stored in the ResolutionContext and map UML type
        # names to XSD type names. After finding an override, this strategy
        # uses the XSD repository to get the full type definition.
        #
        # @example Common use cases
        #   # Fix malformed EA exports
        #   { "xs::string" => "xs:string" }
        #
        #   # Override default mappings
        #   { "CharacterString" => "xs:string" }
        #
        #   # Map to custom types
        #   { "CustomType" => "custom:MyType" }
        class TypeOverrideStrategy < BaseStrategy
          # Check if a type override exists for this element.
          #
          # @param uml_element [Object] The UML element (must respond to
          #   `#type`)
          # @param context [ResolutionContext] The resolution context
          # @return [Boolean] true if an override exists for this type
          #
          # @example
          #   strategy.applicable?(element, context) # => true if override
          #   exists
          def applicable?(uml_element, context)
            return false unless uml_element.respond_to?(:type)
            return false if uml_element.type.nil? || uml_element.type.empty?

            context.has_type_override?(uml_element.type)
          end

          # Resolve the type using the configured override.
          #
          # This method:
          # 1. Gets the override type from the context
          # 2. Normalizes the type name (fixes :: to :)
          # 3. Resolves the type using the XSD repository
          # 4. Returns a resolved or unresolved result
          #
          # @param uml_element [Object] The UML element to resolve
          # @param context [ResolutionContext] The resolution context
          # @return [ResolutionResult] The resolution result
          #
          # @example
          #   result = strategy.resolve(element, context: context)
          #   result.resolved? # => true
          #   result.xsd_type  # => "string"
          def resolve(uml_element, context:)
            override_type = context.get_type_override(uml_element.type)
            normalized_type = normalize_type_name(override_type)

            # Try to resolve via XSD repository
            xsd_result = context.xsd_repository.resolve_type(normalized_type)

            # Check if resolution was successful
            if xsd_result.nil? || !xsd_result.resolved
              error_msg = xsd_result&.error_message ||
                          "Type override '#{override_type}' not found in XSD repository"
              return ResolutionResult.unresolved(
                error: error_msg,
                metadata: {
                  original_type: uml_element.type,
                  override_type: override_type,
                  normalized_type: normalized_type,
                  strategy: name,
                  resolution_path: xsd_result&.resolution_path
                }
              )
            end

            ResolutionResult.resolved(
              xsd_type: xsd_result.local_name,
              namespace: xsd_result.namespace,
              method: name,
              confidence: 1.0,
              metadata: {
                original_type: uml_element.type,
                override_type: override_type,
                normalized_type: normalized_type,
                schema_file: xsd_result.schema_file
              }
            )
          rescue StandardError => e
            ResolutionResult.unresolved(
              error: "Error resolving type override: #{e.message}",
              metadata: {
                original_type: uml_element.type,
                override_type: override_type,
                exception: e.class.name,
                strategy: name
              }
            )
          end

          # Returns a description of this strategy.
          #
          # @return [String] Strategy description
          def to_s
            "#{name} (highest priority, manual overrides)"
          end
        end
      end
    end
  end
end
