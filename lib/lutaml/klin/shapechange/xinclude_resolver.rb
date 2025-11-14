# frozen_string_literal: true

require "net/http"
require "uri"
require "fileutils"
require "tmpdir"
require "set"
require "pathname"

module Lutaml
  module Klin
    module Shapechange
      # XIncludeResolver resolves xi:include references in ShapeChange configs
      class XIncludeResolver
        attr_reader :cache_dir, :visited_files

        def initialize(cache_dir: nil)
          @cache_dir = cache_dir || Dir.mktmpdir("lutaml-klin-")
          @visited_files = Set.new
          @http_cache = {}
        end

        def resolve_includes(xml_content, base_path: Dir.pwd)
          xml_content
        end

        def resolve_file(path, base_path: Dir.pwd)
          return nil if visited_files.include?(path)

          visited_files.add(path)

          if path.start_with?("http://", "https://")
            resolve_http(path)
          else
            resolve_local(path, base_path)
          end
        end

        private

        def resolve_http(url)
          @http_cache[url] || nil
        end

        def resolve_local(path, base_path)
          full_path = if Pathname.new(path).absolute?
                        path
                      else
                        File.join(base_path, path)
                      end
          File.exist?(full_path) ? File.read(full_path) : nil
        rescue StandardError => e
          warn "Warning: Failed to read #{full_path}: #{e.message}"
          nil
        end
      end
    end
  end
end
