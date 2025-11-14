# frozen_string_literal: true

require_relative "base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        # Generates <xs:complexType> for UML classes
        # Implements rule-xsd-cls-type from ShapeChange
        # Based on pComplexType() in XsdDocument.java lines 859-1025
        class ComplexTypeProcessor < BaseRuleProcessor
          RULE_ID = "rule-xsd-cls-type"

          protected

          def apply_rule(uml_class, context)
            # Skip enums - they're handled by EnumerationProcessor
            return if uml_class.is_a?(Lutaml::Uml::Enum)

            xsd_doc = context[:xsd_document]

            # Create complexType element
            complex_type = xsd_doc.add_complex_type(
              name: type_name(uml_class, xsd_doc),
              **additional_attributes(uml_class)
            )

            # Determine if we need complexContent/extension
            base_type = determine_base_type(uml_class, context)

            if needs_extension?(uml_class, base_type)
              # Add complexContent/extension and return the extension element
              # as the content container for properties
              extension = xsd_doc.add_complex_content_extension(complex_type, base_type)
              context[:content_container] = extension
            else
              # Direct content model - complex_type is the container
              context[:content_container] = complex_type
            end

            # Store reference for SequenceProcessor to add sequence/choice
            context[:current_complex_type] = complex_type
          end

          private

          def type_name(uml_class, xsd_doc)
            # Follow GML/ISO 19139 naming conventions
            "#{uml_class.name}Type"
          end

          def additional_attributes(uml_class)
            attrs = {}
            if uml_class.respond_to?(:is_abstract) && uml_class.is_abstract
              attrs[:abstract] = "true"
            end
            attrs
          end

          def determine_base_type(uml_class, context)
            # Check if class has a superclass
            if uml_class.generalization&.general
              parent = uml_class.generalization.general
              parent_name = parent.name || uml_class.generalization.general_name

              # Return qualified base type name
              return "#{context[:prefix]}:#{parent_name}Type" if parent_name
            end

            # Check for default base types based on stereotype/category
            default_base_type_for_class(uml_class, context)
          end

          def default_base_type_for_class(uml_class, context)
            # Return nil for DATATYPE/UNION without base in GML naming
            # (these don't need complexContent/extension)
            return nil if is_datatype_or_union_without_base?(uml_class)

            # For FeatureType, use gml:AbstractFeatureType
            if has_stereotype?(uml_class, "FeatureType")
              return "gml:AbstractFeatureType"
            end

            # For ObjectType, use gml:AbstractGMLType
            if has_stereotype?(uml_class, "ObjectType")
              return "gml:AbstractGMLType"
            end

            nil
          end

          def is_datatype_or_union_without_base?(uml_class)
            # Check if class is DATATYPE or UNION category
            # In Ruby model, we check stereotype or other indicators
            stereotypes = Array(uml_class.stereotype)
            stereotypes.include?("DataType") ||
              stereotypes.include?("Union")
          end

          def has_stereotype?(uml_class, stereotype_name)
            stereotypes = Array(uml_class.stereotype)
            stereotypes.any? { |s| s.downcase == stereotype_name.downcase }
          end

          def needs_extension?(uml_class, base_type)
            # If we have a base type, we need complexContent/extension
            return true if base_type

            # DATATYPE/UNION without base don't need extension
            false
          end

        end
      end
    end
  end
end