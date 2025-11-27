#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "lutaml/klin"
require "lutaml/klin/repositories/uml_repository_adapter"

# Diagnostic script to trace property serialization issue
puts "\n#{'=' * 80}"
puts "  Property Serialization Diagnostic"
puts "=" * 80
puts ""

# Load UML repository directly using Lutaml::UmlRepository::Repository
lur_path = "packages/plateau_all.lur"
puts "Loading UML repository from: #{lur_path}"
repo = Lutaml::UmlRepository::Repository.from_package(lur_path)

# Test with a specific class that should have properties
test_class_path = "Conceptual Models::i-UR::Urban Planning ADE 3.2::uro"
puts "Looking for classes in: #{test_class_path}"

begin
  classes = repo.classes_in_package(test_class_path, recursive: false)
  puts "Found #{classes.size} classes"
  puts ""

  # Find Appurtenance which should have properties
  test_class = classes.find { |c| c.name == "Appurtenance" }
rescue StandardError => e
  puts "❌ Error loading classes: #{e.message}"
  puts "Attempting alternate package paths..."

  # Try alternate path patterns
  alt_paths = [
    "uro",
    "Urban Planning ADE 3.2::uro",
    "i-UR::Urban Planning ADE 3.2::uro"
  ]

  test_class = nil
  alt_paths.each do |alt_path|
    classes = repo.classes_in_package(alt_path, recursive: false)
    puts "✓ Found #{classes.size} classes in '#{alt_path}'"
    test_class = classes.find { |c| c.name == "Appurtenance" }
    break if test_class
  rescue StandardError => e2
    puts "  - '#{alt_path}' failed: #{e2.message}"
  end
end

if test_class.nil?
  puts "❌ Test class 'Appurtenance' not found!"
  puts "Available classes: #{classes.map(&:name).first(10).join(', ')}"
  exit(1)
end

puts "✓ Found test class: #{test_class.name}"
puts ""

# Inspect class structure
puts "Class Details:"
puts "  Name: #{test_class.name}"
puts "  Full Name: #{test_class.full_name || 'N/A'}"
puts "  Is Abstract: #{test_class.respond_to?(:is_abstract) ? test_class.is_abstract : 'N/A'}"
puts "  Stereotype: #{test_class.stereotype.inspect}"
puts ""

# Check for properties via different methods
puts "Property Access Methods:"
puts ""

# Method 1: .attributes
if test_class.respond_to?(:attributes)
  attrs = test_class.attributes || []
  puts "1. test_class.attributes:"
  puts "   Count: #{attrs.size}"
  if attrs.any?
    attrs.first(5).each do |attr|
      puts "   - #{attr.name}: #{attr.type}"
    end
  else
    puts "   ❌ EMPTY or NIL"
  end
else
  puts "1. test_class.attributes: ❌ METHOD NOT AVAILABLE"
end
puts ""

# Method 2: .properties
if test_class.respond_to?(:properties)
  props = test_class.properties || []
  puts "2. test_class.properties:"
  puts "   Count: #{props.size}"
  if props.any?
    props.first(5).each do |prop|
      puts "   - #{prop.name}: #{prop.type}"
    end
  else
    puts "   ❌ EMPTY or NIL"
  end
else
  puts "2. test_class.properties: ❌ METHOD NOT AVAILABLE"
end
puts ""

# Method 3: .owned_attributes
if test_class.respond_to?(:owned_attributes)
  owned = test_class.owned_attributes || []
  puts "3. test_class.owned_attributes:"
  puts "   Count: #{owned.size}"
  if owned.any?
    owned.first(5).each do |attr|
      puts "   - #{attr.name}: #{attr.type || 'N/A'}"
    end
  else
    puts "   ❌ EMPTY or NIL"
  end
else
  puts "3. test_class.owned_attributes: ❌ METHOD NOT AVAILABLE"
end
puts ""

# Method 4: Check available methods
puts "4. Available methods containing 'attr' or 'prop':"
methods = test_class.methods.grep(/attr|prop/)
if methods.any?
  methods.first(10).each { |m| puts "   - #{m}" }
else
  puts "   ❌ NONE FOUND"
end
puts ""

# Inspect class internals
puts "Class Instance Variables:"
test_class.instance_variables.each do |ivar|
  value = test_class.instance_variable_get(ivar)
  puts "  #{ivar}: #{value.class.name}"
  next unless value.respond_to?(:size) && value.size < 10

  puts "    Size: #{value.size}"
  if value.respond_to?(:first) && value.respond_to?(:any?) && value.any?
    puts "    First: #{value.first.inspect}"
  end
end
puts ""

# Check what Lutaml::Uml::Class provides
puts "Lutaml::Uml::Class Methods:"
uml_class = Lutaml::Uml::Class
puts "  Available property accessors:"
uml_class.instance_methods(false).grep(/attr|prop|owned/).each do |m|
  puts "    - #{m}"
end
puts ""

puts "=" * 80
puts "  Diagnostic Complete"
puts "=" * 80
puts ""

puts "DIAGNOSIS:"
puts ""
puts "The PropertyElementProcessor tries to access uml_class.attributes"
puts "at line 22 of property_element_processor.rb:"
puts ""
puts "  attributes = uml_class.attributes || []"
puts ""
if test_class.respond_to?(:attributes)
  attrs = test_class.attributes || []
  if attrs.empty?
    puts "❌ ISSUE CONFIRMED: .attributes method exists but returns EMPTY!"
    puts ""
    puts "Next steps:"
    puts "1. Check if properties are loaded from LUR"
    puts "2. Check lutaml-xmi API for property access"
    puts "3. Fix PropertyElementProcessor to use correct method"
  else
    puts "✓ .attributes method works and returns properties"
    puts "  Issue must be elsewhere in the pipeline"
  end
else
  puts "❌ ISSUE CONFIRMED: .attributes method DOES NOT EXIST!"
  puts ""
  puts "Next steps:"
  puts "1. Find correct method to access properties (likely .properties or .owned_attributes)"
  puts "2. Update PropertyElementProcessor to use correct method"
end
puts ""
