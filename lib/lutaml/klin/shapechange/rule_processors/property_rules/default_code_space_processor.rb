# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds gml:defaultCodeSpace annotation for code list properties
          # Implements rule-xsd-prop-defaultCodeSpace
          # Based on addStandardAnnotation() in XsdDocument.java lines 434-440
          #
          # For properties with a default code space defined,
          # adds the URI to enable validation and resolution of codes
          class DefaultCodeSpaceProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-defaultCodeSpace"

            protected

            def apply_rule(property, context)
              return unless gml_32?(context)

              code_space = get_default_code_space(property)
              return if code_space.nil? || code_space.empty?

              add_default_code_space_annotation(code_space, context)
            end

            private

            def gml_32?(context)
              gml_ns = context[:gml_namespace]
              gml_ns == "http://www.opengis.net/gml/3.2"
            end

            def get_default_code_space(property)
              # Try default_code_space first (snake_case)
              if property.respond_to?(:default_code_space)
                begin
                  code_space = property.default_code_space
                  return code_space.to_s.strip if code_space
                rescue StandardError, NoMethodError
                  # Fall through to alternative
                end
              end

              # Try defaultCodeSpace (camelCase)
              if property.respond_to?(:defaultCodeSpace)
                begin
                  code_space = property.defaultCodeSpace
                  return code_space.to_s.strip if code_space
                rescue StandardError, NoMethodError
                  return nil
                end
              end

              nil
            end

            def add_default_code_space_annotation(code_space, context)
              # Ensure appinfo element exists
              appinfo = ensure_appinfo_element(context)
              return unless appinfo

              # Create gml:defaultCodeSpace
              gml_ns = context[:gml_namespace]
              code_space_elem = create_element_with_namespace(
                "defaultCodeSpace", gml_ns, context
              )
              set_text_content(code_space_elem, code_space, context)

              return unless appinfo.respond_to?(:add_child)

              appinfo.add_child(code_space_elem)
            end

            def ensure_appinfo_element(context)
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

            def set_text_content(element, text, _context)
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
