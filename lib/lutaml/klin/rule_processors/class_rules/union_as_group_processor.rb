# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module ClassRules
        # Processes union types as xs:group references
        #
        # When a union type has the asGroup characteristic enabled, this processor
        # generates xs:group definitions that can be referenced by properties instead
        # of inline element definitions.
        #
        # @example Group Definition
        #   <xs:group name="GeometryUnionGroup">
        #     <xs:choice>
        #       <xs:element ref="gml:Point"/>
        #       <xs:element ref="gml:Curve"/>
        #     </xs:choice>
        #   </xs:group>
        #
        # @example Property Reference
        #   <xs:element name="geometry">
        #     <xs:group ref="prefix:GeometryUnionGroup"/>
        #   </xs:element>
        class UnionAsGroupProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-cls-union-asGroup"

          # Checks if this processor applies to the given class
          #
          # @param uml_class [Lutaml::Uml::Class] The UML class to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if class is a union with asGroup enabled
          def self.applies_to?(uml_class, config)
            return false unless config.rule_enabled?(RULE_NAME)
            return false unless uml_class.is_a?(Lutaml::Uml::Union)

            uml_class.as_group == true
          end

          # Processes a union class to generate xs:group definition
          #
          # @param uml_class [Lutaml::Uml::Union] The union class to process
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.process_class(uml_class, xsd_builder, config)
            group_name = "#{uml_class.name}Group"

            xsd_builder.add_group(group_name) do |group|
              # Add standard annotation with documentation
              if uml_class.definition
                group.add_annotation do |annotation|
                  annotation.add_documentation(uml_class.definition)
                end
              end

              # Create choice container for union options
              group.add_choice do |choice|
                # Add each union property as an element reference
                process_union_options(uml_class, choice, xsd_builder, config)
              end
            end
          end

          # Processes a property with union-as-group type
          #
          # @param property [Lutaml::Uml::Attribute] The property to process
          # @param parent_element [Object] Parent XSD element
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.process_property(property, parent_element, xsd_builder, config)
            type_class = xsd_builder.find_class(property.type)
            return unless applies_to?(type_class, config)

            # Verify package and namespace
            unless type_class.package&.xmlns
              xsd_builder.add_error(
                "Union class '#{type_class.name}' has no package or namespace",
                property
              )
              return
            end

            # Create group reference
            group_ref = "#{type_class.qualified_name}Group"

            parent_element.add_group_reference(group_ref) do |group_ref_element|
              # Add standard annotation
              if property.definition
                group_ref_element.add_annotation do |annotation|
                  annotation.add_documentation(property.definition)
                end
              end

              # Apply multiplicity
              apply_multiplicity(group_ref_element, property)

              # Add namespace import
              xsd_builder.add_import(
                type_class.package.xmlns,
                type_class.package.target_namespace
              )
            end
          end

          # Processes union options as element references
          #
          # @param union_class [Lutaml::Uml::Union] The union class
          # @param choice_element [Object] The choice container element
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.process_union_options(union_class, choice_element, xsd_builder, config)
            union_class.attributes.each do |option|
              option_class = xsd_builder.find_class(option.type)
              next unless option_class

              # Map to element reference
              element_ref = xsd_builder.map_to_element(option_class)
              next unless element_ref

              choice_element.add_element_reference(element_ref) do |elem_ref|
                # Add import for option type namespace
                if option_class.package
                  xsd_builder.add_import(
                    option_class.package.xmlns,
                    option_class.package.target_namespace
                  )
                end
              end
            end
          end

          # Applies multiplicity constraints to group reference
          #
          # @param element [Object] The group reference element
          # @param property [Lutaml::Uml::Attribute] The property
          # @return [void]
          def self.apply_multiplicity(element, property)
            return unless property.cardinality

            min_occurs = property.cardinality[:min] || 1
            max_occurs = property.cardinality[:max] || 1

            element.min_occurs = min_occurs unless min_occurs == 1

            if max_occurs == -1 || max_occurs == Float::INFINITY
              element.max_occurs = "unbounded"
            elsif max_occurs != 1
              element.max_occurs = max_occurs
            end
          end
        end
      end
    end
  end
end