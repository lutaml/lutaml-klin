#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "zip"
require "yaml"
require "lutaml/klin"

# Load lutaml gem to have Lutaml::Uml classes available for Marshal
require "lutaml/uml/document"
require "lutaml/uml/package"
require "lutaml/uml/class"
require "lutaml/uml/top_element_attribute"

puts "\n#{'=' * 80}"
puts "  LUR Package Attribute Inspection"
puts "=" * 80
puts ""

lur_path = "packages/plateau_all.lur"

begin
  Zip::File.open(lur_path) do |zip_file|
    # Load the document
    document_entry = zip_file.find_entry("models/document.marshal")
    unless document_entry
      puts "❌ document.marshal not found in LUR package"
      exit 1
    end

    puts "Loading document from LUR package..."
    document_data = document_entry.get_input_stream.read
    document = Marshal.load(document_data)

    puts "✓ Document loaded successfully"
    puts "  Document class: #{document.class.name}"
    puts ""

    # Navigate to a test package
    puts "Looking for uro package..."

    # Recursive package search
    def find_package_recursive(packages, name_pattern)
      packages.each do |pkg|
        return pkg if pkg.name =~ name_pattern

        if pkg.respond_to?(:packages) && pkg.packages
          found = find_package_recursive(pkg.packages, name_pattern)
          return found if found
        end
      end
      nil
    end

    # Try to find packages
    if document.respond_to?(:packages)
      all_packages = document.packages || []
      puts "  Root packages in document: #{all_packages.size}"

      # Find uro package recursively
      uro_package = find_package_recursive(all_packages, /uro/i)

      if uro_package
        puts "  ✓ Found package: #{uro_package.name}"
        if uro_package.respond_to?(:full_name)
          puts "    Full name: #{uro_package.full_name}"
        end

        # Check for classes
        if uro_package.respond_to?(:classes)
          classes = uro_package.classes || []
          puts "    Classes in package: #{classes.size}"

          if classes.any?
            test_class = classes.first
            puts ""
            puts "Inspecting first class: #{test_class.name}"
            puts "  Class type: #{test_class.class.name}"

            # Check for attributes
            if test_class.respond_to?(:attributes)
              attrs = test_class.attributes || []
              puts "  Attributes count: #{attrs.size}"

              if attrs.empty?
                puts "  ❌ CONFIRMED: attributes array is EMPTY in LUR data"
              else
                puts "  ✓ Attributes are present:"
                attrs.first(5).each do |attr|
                  puts "    - #{attr.name}: #{begin
                    attr.type
                  rescue StandardError
                    'N/A'
                  end}"
                end
              end
            else
              puts "  ❌ Class does not have .attributes method"
            end

            # Check instance variables
            puts ""
            puts "  Instance variables:"
            test_class.instance_variables.each do |ivar|
              value = test_class.instance_variable_get(ivar)
              if value.is_a?(Array)
                puts "    #{ivar}: Array[#{value.size}]"
                if ivar.to_s.include?("attr") && value.any?
                  puts "      First item: #{value.first.class.name}"
                end
              else
                puts "    #{ivar}: #{value.class.name}"
              end
            end
          else
            puts "  ❌ No classes found in package"
          end
        else
          puts "  ❌ Package does not have .classes method"
        end
      else
        puts "  ❌ Could not find uro package"
        puts ""
        puts "  Available packages (first 10):"
        all_packages.first(10).each do |pkg|
          puts "    - #{pkg.name}"
        end
      end
    else
      puts "❌ Document does not have .packages method"
      puts "   Document methods: #{document.methods.grep(/pack/).join(', ')}"
    end
  end
rescue StandardError => e
  puts "❌ ERROR: #{e.message}"
  puts e.backtrace.first(10).join("\n")
end

puts ""
puts "=" * 80
puts "  Inspection Complete"
puts "=" * 80
puts ""
