#!/usr/bin/env ruby
# frozen_string_literal: true

# Analyzes VBA formatting modifications in PLATEAU XSD files
# Identifies what elements were added by XSD整形.xlsm

require "nokogiri"
require "fileutils"

class VBAModificationAnalyzer
  MARKER_START = "整形プログラムによる「_GenericApplicationPropertyOf」関係の追記　↓"
  MARKER_END = "整形プログラムによる「_GenericApplicationPropertyOf」関係の追記　↑"

  def initialize(xsd_file)
    @xsd_file = xsd_file
    @content = File.read(xsd_file)
    @doc = Nokogiri::XML(@content)
  end

  def analyze
    puts "=" * 80
    puts "Analyzing VBA Modifications: #{File.basename(@xsd_file)}"
    puts "=" * 80

    # Find modification sections
    sections = find_modification_sections

    if sections.empty?
      puts "No VBA modification markers found."
      return { elements: [], count: 0 }
    end

    # Extract modified elements
    elements = extract_modified_elements(sections)

    # Print analysis
    print_analysis(elements)

    { elements: elements, count: elements.size }
  end

  private

  def find_modification_sections
    lines = @content.lines
    sections = []
    start_line = nil

    lines.each_with_index do |line, idx|
      if line.include?(MARKER_START)
        start_line = idx
      elsif line.include?(MARKER_END) && start_line
        sections << { start: start_line, end: idx,
                      lines: lines[start_line..idx] }
        start_line = nil
      end
    end

    sections
  end

  def extract_modified_elements(sections)
    elements = []

    sections.each do |section|
      section[:lines].each do |line|
        # Match element declarations
        unless (match = line.match(/<xs:element\s+name="([^"]+)"\s+type="([^"]+)"\s+substitutionGroup="([^"]+)"/))
          next
        end

        elements << {
          name: match[1],
          type: match[2],
          substitution_group: match[3],
          line: line.strip
        }
      end
    end

    elements
  end

  def print_analysis(elements)
    puts "\nTotal VBA-added elements: #{elements.size}"
    puts "\nElements by substitution group:"

    grouped = elements.group_by { |e| e[:substitution_group] }
    grouped.sort_by { |_k, v| -v.size }.each do |group, elems|
      puts "\n  #{group} (#{elems.size} elements):"
      elems.first(3).each do |elem|
        puts "    - #{elem[:name]}: #{elem[:type]}"
      end
      puts "    ... and #{elems.size - 3} more" if elems.size > 3
    end

    puts "\nElement name patterns:"
    prefixes = elements.map do |e|
      e[:name].match(/^([a-z]+)/)[1]
    rescue StandardError
      nil
    end.compact.uniq.sort
    puts "  Prefixes found: #{prefixes.join(', ')}"

    puts "\nType patterns:"
    types = elements.map { |e| e[:type] }.uniq.sort
    puts "  Unique types: #{types.size}"
    types.first(10).each { |t| puts "    - #{t}" }
    puts "    ... and #{types.size - 10} more" if types.size > 10
  end
end

# Run analysis on urbanObject.xsd
if __FILE__ == $PROGRAM_NAME
  xsd_file = "packages/plateau_schemas_extracted/schemas/urbanObject.xsd"

  if File.exist?(xsd_file)
    analyzer = VBAModificationAnalyzer.new(xsd_file)
    result = analyzer.analyze

    puts "\n#{'=' * 80}"
    puts "Summary: #{result[:count]} elements added by VBA formatting program"
    puts "=" * 80
  else
    puts "Error: XSD file not found: #{xsd_file}"
    puts "Please extract the LXR package first."
    exit 1
  end
end
