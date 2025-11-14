# frozen_string_literal: true

require_relative "parsers/standard_rules_parser"

module Lutaml
  module Klin
    module Shapechange
      # Registry for managing encoding rules and their relationships
      # Single Responsibility: Store and lookup rules with inheritance
      class RuleRegistry
        attr_reader :encoding_rules, :rule_definitions

        def initialize
          @encoding_rules = {}      # name => EncodingRule
          @rule_definitions = {}    # id => RuleDefinition
        end

        # Build registry with ShapeChange standard rules loaded from XML
        # @param shapechange_config_dir [String, nil] Path to ShapeChange config directory
        # @return [RuleRegistry] Registry with loaded rules
        def self.build_with_shapechange_standards(shapechange_config_dir = nil)
          registry = new

          # Try to load from ShapeChange StandardRules.xml if available
          if shapechange_config_dir
            standard_rules_path = File.join(shapechange_config_dir, "StandardRules.xml")

            if File.exist?(standard_rules_path)
              encoding_rules = Parsers::StandardRulesParser.parse_encoding_rules(standard_rules_path)
              encoding_rules.each do |er|
                registry.register_encoding_rule(er)
              end
              return registry
            end
          end

          # Fallback to base encoding rules if ShapeChange XML not available
          require_relative "base_encoding_rules"
          BaseEncodingRules.load_into(registry)

          registry
        end

        # Register an encoding rule
        # @param encoding_rule [EncodingRule] The encoding rule to register
        def register_encoding_rule(encoding_rule)
          @encoding_rules[encoding_rule.name] = encoding_rule
        end

        # Register a rule definition
        # @param rule_def [RuleDefinition] The rule definition to register
        def register_rule_definition(rule_def)
          @rule_definitions[rule_def.id] = rule_def
        end

        # Check if a rule applies to an encoding rule (with inheritance)
        # @param rule_id [String] Rule identifier (e.g., "rule-xsd-cls-type")
        # @param encoding_rule_name [String] Encoding rule name (e.g., "iso19136_2007")
        # @return [Boolean] true if rule applies
        def has_rule?(rule_id, encoding_rule_name)
          current = @encoding_rules[encoding_rule_name]
          return false unless current

          # Check current encoding rule
          return true if current.rules&.include?(rule_id)

          # Check parent encoding rule (inheritance)
          if current.extends
            has_rule?(rule_id, current.extends)
          else
            false
          end
        end

        # Get all rules for an encoding rule (with inheritance)
        # @param encoding_rule_name [String] Encoding rule name
        # @return [Array<String>] All rule IDs that apply
        def all_rules_for(encoding_rule_name)
          rules = []
          current = @encoding_rules[encoding_rule_name]

          while current
            rules.concat(current.rules) if current.rules
            current = current.extends ? @encoding_rules[current.extends] : nil
          end

          rules.uniq
        end

        # Get encoding rule by name
        # @param name [String] Encoding rule name
        # @return [EncodingRule, nil] The encoding rule or nil if not found
        def encoding_rule(name)
          @encoding_rules[name]
        end

        # Get rule definition by ID
        # @param id [String] Rule ID
        # @return [RuleDefinition, nil] The rule definition or nil if not found
        def rule_definition(id)
          @rule_definitions[id]
        end
      end
    end
  end
end