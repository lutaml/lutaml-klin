# frozen_string_literal: true

require_relative "../validation_result"

module Lutaml
  module Klin
    module Domain
      module Services
        # Service for validating schema mappings and generating comprehensive
        # validation results.
        #
        # This service analyzes PackageMapping, ClassMapping, and
        # AttributeMapping objects to determine resolution completeness,
        # calculate statistics, and provide actionable suggestions for
        # unresolved items.
        #
        # This is a pure domain service - it performs no I/O operations.
        #
        # @example Validating a schema mapping
        #   service = ValidationService.new
        #   result = service.validate(schema_mapping)
        #   puts "Resolution rate: #{result.resolution_rate}%"
        class ValidationService
          # Validate a complete schema mapping.
          #
          # @param schema_mapping [Lutaml::Klin::Mapping::SchemaMapping]
          #   The schema mapping to validate
          # @return [ValidationResult] Comprehensive validation result
          def validate(schema_mapping)
            unresolved_items = []
            package_details = []

            # Analyze each package
            schema_mapping.package_mappings&.each do |package_mapping|
              package_data = analyze_package(package_mapping, unresolved_items)
              package_details << package_data
            end

            # Calculate summary statistics
            stats = schema_mapping.calculate_statistics
            summary = build_summary(stats)

            ValidationResult.new(
              summary: summary,
              unresolved_items: unresolved_items,
              packages: package_details,
              generated_at: Time.now.utc.iso8601
            )
          end

          private

          # Analyze a single package mapping.
          #
          # @param package_mapping [PackageMapping] Package to analyze
          # @param unresolved_items [Array<Hash>] Accumulator for unresolved
          #   items
          # @return [Hash] Package analysis data
          def analyze_package(package_mapping, unresolved_items)
            class_details = []

            package_mapping.class_mappings&.each do |class_mapping|
              class_data = analyze_class(class_mapping, package_mapping,
                                         unresolved_items)
              class_details << class_data
            end

            pkg_stats = package_mapping.calculate_statistics

            {
              name: package_mapping.uml_package_name,
              namespace: package_mapping.xsd_namespace,
              statistics: pkg_stats,
              resolution_rate: package_mapping.resolution_rate,
              fully_resolved: package_mapping.fully_resolved?,
              classes: class_details
            }
          end

          # Analyze a single class mapping.
          #
          # @param class_mapping [ClassMapping] Class to analyze
          # @param package_mapping [PackageMapping] Parent package
          # @param unresolved_items [Array<Hash>] Accumulator for unresolved
          #   items
          # @return [Hash] Class analysis data
          def analyze_class(class_mapping, package_mapping, unresolved_items)
            attribute_details = []

            class_mapping.attribute_mappings&.each do |attr_mapping|
              attr_data = analyze_attribute(attr_mapping, class_mapping,
                                            package_mapping, unresolved_items)
              attribute_details << attr_data
            end

            {
              name: class_mapping.uml_name,
              status: class_mapping.resolution_status,
              method: class_mapping.resolution_method,
              xsd_name: class_mapping.xsd_name,
              attributes: attribute_details
            }
          end

          # Analyze a single attribute mapping.
          #
          # @param attr_mapping [AttributeMapping] Attribute to analyze
          # @param class_mapping [ClassMapping] Parent class
          # @param package_mapping [PackageMapping] Parent package
          # @param unresolved_items [Array<Hash>] Accumulator for unresolved
          #   items
          # @return [Hash] Attribute analysis data
          def analyze_attribute(attr_mapping, class_mapping, package_mapping,
                                unresolved_items)
            # Record unresolved items
            if attr_mapping.unresolved? || attr_mapping.partial?
              unresolved_items << build_unresolved_item(
                attr_mapping, class_mapping, package_mapping
              )
            end

            {
              name: attr_mapping.uml_name,
              status: attr_mapping.resolution_status,
              method: attr_mapping.resolution_method,
              uml_type: attr_mapping.uml_type,
              xsd_type: attr_mapping.xsd_type,
              error: attr_mapping.resolution_error
            }
          end

          # Build an unresolved item record.
          #
          # @param attr_mapping [AttributeMapping] Unresolved attribute
          # @param class_mapping [ClassMapping] Parent class
          # @param package_mapping [PackageMapping] Parent package
          # @return [Hash] Unresolved item details
          def build_unresolved_item(attr_mapping, class_mapping,
                                    package_mapping)
            {
              type: "attribute",
              package: package_mapping.uml_package_name,
              class: class_mapping.uml_name,
              attribute: attr_mapping.uml_name,
              uml_type: attr_mapping.uml_type,
              status: attr_mapping.resolution_status,
              error: attr_mapping.resolution_error,
              suggestions: generate_suggestions(attr_mapping, class_mapping,
                                                package_mapping)
            }
          end

          # Generate actionable suggestions for resolving an item.
          #
          # @param attr_mapping [AttributeMapping] Unresolved attribute
          # @param class_mapping [ClassMapping] Parent class
          # @param package_mapping [PackageMapping] Parent package
          # @return [Array<String>] List of suggestions
          def generate_suggestions(attr_mapping, class_mapping, package_mapping)
            suggestions = []

            # Check for common issues and provide specific advice
            if attr_mapping.resolution_error&.include?("not found")
              suggestions << "Verify that type '#{attr_mapping.uml_type}' " \
                             "exists in the XSD repository"
              suggestions << "Check namespace mappings for package " \
                             "'#{package_mapping.uml_package_name}'"
            end

            if attr_mapping.resolution_error&.include?("namespace")
              suggestions << "Add namespace mapping in ShapeChange " \
                             "configuration"
              suggestions << "Verify XSD namespace URI is correct"
            end

            if attr_mapping.uml_type&.match?(/^[A-Z]/) &&
               !attr_mapping.uml_type&.match?(/:/)
              suggestions << "Type '#{attr_mapping.uml_type}' appears to be " \
                             "a custom class - ensure it's defined in the UML " \
                             "model"
              suggestions << "Consider adding a type override mapping"
            end

            # Generic suggestions if no specific ones apply
            if suggestions.empty?
              suggestions << "Review the resolution error message for details"
              suggestions << "Check ShapeChange configuration for type mappings"
              suggestions << "Verify UML model completeness"
            end

            suggestions
          end

          # Build summary statistics hash.
          #
          # @param stats [Hash] Raw statistics from schema mapping
          # @return [Hash] Formatted summary
          def build_summary(stats)
            total_classes = stats["total_classes"].to_i
            resolved_classes = stats["resolved_classes"].to_i
            total_attrs = stats["total_attributes"].to_i
            resolved_attrs = stats["resolved_attributes"].to_i

            resolution_rate = if total_classes.zero?
                                0.0
                              else
                                (resolved_classes.to_f / total_classes * 100)
                                  .round(2)
                              end

            attr_rate = if total_attrs.zero?
                          0.0
                        else
                          (resolved_attrs.to_f / total_attrs * 100).round(2)
                        end

            {
              total_packages: stats["total_packages"].to_i,
              total_classes: total_classes,
              resolved_classes: resolved_classes,
              partial_classes: stats["partial_classes"].to_i,
              unresolved_classes: stats["unresolved_classes"].to_i,
              total_attributes: total_attrs,
              resolved_attributes: resolved_attrs,
              partial_attributes: stats["partial_attributes"].to_i,
              unresolved_attributes: stats["unresolved_attributes"].to_i,
              resolution_rate: resolution_rate,
              attribute_resolution_rate: attr_rate
            }
          end
        end
      end
    end
  end
end