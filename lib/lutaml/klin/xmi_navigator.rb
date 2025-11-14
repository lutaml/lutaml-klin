require "lutaml"
require_relative "models/uml/package"
require_relative "models/uml/class"
require_relative "models/uml/attribute"
require_relative "models/uml/association"

module Lutaml
  module Klin
    # Navigate UML models from XMI files using lutaml
    class XmiNavigator
      class FatalError < StandardError; end

      attr_reader :document, :xmi_path

      def initialize(xmi_path = nil)
        @xmi_path = xmi_path
        @packages = {}
        @classes = {}
      end

      # Parse an XMI file and extract UML model
      # Returns self for chaining
      def parse_file(xmi_path = nil)
        path = xmi_path || @xmi_path
        raise FatalError, "XMI file path not provided" unless path
        raise FatalError, "XMI file not found: #{path}" unless File.exist?(path)

        @xmi_path = path
        # Lutaml::Parser.parse returns an Array of Documents
        documents = Lutaml::Parser.parse([File.new(path)])
        @document = documents.first
        extract_model_elements
        self
      end

      # Convenience method: parse the file if path was provided in constructor
      alias parse parse_file

      # Find a package by name
      def find_package(name)
        @packages.values.find { |pkg| pkg.name == name }
      end

      # Find a class by name
      def find_class(name)
        @classes.values.find { |cls| cls.name == name }
      end

      # Get all packages as an array
      def packages
        @packages.values
      end

      # Get all classes as an array
      def classes
        @classes.values
      end

      # Get all classes in a package
      def classes_in_package(package_name)
        pkg = find_package(package_name)
        return [] unless pkg

        pkg.classes.map { |class_id| @classes[class_id] }.compact
      end

      private

      def extract_model_elements
        return unless @document

        extract_packages(@document)
        extract_classes(@document)
      end

      def extract_packages(doc)
        # doc is a Lutaml::Uml::Document object with packages attribute
        packages = doc.packages || []

        packages.each do |pkg_element|
          package = create_package_from_element(pkg_element)
          @packages[package.id] = package

          # Recursively extract nested packages
          extract_nested_packages(pkg_element, package)
        end
      end

      def extract_nested_packages(parent_element, parent_package)
        # lutaml packages have a packages attribute for nested packages
        nested = parent_element.packages || []

        nested.each do |element|
          nested_pkg = create_package_from_element(element)
          parent_package.sub_packages << nested_pkg
          @packages[nested_pkg.id] = nested_pkg

          extract_nested_packages(element, nested_pkg)
        end
      end

      def create_package_from_element(element)
        pkg = Models::Uml::Package.new
        pkg.id = element.xmi_id || element.id
        pkg.name = element.name
        pkg.stereotype = element.respond_to?(:stereotype) ? element.stereotype : nil
        pkg.classes = []
        pkg.sub_packages = []
        pkg
      end

      def extract_classes(doc)
        # Extract classes from the document and all packages
        # Document may have top-level classes
        extract_classes_from_collection(doc.classes || [], nil)

        # Extract classes from packages
        doc.packages.each do |pkg_element|
          extract_classes_from_package_element(pkg_element)
        end
      end

      def extract_classes_from_package_element(pkg_element)
        # Find the package in our registry
        package = @packages[pkg_element.xmi_id || pkg_element.id]
        return unless package

        # Extract classes from this package
        extract_classes_from_collection(pkg_element.classes || [], package.id)

        # Recursively extract from nested packages
        (pkg_element.packages || []).each do |nested_pkg|
          extract_classes_from_package_element(nested_pkg)
        end
      end

      def extract_classes_from_collection(classes_collection, package_id)
        classes_collection.each do |class_element|
          uml_class = create_class_from_element(class_element, package_id)
          @classes[uml_class.id] = uml_class

          # Add to package's class list if package exists
          if package_id && @packages[package_id]
            @packages[package_id].classes << uml_class.id
          end
        end
      end

      def create_class_from_element(element, package_id)
        cls = Models::Uml::Class.new
        cls.id = element.xmi_id || element.id
        cls.name = element.name
        cls.stereotype = element.respond_to?(:stereotype) ? element.stereotype : nil
        cls.package_id = package_id
        cls.is_abstract = element.respond_to?(:is_abstract) ? element.is_abstract : false
        cls.documentation = element.respond_to?(:definition) ? element.definition : nil

        extract_attributes(element, cls)
        extract_associations(element, cls)
        cls
      end

      def extract_attributes(element, uml_class)
        # lutaml classes have an attributes array
        attributes = element.attributes || []

        attributes.each do |attr_element|
          attribute = create_attribute_from_element(attr_element)
          uml_class.attributes << attribute
        end
      end

      def create_attribute_from_element(element)
        attr = Models::Uml::Attribute.new
        attr.id = element.xmi_id || element.id
        attr.name = element.name
        attr.type = element.respond_to?(:type) ? element.type : nil
        attr.type_id = nil  # Will be populated if needed
        attr.is_derived = element.respond_to?(:is_derived) ? element.is_derived : false
        attr.documentation = element.respond_to?(:definition) ? element.definition : nil

        # lutaml uses cardinality instead of multiplicity
        if element.respond_to?(:cardinality) && element.cardinality
          extract_cardinality(element.cardinality, attr)
        end
        attr
      end

      def extract_associations(element, uml_class)
        # Extract associations where this class is the source
        # This will be implemented based on lutaml-xmi's association handling
      end

      def extract_cardinality(cardinality, attribute)
        # cardinality is a Lutaml::Uml::Cardinality object
        # It has min and max attributes
        if cardinality.respond_to?(:min)
          attribute.multiplicity_min = cardinality.min.to_i
        end

        if cardinality.respond_to?(:max)
          max_val = cardinality.max
          attribute.multiplicity_max = max_val == "*" ? "*" : max_val.to_s
        end
      end

      def extract_type_name(element)
        return nil unless element.respond_to?(:type)

        type = element.type
        return nil unless type

        if type.respond_to?(:name)
          type.name
        elsif type.respond_to?(:href)
          # External type reference
          extract_name_from_href(type.href)
        else
          nil
        end
      end

      def extract_type_id(element)
        return nil unless element.respond_to?(:type)

        type = element.type
        return nil unless type

        type.respond_to?(:xmi_idref) ? type.xmi_idref : nil
      end

      def extract_stereotype(element)
        return nil unless element.respond_to?(:xmi_extension)

        extension = element.xmi_extension
        return nil unless extension

        # Extract stereotype from XMI extension
        # Implementation depends on how stereotypes are stored
        nil
      end

      def extract_documentation(element)
        return nil unless element.respond_to?(:owned_comment)

        comments = element.owned_comment || []
        comments.map(&:body).compact.join("\n")
      end

      def extract_name_from_href(href)
        # Extract type name from href like "pathmap://UML_LIBRARIES/..."
        href.split("#").last
      end

      def find_package_element(doc, package_id)
        # Recursively search for package element by ID
        find_element_by_id(doc, package_id)
      end

      def find_element_by_id(element, target_id)
        return element if element.respond_to?(:xmi_id) && element.xmi_id == target_id

        if element.respond_to?(:packaged_element)
          elements = element.packaged_element || []
          elements.each do |child|
            result = find_element_by_id(child, target_id)
            return result if result
          end
        end

        nil
      end
    end
  end
end
