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

# Separate classes
wrong_classes = our_classes.select do |c|
  type_name = "#{c.name}Type"
  !(reference_types.include?(type_name) || reference_elements.include?(c.name))
end

correct_classes = our_classes.select do |c|
  type_name = "#{c.name}Type"
  reference_types.include?(type_name) || reference_elements.include?(c.name)
end

puts "="*70
puts "Analyzing package_path attribute"
puts "="*70

puts "\nWRONG classes - package_path:"
wrong_classes.first(10).each do |c|
  pp = c.respond_to?(:package_path) ? c.package_path : 'N/A'
  puts "  #{c.name}: #{pp}"
end

puts "\nCORRECT classes - package_path:"
correct_classes.first(10).each do |c|
  pp = c.respond_to?(:package_path) ? c.package_path : 'N/A'
  puts "  #{c.name}: #{pp}"
end

# Group by package_path
puts "\n" + "="*70
puts "Package path distribution:"
puts "="*70

wrong_paths = wrong_classes.map { |c| c.package_path }.compact.uniq
correct_paths = correct_classes.map { |c| c.package_path }.compact.uniq

puts "\nUnique package_paths in WRONG classes:"
wrong_paths.each { |p| puts "  #{p}" }

puts "\nUnique package_paths in CORRECT classes:"
correct_paths.each { |p| puts "  #{p}" }

# Count by package_path
puts "\n" + "="*70
puts "Count by package_path:"
puts "="*70

all_package_paths = our_classes.map { |c| c.package_path }.compact
path_counts = Hash.new(0)
all_package_paths.each { |p| path_counts[p] += 1 }

path_counts.sort_by { |_, count| -count }.each do |path, count|
  # Check how many are wrong vs correct
  wrong_count = wrong_classes.count { |c| c.package_path == path }
  correct_count = correct_classes.count { |c| c.package_path == path }
  puts "\n#{path}:"
  puts "  Total: #{count}"
  puts "  Wrong: #{wrong_count}"
  puts "  Correct: #{correct_count}"
end