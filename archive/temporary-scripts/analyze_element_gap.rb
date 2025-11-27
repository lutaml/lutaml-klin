#!/usr/bin/env ruby

# Parse reference XSD to understand structure
require "nokogiri"

ref_doc = Nokogiri::XML(File.read("examples/i-ur/urbanFunction.xsd"))
our_doc = Nokogiri::XML(File.read("examples/output/urbanFunction.xsd"))

# Count different element types in reference
ref_elements = ref_doc.xpath("//xs:element").map { |el| el["name"] }.compact
ref_abstract = ref_elements.select { |name| name.start_with?("_") }
ref_property_elements = ref_elements.reject { |name| name.start_with?("_") || name.end_with?("Type") }

puts "=== Reference XSD Analysis ==="
puts "Total elements: #{ref_elements.size}"
puts "Abstract elements (start with _): #{ref_abstract.size}"
puts "  #{ref_abstract.first(5).join(', ')}..."
puts "Property/regular elements: #{ref_property_elements.size}"

# Count in our output
our_elements = our_doc.xpath("//xs:element").map { |el| el["name"] }.compact
our_abstract = our_elements.select { |name| name.start_with?("_") }
our_property_elements = our_elements.reject { |name| name.start_with?("_") || name.end_with?("Type") }

puts "\n=== Our Output Analysis ==="
puts "Total elements: #{our_elements.size}"
puts "Abstract elements (start with _): #{our_abstract.size}"
puts "Property/regular elements: #{our_property_elements.size}"

# Find missing abstract elements
missing_abstract = ref_abstract - our_abstract
puts "\n=== Missing Abstract Elements (#{missing_abstract.size}) ==="
missing_abstract.each { |name| puts "  - #{name}" }

# Analyze where property elements are defined
puts "\n=== Property Element Location Analysis ==="
ref_doc.xpath("//xs:complexType").first(3).each do |ct|
  name = ct["name"]
  next unless name
  local_elements = ct.xpath(".//xs:element[@name]").map { |el| el["name"] }
  puts "#{name}: #{local_elements.size} local elements (#{local_elements.first(3).join(',')}...)" if local_elements.any?
end
