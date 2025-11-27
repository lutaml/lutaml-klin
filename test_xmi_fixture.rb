#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/lutaml/klin"

# Test with real PLATEAU XMI file
xmi_path = "/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251022-uro.xmi"

puts "Testing XMI fixture parsing..."
puts "File: #{xmi_path}"
puts "Exists: #{File.exist?(xmi_path)}"
puts ""

begin
  require "lutaml"

  puts "Attempting to parse XMI with lutaml..."
  documents = Lutaml::Parser.parse([File.new(xmi_path)])

  puts "Success! Parsed #{documents.size} document(s)"

  documents.each_with_index do |doc, idx|
    puts "\nDocument #{idx + 1}:"
    puts "  Class: #{doc.class.name}"
    puts "  Packages: #{doc.packages.size}" if doc.respond_to?(:packages)

    next unless doc.respond_to?(:packages)

    doc.packages.each do |pkg|
      puts "\n  Package: #{pkg.name}"
      puts "    Classes: #{pkg.classes&.size || 0}"

      next unless pkg.classes

      pkg.classes.each do |cls|
        puts "\n    Class: #{cls.name}"
        puts "      Attributes: #{cls.attributes&.size || 0}"

        next unless cls.attributes

        cls.attributes.each do |attr|
          type_name = if attr.type.is_a?(String)
                        attr.type
                      elsif attr.type.respond_to?(:name)
                        attr.type.name
                      else
                        "unknown"
                      end
          puts "        - #{attr.name}: #{type_name}"
        end
      end
    end
  end
rescue StandardError => e
  puts "ERROR: #{e.class.name}: #{e.message}"
  puts "\nBacktrace:"
  puts e.backtrace.first(10).join("\n")
end
