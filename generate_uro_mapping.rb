#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "lib/lutaml/klin/xmi_navigator"
require_relative "lib/lutaml/klin/models/uml/package"
require_relative "lib/lutaml/klin/models/uml/class"
require_relative "lib/lutaml/klin/models/uml/attribute"
require "yaml"

# Parse XMI
puts "Parsing XMI file..."
xmi_path = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"
navigator = Lutaml::Klin::XmiNavigator.new
navigator.parse_file(xmi_path)

# Find URO package
uro_package = navigator.find_package("uro")

if uro_package
  puts "\n✓ Found package: #{uro_package.name}"

  # Get actual class objects using navigator method
  classes_in_uro = navigator.classes_in_package("uro")
  puts "  Classes: #{classes_in_uro.size}"

  # Prepare mapping data
  mapping_data = {
    package_name: uro_package.name,
    total_classes: classes_in_uro.size,
    classes: []
  }

  # Process all classes
  classes_in_uro.each do |cls|
    class_data = {
      name: cls.name,
      stereotype: cls.stereotype,
      id: cls.id,
      attributes: (cls.attributes || []).map do |attr|
        # Handle case where attr might be a string or an object
        if attr.respond_to?(:name)
          {
            name: attr.name,
            type: attr.type,
            multiplicity: "#{attr.multiplicity_min}..#{attr.multiplicity_max}"
          }
        else
          { name: attr.to_s, type: "unknown", multiplicity: "0..1" }
        end
      end,
      associations: (cls.associations || []).map do |assoc|
        if assoc.respond_to?(:name)
          {
            name: assoc.name,
            target_class: assoc.target_class,
            multiplicity: assoc.multiplicity
          }
        else
          { name: assoc.to_s, target_class: "unknown", multiplicity: "0..1" }
        end
      end
    }
    mapping_data[:classes] << class_data
  end

  # Group by stereotype
  by_stereotype = classes_in_uro.group_by(&:stereotype)
  mapping_data[:stereotypes] = {}
  by_stereotype.each do |stereotype, classes|
    mapping_data[:stereotypes][stereotype] = classes.size
  end

  # Save to YAML
  output_file = "uro_mapping_data.yaml"
  File.write(output_file, mapping_data.to_yaml)
  puts "\n✓ Mapping data saved to: #{output_file}"

  # Print summary
  puts "\n#{'=' * 80}"
  puts "SUMMARY"
  puts "=" * 80
  puts "Package: #{mapping_data[:package_name]}"
  puts "Total classes: #{mapping_data[:total_classes]}"
  puts "\nClasses by stereotype:"
  mapping_data[:stereotypes].sort_by do |_, count|
    -count
  end.each do |stereotype, count|
    puts "  #{stereotype}: #{count} classes"
  end

else
  puts "❌ URO package not found"
  puts "\nAvailable packages:"
  navigator.packages.each do |pkg|
    puts "  - #{pkg.name} (#{pkg.classes.size} classes)"
  end
  exit 1
end
