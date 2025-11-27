#!/usr/bin/env ruby
# frozen_string_literal: true

require "nokogiri"
require "fileutils"

# Load both XSD files
generated_file = "final_schemas/urbanFunction.xsd"
reference_file = "examples/i-ur/urbanFunction.xsd"

puts "=" * 80
puts "XSD Comparison using Canon Gem"
puts "=" * 80
puts

unless File.exist?(generated_file)
  puts "❌ Generated file not found: #{generated_file}"
  exit 1
end

unless File.exist?(reference_file)
  puts "❌ Reference file not found: #{reference_file}"
  exit 1
end

generated = File.read(generated_file)
reference = File.read(reference_file)

# Parse XML documents
puts "Parsing XSD files..."
gen_doc = Nokogiri::XML(generated)
ref_doc = Nokogiri::XML(reference)

# Normalize and compare
gen_normalized = gen_doc.to_xml(indent: 2).gsub(/\s+/, " ").strip
ref_normalized = ref_doc.to_xml(indent: 2).gsub(/\s+/, " ").strip

if gen_normalized == ref_normalized
  puts "✅ XSD files are identical"
  exit 0
else
  puts "❌ XSD files differ"
  puts

  # Remove namespaces for easier comparison
  gen_doc.remove_namespaces!
  ref_doc.remove_namespaces!

  # Compare elements
  gen_elements = gen_doc.xpath("//element[@name]")
  ref_elements = ref_doc.xpath("//element[@name]")

  puts "📊 Element Statistics:"
  puts "  Generated: #{gen_elements.size}"
  puts "  Reference: #{ref_elements.size}"
  puts

  # Get element names
  gen_names = gen_elements.map { |e| e["name"] }.compact.sort.uniq
  ref_names = ref_elements.map { |e| e["name"] }.compact.sort.uniq

  missing = ref_names - gen_names
  extra = gen_names - ref_names

  if missing.any?
    puts "❌ Missing elements (#{missing.size}):"
    missing.each { |name| puts "  - #{name}" }
    puts
  end

  if extra.any?
    puts "⚠️  Extra elements (#{extra.size}):"
    extra.each { |name| puts "  - #{name}" }
    puts
  end

  # Compare types
  gen_types = gen_doc.xpath("//complexType[@name]")
  ref_types = ref_doc.xpath("//complexType[@name]")

  puts "📊 ComplexType Statistics:"
  puts "  Generated: #{gen_types.size}"
  puts "  Reference: #{ref_types.size}"
  puts

  gen_type_names = gen_types.map { |t| t["name"] }.compact.sort.uniq
  ref_type_names = ref_types.map { |t| t["name"] }.compact.sort.uniq

  missing_types = ref_type_names - gen_type_names
  extra_types = gen_type_names - ref_type_names

  if missing_types.any?
    puts "❌ Missing complexTypes (#{missing_types.size}):"
    missing_types.first(20).each { |name| puts "  - #{name}" }
    puts "  ... and #{missing_types.size - 20} more" if missing_types.size > 20
    puts
  end

  if extra_types.any?
    puts "⚠️  Extra complexTypes (#{extra_types.size}):"
    extra_types.first(20).each { |name| puts "  - #{name}" }
    puts "  ... and #{extra_types.size - 20} more" if extra_types.size > 20
    puts
  end

  # Compare namespaces
  gen_ns = Nokogiri::XML(generated).root.namespaces
  ref_ns = Nokogiri::XML(reference).root.namespaces

  puts "📊 Namespace Comparison:"
  puts "  Generated: #{gen_ns.keys.sort.join(', ')}"
  puts "  Reference: #{ref_ns.keys.sort.join(', ')}"
  puts

  missing_ns = ref_ns.keys - gen_ns.keys
  extra_ns = gen_ns.keys - ref_ns.keys

  if missing_ns.any?
    puts "❌ Missing namespaces:"
    missing_ns.each { |ns| puts "  - #{ns} => #{ref_ns[ns]}" }
    puts
  end

  if extra_ns.any?
    puts "⚠️  Extra namespaces:"
    extra_ns.each { |ns| puts "  - #{ns} => #{gen_ns[ns]}" }
    puts
  end

  # Check root element differences
  gen_root = Nokogiri::XML(generated).root
  ref_root = Nokogiri::XML(reference).root

  puts "📊 Root Element Comparison:"
  puts "  Generated namespace: #{begin
    gen_root.namespace.href
  rescue StandardError
    'none'
  end}"
  puts "  Reference namespace: #{begin
    ref_root.namespace.href
  rescue StandardError
    'none'
  end}"
  puts "  Generated targetNamespace: #{gen_root['targetNamespace']}"
  puts "  Reference targetNamespace: #{ref_root['targetNamespace']}"
  puts "  Generated elementFormDefault: #{gen_root['elementFormDefault']}"
  puts "  Reference elementFormDefault: #{ref_root['elementFormDefault']}"
  puts "  Generated version: #{gen_root['version']}"
  puts "  Reference version: #{ref_root['version']}"
  puts

  # Find structural differences with diff
  puts "📝 Detailed Diff (first 50 lines):"
  require "tempfile"

  Tempfile.create(["gen", ".xml"]) do |gen_file|
    Tempfile.create(["ref", ".xml"]) do |ref_file|
      gen_file.write(gen_doc.to_xml(indent: 2))
      gen_file.flush
      ref_file.write(ref_doc.to_xml(indent: 2))
      ref_file.flush

      system("diff -u #{ref_file.path} #{gen_file.path} | head -50")
    end
  end

  exit 1
end
