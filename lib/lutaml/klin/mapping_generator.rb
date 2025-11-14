# frozen_string_literal: true

require "time"

module Lutaml
  module Klin
    # MappingGenerator orchestrates UML-to-XSD mapping generation
    #
    # This class combines:
    # 1. UML model (from XMI) via XmiNavigator
    # 2. XSD schemas via XsdAnalyzer
    # 3. ShapeChange configuration for encoding rules and type mappings
    #
    # It generates YAML mappings showing how UML classes and attributes
    # map to XSD complex types and elements.
    class MappingGenerator
      attr_reader :config, :xmi_navigator, :xsd_analyzers, :mapping, :type_overrides

      # Initialize the mapping generator
      #
      # @param config [Shapechange::Models::Config::ShapeChangeConfiguration]
      #   Parsed ShapeChange configuration
      # @param xmi_navigator [XmiNavigator] Navigator for UML model
      # @param xsd_analyzers [Hash<String, XsdAnalyzer>] XSD analyzers by namespace
      # @param type_overrides [Hash<String, String>] Optional type override mappings
      def initialize(config:, xmi_navigator:, xsd_analyzers:, type_overrides: nil)
        @config = config
        @xmi_navigator = xmi_navigator
        @xsd_analyzers = xsd_analyzers
        @type_overrides = type_overrides || {}
        @mapping = Models::Mapping::SchemaMapping.new
        @type_mapping_cache = build_type_mapping_cache
      end

      # Generate mapping for a specific UML package
      #
      # @param package_name [String] Name of the UML package to map
      # @return [Models::Mapping::SchemaMapping] Generated mapping
      def generate_mapping(package_name)
        initialize_mapping

        uml_package = @xmi_navigator.find_package(package_name)
        unless uml_package
          raise ArgumentError, "Package not found: #{package_name}"
        end

        package_mapping = create_package_mapping(uml_package)
        @mapping.package_mappings << package_mapping if package_mapping

        @mapping
      end

      # Save mapping to YAML file
      #
      # @param output_path [String] Path to save YAML file
      def save_mapping(output_path)
        File.write(output_path, @mapping.to_yaml)
      end

      private

      def initialize_mapping
        @mapping.version = "1.0"
        @mapping.generated_at = Time.now.utc.iso8601
        @mapping.source_xmi = @xmi_navigator.xmi_path
        @mapping.package_mappings = []
        @mapping.namespaces = @config.xml_namespaces.map(&:ns)
      end

      # Build cache of UML type to XSD type mappings from config
      def build_type_mapping_cache
        cache = {}
        @config.xsd_map_entries.each do |entry|
          cache[entry.type] = entry
        end
        cache
      end

      # Create package mapping for a UML package
      def create_package_mapping(uml_package)
        # Find the XSD namespace for this package
        namespace = find_package_namespace(uml_package)
        return unless namespace

        # Find corresponding XSD analyzer
        xsd_analyzer = @xsd_analyzers[namespace]
        return unless xsd_analyzer

        Models::Mapping::PackageMapping.new.tap do |pkg|
          pkg.uml_name = uml_package.name
          pkg.xsd_namespace = namespace
          pkg.class_mappings = create_class_mappings(uml_package, xsd_analyzer)
        end
      end

      # Find XSD namespace for a UML package
      def find_package_namespace(uml_package)
        # Look up in ShapeChange config package infos
        package_info = @config.package_infos.find do |info|
          info.package_name == uml_package.name
        end

        package_info&.namespace || find_namespace_by_package_name(uml_package.name)
      end

      # Fallback: find namespace by matching package name patterns
      def find_namespace_by_package_name(package_name)
        @config.xml_namespaces.find do |ns|
          ns.nsabr.downcase == package_name.downcase ||
            ns.ns.include?(package_name.downcase)
        end&.ns
      end

      # Create class mappings for all classes in the package
      def create_class_mappings(uml_package, xsd_analyzer)
        uml_package.classes.map do |uml_class|
          create_class_mapping(uml_class, xsd_analyzer)
        end.compact
      end

      # Create mapping for a single UML class to XSD complex type
      def create_class_mapping(uml_class, xsd_analyzer)
        # Find corresponding XSD complex type
        xsd_type = find_matching_xsd_type(uml_class, xsd_analyzer)
        return unless xsd_type

        Models::Mapping::ClassMapping.new.tap do |cls|
          cls.uml_name = uml_class.name
          cls.xsd_name = xsd_type.name
          cls.xsd_namespace = xsd_analyzer.target_namespace
          cls.attribute_mappings = create_attribute_mappings(
            uml_class,
            xsd_type,
            xsd_analyzer
          )
        end
      end

      # Find XSD complex type matching a UML class
      def find_matching_xsd_type(uml_class, xsd_analyzer)
        # First try exact name match
        xsd_type = xsd_analyzer.complex_types.find do |ct|
          ct.name == uml_class.name
        end

        return xsd_type if xsd_type

        # Try with Type suffix (common ShapeChange convention)
        type_name = "#{uml_class.name}Type"
        xsd_analyzer.complex_types.find { |ct| ct.name == type_name }
      end

      # Create attribute mappings for all attributes in the class
      def create_attribute_mappings(uml_class, xsd_type, xsd_analyzer)
        mappings = []

        # Extract XSD structure
        xsd_mapping = xsd_analyzer.extract_complex_type_mapping(xsd_type)

        # Map UML attributes to XSD elements
        uml_class.attributes.each do |uml_attr|
          attr_mapping = map_uml_attribute_to_xsd(
            uml_attr,
            xsd_mapping,
            xsd_analyzer
          )
          mappings << attr_mapping if attr_mapping
        end

        mappings
      end

      # Map a single UML attribute to XSD element/attribute
      def map_uml_attribute_to_xsd(uml_attr, xsd_mapping, xsd_analyzer)
        # Find matching XSD element or attribute
        xsd_element = find_matching_xsd_element(uml_attr, xsd_mapping)
        return unless xsd_element

        Models::Mapping::AttributeMapping.new.tap do |attr|
          attr.uml_name = uml_attr.name
          attr.uml_type = uml_attr.type
          attr.xsd_name = xsd_element.name
          attr.xsd_type = resolve_xsd_type(xsd_element.type, xsd_analyzer)
          attr.namespace = xsd_element.namespace
          attr.min_occurs = xsd_element.min_occurs
          attr.max_occurs = xsd_element.max_occurs
        end
      end

      # Find XSD element matching a UML attribute
      def find_matching_xsd_element(uml_attr, xsd_mapping)
        # Try exact name match in elements
        element = xsd_mapping.elements.find do |elem|
          elem.name.downcase == uml_attr.name.downcase
        end

        return element if element

        # Try in attributes
        xsd_mapping.attributes.find do |attr|
          attr.name.downcase == uml_attr.name.downcase
        end
      end

      # Resolve XSD type using type overrides and ShapeChange type mappings
      #
      # Resolution priority:
      # 1. Type override mapping (e.g., "xs::string" -> "xs:string")
      # 2. ShapeChange type mapping cache
      # 3. Original type reference
      def resolve_xsd_type(xsd_type_ref, xsd_analyzer)
        return xsd_type_ref unless xsd_type_ref

        # Step 1: Apply type override if configured
        type_ref = @type_overrides[xsd_type_ref] || xsd_type_ref

        # Remove namespace prefix to get type name
        type_name = type_ref.split(':').last

        # Step 2: Check if this is a mapped type in ShapeChange config
        mapped = @type_mapping_cache[type_name]
        return mapped.xml_type if mapped

        # Step 3: Return resolved or original type
        type_ref
      end
    end
  end
end
