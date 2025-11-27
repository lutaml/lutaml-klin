require 'lutaml'

# Load LUR
repo = Lutaml::UmlRepository::Repository.from_package('../spec/fixtures/packages/plateau_all.lur')

# Classes to search for
search_classes = [
  'AccomodationType',
  'CityObjectGroup',
  'CommutingPopulationType'
]

puts "=== Searching for classes across all packages ==="
puts ""

search_classes.each do |class_name|
  puts "Searching for: #{class_name}"
  
  # Get all classes and filter
  found = false
  repo.list_packages('ModelRoot', recursive: true).each do |pkg|
    classes = repo.classes_in_package(pkg, recursive: false)
    classes.each do |klass|
      if klass.name == class_name
        puts "  Found in: #{pkg}"
        puts "  Full name: #{klass.qualified_name}"
        puts "  Stereotype: #{klass.stereotype || 'none'}"
        puts "  Abstract: #{klass.is_abstract?}"
        found = true
      end
    end
  end
  
  puts "  NOT FOUND" unless found
  puts ""
end
