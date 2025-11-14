# frozen_string_literal: true

require_relative "../base_rule_processor"

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Processor for rule-xsd-cls-enum-subtypes
          #
          # Includes enumeration values from subtypes when generating
          # enumeration type definitions.
          #
          # Based on XsdDocument.java:pAnonymousEnumeration() lines 1806-1825
          class EnumSubtypesProcessor < BaseRuleProcessor
            RULE_NAME = "rule-xsd-cls-enum-subtypes"

            def self.rule_name
              RULE_NAME
            end

            # Process enumeration to collect values including subtypes
            #
            # @param uml_class [Lutaml::Uml::Class] The enumeration class
            # @param context [Hash] Processing context with :model
            # @return [Hash] Processing result with all enumeration values
            def process(uml_class, context = {})
              return default_result unless applies_to?(uml_class)

              model = context[:model]
              return default_result unless model

              classes = collect_enumeration_classes(uml_class, model)
              all_values = extract_all_values(classes)

              {
                applies: true,
                result: {
                  enumeration_classes: classes.map(&:name),
                  all_values: all_values,
                  includes_subtypes: classes.size > 1,
                  class_count: classes.size
                },
                message: "Collected #{all_values.size} values from #{classes.size} enumeration class(es)"
              }
            end

            private

            # Collect enumeration classes including subtypes
            #
            # @param enumeration_class [Object] The enumeration class
            # @param model [Object] The UML model
            # @return [Array<Object>] Ordered list of enumeration classes
            def collect_enumeration_classes(enumeration_class, model)
              classes = [enumeration_class]

              # Traverse subtypes and add enumerations/codelists
              tasks = [enumeration_class]

              while tasks.any?
                current_class = tasks.shift
                subtypes = get_subtypes(current_class)

                next unless subtypes

                subtypes.each do |subtype_id|
                  subtype = get_class_by_id(model, subtype_id)

                  next unless subtype
                  next unless is_enum_or_codelist?(subtype)

                  tasks << subtype
                  classes << subtype # Add at end (current first, then subtypes)
                end
              end

              classes
            end

            # Extract all enumeration values from classes
            #
            # @param classes [Array<Object>] List of enumeration classes
            # @return [Array<Hash>] All enumeration values with metadata
            def extract_all_values(classes)
              values = []

              classes.each do |cls|
                properties = get_properties(cls)
                next unless properties

                properties.each do |property|
                  values << {
                    name: get_property_name(property),
                    initial_value: get_initial_value(property),
                    from_class: cls.name
                  }
                end
              end

              values
            end

            # Get subtypes from class
            #
            # @param uml_class [Object] The class
            # @return [Array, nil] Subtype IDs
            def get_subtypes(uml_class)
              return nil unless uml_class.respond_to?(:subtypes)

              subtypes = uml_class.subtypes
              return nil unless subtypes

              # Handle SortedSet or Array
              subtypes.respond_to?(:to_a) ? subtypes.to_a : subtypes
            rescue StandardError
              nil
            end

            # Get class by ID from model
            #
            # @param model [Object] The model
            # @param class_id [String] Class ID
            # @return [Object, nil] The class
            def get_class_by_id(model, class_id)
              return nil unless model.respond_to?(:class_by_id)

              model.class_by_id(class_id)
            rescue StandardError
              nil
            end

            # Check if class is enumeration or code list
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if enum or codelist
            def is_enum_or_codelist?(uml_class)
              return false unless uml_class.respond_to?(:category)

              category = uml_class.category
              return false unless category

              cat_str = category.to_s.downcase
              cat_str == "enumeration" || cat_str == "codelist"
            rescue StandardError
              false
            end

            # Get properties from class
            #
            # @param uml_class [Object] The class
            # @return [Array, Hash, nil] Properties
            def get_properties(uml_class)
              return nil unless uml_class.respond_to?(:properties)

              properties = uml_class.properties
              return nil unless properties

              # Handle Hash (properties.values) or Array
              if properties.respond_to?(:values)
                properties.values
              elsif properties.respond_to?(:to_a)
                properties.to_a
              else
                properties
              end
            rescue StandardError
              nil
            end

            # Get property name
            #
            # @param property [Object] The property
            # @return [String] Property name
            def get_property_name(property)
              return property.name if property.respond_to?(:name)
              "unknown"
            rescue StandardError
              "unknown"
            end

            # Get initial value from property
            #
            # @param property [Object] The property
            # @return [String, nil] Initial value
            def get_initial_value(property)
              return nil unless property.respond_to?(:initial_value)

              initial_value = property.initial_value
              initial_value unless initial_value.to_s.empty?
            rescue StandardError
              nil
            end

            # Check if rule applies to the class
            #
            # @param uml_class [Object] The class
            # @return [Boolean] True if class is enumeration or code list
            def applies_to?(uml_class)
              is_enum_or_codelist?(uml_class)
            end

            # Default result when rule doesn't apply
            #
            # @return [Hash] Default result structure
            def default_result
              {
                applies: false,
                result: nil,
                message: "Not an enumeration or code list"
              }
            end
          end
        end
      end
    end
  end
end