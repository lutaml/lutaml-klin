# frozen_string_literal: true

module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        module ClassRules
          # Processor for rule-xsd-cls-standard-19139-isoType
          # Adds @gco:isoType attribute to classes extending ISO 19139 metadata types
          #
          # Single Responsibility: Handle ISO 19139 isoType attribute generation
          class Standard19139IsoTypeProcessor < BaseProcessor
            # ISO 19139 family of namespaces
            ISO_19139_NAMESPACES = [
              "http://www.isotc211.org/2005/gco",
              "http://www.isotc211.org/2005/gmd",
              "http://www.isotc211.org/2005/gmx",
              "http://www.isotc211.org/2005/gsr",
              "http://www.isotc211.org/2005/gss",
              "http://www.isotc211.org/2005/gts",
            ].freeze

            # Check if this processor applies to the given class
            # @param klass [Lutaml::Uml::Class] The class to check
            # @param config [Configuration] The configuration
            # @return [Boolean] true if applicable
            def self.applies_to?(klass, config)
              return false unless klass.base_class

              # Must have the rule enabled
              config.has_rule?("rule-xsd-cls-standard-19139-isoType")
            end

            # Process the class to add @gco:isoType attribute
            # @param klass [Lutaml::Uml::Class] The class to process
            # @param builder [XsdBuilder] The XSD builder
            # @param config [Configuration] The configuration
            # @return [Hash, nil] ISO type information or nil
            def self.process(klass, builder, config)
              base_class = klass.base_class
              return nil unless base_class

              # Look up element map entry for the base type
              base_type_name = base_class.name
              encoding_rule = klass.encoding_rule || "xsd"

              element_map_entry = config.element_map_entry(
                base_type_name,
                encoding_rule
              )
              return nil unless element_map_entry

              # Extract XML element QName (e.g., "gmd:CI_Citation")
              xml_element = element_map_entry[:element]&.strip
              return nil if xml_element.nil? || xml_element.empty?

              # Parse QName to get namespace and local name
              colon_idx = xml_element.index(":")
              return nil unless colon_idx && colon_idx > 0

              nsabr = xml_element[0...colon_idx]
              local_name = xml_element[(colon_idx + 1)..-1]

              # Get full namespace URI
              namespace = config.full_namespace(nsabr)

              # Handle case where namespace might be from the same package
              if namespace.nil? && base_class.package
                pkg_nsabr = base_class.package.xmlns
                if pkg_nsabr&.downcase == nsabr.downcase
                  namespace = base_class.package.target_namespace
                end
              end

              return nil unless namespace

              # Check if namespace is one of the ISO 19139 family
              return nil unless ISO_19139_NAMESPACES.include?(namespace)

              # Return ISO type information
              {
                namespace: namespace,
                namespace_abbr: nsabr,
                local_name: local_name,
                gco_namespace: config.full_namespace("gco"),
              }
            end

            # Add @gco:isoType attribute to the extension element
            # @param extension_element [Nokogiri::XML::Element] The xs:extension element
            # @param iso_type_info [Hash] ISO type information
            # @param builder [XsdBuilder] The XSD builder
            def self.add_iso_type_attribute(extension_element, iso_type_info, builder)
              # Ensure gco namespace is imported
              builder.add_namespace_import(
                "gco",
                iso_type_info[:gco_namespace]
              )

              # Create attribute element
              attr_element = builder.create_element("attribute")
              builder.add_attribute(attr_element, "ref", "gco:isoType")
              builder.add_attribute(attr_element, "use", "required")
              builder.add_attribute(attr_element, "fixed", iso_type_info[:local_name])

              # Append to extension element
              extension_element.add_child(attr_element)
            end
          end
        end
      end
    end
  end
end