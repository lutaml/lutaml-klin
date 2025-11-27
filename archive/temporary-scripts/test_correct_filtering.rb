#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin/repositories/uml_repository_adapter"

adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  "spec/fixtures/packages/plateau_all.lur"
)

puts "=" * 70
puts "Testing Correct Package Filtering"
puts "=" * 70

# Test 1: Short name (current broken approach)
puts "\n1. Using short name 'urf' (BROKEN - relative match):"
classes_short = adapter.classes_in_package("urf", recursive: false)
puts "   Classes: #{classes_short.size}"

# Test 2: Full absolute path (correct approach)
full_path = "ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.1::urf"
puts "\n2. Using full path '#{full_path}':"
classes_full = adapter.classes_in_package(full_path, recursive: false)
puts "   Classes: #{classes_full.size}"

# Test 3: Check if CityObjectGroup is still there
puts "\n3. Checking for CityObjectGroup:"
cog_short = classes_short.find { |c| c.name == "CityObjectGroup" }
cog_full = classes_full.find { |c| c.name == "CityObjectGroup" }
puts "   In short path result: #{cog_short ? 'FOUND (WRONG!)' : 'not found'}"
puts "   In full path result: #{cog_full ? 'FOUND (WRONG!)' : 'not found (CORRECT)'}"

# Test 4: Check problematic DataTypes
puts "\n4. Checking problematic DataTypes:"
["AccomodationType", "AreaClassicificationType"].each do |name|
  in_short = classes_short.any? { |c| c.name == name }
  in_full = classes_full.any? { |c| c.name == name }
  puts "   #{name}:"
  puts "     Short path: #{in_short ? 'FOUND' : 'not found'}"
  puts "     Full path: #{in_full ? 'FOUND' : 'not found'}"
end

# Test 5: Sample classes from full path
puts "\n5. First 10 classes from FULL path:"
classes_full.first(10).each do |c|
  puts "   #{c.name} (#{c.stereotype})"
end

# Test 6: Check against reference
puts "\n" + "=" * 70
puts "Reference Comparison"
puts "=" * 70
puts "Full path classes: #{classes_full.size}"
puts "Reference types (from XSD): ~322"
puts "Estimated classes for 322 types: ~140-160"
puts ""
if classes_full.size.between?(140, 160)
  puts "✅ LOOKS CORRECT! Class count in expected range"
elsif classes_full.size < 140
  puts "❌ TOO FEW - Missing classes"
else
  puts "❌ TOO MANY - Still overcounting by #{classes_full.size - 160}"
end