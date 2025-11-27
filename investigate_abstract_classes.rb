#!/usr/bin/env ruby
require_relative 'lib/lutaml/klin/repositories/uml_repository_adapter'

repo_path = 'spec/fixtures/packages/plateau_all.lur'
adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(repo_path)
repo = adapter.repository

classes = repo.classes_in_package('urf')
puts "Total classes: #{classes.size}"

# Find UrbanFunction (base class)
urban_function = classes.find { |c| c.name == 'UrbanFunction' || c.name == '_UrbanFunction' }
if urban_function
  puts "\nFound class: #{urban_function.name}"
  puts "Stereotype: #{urban_function.stereotype}"
  puts "Is abstract: #{urban_function.is_abstract?}" if urban_function.respond_to?(:is_abstract?)
  puts "Methods available: #{urban_function.methods.grep(/abstract/).join(', ')}"
else
  puts "\nNo UrbanFunction class found"
  puts "Looking for similar names:"
  classes.select { |c| c.name.downcase.include?('urban') && c.name.downcase.include?('function') }.each do |c|
    puts "  - #{c.name}"
  end
end

# Find some subclasses
puts "\n=== Sample subclasses ==="
['Administration', 'Agreement', 'CensusBlock'].each do |name|
  klass = classes.find { |c| c.name == name }
  if klass
    puts "\n#{name}:"
    puts "  Stereotype: #{klass.stereotype}"
    if klass.respond_to?(:generalization) && !klass.generalization.empty?
      puts "  Parent: #{klass.generalization.first.general_name}"
    end
  end
end

# Check for DistrictPlan classes
district_plans = classes.select { |c| c.name.include?('DistrictPlan') }
puts "\n=== DistrictPlan classes (#{district_plans.size}) ==="
district_plans.first(5).each do |klass|
  puts "#{klass.name} (#{klass.stereotype})"
end
