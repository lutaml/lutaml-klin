require 'lutaml'
require_relative 'lib/lutaml/klin/repositories/uml_repository_adapter'
require_relative 'lib/lutaml/klin/shapechange/reference_classes'

# Load UML from LUR
adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new('spec/fixtures/packages/plateau_all.lur')
classes = adapter.classes_in_package('uro', recursive: false)

# Filter to reference classes only
filtered_classes = classes.select do |c|
  Lutaml::Klin::Shapechange::ReferenceClasses.include?(c.name, 'uro')
end

puts "=== URO Package Analysis ==="
puts "Total classes in package: #{classes.size}"
puts "Filtered classes (in reference): #{filtered_classes.size}"
puts ""

# Count total attributes
total_attrs = 0
classes_with_attrs = 0
sample_output = []

filtered_classes.each do |uml_class|
  attrs = uml_class.attributes || []
  if attrs.any?
    total_attrs += attrs.size
    classes_with_attrs += 1
    
    # Sample first 3 classes
    if sample_output.size < 3
      sample_output << {
        name: uml_class.name,
        attr_count: attrs.size,
        samples: attrs.first(3).map { |a| "#{a.name}:#{a.type}" }
      }
    end
  end
end

puts "Classes with attributes: #{classes_with_attrs}/#{filtered_classes.size}"
puts "Total attributes across all classes: #{total_attrs}"
puts ""
puts "Sample classes:"
sample_output.each do |sample|
  puts "  #{sample[:name]} (#{sample[:attr_count]} attrs):"
  sample[:samples].each { |s| puts "    - #{s}" }
end
