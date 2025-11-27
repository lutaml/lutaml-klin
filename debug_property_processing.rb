#!/usr/bin/env ruby
# frozen_string_literal: true

# debug_property_processing.rb

require_relative "lib/lutaml/klin"

# Temporarily patch PropertyElementProcessor to add debug output
module Lutaml
  module Klin
    module Shapechange
      module RuleProcessors
        class PropertyElementProcessor
          alias original_apply_rule apply_rule

          def apply_rule(uml_class, context)
            puts "\n=== PropertyElementProcessor.apply_rule ==="
            puts "Class: #{uml_class.name}"

            sequence = context[:sequence_or_choice]
            puts "Sequence present: #{!sequence.nil?}"

            attributes = uml_class.attributes || []
            puts "Attributes count: #{attributes.size}"

            if attributes.any?
              puts "First 3 attributes:"
              attributes.first(3).each do |attr|
                puts "  - #{attr.name}: #{attr.type}"
              end
            end

            # Call original method
            result = original_apply_rule(uml_class, context)

            if sequence
              puts "Sequence children after processing: #{sequence.children.size}"
            end

            result
          end
        end
      end
    end
  end
end

# Generate simple schema
lur_path = "packages/plateau_all.lur"
config_path = "examples/ShapeChangeConfig_Plateau_urf_for_plateau.xml"
output_dir = "debug_output"

puts "Loading UML repository..."
uml_repo = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)

puts "Loading configuration..."
parser = Lutaml::Klin::Shapechange::ConfigParser.new
config = parser.parse_file(config_path)

puts "\nGenerating XSD for 'urf' package..."
generator = Lutaml::Klin::Shapechange::XsdGenerator.new(uml_repo, config)
result = generator.generate_schemas(["urf"], output_dir)

puts "\n=== Generation Complete ==="
puts "Result: #{result.inspect}"
