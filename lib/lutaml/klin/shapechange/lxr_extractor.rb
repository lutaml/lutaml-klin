# frozen_string_literal: true

require_relative "config_parser"

module Lutaml
  module Klin
    module Shapechange
      # LxrExtractor extracts LXR (XML Schema Repository) package information
      # from ShapeChange configuration files
      class LxrExtractor
        attr_reader :parser

        def initialize(parser: nil)
          @parser = parser || ConfigParser.new
        end

        # Extract comprehensive schema information for LXR package creation
        # @param shapechange_config_path [String] path to ShapeChange configuration file
        # @return [Hash] schema information including xsd_files, namespace_mappings, schema_location_mappings
        def extract_schema_info(shapechange_config_path)
          config = parser.parse_file(shapechange_config_path)

          {
            xsd_files: extract_xsd_files(config),
            namespace_mappings: extract_namespace_mappings(config),
            schema_location_mappings: extract_schema_location_mappings(config)
          }
        end

        # Extract only XSD schema files referenced in the configuration
        # @param config [ShapeChangeConfiguration] parsed ShapeChange configuration
        # @return [Array<String>] list of XSD file paths
        def extract_xsd_files(config)
          xsd_files = []

          # Extract from PackageInfo xsdDocument attributes
          config.package_infos.each do |package|
            if package.xsd_document&.strip
              xsd_files << package.xsd_document.strip
            end
          end

          # Extract from xsd_schema_locations (if populated by parser)
          if config.respond_to?(:xsd_schema_locations) && config.xsd_schema_locations
            xsd_files.concat(config.xsd_schema_locations)
          end

          # Extract from XmlNamespace location attributes
          config.xml_namespaces.each do |namespace|
            if namespace.location&.strip&.end_with?(".xsd")
              xsd_files << namespace.location.strip
            end
          end

          xsd_files.compact.uniq
        end

        # Extract namespace prefix-to-URI mappings
        # @param config [ShapeChangeConfiguration] parsed ShapeChange configuration
        # @return [Array<Hash>] array of { prefix: String, uri: String } mappings
        def extract_namespace_mappings(config)
          mappings = []

          # From PackageInfo elements
          config.package_infos.each do |package|
            next unless package.nsabr&.strip && package.ns&.strip

            mappings << {
              prefix: package.nsabr.strip,
              uri: package.ns.strip
            }
          end

          # From XmlNamespace elements
          config.xml_namespaces.each do |namespace|
            next unless namespace.nsabr&.strip && namespace.ns&.strip

            mappings << {
              prefix: namespace.nsabr.strip,
              uri: namespace.ns.strip
            }
          end

          # Deduplicate by URI (keep first occurrence)
          seen_uris = Set.new
          mappings.reject do |mapping|
            if seen_uris.include?(mapping[:uri])
              true
            else
              seen_uris << mapping[:uri]
              false
            end
          end
        end

        # Extract schema location mappings for imports/includes
        # @param config [ShapeChangeConfiguration] parsed ShapeChange configuration
        # @return [Array<Hash>] array of { from: String, to: String } mappings
        def extract_schema_location_mappings(config)
          mappings = []

          # From target configuration schema includes
          if config.target_config&.dig(:schema_includes)
            config.target_config[:schema_includes].each do |include_info|
              if include_info[:from]
                mappings << {
                  from: include_info[:from],
                  to: normalize_schema_path(include_info[:from])
                }
              elsif include_info[:fallback]
                mappings << {
                  from: include_info[:fallback],
                  to: normalize_schema_path(include_info[:fallback])
                }
              end
            end
          end

          # From XmlNamespace locations (create mappings from remote to local)
          config.xml_namespaces.each do |namespace|
            unless namespace.location&.strip&.end_with?(".xsd") && namespace.nsabr&.strip
              next
            end

            local_path = build_local_schema_path(namespace.nsabr.strip)
            remote_location = namespace.location.strip

            mappings << {
              from: remote_location,
              to: local_path
            }
          end

          mappings.compact
        end

        private

        # Normalize schema file path for consistent local mapping
        # @param path [String] original schema path
        # @return [String] normalized path
        def normalize_schema_path(path)
          # Extract filename from full paths/URLs
          filename = File.basename(path.strip)

          # Create relative path structure for LXR packages
          if filename.end_with?(".xsd")
            "reference-docs/xsd/#{filename}"
          else
            path
          end
        end

        # Build local schema path from namespace prefix
        # @param prefix [String] namespace prefix
        # @return [String] local schema path
        def build_local_schema_path(prefix)
          case prefix
          when "gml"
            "reference-docs/xsd/gml/#{prefix}.xsd"
          when "urf", "uro"
            "reference-docs/xsd/i-ur/#{prefix}.xsd"
          when "citygml"
            "reference-docs/xsd/citygml/#{prefix}.xsd"
          else
            "reference-docs/xsd/#{prefix}.xsd"
          end
        end
      end
    end
  end
end
