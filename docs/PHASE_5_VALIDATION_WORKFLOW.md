# Phase 5: Validation Workflow & Reporters

This document describes the validation workflow and reporting system for lutaml-klin LUR+LXR integration.

## Overview

Phase 5 implements a comprehensive validation system that analyzes schema mappings, calculates statistics, identifies unresolved items, and generates detailed reports in multiple formats.

## Architecture

The validation system follows a clean architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         ValidationWorkflow                            │  │
│  │  - Orchestrates validation                            │  │
│  │  - Coordinates report generation                      │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                           │
│  ┌──────────────────┐  ┌──────────────────────────────┐    │
│  │ ValidationService│  │  ValidationResult            │    │
│  │ - Pure logic     │  │  - Value object              │    │
│  │ - No I/O         │  │  - Immutable                 │    │
│  └──────────────────┘  └──────────────────────────────┘    │
│                                                             │
│  ┌──────────────────┐  ┌──────────────────────────────┐    │
│  │  JsonReporter    │  │  MarkdownReporter            │    │
│  │  - JSON format   │  │  - Markdown format           │    │
│  └──────────────────┘  └──────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. ValidationResult (Value Object)

**Location:** `lib/lutaml/klin/domain/validation_result.rb`

Immutable value object containing validation results:

```ruby
result = ValidationResult.new(
  summary: {
    total_packages: 3,
    total_classes: 174,
    resolved_classes: 170,
    resolution_rate: 97.7
  },
  unresolved_items: [...],
  packages: [...]
)

result.valid?           # => false
result.resolution_rate  # => 97.7
result.unresolved_count # => 4
```

**Key Methods:**
- `valid?` - Returns true if no unresolved items
- `resolution_rate` - Overall resolution percentage
- `total_packages`, `total_classes`, `total_attributes` - Statistics accessors
- `unresolved_count` - Number of unresolved items

### 2. ValidationService (Pure Domain Logic)

**Location:** `lib/lutaml/klin/domain/services/validation_service.rb`

Pure validation logic with no I/O operations:

```ruby
service = ValidationService.new
result = service.validate(schema_mapping)
```

**Responsibilities:**
- Analyze PackageMapping, ClassMapping, AttributeMapping
- Calculate resolution statistics
- Identify unresolved/partial items
- Generate actionable suggestions

**Analysis Flow:**
1. Iterate through all packages
2. For each package, analyze all classes
3. For each class, analyze all attributes
4. Collect unresolved items with context
5. Generate suggestions based on error patterns
6. Calculate comprehensive statistics

### 3. JsonReporter (Report Generator)

**Location:** `lib/lutaml/klin/domain/reporters/json_reporter.rb`

Generates structured JSON reports:

```ruby
reporter = JsonReporter.new
path = reporter.generate(validation_result, "report.json")
```

**Output Structure:**
```json
{
  "version": "1.0",
  "generated_at": "2025-10-25T16:00:00Z",
  "validation_status": "invalid",
  "summary": {
    "total_packages": 3,
    "total_classes": 174,
    "resolved_classes": 170,
    "resolution_rate": 97.7
  },
  "unresolved_items": [...],
  "packages": [...]
}
```

### 4. MarkdownReporter (Report Generator)

**Location:** `lib/lutaml/klin/domain/reporters/markdown_reporter.rb`

Generates human-readable Markdown reports:

```ruby
reporter = MarkdownReporter.new
path = reporter.generate(validation_result, "report.md")
```

**Output Structure:**
```markdown
# UML-to-XSD Validation Report

**Status:** ⚠️ Invalid
**Generated:** 2025-10-25T16:00:00Z

## Summary

| Metric | Value | Status |
|--------|-------|--------|
| Resolution Rate | 97.7% | ⚠️ Near Complete |
| Classes | 170/174 | ⚠️ 4 unresolved |

## Unresolved Items
...

## Package Details
...
```

### 5. ValidationWorkflow (Application Orchestrator)

**Location:** `lib/lutaml/klin/application/validation_workflow.rb`

High-level workflow orchestration:

```ruby
workflow = ValidationWorkflow.new

# Validate only
result = workflow.validate_mapping(schema_mapping)

# Validate and generate reports
output = workflow.validate_and_report(
  schema_mapping,
  "output/validation"
)
# Creates: output/validation.json, output/validation.md

result = output[:result]
paths = output[:report_paths]
```

## Usage Examples

### Basic Validation

```ruby
require "lutaml/klin/application/validation_workflow"

# Load your schema mapping
schema_mapping = YAML.load_file("mapping.yml")

# Create workflow
workflow = Lutaml::Klin::Application::ValidationWorkflow.new

# Validate
result = workflow.validate_mapping(schema_mapping)

puts "Resolution Rate: #{result.resolution_rate}%"
puts "Valid: #{result.valid?}"
puts "Unresolved: #{result.unresolved_count}"
```

### Generate Reports

```ruby
# Validate and generate reports
output = workflow.validate_and_report(
  schema_mapping,
  "reports/validation_2025-10-25"
)

result = output[:result]
report_paths = output[:report_paths]

puts "Reports generated:"
report_paths.each { |path| puts "  - #{path}" }
```

### Analyze Results

```ruby
result = workflow.validate_mapping(schema_mapping)

# Check overall status
if result.valid?
  puts "✅ All mappings resolved!"
else
  puts "⚠️ #{result.unresolved_count} unresolved items"

  # Examine unresolved items
  result.unresolved_items.each do |item|
    puts "\n#{item[:package]}::#{item[:class]}::#{item[:attribute]}"
    puts "  Type: #{item[:uml_type]}"
    puts "  Error: #{item[:error]}"
    puts "  Suggestions:"
    item[:suggestions].each { |s| puts "    - #{s}" }
  end
end
```

### Custom Validation Service

```ruby
class CustomValidationService < Lutaml::Klin::Domain::Services::ValidationService
  def validate(schema_mapping)
    result = super
    # Add custom analysis
    result
  end
end

workflow = ValidationWorkflow.new(
  validation_service: CustomValidationService.new
)
```

## Suggestion System

The validation service provides actionable suggestions based on error patterns:

### Type Not Found
```
Error: "Type not found in XSD repository"
Suggestions:
- Verify that type 'CustomType' exists in the XSD repository
- Check namespace mappings for package 'ModelRoot::i-UR::urf'
```

### Namespace Issues
```
Error: "Invalid namespace mapping"
Suggestions:
- Add namespace mapping in ShapeChange configuration
- Verify XSD namespace URI is correct
```

### Custom Classes
```
Error: "Unknown error"
Type: "CustomClass" (capitalized)
Suggestions:
- Type 'CustomClass' appears to be a custom class - ensure it's defined in the UML model
- Consider adding a type override mapping
```

### Generic
```
Suggestions:
- Review the resolution error message for details
- Check ShapeChange configuration for type mappings
- Verify UML model completeness
```

## Report Formats

### JSON Report

**Use Cases:**
- Machine processing
- Integration with other tools
- Automated analysis
- CI/CD pipelines

**Features:**
- Structured, hierarchical data
- Complete validation details
- Easy to parse programmatically
- Pretty-printed for readability

### Markdown Report

**Use Cases:**
- Human review
- Documentation
- Code reviews
- Manual inspection

**Features:**
- Tables with statistics
- Status indicators (✅, ⚠️, ❌)
- Hierarchical sections
- Actionable suggestions
- Package-level breakdowns

## Testing

Comprehensive test suites are provided:

```bash
# Run all validation tests
bundle exec rspec spec/lutaml/klin/domain/validation_result_spec.rb
bundle exec rspec spec/lutaml/klin/domain/services/validation_service_spec.rb
bundle exec rspec spec/lutaml/klin/domain/reporters/json_reporter_spec.rb
bundle exec rspec spec/lutaml/klin/domain/reporters/markdown_reporter_spec.rb
bundle exec rspec spec/lutaml/klin/application/validation_workflow_spec.rb
```

## Integration with Mapping Workflow

The validation workflow integrates seamlessly with the mapping workflow:

```ruby
# Phase 4: Generate mappings
mapping_workflow = Lutaml::Klin::Application::MappingWorkflow.new
schema_mapping = mapping_workflow.generate_mapping(
  uml_repo,
  schema_repo,
  config
)

# Phase 5: Validate and report
validation_workflow = Lutaml::Klin::Application::ValidationWorkflow.new
output = validation_workflow.validate_and_report(
  schema_mapping,
  "output/validation"
)

result = output[:result]
if result.valid?
  puts "✅ Mapping is complete and valid"
else
  puts "⚠️ Mapping has #{result.unresolved_count} unresolved items"
  puts "See reports: #{output[:report_paths].join(', ')}"
end
```

## Design Principles

### Separation of Concerns
- **ValidationService**: Pure domain logic, no I/O
- **Reporters**: Formatting only, no business logic
- **ValidationWorkflow**: Orchestration, coordinates components

### Immutability
- **ValidationResult**: Frozen value object
- All attributes are immutable
- Thread-safe by design

### Extensibility
- Custom validation services can be injected
- New report formats can be added easily
- Suggestion system is pattern-based

### Error Handling
- Reporters handle I/O errors gracefully
- Failed report generation doesn't stop workflow
- Warnings are logged, execution continues

## Future Enhancements

Potential improvements for future phases:

1. **HTML Reporter** - Rich, interactive HTML reports
2. **CSV Reporter** - Tabular data export
3. **Diff Reports** - Compare validation results over time
4. **Severity Levels** - Categorize unresolved items by severity
5. **Auto-fix Suggestions** - Propose specific code changes
6. **Integration Tests** - End-to-end validation scenarios
7. **Performance Metrics** - Track validation performance
8. **Custom Validators** - Plugin system for custom validation rules

## Related Documentation

- [Phase 1: Repository Adapters](PHASE_1_REPOSITORY_ADAPTERS.md)
- [Phase 2: Resolution Engine](PHASE_2_RESOLUTION_ENGINE.md)
- [Phase 3: Enhanced Mapping Models](PHASE_3_ENHANCED_MAPPING_MODELS.md)
- [Phase 4: Mapping Workflow](PHASE_4_MAPPING_WORKFLOW.md)
- [Implementation Plan](FINAL_IMPLEMENTATION_PLAN.md)

## Conclusion

Phase 5 provides a comprehensive validation and reporting system that:
- Analyzes mapping completeness with detailed statistics
- Identifies unresolved items with actionable suggestions
- Generates reports in multiple formats (JSON, Markdown)
- Integrates seamlessly with the mapping workflow
- Follows clean architecture principles
- Is fully tested and documented

This completes the LUR+LXR integration implementation, providing a complete end-to-end solution for UML-to-XSD schema mapping with full validation and reporting capabilities.