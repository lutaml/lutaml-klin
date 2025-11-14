# frozen_string_literal: true

require_relative "../domain/services/lookup_service"
require_relative "../models/mapping/schema_mapping"

module Lutaml
  module Klin
    module Application
      # Application-layer workflow for performing bidirectional lookups
      #
      # Orchestrates loading mapping files and executing lookup queries
      # with support for multiple output formats and interactive mode.
      class LookupWorkflow
        attr_reader :mapping, :lookup_service

        # Initialize workflow with a mapping file
        #
        # @param mapping_file_path [String] path to the YAML mapping file
        # @raise [Lutaml::Klin::Error] if file doesn't exist or is invalid
        def initialize(mapping_file_path)
          @mapping_file_path = mapping_file_path
          load_mapping
          @lookup_service = Domain::Services::LookupService.new(@mapping)
        end

        # Perform UML to XSD lookup
        #
        # @param uml_identifier [String] UML class or attribute identifier
        # @param type [Symbol] lookup type (:class or :attribute)
        # @param fuzzy [Boolean] enable fuzzy matching
        # @return [Domain::LookupResult] the lookup result
        def lookup_uml_to_xsd(uml_identifier, type: :auto, fuzzy: false)
          case type
          when :class
            @lookup_service.find_xsd_for_uml_class(uml_identifier, fuzzy: fuzzy)
          when :attribute
            # Parse class and attribute from identifier
            parts = uml_identifier.split("::")
            if parts.size < 2
              raise Error, "Attribute lookup requires format 'ClassName::attributeName'"
            end

            attr_name = parts.pop
            class_qname = parts.join("::")
            @lookup_service.find_xsd_for_uml_attribute(class_qname, attr_name, fuzzy: fuzzy)
          when :auto
            # Auto-detect based on format
            @lookup_service.auto_lookup(uml_identifier, fuzzy: fuzzy)
          else
            raise Error, "Unknown lookup type: #{type}"
          end
        end

        # Perform XSD to UML lookup
        #
        # @param xsd_identifier [String] XSD type or element identifier
        # @param type [Symbol] lookup type (:type, :element, or :auto)
        # @param fuzzy [Boolean] enable fuzzy matching
        # @return [Domain::LookupResult] the lookup result
        def lookup_xsd_to_uml(xsd_identifier, type: :auto, fuzzy: false)
          case type
          when :type
            @lookup_service.find_uml_for_xsd_type(xsd_identifier, fuzzy: fuzzy)
          when :element
            @lookup_service.find_uml_for_xsd_element(xsd_identifier, fuzzy: fuzzy)
          when :auto
            # Auto-detect - try both type and element
            @lookup_service.auto_lookup(xsd_identifier, fuzzy: fuzzy)
          else
            raise Error, "Unknown lookup type: #{type}"
          end
        end

        # Perform auto-detection lookup
        #
        # @param identifier [String] the identifier to look up
        # @param fuzzy [Boolean] enable fuzzy matching
        # @return [Domain::LookupResult] the lookup result
        def auto_lookup(identifier, fuzzy: false)
          @lookup_service.auto_lookup(identifier, fuzzy: fuzzy)
        end

        # Format lookup result for output
        #
        # @param result [Domain::LookupResult] the lookup result
        # @param format [Symbol] output format (:text, :json, or :yaml)
        # @return [String] formatted output
        def format_result(result, format: :text)
          case format
          when :json
            format_json(result)
          when :yaml
            format_yaml(result)
          when :text
            format_text(result)
          else
            raise Error, "Unknown format: #{format}"
          end
        end

        # Interactive lookup mode
        #
        # @return [void]
        def interactive_lookup
          puts "=== Lutaml-Klin Interactive Lookup ==="
          puts "Enter 'exit' or 'quit' to exit"
          puts "Enter 'help' for usage instructions"
          puts

          loop do
            print "lookup> "
            input = $stdin.gets&.chomp
            break if input.nil? || %w[exit quit].include?(input.downcase)

            next if input.strip.empty?

            if input.downcase == "help"
              print_help
              next
            end

            process_interactive_query(input)
          end

          puts "Goodbye!"
        end

        private

        # Load and parse the mapping file
        #
        # @raise [Lutaml::Klin::Error] if file doesn't exist or is invalid
        def load_mapping
          unless File.exist?(@mapping_file_path)
            raise Error, "Mapping file not found: #{@mapping_file_path}"
          end

          yaml_content = File.read(@mapping_file_path)
          @mapping = Mapping::SchemaMapping.from_yaml(yaml_content)
        rescue StandardError => e
          raise Error, "Failed to load mapping file: #{e.message}"
        end

        # Format result as JSON
        #
        # @param result [Domain::LookupResult] the result
        # @return [String] JSON output
        def format_json(result)
          require "json"
          JSON.pretty_generate(result.to_h)
        end

        # Format result as YAML
        #
        # @param result [Domain::LookupResult] the result
        # @return [String] YAML output
        def format_yaml(result)
          require "yaml"
          result.to_h.to_yaml
        end

        # Format result as human-readable text
        #
        # @param result [Domain::LookupResult] the result
        # @return [String] text output
        def format_text(result)
          lines = []
          lines << "=== Lookup Result ==="
          lines << "Query: #{result.query}"
          lines << "Direction: #{result.direction}"
          lines << "Matches: #{result.match_count}"
          lines << ""

          if result.found?
            result.matches.each_with_index do |match, index|
              lines << "--- Match #{index + 1} ---"
              lines.concat(format_match(match, result.direction))
              lines << ""
            end
          else
            lines << "No matches found."
            if result.metadata[:fuzzy] == false
              lines << "Try enabling fuzzy matching with --fuzzy flag."
            end
          end

          lines.join("\n")
        end

        # Format a single match
        #
        # @param match [Hash] the match data
        # @param direction [Symbol] lookup direction
        # @return [Array<String>] formatted match lines
        def format_match(match, direction)
          lines = []

          if direction == :uml_to_xsd || direction == :auto
            # UML → XSD mapping
            if match[:uml_class]
              lines << "UML Class: #{match[:uml_class]}"
              lines << "  Package: #{match[:uml_package]}" if match[:uml_package]
              lines << "  Stereotype: #{match[:uml_stereotype]}" if match[:uml_stereotype]
            end

            if match[:uml_attribute]
              lines << "UML Attribute: #{match[:uml_attribute]}"
              lines << "  Type: #{match[:uml_type]}" if match[:uml_type]
              lines << "  Multiplicity: #{match[:uml_multiplicity]}" if match[:uml_multiplicity]
            end

            lines << "XSD Element: #{match[:xsd_element]}" if match[:xsd_element]
            lines << "XSD Type: #{match[:xsd_type]}" if match[:xsd_type]
            lines << "XSD Type Name: #{match[:xsd_type_name]}" if match[:xsd_type_name]
            lines << "XSD Namespace: #{match[:xsd_namespace]}" if match[:xsd_namespace]

            if match[:xsd_name]
              lines << "XSD Name: #{match[:xsd_name]}"
              lines << "  Namespace: #{match[:xsd_namespace]}" if match[:xsd_namespace]
              lines << "  Type: #{match[:xsd_type]}" if match[:xsd_type]
              lines << "  Path: #{match[:xsd_path]}" if match[:xsd_path]
              lines << "  Min Occurs: #{match[:min_occurs]}" if match[:min_occurs]
              lines << "  Max Occurs: #{match[:max_occurs]}" if match[:max_occurs]
              lines << "  Is Element: #{match[:is_element]}" unless match[:is_element].nil?
            end
          elsif direction == :xsd_to_uml
            # XSD → UML mapping
            lines << "XSD Element: #{match[:xsd_element]}" if match[:xsd_element]
            lines << "XSD Type: #{match[:xsd_type]}" if match[:xsd_type]
            lines << "XSD Namespace: #{match[:xsd_namespace]}" if match[:xsd_namespace]

            if match[:uml_class]
              lines << "UML Class: #{match[:uml_class]}"
              lines << "  Name: #{match[:uml_name]}" if match[:uml_name]
              lines << "  Package: #{match[:uml_package]}" if match[:uml_package]
              lines << "  Stereotype: #{match[:uml_stereotype]}" if match[:uml_stereotype]
            end

            if match[:uml_attribute]
              lines << "UML Attribute: #{match[:uml_attribute]}"
              lines << "  Class: #{match[:uml_class]}" if match[:uml_class]
              lines << "  Type: #{match[:uml_type]}" if match[:uml_type]
              lines << "  Multiplicity: #{match[:uml_multiplicity]}" if match[:uml_multiplicity]
            end
          end

          # Add resolution info
          if match[:resolution_status]
            lines << "Resolution Status: #{match[:resolution_status]}"
            lines << "Resolution Method: #{match[:resolution_method]}" if match[:resolution_method]
          end

          # Add match quality if available
          if match[:match_quality]
            lines << "Match Quality: #{(match[:match_quality] * 100).round(1)}%"
          end

          lines
        end

        # Process an interactive query
        #
        # @param query [String] the query string
        def process_interactive_query(query)
          # Parse query for options
          fuzzy = query.include?("--fuzzy") || query.include?("-f")
          query = query.gsub(/--fuzzy|-f/, "").strip

          # Perform lookup
          result = auto_lookup(query, fuzzy: fuzzy)

          # Display result
          puts format_text(result)
          puts
        rescue StandardError => e
          puts "Error: #{e.message}"
          puts
        end

        # Print help message
        def print_help
          puts <<~HELP
            Interactive Lookup Help
            =======================

            Usage:
              - Enter a UML class/attribute name or XSD type/element name
              - Add --fuzzy or -f for fuzzy matching
              - The system will auto-detect the lookup direction

            Examples:
              ModelRoot::i-UR::urf::UrbanPlanningArea
              UrbanPlanningArea::areaType
              gml:CodeType
              urf:UrbanPlanningAreaType
              --fuzzy UrbanPlanning

            Commands:
              help  - Show this help message
              exit  - Exit interactive mode
              quit  - Exit interactive mode

          HELP
        end
      end
    end
  end
end