# frozen_string_literal: true

require "lutaml/model"
require_relative "encoding_rule"

module Lutaml
  module Klin
    module Shapechange
      # Wrapper model for StandardRules.xml root element
      # Represents the entire rules configuration document
      class StandardRules < Lutaml::Model::Serializable
        attribute :encoding_rules, EncodingRule, collection: true

        xml do
          root "rules", mixed: true
          namespace "http://www.interactive-instruments.de/ShapeChange/Configuration/1.1"

          map_element "EncodingRule", to: :encoding_rules
        end

        # Find encoding rule by name
        # @param name [String] Encoding rule name
        # @return [EncodingRule, nil] The encoding rule or nil if not found
        def find_encoding_rule(name)
          encoding_rules&.find { |er| er.name == name }
        end

        # Get all encoding rule names
        # @return [Array<String>] All encoding rule names
        def encoding_rule_names
          encoding_rules&.map(&:name) || []
        end
      end
    end
  end
end
