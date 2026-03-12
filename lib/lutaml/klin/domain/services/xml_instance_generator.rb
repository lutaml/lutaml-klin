# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      module Services
        # Generates sample XML instances showing UML-to-XSD mappings
        #
        # This service generates example XML documents that demonstrate how
        # UML attributes are mapped to XSD elements, with optional comments
        # showing the mapping relationships.
        #
        # @example
        #   generator = XmlInstanceGenerator.new
        #   xml = generator.generate_instance(class_data, attributes_data)
        class XmlInstanceGenerator
          # Generate XML instance for a class
          #
          # @param class_data [Hash] Class information
          # @param attributes_data [Array<Hash>] Attribute mappings
          # @param options [Hash] Generation options
          # @option options [Boolean] :include_comments Include UML/XSD
          #   mapping comments (default: true)
          # @option options [Boolean] :include_sample_values Include sample
          #   values (default: true)
          # @return [String] Formatted XML or nil if element_name is missing
          def generate_instance(class_data, attributes_data, options = {})
            options = {
              include_comments: true,
              include_sample_values: true
            }.merge(options)

            element_name = class_data[:xsd_element_name]
            return nil if element_name.nil? || element_name.empty?

            namespace_prefix = extract_prefix(class_data[:xsd_namespace])

            xml = []
            xml << '<?xml version="1.0" encoding="UTF-8"?>'
            xml << "<#{namespace_prefix}:#{element_name}"
            xml << "  xmlns:#{namespace_prefix}=\"#{class_data[:xsd_namespace]}\""
            xml << '  xmlns:gml="http://www.opengis.net/gml/3.2"'
            xml << "  gml:id=\"#{element_name.downcase}-1\">"

            attributes_data.each do |attr|
              xml << generate_attribute_element(
                attr,
                namespace_prefix,
                options
              )
            end

            xml << "</#{namespace_prefix}:#{element_name}>"
            xml.join("\n")
          end

          private

          # Generate XML element for an attribute
          #
          # @param attr [Hash] Attribute data
          # @param ns_prefix [String] Namespace prefix
          # @param options [Hash] Generation options
          # @return [String] XML element(s) for attribute
          def generate_attribute_element(attr, ns_prefix, options)
            lines = []

            # Add mapping comment
            if options[:include_comments]
              lines << ""
              lines << "  <!-- UML: #{attr[:name]} : #{attr[:uml_type]} " \
                       "[#{attr[:uml_multiplicity]}] -->"
              lines << "  <!-- XSD: #{attr[:xsd_name]} : #{attr[:xsd_type]} -->"
            end

            # Handle cardinality
            max_occurs = parse_max_occurs(attr[:xsd_max_occurs])
            count = calculate_instance_count(max_occurs)

            count.times do |i|
              value = if options[:include_sample_values]
                        generate_sample_value(attr, i)
                      else
                        "..."
                      end
              lines << "  <#{ns_prefix}:#{attr[:xsd_name]}>#{value}" \
                       "</#{ns_prefix}:#{attr[:xsd_name]}>"
            end

            lines.join("\n")
          end

          # Generate sample value for an attribute
          #
          # @param attr [Hash] Attribute data
          # @param index [Integer] Instance index for multiple values
          # @return [String] Sample value
          def generate_sample_value(attr, index)
            case attr[:xsd_type]
            when /CodeType/i
              ["residential", "commercial", "industrial"][index % 3]
            when /string/i, /CharacterString/i
              "Sample #{attr[:name]} #{index + 1}"
            when /integer/i, /int/i
              (index + 1).to_s
            when /double/i, /float/i, /decimal/i
              ((index + 1) * 1.5).to_s
            when /boolean/i
              (index % 2).zero? ? "true" : "false"
            when /date/i
              "2024-01-#{format('%02d', (index % 28) + 1)}"
            when /time/i
              "#{format('%02d', index % 24)}:00:00"
            else
              "value#{index + 1}"
            end
          end

          # Extract namespace prefix from namespace URI
          #
          # @param namespace [String] Namespace URI
          # @return [String] Namespace prefix
          def extract_prefix(namespace)
            case namespace
            when /uro/i then "uro"
            when /urf/i then "urf"
            when /gml/i then "gml"
            when /core/i then "core"
            else "ns"
            end
          end

          # Parse max occurs value
          #
          # @param max_occurs [String] Max occurs value
          # @return [String] Normalized max occurs value
          def parse_max_occurs(max_occurs)
            return "unbounded" if max_occurs.to_s == "unbounded"

            max_occurs.to_s
          end

          # Calculate number of instances to generate
          #
          # @param max_occurs [String] Max occurs value
          # @return [Integer] Number of instances to generate
          def calculate_instance_count(max_occurs)
            if max_occurs == "unbounded"
              2 # Generate 2 instances for unbounded
            else
              count = max_occurs.to_i
              [count, 1].max # At least 1, but respect max_occurs
            end
          end
        end
      end
    end
  end
end