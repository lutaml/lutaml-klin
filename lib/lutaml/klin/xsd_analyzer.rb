# frozen_string_literal: true

require "lutaml/xsd"
require_relative "models/xsd/complex_type_mapping"
require_relative "models/xsd/element_mapping"

module Lutaml
  module Klin
    # XsdAnalyzer parses XSD files using lutaml-xsd and provides
    # access to schema elements, types, and structure
    class XsdAnalyzer
      attr_reader :schema

      def initialize
        @schema = nil
      end

      # Parse an XSD file and return the schema object
      #
      # @param file_path [String] Path to the XSD file
      # @return [Lutaml::Xsd::Schema] Parsed schema object
      def parse_file(file_path)
        content = File.read(file_path)
        location = File.dirname(file_path)

        @schema = Lutaml::Xsd.parse(content, location: "#{location}/")
      end

      # Get all top-level elements from the schema
      #
      # @return [Array<Lutaml::Xsd::Element>] Array of element objects
      def elements
        return [] unless @schema

        @schema.element || []
      end

      # Get all complex types from the schema
      #
      # @return [Array<Lutaml::Xsd::ComplexType>] Array of complex type objects
      def complex_types
        return [] unless @schema

        @schema.complex_type || []
      end

      # Get all simple types from the schema
      #
      # @return [Array<Lutaml::Xsd::SimpleType>] Array of simple type objects
      def simple_types
        return [] unless @schema

        @schema.simple_type || []
      end

      # Get target namespace from the schema
      #
      # @return [String, nil] Target namespace URI
      def target_namespace
        @schema&.target_namespace
      end

      # Find an element by name
      #
      # @param name [String] Element name to search for
      # @return [Lutaml::Xsd::Element, nil] Found element or nil
      def find_element(name)
        elements.find { |el| el.name == name }
      end

      # Find a complex type by name
      #
      # @param name [String] Complex type name to search for
      # @return [Lutaml::Xsd::ComplexType, nil] Found complex type or nil
      def find_complex_type(name)
        complex_types.find { |ct| ct.name == name }
      end

      # Find a simple type by name
      #
      # @param name [String] Simple type name to search for
      # @return [Lutaml::Xsd::SimpleType, nil] Found simple type or nil
      def find_simple_type(name)
        simple_types.find { |st| st.name == name }
      end

      # Extract detailed mapping information from complex types
      #
      # @return [Array<Models::Xsd::ComplexTypeMapping>] Array of complex type mappings
      def extract_complex_type_mappings
        complex_types.map do |ct|
          extract_complex_type_mapping(ct)
        end
      end

      private

      # Extract mapping information from a single complex type
      #
      # @param complex_type [Lutaml::Xsd::ComplexType] The complex type to analyze
      # @return [Models::Xsd::ComplexTypeMapping] The extracted mapping
      def extract_complex_type_mapping(complex_type)
        mapping = Models::Xsd::ComplexTypeMapping.new
        mapping.name = complex_type.name
        mapping.abstract = complex_type.abstract || false
        mapping.mixed = complex_type.mixed || false
        mapping.namespace = target_namespace

        # Extract base type from complex_content extension
        if complex_type.complex_content&.extension
          mapping.extension = true
          mapping.base_type = complex_type.complex_content.extension.base
        end

        # Extract elements from sequence, choice, or all
        mapping.elements = extract_elements_from_content(complex_type)

        # Extract attributes
        mapping.attributes = extract_attributes(complex_type)

        mapping
      end

      # Extract elements from complex type content (sequence, choice, all)
      #
      # @param complex_type [Lutaml::Xsd::ComplexType] The complex type
      # @return [Array<Models::Xsd::ElementMapping>] Array of element mappings
      def extract_elements_from_content(complex_type)
        elements = []

        # From direct sequence
        if complex_type.sequence
          elements.concat(extract_elements_from_sequence(complex_type.sequence))
        end

        # From complex_content extension sequence
        if complex_type.complex_content&.extension&.sequence
          elements.concat(extract_elements_from_sequence(
                            complex_type.complex_content.extension.sequence
                          ))
        end

        # From choice
        if complex_type.choice
          elements.concat(extract_elements_from_choice(complex_type.choice))
        end

        # From all
        if complex_type.all
          elements.concat(extract_elements_from_all(complex_type.all))
        end

        elements
      end

      # Extract elements from a sequence
      #
      # @param sequence [Lutaml::Xsd::Sequence] The sequence
      # @return [Array<Models::Xsd::ElementMapping>] Array of element mappings
      def extract_elements_from_sequence(sequence)
        return [] unless sequence&.element

        sequence.element.map do |el|
          create_element_mapping(el)
        end
      end

      # Extract elements from a choice
      #
      # @param choice [Lutaml::Xsd::Choice] The choice
      # @return [Array<Models::Xsd::ElementMapping>] Array of element mappings
      def extract_elements_from_choice(choice)
        return [] unless choice&.element

        choice.element.map do |el|
          create_element_mapping(el)
        end
      end

      # Extract elements from an all group
      #
      # @param all [Lutaml::Xsd::All] The all group
      # @return [Array<Models::Xsd::ElementMapping>] Array of element mappings
      def extract_elements_from_all(all)
        return [] unless all&.element

        all.element.map do |el|
          create_element_mapping(el)
        end
      end

      # Extract attributes from a complex type
      #
      # @param complex_type [Lutaml::Xsd::ComplexType] The complex type
      # @return [Array<Models::Xsd::ElementMapping>] Array of attribute mappings
      def extract_attributes(complex_type)
        attributes = []

        # Direct attributes
        if complex_type.attribute
          attributes.concat(complex_type.attribute.map do |attr|
            create_attribute_mapping(attr)
          end)
        end

        # Attributes from complex_content extension
        if complex_type.complex_content&.extension&.attribute
          attributes.concat(
            complex_type.complex_content.extension.attribute.map do |attr|
              create_attribute_mapping(attr)
            end
          )
        end

        attributes
      end

      # Create an element mapping from an XSD element
      #
      # @param element [Lutaml::Xsd::Element] The XSD element
      # @return [Models::Xsd::ElementMapping] The element mapping
      def create_element_mapping(element)
        mapping = Models::Xsd::ElementMapping.new
        mapping.name = element.name || element.ref
        mapping.type = element.type
        mapping.min_occurs = element.min_occurs&.to_s || "1"
        mapping.max_occurs = element.max_occurs&.to_s || "1"
        mapping.namespace = target_namespace
        mapping
      end

      # Create an attribute mapping from an XSD attribute
      #
      # @param attribute [Lutaml::Xsd::Attribute] The XSD attribute
      # @return [Models::Xsd::ElementMapping] The attribute mapping
      def create_attribute_mapping(attribute)
        mapping = Models::Xsd::ElementMapping.new
        mapping.name = attribute.name || attribute.ref
        mapping.type = attribute.type
        mapping.min_occurs = attribute.use == "required" ? "1" : "0"
        mapping.max_occurs = "1"
        mapping.namespace = target_namespace
        mapping
      end
    end
  end
end
