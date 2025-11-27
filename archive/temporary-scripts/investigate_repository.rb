#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin/repositories/uml_repository_adapter"

adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  "spec/fixtures/packages/plateau_all.lur"
)

puts "=" * 70
puts "Repository Investigation"
puts "=" * 70

# Test 1: Different package specifications
["urf", "uro", "ModelRoot::i-UR::urf", "ModelRoot::i-UR::uro"].each do |pkg|
  
    classes = adapter.classes_in_package(pkg, recursive: false)
    puts "\n#{pkg}:"
    puts "  Classes: #{classes.size}"
    puts "  Stereotypes: #{classes.map(&:stereotype).flatten.uniq.join(', ')}"
rescue => e
    puts "\n#{pkg}: ERROR - #{e.message}"
  
end

# Test 2: Check package structure
puts "\n" + "=" * 70
puts "Package Structure"
puts "=" * 70
all_packages = adapter.all_packages
puts "Total packages: #{all_packages.size}"
puts "\nPackages containing 'urf' or 'uro':"
all_packages.select { |p| p.to_s.include?("urf") || p.to_s.include?("uro") }.each do |p|
  puts "  - #{p}"
end

# Test 3: Sample class details
puts "\n" + "=" * 70
puts "Sample URF Classes (first 10)"
puts "=" * 70
urf_classes = adapter.classes_in_package("urf", recursive: false)
urf_classes.first(10).each do |c|
  puts "  #{c.name}:"
  puts "    XMI ID: #{begin
                        c.xmi_id
  rescue
                        'N/A'
  end}"
  puts "    Stereotype: #{Array(c.stereotype).join(', ')}"
  puts "    Package: #{begin
                         c.package&.name
  rescue
                         'nil'
  end}"

  # Check for qualified name or namespace
  if c.respond_to?(:full_name)
    puts "    Full name: #{begin
                             c.full_name
    rescue
                             'N/A'
    end}"
  end
  next unless c.respond_to?(:namespace)
  puts "    Namespace: #{begin
                           c.namespace
  rescue
                           'N/A'
  end}"
end

# Test 4: Look for problematic classes
puts "\n" + "=" * 70
puts "Checking Problematic Classes"
puts "=" * 70
["AccomodationType", "AreaClassicificationType", "CityObjectGroup"].each do |name|
  c = urf_classes.find { |cl| cl.name == name }
  if c
    puts "\n#{name} FOUND in URF:"
    puts "  Stereotype: #{Array(c.stereotype).join(', ')}"
    puts "  XMI ID: #{begin
                        c.xmi_id
    rescue
                        'N/A'
    end}"
    puts "  Package: #{begin
                         c.package&.name
    rescue
                         'nil'
    end}"

    # Check for qualified/full name
    if c.respond_to?(:full_name)
      puts "  Full name: #{begin
                             c.full_name
      rescue
                             'N/A'
      end}"
    end

    # Check tagged values
    if c.respond_to?(:tagged_values) && c.tagged_values
      tvs = c.tagged_values.map { |tv| 
              begin
                                         "#{tv.tag}=#{tv.value}"
              rescue
                                         tv.to_s
              end }
      puts "  Tagged values: #{tvs.join(', ')}" unless tvs.empty?
    else
      puts "  Tagged values: none/nil"
    end
  else
    puts "\n#{name} NOT in URF"
  end
end

# Test 5: Stereotype breakdown
puts "\n" + "=" * 70
puts "Stereotype Breakdown for URF"
puts "=" * 70
stereotype_counts = Hash.new(0)
urf_classes.each do |c|
  stereotypes = Array(c.stereotype)
  if stereotypes.empty?
    stereotype_counts["none"] += 1
  else
    stereotypes.each { |s| stereotype_counts[s] += 1 }
  end
end
stereotype_counts.sort_by { |_, count| -count }.each do |stereotype, count|
  puts "  #{stereotype}: #{count} classes"
end

# Test 6: Check if classes have package info in XMI ID or full name
puts "\n" + "=" * 70
puts "Analyzing Class Identifiers"
puts "=" * 70
sample_classes = urf_classes.first(5)
sample_classes.each do |c|
  puts "\n#{c.name}:"
  puts "  xmi_id: #{begin
                      c.xmi_id
  rescue
                      'N/A'
  end}"

  # Try various potential identifier methods
  [:full_name, :qualified_name, :namespace, :owner_package].each do |method|
    next unless c.respond_to?(method)
    value = begin
              c.send(method)
    rescue
              "ERROR"
    end
    puts "  #{method}: #{value}" unless value.nil?
  end
end

puts "\n" + "=" * 70
puts "Investigation Complete"
puts "=" * 70