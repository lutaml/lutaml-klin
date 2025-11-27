#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin/repositories/uml_repository_adapter"

adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  "spec/fixtures/packages/plateau_all.lur"
)

puts "=" * 70
puts "Analyzing Qualified Names"
puts "=" * 70

# Get internal access to repository
repo = adapter.instance_variable_get(:@repository)
qualified_names = repo.indexes[:qualified_names]

puts "\nTotal classes in index: #{qualified_names.size}"

# Sample qualified names containing 'urf' or 'uro'
puts "\n" + "=" * 70
puts "Sample qualified names containing 'urf':"
puts "=" * 70

urf_qnames = qualified_names.keys.select { |qn| qn.include?("urf") }
puts "Found #{urf_qnames.size} qualified names with 'urf'"
puts "\nFirst 20:"
urf_qnames.first(20).each do |qn|
  puts "  #{qn}"
end

puts "\n" + "=" * 70
puts "Sample qualified names containing 'uro':"
puts "=" * 70

uro_qnames = qualified_names.keys.select { |qn| qn.include?("uro") }
puts "Found #{uro_qnames.size} qualified names with 'uro'"
puts "\nFirst 20:"
uro_qnames.first(20).each do |qn|
  puts "  #{qn}"
end

# Check specific problematic classes
puts "\n" + "=" * 70
puts "Qualified names for problematic classes:"
puts "=" * 70

["AccomodationType", "AreaClassicificationType", "CityObjectGroup"].each do |name|
  matches = qualified_names.keys.select { |qn| qn.include?(name) }
  if matches.any?
    puts "\n#{name}:"
    matches.each { |qn| puts "  #{qn}" }
  else
    puts "\n#{name}: NOT FOUND in qualified names index"
  end
end

# Check package structure
puts "\n" + "=" * 70
puts "Package Paths in Index:"
puts "=" * 70

package_paths = repo.indexes[:package_paths]
puts "Total package paths: #{package_paths.size}"
puts "\nPackage paths containing 'urf' or 'uro':"
package_paths.keys.select { |p| p.include?("urf") || p.include?("uro") }.sort.each do |p|
  puts "  #{p}"
end