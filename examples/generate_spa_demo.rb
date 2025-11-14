#!/usr/bin/env ruby
# frozen_string_literal: true

# Example script showing SPA generation using lutaml-klin

require_relative "../lib/lutaml/klin/spa"

puts "=" * 80
puts "LutaML-Klin Enhanced HTML SPA Generator Demo"
puts "=" * 80

# Example 1: Generate multi-file SPA from LXR only
puts "\n1. Generating multi-file SPA from LXR package..."
if File.exist?("packages/plateau_schemas.lxr")
  begin
    Lutaml::Klin::Spa.generate(
      "packages/plateau_schemas.lxr",
      output: "examples/spa_output/multi_file",
      mode: :multi_file,
      theme: "default",
      verbose: true
    )
    puts "✓ Multi-file SPA generated at: examples/spa_output/multi_file"
  rescue => e
    puts "⚠ Error: #{e.message}"
  end
else
  puts "⚠ Skipped: LXR package not found at packages/plateau_schemas.lxr"
end

# Example 2: Generate embedded SPA with PLATEAU mapping
puts "\n2. Generating embedded SPA with UML mapping..."
if File.exist?("packages/plateau_schemas.lxr")
  begin
    yaml_path = if File.exist?("plateau_xsd_mapping/plateau_xsd_mapping.yaml")
                  "plateau_xsd_mapping/plateau_xsd_mapping.yaml"
                else
                  nil
                end

    Lutaml::Klin::Spa.generate(
      "packages/plateau_schemas.lxr",
      yaml_path: yaml_path,
      output: "examples/spa_output/plateau_embedded.html",
      mode: :embedded,
      theme: "plateau",
      verbose: true
    )
    puts "✓ Embedded SPA generated at: examples/spa_output/plateau_embedded.html"
  rescue => e
    puts "⚠ Error: #{e.message}"
  end
else
  puts "⚠ Skipped: Required files not found"
end

# Example 3: Using Ruby API to process schema data
puts "\n3. Using Ruby API to process schema data..."
if File.exist?("packages/plateau_schemas.lxr")
  begin
    schema = Lutaml::Klin::Spa.process(
      "packages/plateau_schemas.lxr",
      verbose: true
    )

    puts "\nSchema Information:"
    puts "  Name: #{schema.metadata.name}"
    puts "  Version: #{schema.metadata.version}"
    puts "  Schemas: #{schema.schemas.size}"
    puts "  Elements: #{schema.elements.size}"
    puts "  Complex Types: #{schema.complex_types.size}"
    puts "  Search Terms: #{schema.search_index.terms.size}"
  rescue => e
    puts "⚠ Error: #{e.message}"
  end
else
  puts "⚠ Skipped: LXR package not found"
end

# Example 4: Custom theme and title
puts "\n4. Generating SPA with custom theme and title..."
if File.exist?("packages/plateau_schemas.lxr")
  begin
    Lutaml::Klin::Spa.generate(
      "packages/plateau_schemas.lxr",
      output: "examples/spa_output/custom_theme",
      mode: :multi_file,
      theme: "dark",
      title: "Custom Schema Documentation",
      verbose: true
    )
    puts "✓ Custom themed SPA generated at: examples/spa_output/custom_theme"
  rescue => e
    puts "⚠ Error: #{e.message}"
  end
else
  puts "⚠ Skipped: LXR package not found"
end

puts "\n" + "=" * 80
puts "Demo complete!"
puts ""
puts "Generated SPAs can be viewed by:"
puts "  1. For multi-file mode: Serve with a web server"
puts "     cd examples/spa_output/multi_file"
puts "     python3 -m http.server 8000"
puts "     Then open http://localhost:8000"
puts ""
puts "  2. For embedded mode: Open directly in browser"
puts "     open examples/spa_output/plateau_embedded.html"
puts "=" * 80