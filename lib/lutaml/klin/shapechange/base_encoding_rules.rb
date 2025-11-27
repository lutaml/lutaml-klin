# frozen_string_literal: true

require_relative "models/config/encoding_rule"

module Lutaml
  module Klin
    module Shapechange
      # DEPRECATED: Base encoding rules defined programmatically
      # These are hardcoded fallback rules used only when ShapeChange
      # StandardRules.xml is not available.
      #
      # ARCHITECTURAL NOTE: This violates "configuration over code" principle.
      # Prefer loading rules from ShapeChange StandardRules.xml via
      # RuleRegistry.build_with_shapechange_standards()
      #
      # This module is kept only for:
      # 1. Fallback when ShapeChange XML files are unavailable
      # 2. Standalone operation without ShapeChange installation
      #
      # For production use, always load from StandardRules.xml
      module BaseEncodingRules
        # Core encoding rule (the ultimate base "*")
        # Source: XmlSchema.java lines with ProcessRuleSet("*", ...)
        def self.core
          EncodingRule.new.tap do |er|
            er.name = "*"
            er.extends = nil
            er.rules = %w[
              req-xsd-pkg-xsdDocument-unique
              req-xsd-cls-name-unique
              req-xsd-cls-ncname
              req-xsd-prop-data-type
              req-xsd-prop-value-type-exists
              req-xsd-prop-ncname
              rule-xsd-pkg-contained-packages
              rule-xsd-pkg-dependencies
              rule-xsd-cls-unknown-as-object
              rule-xsd-cls-object-element
              rule-xsd-cls-type
              rule-xsd-cls-property-type
              rule-xsd-cls-local-properties
              rule-xsd-cls-sequence
              rule-xsd-prop-encode-properties
            ]
          end
        end

        # Base iso19136_2007 encoding rule (GML 3.2)
        # Source: XmlSchema.java lines with ProcessRuleSet("iso19136_2007", "*", ...)
        def self.iso19136_2007
          EncodingRule.new.tap do |er|
            er.name = "iso19136_2007"
            er.extends = "*"
            er.rules = %w[
              req-xsd-cls-generalization-consistent
              rule-xsd-all-naming-gml
              rule-xsd-cls-global-enumeration
              rule-xsd-cls-codelist-asDictionary
              rule-xsd-cls-standard-gml-property-types
              rule-xsd-cls-noPropertyType
              rule-xsd-cls-byValuePropertyType
              rule-xsd-pkg-gmlProfileSchema
              rule-xsd-prop-targetElement
              rule-xsd-prop-reverseProperty
              rule-xsd-prop-defaultCodeSpace
              rule-xsd-prop-inlineOrByReference
            ]
          end
        end

        # GML 3.3 encoding rule
        # Source: XmlSchema.java lines with ProcessRuleSet("gml33", "*", ...)
        def self.gml33
          EncodingRule.new.tap do |er|
            er.name = "gml33"
            er.extends = "*"
            er.rules = %w[
              req-xsd-cls-generalization-consistent
              rule-xsd-all-naming-gml
              rule-xsd-cls-global-enumeration
              rule-xsd-cls-codelist-asDictionaryGml33
              rule-xsd-cls-standard-gml-property-types
              rule-xsd-cls-noPropertyType
              rule-xsd-cls-byValuePropertyType
              rule-xsd-pkg-gmlProfileSchema
              rule-xsd-prop-targetElement
              rule-xsd-prop-reverseProperty
              rule-xsd-prop-defaultCodeSpace
              rule-xsd-prop-inlineOrByReference
              rule-xsd-rel-association-classes
            ]
          end
        end

        # ISO 19139:2007 encoding rule (Metadata)
        # Source: XmlSchema.java lines with ProcessRuleSet("iso19139_2007", "*", ...)
        def self.iso19139_2007
          EncodingRule.new.tap do |er|
            er.name = "iso19139_2007"
            er.extends = "*"
            er.rules = %w[
              rule-xsd-cls-enum-object-element
              rule-xsd-cls-enum-property-type
              rule-xsd-cls-global-enumeration
              rule-xsd-cls-standard-19139-property-types
              rule-xsd-all-naming-19139
            ]
          end
        end

        # CityGML 2.0 encoding rule (extends GML 3.2)
        # Based on CityGML 2.0 specification using iso19136_2007 as base
        def self.citygml
          EncodingRule.new.tap do |er|
            er.name = "citygml"
            er.extends = "iso19136_2007"
            er.rules = [
              # Inherit all iso19136_2007 rules
              # Add PLATEAU-specific rule for ADE hook elements
              "rule-xsd-cls-plateau-ade-hooks"
            ]
          end
        end

        # PLATEAU encoding rule (extends CityGML with ADE hooks)
        # Generates PLATEAU URO/URF extensions for CityGML base types
        # Uses X- prefix per convention for custom (non-ShapeChange) rules
        def self.x_plateau
          EncodingRule.new.tap do |er|
            er.name = "X-plateau"
            er.extends = "citygml"
            er.rules = [
              # Add PLATEAU-specific rule for ADE hook elements
              "rule-xsd-cls-plateau-ade-hooks"
            ]
          end
        end

        # Get all base encoding rules
        # @return [Array<EncodingRule>] All base encoding rules
        def self.all
          [
            core,
            iso19136_2007,
            gml33,
            iso19139_2007,
            citygml,
            x_plateau
          ]
        end

        # Load base encoding rules into registry
        # @param registry [RuleRegistry] The registry to populate
        def self.load_into(registry)
          all.each do |encoding_rule|
            registry.register_encoding_rule(encoding_rule)
          end
        end
      end
    end
  end
end
