# frozen_string_literal: true

require_relative "../base_processor"

module Lutaml
  module Klin
    module RuleProcessors
      module PropertyRules
        # Processes properties with attribute map entries
        #
        # When a property type has attribute or attributeGroup map entries but no
        # element content, this processor creates an anonymous complexType with
        # the mapped attributes.
        #
        # @example Anonymous Complex Type with Attributes
        #   <xs:element name="link">
        #     <xs:complexType>
        #       <xs:attribute ref="xlink:href"/>
        #       <xs:attributeGroup ref="xlink:simpleAttrs"/>
        #     </xs:complexType>
        #   </xs:element>
        class AttMapEntryProcessor < BaseProcessor
          # Rule identifier
          RULE_NAME = "rule-xsd-prop-att-map-entry"

          # Checks if this processor applies to the given property
          #
          # @param property [Lutaml::Uml::Attribute] The property to check
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if property has attribute map entries
          def self.applies_to?(property, config)
            return false unless config.rule_enabled?(RULE_NAME)
            return false if property.is_attribute? # Already an attribute element

            # Check if property type has attribute or attributeGroup map entries
            has_attribute_map_entries?(property, config)
          end

          # Processes a property with attribute map entries
          #
          # @param property [Lutaml::Uml::Attribute] The property to process
          # @param parent_element [Object] Parent XSD element
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.process_property(property, parent_element, xsd_builder, config)
            return unless applies_to?(property, config)

            # Get attribute and attributeGroup map entries
            attribute_ref = get_attribute_map_entry(property, config)
            attribute_group_ref = get_attribute_group_map_entry(property, config)

            return if attribute_ref.nil? && attribute_group_ref.nil?

            # Create anonymous complex type
            parent_element.add_complex_type do |complex_type|
              # Add nilReason if needed
              if should_add_nil_reason?(property, config)
                complex_type.add_attribute do |attr|
                  add_nil_reason_attribute(attr, config)
                end
              end

              # Add metadata if needed
              if should_add_metadata?(property, config)
                add_metadata_attribute(complex_type)
              end

              # Add soft-typed name if needed
              if should_add_soft_typed_name?(property, config)
                complex_type.add_attribute do |attr|
                  add_name_attribute(attr)
                end
              end

              # Add attribute reference
              if attribute_ref
                add_attribute_reference(
                  complex_type,
                  attribute_ref,
                  xsd_builder
                )
              end

              # Add attribute group reference
              if attribute_group_ref
                add_attribute_group_reference(
                  complex_type,
                  attribute_group_ref,
                  xsd_builder
                )
              end
            end
          end

          # Checks if property type has attribute map entries
          #
          # @param property [Lutaml::Uml::Attribute] The property
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if attribute or attributeGroup map entries exist
          def self.has_attribute_map_entries?(property, config)
            attribute_ref = get_attribute_map_entry(property, config)
            attribute_group_ref = get_attribute_group_map_entry(property, config)

            !attribute_ref.nil? || !attribute_group_ref.nil?
          end

          # Gets attribute map entry for property type
          #
          # @param property [Lutaml::Uml::Attribute] The property
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [String, nil] Attribute reference or nil
          def self.get_attribute_map_entry(property, config)
            type_name = property.type
            encoding_rule = config.encoding_rule || "xsd"

            map_entry = config.attribute_map_entry(type_name, encoding_rule)
            map_entry&.rule
          end

          # Gets attributeGroup map entry for property type
          #
          # @param property [Lutaml::Uml::Attribute] The property
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [String, nil] AttributeGroup reference or nil
          def self.get_attribute_group_map_entry(property, config)
            type_name = property.type
            encoding_rule = config.encoding_rule || "xsd"

            map_entry = config.attribute_group_map_entry(type_name, encoding_rule)
            map_entry&.rule
          end

          # Checks if nilReason should be added
          #
          # @param property [Lutaml::Uml::Attribute] The property
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if nilReason should be added
          def self.should_add_nil_reason?(property, config)
            return false unless config.rule_enabled?("rule-xsd-prop-nillable")

            property.nil_reason_allowed? || property.voidable?
          end

          # Checks if metadata attribute should be added
          #
          # @param property [Lutaml::Uml::Attribute] The property
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if metadata should be added
          def self.should_add_metadata?(property, config)
            return false unless config.rule_enabled?("rule-xsd-prop-metadata")

            property.property_metadata?
          end

          # Checks if soft-typed name attribute should be added
          #
          # @param property [Lutaml::Uml::Attribute] The property
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [Boolean] true if name attribute should be added
          def self.should_add_soft_typed_name?(property, config)
            return false unless config.rule_enabled?("rule-xsd-prop-soft-typed")

            property.tagged_value("soft-typed") == "true"
          end

          # Adds nilReason attribute to complex type
          #
          # @param attribute_element [Object] The attribute element
          # @param config [Lutaml::Klin::XsdGeneratorConfiguration] Configuration
          # @return [void]
          def self.add_nil_reason_attribute(attribute_element, config)
            gml_version = config.gml_version || "3.2"

            if gml_version == "3.2"
              attribute_element.name = "nilReason"
              attribute_element.type = "gml:NilReasonType"
            else
              attribute_element.name = "nilReason"
              attribute_element.type = "gml:NullType"
            end
          end

          # Adds metadata attribute
          #
          # @param complex_type [Object] The complex type element
          # @return [void]
          def self.add_metadata_attribute(complex_type)
            complex_type.add_attribute do |attr|
              attr.name = "metadata"
              attr.type = "xs:anyURI"
            end
          end

          # Adds name attribute for soft typing
          #
          # @param attribute_element [Object] The attribute element
          # @return [void]
          def self.add_name_attribute(attribute_element)
            attribute_element.name = "name"
            attribute_element.type = "xs:NCName"
            attribute_element.use = "required"
          end

          # Adds attribute reference to complex type
          #
          # @param complex_type [Object] The complex type element
          # @param attribute_ref [String] The attribute reference (e.g., "xlink:href")
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @return [void]
          def self.add_attribute_reference(complex_type, attribute_ref, xsd_builder)
            complex_type.add_attribute do |attr|
              attr.ref = attribute_ref

              # Import namespace if needed
              if attribute_ref.include?(":")
                prefix, _name = attribute_ref.split(":", 2)
                namespace = xsd_builder.resolve_namespace(prefix)
                xsd_builder.add_import(prefix, namespace) if namespace
              end
            end
          end

          # Adds attributeGroup reference to complex type
          #
          # @param complex_type [Object] The complex type element
          # @param group_ref [String] The attributeGroup reference
          # @param xsd_builder [Lutaml::Klin::Builders::XsdDocumentBuilder] XSD builder
          # @return [void]
          def self.add_attribute_group_reference(complex_type, group_ref, xsd_builder)
            complex_type.add_attribute_group do |attr_group|
              attr_group.ref = group_ref

              # Import namespace if needed
              if group_ref.include?(":")
                prefix, _name = group_ref.split(":", 2)
                namespace = xsd_builder.resolve_namespace(prefix)
                xsd_builder.add_import(prefix, namespace) if namespace
              end
            end
          end
        end
      end
    end
  end
end