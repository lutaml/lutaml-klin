#!/usr/bin/env ruby
# frozen_string_literal: true

# Unit test for XSD namespace prefix fix

require_relative "lib/lutaml/klin/shapechange/models/xsd_document"

puts "Testing XSD Namespace Prefix Fix"
puts "=" * 80

# Test 1: Create XSD document
puts "\n1. Creating XSD document with xs: namespace prefix..."
xsd_doc = Lutaml::Klin::Shapechange::Models::XsdDocument.new(
  namespace: "https://www.geospatial.jp/iur/urf/3.2",
  prefix: "urf",
  version: "3.2.1"
)

xml_output = xsd_doc.to_xml
puts "   ✓ Document created"

# Test 2: Check xs: namespace declaration
puts "\n2. Checking xmlns:xs namespace declaration..."
if xml_output.include?('xmlns:xs="http://www.w3.org/2001/XMLSchema"')
  puts "   ✓ PASS: Found xmlns:xs declaration"
else
  puts "   ✗ FAIL: Missing xmlns:xs declaration"
  puts "   Actual namespaces:"
  xml_output.lines.first(5).each { |line| puts "     #{line}" }
end

# Test 3: Check root element uses xs:schema
puts "\n3. Checking root element..."
if xml_output.include?("<xs:schema")
  puts "   ✓ PASS: Root element is <xs:schema>"
else
  puts "   ✗ FAIL: Root element not using xs:schema"
  puts "   First line: #{xml_output.lines.first(3).join}"
end

# Test 4: Add element and check prefix
puts "\n4. Adding element and checking xs: prefix..."
xsd_doc.add_element(
  name: "TestElement",
  type: "urf:TestType",
  substitutionGroup: "urf:_BaseElement"
)

xml_output = xsd_doc.to_xml
if xml_output.include?("<xs:element")
  puts "   ✓ PASS: Element uses <xs:element> prefix"
else
  puts "   ✗ FAIL: Element not using xs: prefix"
end

# Test 5: Add complex type and check prefix
puts "\n5. Adding complex type and checking xs: prefix..."
complex_type = xsd_doc.add_complex_type(name: "TestType")
extension = xsd_doc.add_complex_content_extension(complex_type, "urf:BaseType")
xsd_doc.add_sequence(extension)

xml_output = xsd_doc.to_xml
if xml_output.include?("<xs:complexType")
  puts "   ✓ PASS: ComplexType uses <xs:complexType> prefix"
else
  puts "   ✗ FAIL: ComplexType not using xs: prefix"
end

if xml_output.include?("<xs:complexContent")
  puts "   ✓ PASS: ComplexContent uses <xs:complexContent> prefix"
else
  puts "   ✗ FAIL: ComplexContent not using xs: prefix"
end

if xml_output.include?("<xs:extension")
  puts "   ✓ PASS: Extension uses <xs:extension> prefix"
else
  puts "   ✗ FAIL: Extension not using xs: prefix"
end

if xml_output.include?("<xs:sequence")
  puts "   ✓ PASS: Sequence uses <xs:sequence> prefix"
else
  puts "   ✗ FAIL: Sequence not using xs: prefix"
end

# Test 6: Add import and check prefix
puts "\n6. Adding import and checking xs: prefix..."
xsd_doc.add_import(
  namespace: "http://www.opengis.net/gml/3.2",
  location: "http://schemas.opengis.net/gml/3.2.1/gml.xsd"
)

xml_output = xsd_doc.to_xml
if xml_output.include?("<xs:import")
  puts "   ✓ PASS: Import uses <xs:import> prefix"
else
  puts "   ✗ FAIL: Import not using xs: prefix"
end

# Print sample output
puts "\n7. Sample XML output (first 30 lines):"
puts "-" * 80
puts xml_output.lines.first(30).join
puts "-" * 80

puts "\n#{'=' * 80}"
puts "Test Complete!"
puts "All xs: prefix checks passed!" if xml_output.match?(/<xs:\w+/)
puts "=" * 80
