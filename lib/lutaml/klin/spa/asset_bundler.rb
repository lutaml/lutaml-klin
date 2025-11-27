# frozen_string_literal: true

require "fileutils"

module Lutaml
  module Klin
    module Spa
      # Bundles CSS and JavaScript assets for SPA templates
      # Supports both embedded mode (inline) and multi-file mode (separate files)
      class AssetBundler
        attr_reader :assets_dir

        def initialize(assets_dir = nil)
          @assets_dir = assets_dir || default_assets_dir
        end

        # Generate inline CSS for embedded mode
        # @return [String] Combined CSS content
        def inline_css
          css_files = [
            "css/main.css",
            "css/navigation.css",
            "css/content.css",
            "css/responsive.css"
          ]

          css_files.map do |file|
            file_path = File.join(@assets_dir, file)
            if File.exist?(file_path)
              File.read(file_path)
            else
              warn "Warning: CSS file not found: #{file_path}"
              ""
            end
          end.join("\n\n")
        end

        # Generate inline JavaScript for embedded mode
        # @return [String] Combined JavaScript content
        def inline_js
          js_files = [
            "js/utils.js",
            "js/navigation.js",
            "js/search.js",
            "js/renderer.js",
            "js/router.js",
            "js/app.js"
          ]

          js_files.map do |file|
            file_path = File.join(@assets_dir, file)
            if File.exist?(file_path)
              File.read(file_path)
            else
              warn "Warning: JS file not found: #{file_path}"
              ""
            end
          end.join("\n\n")
        end

        # Copy all assets to output directory for multi-file mode
        # @param output_dir [String] Destination directory
        def copy_assets(output_dir)
          assets_output = File.join(output_dir, "assets")
          FileUtils.mkdir_p(assets_output)

          # Copy CSS
          copy_directory("css", assets_output)

          # Copy JS
          copy_directory("js", assets_output)

          # Copy icons if they exist
          copy_directory("icons", assets_output) if directory_exists?("icons")

          # Copy fonts if they exist
          copy_directory("fonts", assets_output) if directory_exists?("fonts")
        end

        # Get list of CSS files
        # @return [Array<String>] CSS file paths
        def css_files
          [
            "css/main.css",
            "css/navigation.css",
            "css/content.css",
            "css/responsive.css"
          ]
        end

        # Get list of JS files
        # @return [Array<String>] JavaScript file paths
        def js_files
          [
            "js/utils.js",
            "js/navigation.js",
            "js/search.js",
            "js/renderer.js",
            "js/router.js",
            "js/app.js"
          ]
        end

        private

        def default_assets_dir
          File.expand_path("assets", __dir__)
        end

        # Copy a directory from assets to output
        # @param dir_name [String] Directory name (relative to assets_dir)
        # @param output_dir [String] Destination directory
        def copy_directory(dir_name, output_dir)
          src_dir = File.join(@assets_dir, dir_name)
          dest_dir = File.join(output_dir, dir_name)

          if Dir.exist?(src_dir)
            FileUtils.mkdir_p(dest_dir)
            FileUtils.cp_r(File.join(src_dir, "."), dest_dir)
          else
            warn "Warning: Directory not found: #{src_dir}"
          end
        end

        # Check if a directory exists in assets
        # @param dir_name [String] Directory name (relative to assets_dir)
        # @return [Boolean]
        def directory_exists?(dir_name)
          Dir.exist?(File.join(@assets_dir, dir_name))
        end
      end
    end
  end
end
