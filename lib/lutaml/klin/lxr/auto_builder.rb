# frozen_string_literal: true

require "tempfile"
require_relative "cache_manager"
require_relative "errors"
require_relative "../shapechange/lxr_extractor"
require_relative "input_strategy"
require_relative "config_builder"
require_relative "package_builder"

module Lutaml
  module Klin
    module Lxr
      # AutoBuilder orchestrates automatic LXR package creation during workflow
      # Responsible for cache management and seamless LXR generation
      class AutoBuilder
        attr_reader :config_path, :options, :extractor, :cache_manager

        # @param shapechange_config_path [String] Path to ShapeChange configuration
        # @param options [Hash] Build options
        # @option options [String] :cache_dir Directory for cached LXR packages
        # @option options [Boolean] :force_rebuild Force rebuild even if cached
        # @option options [Boolean] :verbose Enable verbose output
        # @option options [String] :xsd_mode XSD bundling mode
        # @option options [String] :resolution_mode Resolution mode
        # @option options [String] :format Serialization format
        def initialize(shapechange_config_path, options = {})
          @config_path = shapechange_config_path
          @options = options
          @extractor = Shapechange::LxrExtractor.new
          @cache_manager = CacheManager.new(options[:cache_dir])

          validate_config_exists!
        end

        # Build or use existing cached LXR package
        # @return [String] Path to LXR package (cached or newly built)
        def build_or_use_existing
          # Check cache first unless force rebuild
          unless options[:force_rebuild]
            cached_path = cache_manager.cached_lxr_path(config_path)
            if cached_path
              log("✓ Cache hit: Using #{cached_path}")
              return cached_path
            end
          end

          log("⚠️  Cache miss - building new LXR package")

          # Build new LXR package
          lxr_path = build_lxr_package

          # Cache it for future use
          cached_path = cache_manager.cache_lxr(lxr_path, config_path)
          log("💾 Cached for future use: #{cached_path}")

          # Remove temporary file if it was created
          if lxr_path != cached_path && File.exist?(lxr_path)
            File.unlink(lxr_path)
          end

          cached_path
        rescue StandardError => e
          raise AutoLxrError, "Failed to build LXR package: #{e.message}"
        end

        private

        # Validate that config file exists
        # @raise [InvalidInputError] If config doesn't exist
        def validate_config_exists!
          return if File.exist?(config_path)

          raise InvalidInputError,
                "ShapeChange config not found: #{config_path}"
        end

        # Build LXR package from ShapeChange config
        # @return [String] Path to built LXR package
        def build_lxr_package
          log("📋 Extracting schema info from ShapeChange config...")

          # Extract schema information
          schema_info = extractor.extract_schema_info(config_path)

          log("✓ Found #{schema_info[:xsd_files].size} XSD files, " \
              "#{schema_info[:namespace_mappings].size} namespace mappings")

          # Build configuration using InputStrategy and ConfigBuilder
          log("📦 Building LXR package configuration...")

          input_strategy = InputStrategy.from_shapechange(
            shapechange_config_path: config_path,
            schema_info: schema_info
          )

          config_builder = ConfigBuilder.new(
            xsd_mode: options[:xsd_mode] || "include_all",
            resolution_mode: options[:resolution_mode] || "resolved",
            format: options[:format] || "marshal"
          )

          config_hash = config_builder.build(input_strategy)

          # Build package
          log("🔨 Building LXR package...")

          # Create temporary output path
          temp_lxr = Tempfile.new(["auto_lxr", ".lxr"])
          temp_lxr.close

          builder = PackageBuilder.new(verbose: options[:verbose])
          result = builder.build(
            config_hash,
            temp_lxr.path,
            name: options[:name] || derive_package_name,
            version: options[:version] || "1.0.0",
            description: options[:description] || derive_package_description,
            validate: true
          )

          unless result[:success]
            raise PackageBuildError,
                  "LXR build failed: #{result[:messages].join("\n")}"
          end

          log("✓ LXR package created: #{temp_lxr.path}")

          temp_lxr.path
        end

        # Derive package name from config file
        # @return [String] Package name
        def derive_package_name
          File.basename(config_path, ".*").gsub(/[^a-zA-Z0-9_-]/, "_")
        end

        # Derive package description from config file
        # @return [String] Package description
        def derive_package_description
          "Auto-generated LXR package from #{File.basename(config_path)}"
        end

        # Log message if verbose mode enabled
        # @param message [String] Message to log
        def log(message)
          puts message if options[:verbose]
        end
      end
    end
  end
end
