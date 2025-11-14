# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      module Services
        # TransformationAnalyzer predicts how ShapeChange would transform
        # UML elements to XSD elements.
        #
        # ShapeChange generates XSD files from UML models following specific
        # transformation rules. This service understands those rules and can
        # predict the expected XSD structure for any UML element.
        #
        # This is a pure, stateless service following OO principles:
        # - **Single Responsibility**: Only transformation analysis
        # - **Open/Closed**: Can be extended with more rules via subclassing
        # - **Immutable**: Configuration passed at construction, never modified
        # - **MECE**: Each method handles distinct, non-overlapping concerns
        #
        # @example Analyzing a UML class
        #   analyzer = TransformationAnalyzer.new(shapechange_config)
        #   analysis = analyzer.analyze_class(uml_class)
        #   # => { element_name: "Building", type_name: "BuildingType", ... }
        #
        # @example Analyzing a UML attribute
        #   analysis = analyzer.analyze_attribute(uml_attr)
        #   # => { xml_name: "height", xml_type: "gml:LengthType", ... }
        class TransformationAnalyzer
          # @return [ShapeChangeConfiguration] The ShapeChange configuration
          attr_reader :config

          # Initialize the transformation analyzer
          #
          # @param shapechange_config [ShapeChangeConfiguration] The
          #   ShapeChange configuration with type mappings and namespaces
          #
          # @raise [ArgumentError] if shapechange_config is nil
          def initialize(shapechange_config)
            raise ArgumentError, "shapechange_config is required" if
              shapechange_config.nil?

            @config = shapechange_config
            freeze
          end

          # Predict how a UML class would transform to XSD
          #
          # Follows GML/ShapeChange conventions:
          # - Element name = class name (unchanged)
          # - Type name = class name + "Type" suffix
          # - Property type name = class name + "PropertyType" suffix
          # - Namespace from package configuration
          #
          # @param uml_class [Object] UML class object (must respond to name,
          #   package)
          # @return [Hash] Predicted XSD structure with keys:
          #   - :element_name - XSD element name
          #   - :type_name - XSD type name
          #   - :property_type_name - XSD property type wrapper
          #   - :namespace - Target XSD namespace
          #
          # @example
          #   analysis = analyzer.analyze_class(building_class)
          #   analysis[:element_name] # => "Building"
          #   analysis[:type_name] # => "BuildingType"
          def analyze_class(uml_class)
            {
              element_name: uml_class.name,
              type_name: "#{uml_class.name}Type",
              property_type_name: "#{uml_class.name}PropertyType",
              namespace: determine_namespace(uml_class)
            }
          end

          # Predict how a UML attribute would transform to XSD
          #
          # Follows GML/ShapeChange conventions:
          # - XML name = attribute name (unchanged)
          # - XML type resolved from ShapeChange type mappings
          # - XML attribute vs. element based on name heuristics
          #
          # @param uml_attr [Object] UML attribute object (must respond to
          #   name, type)
          # @return [Hash] Predicted XSD structure with keys:
          #   - :xml_name - XSD element/attribute name
          #   - :xml_type - XSD type (resolved from mappings)
          #   - :is_attribute - Boolean: true if XML attribute, false if element
          #
          # @example
          #   analysis = analyzer.analyze_attribute(height_attr)
          #   analysis[:xml_name] # => "height"
          #   analysis[:xml_type] # => "gml:LengthType"
          #   analysis[:is_attribute] # => false
          def analyze_attribute(uml_attr)
            {
              xml_name: uml_attr.name,
              xml_type: resolve_xml_type(uml_attr.type),
              is_attribute: is_xml_attribute?(uml_attr)
            }
          end

          # Resolve a UML type to its corresponding XSD type
          #
          # Uses ShapeChange XsdMapEntry lookups to find the XML type
          # mapping. Falls back to the original type if no mapping found.
          #
          # @param uml_type [String] The UML type name
          # @param encoding_rule [String] The encoding rule (default: "citygml")
          # @return [String] The resolved XSD type
          #
          # @example
          #   resolve_xml_type("CharacterString") # => "xs:string"
          #   resolve_xml_type("Length") # => "gml:LengthType"
          def resolve_xml_type(uml_type, encoding_rule: "citygml")
            return nil unless uml_type

            # Normalize type name: gml::CodeType → gml:CodeType
            normalized_type = uml_type.to_s.gsub('::', ':').strip

            # Look up in XsdMapEntry with normalized name
            map_entry = config.find_type_mapping(normalized_type,
                                                  encoding_rule: encoding_rule)

            # Return normalized XSD type
            if map_entry
              map_entry.xml_type&.strip
            else
              normalized_type  # Return normalized type as fallback
            end
          end

          # Determine if a UML attribute maps to an XML attribute
          #
          # Uses heuristics based on common GML patterns:
          # - id, href, codeSpace → XML attributes
          # - Other names → XML elements
          #
          # @param uml_attr [Object] UML attribute object
          # @return [Boolean] true if should be XML attribute
          #
          # @example
          #   is_xml_attribute?(id_attr) # => true
          #   is_xml_attribute?(name_attr) # => false
          def is_xml_attribute?(uml_attr)
            # Common XML attribute names in GML
            xml_attribute_names = %w[id href codeSpace uom nilReason owns]

            xml_attribute_names.include?(uml_attr.name)
          end

          # Determine the target namespace for a UML class
          #
          # Looks up the namespace configuration for the class's package.
          # Falls back to a default namespace if not found.
          #
          # @param uml_class [Object] UML class object (must respond to
          #   qualified_name or package)
          # @return [String, nil] The target XSD namespace URI
          #
          # @example
          #   determine_namespace(building) # => "http://www.opengis.net/..."
          def determine_namespace(uml_class)
            # Try to get qualified name or package name
            package_path = if uml_class.respond_to?(:qualified_name)
                            uml_class.qualified_name
                          elsif uml_class.respond_to?(:package)
                            uml_class.package
                          else
                            nil
                          end

            return nil unless package_path

            config.namespace_for_package(package_path)
          rescue StandardError
            # If anything fails, return nil
            nil
          end

          # Check if a type mapping exists in ShapeChange configuration
          #
          # @param uml_type [String] The UML type name
          # @param encoding_rule [String] The encoding rule (default: "citygml")
          # @return [Boolean] true if mapping exists
          #
          # @example
          #   has_type_mapping?("CharacterString") # => true
          #   has_type_mapping?("UnknownType") # => false
          def has_type_mapping?(uml_type, encoding_rule: "citygml")
            config.has_type_mapping?(uml_type, encoding_rule: encoding_rule)
          end

          # Get the type mapping entry for a UML type
          #
          # @param uml_type [String] The UML type name
          # @param encoding_rule [String] The encoding rule (default: "citygml")
          # @return [XsdMapEntry, nil] The mapping entry or nil if not found
          #
          # @example
          #   entry = get_type_mapping("CharacterString")
          #   entry.xml_type # => "xs:string"
          def get_type_mapping(uml_type, encoding_rule: "citygml")
            config.get_type_mapping(uml_type, encoding_rule: encoding_rule)
          end
        end
      end
    end
  end
end