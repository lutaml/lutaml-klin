# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Shapechange
      # Helper class to parse rule elements with name attributes
      class Rule < Lutaml::Model::Serializable
        attribute :name, :string

        xml do
          root "rule"
          map_attribute "name", to: :name
        end
      end

      # Represents an encoding rule from ShapeChange configuration
      class EncodingRule < Lutaml::Model::Serializable
        attribute :name, :string
        attribute :extends, :string
        attribute :rule_elements, Rule, collection: true

        xml do
          root "EncodingRule"
          map_attribute "name", to: :name
          map_attribute "extends", to: :extends
          map_element "rule", to: :rule_elements
        end

        # Get rule names as array of strings
        # @return [Array<String>] Rule names
        def rules
          rule_elements&.map(&:name) || []
        end

        # Set rules from array of strings
        # @param rule_names [Array<String>] Rule names to set
        def rules=(rule_names)
          self.rule_elements = rule_names&.map { |name| Rule.new(name: name) } || []
        end

        # Check if this encoding rule includes a specific rule
        # (considering inheritance chain)
        def has_rule?(rule_name, all_encoding_rules = [])
          return true if rules&.include?(rule_name)

          if extends
            parent = all_encoding_rules.find { |er| er.name == extends }
            return parent.has_rule?(rule_name, all_encoding_rules) if parent
          end

          false
        end
      end
    end
  end
end
