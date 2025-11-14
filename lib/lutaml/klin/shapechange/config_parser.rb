# frozen_string_literal: true

require "moxml"
require "nokogiri"
require_relative "models/config/shape_change_configuration"
require_relative "xinclude_resolver"

module Lutaml
  module Klin
    module Shapechange
      # ConfigParser parses ShapeChange XML configuration files
      class ConfigParser
        attr_reader :resolver

        def initialize(resolver: nil)
          @resolver = resolver || XIncludeResolver.new
        end

        def parse_file(path)
          unless File.exist?(path)
            raise FatalError, "Configuration file not found: #{path}"
          end

          content = File.read(path)
          base_path = File.dirname(File.expand_path(path))

          resolved_content = resolver.resolve_includes(
            content,
            base_path: base_path
          )
          parse_content(resolved_content)
        rescue FatalError
          raise
        rescue StandardError => e
          raise FatalError, "Failed to parse configuration: #{e.message}"
        end

        def parse_content(xml_content)
          # Parse with Nokogiri since the XML structure is complex
          doc = Nokogiri::XML(xml_content)
          doc.remove_namespaces!

          config = ShapeChangeConfiguration.new

          # Extract xml_namespaces from <input><xmlNamespaces><XmlNamespace>
          config.xml_namespaces = extract_xml_namespaces(doc)

          # Extract xsd_map_entries from <input><xsdMapEntries><XsdMapEntry>
          config.xsd_map_entries = extract_xsd_map_entries(doc)

          # Extract package_infos from <input><packages><PackageInfo>
          config.package_infos = extract_package_infos(doc)

          # Extract encoding_rules from <rules><EncodingRule>
          config.encoding_rules = extract_encoding_rules(doc)

          # Extract XSD schema locations and mappings for LXR extraction
          config.xsd_schema_locations = extract_xsd_schema_locations(doc)

          # Extract target configuration from <targets><TargetXmlSchema>
          config.target_config = extract_target_config(doc)

          config
        rescue StandardError => e
          raise FatalError,
                "Failed to parse configuration content: #{e.message}"
        end

        private

        def extract_xml_namespaces(doc)
          namespaces = []
          doc.xpath("//xmlNamespaces/XmlNamespace").each do |node|
            namespaces << XmlNamespace.new(
              nsabr: node["nsabr"],
              ns: node["ns"],
              location: node["location"]
            )
          end
          namespaces
        end

        def extract_xsd_map_entries(doc)
          entries = []
          doc.xpath("//xsdMapEntries/XsdMapEntry").each do |node|
            entries << XsdMapEntry.new(
              type: node["type"],
              xsd_encoding_rules: node["xsdEncodingRules"],
              xml_type: node["xmlType"],
              xml_property_type: node["xmlPropertyType"],
              xml_element: node["xmlElement"],
              xml_type_type: node["xmlTypeType"],
              xml_type_content: node["xmlTypeContent"],
              xml_type_nil_reason: node["xmlTypeNilReason"]
            )
          end
          entries
        end

        def extract_package_infos(doc)
          packages = []
          doc.xpath("//packages/PackageInfo").each do |node|
            packages << PackageInfo.new(
              package_name: node["packageName"],
              ns: node["ns"],
              nsabr: node["nsabr"],
              xsd_document: node["xsdDocument"],
              version: node["version"]
            )
          end
          packages
        end

        def extract_encoding_rules(doc)
          rules = []
          doc.xpath("//rules/EncodingRule").each do |node|
            rule_names = node.xpath("rule").map { |r| r["name"] }

            rules << EncodingRule.new(
              name: node["name"],
              extends: node["extends"],
              rules: rule_names
            )
          end
          rules
        end

        def extract_xsd_schema_locations(doc)
          locations = []

          # Extract from PackageInfo xsdDocument attributes
          doc.xpath("//packages/PackageInfo[@xsdDocument]").each do |node|
            xsd_doc = node["xsdDocument"]
            locations << xsd_doc.strip if xsd_doc&.strip
          end

          # Extract from XmlNamespace location attributes (filter for XSD files)
          doc.xpath("//xmlNamespaces/XmlNamespace[@location]").each do |node|
            location = node["location"]
            if location&.strip&.end_with?('.xsd')
              locations << location.strip
            end
          end

          locations
        end

        def extract_schema_includes(doc)
          includes = []

          # Extract xi:include elements for XSD files
          doc.xpath("//xi:include[contains(@href, '.xsd')]").each do |node|
            href = node["href"]
            includes << { from: href } if href&.strip
          end

          # Extract xi:fallback elements for XSD files
          doc.xpath("//xi:fallback[contains(., '.xsd')]").each do |node|
            fallback_content = node.text.strip
            includes << { fallback: fallback_content } if fallback_content
          end

          includes
        end

        def extract_target_config(doc)
          target_node = doc.at_xpath("//targets/TargetXmlSchema")
          return {} unless target_node

          {
            mode: target_node["mode"],
            default_encoding_rule: target_node.at_xpath("targetParameter[@name='defaultEncodingRule']")&.[]("value"),
            output_directory: target_node.at_xpath("targetParameter[@name='outputDirectory']")&.[]("value"),
            xsd_schema_locations: extract_xsd_schema_locations(doc),
            schema_includes: extract_schema_includes(doc)
          }
        end
      end
    end
  end
end
