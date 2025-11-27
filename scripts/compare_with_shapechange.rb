#!/usr/bin/env ruby
# frozen_string_literal: true

require "nokogiri"
require "fileutils"

# Comparison script for lutaml-klin vs ShapeChange XSD output
class ShapeChangeComparison
  attr_reader :differences, :stats

  def initialize
    @differences = []
    @stats = {
      reference: {},
      generated: {}
    }
  end

  def compare_xsd_files(reference_path, generated_path, schema_name)
    puts "\n#{'=' * 80}"
    puts "  Comparing #{schema_name} XSD Files"
    puts "=" * 80
    puts ""
    puts "Reference: #{reference_path}"
    puts "Generated: #{generated_path}"
    puts ""

    # Read files
    reference_content = File.read(reference_path)
    generated_content = File.read(generated_path)

    # Parse XML
    reference_doc = Nokogiri::XML(reference_content)
    generated_doc = Nokogiri::XML(generated_content)

    # Compare structure
    compare_schema_attributes(reference_doc, generated_doc, schema_name)
    compare_imports(reference_doc, generated_doc, schema_name)
    compare_elements(reference_doc, generated_doc, schema_name)
    compare_complex_types(reference_doc, generated_doc, schema_name)
    compare_simple_types(reference_doc, generated_doc, schema_name)
    compare_ade_hooks(reference_doc, generated_doc, schema_name)

    # Display results
    puts "\n#{'-' * 80}"
    puts "  Comparison Results for #{schema_name}"
    puts "-" * 80
    display_differences(schema_name)
    puts ""
  end

  def display_statistics
    puts "\n#{'=' * 80}"
    puts "  Statistics Summary"
    puts "=" * 80
    puts ""

    @stats[:reference].each do |schema, data|
      puts "#{schema} (Reference):"
      puts "  Imports: #{data[:imports] || 0}"
      puts "  Elements: #{data[:elements] || 0}"
      puts "  Complex Types: #{data[:complex_types] || 0}"
      puts "  Simple Types: #{data[:simple_types] || 0}"
      puts "  ADE Hooks: #{data[:ade_hooks] || 0}"
      puts ""

      gen_data = @stats[:generated][schema]
      puts "#{schema} (Generated):"
      puts "  Imports: #{gen_data[:imports] || 0}"
      puts "  Elements: #{gen_data[:elements] || 0}"
      puts "  Complex Types: #{gen_data[:complex_types] || 0}"
      puts "  Simple Types: #{gen_data[:simple_types] || 0}"
      puts "  ADE Hooks: #{gen_data[:ade_hooks] || 0}"
      puts ""
    end
  end

  def generate_report(output_path)
    File.open(output_path, "w") do |f|
      f.puts "# ShapeChange Compatibility Validation Report"
      f.puts ""
      f.puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
      f.puts ""

      f.puts "## Statistics"
      f.puts ""
      @stats[:reference].each do |schema, data|
        f.puts "### #{schema}"
        f.puts ""
        f.puts "| Metric | Reference | Generated | Match |"
        f.puts "| ------ | --------- | --------- | ----- |"

        gen_data = @stats[:generated][schema]
        %i[imports elements complex_types simple_types
           ade_hooks].each do |metric|
          ref_val = data[metric] || 0
          gen_val = gen_data[metric] || 0
          match = ref_val == gen_val ? "✓" : "✗"
          f.puts "| #{metric.to_s.capitalize.gsub('_',
                                                  ' ')} | #{ref_val} | #{gen_val} | #{match} |"
        end
        f.puts ""
      end

      f.puts "## Differences Found"
      f.puts ""
      if @differences.empty?
        f.puts "✓ No semantic differences found."
      else
        @differences.group_by { |d| d[:schema] }.each do |schema, diffs|
          f.puts "### #{schema}"
          f.puts ""
          diffs.group_by { |d| d[:category] }.each do |category, cat_diffs|
            f.puts "#### #{category}"
            f.puts ""
            cat_diffs.each do |diff|
              f.puts "- #{diff[:description]}"
            end
            f.puts ""
          end
        end
      end
    end

    puts "\n✓ Report saved to: #{output_path}"
  end

  private

  def compare_schema_attributes(ref_doc, gen_doc, schema_name)
    ref_schema = ref_doc.root
    gen_schema = gen_doc.root

    # Check schema element name
    if ref_schema.name != gen_schema.name
      record_difference(schema_name, "Schema Element Name",
                        "Reference: #{ref_schema.name}, Generated: #{gen_schema.name}")
    end

    # Check targetNamespace
    ref_ns = ref_schema["targetNamespace"]
    gen_ns = gen_schema["targetNamespace"]
    if ref_ns != gen_ns
      record_difference(schema_name, "Target Namespace",
                        "Reference: #{ref_ns}, Generated: #{gen_ns}")
    end

    # Check version
    ref_version = ref_schema["version"]
    gen_version = gen_schema["version"]
    if ref_version&.strip != gen_version&.strip
      record_difference(schema_name, "Version",
                        "Reference: #{ref_version}, Generated: #{gen_version}")
    end

    # Check elementFormDefault
    ref_form = ref_schema["elementFormDefault"]
    gen_form = gen_schema["elementFormDefault"]
    if ref_form != gen_form
      record_difference(schema_name, "Element Form Default",
                        "Reference: #{ref_form}, Generated: #{gen_form}")
    end

    # Check attributeFormDefault
    ref_attr_form = ref_schema["attributeFormDefault"]
    gen_attr_form = gen_schema["attributeFormDefault"]
    return unless ref_attr_form != gen_attr_form && ref_attr_form

    record_difference(schema_name, "Attribute Form Default",
                      "Reference: #{ref_attr_form}, Generated: #{gen_attr_form || 'missing'}")
  end

  def compare_imports(ref_doc, gen_doc, schema_name)
    ref_imports = ref_doc.xpath("//xs:import",
                                { "xs" => "http://www.w3.org/2001/XMLSchema" })
    gen_imports = gen_doc.xpath("//xs:import",
                                { "xs" => "http://www.w3.org/2001/XMLSchema" })

    ref_namespaces = ref_imports.map { |i| i["namespace"] }.compact.sort
    gen_namespaces = gen_imports.map { |i| i["namespace"] }.compact.sort

    @stats[:reference][schema_name] ||= {}
    @stats[:generated][schema_name] ||= {}
    @stats[:reference][schema_name][:imports] = ref_namespaces.size
    @stats[:generated][schema_name][:imports] = gen_namespaces.size

    missing = ref_namespaces - gen_namespaces
    extra = gen_namespaces - ref_namespaces

    if missing.any?
      record_difference(schema_name, "Missing Imports", missing.join(", "))
    end

    if extra.any?
      record_difference(schema_name, "Extra Imports", extra.join(", "))
    end

    # Check schema locations
    ref_imports.each do |ref_import|
      ns = ref_import["namespace"]
      gen_import = gen_imports.find { |gi| gi["namespace"] == ns }
      next unless gen_import

      ref_loc = ref_import["schemaLocation"]
      gen_loc = gen_import["schemaLocation"]

      if ref_loc != gen_loc
        record_difference(schema_name, "Schema Location for #{ns}",
                          "Reference: #{ref_loc}, Generated: #{gen_loc}")
      end
    end
  end

  def compare_elements(ref_doc, gen_doc, schema_name)
    ref_elements = ref_doc.xpath("//xs:element[@name]",
                                 { "xs" => "http://www.w3.org/2001/XMLSchema" })
    gen_elements = gen_doc.xpath("//xs:element[@name]",
                                 { "xs" => "http://www.w3.org/2001/XMLSchema" })

    ref_element_names = ref_elements.map { |e| e["name"] }.compact.sort
    gen_element_names = gen_elements.map { |e| e["name"] }.compact.sort

    @stats[:reference][schema_name][:elements] = ref_element_names.size
    @stats[:generated][schema_name][:elements] = gen_element_names.size

    missing = ref_element_names - gen_element_names
    extra = gen_element_names - ref_element_names

    if missing.any?
      record_difference(schema_name, "Missing Elements (#{missing.size})",
                        missing[0..4].join(", "))
    end

    if extra.any?
      record_difference(schema_name, "Extra Elements (#{extra.size})",
                        extra[0..4].join(", "))
    end

    # Compare element attributes for common elements
    common_elements = ref_element_names & gen_element_names
    common_elements.each do |elem_name|
      ref_elem = ref_elements.find { |e| e["name"] == elem_name }
      gen_elem = gen_elements.find { |e| e["name"] == elem_name }

      # Compare type
      if ref_elem["type"] != gen_elem["type"]
        record_difference(schema_name, "Element #{elem_name} type",
                          "Reference: #{ref_elem['type']}, Generated: #{gen_elem['type']}")
      end

      # Compare substitutionGroup
      if ref_elem["substitutionGroup"] != gen_elem["substitutionGroup"]
        record_difference(schema_name, "Element #{elem_name} substitutionGroup",
                          "Reference: #{ref_elem['substitutionGroup']}, Generated: #{gen_elem['substitutionGroup']}")
      end

      # Compare abstract
      if ref_elem["abstract"] != gen_elem["abstract"]
        record_difference(schema_name, "Element #{elem_name} abstract",
                          "Reference: #{ref_elem['abstract']}, Generated: #{gen_elem['abstract']}")
      end
    end
  end

  def compare_complex_types(ref_doc, gen_doc, schema_name)
    ref_types = ref_doc.xpath("//xs:complexType[@name]",
                              { "xs" => "http://www.w3.org/2001/XMLSchema" })
    gen_types = gen_doc.xpath("//xs:complexType[@name]",
                              { "xs" => "http://www.w3.org/2001/XMLSchema" })

    ref_type_names = ref_types.map { |t| t["name"] }.compact.sort
    gen_type_names = gen_types.map { |t| t["name"] }.compact.sort

    @stats[:reference][schema_name][:complex_types] = ref_type_names.size
    @stats[:generated][schema_name][:complex_types] = gen_type_names.size

    missing = ref_type_names - gen_type_names
    extra = gen_type_names - ref_type_names

    if missing.any?
      record_difference(schema_name, "Missing Complex Types (#{missing.size})",
                        missing[0..4].join(", "))
    end

    if extra.any?
      record_difference(schema_name, "Extra Complex Types (#{extra.size})",
                        extra[0..4].join(", "))
    end

    # Compare type structure for common types (sample a few)
    common_types = ref_type_names & gen_type_names
    common_types.first(5).each do |type_name|
      ref_type = ref_types.find { |t| t["name"] == type_name }
      gen_type = gen_types.find { |t| t["name"] == type_name }

      # Check if abstract
      if ref_type["abstract"] != gen_type["abstract"]
        record_difference(schema_name, "ComplexType #{type_name} abstract",
                          "Reference: #{ref_type['abstract']}, Generated: #{gen_type['abstract']}")
      end

      # Check if has extension
      ref_extension = ref_type.xpath(".//xs:extension",
                                     { "xs" => "http://www.w3.org/2001/XMLSchema" }).first
      gen_extension = gen_type.xpath(".//xs:extension",
                                     { "xs" => "http://www.w3.org/2001/XMLSchema" }).first

      if ref_extension && !gen_extension
        record_difference(schema_name, "ComplexType #{type_name} extension",
                          "Reference has extension, Generated missing")
      elsif !ref_extension && gen_extension
        record_difference(schema_name, "ComplexType #{type_name} extension",
                          "Generated has extension, Reference missing")
      elsif ref_extension && gen_extension
        ref_base = ref_extension["base"]
        gen_base = gen_extension["base"]
        if ref_base != gen_base
          record_difference(schema_name, "ComplexType #{type_name} base",
                            "Reference: #{ref_base}, Generated: #{gen_base}")
        end
      end

      # Check sequence children count
      ref_seq = ref_type.xpath(".//xs:sequence",
                               { "xs" => "http://www.w3.org/2001/XMLSchema" }).first
      gen_seq = gen_type.xpath(".//xs:sequence",
                               { "xs" => "http://www.w3.org/2001/XMLSchema" }).first

      next unless ref_seq && gen_seq

      ref_children = ref_seq.xpath(".//xs:element",
                                   { "xs" => "http://www.w3.org/2001/XMLSchema" }).size
      gen_children = gen_seq.xpath(".//xs:element",
                                   { "xs" => "http://www.w3.org/2001/XMLSchema" }).size

      if ref_children != gen_children && ref_children.positive?
        record_difference(schema_name, "ComplexType #{type_name} sequence children",
                          "Reference: #{ref_children} elements, Generated: #{gen_children} elements")
      end
    end
  end

  def compare_simple_types(ref_doc, gen_doc, schema_name)
    ref_types = ref_doc.xpath("//xs:simpleType[@name]",
                              { "xs" => "http://www.w3.org/2001/XMLSchema" })
    gen_types = gen_doc.xpath("//xs:simpleType[@name]",
                              { "xs" => "http://www.w3.org/2001/XMLSchema" })

    ref_type_names = ref_types.map { |t| t["name"] }.compact.sort
    gen_type_names = gen_types.map { |t| t["name"] }.compact.sort

    @stats[:reference][schema_name][:simple_types] = ref_type_names.size
    @stats[:generated][schema_name][:simple_types] = gen_type_names.size

    missing = ref_type_names - gen_type_names
    extra = gen_type_names - ref_type_names

    if missing.any?
      record_difference(schema_name, "Missing Simple Types (#{missing.size})",
                        missing.join(", "))
    end

    return unless extra.any?

    record_difference(schema_name, "Extra Simple Types (#{extra.size})",
                      extra.join(", "))
  end

  def compare_ade_hooks(ref_doc, gen_doc, schema_name)
    # ADE hooks are elements with substitutionGroup pointing to CityGML types
    # e.g., substitutionGroup="bldg:_GenericApplicationPropertyOfAbstractBuilding"
    ref_hooks = ref_doc.xpath("//xs:element[contains(@substitutionGroup, '_GenericApplicationPropertyOf')]",
                              { "xs" => "http://www.w3.org/2001/XMLSchema" })
    gen_hooks = gen_doc.xpath("//xs:element[contains(@substitutionGroup, '_GenericApplicationPropertyOf')]",
                              { "xs" => "http://www.w3.org/2001/XMLSchema" })

    ref_hook_names = ref_hooks.map { |h| h["name"] }.compact.sort
    gen_hook_names = gen_hooks.map { |h| h["name"] }.compact.sort

    @stats[:reference][schema_name][:ade_hooks] = ref_hook_names.size
    @stats[:generated][schema_name][:ade_hooks] = gen_hook_names.size

    missing = ref_hook_names - gen_hook_names
    extra = gen_hook_names - ref_hook_names

    if missing.any?
      record_difference(schema_name, "Missing ADE Hooks (#{missing.size})",
                        missing[0..9].join(", "))
    end

    return unless extra.any?

    record_difference(schema_name, "Extra ADE Hooks (#{extra.size})",
                      extra[0..9].join(", "))
  end

  def record_difference(schema, category, description)
    @differences << {
      schema: schema,
      category: category,
      description: description
    }
  end

  def display_differences(schema_name)
    schema_diffs = @differences.select { |d| d[:schema] == schema_name }

    if schema_diffs.empty?
      puts "✓ No major differences found (only formatting may differ)"
      return
    end

    puts "❌ Found #{schema_diffs.size} difference(s):"
    puts ""

    schema_diffs.group_by { |d| d[:category] }.each do |category, diffs|
      puts "  #{category}:"
      diffs.each do |diff|
        puts "    - #{diff[:description]}"
      end
      puts ""
    end
  end
end

# Main execution
if __FILE__ == $PROGRAM_NAME
  comparer = ShapeChangeComparison.new

  # Compare URO schemas
  comparer.compare_xsd_files(
    "/Users/mulgogi/src/mn/mn-samples-plateau/reference-docs/xsd/i-ur/urbanObject.xsd",
    "final_schemas/urbanObject.xsd",
    "urbanObject (URO)"
  )

  # Compare URF schemas
  comparer.compare_xsd_files(
    "/Users/mulgogi/src/mn/mn-samples-plateau/reference-docs/xsd/i-ur/urbanFunction.xsd",
    "final_schemas/urbanFunction.xsd",
    "urbanFunction (URF)"
  )

  # Display overall statistics
  comparer.display_statistics

  # Generate report
  FileUtils.mkdir_p("docs")
  comparer.generate_report("docs/SHAPECHANGE-COMPATIBILITY-VALIDATION.md")

  puts "\n#{'=' * 80}"
  puts "  Comparison Complete"
  puts "=" * 80
  puts ""

  exit(comparer.differences.any? ? 1 : 0)
end
