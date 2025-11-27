# frozen_string_literal: true

require "fileutils"
require "digest"
require_relative "errors"

module Lutaml
  module Klin
    module Lxr
      # CacheManager manages LXR package caching to avoid unnecessary rebuilds
      # Responsible for cache key generation, validation, and cleanup
      class CacheManager
        DEFAULT_CACHE_DIR = ".lutaml-klin/cache"

        attr_reader :cache_dir

        # @param cache_dir [String] Directory for cached LXR packages
        def initialize(cache_dir = nil)
          @cache_dir = cache_dir || DEFAULT_CACHE_DIR
          ensure_cache_dir_exists
        end

        # Get cached LXR path if exists and valid
        # @param config_path [String] Path to ShapeChange configuration file
        # @return [String, nil] Path to cached LXR or nil if not cached
        def cached_lxr_path(config_path)
          unless File.exist?(config_path)
            raise InvalidInputError, "Config file not found: #{config_path}"
          end

          cache_file = cache_file_path(config_path)
          return nil unless File.exist?(cache_file)

          # Validate cache is still valid
          if cache_valid?(cache_file, config_path)
            cache_file
          else
            # Invalid cache, remove it
            File.unlink(cache_file)
            nil
          end
        end

        # Cache an LXR package
        # @param source_lxr_path [String] Path to source LXR package
        # @param config_path [String] Path to ShapeChange config used to create it
        # @return [String] Path to cached LXR
        def cache_lxr(source_lxr_path, config_path)
          unless File.exist?(source_lxr_path)
            raise PackageBuildError, "Source LXR not found: #{source_lxr_path}"
          end

          unless File.exist?(config_path)
            raise InvalidInputError, "Config file not found: #{config_path}"
          end

          cache_file = cache_file_path(config_path)

          # Copy to cache
          FileUtils.cp(source_lxr_path, cache_file)

          cache_file
        end

        # Invalidate cached LXR for given config
        # @param config_path [String] Path to ShapeChange configuration file
        # @return [Boolean] True if cache was removed
        def invalidate(config_path)
          cache_file = cache_file_path(config_path)
          if File.exist?(cache_file)
            File.unlink(cache_file)
            true
          else
            false
          end
        end

        # Clean old cached LXR packages
        # @param max_age_days [Integer] Maximum age in days
        # @return [Array<String>] Paths of removed cache files
        def clean_old_caches(max_age_days = 30)
          return [] unless Dir.exist?(cache_dir)

          max_age_seconds = max_age_days * 24 * 60 * 60
          current_time = Time.now
          removed_files = []

          Dir.glob(File.join(cache_dir, "*.lxr")).each do |cache_file|
            file_age = current_time - File.mtime(cache_file)
            if file_age > max_age_seconds
              File.unlink(cache_file)
              removed_files << cache_file
            end
          end

          removed_files
        end

        private

        # Generate cache file path for config
        # @param config_path [String] Path to ShapeChange configuration
        # @return [String] Path to cache file
        def cache_file_path(config_path)
          key = cache_key(config_path)
          File.join(cache_dir, "#{key}.lxr")
        end

        # Generate unique cache key from config file
        # @param config_path [String] Path to ShapeChange configuration
        # @return [String] Cache key
        def cache_key(config_path)
          # Use config basename and modification time
          config_basename = File.basename(config_path, ".*")
          config_mtime = File.mtime(config_path).to_i

          # Also include content hash for robustness
          content_hash = Digest::MD5.file(config_path).hexdigest[0..7]

          "#{config_basename}_#{config_mtime}_#{content_hash}"
        end

        # Check if cached LXR is still valid
        # @param cache_file [String] Path to cached LXR
        # @param config_path [String] Path to ShapeChange configuration
        # @return [Boolean] True if cache is valid
        def cache_valid?(cache_file, config_path)
          return false unless File.exist?(cache_file)
          return false if File.empty?(cache_file)

          # Cache is valid if config hasn't been modified since cache creation
          File.mtime(cache_file) >= File.mtime(config_path)
        end

        # Ensure cache directory exists
        # @return [void]
        def ensure_cache_dir_exists
          FileUtils.mkdir_p(cache_dir)
        end
      end
    end
  end
end
