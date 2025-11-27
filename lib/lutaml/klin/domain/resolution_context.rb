# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      # Immutable context object containing all resources needed for type
      # resolution.
      #
      # A ResolutionContext bundles together the various repositories and
      # configurations that resolution strategies need to perform their work.
      # This provides a clean way to pass dependencies without polluting
      # method signatures.
      #
      # This is an immutable value object - all attributes are read-only and
      # set at construction time.
      #
      # @example Creating a context
      #   context = ResolutionContext.new(
      #     xsd_repository: schema_repo,
      #     shapechange_config: config,
      #     type_overrides: { "CharacterString" => "xs:string" }
      #   )
      #
      # @example Using context in a strategy
      #   if context.type_overrides.key?(uml_element.type)
      #     override_type = context.type_overrides[uml_element.type]
      #     # ... resolve using override
      #   end
      class ResolutionContext
        # @return [SchemaRepositoryAdapter] The XSD repository for type
        #   lookups
        attr_reader :xsd_repository

        # @return [Object] The ShapeChange configuration containing type
        #   mappings
        attr_reader :shapechange_config

        # @return [Hash<String, String>] Type override mappings from UML type
        #   to XSD type
        attr_reader :type_overrides

        # @return [UmlRepositoryAdapter, nil] The UML repository for class
        #   lookups
        attr_reader :uml_repository

        # Initialize a new resolution context.
        #
        # @param xsd_repository [SchemaRepositoryAdapter] XSD repository for
        #   type lookups
        # @param shapechange_config [Object] ShapeChange configuration with
        #   type mappings
        # @param type_overrides [Hash<String, String>] Type override mappings
        #   (default: {})
        #
        # @raise [ArgumentError] if xsd_repository is nil
        # @raise [ArgumentError] if shapechange_config is nil
        #
        # @example
        #   context = ResolutionContext.new(
        #     xsd_repository: schema_repo,
        #     shapechange_config: config,
        #     type_overrides: { "CharacterString" => "xs:string" }
        #   )
        def initialize(xsd_repository:, shapechange_config:,
                       type_overrides: {}, uml_repository: nil)
          raise ArgumentError, "xsd_repository is required" if
            xsd_repository.nil?
          raise ArgumentError, "shapechange_config is required" if
            shapechange_config.nil?

          @xsd_repository = xsd_repository
          @shapechange_config = shapechange_config
          @type_overrides = type_overrides.freeze
          @uml_repository = uml_repository
          freeze
        end

        # Check if a type override exists for the given type.
        #
        # @param type_name [String] The UML type name to check
        # @return [Boolean] true if an override exists
        #
        # @example
        #   context.has_type_override?("CharacterString") # => true
        def has_type_override?(type_name)
          type_overrides.key?(type_name)
        end

        # Get the override type for a given UML type.
        #
        # @param type_name [String] The UML type name
        # @return [String, nil] The override XSD type, or nil if not found
        #
        # @example
        #   context.get_type_override("CharacterString") # => "xs:string"
        def get_type_override(type_name)
          type_overrides[type_name]
        end

        # Returns a detailed inspection string for debugging.
        #
        # @return [String] Context information
        def inspect
          "#<#{self.class.name} " \
            "xsd_repository=#{xsd_repository.class.name} " \
            "shapechange_config=#{shapechange_config.class.name} " \
            "type_overrides=#{type_overrides.keys.size} mappings>"
        end

        # Returns a human-readable description of the context.
        #
        # @return [String] Description of the context
        def to_s
          "ResolutionContext with #{type_overrides.keys.size} type overrides"
        end
      end
    end
  end
end
