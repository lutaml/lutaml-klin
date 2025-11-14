# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module ClassRules
        # Processes mixin classes as xs:group references
        #
        # Instead of inlining mixin properties, this processor references them
        # via xs:group elements, providing better modularity and reusability.
        #
        # @example Group Reference
        #   <xs:complexType name="BuildingType">
        #     <xs:sequence>
        #       <xs:group ref="prefix:IdentifiableGroup"/>
        #       <xs:element name="buildingType" type="xs:string"/>
        #     </xs:sequence>
        #   </xs:complexType>
        #
        # @example Mixin Group Definition
        #   <xs:group name="IdentifiableGroup">
        #     <xs:sequence>
        #       <xs:element name="identifier" type="xs:string"/>
        #     </xs:sequence>
        #   </xs:group>
        class MixinClassesAsGroupProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-cls-mixin-classes-as-group"

          # Checks if this processor applies
          #
          # @param uml_class [Lutaml::Uml::Class] The UML class to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if rule is enabled and class has mixin supertypes
          def self.applies_to?(uml_class, config)
            return false unless config.rule_enabled?(RULE_NAME)
            return false unless config.rule_enabled?("rule-xsd-cls-mixin-classes")
            return false unless config.rule_enabled?("rule-xsd-cls-sequence")

            # Check if class has mixin supertypes
            has_mixin_supertypes?(uml_class, config)
          end

          # Adds group references for mixin supertypes
          #
          # @param uml_class [Lutaml::Uml::Class] The class being processed
          # @param sequence_element [Object] The xs:sequence element
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @param recursive [Boolean] Whether to recursively process mixin hierarchies
          # @return [void]
          def self.add_group_references(uml_class, sequence_element, xsd_builder, config, recursive: false)
            return unless uml_class.generalizations

            uml_class.generalizations.each do |generalization|
              supertype = xsd_builder.find_class(generalization.general)
              next unless supertype

              if is_mixin_or_abstract?(supertype, config)
                # Add group reference for mixin
                add_mixin_group_reference(
                  supertype,
                  sequence_element,
                  xsd_builder,
                  config
                )

                # Recursively process mixin's supertypes
                if recursive
                  add_group_references(
                    supertype,
                    sequence_element,
                    xsd_builder,
                    config,
                    recursive: true
                  )
                end

              elsif config.rule_enabled?("rule-xsd-cls-mixin-classes-non-mixin-supertypes") && recursive
                # Process non-mixin supertype properties inline
                process_supertype_properties_inline(
                  supertype,
                  sequence_element,
                  xsd_builder,
                  config
                )

                # Recursively process its supertypes
                add_group_references(
                  supertype,
                  sequence_element,
                  xsd_builder,
                  config,
                  recursive: true
                )
              end
            end
          end

          # Checks if class has mixin supertypes
          #
          # @param uml_class [Lutaml::Uml::Class] The class to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if class has mixin supertypes
          def self.has_mixin_supertypes?(uml_class, config)
            return false unless uml_class.generalizations

            uml_class.generalizations.any? do |generalization|
              # Would need to resolve the supertype to check, but for now
              # we assume if generalizations exist, we might need this rule
              true
            end
          end

          # Checks if a class is a mixin or treated as one
          #
          # @param uml_class [Lutaml::Uml::Class] The class to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if class is mixin or abstract with no-abstract-classes rule
          def self.is_mixin_or_abstract?(uml_class, config)
            return true if uml_class.is_a?(Lutaml::Uml::Mixin)

            # Check if abstract class should be treated as mixin
            if config.rule_enabled?("rule-xsd-cls-no-abstract-classes")
              return true if uml_class.is_abstract?
            end

            false
          end

          # Adds a group reference for a mixin class
          #
          # @param mixin_class [Lutaml::Uml::Class] The mixin class
          # @param sequence_element [Object] The parent sequence element
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.add_mixin_group_reference(mixin_class, sequence_element, xsd_builder, config)
            group_ref = "#{mixin_class.qualified_name}Group"

            sequence_element.add_group_reference(group_ref) do |group_ref_element|
              # Import mixin's namespace
              if mixin_class.package
                xsd_builder.add_import(
                  mixin_class.package.xmlns,
                  mixin_class.package.target_namespace
                )
              end
            end
          end

          # Processes supertype properties inline instead of via group
          #
          # @param supertype [Lutaml::Uml::Class] The supertype class
          # @param sequence_element [Object] The parent sequence element
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.process_supertype_properties_inline(supertype, sequence_element, xsd_builder, config)
            return unless supertype.attributes

            supertype.attributes.each do |property|
              # Process each property using standard property processing
              PropertyProcessor.process_property(
                property,
                sequence_element,
                xsd_builder,
                config
              )
            end
          end

          # Creates group definition for a mixin class
          #
          # This is typically called separately when processing the mixin class itself
          #
          # @param mixin_class [Lutaml::Uml::Class] The mixin class
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.create_mixin_group(mixin_class, xsd_builder, config)
            return unless is_mixin_or_abstract?(mixin_class, config)

            group_name = "#{mixin_class.name}Group"

            xsd_builder.add_group(group_name) do |group|
              # Add standard annotation
              if mixin_class.definition
                group.add_annotation do |annotation|
                  annotation.add_documentation(mixin_class.definition)
                end
              end

              # Create sequence for mixin properties
              group.add_sequence do |sequence|
                # First, recursively add mixin's own mixin supertypes
                if config.rule_enabled?("rule-xsd-cls-mixin-classes")
                  add_group_references(
                    mixin_class,
                    sequence,
                    xsd_builder,
                    config,
                    recursive: true
                  )
                end

                # Then add mixin's own properties
                mixin_class.attributes.each do |property|
                  PropertyProcessor.process_property(
                    property,
                    sequence,
                    xsd_builder,
                    config
                  )
                end
              end
            end
          end
        end
      end
    end
  end
end