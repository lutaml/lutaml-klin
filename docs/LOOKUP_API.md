# Bidirectional Lookup API: UML ↔ XSD Mappings

## Overview

The Lutaml-Klin Lookup API provides bidirectional mapping queries between UML models and XSD schemas. It enables you to:

- **UML → XSD**: Find XSD types/elements for UML classes/attributes
- **XSD → UML**: Find UML classes/attributes for XSD types/elements
- **Auto-detection**: Automatically detect lookup direction based on identifier format
- **Fuzzy matching**: Find partial matches when exact identifiers are unknown

## Architecture

The lookup system consists of three main components:

1. **LookupResult** (Domain Value Object): Encapsulates lookup results with metadata
2. **LookupService** (Domain Service): Core bidirectional lookup logic with O(1) indexed lookups
3. **LookupWorkflow** (Application Layer): Orchestrates loading mappings and executing lookups

## Ruby API

### Basic Usage

```ruby
require "lutaml/klin/application/lookup_workflow"

# Initialize workflow with mapping file
workflow = Lutaml::Klin::Application::LookupWorkflow.new("mapping.yaml")

# Perform lookups
result = workflow.lookup_uml_to_xsd("ModelRoot::i-UR::urf::UrbanPlanningArea")
```

### UML → XSD Lookups

#### Lookup UML Class

```ruby
# Find XSD mapping for a UML class
result = workflow.lookup_uml_to_xsd(
  "ModelRoot::i-UR::urf::UrbanPlanningArea",
  type: :class
)

if result.found?
  match = result.first_match
  puts "XSD Element: #{match[:xsd_element]}"
  puts "XSD Type: #{match[:xsd_type]}"
  puts "XSD Namespace: #{match[:xsd_namespace]}"
end
```

#### Lookup UML Attribute

```ruby
# Find XSD mapping for a UML attribute
result = workflow.lookup_uml_to_xsd(
  "ModelRoot::i-UR::urf::UrbanPlanningArea::areaType",
  type: :attribute
)

if result.found?
  match = result.first_match
  puts "XSD Name: #{match[:xsd_name]}"
  puts "XSD Type: #{match[:xsd_type]}"
  puts "Min Occurs: #{match[:min_occurs]}"
  puts "Max Occurs: #{match[:max_occurs]}"
end
```

### XSD → UML Lookups

#### Lookup XSD Type

```ruby
# Find UML classes mapped to an XSD type
result = workflow.lookup_xsd_to_uml("gml:CodeType", type: :type)

if result.multiple_matches?
  puts "Found #{result.match_count} classes:"
  result.matches.each do |match|
    puts "  - #{match[:uml_class]}"
  end
end
```

#### Lookup XSD Element

```ruby
# Find UML attributes mapped to an XSD element
result = workflow.lookup_xsd_to_uml("urf:name", type: :element)

result.matches.each do |match|
  puts "UML Class: #{match[:uml_class]}"
  puts "UML Attribute: #{match[:uml_attribute]}"
  puts "UML Type: #{match[:uml_type]}"
end
```

### Auto-Detection

```ruby
# Automatically detect lookup direction
result = workflow.auto_lookup("ModelRoot::i-UR::urf::UrbanPlanningArea")
# Detects UML class lookup (contains ::)

result = workflow.auto_lookup("gml:CodeType")
# Detects XSD type lookup (contains :)
```

### Fuzzy Matching

```ruby
# Enable fuzzy matching for partial names
result = workflow.auto_lookup("UrbanPlanning", fuzzy: true)

if result.found?
  result.matches.each do |match|
    quality = (match[:match_quality] * 100).round(1)
    puts "#{match[:uml_class]} (#{quality}% match)"
  end
end
```

### Output Formats

```ruby
# Text format (human-readable)
puts workflow.format_result(result, format: :text)

# JSON format
json = workflow.format_result(result, format: :json)
puts JSON.pretty_generate(JSON.parse(json))

# YAML format
yaml = workflow.format_result(result, format: :yaml)
puts yaml
```

### LookupResult API

```ruby
result = workflow.auto_lookup("SomeIdentifier")

# Check if matches were found
result.found?            # => true/false
result.single_match?     # => true if exactly 1 match
result.multiple_matches? # => true if > 1 match

# Access matches
result.first_match       # => Hash or nil
result.matches           # => Array of Hashes
result.match_count       # => Integer

# Check direction
result.uml_to_xsd?       # => true/false
result.xsd_to_uml?       # => true/false

# Convert to formats
result.to_h              # => Hash
result.to_json           # => String (JSON)
result.to_yaml           # => String (YAML)
```

## Command-Line Interface

### Basic Lookup Command

Auto-detects direction based on identifier format:

```bash
lutaml-klin lookup "ModelRoot::i-UR::urf::UrbanPlanningArea" \
  --mapping mapping.yaml
```

### UML to XSD Lookup

```bash
# Lookup UML class
lutaml-klin lookup-uml "ModelRoot::i-UR::urf::UrbanPlanningArea" \
  --mapping mapping.yaml

# Lookup UML attribute
lutaml-klin lookup-uml "ModelRoot::i-UR::urf::UrbanPlanningArea::areaType" \
  --mapping mapping.yaml
```

### XSD to UML Lookup

```bash
# Lookup XSD type
lutaml-klin lookup-xsd "gml:CodeType" \
  --mapping mapping.yaml

# Lookup XSD element
lutaml-klin lookup-xsd "urf:name" \
  --mapping mapping.yaml
```

### Advanced Options

```bash
# Enable fuzzy matching
lutaml-klin lookup "UrbanPlanning" \
  --mapping mapping.yaml \
  --fuzzy

# Specify output format
lutaml-klin lookup "gml:CodeType" \
  --mapping mapping.yaml \
  --format json

# Explicit direction and type
lutaml-klin lookup "UrbanPlanningArea" \
  --mapping mapping.yaml \
  --direction uml-to-xsd \
  --type class \
  --fuzzy
```

### Interactive Mode

```bash
lutaml-klin interactive-lookup --mapping mapping.yaml
```

Interactive mode provides a REPL-like interface:

```
=== Lutaml-Klin Interactive Lookup ===
Enter 'exit' or 'quit' to exit
Enter 'help' for usage instructions

lookup> ModelRoot::i-UR::urf::UrbanPlanningArea
=== Lookup Result ===
Query: ModelRoot::i-UR::urf::UrbanPlanningArea
Direction: uml_to_xsd
Matches: 1

--- Match 1 ---
UML Class: ModelRoot::i-UR::urf::UrbanPlanningArea
XSD Element: UrbanPlanningArea
XSD Type: urf:UrbanPlanningAreaType
...

lookup> gml:CodeType --fuzzy
...

lookup> exit
Goodbye!
```

## Match Result Structure

### UML Class Match

```ruby
{
  uml_class: "ModelRoot::i-UR::urf::UrbanPlanningArea",
  uml_name: "UrbanPlanningArea",
  uml_package: "ModelRoot::i-UR::urf",
  uml_stereotype: "FeatureType",
  xsd_element: "UrbanPlanningArea",
  xsd_type: "urf:UrbanPlanningAreaType",
  xsd_type_name: "UrbanPlanningAreaType",
  xsd_namespace: "http://www.opengis.net/plateau/urbanPlanning/2.0",
  resolution_status: "resolved",
  resolution_method: "shapechange"
}
```

### UML Attribute Match

```ruby
{
  uml_class: "ModelRoot::i-UR::urf::UrbanPlanningArea",
  uml_attribute: "areaType",
  uml_type: "Code",
  uml_multiplicity: "0..1",
  xsd_name: "areaType",
  xsd_type: "gml:CodeType",
  xsd_path: "/UrbanPlanningArea/areaType",
  xsd_namespace: "gml",
  is_element: true,
  min_occurs: "0",
  max_occurs: "1",
  resolution_status: "resolved"
}
```

## Performance

The lookup service uses bidirectional indexes for O(1) lookup performance:

- **UML Class Index**: `uml_qualified_name → ClassMapping`
- **UML Attribute Index**: `"class_qname::attr_name" → AttributeMapping`
- **XSD Type Index**: `xsd_type_qname → [ClassMapping]`
- **XSD Element Index**: `xsd_element_qname → [{class_qname, attribute}]`

This allows efficient lookups even for large mapping files with thousands of classes.

## Fuzzy Matching Algorithm

Fuzzy matching uses a quality scoring system:

- **1.0**: Exact match
- **0.9**: Starts with query
- **0.8**: Ends with query
- **0.7 × (1 - position/length)**: Contains query (earlier = higher score)

Results are automatically sorted by match quality (highest first).

## Error Handling

```ruby
begin
  workflow = Lutaml::Klin::Application::LookupWorkflow.new("mapping.yaml")
  result = workflow.auto_lookup("SomeClass")
rescue Lutaml::Klin::Error => e
  puts "Error: #{e.message}"
end
```

Common errors:

- **File not found**: Mapping file doesn't exist
- **Invalid YAML**: Mapping file has syntax errors
- **Malformed identifier**: Attribute lookup without proper format

## Best Practices

1. **Use qualified names**: Always use fully qualified UML names for accurate lookups
2. **Enable fuzzy matching cautiously**: Fuzzy matching can return many results
3. **Check match count**: Use `result.single_match?` before accessing `first_match`
4. **Handle no results gracefully**: Always check `result.found?` before accessing matches
5. **Use appropriate lookup type**: Specify `:class` or `:attribute` for better performance
6. **Cache workflow instance**: Reuse the workflow object for multiple lookups

## Integration Examples

### CI/CD Validation

```ruby
# Validate all UML classes have XSD mappings
uml_classes.each do |class_qname|
  result = workflow.lookup_uml_to_xsd(class_qname, type: :class)
  unless result.found?
    puts "WARNING: No XSD mapping for #{class_qname}"
  end
end
```

### Documentation Generation

```ruby
# Generate cross-reference documentation
result = workflow.lookup_uml_to_xsd(class_qname, type: :class)
if result.found?
  match = result.first_match
  puts "## #{match[:uml_name]}"
  puts "**XSD Type**: `#{match[:xsd_type]}`"
  puts "**Namespace**: #{match[:xsd_namespace]}"
end
```

### IDE Integration

```ruby
# Autocomplete for XSD types based on UML input
partial_input = "Urban"
result = workflow.auto_lookup(partial_input, fuzzy: true)
suggestions = result.matches.map { |m| m[:uml_class] }
```

## See Also

- [Mapping Generation](FINAL_IMPLEMENTATION_PLAN.md)
- [Validation Workflow](SPA_AND_VALIDATION_ARCHITECTURE.md)
- [CLI Commands](../README.adoc#cli-usage)