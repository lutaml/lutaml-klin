#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "lutaml/klin"

puts "\n#{'=' * 80}"
puts "  PropertyElementProcessor Test"
puts "=" * 80
puts ""

# Create mock UML class with attributes
MockAttribute = Struct.new(:name, :type, :cardinality, keyword_init: true) do
  def initialize(name:, type:, cardinality: nil)
    super(name: name, type: type, cardinality: cardinality || MockCardinality.new)
  end
end

MockCardinality = Struct.new(:min, :max, keyword_init: true) do
  def initialize(min: 1, max: "1")
    super
  end
end

MockClass = Struct.new(:name, :attributes, keyword_init: true) do
  def initialize(name:, attributes: [])
    super
  end
end

# Create test class with properties
test_class = MockClass.new(
  name: "Building",
  attributes: [
    MockAttribute.new(name: "buildingID", type: "CharacterString"),
    MockAttribute.new(name: "measuredHeight", type: "Length"),
    MockAttribute.new(
      name: "address",
      type: "Address",
      cardinality: MockCardinality.new(min: 0, max: "*")
    )
  ]
)

puts "Test UML Class:"
puts "  Name: #{test_class.name}"
puts "  Attributes count: #{test_class.attributes.size}"
puts ""

test_class.attributes.each do |attr|
  puts "  - #{attr.name}: #{attr.type} [#{attr.cardinality.min}..#{attr.cardinality.max}]"
end
puts ""

# Now test the PropertyElementProcessor
require_relative "../lib/lutaml/klin/shapechange/rule_processors/property_element_processor"
require_relative "../lib/lutaml/klin/shapechange/rule_checker"
require_relative "../lib/lutaml/klin/shapechange/rule_registry"

# Create minimal mock objects
class MockXsdDocument
  attr_reader :elements

  def initialize
    @elements = []
  end

  def create_element(name)
    element = { name: name, attributes: {}, children: [] }
    @elements << element
    element
  end

  def add_child(parent, child)
    parent[:children] << child
  end
end

class MockSequence
  attr_reader :children

  def initialize
    @children = []
  end

  def add_child(element)
    @children << element
  end
end

class MockConfig
  def find_type_mapping(type_name)
    # Simulate basic type mappings
    mappings = {
      "CharacterString" => OpenStruct.new(xml_type: "xs:string"),
      "Integer" => OpenStruct.new(xml_type: "xs:integer")
    }
    mappings[type_name]
  end
end

# Create test context
xsd_doc = MockXsdDocument.new
sequence = MockSequence.new
config = MockConfig.new

# Create rule registry with base encoding rules
rule_registry = Lutaml::Klin::Shapechange::RuleRegistry.new
Lutaml::Klin::Shapechange::BaseEncodingRules.load_into(rule_registry)
Lutaml::Klin::Shapechange.load_standard_rules(rule_registry)

# Create rule checker with iso19136_2007 encoding rule
rule_checker = Lutaml::Klin::Shapechange::RuleChecker.new(rule_registry,
                                                          "iso19136_2007")

puts "Rule registry configured"
puts "  Encoding rules: #{rule_registry.encoding_rules.keys.join(', ')}"
puts "  Rule 'rule-xsd-prop-encode-properties' registered: #{rule_registry.rule_definition('rule-xsd-prop-encode-properties') ? 'YES' : 'NO'}"
puts "  Rule applies to test class: #{if rule_checker.applies?(
  'rule-xsd-prop-encode-properties', test_class
)
                                        'YES'
                                      else
                                        'NO'
                                      end}"
puts ""

context = {
  xsd_document: xsd_doc,
  sequence_or_choice: sequence,
  prefix: "app",
  config: config
}

puts "Running PropertyElementProcessor..."
processor = Lutaml::Klin::Shapechange::RuleProcessors::PropertyElementProcessor.new(
  rule_checker,
  config
)

begin
  processor.process(test_class, context)

  puts "✓ Processor executed successfully"
  puts ""
  puts "Generated XSD elements in sequence:"
  puts "  Element count: #{sequence.children.size}"
  puts ""

  sequence.children.each do |element|
    puts "  <xs:element"
    element[:attributes].each do |key, value|
      puts "    #{key}=\"#{value}\""
    end
    puts "  />"
  end

  puts ""
  if sequence.children.empty?
    puts "❌ WARNING: No elements were generated!"
    puts "   This suggests attributes are not being processed correctly."
  else
    puts "✓ SUCCESS: Elements were generated as expected!"
  end
rescue StandardError => e
  puts "❌ ERROR: #{e.message}"
  puts e.backtrace.first(10).join("\n")
end

puts ""
puts "=" * 80
puts "  Test Complete"
puts "=" * 80
puts ""
