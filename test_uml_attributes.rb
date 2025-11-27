#!/usr/bin/env ruby
# frozen_string_literal: true

# test_uml_attributes.rb

require_relative "lib/lutaml/klin"

# Load LUR
lur = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new("packages/plateau_all.lur")

# Get URF classes
urf_classes = lur.repository.classes_in_package("urf")

puts "Total URF classes: #{urf_classes.size}"
puts "\nChecking first 10 classes for attributes:\n"

urf_classes.first(10).each do |uml_class|
  attrs = uml_class.attributes || []
  puts "#{uml_class.name}: #{attrs.size} attributes"

  next unless attrs.any?

  attrs.first(3).each do |attr|
    puts "  - #{attr.name}: type=#{attr.type}"
    puts "    Methods: #{attr.methods.grep(/^[a-z]/).sort.join(', ')}"
  end
end
