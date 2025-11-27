# frozen_string_literal: true

require_relative "models/rule_definition"

module Lutaml
  module Klin
    module Shapechange
      # Standard encoding rules for XSD generation
      # Configuration-driven approach following Open/Closed principle
      STANDARD_RULES = {
        # Core rules (always active for XSD generation)
        "rule-xsd-cls-type" => {
          scope: "class",
          category: "required",
          description: "Generate complexType for classes",
          applies_to: []
        },
        "rule-xsd-cls-object-element" => {
          scope: "class",
          category: "required",
          description: "Generate element for classes",
          applies_to: []
        },
        "rule-xsd-prop-att" => {
          scope: "property",
          category: "required",
          description: "Generate attribute for properties",
          applies_to: []
        },

        # GML 3.2 specific rules
        "rule-xsd-all-naming-gml" => {
          scope: "all",
          category: "optional",
          description: "Use GML naming conventions",
          applies_to: []
        },
        "rule-xsd-cls-standard-gml-property-types" => {
          scope: "class",
          category: "optional",
          description: "Use standard GML property types",
          applies_to: []
        },
        "rule-xsd-cls-byValuePropertyType" => {
          scope: "class",
          category: "optional",
          description: "Generate byValue property types",
          applies_to: []
        },
        "rule-xsd-cls-standard-19136-property-types" => {
          scope: "class",
          category: "optional",
          description: "Use ISO 19136 standard property types",
          applies_to: []
        },

        # Type-specific rules
        "rule-xsd-cls-codelist-asDictionary" => {
          scope: "class",
          category: "optional",
          description: "Represent code lists as dictionaries",
          applies_to: ["CodeList"]
        },
        "rule-xsd-cls-enum-object-element" => {
          scope: "class",
          category: "optional",
          description: "Generate object element for enumerations",
          applies_to: ["Enumeration"]
        },
        "rule-xsd-cls-union-as-group-property-type" => {
          scope: "class",
          category: "optional",
          description: "Represent unions as group property types",
          applies_to: ["Union"]
        },
        "rule-xsd-cls-sequence" => {
          scope: "class",
          category: "required",
          description: "Generate sequence content model for classes",
          applies_to: []
        },

        # Inheritance rules
        "rule-xsd-cls-no-base-class" => {
          scope: "class",
          category: "optional",
          description: "Do not generate base class elements",
          applies_to: []
        },
        "rule-xsd-cls-no-abstract-classes" => {
          scope: "class",
          category: "optional",
          description: "Do not generate abstract classes",
          applies_to: []
        },

        # Property encoding rules
        "rule-xsd-prop-encode-properties" => {
          scope: "class",
          category: "required",
          description: "Encode properties as elements in sequence",
          applies_to: []
        },
        "rule-xsd-prop-sequence" => {
          scope: "property",
          category: "optional",
          description: "Use sequence for properties",
          applies_to: []
        },
        "rule-xsd-prop-metadata-gmlsf-byReference" => {
          scope: "property",
          category: "optional",
          description: "Support metadata by reference",
          applies_to: []
        },
        "rule-xsd-prop-nillable" => {
          scope: "property",
          category: "optional",
          description: "Make properties nillable",
          applies_to: []
        },

        # Basic type rules
        "rule-xsd-cls-basictype" => {
          scope: "class",
          category: "optional",
          description: "Generate basic types with facet restrictions",
          applies_to: ["BasicType"]
        },
        "rule-xsd-cls-basictype-list" => {
          scope: "class",
          category: "optional",
          description: "Generate list-based basic types",
          applies_to: ["BasicType"]
        },
        "rule-xsd-cls-local-basictype" => {
          scope: "class",
          category: "optional",
          description: "Generate anonymous basic types for local scope",
          applies_to: ["BasicType"]
        },

        # Package rules
        "rule-xsd-pkg-contained-packages" => {
          scope: "package",
          category: "optional",
          description: "Include contained packages",
          applies_to: []
        },
        "rule-xsd-pkg-gmlProfileSchema" => {
          scope: "package",
          category: "optional",
          description: "Generate GML profile schema",
          applies_to: []
        },

        # PLATEAU-specific rules
        "rule-xsd-cls-plateau-ade-hooks" => {
          scope: "class",
          category: "optional",
          description: "Generate PLATEAU ADE hook elements for CityGML integration",
          applies_to: []
        }
      }.freeze

      # Load standard rules into a registry
      # @param registry [RuleRegistry] The registry to populate
      def self.load_standard_rules(registry)
        STANDARD_RULES.each do |rule_id, metadata|
          rule_def = RuleDefinition.new.tap do |rd|
            rd.id = rule_id
            rd.scope = metadata[:scope]
            rd.category = metadata[:category]
            rd.description = metadata[:description]
            rd.applies_to = metadata[:applies_to]
          end
          registry.register_rule_definition(rule_def)
        end
      end
    end
  end
end
