# frozen_string_literal: true

module Lutaml
  module Klin
    module Domain
      module Reporters
        # Reporter for generating Markdown validation reports.
        #
        # This reporter converts ValidationResult objects into
        # human-readable Markdown documents with tables, sections,
        # and formatted content.
        #
        # The Markdown format is ideal for documentation, code reviews,
        # and manual inspection of validation results.
        #
        # @example Generating a Markdown report
        #   reporter = MarkdownReporter.new
        #   path = reporter.generate(validation_result, "report.md")
        #   puts "Report written to #{path}"
        class MarkdownReporter
          # Generate a Markdown validation report.
          #
          # @param validation_result [ValidationResult] The validation result
          # @param output_path [String] Path where the report should be written
          # @return [String] The path to the generated report
          def generate(validation_result, output_path)
            content = build_markdown_content(validation_result)

            File.write(output_path, content)
            output_path
          end

          private

          # Build the complete Markdown content.
          #
          # @param result [ValidationResult] The validation result
          # @return [String] Complete Markdown document
          def build_markdown_content(result)
            sections = []

            sections << build_header(result)
            sections << build_summary_section(result)
            sections << build_unresolved_section(result) unless result.valid?
            sections << build_packages_section(result)

            sections.join("\n\n")
          end

          # Build the document header.
          #
          # @param result [ValidationResult] The validation result
          # @return [String] Header section
          def build_header(result)
            status = result.valid? ? "✅ Valid" : "⚠️ Invalid"
            <<~HEADER.chomp
              # UML-to-XSD Validation Report

              **Status:** #{status}
              **Generated:** #{result.generated_at}
            HEADER
          end

          # Build the summary statistics section.
          #
          # @param result [ValidationResult] The validation result
          # @return [String] Summary section
          def build_summary_section(result)
            rate = result.resolution_rate
            rate_status = status_indicator(rate)

            class_status = resolution_status_text(
              result.resolved_classes,
              result.total_classes
            )

            attr_status = resolution_status_text(
              result.resolved_attributes,
              result.total_attributes
            )

            <<~SUMMARY.chomp
              ## Summary

              | Metric | Value | Status |
              |--------|-------|--------|
              | Resolution Rate | #{rate.round(2)}% | #{rate_status} |
              | Packages | #{result.total_packages} | #{status_for_count(result.total_packages)} |
              | Classes | #{result.resolved_classes}/#{result.total_classes} | #{class_status} |
              | Attributes | #{result.resolved_attributes}/#{result.total_attributes} | #{attr_status} |
            SUMMARY
          end

          # Build the unresolved items section.
          #
          # @param result [ValidationResult] The validation result
          # @return [String] Unresolved items section
          def build_unresolved_section(result)
            return "" if result.unresolved_items.empty?

            items_md = result.unresolved_items.map do |item|
              format_unresolved_item(item)
            end.join("\n\n")

            <<~UNRESOLVED.chomp
              ## Unresolved Items

              Found #{result.unresolved_count} unresolved items:

              #{items_md}
            UNRESOLVED
          end

          # Format a single unresolved item.
          #
          # @param item [Hash] Unresolved item details
          # @return [String] Formatted item
          def format_unresolved_item(item)
            suggestions = item[:suggestions] || []
            suggestions_md = if suggestions.empty?
                               "_No suggestions available_"
                             else
                               suggestions.map { |s| "  - #{s}" }.join("\n")
                             end

            <<~ITEM.chomp
              ### #{item[:type].capitalize}: #{item[:package]}::#{item[:class]}::#{item[:attribute]}

              - **UML Type:** `#{item[:uml_type]}`
              - **Status:** #{item[:status]}
              - **Error:** #{item[:error] || 'Unknown error'}

              **Suggestions:**
              #{suggestions_md}
            ITEM
          end

          # Build the packages section.
          #
          # @param result [ValidationResult] The validation result
          # @return [String] Packages section
          def build_packages_section(result)
            return "## Packages\n\n_No packages found_" if result.packages.empty?

            packages_md = result.packages.map do |pkg|
              format_package(pkg)
            end.join("\n\n")

            "## Package Details\n\n#{packages_md}"
          end

          # Format a single package.
          #
          # @param package [Hash] Package details
          # @return [String] Formatted package
          def format_package(package)
            stats = package[:statistics]
            rate = package[:resolution_rate].round(2)
            status = package[:fully_resolved] ? "✅ Fully Resolved" : "⚠️ Partial"

            <<~PACKAGE.chomp
              ### #{package[:name]}

              **Status:** #{status}
              **Namespace:** `#{package[:namespace]}`
              **Resolution Rate:** #{rate}%

              | Metric | Count |
              |--------|-------|
              | Total Classes | #{stats['total_classes']} |
              | Resolved Classes | #{stats['resolved_classes']} |
              | Total Attributes | #{stats['total_attributes']} |
              | Resolved Attributes | #{stats['resolved_attributes']} |
            PACKAGE
          end

          # Get status indicator for a resolution rate.
          #
          # @param rate [Float] Resolution rate percentage
          # @return [String] Status indicator
          def status_indicator(rate)
            case rate
            when 100.0
              "✅ Complete"
            when 90.0..99.9
              "⚠️ Near Complete"
            when 50.0..89.9
              "⚠️ Partial"
            else
              "❌ Incomplete"
            end
          end

          # Get resolution status text.
          #
          # @param resolved [Integer] Resolved count
          # @param total [Integer] Total count
          # @return [String] Status text
          def resolution_status_text(resolved, total)
            return "✅ All resolved" if resolved == total && total > 0
            return "❌ None resolved" if resolved.zero? && total > 0
            return "N/A" if total.zero?

            unresolved = total - resolved
            "⚠️ #{unresolved} unresolved"
          end

          # Get status for a count.
          #
          # @param count [Integer] Count value
          # @return [String] Status text
          def status_for_count(count)
            count > 0 ? "✅" : "❌"
          end
        end
      end
    end
  end
end