# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Shapechange
      class XsdMapEntry < Lutaml::Model::Serializable
        attribute :type, :string
        attribute :xsd_encoding_rules, :string  # Space-separated rule names
        attribute :xml_type, :string
        attribute :xml_property_type, :string
        attribute :xml_element, :string
        attribute :xml_type_type, :string      # "simple" or "complex"
        attribute :xml_type_content, :string   # "simple" or "complex"
        attribute :xml_type_nil_reason, :string

        xml do
          root "XsdMapEntry"
          map_attribute "type", to: :type
          map_attribute "xsdEncodingRules", to: :xsd_encoding_rules
          map_attribute "xmlType", to: :xml_type
          map_attribute "xmlPropertyType", to: :xml_property_type
          map_attribute "xmlElement", to: :xml_element
          map_attribute "xmlTypeType", to: :xml_type_type
          map_attribute "xmlTypeContent", to: :xml_type_content
          map_attribute "xmlTypeNilReason", to: :xml_type_nil_reason
        end

        # Check if this mapping applies to an encoding rule
        def applies_to?(encoding_rule_name)
          return true unless xsd_encoding_rules

          xsd_encoding_rules.split.include?(encoding_rule_name)
        end
      end
    end
  end
end
