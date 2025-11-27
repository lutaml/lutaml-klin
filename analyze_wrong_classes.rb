#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/lutaml/klin/repositories/uml_repository_adapter'

adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  'spec/fixtures/packages/plateau_all.lur'
)

full_path = 'ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.1::urf'
our_classes = adapter.classes_in_package(full_path, recursive: false)

# Get reference types
reference_types = `grep 'name="[A-Z][^"]*Type"' examples/i-ur/urbanFunction.xsd | grep -o 'name="[^"]*"' | sed 's/name="//;s/"//' | sort -u`.split("\n")
reference_elements = `grep '<xs:element name="[A-Z]' examples/i-ur/urbanFunction.xsd | grep -o 'name="[^"]*"' | sed 's/name="//;s/"//' | sort -u`.split("\n")

# Separate into correct and wrong
correct_classes = []
wrong_classes = []

our_classes.each do |c|
  type_name = "#{c.name}Type"
  if reference_types.include?(type_name) || reference_elements.include?(c.name)
    correct_classes << c
  else
    wrong_classes << c
  end
end

puts "="*70
puts "Analyzing the 51 WRONG classes"
puts "="*70

# Check visibility
puts "\n1. Visibility analysis:"
visibility_counts = Hash.new(0)
wrong_classes.each do |c|
  vis = c.respond_to?(:visibility) ? c.visibility : 'unknown'
  visibility_counts[vis] += 1
end
puts "Wrong classes:"
visibility_counts.sort_by { |_, count| -count }.each do |vis, count|
  puts "  #{vis}: #{count}"
end

correct_visibility_counts = Hash.new(0)
correct_classes.first(51).each do |c|
  vis = c.respond_to?(:visibility) ? c.visibility : 'unknown'
  correct_visibility_counts[vis] += 1
end
puts "Correct classes (sample of 51):"
correct_visibility_counts.sort_by { |_, count| -count }.each do |vis, count|
  puts "  #{vis}: #{count}"
end

# Check if ShapeChange config has publicOnly
puts "\n2. ShapeChange config publicOnly setting:"
config_public = `grep publicOnly examples/ShapeChangeConfig_Plateau_urf.xml`.strip
puts "  #{config_public}"

# Detail first 10 wrong classes
puts "\n" + "="*70
puts "First 10 WRONG classes - detailed info:"
puts "="*70
wrong_classes.first(10).each do |c|
  puts "\n#{c.name}:"
  puts "  Stereotype: #{c.stereotype}"
  puts "  Visibility: #{c.respond_to?(:visibility) ? c.visibility : 'N/A'}"
  puts "  XMI ID: #{c.xmi_id}"
  
  # Check for tagged values
  if c.respond_to?(:tagged_values) && c.tagged_values
    tvs = c.tagged_values.map { |tv| "#{tv.tag}=#{tv.value}" rescue tv.to_s }
    puts "  Tagged values: #{tvs.join(', ')}" unless tvs.empty?
  end
  
  # Check attributes
  if c.respond_to?(:attributes) && c.attributes
    puts "  Attributes: #{c.attributes.size}"
  end
end

# Detail first 5 correct classes for comparison
puts "\n" + "="*70
puts "First 5 CORRECT classes - for comparison:"
puts "="*70
correct_classes.first(5).each do |c|
  puts "\n#{c.name}:"
  puts "  Stereotype: #{c.stereotype}"
  puts "  Visibility: #{c.respond_to?(:visibility) ? c.visibility : 'N/A'}"
  puts "  XMI ID: #{c.xmi_id}"
  
  if c.respond_to?(:attributes) && c.attributes
    puts "  Attributes: #{c.attributes.size}"
  end
end