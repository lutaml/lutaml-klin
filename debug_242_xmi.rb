#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "lib/lutaml/klin"

puts "Debugging 242.xmi structure..."
puts "=" * 80

XMI_FILE = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251010-242.xmi"

navigator = Lutaml::Klin::XmiNavigator.new
navigator.parse_file(XMI_FILE)

# Get all packages
packages = navigator.packages
puts "Total packages: #{packages.size}"
puts

# List first 20 packages with details
puts "First 20 packages:"
puts "-" * 80
packages.first(20).each_with_index do |(pkg_name, pkg_id), idx|
  puts "[#{idx + 1}] #{pkg_name}"
  puts "    ID: #{pkg_id}"

  # Try to get classes
  classes = navigator.classes_in_package(pkg_name)
  puts "    Classes found: #{classes.size}"

  if classes.size.positive?
    puts "    First 3 classes:"
    classes.first(3).each do |cls|
      puts "      - #{cls.name} (#{cls.stereotype || 'no stereotype'})"
    end
  end
  puts
end

# Check if there are any packages with classes
packages_with_classes = packages.select do |pkg_name, _|
  navigator.classes_in_package(pkg_name).size.positive?
end

puts "=" * 80
puts "Summary:"
puts "  Total packages: #{packages.size}"
puts "  Packages with classes: #{packages_with_classes.size}"
puts

if packages_with_classes.size.positive?
  puts "Packages with classes:"
  packages_with_classes.each_key do |pkg_name|
    class_count = navigator.classes_in_package(pkg_name).size
    puts "  - #{pkg_name}: #{class_count} classes"
  end
else
  puts "⚠️  No packages with classes found!"
  puts
  puts "This suggests the XMI structure may be different."
  puts "Checking document structure directly..."
  puts

  # Access document directly
  doc = navigator.instance_variable_get(:@document)
  if doc
    puts "Document root: #{doc.root.name}"
    puts "Namespaces: #{doc.root.namespaces.inspect}"

    # Find all packagedElement
    packaged_elements = doc.xpath("//packagedElement")
    puts "Total packagedElement nodes: #{packaged_elements.size}"

    # Find all class elements
    class_elements = doc.xpath("//packagedElement[@xmi:type='uml:Class']",
                               "xmi" => "http://www.omg.org/spec/XMI/20131001")
    puts "Total Class nodes: #{class_elements.size}"

    if class_elements.size.positive?
      puts
      puts "First 5 classes found directly:"
      class_elements.first(5).each do |cls|
        name = cls["name"]
        owner_id = cls["owner"]
        puts "  - #{name} (owner: #{owner_id})"
      end
    end
  end
end
