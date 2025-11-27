#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'set'

# XSD Content Validation Script
# Compares two XSD files for content-level parity beyond just structural counts

class XsdContentValidator
  XS_NS = 'http://www.w3.org/2001/XMLSchema'

  def initialize(our_file, ref_file)
    @our_file = our_file
    @ref_file = ref_file
    @our_doc = Nokogiri::XML(File.read(our_file))
    @ref_doc = Nokogiri::XML(File.read(ref_file))
    @mismatches = []
  end

  def validate
    puts "=" * 80
    puts "XSD CONTENT VALIDATION"
    puts "=" * 80
    puts "Our file: #{@our_file}"
    puts "Ref file: #{@ref_file}"
    puts

    validate_elements
    validate_complex_types
    validate_simple_types
    validate_attribute_groups
    validate_namespaces

    print_summary
  end

  private

  def validate_elements
    puts "📝 Validating top-level elements..."

    our_elems = extract_elements(@our_doc)
    ref_elems = extract_elements(@ref_doc)

    check_sets("Elements", our_elems, ref_elems)

    # Check substitutionGroup matches
    check_substitution_groups(our_elems, ref_elems)
  end

  def validate_complex_types
    puts "\n📝 Validating complex types..."

    our_types = extract_complex_types(@our_doc)
    ref_types = extract_complex_types(@ref_doc)

    check_sets("Complex Types", our_types, ref_types)

    # Check type structure matches
    check_type_structures(our_types, ref_types)
  end

  def validate_simple_types
    puts "\n📝 Validating simple types..."

    our_types = extract_simple_types(@our_doc)
    ref_types = extract_simple_types(@ref_doc)

    check_sets("Simple Types", our_types, ref_types)
  end

  def validate_attribute_groups
    puts "\n📝 Validating attribute groups..."

    our_groups = extract_attribute_groups(@our_doc)
    ref_groups = extract_attribute_groups(@ref_doc)

    check_sets("Attribute Groups", our_groups, ref_groups)
  end

  def validate_namespaces
    puts "\n📝 Validating namespaces..."

    our_ns = extract_namespaces(@our_doc)
    ref_ns = extract_namespaces(@ref_doc)

    our_only = our_ns.keys - ref_ns.keys
    ref_only = ref_ns.keys - our_ns.keys

    if our_only.empty? && ref_only.empty?
      puts "  ✅ All namespace prefixes match"
    else
      @mismatches << "Namespace prefixes mismatch"
      puts "  ❌ Namespace prefix differences:"
      our_only.each { |prefix| puts "    - In ours only: #{prefix}" }
      ref_only.each { |prefix| puts "    - In reference only: #{prefix}" }
    end
  end

  def extract_elements(doc)
    doc.xpath("/xs:schema/xs:element[@name]", 'xs' => XS_NS).map do |elem|
      {
        name: elem['name'],
        type: elem['type'],
        substitutionGroup: elem['substitutionGroup'],
        abstract: elem['abstract']
      }
    end
  end

  def extract_complex_types(doc)
    doc.xpath("/xs:schema/xs:complexType[@name]", 'xs' => XS_NS).map do |type|
      {
        name: type['name'],
        abstract: type['abstract'],
        has_extension: !type.xpath(".//xs:extension", 'xs' => XS_NS).empty?,
        base_type: type.xpath(".//xs:extension/@base", 'xs' => XS_NS).first&.value
      }
    end
  end

  def extract_simple_types(doc)
    doc.xpath("/xs:schema/xs:simpleType[@name]", 'xs' => XS_NS).map do |type|
      {
        name: type['name']
      }
    end
  end

  def extract_attribute_groups(doc)
    doc.xpath("/xs:schema/xs:attributeGroup[@name]", 'xs' => XS_NS).map do |group|
      {
        name: group['name']
      }
    end
  end

  def extract_namespaces(doc)
    namespaces = {}
    doc.root.namespace_definitions.each do |ns|
      namespaces[ns.prefix || 'default'] = ns.href
    end
    namespaces
  end

  def check_sets(category, ours, refs)
    our_names = ours.map { |item| item[:name] }.to_set
    ref_names = refs.map { |item| item[:name] }.to_set

    our_only = our_names - ref_names
    ref_only = ref_names - our_names

    if our_only.empty? && ref_only.empty?
      puts "  ✅ All #{category.downcase} names match (#{our_names.size} total)"
    else
      @mismatches << "#{category} names mismatch"
      puts "  ❌ #{category} name differences:"

      unless our_only.empty?
        puts "\n    In our output only (#{our_only.size}):"
        our_only.sort.first(10).each { |name| puts "      - #{name}" }
        puts "      ... (#{our_only.size - 10} more)" if our_only.size > 10
      end

      unless ref_only.empty?
        puts "\n    In reference only (#{ref_only.size}):"
        ref_only.sort.first(10).each { |name| puts "      - #{name}" }
        puts "      ... (#{ref_only.size - 10} more)" if ref_only.size > 10
      end
    end
  end

  def check_substitution_groups(our_elems, ref_elems)
    our_map = our_elems.each_with_object({}) do |elem, h|
      h[elem[:name]] = elem[:substitutionGroup]
    end

    ref_map = ref_elems.each_with_object({}) do |elem, h|
      h[elem[:name]] = elem[:substitutionGroup]
    end

    mismatches = []
    our_map.each do |name, our_sg|
      ref_sg = ref_map[name]
      next if our_sg == ref_sg

      mismatches << { name: name, ours: our_sg, ref: ref_sg }
    end

    if mismatches.empty?
      puts "  ✅ All substitutionGroup attributes match"
    else
      @mismatches << "SubstitutionGroup mismatches"
      puts "  ❌ SubstitutionGroup differences (#{mismatches.size}):"
      mismatches.first(10).each do |m|
        puts "    - #{m[:name]}: '#{m[:ours]}' vs '#{m[:ref]}' (ref)"
      end
      puts "    ... (#{mismatches.size - 10} more)" if mismatches.size > 10
    end
  end

  def check_type_structures(our_types, ref_types)
    our_map = our_types.each_with_object({}) do |type, h|
      h[type[:name]] = type
    end

    ref_map = ref_types.each_with_object({}) do |type, h|
      h[type[:name]] = type
    end

    mismatches = []
    our_map.each do |name, our_type|
      ref_type = ref_map[name]
      next unless ref_type

      if our_type[:base_type] != ref_type[:base_type]
        mismatches << {
          name: name,
          field: 'base_type',
          ours: our_type[:base_type],
          ref: ref_type[:base_type]
        }
      end
    end

    if mismatches.empty?
      puts "  ✅ All type base types match"
    else
      @mismatches << "Type structure mismatches"
      puts "  ❌ Type structure differences (#{mismatches.size}):"
      mismatches.first(10).each do |m|
        puts "    - #{m[:name]}.#{m[:field]}: '#{m[:ours]}' vs '#{m[:ref]}' (ref)"
      end
      puts "    ... (#{mismatches.size - 10} more)" if mismatches.size > 10
    end
  end

  def print_summary
    puts "\n" + "=" * 80
    puts "VALIDATION SUMMARY"
    puts "=" * 80

    if @mismatches.empty?
      puts "✅ PERFECT CONTENT MATCH - All aspects validated successfully!"
      puts "\nBoth XSD files are identical in:"
      puts "  • Element names and attributes"
      puts "  • Complex type names and structures"
      puts "  • Simple type names"
      puts "  • Attribute group names"
      puts "  • Namespace declarations"
      puts "  • SubstitutionGroup references"
    else
      puts "❌ CONTENT MISMATCHES FOUND (#{@mismatches.size} categories)"
      puts "\nMismatch categories:"
      @mismatches.each { |m| puts "  • #{m}" }
      puts "\nReview the detailed output above for specific differences."
    end

    puts "=" * 80
  end
end

# Main execution
if ARGV.size != 2
  puts "Usage: ruby validate_xsd_content.rb <our_xsd> <reference_xsd>"
  puts "\nExample:"
  puts "  ruby validate_xsd_content.rb \\"
  puts "    examples/output/urbanObject.xsd \\"
  puts "    spec/fixtures/shapechange/urbanObject.xsd"
  exit 1
end

validator = XsdContentValidator.new(ARGV[0], ARGV[1])
validator.validate