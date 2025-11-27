#!/usr/bin/env ruby
# frozen_string_literal: true

require "nokogiri"
require "set"

# Paths
our_xsd = "examples/output/urbanObject.xsd"
ref_xsd = "spec/fixtures/shapechange/urbanObject.xsd"

# Parse both XSD files
our_doc = File.open(our_xsd) { |f| Nokogiri::XML(f) }
ref_doc = File.open(ref_xsd) { |f| Nokogiri::XML(f) }

ns = { "xs" => "http://www.w3.org/2001/XMLSchema" }

# Extract elements with substitutionGroup from both files
our_elements_with_subst = our_doc.xpath("//xs:schema/xs:element[@substitutionGroup]", ns).map do |el|
  {
    name: el["name"],
    type: el["type"],
    subst: el["substitutionGroup"]
  }
end

ref_elements_with_subst = ref_doc.xpath("//xs:schema/xs:element[@substitutionGroup]", ns).map do |el|
  {
    name: el["name"],
    type: el["type"],
    subst: el["substitutionGroup"]
  }
end

# Create sets of element names for comparison
our_names = Set.new(our_elements_with_subst.map { |e| e[:name] })
ref_names = Set.new(ref_elements_with_subst.map { |e| e[:name] })

# Find missing elements
missing_names = ref_names - our_names
extra_names = our_names - ref_names

puts "=" * 80
puts "SUBSTITUTION GROUP ANALYSIS"
puts "=" * 80
puts
puts "Our output: #{our_elements_with_subst.size} elements with substitutionGroup"
puts "Reference:  #{ref_elements_with_subst.size} elements with substitutionGroup"
puts "Missing:    #{missing_names.size} elements"
puts "Extra:      #{extra_names.size} elements"
puts

if missing_names.any?
  puts "=" * 80
  puts "MISSING ELEMENTS (in reference but not in ours)"
  puts "=" * 80

  ref_elements_with_subst.select { |e| missing_names.include?(e[:name]) }.each do |el|
    puts "  #{el[:name]}"
    puts "    type: #{el[:type]}"
    puts "    substitutionGroup: #{el[:subst]}"
    puts
  end
end

if extra_names.any?
  puts "=" * 80
  puts "EXTRA ELEMENTS (in ours but not in reference)"
  puts "=" * 80

  our_elements_with_subst.select { |e| extra_names.include?(e[:name]) }.each do |el|
    puts "  #{el[:name]}"
    puts "    type: #{el[:type]}"
    puts "    substitutionGroup: #{el[:subst]}"
    puts
  end
end

# Analyze patterns in missing elements
if missing_names.any?
  puts "=" * 80
  puts "PATTERN ANALYSIS OF MISSING ELEMENTS"
  puts "=" * 80

  missing_elements = ref_elements_with_subst.select { |e| missing_names.include?(e[:name]) }

  # Group by substitutionGroup
  by_subst = missing_elements.group_by { |e| e[:subst] }

  puts "\nBy substitutionGroup:"
  by_subst.each do |subst, elements|
    puts "  #{subst}: #{elements.size} elements"
    elements.each do |el|
      puts "    - #{el[:name]} (#{el[:type]})"
    end
  end

  # Check if these are ADE hooks
  puts "\nADE Hook Check:"
  ade_keywords = %w[bldg brid tun luse wtr frn tran veg grp dem core]
  ade_count = missing_elements.count { |e| ade_keywords.any? { |kw| e[:name].include?(kw) } }
  puts "  #{ade_count} / #{missing_elements.size} appear to be ADE hooks (based on naming)"
end