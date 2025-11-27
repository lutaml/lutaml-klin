#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin/repositories/uml_repository_adapter"

adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  "spec/fixtures/packages/plateau_all.lur"
)

full_path = "ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.1::urf"
our_classes = adapter.classes_in_package(full_path, recursive: false)

# Get reference types
reference_types = `grep 'name="[A-Z][^"]*Type"' examples/i-ur/urbanFunction.xsd | grep -o 'name="[^"]*"' | sed 's/name="//;s/"//' | sort -u`.split("\n")
reference_elements = `grep '<xs:element name="[A-Z]' examples/i-ur/urbanFunction.xsd | grep -o 'name="[^"]*"' | sed 's/name="//;s/"//' | sort -u`.split("\n")

# Separate classes
wrong_classes = our_classes.reject do |c|
  type_name = "#{c.name}Type"
  reference_types.include?(type_name) || reference_elements.include?(c.name)
end

correct_classes = our_classes.select do |c|
  type_name = "#{c.name}Type"
  reference_types.include?(type_name) || reference_elements.include?(c.name)
end

puts "=" * 70
puts "Checking class attributes for filtering clues"
puts "=" * 70

# Check all available attributes on classes
puts "\nAvailable methods on UML Class object:"
sample = our_classes.first
methods = sample.methods.sort - Object.methods
relevant = methods.select do |m|
  m.to_s =~ /(package|version|profile|status|tag|comment|definition|document)/i
end
puts relevant.take(20).join(", ")

# Check specific attributes
puts "\n" + "=" * 70
puts "Checking specific attributes on WRONG classes:"
puts "=" * 70

wrong_classes.first(5).each do |c|
  puts "\n#{c.name}:"
  
  # Try various potential attributes
  [:definition, :documentation, :comments].each do |attr|
    if c.respond_to?(attr)
      val = c.send(attr)
      puts "  #{attr}: #{val}" if val && !val.to_s.empty?
    end
  end
  
  # Check if class has owner package info
  if c.respond_to?(:owner_package)
    puts "  owner_package: #{c.owner_package}"
  end
end

puts "\n" + "=" * 70
puts "Checking specific attributes on CORRECT classes:"
puts "=" * 70

correct_classes.first(5).each do |c|
  puts "\n#{c.name}:"
  
  [:definition, :documentation, :comments].each do |attr|
    if c.respond_to?(attr)
      val = c.send(attr)
      puts "  #{attr}: #{val}" if val && !val.to_s.empty?
    end
  end
end

# Check if classes have relationships
puts "\n" + "=" * 70
puts "Inheritance check:"
puts "=" * 70

puts "\nWRONG classes with generalization:"
wrong_classes.select { |c| c.respond_to?(:generalization) && c.generalization }.take(5).each do |c|
  puts "  #{c.name}: has generalization"
end

puts "\nCORRECT classes with generalization:"
correct_classes.select { |c| c.respond_to?(:generalization) && c.generalization }.take(5).each do |c|
  puts "  #{c.name}: has generalization"
end

# Summary
puts "\n" + "=" * 70
puts "HYPOTHESIS:"
puts "=" * 70
puts "The 51 'wrong' classes exist in the UML package but ShapeChange"
puts "excludes them from XSD generation. Possible reasons:"
puts ""
puts "1. They may be deprecated or from older versions"
puts "2. They may be marked with a tag we can't see in the LUR"
puts "3. They may be in a nested sub-package we're not detecting"
puts "4. ShapeChange may use PackageInfo xsdDocument filter"
puts ""
puts "Next step: Check if PackageInfo filtering is the issue"