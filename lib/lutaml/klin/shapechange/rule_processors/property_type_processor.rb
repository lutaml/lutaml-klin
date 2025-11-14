# frozen_string_literal: true

require_relative "base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Generates PropertyType elements like BuildingPropertyType
        # Implements rule-xsd-cls-standard-gml-property-types
        # Based on ShapeChange's pPropertyTypes() logic (XsdDocument.java lines 1234-1325)
        class PropertyTypeProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-cls-standard-gml-property-types"

          protected

          def apply_rule(uml_class, context)
            xsd_doc = context[:xsd_document]

            # Generate: <xs:complexType name="BuildingPropertyType">
            property_type = xsd_doc.add_complex_type(
              name: property_type_name(uml_class)
            )

            # Add sequence with minOccurs="0"
            sequence = xsd_doc.add_sequence(property_type)
            sequence["minOccurs"] = "0"

            # Add element reference to object
            element_ref = xsd_doc.create_element("element")
            element_ref["ref"] = "#{context[:prefix]}:#{uml_class.name}"
            sequence.add_child(element_ref)

            # Add AssociationAttributeGroup if class has identity
            if class_has_identity?(uml_class)
              xsd_doc.add_attribute_group(
                property_type,
                ref: "gml:AssociationAttributeGroup"
              )

              # Add import for gml namespace
              xsd_doc.add_import(
                namespace: "http://www.opengis.net/gml/3.2",
                location: "http://schemas.opengis.net/gml/3.2.1/gml.xsd"
              )
            end
          end

          private

          def property_type_name(uml_class)
            base = uml_class.name
            # Avoid double "Property" suffix
            suffix = base.end_with?("Property") ? "_" : ""
            "#{base}#{suffix}PropertyType"
          end

          def class_has_identity?(uml_class)
            # Classes with identity: Feature, Object, Mixin
            # Check stereotypes
            stereotypes = Array(uml_class.stereotype).map(&:to_s)

            # GML feature types and object types have identity
            return true if stereotypes.include?("featureType")
            return true if stereotypes.include?("FeatureType")
            return true if stereotypes.include?("objectType")
            return true if stereotypes.include?("ObjectType")
            return true if stereotypes.include?("Mixin")

            false
          end
        end
      end
    end
  end
end