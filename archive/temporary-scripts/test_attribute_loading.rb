#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin"

puts "=== UML Attribute Loading Test ==="
puts

# Load repository
lur_path = "packages/plateau_all.lur"
puts "Loading repository from: #{lur_path}"
lur = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(lur_path)
puts "✓ Repository loaded"
puts

# Get classes from urf package
puts "Fetching classes from 'urf' package..."
urf_classes = lur.classes_in_package("urf")
puts "✓ Found #{urf_classes.size} classes"
puts

# Test first few classes
puts "=== Testing First 5 Classes ==="
urf_classes.first(5).each do |uml_class|
  puts
  puts "Class: #{uml_class.name}"
  puts "  Type: #{uml_class.class.name}"

  # Check if attributes method exists
  if uml_class.respond_to?(:attributes)
    attrs = uml_class.attributes
    if attrs.nil?
      puts "  ❌ Attributes method returns nil!"
    elsif attrs.empty?
      puts "  ⚠️  Attributes is empty array"
    else
      puts "  ✓ Attributes: #{attrs.size}"
      attrs.first(3).each do |attr|
        puts "    - #{attr.name}: #{attr.type} (#{attr.class.name})"
      end
    end
  else
    puts "  ❌ No attributes method!"
  end

  # Check for owned_attributes (alternative name)
  if uml_class.respond_to?(:owned_attributes)
    owned = uml_class.owned_attributes
    puts "  ✓ owned_attributes: #{owned.size}" if owned && !owned.empty?
  end

  # Check for properties (another alternative)
  next unless uml_class.respond_to?(:properties)

  props = uml_class.properties
  puts "  ✓ properties: #{props.size}" if props && !props.empty?
end

puts
puts "=== Summary ==="
puts "Total classes in urf: #{urf_classes.size}"

# Count classes with attributes
with_attrs = urf_classes.count do |c|
  c.respond_to?(:attributes) && c.attributes && !c.attributes.empty?
end
puts "Classes with attributes: #{with_attrs}"
puts "Classes without attributes: #{urf_classes.size - with_attrs}"
