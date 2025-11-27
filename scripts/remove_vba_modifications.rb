#!/usr/bin/env ruby
# frozen_string_literal: true

# Removes VBA formatting modifications from PLATEAU XSD files
# Returns XSD to raw ShapeChange output state

require "nokogiri"
require "fileutils"

class VBAModificationRemover
  MARKER_START = "整形プログラムによる「_GenericApplicationPropertyOf」関係の追記　↓"
  MARKER_END = "整形プログラムによる「_GenericApplicationPropertyOf」関係の追記　↑"

  def initialize(input_file, output_file)
    @input_file = input_file
    @output_file = output_file
  end

  def remove_modifications
    content = File.read(@input_file)
    lines = content.lines

    # Find sections to remove
    sections_to_remove = find_removal_sections(lines)

    if sections_to_remove.empty?
      puts "No VBA modifications found in #{File.basename(@input_file)}"
      # Just copy the file as-is
      FileUtils.cp(@input_file, @output_file)
      return { removed: 0 }
    end

    # Remove the sections
    cleaned_lines = remove_sections(lines, sections_to_remove)

    # Write cleaned content
    File.write(@output_file, cleaned_lines.join)

    removed_count = sections_to_remove.sum { |s| s[:end] - s[:start] + 1 }

    puts "Removed VBA modifications from #{File.basename(@input_file)}"
    puts "  - Removed #{removed_count} lines"
    puts "  - Output: #{@output_file}"

    { removed: removed_count }
  end

  private

  def find_removal_sections(lines)
    sections = []
    start_line = nil

    lines.each_with_index do |line, idx|
      if line.include?(MARKER_START)
        start_line = idx
      elsif line.include?(MARKER_END) && start_line
        sections << { start: start_line, end: idx }
        start_line = nil
      end
    end

    sections
  end

  def remove_sections(lines, sections)
    # Create a set of line indices to remove
    lines_to_remove = Set.new
    sections.each do |section|
      (section[:start]..section[:end]).each { |i| lines_to_remove.add(i) }
    end

    # Filter out removed lines
    lines.select.with_index { |_, idx| !lines_to_remove.include?(idx) }
  end
end

# Process urbanObject.xsd and urbanFunction.xsd
if __FILE__ == $PROGRAM_NAME
  require "set"

  files_to_process = [
    {
      input: "packages/plateau_schemas_extracted/schemas/urbanObject.xsd",
      output: "spec/fixtures/shapechange_unmodified/urbanObject.xsd"
    },
    {
      input: "packages/plateau_schemas_extracted/schemas/urbanFunction.xsd",
      output: "spec/fixtures/shapechange_unmodified/urbanFunction.xsd"
    }
  ]

  # Ensure output directory exists
  FileUtils.mkdir_p("spec/fixtures/shapechange_unmodified")

  total_removed = 0

  files_to_process.each do |file_pair|
    if File.exist?(file_pair[:input])
      remover = VBAModificationRemover.new(file_pair[:input],
                                           file_pair[:output])
      result = remover.remove_modifications
      total_removed += result[:removed]
    else
      puts "Warning: Input file not found: #{file_pair[:input]}"
    end
  end

  puts "\n#{'=' * 80}"
  puts "Total lines removed: #{total_removed}"
  puts "Unmodified reference XSD files created in spec/fixtures/shapechange_unmodified/"
  puts "=" * 80
end
