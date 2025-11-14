# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module PropertyRules
          # Adds gml:targetElement annotation for GML 3.2 associations
          # Implements rule-xsd-prop-targetElement
          # Based on addStandardAnnotation() in XsdDocument.java lines 379-396
          #
          # For properties encoded by reference, adds targetElement
          # to specify the expected type of the referenced object
          class TargetElementProcessor < BaseRuleProcessor
            RULE_ID = "rule-xsd-prop-targetElement"

            protected

            def apply_rule(property, context)
              return unless gml_32?(context)
              return unless by_reference_or_okstra?(property, context)

              value_class = get_value_class(property, context)
              return unless value_class
              return if code_list?(value_class)
              return unless has_object_element?(value_class, context)

              target_element = determine_target_element(value_class, context)
              return unless target_element

              add_target_element_annotation(target_element, context)
            end

            private

            def gml_32?(context)
              gml_ns = context[:gml_namespace]
              gml_ns == "http://www.opengis.net/gml/3.2"
            end

            def by_reference_or_okstra?(property, context)
              # Check if encoded by reference
              encoding = get_encoding_mode(property)
              return true if encoding == "byreference"

              # Check OKSTRAFID with rule-xsd-cls-okstra-fid
              value_class = get_value_class(property, context)
              return false unless value_class
              return false unless value_class.respond_to?(:category)

              category = value_class.category.to_s.upcase
              return false unless category == "OKSTRAFID"

              # Check if okstra-fid rule applies
              rule_checker.applies?("rule-xsd-cls-okstra-fid", value_class)
            end

            def get_encoding_mode(property)
              # Read inlineOrByReference from property
              mode = nil

              if property.respond_to?(:inline_or_by_reference)
                mode = property.inline_or_by_reference
              elsif property.respond_to?(:inlineOrByReference)
                mode = property.inlineOrByReference
              end

              return mode.to_s.downcase if mode

              "standard"
            end

            def get_value_class(property, context)
              return nil unless property.respond_to?(:type)

              type_info = begin
                            property.type
                          rescue
                            nil
                          end
              return nil unless type_info

              # Try to find class by ID or name
              model = context[:model]
              return nil unless model

              class_by_id = begin
                              model.class_by_id(type_info.id) if type_info.respond_to?(:id)
                            rescue
                              nil
                            end
              return class_by_id if class_by_id

              begin
                model.class_by_name(type_info.name) if type_info.respond_to?(:name)
              rescue
                nil
              end
            end

            def code_list?(value_class)
              return false unless value_class.respond_to?(:category)

              category = value_class.category.to_s.upcase
              category == "CODELIST"
            end

            def has_object_element?(value_class, context)
              return false unless value_class.respond_to?(:category)

              category = value_class.category.to_s.upcase

              # Categories that have object elements
              %w[DATATYPE UNION FEATURE OBJECT OKSTRAFID].include?(category)
            end

            def determine_target_element(value_class, context)
              # First try to get mapped element from config
              config = context[:config]
              if config && config.respond_to?(:element_map_entry)
                map_entry = config.element_map_entry(value_class.name, "xsd")
                return map_entry.target if map_entry && map_entry.respond_to?(:target)
              end

              # Fall back to qname
              if value_class.respond_to?(:qname)
                return value_class.qname
              end

              nil
            end

            def add_target_element_annotation(target_element, context)
              # Ensure appinfo element exists
              appinfo = ensure_appinfo_element(context)
              return unless appinfo

              # Create gml:targetElement
              gml_ns = context[:gml_namespace]
              target_elem = create_element_with_namespace("targetElement", gml_ns, context)
              set_text_content(target_elem, target_element, context)

              appinfo.add_child(target_elem) if appinfo.respond_to?(:add_child)
            end

            def ensure_appinfo_element(context)
              # Check if appinfo already exists
              annotation = context[:annotation_element]

              unless annotation
                # Create annotation if needed
                annotation = create_annotation_element(context)
                context[:annotation_element] = annotation
              end

              # Get or create appinfo within annotation
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

              # Add to property element if available
              prop_elem = context[:property_element]
              prop_elem.add_child(annotation) if prop_elem && annotation

              annotation
            end

            def create_element_with_namespace(name, namespace, context)
              xsd_doc = context[:xsd_document]
              return nil unless xsd_doc

              # Create element with namespace prefix
              nsabr = namespace_abbreviation(namespace)
              qualified_name = "#{nsabr}:#{name}"

              xsd_doc.create_element(qualified_name, namespace)
            end

            def namespace_abbreviation(namespace)
              case namespace
              when "http://www.opengis.net/gml/3.2"
                "gml"
              when "http://www.opengis.net/gml"
                "gml"
              else
                "gml"
              end
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