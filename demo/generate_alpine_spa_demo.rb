#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script for Alpine.js SPA generation
# This demonstrates the new Alpine.js-based SPA template with real PLATEAU data

require "bundler/setup"
require "lutaml/klin"

puts "=" * 70
puts "🎯 LutaML Klin - Alpine.js SPA Demo Generator"
puts "=" * 70
puts ""

# Check if test data exists
lur_path = File.expand_path("../spec/fixtures/packages/plateau_all.lur", __dir__)
unless File.exist?(lur_path)
  puts "❌ Error: LUR package not found at #{lur_path}"
  puts "   Please ensure test fixtures are available"
  exit 1
end

config_path = File.expand_path("../examples/ShapeChangeConfig_Plateau_uro.xml", __dir__)
unless File.exist?(config_path)
  puts "❌ Error: Config not found at #{config_path}"
  exit 1
end

# Display configuration
puts "📦 Input Configuration:"
puts "   • LUR Package: #{lur_path}"
puts "   • ShapeChange Config: #{config_path}"
puts "   • Package Filter: **::uro"
puts "   • Template Type: Alpine.js (default)"
puts "   • Data Mode: Embedded (works with file://)"
puts ""

# Create output directory
output_dir = File.expand_path("output/alpine_spa", __dir__)
FileUtils.mkdir_p(output_dir)

puts "📁 Output Directory: #{output_dir}"
puts ""
puts "⚙️  Starting processing workflow..."
puts ""

# Create workflow with progress callback
workflow = Lutaml::Klin::Application::ProcessingWorkflow.new(
  progress_callback: lambda { |stage, msg|
    puts "   [#{stage.to_s.upcase.ljust(12)}] #{msg}"
  }
)

# Execute the workflow
begin
  result = workflow.execute(
    lur_path: lur_path,
    lxr_path: nil, # Will be auto-created from config
    config_path: config_path,
    package_filter: "**::uro",
    output_dir: output_dir,
    generate_mappings: true,
    generate_spa: true,
    spa_template_type: :alpine, # Use Alpine.js template
    spa_data_mode: :embedded, # Embedded for file:// access
    validate: true,
    verbose: false
  )

  puts ""
  puts "=" * 70
  puts "✅ Demo Generation Complete!"
  puts "=" * 70
  puts ""

  # Display statistics
  puts "📊 Processing Statistics:"
  puts "   • Total Packages: #{result.total_packages}"
  puts "   • Total Classes: #{result.total_classes}"
  puts "   • Resolved Classes: #{result.resolved_classes}"
  puts "   • Resolution Rate: #{result.resolution_rate.round(1)}%"
  puts ""

  # Display output locations
  spa_path = File.join(output_dir, "spa", "index.html")
  mappings_path = File.join(output_dir, "mappings")
  
  puts "📁 Generated Files:"
  puts "   • SPA Website: #{File.join(output_dir, 'spa')}"
  puts "   • Mappings: #{mappings_path}"
  if result.validation_report_path
    puts "   • Validation Report: #{result.validation_report_path}"
  end
  puts ""

  # Display browser instructions
  puts "🌐 Open in Browser:"
  puts "   #{URI.join('file:///', spa_path.sub(%r{^/}, ''))}"
  puts ""
  puts "   Or use:"
  puts "   open #{spa_path}"
  puts ""

  # Display feature highlights
  puts "💡 Features to Try:"
  puts "   • Search for classes (e.g., 'Building', 'UrbanPlanningArea')"
  puts "   • Navigate through package tree"
  puts "   • Click on classes to view details"
  puts "   • Use filter checkboxes to filter by resolution status"
  puts "   • Copy URL to share specific views (hash-based routing)"
  puts "   • Resize browser to see responsive design"
  puts ""

  # Display comparison option
  puts "🔄 Compare with Vanilla JS:"
  puts "   To generate the vanilla JavaScript version:"
  puts "   ruby demo/generate_alpine_spa_demo.rb --vanilla"
  puts ""
rescue StandardError => e
  puts ""
  puts "=" * 70
  puts "❌ Error During Processing"
  puts "=" * 70
  puts ""
  puts "Error: #{e.message}"
  puts ""
  puts "Backtrace:"
  puts e.backtrace.first(10).join("\n")
  puts ""
  exit 1
end