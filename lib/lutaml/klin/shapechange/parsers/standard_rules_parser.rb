# frozen_string_literal: true

require_relative "../models/config/standard_rules"

module Lutaml
  module Klin
    module Shapechange
      module Parsers
        # Parses ShapeChange StandardRules.xml using lutaml-model
        # Single Responsibility: Parse rules configuration from XML
        class StandardRulesParser
          # Parse StandardRules.xml from ShapeChange repository
          # @param filepath [String] Path to StandardRules.xml
          # @return [StandardRules] Parsed standard rules document
          def self.parse_file(filepath)
            StandardRules.from_xml(File.read(filepath))
          end

          # Parse StandardRules.xml and return encoding rules
          # @param filepath [String] Path to StandardRules.xml
          # @return [Array<EncodingRule>] Parsed encoding rules
          def self.parse_encoding_rules(filepath)
            standard_rules = parse_file(filepath)
            standard_rules.encoding_rules || []
          end
        end
      end
    end
  end
end