# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds gml:reversePropertyName annotation for bidirectional associations
          # Implements rule-xsd-prop-reverseProperty
          # Based on addStandardAnnotation() in XsdDocument.java lines 426-432
          #
          # For navigable bidirectional associations, adds reversePropertyName
          # to document the inverse relationship
          class ReversePropertyProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-reverseProperty"

            protected

            def apply_rule(property, context)
              return unless gml_32?(context)

              reverse_prop = get_reverse_property(property)
              return unless reverse_prop
              return unless navigable?(reverse_prop)

              reverse_qname = determine_qname(reverse_prop, context)
              return unless reverse_qname

              add_reverse_property_annotation(reverse_qname, context)
            end

            private

            def gml_32?(context)
              gml_ns = context[:gml_namespace]
              gml_ns == "http://www.opengis.net/gml/3.2"
            end

            def get_reverse_property(property)
              # Try reverse_property first
              if property.respond_to?(:reverse_property)
                begin
                  return property.reverse_property
                rescue StandardError, NoMethodError
                  # Fall through to alternative
                end
              end

              # Try reverseProperty (camelCase)
              if property.respond_to?(:reverseProperty)
                begin
                  return property.reverseProperty
                rescue StandardError, NoMethodError
                  return nil
                end
              end

              nil
            end

            def navigable?(property)
              return false unless property

              # If no navigable method, assume true
              return true unless property.respond_to?(:navigable?)

              begin
                property.navigable?
              rescue StandardError, NoMethodError
                true
              end
            end

            def determine_qname(property, context)
              # Try config's determineQName method if available
              config = context[:config]
              if config && config.respond_to?(:determine_qname)
                begin
                  qname = config.determine_qname(property)
                  return qname if qname
                rescue
                  # Fall through to manual determination
                end
              end

              # Manually construct qname
              construct_qname(property)
            end

            def construct_qname(property)
              return nil unless property.respond_to?(:name)

              name = property.name
              return nil unless name

              # Try to get package xmlns
              if property.respond_to?(:in_class)
                owner_class = property.in_class
                if owner_class && owner_class.respond_to?(:pkg)
                  pkg = owner_class.pkg
                  if pkg && pkg.respond_to?(:xmlns)
                    xmlns = pkg.xmlns
                    return "#{xmlns}:#{name}" if xmlns
                  end
                end
              end

              # Fall back to just the name
              name
            end

            def add_reverse_property_annotation(qname, context)
              # Ensure appinfo element exists
              appinfo = ensure_appinfo_element(context)
              return unless appinfo

              # Create gml:reversePropertyName
              gml_ns = context[:gml_namespace]
              reverse_elem = create_element_with_namespace("reversePropertyName", gml_ns, context)
              set_text_content(reverse_elem, qname, context)

              appinfo.add_child(reverse_elem) if appinfo.respond_to?(:add_child)
            end

            def ensure_appinfo_element(context)
              # Reuse logic from target_element_processor
              annotation = context[:annotation_element]

              unless annotation
                annotation = create_annotation_element(context)
                context[:annotation_element] = annotation
              end

              appinfo = context[:appinfo_element]
              unless appinfo
                xsd_doc = context[:xsd_document]
                appinfo = xsd_doc.create_element("appinfo") if xsd_doc
                annotation.add_child(appinfo) if annotation && appinfo
                context[:appinfo_element] = appinfo
              end

              appinfo
            end

            def create_annotation_element(context)
              xsd_doc = context[:xsd_document]
              return nil unless xsd_doc

              annotation = xsd_doc.create_element("annotation")

              prop_elem = context[:property_element]
              prop_elem.add_child(annotation) if prop_elem && annotation

              annotation
            end

            def create_element_with_namespace(name, namespace, context)
              xsd_doc = context[:xsd_document]
              return nil unless xsd_doc

              nsabr = "gml"
              qualified_name = "#{nsabr}:#{name}"

              xsd_doc.create_element(qualified_name, namespace)
            end

            def set_text_content(element, text, context)
              return unless element

              if element.respond_to?(:content=)
                element.content = text
              elsif element.respond_to?(:text=)
                element.text = text
              end
            end
          end
        end
      end
    end
  end
end