# frozen_string_literal: true

require_relative "base_rule_processor"
require "yaml"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Generates PLATEAU ADE hook elements for CityGML integration
        # Implements rule-xsd-cls-plateau-ade-hooks
        #
        # Replicates VBA post-processing that adds substitution group
        # elements for URO/URF attributes to extend CityGML base types.
        #
        # @example Generated output
        #   <xs:element name="bldgDataQualityAttribute"
        #               type="uro:DataQualityAttributePropertyType"
        #               substitutionGroup="bldg:_GenericApplicationPropertyOfAbstractBuilding"/>
        class PlateauAdeHooksProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-cls-plateau-ade-hooks"

          def initialize(rule_checker, config)
            super
            @ade_mappings = load_ade_mappings
            @imported_namespaces = Set.new
          end

          protected

          def apply_rule(uml_class, context)
            # Find all ADE hook mappings for this class
            hooks = @ade_mappings[uml_class.name]
            return unless hooks&.any?

            xsd_doc = context[:xsd_document]
            prefix = context[:prefix]

            # Generate hook element for each mapping
            hooks.each do |hook|
              add_ade_hook_element(xsd_doc, prefix, uml_class, hook)
              ensure_citygml_import(xsd_doc, hook)
            end
          end

          private

          def add_ade_hook_element(xsd_doc, prefix, uml_class, hook)
            # Determine the type to use
            element_type = hook[:type_override] || "#{prefix}:#{uml_class.name}PropertyType"

            # Add global element with substitutionGroup
            xsd_doc.add_element(
              name: hook[:element_name],
              type: element_type,
              substitutionGroup: substitution_group_ref(hook)
            )
          end

          def substitution_group_ref(hook)
            "#{hook[:citygml_prefix]}:_GenericApplicationPropertyOf#{hook[:citygml_base]}"
          end

          def ensure_citygml_import(xsd_doc, hook)
            namespace = hook[:citygml_namespace]
            return if @imported_namespaces.include?(namespace)

            # Add import for CityGML module
            xsd_doc.add_import(
              namespace: namespace,
              location: citygml_schema_location(hook[:citygml_prefix])
            )

            @imported_namespaces.add(namespace)
          end

          def citygml_schema_location(prefix)
            # Map CityGML module prefixes to schema locations
            locations = {
              "bldg" => "http://schemas.opengis.net/citygml/building/2.0/building.xsd",
              "brid" => "http://schemas.opengis.net/citygml/bridge/2.0/bridge.xsd",
              "tun" => "http://schemas.opengis.net/citygml/tunnel/2.0/tunnel.xsd",
              "luse" => "http://schemas.opengis.net/citygml/landuse/2.0/landUse.xsd",
              "wtr" => "http://schemas.opengis.net/citygml/waterbody/2.0/waterBody.xsd",
              "frn" => "http://schemas.opengis.net/citygml/cityfurniture/2.0/cityFurniture.xsd",
              "tran" => "http://schemas.opengis.net/citygml/transportation/2.0/transportation.xsd",
              "veg" => "http://schemas.opengis.net/citygml/vegetation/2.0/vegetation.xsd",
              "grp" => "http://schemas.opengis.net/citygml/cityobjectgroup/2.0/cityObjectGroup.xsd",
              "dem" => "http://schemas.opengis.net/citygml/relief/2.0/relief.xsd",
              "core" => "http://schemas.opengis.net/citygml/2.0/cityGMLBase.xsd"
            }

            locations[prefix] || raise("Unknown CityGML prefix: #{prefix}")
          end

          def load_ade_mappings
            config_file = File.expand_path(
              "../../../../../config/plateau_ade_mappings.yml",
              __dir__
            )

            return {} unless File.exist?(config_file)

            data = YAML.load_file(config_file)

            # Group by class name for quick lookup
            # A single class can have multiple hook elements
            data["ade_hooks"].each_with_object(Hash.new do |h, k|
              h[k] = []
            end) do |hook, hash|
              hash[hook["class"]] << {
                element_name: hook["element_name"],
                citygml_prefix: hook["citygml_prefix"],
                citygml_base: hook["citygml_base"],
                citygml_namespace: hook["citygml_namespace"],
                type_override: hook["type_override"]
              }
            end
          end
        end
      end
    end
  end
end
