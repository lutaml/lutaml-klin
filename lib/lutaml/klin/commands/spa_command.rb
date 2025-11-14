# frozen_string_literal: true

require_relative "../spa/generator"

module Lutaml
  module Klin
    module Commands
      # CLI command for SPA (Single Page Application) generation
      # Provides user-friendly interface to Generator class
      class SpaCommand
        attr_reader :options

        # @param options [Hash] Command options
        # @option options [String] :lxr Path to LXR package file
        # @option options [String] :yaml Path to YAML mapping file (optional)
        # @option options [String] :output Output path (file or directory)
        # @option options [Symbol, String] :mode Output mode (:embedded or :multi_file)
        # @option options [String] :theme UI theme (default, dark, plateau)
        # @option options [String] :title Custom website title
        # @option options [String] :template_dir Custom template directory
        # @option options [String] :assets_dir Custom assets directory
        # @option options [Boolean] :verbose Enable verbose output
        def initialize(options = {})
          @options = normalize_options(options)
          validate_options!
        end

        # Execute SPA generation command
        # @return [void]
        def run
          generator = Spa::Generator.new(
            mode: @options[:mode]&.to_sym || :multi_file,
            theme: @options[:theme] || "default",
            title: @options[:title],
            template_dir: @options[:template_dir],
            assets_dir: @options[:assets_dir],
            verbose: @options[:verbose]
          )

          schema = generator.generate(
            @options[:lxr],
            @options[:yaml],
            @options[:output]
          )

          report_success(schema)
        rescue => e
          report_error(e)
          raise
        end

        private

        # Normalize options to use symbol keys
        # @param options [Hash] Raw options
        # @return [Hash] Normalized options
        def normalize_options(options)
          return {} unless options

          if options.respond_to?(:to_h)
            options.to_h.transform_keys(&:to_sym)
          else
            options
          end
        end

        # Validate command options
        # @raise [ArgumentError] If options are invalid
        def validate_options!
          unless @options[:lxr]
            raise ArgumentError, "--lxr (LXR package path) is required"
          end

          unless File.exist?(@options[:lxr])
            raise ArgumentError, "LXR package not found: #{@options[:lxr]}"
          end

          if @options[:yaml] && !File.exist?(@options[:yaml])
            raise ArgumentError, "YAML mapping not found: #{@options[:yaml]}"
          end

          validate_mode if @options[:mode]
          validate_theme if @options[:theme]
        end

        # Validate mode option
        # @raise [ArgumentError] If mode is invalid
        def validate_mode
          valid_modes = %w[embedded multi-file multi_file]
          mode_str = @options[:mode].to_s.tr("_", "-")

          unless valid_modes.include?(mode_str)
            raise ArgumentError,
                  "Invalid mode: #{@options[:mode]}. " \
                  "Must be 'embedded' or 'multi-file'"
          end
        end

        # Validate theme option
        # @raise [ArgumentError] If theme is invalid
        def validate_theme
          valid_themes = %w[default dark plateau]
          unless valid_themes.include?(@options[:theme])
            raise ArgumentError,
                  "Invalid theme: #{@options[:theme]}. " \
                  "Must be one of: #{valid_themes.join(', ')}"
          end
        end

        # Report successful generation
        # @param schema [Spa::Models::UnifiedSchema] Generated schema
        def report_success(schema)
          puts "\n✓ SPA generated successfully"
          puts "  Mode: #{display_mode}"
          puts "  Output: #{@options[:output] || default_output}"
          puts "  Schemas: #{schema.schemas.size}"
          puts "  Total components: #{total_components(schema)}"

          if @options[:yaml]
            mapped_count = count_mapped_components(schema)
            puts "  UML-mapped components: #{mapped_count}"
          end
        end

        # Report generation error
        # @param error [Exception] Error that occurred
        def report_error(error)
          puts "\n✗ SPA generation failed"
          puts "  Error: #{error.message}"
          puts "  #{error.backtrace.first}" if @options[:verbose]
        end

        # Get display mode string
        # @return [String] Mode for display
        def display_mode
          mode = @options[:mode]&.to_s || "multi-file"
          mode.tr("_", "-")
        end

        # Get default output path
        # @return [String] Default output
        def default_output
          if @options[:mode]&.to_sym == :embedded
            "spa_output.html"
          else
            "spa_output/"
          end
        end

        # Count total components in schema
        # @param schema [Spa::Models::UnifiedSchema] Schema
        # @return [Integer] Total component count
        def total_components(schema)
          schema.elements.size +
            schema.complex_types.size +
            schema.simple_types.size +
            schema.attributes.size
        end

        # Count UML-mapped components
        # @param schema [Spa::Models::UnifiedSchema] Schema
        # @return [Integer] Mapped component count
        def count_mapped_components(schema)
          count = 0
          count += schema.elements.count { |e| e.respond_to?(:uml_mapping) && e.uml_mapping }
          count += schema.complex_types.count { |t| t.respond_to?(:uml_mapping) && t.uml_mapping }
          count += schema.simple_types.count { |t| t.respond_to?(:uml_mapping) && t.uml_mapping }
          count += schema.attributes.count { |a| a.respond_to?(:uml_mapping) && a.uml_mapping }
          count
        end
      end
    end
  end
end