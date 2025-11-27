#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin/repositories/uml_repository_adapter"

adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  "spec/fixtures/packages/plateau_all.lur"
)

full_path = "ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.1::urf"
our_classes = adapter.classes_in_package(full_path, recursive: false)

puts "=" * 70
puts "Comparing our 208 classes with reference XSD"
puts "=" * 70

# Read reference XSD to get list of types
reference_types = `grep 'name="[A-Z][^"]*Type"' examples/i-ur/urbanFunction.xsd | grep -o 'name="[^"]*"' | sed 's/name="//;s/"//' | sort -u`.split("\n")
reference_elements = `grep '<xs:element name="[A-Z]' examples/i-ur/urbanFunction.xsd | grep -o 'name="[^"]*"' | sed 's/name="//;s/"//' | sort -u`.split("\n")

puts "\nReference XSD:"
puts "  Types ending in 'Type': #{reference_types.size}"
puts "  Elements starting with uppercase: #{reference_elements.size}"

# Check each of our classes
in_reference = []
not_in_reference = []

our_classes.each do |c|
  class_name = c.name
  # For types, we expect ClassName -> ClassNameType
  # For elements, we expect ClassName -> ClassName element
  
  type_name = "#{class_name}Type"
  
  if reference_types.include?(type_name) || reference_elements.include?(class_name)
    in_reference << c
  else
    not_in_reference << c
  end
end

puts "\nOur 208 classes:"
puts "  In reference: #{in_reference.size}"
puts "  NOT in reference: #{not_in_reference.size}"

puts "\n" + "=" * 70
puts "Classes NOT in reference (first 30):"
puts "=" * 70
not_in_reference.first(30).each do |c|
  puts "  #{c.name} (#{c.stereotype})"
end

puts "\n" + "=" * 70
puts "Stereotype breakdown of classes NOT in reference:"
puts "=" * 70
stereotype_counts = Hash.new(0)
not_in_reference.each do |c|
  st = c.stereotype.to_s.empty? ? "none" : c.stereotype
  stereotype_counts[st] += 1
end
stereotype_counts.sort_by { |_, count| -count }.each do |st, count|
  puts "  #{st}: #{count}"
end

# Check CityObjectGroup specifically
puts "\n" + "=" * 70
puts "CityObjectGroup Analysis:"
puts "=" * 70
cog = our_classes.find { |c| c.name == "CityObjectGroup" }
if cog
  puts "Found in our classes:"
  puts "  Name: #{cog.name}"
  puts "  Stereotype: #{cog.stereotype}"
  puts "  XMI ID: #{cog.xmi_id}"
  
  # Check if it's in reference
  in_ref_types = reference_types.any? { |t| t.include?("CityObjectGroup") }
  in_ref_elements = reference_elements.any? { |e| e.include?("CityObjectGroup") }
  puts "  In reference types: #{in_ref_types}"
  puts "  In reference elements: #{in_ref_elements}"
end