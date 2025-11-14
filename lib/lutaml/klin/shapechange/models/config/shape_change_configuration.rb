# frozen_string_literal: true

require "lutaml/model"
require_relative "xml_namespace"
require_relative "xsd_map_entry"
require_relative "package_info"
require_relative "encoding_rule"

module Lutaml
  module Klin
    module Shapechange
      class ShapeChangeConfiguration < Lutaml::Model::Serializable
        attribute :xml_namespaces, XmlNamespace, collection: true
        attribute :xsd_map_entries, XsdMapEntry, collection: true
        attribute :package_infos, PackageInfo, collection: true
        attribute :encoding_rules, EncodingRule, collection: true
        attribute :xsd_schema_locations, :string, collection: true
        attribute :target_config, :hash

        xml do
          root "ShapeChangeConfiguration", mixed: true
          namespace "http://www.interactive-instruments.de/ShapeChange/Configuration/1.1",
                    "sc"

          map_element "XmlNamespace", to: :xml_namespaces
          map_element "XsdMapEntry", to: :xsd_map_entries
          map_element "PackageInfo", to: :package_infos
          map_element "EncodingRule", to: :encoding_rules
        end

        # Find namespace for a UML package
        def namespace_for_package(package_path)
          simple_name = package_path.split('::').last.strip

          pkg_info = package_infos.find do |pi|
            pi.package_name&.strip == simple_name ||
            pi.package_name&.strip == package_path
          end

          pkg_info&.ns&.strip
        end

        # Find prefix for a namespace URI
        def prefix_for_namespace(namespace_uri)
          namespace_uri = namespace_uri&.strip
          return nil unless namespace_uri

          # Try xml_namespaces first
          xml_ns = xml_namespaces.find { |ns| ns.ns&.strip == namespace_uri }
          return xml_ns.nsabr&.strip if xml_ns

          # Try package_infos
          pkg_info = package_infos.find { |pi| pi.ns&.strip == namespace_uri }
          pkg_info&.nsabr&.strip
        end

        # Find type mapping for UML type
        def find_type_mapping(uml_type, encoding_rule: "citygml")
          # Normalize type name (gml::CodeType → gml:CodeType)
          clean_type = uml_type.to_s.gsub('::', ':').strip

          xsd_map_entries.find do |entry|
            # Normalize BOTH the search term and the entry's type
            entry_type = entry.type&.gsub('::', ':')&.strip
            entry_type == clean_type &&
            entry.applies_to?(encoding_rule)
          end
        end

        # Check if type mapping exists for UML type (wrapper for find_type_mapping)
        def has_type_mapping?(uml_type, encoding_rule: "citygml")
          !find_type_mapping(uml_type, encoding_rule: encoding_rule).nil?
        end

        # Get type mapping for UML type (wrapper for find_type_mapping)
        def get_type_mapping(uml_type, encoding_rule: "citygml")
          find_type_mapping(uml_type, encoding_rule: encoding_rule)
        end
      end
    end
  end
end
