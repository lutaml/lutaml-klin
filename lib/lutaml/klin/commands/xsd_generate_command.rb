# frozen_string_literal: true

require_relative "../repositories/uml_repository_adapter"
require_relative "../shapechange/config_parser"
require_relative "../shapechange/xsd_generator"

module Lutaml
  module Klin
    module Commands
      # CLI command for XSD generation from UML
      class XsdGenerateCommand
        def initialize(options)
          @options = options
        end

        def run
          puts "\n#{'=' * 70}"
          puts "  LUTAML-KLIN: XSD Schema Generator"
          puts "=" * 70
          puts ""

          # Load LUR package
          puts "Loading UML repository..."
          lur_adapter = Repositories::UmlRepositoryAdapter.new(@options[:lur])

          # Load ShapeChange config
          puts "Loading ShapeChange configuration..."
          parser = Shapechange::ConfigParser.new
          config = parser.parse_file(@options[:config])

          # Create generator
          generator = Shapechange::XsdGenerator.new(
            lur_adapter.repository,
            config
          )

          # Parse packages
          packages = (@options[:packages] || "**").split(",").map(&:strip)

          puts "Generating XSD schemas for #{packages.size} package(s)..."
          puts ""

          # Generate XSD
          results = generator.generate_schemas(
            packages,
            @options[:output]
          )

          # Display results
          puts "=" * 70
          puts "  GENERATION COMPLETE"
          puts "=" * 70
          puts ""
          puts "Generated #{results.size} XSD file(s):"
          results.each do |r|
            puts "  ✓ #{r[:file]}"
            puts "    Namespace: #{r[:namespace]}"
            puts "    Classes: #{r[:classes_processed]}"
            puts ""
          end
        rescue StandardError => e
          puts "\n#{'=' * 70}"
          puts "  ❌  ERROR"
          puts "=" * 70
          puts ""
          puts "#{e.class}: #{e.message}"
          if @options[:verbose]
            puts ""
            puts "Backtrace:"
            e.backtrace.first(10).each { |line| puts "  #{line}" }
          end
          puts ""
          exit(1)
        end
      end
    end
  end
end
