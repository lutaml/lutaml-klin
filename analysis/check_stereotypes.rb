require "lutaml"

# Load LUR
repo = Lutaml::UmlRepository::Repository.from_package("../spec/fixtures/packages/plateau_all.lur")

# Classes to check
extra_classes = [
  "AccomodationType",
  "CityObjectGroup",
  "CommutingPopulationType", 
  "DaytimePopulationType",
  "DisasterDamage"
]

puts "=== Checking extra classes in URF package ==="
puts ""

extra_classes.each do |class_name|
  # Try to find in different packages
  ["urf", "uro"].each do |pkg|
    full_name = "#{pkg}::#{class_name}"
    klass = begin
              repo.find_class(full_name)
    rescue
              nil
    end
    
    next unless klass
    puts "#{class_name} (found in #{pkg}):"
    puts "  Stereotype: #{klass.stereotype || 'none'}"
    puts "  Package: #{klass.package&.name}"
    puts "  Abstract: #{klass.is_abstract?}"
      
    # Check tagged values
    if klass.respond_to?(:tagged_values) && klass.tagged_values.any?
      puts "  Tagged values:"
      klass.tagged_values.each do |tv|
        puts "    #{tv.tag}: #{tv.value}"
      end
    end
    puts ""
    break
  end
end
