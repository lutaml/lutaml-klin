#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "lib/lutaml/klin/xmi_navigator"

xmi_path = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"

puts "Testing XmiNavigator with: #{xmi_path}"
navigator = Lutaml::Klin::XmiNavigator.new
navigator.parse_file(xmi_path)

puts "\n=== Packages Found ==="
puts "Total packages: #{navigator.packages.size}"
navigator.packages.values.first(5).each do |pkg|
  puts "  - #{pkg.name} (ID: #{pkg.id})"
end

puts "\n=== Classes Found ==="
puts "Total classes: #{navigator.classes.size}"
navigator.classes.values.first(10).each do |cls|
  puts "  - #{cls.name} (ID: #{cls.id}, Package: #{cls.package_id})"
  puts "    Attributes: #{cls.attributes.size}"
end

puts "\n=== Testing find_package ==="
first_pkg_name = navigator.packages.values.first&.name
if first_pkg_name
  found = navigator.find_package(first_pkg_name)
  puts "Found package '#{first_pkg_name}': #{found ? 'YES' : 'NO'}"
end

puts "\n=== Testing find_class ==="
first_class_name = navigator.classes.values.first&.name
if first_class_name
  found = navigator.find_class(first_class_name)
  puts "Found class '#{first_class_name}': #{found ? 'YES' : 'NO'}"
  if found
    puts "  - #{found.attributes.size} attributes"
    found.attributes.first(3).each do |attr|
      puts "    * #{attr.name}: #{attr.type}"
    end
  end
end

puts "\n✅ XmiNavigator test completed!"
