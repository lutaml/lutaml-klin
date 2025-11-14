# frozen_string_literal: true

require_relative "base_strategy"

module Lutaml
  module Klin
    module Domain
      module Strategies
        # Strategy for resolving types using ShapeChange type mappings.
        #
        # ShapeChange configurations contain type mappings that specify how
        # UML types should be converted to XSD types. This strategy:
        #
        # 1. Checks if the ShapeChange config has a mapping for the type
        # 2. Extracts the xml_type from the mapping
        # 3. Resolves the xml_type via the XSD repository
        #
        # This is the standard method used by ShapeChange for GML/XSD
        # generation and has medium priority (after overrides, before direct
        # lookup).
        #
        # @example ShapeChange type mapping
        #   <TypeMapping>
        #     <uml_type>CharacterString</uml_type>
        #     <xml_type>xs:string</xml_type>
        #   </TypeMapping>
        class ShapeChangeMappingStrategy < BaseStrategy
          # Check if a ShapeChange mapping exists for this element's type.
          #
          # @param uml_element [Object] The UML element (must respond to
          #   `#type`)
          # @param context [ResolutionContext] The resolution context
          # @return [Boolean] true if a ShapeChange mapping exists
          #
          # @example
          #   strategy.applicable?(element, context) # => true if mapping
          #   exists
          def applicable?(uml_element, context)
            return false unless uml_element.respond_to?(:type)
            return false if uml_element.type.nil? || uml_element.type.empty?
            return false unless context.shapechange_config.respond_to?(
              :has_type_mapping?
            )

            # Normalize UML type name before checking mapping
            normalized_type = normalize_type_name(uml_element.type.to_s.strip)
            context.shapechange_config.has_type_mapping?(normalized_type)
          end

          # Resolve the type using the ShapeChange mapping.
          #
          # This method:
          # 1. Gets the type mapping from the ShapeChange config
          # 2. Extracts the xml_type from the mapping
          # 3. Normalizes the type name (fixes :: to :)
          # 4. Resolves via the XSD repository
          # 5. Returns a resolved or unresolved result
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
            # Normalize UML type name first
            normalized_type = normalize_type_name(uml_element.type.to_s.strip)

            # Get the type mapping from ShapeChange config
            mapping = context.shapechange_config.get_type_mapping(
              normalized_type
            )

            if mapping.nil?
              return ResolutionResult.unresolved(
                error: "ShapeChange mapping not found (should not happen " \
                       "if applicable? returned true)",
                metadata: {
                  original_type: uml_element.type,
                  normalized_type: normalized_type,
                  strategy: name,
                }
              )
            end

            # Extract xml_type from mapping and normalize it
            xml_type = extract_xml_type(mapping)
            if xml_type.nil? || xml_type.empty?
              return ResolutionResult.unresolved(
                error: "ShapeChange mapping has no xml_type",
                metadata: {
                  original_type: uml_element.type,
                  normalized_type: normalized_type,
                  mapping: mapping,
                  strategy: name,
                }
              )
            end

            # Normalize the xml_type from mapping
            normalized_xml_type = normalize_type_name(xml_type.strip)

            # Extract prefix and local name from xml_type
            if normalized_xml_type.include?(':')
              prefix, local_name = normalized_xml_type.split(':', 2)
            else
              prefix = nil
              local_name = normalized_xml_type
            end

            # Resolve namespace from ShapeChange config
            namespace = if prefix
              # Find namespace by prefix in xml_namespaces
              xml_ns = context.shapechange_config.xml_namespaces.find do |ns|
                ns.nsabr&.strip == prefix
              end
              xml_ns&.ns&.strip
            end

            # Return success with ShapeChange-provided mapping
            ResolutionResult.resolved(
              xsd_type: local_name,
              namespace: namespace,
              method: name,
              confidence: 0.95, # High confidence - direct ShapeChange mapping
              metadata: {
                original_type: uml_element.type,
                normalized_uml_type: normalized_type,
                xml_type: xml_type,
                normalized_xml_type: normalized_xml_type,
                mapping_source: "ShapeChange",
                prefix: prefix,
              }
            )
          rescue StandardError => e
            ResolutionResult.unresolved(
              error: "Error resolving ShapeChange mapping: #{e.message}",
              metadata: {
                original_type: uml_element.type,
                normalized_type: normalized_type,
                exception: e.class.name,
                strategy: name,
              }
            )
          end

          # Returns a description of this strategy.
          #
          # @return [String] Strategy description
          def to_s
            "#{name} (uses ShapeChange type mappings)"
          end

          private

          # Extract the xml_type from a ShapeChange mapping.
          #
          # The mapping structure may vary, so this method handles different
          # formats.
          #
          # @param mapping [Hash, Object] The ShapeChange mapping
          # @return [String, nil] The xml_type, or nil if not found
          def extract_xml_type(mapping)
            return nil if mapping.nil?

            # Handle hash-like mappings
            if mapping.respond_to?(:[])
              return mapping[:xml_type] || mapping["xml_type"]
            end

            # Handle object-like mappings
            if mapping.respond_to?(:xml_type)
              return mapping.xml_type
            end

            nil
          end
        end
      end
    end
  end
end