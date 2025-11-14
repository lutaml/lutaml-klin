# frozen_string_literal: true

require "nokogiri"

module Lutaml
  module Klin
    module Shapechange
      module Models
        # Represents an XSD document being built
        # Provides methods to add elements, types, imports, etc.
        # Single Responsibility: Manage XSD document structure
        class XsdDocument
          attr_reader :namespace, :prefix, :version
          attr_accessor :root_element

          def initialize(namespace:, prefix:, version: "1.0")
            @namespace = namespace
            @prefix = prefix
            @version = version
            @imports = []
            @includes = []
            create_document
            add_standard_imports
          end

          # Create Nokogiri XML document
          def create_document
            @xml_doc = Nokogiri::XML::Document.new
            @root_element = @xml_doc.create_element("xs:schema")

            # Add namespace definitions
            @root_element.add_namespace_definition("xs", "http://www.w3.org/2001/XMLSchema")
            @root_element.add_namespace_definition(@prefix, @namespace)

            # Set attributes
            @root_element["targetNamespace"] = @namespace
            @root_element["elementFormDefault"] = "qualified"
            @root_element["version"] = @version

            @xml_doc.add_child(@root_element)
          end

          # Add an import statement
          def add_import(namespace:, location: nil)
            return if @imports.include?(namespace)

            @imports << namespace

            import_element = @xml_doc.create_element("xs:import")
            import_element["namespace"] = namespace
            import_element["schemaLocation"] = location if location

            # Insert after any existing imports
            @root_element.prepend_child(import_element)
          end

          # Add a global element
          def add_element(name:, type:, **attributes)
            element = @xml_doc.create_element("xs:element")
            element["name"] = name
            element["type"] = type

            attributes.each { |k, v| element[k.to_s] = v.to_s }
            @root_element.add_child(element)
            element
          end

          # Add a complex type
          def add_complex_type(name:, **attributes)
            complex_type = @xml_doc.create_element("xs:complexType")
            complex_type["name"] = name

            attributes.each { |k, v| complex_type[k.to_s] = v.to_s }
            @root_element.add_child(complex_type)
            complex_type
          end

          # Add complexContent/extension structure to a complexType
          def add_complex_content_extension(complex_type, base_type)
            complex_content = @xml_doc.create_element("xs:complexContent")
            complex_type.add_child(complex_content)

            extension = @xml_doc.create_element("xs:extension")
            extension["base"] = base_type
            complex_content.add_child(extension)

            extension
          end

          # Add a sequence element (for content model)
          def add_sequence(parent)
            sequence = @xml_doc.create_element("xs:sequence")
            parent.add_child(sequence)
            sequence
          end

          # Add a choice element (for union types)
          def add_choice(parent)
            choice = @xml_doc.create_element("xs:choice")
            parent.add_child(choice)
            choice
          end

          # Create an element without adding to document
          def create_element(name, **attributes)
            # Prefix with xs: if not already prefixed
            prefixed_name = name.include?(":") ? name : "xs:#{name}"
            element = @xml_doc.create_element(prefixed_name)
            attributes.each { |k, v| element[k.to_s] = v.to_s if v }
            element
          end

          # Add attribute group reference
          def add_attribute_group(parent, ref:)
            attr_group = create_element("attributeGroup", ref: ref)
            parent.add_child(attr_group)
            attr_group
          end

          # Add a simple type
          def add_simple_type(name:, **attributes)
            simple_type = @xml_doc.create_element("xs:simpleType")
            simple_type["name"] = name

            attributes.each { |k, v| simple_type[k.to_s] = v.to_s }
            @root_element.add_child(simple_type)
            simple_type
          end

          # Add restriction to a simple type
          def add_restriction(parent, base:)
            restriction = @xml_doc.create_element("xs:restriction")
            restriction["base"] = base
            parent.add_child(restriction)
            restriction
          end

          # Add union to a simple type
          def add_union(parent, member_types:)
            union = @xml_doc.create_element("xs:union")
            union["memberTypes"] = member_types
            parent.add_child(union)
            union
          end

          # Add enumeration value to a restriction
          def add_enumeration(parent, value:)
            enumeration = @xml_doc.create_element("xs:enumeration")
            enumeration["value"] = value
            parent.add_child(enumeration)
            enumeration
          end

          # Add pattern to a restriction
          def add_pattern(parent, value:)
            pattern = @xml_doc.create_element("xs:pattern")
            pattern["value"] = value
            parent.add_child(pattern)
            pattern
          end

          # Add standard GML import that's always needed
          def add_standard_imports
            # GML 3.2 is the standard for geometric types
            add_import(
              namespace: "http://www.opengis.net/gml/3.2",
              location: "http://schemas.opengis.net/gml/3.2.1/gml.xsd"
            )
          end

          # Scan document for referenced namespaces and add imports
          def add_required_namespace_imports(config)
            # Extract all namespace prefixes referenced in the document
            referenced_prefixes = extract_referenced_prefixes

            # For each referenced prefix, find its namespace and add import
            referenced_prefixes.each do |prefix_name|
              next if prefix_name == 'xs' # Skip XML Schema namespace
              next if prefix_name == @prefix # Skip target namespace

              # Find namespace info from config
              ns_info = config.xml_namespaces.find { |ns| ns.nsabr&.strip == prefix_name }
              next unless ns_info

              # Add import for this namespace
              add_import(
                namespace: ns_info.ns,
                location: ns_info.location
              )
            end
          end

          # Convert to XML string
          def to_xml
            @xml_doc.to_xml(indent: 2)
          end

          private

          # Extract all namespace prefixes referenced in type and ref attributes
          def extract_referenced_prefixes
            prefixes = Set.new

            # Scan all type attributes (e.g., type="gml:CodeType")
            @root_element.xpath(".//@type").each do |attr|
              type_value = attr.value
              if type_value.include?(':')
                prefix_name = type_value.split(':').first
                prefixes << prefix_name
              end
            end

            # Scan all ref attributes (e.g., ref="gml:AbstractFeature")
            @root_element.xpath(".//@ref").each do |attr|
              ref_value = attr.value
              if ref_value.include?(':')
                prefix_name = ref_value.split(':').first
                prefixes << prefix_name
              end
            end

            # Scan all base attributes in extensions (e.g., base="gml:AbstractFeatureType")
            @root_element.xpath(".//@base").each do |attr|
              base_value = attr.value
              if base_value.include?(':')
                prefix_name = base_value.split(':').first
                prefixes << prefix_name
              end
            end

            # Scan all substitutionGroup attributes
            @root_element.xpath(".//@substitutionGroup").each do |attr|
              sub_value = attr.value
              if sub_value.include?(':')
                prefix_name = sub_value.split(':').first
                prefixes << prefix_name
              end
            end

            prefixes.to_a
          end
        end
      end
    end
  end
end