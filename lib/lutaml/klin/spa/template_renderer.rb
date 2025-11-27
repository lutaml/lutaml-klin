# frozen_string_literal: true

require "liquid"
require "json"

module Lutaml
  module Klin
    module Spa
      # Renders Liquid templates with schema data
      class TemplateRenderer
        attr_reader :template_dir, :partials_dir

        def initialize(template_dir = nil)
          @template_dir = template_dir || default_template_dir
          @partials_dir = File.join(@template_dir, "partials")
          @file_system = Liquid::LocalFileSystem.new(@partials_dir)

          # Configure Liquid environment for this instance
          Liquid::Template.file_system = @file_system
        end

        # Render a template with the given context
        # @param template_name [String] Name of the template file (e.g., 'layout.liquid')
        # @param context [Hash] Data to pass to the template
        # @return [String] Rendered HTML
        def render_template(template_name, context = {})
          template_path = File.join(@template_dir, template_name)
          unless File.exist?(template_path)
            raise TemplateNotFoundError,
                  "Template not found: #{template_path}"
          end

          template_content = File.read(template_path)

          # Set file system before parsing
          Liquid::Template.file_system = @file_system

          # Parse and render Liquid template
          template = Liquid::Template.parse(template_content)
          template.render(stringify_keys(context))
        end

        # Render a partial with the given context
        # @param partial_name [String] Name of the partial (without .liquid extension)
        # @param context [Hash] Data to pass to the partial
        # @return [String] Rendered HTML
        def render_partial(partial_name, context = {})
          partial_path = File.join(@partials_dir, "#{partial_name}.liquid")
          unless File.exist?(partial_path)
            raise TemplateNotFoundError,
                  "Partial not found: #{partial_path}"
          end

          partial_content = File.read(partial_path)

          # Set file system before parsing
          Liquid::Template.file_system = @file_system

          template = Liquid::Template.parse(partial_content)
          template.render(stringify_keys(context))
        end

        private

        def default_template_dir
          File.expand_path("templates", __dir__)
        end

        # Convert hash keys to strings recursively
        # Liquid requires string keys for accessing data
        def stringify_keys(obj)
          case obj
          when Hash
            obj.each_with_object({}) do |(key, value), result|
              result[key.to_s] = stringify_keys(value)
            end
          when Array
            obj.map { |item| stringify_keys(item) }
          else
            obj
          end
        end
      end

      # Custom error for template not found
      class TemplateNotFoundError < StandardError; end
    end
  end
end
