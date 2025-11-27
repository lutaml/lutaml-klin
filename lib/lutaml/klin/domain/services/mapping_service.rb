# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      module Services
        # MappingService provides pure domain logic for mapping UML elements
        # to XSD elements.
        #
        # This service contains NO I/O operations - it only processes data
        # and makes decisions based on business rules. All I/O is handled by
        # the application layer (MappingWorkflow).
        #
        # Responsibilities:
        # - Map UML classes to XSD types using resolution engine
        # - Map UML attributes to XSD elements using resolution engine
        # - Derive XSD element names from UML attribute names
        # - Convert UML multiplicities to XSD min/maxOccurs
        # - Extract resolution metadata for mapping models
        #
        # @example Using MappingService
        #   service = MappingService.new(resolution_engine)
        #
        #   # Map a class
        #   class_result = service.map_class_to_xsd(
        #     uml_class,
        #     xsd_namespace,
        #     context
        #   )
        #
        #   # Map an attribute
        #   attr_result = service.map_attribute_to_xsd(uml_attribute, context)
        class MappingService
          # @return [ResolutionEngine] The resolution engine for type resolution
          attr_reader :resolution_engine

          # @return [TransformationAnalyzer] The transformation analyzer for
          #   predicting ShapeChange transformations
          attr_reader :transformation_analyzer

          # Initialize the mapping service
          #
          # @param resolution_engine [ResolutionEngine] The resolution engine
          #   to use for all type resolutions
          # @param transformation_analyzer [TransformationAnalyzer] The
          #   transformation analyzer for understanding ShapeChange intent
          def initialize(resolution_engine, transformation_analyzer)
            @resolution_engine = resolution_engine
            @transformation_analyzer = transformation_analyzer
          end

          # Map a UML class to XSD type information
          #
          # Uses the resolution engine to resolve the class type and extracts
          # all relevant metadata for creating a ClassMapping model.
          #
          # @param uml_class [Object] UML class object (must respond to name,
          #   qualified_name, stereotype, documentation, attributes)
          # @param xsd_namespace [String] Target XSD namespace
          # @param context [ResolutionContext] Resolution context
          # @return [Hash] Hash with class mapping details:
          #   - :uml_name - UML class name
          #   - :uml_qualified_name - Fully qualified UML name
          #   - :uml_stereotype - Primary stereotype
          #   - :uml_documentation - UML documentation
          #   - :xsd_namespace - Target XSD namespace
          #   - :resolution_status - "resolved", "partial", or "unresolved"
          #   - :resolution_method - Resolution strategy name
          #   - :resolution_confidence - Confidence score (0-1)
          #   - :xsd_element_name - XSD element name (if resolved)
          #   - :xsd_type_name - XSD type name (if resolved)
          #   - :xsd_documentation - XSD documentation (if resolved)
          def map_class_to_xsd(uml_class, xsd_namespace, context)
            # Analyze transformation first to understand ShapeChange intent
            analysis = transformation_analyzer.analyze_class(uml_class)

            # Create a simple object with type property for resolution
            class_element = OpenStruct.new(type: uml_class.name)
            result = resolution_engine.resolve(class_element, context: context)

            # Construct qualified name from package and class name
            qualified_name = if uml_class.respond_to?(:qualified_name)
                               uml_class.qualified_name
                             else
                               uml_class.name
                             end

            mapping_details = {
              uml_name: uml_class.name,
              uml_qualified_name: qualified_name,
              uml_stereotype: extract_primary_stereotype(uml_class),
              uml_documentation: extract_documentation(uml_class),
              xsd_namespace: xsd_namespace
            }

            # Add resolution tracking
            if result.resolved?
              mapping_details.merge!(
                resolution_status: "resolved",
                resolution_method: result.method,
                resolution_confidence: extract_confidence(result),
                xsd_element_name: result.xsd_element&.name || analysis[:element_name],
                xsd_type_name: result.xsd_type || analysis[:type_name],
                xsd_documentation: result.xsd_element&.documentation
              )
            else
              # Use analysis as fallback when resolution fails
              mapping_details.merge!(
                resolution_status: "inferred",
                resolution_method: "transformation_analyzer",
                resolution_confidence: 0.7,
                xsd_element_name: analysis[:element_name],
                xsd_type_name: analysis[:type_name],
                xsd_documentation: nil
              )
            end

            mapping_details
          end

          # Map a UML attribute to XSD element information
          #
          # Uses the resolution engine to resolve the attribute's type and
          # extracts all relevant metadata for creating an AttributeMapping.
          #
          # @param uml_attribute [Object] UML attribute object (must respond to
          #   name, type, documentation, multiplicity)
          # @param context [ResolutionContext] Resolution context
          # @return [Hash] Hash with attribute mapping details:
          #   - :uml_name - UML attribute name
          #   - :uml_type - UML attribute type
          #   - :uml_documentation - UML documentation
          #   - :uml_multiplicity - UML multiplicity string
          #   - :xsd_name - Derived XSD element name
          #   - :xsd_type - Resolved XSD type
          #   - :xsd_documentation - XSD documentation (if resolved)
          #   - :xsd_min_occurs - XSD minOccurs
          #   - :xsd_max_occurs - XSD maxOccurs
          #   - :resolution_status - "resolved", "partial", or "unresolved"
          #   - :resolution_method - Resolution strategy name
          #   - :resolution_error - Error message (if unresolved)
          def map_attribute_to_xsd(uml_attribute, context)
            # Analyze transformation first to understand ShapeChange intent
            analysis = transformation_analyzer.analyze_attribute(uml_attribute)

            # Then attempt resolution via resolution engine
            result = resolution_engine.resolve(uml_attribute, context: context)

            # Derive XSD element name from UML attribute name
            derive_xsd_element_name(uml_attribute)

            # Convert UML multiplicity to XSD occurs
            multiplicity = extract_multiplicity(uml_attribute)
            occurs = map_multiplicity(multiplicity)

            mapping_details = {
              uml_name: uml_attribute.name,
              uml_type: uml_attribute.type,
              uml_documentation: extract_documentation(uml_attribute),
              uml_multiplicity: multiplicity,
              xsd_name: analysis[:xml_name],
              xsd_min_occurs: occurs[:min],
              xsd_max_occurs: occurs[:max]
            }

            # Add resolution details
            if result.resolved?
              mapping_details.merge!(
                xsd_type: result.xsd_type,
                xsd_documentation: result.xsd_element&.documentation,
                resolution_status: "resolved",
                resolution_method: result.method,
                resolution_confidence: extract_confidence(result),
                resolution_error: nil,
                is_attribute: analysis[:is_attribute]
              )
            elsif result.partial?
              mapping_details.merge!(
                xsd_type: result.xsd_type,
                resolution_status: "partial",
                resolution_method: result.method,
                resolution_confidence: 0.5,
                resolution_error: result.error,
                is_attribute: analysis[:is_attribute]
              )
            else
              # Use analysis as fallback when resolution fails
              mapping_details.merge!(
                xsd_type: analysis[:xml_type],
                resolution_status: analysis[:xml_type] ? "inferred" : "unresolved",
                resolution_method: analysis[:xml_type] ? "transformation_analyzer" : nil,
                resolution_confidence: analysis[:xml_type] ? 0.7 : 0.0,
                # Only set error if truly unresolved (no inferred type)
                resolution_error: analysis[:xml_type] ? nil : result.error,
                is_attribute: analysis[:is_attribute]
              )
            end

            mapping_details
          end

          # Derive XSD element name from UML attribute name
          #
          # Applies naming conventions to transform UML attribute names to
          # XSD element names. Currently uses the UML name as-is, but can be
          # enhanced with transformation rules.
          #
          # @param uml_attribute [Object] UML attribute object
          # @return [String] XSD element name
          def derive_xsd_element_name(uml_attribute)
            # Simple case: use attribute name as-is
            # Could be enhanced with naming conventions, e.g.:
            # - camelCase to snake_case
            # - Prefix/suffix transformations
            # - Namespace-specific rules
            uml_attribute.name
          end

          # Convert UML multiplicity to XSD min/maxOccurs
          #
          # Translates UML multiplicity strings to XSD occurrence constraints.
          #
          # @param multiplicity [String, nil] UML multiplicity string
          # @return [Hash] Hash with :min and :max keys
          #
          # @example Multiplicity conversions
          #   map_multiplicity("1")      # => {min: "1", max: "1"}
          #   map_multiplicity("0..1")   # => {min: "0", max: "1"}
          #   map_multiplicity("1..*")   # => {min: "1", max: "unbounded"}
          #   map_multiplicity("0..*")   # => {min: "0", max: "unbounded"}
          #   map_multiplicity(nil)      # => {min: "1", max: "1"}
          def map_multiplicity(multiplicity)
            return { min: "1", max: "1" } if multiplicity.nil? ||
                                             multiplicity.empty?

            case multiplicity
            when "1"
              { min: "1", max: "1" }
            when "0..1"
              { min: "0", max: "1" }
            when "1..*", "*"
              { min: "1", max: "unbounded" }
            when "0..*"
              { min: "0", max: "unbounded" }
            else
              # Handle numeric ranges like "2..5"
              if multiplicity =~ /^(\d+)\.\.(\d+|\*)$/
                min_val = Regexp.last_match(1)
                max_val = if Regexp.last_match(2) == "*"
                            "unbounded"
                          else
                            Regexp.last_match(2)
                          end
                { min: min_val, max: max_val }
              else
                # Default for unrecognized multiplicity
                { min: "1", max: "1" }
              end
            end
          end

          private

          # Extract primary stereotype from UML element
          #
          # @param uml_element [Object] UML element
          # @return [String, nil] Primary stereotype or nil
          def extract_primary_stereotype(uml_element)
            return nil unless uml_element.respond_to?(:stereotype)

            stereotype = uml_element.stereotype
            return nil if stereotype.nil? || stereotype.empty?

            # If multiple stereotypes, return first one
            stereotype.is_a?(Array) ? stereotype.first : stereotype
          end

          # Extract documentation from UML element
          #
          # @param uml_element [Object] UML element
          # @return [String, nil] Documentation text or nil
          def extract_documentation(uml_element)
            return nil unless uml_element.respond_to?(:documentation)

            doc = uml_element.documentation
            doc.nil? || doc.empty? ? nil : doc
          end

          # Extract multiplicity from UML attribute
          #
          # @param uml_attribute [Object] UML attribute
          # @return [String, nil] Multiplicity string or nil
          def extract_multiplicity(uml_attribute)
            return nil unless uml_attribute.respond_to?(:multiplicity)

            mult = uml_attribute.multiplicity
            mult.nil? || mult.empty? ? nil : mult
          end

          # Extract confidence score from resolution result
          #
          # @param result [ResolutionResult] Resolution result
          # @return [Float] Confidence score (0.0-1.0)
          def extract_confidence(result)
            return 0.0 unless result.resolved?

            # Try to get confidence from metadata
            confidence = result.metadata[:confidence] ||
                         result.metadata["confidence"]

            return confidence.to_f if confidence

            # Default confidence based on resolution method
            case result.method
            when /override/i
              1.0  # User overrides are 100% confident
            when /shapechange/i
              0.9  # ShapeChange mappings are very reliable
            when /repository/i
              0.95 # Direct schema lookups are highly reliable
            else
              0.8  # Default confidence
            end
          end
        end
      end
    end
  end
end
