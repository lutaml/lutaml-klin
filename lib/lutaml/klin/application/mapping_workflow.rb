# frozen_string_literal: true

require "yaml"
require_relative "../models/mapping/schema_mapping"
require_relative "../models/mapping/package_mapping"
require_relative "../models/mapping/class_mapping"
require_relative "../models/mapping/attribute_mapping"
require_relative "../domain/services/mapping_service"
require_relative "../domain/services/transformation_analyzer"
require_relative "../domain/resolution_engine"
require_relative "../domain/resolution_context"
require_relative "../domain/strategies/type_override_strategy"
require_relative "../domain/strategies/shapechange_strategy"
require_relative "../domain/strategies/domain_type_strategy"
require_relative "../domain/strategies/schema_repository_strategy"

module Lutaml
  module Klin
    module Application
      # MappingWorkflow orchestrates the UML-to-XSD mapping generation process.
      #
      # This is the main application layer component that coordinates:
      # - Loading UML packages from LUR repository
      # - Resolving types using the Resolution Engine
      # - Building enhanced mapping models with full tracking
      # - Saving YAML output files
      #
      # The workflow follows these principles:
      # - **Pure orchestration** - no business logic here
      # - **Delegation** - business logic delegated to MappingService
      # - **I/O handling** - this layer handles all file operations
      # - **Error handling** - comprehensive error reporting
      #
      # @example Basic usage
      #   workflow = MappingWorkflow.new(
      #     uml_repository: uml_repo,
      #     xsd_repository: xsd_repo,
      #     shapechange_config: config,
      #     type_overrides: {"OldType" => "NewType"}
      #   )
      #
      #   mapping = workflow.generate_mapping_for_package("ModelRoot::Core")
      #   workflow.save_mapping(mapping, "output.yaml")
      #
      # @example Multiple packages
      #   mappings = workflow.generate_mappings_for_packages([
      #     "ModelRoot::Core",
      #     "ModelRoot::Extensions"
      #   ])
      #   workflow.save_mapping(mappings, "complete_mapping.yaml")
      class MappingWorkflow
        # @return [UmlRepositoryAdapter] The UML repository adapter
        attr_reader :uml_repository

        # @return [SchemaRepositoryAdapter] The XSD repository adapter
        attr_reader :xsd_repository

        # @return [Object] The ShapeChange configuration
        attr_reader :shapechange_config

        # @return [Hash] Type override mappings
        attr_reader :type_overrides

        # @return [ResolutionEngine] The resolution engine
        attr_reader :resolution_engine

        # @return [MappingService] The mapping service
        attr_reader :mapping_service

        # @return [TransformationAnalyzer] The transformation analyzer
        attr_reader :transformation_analyzer

        # Initialize the mapping workflow
        #
        # @param uml_repository [UmlRepositoryAdapter] UML repository adapter
        # @param xsd_repository [SchemaRepositoryAdapter] XSD repository adapter
        # @param shapechange_config [Object] ShapeChange configuration object
        # @param type_overrides [Hash] Type override mappings
        #   (UML type => XSD type)
        #
        # @raise [ArgumentError] if required parameters are missing
        def initialize(uml_repository:, xsd_repository:,
                       shapechange_config:, type_overrides: {})
          raise ArgumentError, "uml_repository is required" if
            uml_repository.nil?
          raise ArgumentError, "xsd_repository is required" if
            xsd_repository.nil?
          raise ArgumentError, "shapechange_config is required" if
            shapechange_config.nil?

          @uml_repository = uml_repository
          @xsd_repository = xsd_repository
          @shapechange_config = shapechange_config
          @type_overrides = type_overrides || {}

          # Create transformation analyzer
          @transformation_analyzer = Domain::Services::TransformationAnalyzer.new(
            shapechange_config
          )

          # Build resolution engine with strategies
          @resolution_engine = build_resolution_engine

          # Initialize mapping service WITH analyzer
          @mapping_service = Domain::Services::MappingService.new(
            @resolution_engine,
            @transformation_analyzer
          )
        end

        # Generate mapping for a single UML package
        #
        # This method:
        # 1. Finds the UML package
        # 2. Determines the XSD namespace
        # 3. Gets all classes in the package
        # 4. Maps each class with its attributes
        # 5. Returns a PackageMapping model
        #
        # @param package_path [String] UML package path (e.g.,
        #   "ModelRoot::Core::Building")
        # @param recursive [Boolean] Whether to include subpackages
        # @param verbose [Boolean] Enable verbose output
        # @param progress_callback [Proc] Optional progress callback
        # @return [Mapping::PackageMapping] The package mapping
        #
        # @raise [RuntimeError] if package not found
        # @raise [RuntimeError] if namespace cannot be determined
        def generate_mapping_for_package(package_path, recursive: false, verbose: false, progress_callback: nil)
          # 1. Find UML package
          uml_package = uml_repository.find_package(package_path)
          raise "Package not found: #{package_path}" if uml_package.nil?

          # 2. Determine XSD namespace from ShapeChange config
          xsd_namespace = determine_xsd_namespace(uml_package)

          # 3. Get all classes in package
          uml_classes = uml_repository.classes_in_package(
            package_path,
            recursive: recursive
          )

          if verbose
            progress_callback&.call(:mapping, "\nProcessing package: #{package_path}")
            progress_callback&.call(:mapping, "  Found #{uml_classes.size} classes")
          end

          # 4. Map each class
          class_mappings = uml_classes.map.with_index do |uml_class, idx|
            if verbose
              progress_callback&.call(:mapping, "\n[#{idx + 1}/#{uml_classes.size}] Processing class: #{uml_class.name}")
            end
            build_class_mapping(uml_class, xsd_namespace, verbose: verbose, progress_callback: progress_callback)
          end

          # 5. Build and return PackageMapping
          Mapping::PackageMapping.new.tap do |pkg_mapping|
            pkg_mapping.uml_name = uml_package.name
            pkg_mapping.uml_package_name = package_path
            pkg_mapping.xsd_namespace = xsd_namespace
            pkg_mapping.xsd_namespace_prefix = extract_namespace_prefix(
              xsd_namespace
            )
            pkg_mapping.class_mappings = class_mappings
            pkg_mapping.created_at = Time.now.utc.iso8601
            pkg_mapping.resolution_statistics =
              pkg_mapping.calculate_statistics.to_yaml
          end
        end

        # Generate mappings for multiple UML packages
        #
        # @param package_paths [Array<String>] List of UML package paths
        # @param recursive [Boolean] Whether to include subpackages
        # @param verbose [Boolean] Enable verbose output
        # @return [Mapping::SchemaMapping] The complete schema mapping
        def generate_mappings_for_packages(package_paths, recursive: false, verbose: false)
          package_mappings = package_paths.map.with_index do |path, idx|
            if verbose
              progress_callback = ->(stage, msg) {
                puts "[#{Time.now.strftime('%H:%M:%S')}] #{msg}" if stage == :mapping
              }
            end

            generate_mapping_for_package(path, recursive: recursive, verbose: verbose, progress_callback: progress_callback)
          end

          Mapping::SchemaMapping.new.tap do |schema_mapping|
            schema_mapping.version = "1.0"
            schema_mapping.package_mappings = package_mappings
            schema_mapping.set_timestamp!

            # Extract unique namespaces
            schema_mapping.namespaces = package_mappings
              .map(&:xsd_namespace)
              .compact
              .uniq
          end
        end

        # Save mapping to YAML file
        #
        # @param mapping [Mapping::SchemaMapping, Mapping::PackageMapping]
        #   The mapping to save
        # @param output_path [String] Path to output YAML file
        #
        # @raise [RuntimeError] if save fails
        def save_mapping(mapping, output_path)
          yaml_content = mapping.to_yaml

          File.write(output_path, yaml_content)
        rescue StandardError => e
          raise "Failed to save mapping to '#{output_path}': #{e.message}"
        end

        private

        # Build the resolution engine with all strategies
        #
        # Strategies are ordered by priority:
        # 1. Type overrides (highest priority)
        # 2. ShapeChange mappings
        # 3. Schema repository lookups (lowest priority)
        #
        # @return [ResolutionEngine] Configured resolution engine
        def build_resolution_engine
          strategies = []

          # 1. Type override strategy (if overrides provided)
          unless type_overrides.empty?
            strategies << Domain::Strategies::TypeOverrideStrategy.new
          end

          # 2. ShapeChange mapping strategy (standard types)
          strategies << Domain::Strategies::ShapeChangeMappingStrategy.new

          # 3. Domain type strategy (custom UML classes)
          strategies << Domain::Strategies::DomainTypeStrategy.new

          # 4. Schema repository strategy
          strategies << Domain::Strategies::SchemaRepositoryStrategy.new

          Domain::ResolutionEngine.new(strategies)
        end

        # Build a ClassMapping from a UML class
        #
        # @param uml_class [Object] UML class object
        # @param xsd_namespace [String] Target XSD namespace
        # @param verbose [Boolean] Enable verbose output
        # @param progress_callback [Proc] Optional progress callback
        # @return [Mapping::ClassMapping] The class mapping
        def build_class_mapping(uml_class, xsd_namespace, verbose: false, progress_callback: nil)
          # Report progress for verbose mode
          if verbose
            progress_callback&.call(:mapping, "Processing class: #{uml_class.name} (#{uml_class.stereotype})")
          end

          # Create resolution context
          context = Domain::ResolutionContext.new(
            xsd_repository: xsd_repository,
            shapechange_config: shapechange_config,
            type_overrides: type_overrides,
            uml_repository: uml_repository
          )

          # Use mapping service to map class
          class_details = mapping_service.map_class_to_xsd(
            uml_class,
            xsd_namespace,
            context
          )

          # Map attributes with verbose output
          attribute_mappings = (uml_class.attributes || []).map.with_index do |attr, idx|
            if verbose
              progress_callback&.call(:mapping, "  [#{idx + 1}/#{uml_class.attributes.size}] Attribute: #{attr.name}")
            end
            build_attribute_mapping(attr, context, verbose: verbose, progress_callback: progress_callback)
          end

          # Build ClassMapping model
          Mapping::ClassMapping.new.tap do |cm|
            cm.uml_name = class_details[:uml_name]
            cm.uml_qualified_name = class_details[:uml_qualified_name]
            cm.uml_stereotype = class_details[:uml_stereotype]
            cm.uml_documentation = class_details[:uml_documentation]
            cm.xsd_namespace = class_details[:xsd_namespace]
            cm.xsd_element_name = class_details[:xsd_element_name]
            cm.xsd_type_name = class_details[:xsd_type_name]
            cm.xsd_documentation = class_details[:xsd_documentation]
            cm.resolution_status = class_details[:resolution_status]
            cm.resolution_method = class_details[:resolution_method]
            cm.resolution_confidence = class_details[:resolution_confidence]
            cm.attribute_mappings = attribute_mappings
          end
        end

        # Build an AttributeMapping from a UML attribute
        #
        # @param uml_attribute [Object] UML attribute object
        # @param context [ResolutionContext] Resolution context
        # @param verbose [Boolean] Enable verbose output
        # @param progress_callback [Proc] Optional progress callback
        # @return [Mapping::AttributeMapping] The attribute mapping
        def build_attribute_mapping(uml_attribute, context, verbose: false, progress_callback: nil)
          # Use mapping service to map attribute
          attr_details = mapping_service.map_attribute_to_xsd(
            uml_attribute,
            context
          )

          # Show resolution details in verbose mode
          if verbose && progress_callback
            status = attr_details[:resolution_status] == :resolved ? "✓" : "✗"
            method = attr_details[:resolution_method] || "none"
            confidence = attr_details[:resolution_confidence] ? "(#{(attr_details[:resolution_confidence] * 100).round(1)}%)" : ""

            progress_callback&.call(:mapping, "    #{status} #{method} #{confidence}")
          end

          # Build AttributeMapping model
          Mapping::AttributeMapping.new.tap do |am|
            am.uml_name = attr_details[:uml_name]
            am.uml_type = attr_details[:uml_type]
            am.uml_documentation = attr_details[:uml_documentation]
            am.uml_multiplicity = attr_details[:uml_multiplicity]
            am.xsd_name = attr_details[:xsd_name]
            am.xsd_type = attr_details[:xsd_type]
            am.xsd_documentation = attr_details[:xsd_documentation]
            am.xsd_min_occurs = attr_details[:xsd_min_occurs]
            am.xsd_max_occurs = attr_details[:xsd_max_occurs]
            am.resolution_status = attr_details[:resolution_status]
            am.resolution_method = attr_details[:resolution_method]
            am.resolution_error = attr_details[:resolution_error]
          end
        end

        # Determine XSD namespace for a UML package
        #
        # Looks up namespace mapping in ShapeChange configuration.
        #
        # @param uml_package [Object] UML package object
        # @return [String] XSD namespace URI
        #
        # @raise [RuntimeError] if namespace cannot be determined
        def determine_xsd_namespace(uml_package)
          # Get package name - try qualified_name first, fall back to name
          package_path = if uml_package.respond_to?(:qualified_name)
            uml_package.qualified_name
          else
            uml_package.name
          end

          # Get namespace from ShapeChange config
          namespace = shapechange_config.namespace_for_package(package_path)

          if namespace.nil? || namespace.empty?
            raise "Cannot determine XSD namespace for package: #{package_path}"
          end

          namespace
        rescue StandardError => e
          # Fallback namespace
          "http://example.org/#{uml_package.name.downcase}"
        end

        # Extract namespace prefix from XSD namespace URI
        #
        # @param namespace [String] XSD namespace URI
        # @return [String, nil] Namespace prefix or nil
        def extract_namespace_prefix(namespace)
          # Try to get prefix from ShapeChange config
          shapechange_config.prefix_for_namespace(namespace)
        rescue NoMethodError
          # Fallback: derive from namespace URI
          derive_prefix_from_namespace(namespace)
        end

        # Derive a namespace prefix from namespace URI
        #
        # @param namespace [String] XSD namespace URI
        # @return [String] Derived prefix
        def derive_prefix_from_namespace(namespace)
          # Extract last path segment as prefix
          # e.g., "http://www.opengis.net/gml/3.2" => "gml"
          return nil if namespace.nil? || namespace.empty?

          parts = namespace.split("/").reject(&:empty?)
          return nil if parts.empty?

          # Try to find a meaningful part (not http, www, numbers, etc.)
          prefix = parts.reverse.find do |part|
            !part.match?(/^(http|https|www|\d+(\.\d+)*)$/)
          end

          prefix&.downcase
        end
      end
    end
  end
end