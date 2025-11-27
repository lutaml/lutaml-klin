# frozen_string_literal: true

require_relative "schema_selector"

module Lutaml
  module Klin
    module Shapechange
      # Selects classes for XSD generation based on ShapeChange configuration
      # Implements the logic from ShapeChange's ClassSelector.java
      class ClassSelector
        attr_reader :schema_selector, :uml_repository

        def initialize(schema_selector, uml_repository)
          @schema_selector = schema_selector
          @uml_repository = uml_repository
        end

        # Select all classes for a package that should be included in XSD
        # @param package_name [String] Package name
        # @return [Array] List of UML classes to process
        def select_classes_for_package(package_name)
          # Check if this package's schema is selected
          return [] unless schema_selector.selected_schema?(package_name)

          # Get ALL classes from UML repository for this package
          # This is the key difference from ReferenceClasses hack:
          # We trust the UML model, not hardcoded lists
          uml_repository.classes_in_package(package_name)

          # ShapeChange applies name and stereotype filters here,
          # but for now we return all classes from selected schemas
          # Future: Add namePattern and stereotypePattern support
          
        end

        # Alternative method that accepts config directly
        # @param config [ShapeChangeConfiguration] Configuration object
        # @param uml_repository [Object] UML repository
        # @param package_name [String] Package name
        # @return [Array] List of UML classes to process
        def self.select_classes(config, uml_repository, package_name)
          selector = SchemaSelector.new(config)
          new(selector, uml_repository).select_classes_for_package(package_name)
        end
      end
    end
  end
end