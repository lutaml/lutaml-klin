# frozen_string_literal: true

require_relative "base_strategy"
require_relative "../resolution_result"

module Lutaml
  module Klin
    module Domain
      module Strategies
        # DomainTypeStrategy resolves UML class references to their XSD type
        # names by looking up the class in the UML repository and applying
        # ShapeChange GML naming rules.
        #
        # This strategy handles custom domain types that aren't in
        # XsdMapEntry:
        # - FacilityAttribute → FacilityAttributeType
        # - ConstructionEvent → ConstructionEventType
        # - DmAttribute → DmAttributeType
        #
        # Follows ShapeChange's logic from XsdDocument.java lines 2849-3025.
        #
        # @example
        #   strategy = DomainTypeStrategy.new
        #   result = strategy.resolve(element, context: context)
        #   result.xsd_type # => "FacilityAttributeType"
        class DomainTypeStrategy < BaseStrategy
          # Returns the simple name of this strategy.
          #
          # @return [String] The strategy name
          def name
            "DomainTypeStrategy"
          end

          # Check if this strategy can handle the given UML element.
          #
          # Checks if the type name refers to a UML class in the model.
          #
          # @param uml_element [Object] The UML element (must respond to
          #   `#type`)
          # @param context [ResolutionContext] The resolution context
          # @return [Boolean] true if a UML class exists for this type
          def applicable?(uml_element, context)
            return false unless uml_element.respond_to?(:type)
            return false if uml_element.type.nil? || uml_element.type.empty?
            return false unless context.respond_to?(:uml_repository)
            return false if context.uml_repository.nil?

            # Check if the type name refers to a UML class in the model
            uml_class = find_uml_class(uml_element.type, context)
            !uml_class.nil?
          end

          # Resolve the type using UML class lookup and GML naming rules.
          #
          # This method:
          # 1. Finds the UML class in the repository
          # 2. Applies ShapeChange GML naming rules
          # 3. Returns a resolved result with metadata
          #
          # @param uml_element [Object] The UML element to resolve
          # @param context [ResolutionContext] The resolution context
          # @return [ResolutionResult] The resolution result
          def resolve(uml_element, context:)
            uml_class = find_uml_class(uml_element.type, context)

            unless uml_class
              return ResolutionResult.unresolved(
                error: "UML class not found for type: #{uml_element.type}",
                metadata: {
                  original_type: uml_element.type,
                  strategy: name,
                }
              )
            end

            # Apply ShapeChange GML naming rules
            type_name = apply_type_naming(uml_class)
            property_type_name = apply_property_type_naming(uml_class)
            namespace = determine_namespace(uml_class, context)

            # This matches what ShapeChange WOULD generate
            ResolutionResult.resolved(
              xsd_type: type_name,
              namespace: namespace,
              method: :domain_type_inference,
              confidence: 0.90,
              metadata: {
                uml_class_found: true,
                uml_class_name: uml_class.name,
                class_category: uml_class.respond_to?(:stereotype) ?
                  uml_class.stereotype : nil,
                xsd_property_type: property_type_name,
                xsd_namespace: namespace,
                naming_rule: "rule-xsd-all-naming-gml",
                strategy: name,
              }
            )
          rescue StandardError => e
            ResolutionResult.unresolved(
              error: "Error resolving domain type: #{e.message}",
              metadata: {
                original_type: uml_element.type,
                exception: e.class.name,
                strategy: name,
              }
            )
          end

          # Returns a description of this strategy.
          #
          # @return [String] Strategy description
          def to_s
            "#{name} (UML class lookup with GML naming rules)"
          end

          private

          # Find a UML class by type name in the repository.
          #
          # Handles namespace-qualified names and normalizes type names.
          #
          # @param type_name [String] The type name to search for
          # @param context [ResolutionContext] The resolution context
          # @return [Object, nil] The UML class or nil if not found
          def find_uml_class(type_name, context)
            return nil unless context.respond_to?(:uml_repository)

            # Normalize type name
            normalized = type_name.to_s.gsub("::", ":").strip

            # Remove namespace prefix if present
            local_name = if normalized.include?(":")
              normalized.split(":", 2).last
            else
              normalized
            end

            # Try to find in UML repository
            context.uml_repository.find_class(local_name)
          rescue StandardError
            nil
          end

          # Apply GML type naming rule.
          #
          # GML rule: ClassName + "Type"
          # From XsdDocument.java line 659-660
          #
          # @param uml_class [Object] The UML class
          # @return [String] The XSD type name
          def apply_type_naming(uml_class)
            base_name = uml_class.name
            suffix = base_name.end_with?("Property") ? "_" : ""
            "#{base_name}#{suffix}Type"
          end

          # Apply GML property type naming rule.
          #
          # GML rule: ClassName + "PropertyType"
          # From XsdDocument.java line 683-684
          #
          # @param uml_class [Object] The UML class
          # @return [String] The XSD property type name
          def apply_property_type_naming(uml_class)
            base_name = uml_class.name
            suffix = base_name.end_with?("Property") ? "_" : ""
            "#{base_name}#{suffix}PropertyType"
          end

          # Determine the XSD namespace for a UML class.
          #
          # Gets the namespace for the package this class belongs to.
          #
          # @param uml_class [Object] The UML class
          # @param context [ResolutionContext] The resolution context
          # @return [String, nil] The XSD namespace URI
          def determine_namespace(uml_class, context)
            # Get package name for the class
            package_name = if uml_class.respond_to?(:package)
              uml_class.package
            elsif uml_class.respond_to?(:owner)
              uml_class.owner&.name
            end

            return nil unless package_name

            context.shapechange_config.namespace_for_package(package_name)
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end