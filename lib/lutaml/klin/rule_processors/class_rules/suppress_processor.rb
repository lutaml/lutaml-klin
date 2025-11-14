# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module ClassRules
        # Processes suppressed classes with ADE element properties
        #
        # Generates ADE substitution elements for properties of suppressed classes,
        # allowing extension via substitution groups in ADE schemas.
        #
        # @example ADE Substitution Element
        #   <xs:element name="height"
        #               type="gml:MeasureType"
        #               substitutionGroup="bldg:_GenericApplicationPropertyOfAbstractBuilding"/>
        class SuppressProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-cls-suppress"

          # Checks if this processor applies to the given class
          #
          # @param uml_class [Lutaml::Uml::Class] The UML class to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if class is suppressed with adeelement stereotype
          def self.applies_to?(uml_class, config)
            return false unless config.rule_enabled?(RULE_NAME)
            return false unless uml_class.stereotype?("adeelement")

            true
          end

          # Processes a property of a suppressed ADE element class
          #
          # @param property [Lutaml::Uml::Attribute] The property to process
          # @param parent_class [Lutaml::Uml::Class] The suppressed class
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.process_property(property, parent_class, xsd_builder, config)
            return unless applies_to?(parent_class, config)

            # Find unsuppressed supertype
            unsuppressed_supertype = find_unsuppressed_supertype(parent_class, xsd_builder)

            unless unsuppressed_supertype
              xsd_builder.add_error(
                "ADE class '#{parent_class.name}' cannot be suppressed, as it has no unsuppressed supertype",
                parent_class
              )
              return
            end

            # Create element with substitution group
            xsd_builder.add_element(property.name) do |element|
              # Add standard annotation
              if property.definition
                element.add_annotation do |annotation|
                  annotation.add_documentation(property.definition)
                end
              end

              # Set property type
              set_property_type(element, property, parent_class, xsd_builder, config)

              # Set substitution group
              substitution_group = build_substitution_group_name(
                unsuppressed_supertype,
                xsd_builder
              )

              if substitution_group
                element.substitution_group = substitution_group

                # Import supertype namespace
                if unsuppressed_supertype.package
                  xsd_builder.add_import(
                    unsuppressed_supertype.package.xmlns,
                    unsuppressed_supertype.package.target_namespace
                  )
                end
              end

              # Record encoding info
              if xsd_builder.write_xml_encoding_infos?
                xsd_builder.add_encoding_info(
                  property,
                  property.name,
                  xsd_builder.target_namespace,
                  false
                )
              end
            end
          end

          # Finds the unsuppressed supertype of a class
          #
          # @param uml_class [Lutaml::Uml::Class] The class
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @return [Lutaml::Uml::Class, nil] The unsuppressed supertype or nil
          def self.find_unsuppressed_supertype(uml_class, xsd_builder)
            return nil unless uml_class.generalizations

            uml_class.generalizations.each do |generalization|
              supertype = xsd_builder.find_class(generalization.general)
              next unless supertype

              # Check if this supertype is unsuppressed
              unless supertype.stereotype?("adeelement")
                return supertype
              end

              # Recursively check supertype's supertypes
              result = find_unsuppressed_supertype(supertype, xsd_builder)
              return result if result
            end

            nil
          end

          # Sets the property type on the element
          #
          # @param element [Object] The element to configure
          # @param property [Lutaml::Uml::Attribute] The property
          # @param parent_class [Lutaml::Uml::Class] The parent class
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.set_property_type(element, property, parent_class, xsd_builder, config)
            type_class = xsd_builder.find_class(property.type)

            if type_class&.as_character_string?
              # Simple string type
              element.type = "xs:string"
            else
              # Map property type normally
              PropertyTypeMapper.map_property_type(
                element,
                property,
                parent_class,
                xsd_builder,
                config
              )
            end
          end

          # Builds the substitution group name for ADE elements
          #
          # Format: prefix:_GenericApplicationPropertyOfSuperTypeName
          #
          # @param supertype [Lutaml::Uml::Class] The unsuppressed supertype
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @return [String, nil] The substitution group name or nil
          def self.build_substitution_group_name(supertype, xsd_builder)
            element_name = xsd_builder.map_to_element(supertype)
            return nil unless element_name

            # Transform element name to substitution group name
            # e.g., "bldg:AbstractBuilding" -> "bldg:_GenericApplicationPropertyOfAbstractBuilding"

            # Replace :_ with : (normalize)
            normalized = element_name.gsub(/:_/, ":")

            # Split into prefix and local name
            if normalized.include?(":")
              prefix, local_name = normalized.split(":", 2)
              "#{prefix}:_GenericApplicationPropertyOf#{local_name}"
            else
              "_GenericApplicationPropertyOf#{normalized}"
            end
          end
        end
      end
    end
  end
end