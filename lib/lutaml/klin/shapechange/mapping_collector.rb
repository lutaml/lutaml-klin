# frozen_string_literal: true

require_relative "../models/mapping/schema_mapping"
require_relative "../models/mapping/package_mapping"
require_relative "../models/mapping/class_mapping"
require_relative "../models/mapping/attribute_mapping"
require_relative "../models/mapping/transformation_info"

module Lutaml
  module Klin
    module Shapechange
      # Collects UML→XSD transformation data during XSD generation
      # Follows passive observer pattern - records without interfering
      #
      # Design Principles:
      # - Single Responsibility: Only collects transformation data
      # - DRY: Delegates to lutaml-model classes for structure
      # - MECE: Each transformation aspect tracked once
      # - OOP: Proper encapsulation and composition
      class MappingCollector
        attr_reader :package_name, :package_namespace, :package_prefix, :config, :lur_path, :config_path

        def initialize(
          package_name:,
          package_namespace:,
          package_prefix:,
          config:,
          lur_path: nil,
          config_path: nil
        )
          @package_name = package_name
          @package_namespace = package_namespace
          @package_prefix = package_prefix
          @config = config
          @lur_path = lur_path
          @config_path = config_path

          # Collection state
          @class_mappings = []
          @current_class_mapping = nil
        end

        # Record a class-level transformation
        #
        # @param uml_class [Lutaml::Uml::Class] UML class being transformed
        # @param xsd_element_name [String] XSD element name generated
        # @param xsd_type_name [String] XSD type name generated
        # @param xsd_element_substitution_group [String] Substitution group (optional)
        # @param xsd_type_base [String] Base type for extension (optional)
        # @param rules_applied [Array<String>] Rules applied
        # @param context [Hash] Additional context
        def record_class_mapping(
          uml_class:,
          xsd_element_name: nil,
          xsd_type_name: nil,
          xsd_element_substitution_group: nil,
          xsd_type_base: nil,
          rules_applied: [],
          context: {}
        )
          # Create ClassMapping
          class_mapping = build_class_mapping(
            uml_class,
            xsd_element_name,
            xsd_type_name,
            xsd_element_substitution_group,
            xsd_type_base
          )

          # Create TransformationInfo
          transformation_info = build_transformation_info(
            rules_applied: rules_applied,
            context: context,
            uml_class: uml_class
          )

          class_mapping.transformation_info = transformation_info
          class_mapping.resolution_status = "resolved" # XSD generation = resolved

          # Store mapping and set as current
          @class_mappings << class_mapping
          @current_class_mapping = class_mapping
        end

        # Record an attribute-level transformation
        #
        # @param uml_attribute [Lutaml::Uml::Attribute] UML attribute
        # @param xsd_property_name [String] XSD property name
        # @param xsd_property_type [String] XSD property type
        # @param xsd_min_occurs [String] Min occurs constraint
        # @param xsd_max_occurs [String] Max occurs constraint
        # @param type_mapping_info [Hash] Type mapping metadata
        # @param rules_applied [Array<String>] Rules applied
        # @param context [Hash] Additional context
        def record_attribute_mapping(
          uml_attribute:,
          xsd_property_name:,
          xsd_property_type:,
          xsd_min_occurs: nil,
          xsd_max_occurs: nil,
          type_mapping_info: nil,
          rules_applied: [],
          context: {}
        )
          return unless @current_class_mapping

          # Create AttributeMapping
          attr_mapping = build_attribute_mapping(
            uml_attribute,
            xsd_property_name,
            xsd_property_type,
            xsd_min_occurs,
            xsd_max_occurs
          )

          # Create TransformationInfo
          transformation_info = build_transformation_info(
            rules_applied: rules_applied,
            context: context,
            type_mapping: type_mapping_info
          )

          attr_mapping.transformation_info = transformation_info
          attr_mapping.resolution_status = "resolved" # XSD generation = resolved

          # Add to current class
          @current_class_mapping.attribute_mappings ||= []
          @current_class_mapping.attribute_mappings << attr_mapping
        end

        # Get current class being processed (for attribute mappings)
        #
        # @return [ClassMapping, nil] Current class or nil
        attr_reader :current_class_mapping

        # Generate statistics for this package
        #
        # @return [Hash] Statistics hash
        def generate_statistics
          total_classes = @class_mappings.size
          total_attributes = @class_mappings.sum do |cm|
            cm.attribute_mappings&.size || 0
          end

          # Count rules applied
          rules_count = {}
          @class_mappings.each do |cm|
            next unless cm.transformation_info

            cm.transformation_info.rules_applied&.each do |rule|
              rules_count[rule] ||= 0
              rules_count[rule] += 1
            end

            cm.attribute_mappings&.each do |am|
              next unless am.transformation_info

              am.transformation_info.rules_applied&.each do |rule|
                rules_count[rule] ||= 0
                rules_count[rule] += 1
              end
            end
          end

          {
            "total_classes" => total_classes,
            "total_attributes" => total_attributes,
            "resolution_success_rate" => 1.0, # XSD generation = 100%
            "rules_applied" => rules_count
          }
        end

        # Convert collected data to SchemaMapping model
        #
        # @return [Mapping::SchemaMapping] Complete schema mapping
        def to_schema_mapping
          # Create PackageMapping
          package_mapping = Mapping::PackageMapping.new
          package_mapping.uml_name = @package_name
          package_mapping.uml_package_name = @package_name
          package_mapping.xsd_namespace = @package_namespace
          package_mapping.xsd_namespace_prefix = @package_prefix
          package_mapping.class_mappings = @class_mappings
          package_mapping.created_at = Time.now.utc.iso8601
          package_mapping.resolution_statistics = generate_statistics.to_yaml

          # Create SchemaMapping
          schema_mapping = Mapping::SchemaMapping.new
          schema_mapping.version = "1.0"
          schema_mapping.generated_at = Time.now.utc.iso8601
          schema_mapping.source_lur = @lur_path
          schema_mapping.source_config = @config_path
          schema_mapping.package_mappings = [package_mapping]
          schema_mapping.namespaces = [@package_namespace].compact

          schema_mapping
        end

        # Serialize to YAML using lutaml-model
        #
        # @return [String] YAML representation
        def to_yaml
          to_schema_mapping.to_yaml
        end

        private

        # Build ClassMapping from UML class and XSD names
        def build_class_mapping(
          uml_class,
          xsd_element_name,
          xsd_type_name,
          xsd_substitution_group,
          xsd_type_base
        )
          mapping = Mapping::ClassMapping.new
          mapping.uml_name = uml_class.name
          mapping.uml_qualified_name = uml_class.xmi_id || uml_class.name
          mapping.uml_stereotype = uml_class.stereotype
          
          # Get documentation if available
          mapping.uml_documentation = if uml_class.respond_to?(:documentation)
                                        uml_class.documentation
                                      end
          
          mapping.stereotypes = [uml_class.stereotype].compact

          mapping.xsd_element_name = xsd_element_name
          mapping.xsd_type_name = xsd_type_name
          mapping.xsd_type = xsd_type_name # Same as type_name for XSD generation
          mapping.xsd_namespace = @package_namespace

          # Store XSD-specific metadata in xsd_documentation (temporary)
          metadata_parts = []
          if xsd_substitution_group
            metadata_parts << "substitutionGroup: #{xsd_substitution_group}"
          end
          metadata_parts << "base: #{xsd_type_base}" if xsd_type_base
          mapping.xsd_documentation = metadata_parts.join(", ") unless metadata_parts.empty?

          mapping.attribute_mappings = []
          mapping
        end

        # Build AttributeMapping from UML attribute and XSD property
        def build_attribute_mapping(
          uml_attribute,
          xsd_property_name,
          xsd_property_type,
          xsd_min_occurs,
          xsd_max_occurs
        )
          mapping = Mapping::AttributeMapping.new
          mapping.uml_name = uml_attribute.name
          mapping.uml_type = if uml_attribute.type.respond_to?(:name)
                               uml_attribute.type.name
                             else
                               uml_attribute.type.to_s
                             end
          
          # Get documentation if available
          mapping.uml_documentation = if uml_attribute.respond_to?(:documentation)
                                        uml_attribute.documentation
                                      end

          # Extract multiplicity from UML attribute
          if uml_attribute.respond_to?(:cardinality)
            mapping.uml_multiplicity = format_multiplicity(uml_attribute.cardinality)
          end

          mapping.xsd_name = xsd_property_name
          mapping.xsd_type = xsd_property_type
          mapping.xsd_min_occurs = xsd_min_occurs
          mapping.xsd_max_occurs = xsd_max_occurs
          mapping.namespace = @package_namespace

          mapping
        end

        # Build TransformationInfo from context
        def build_transformation_info(
          rules_applied:,
          context:,
          uml_class: nil,
          type_mapping: nil
        )
          info = Mapping::TransformationInfo.new
          info.rules_applied = rules_applied.compact

          # Extract encoding rule from context or config
          info.encoding_rule = context[:encoding_rule] || @config&.encoding_rule

          # Extract flags from context
          info.has_property_type = context[:has_property_type] || false
          info.is_abstract = context[:is_abstract] || false
          info.is_substitutable = context[:is_substitutable] || false

          # Type mapping info
          if type_mapping
            info.type_mapping_source = type_mapping[:source]
            info.type_mapping_description = type_mapping[:description]
          end

          # Store additional metadata
          metadata = {}
          metadata[:stereotype] = uml_class.stereotype if uml_class
          metadata[:substitution_group] = context[:substitution_group] if context[:substitution_group]
          metadata[:base_type] = context[:base_type] if context[:base_type]
          info.metadata_hash = metadata unless metadata.empty?

          info
        end

        # Format UML cardinality to multiplicity string
        def format_multiplicity(cardinality)
          return "0..1" unless cardinality

          # Handle both hash-like and object-like cardinality
          min = if cardinality.respond_to?(:min)
                  cardinality.min
                elsif cardinality.respond_to?(:[])
                  cardinality["min"] || cardinality[:min]
                else
                  0
                end

          max = if cardinality.respond_to?(:max)
                  cardinality.max
                elsif cardinality.respond_to?(:[])
                  cardinality["max"] || cardinality[:max]
                end

          if max.nil? || max == -1 || max == "*"
            "#{min}..*"
          elsif min.to_s == max.to_s
            min.to_s
          else
            "#{min}..#{max}"
          end
        end
      end
    end
  end
end