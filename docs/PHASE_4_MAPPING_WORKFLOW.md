# Phase 4: Mapping Workflow - UML-to-XSD Mapping Generation

## Summary

Phase 4 successfully implements the application layer workflow that orchestrates UML-to-XSD mapping generation. This completes the lutaml-klin LUR+LXR integration by providing a high-level API for generating mapping files with full resolution tracking.

## Components Implemented

### 1. MappingService (`lib/lutaml/klin/domain/services/mapping_service.rb`)

**Pure Domain Logic - No I/O**

The MappingService contains all business logic for mapping UML elements to XSD elements:

- `map_class_to_xsd(uml_class, xsd_namespace, context)` - Maps UML classes to XSD types
- `map_attribute_to_xsd(uml_attribute, context)` - Maps UML attributes to XSD elements
- `derive_xsd_element_name(uml_attribute)` - Derives XSD element names from UML attributes
- `map_multiplicity(multiplicity)` - Converts UML multiplicity to XSD min/maxOccurs

**Key Features:**

- Uses [`ResolutionEngine`](lib/lutaml/klin/domain/resolution_engine.rb) for ALL type resolutions
- Extracts documentation, stereotypes, and metadata
- Calculates resolution confidence scores
- Returns structured hashes for building mapping models
- NO file I/O - pure business logic

**Multiplicity Mapping:**

```ruby
service.map_multiplicity("1")      # => {min: "1", max: "1"}
service.map_multiplicity("0..1")   # => {min: "0", max: "1"}
service.map_multiplicity("1..*")   # => {min: "1", max: "unbounded"}
service.map_multiplicity("0..*")   # => {min: "0", max: "unbounded"}
service.map_multiplicity("2..5")   # => {min: "2", max: "5"}
```

### 2. MappingWorkflow (`lib/lutaml/klin/application/mapping_workflow.rb`)

**Application Layer Orchestration**

The MappingWorkflow coordinates the entire mapping generation process:

- `generate_mapping_for_package(package_path, recursive:)` - Maps a single package
- `generate_mappings_for_packages(package_paths, recursive:)` - Maps multiple packages
- `save_mapping(mapping, output_path)` - Saves mapping to YAML file

**Workflow Steps:**

1. Loads UML packages from LUR repository
2. Determines XSD namespace from ShapeChange config
3. Gets all classes in package
4. For each class:
   - Resolves class type using Resolution Engine
   - Maps all attributes using MappingService
   - Builds enhanced [`ClassMapping`](lib/lutaml/klin/models/mapping/class_mapping.rb) with resolution tracking
5. Builds [`PackageMapping`](lib/lutaml/klin/models/mapping/package_mapping.rb) with statistics
6. Optionally builds [`SchemaMapping`](lib/lutaml/klin/models/mapping/schema_mapping.rb) for multiple packages
7. Serializes to YAML with full traceability

**Architecture:**

- **Pure orchestration** - no business logic
- **Delegates** to MappingService for all business decisions
- **Handles** all I/O operations (file reading/writing)
- **Manages** repository adapters and configuration
- **Builds** resolution engine with proper strategy chain

## Integration Points

### With Phase 1 (Repository Adapters)

- Uses [`UmlRepositoryAdapter`](lib/lutaml/klin/repositories/uml_repository_adapter.rb) to load UML packages
- Uses [`SchemaRepositoryAdapter`](lib/lutaml/klin/repositories/schema_repository_adapter.rb) for XSD type lookups
- Passes repositories to ResolutionContext for strategy access

### With Phase 2 (Resolution Engine)

- Builds [`ResolutionEngine`](lib/lutaml/klin/domain/resolution_engine.rb) with strategy chain:
  1. [`TypeOverrideStrategy`](lib/lutaml/klin/domain/strategies/type_override_strategy.rb) (if overrides provided)
  2. [`ShapeChangeMappingStrategy`](lib/lutaml/klin/domain/strategies/shapechange_strategy.rb)
  3. [`SchemaRepositoryStrategy`](lib/lutaml/klin/domain/strategies/schema_repository_strategy.rb)
- Creates [`ResolutionContext`](lib/lutaml/klin/domain/resolution_context.rb) with all dependencies
- Passes engine to MappingService

### With Phase 3 (Enhanced Mapping Models)

- Populates all enhanced attributes in mapping models:
  - `uml_documentation`, `uml_stereotype`, `uml_multiplicity`
  - `xsd_documentation`, `xsd_min_occurs`, `xsd_max_occurs`
  - `resolution_status`, `resolution_method`, `resolution_confidence`
  - `resolution_error` (for failures)
- Calculates and stores resolution statistics
- Enables full traceability in YAML output

## Usage Example

```ruby
require 'lutaml/klin/application/mapping_workflow'
require 'lutaml/klin/repositories/uml_repository_adapter'
require 'lutaml/klin/repositories/schema_repository_adapter'
require 'lutaml/klin/shapechange/config_parser'

# Load repositories
uml_repo = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  "path/to/model.lur"
)
xsd_repo = Lutaml::Klin::Repositories::SchemaRepositoryAdapter.new(
  "path/to/schemas.lxr"
)

# Load ShapeChange configuration
config = Lutaml::Klin::ShapeChange::ConfigParser.parse_file(
  "path/to/config.xml"
)

# Optional: Define type overrides for corrections
type_overrides = {
  "CharacterString" => "xs:string",
  "Real" => "xs:double"
}

# Create workflow
workflow = Lutaml::Klin::Application::MappingWorkflow.new(
  uml_repository: uml_repo,
  xsd_repository: xsd_repo,
  shapechange_config: config,
  type_overrides: type_overrides
)

# Generate mapping for single package
package_mapping = workflow.generate_mapping_for_package(
  "ModelRoot::Core::Building",
  recursive: false
)

# Save to YAML
workflow.save_mapping(package_mapping, "building_mapping.yaml")

# Or generate for multiple packages
schema_mapping = workflow.generate_mappings_for_packages([
  "ModelRoot::Core::Building",
  "ModelRoot::Core::Road",
  "ModelRoot::Core::Bridge"
], recursive: true)

workflow.save_mapping(schema_mapping, "complete_mapping.yaml")

# Query statistics
stats = schema_mapping.calculate_statistics
puts "Total classes: #{stats['total_classes']}"
puts "Resolved: #{stats['resolved_classes']}"
puts "Resolution rate: #{schema_mapping.resolution_rate}%"
```

## Output Example

```yaml
version: "1.0"
generated_at: "2024-01-15T10:30:00Z"
source_lur: "path/to/model.lur"
source_lxr: "path/to/schemas.lxr"
source_config: "path/to/config.xml"

package_mappings:
  - uml_name: Building
    uml_package_name: ModelRoot::Core::Building
    xsd_namespace: http://example.org/core
    xsd_namespace_prefix: core
    created_at: "2024-01-15T10:30:00Z"

    class_mappings:
      - uml_name: Building
        uml_qualified_name: ModelRoot::Core::Building::Building
        uml_stereotype: featureType
        uml_documentation: "Represents a building feature"
        xsd_namespace: http://example.org/core
        xsd_element_name: Building
        xsd_type_name: BuildingType
        xsd_documentation: "Building element type"
        resolution_status: resolved
        resolution_method: ShapeChangeMappingStrategy
        resolution_confidence: 0.9

        attribute_mappings:
          - uml_name: height
            uml_type: Real
            uml_documentation: "Building height in meters"
            uml_multiplicity: "0..1"
            xsd_name: height
            xsd_type: xs:double
            xsd_documentation: "Height element"
            xsd_min_occurs: "0"
            xsd_max_occurs: "1"
            resolution_status: resolved
            resolution_method: SchemaRepositoryStrategy
```

## Enhanced Features

### Resolution Tracking

Every mapping element tracks:
- **Resolution status**: `resolved`, `partial`, or `unresolved`
- **Resolution method**: Which strategy succeeded
- **Resolution confidence**: 0.0-1.0 score
- **Resolution error**: Detailed error if failed

### Hierarchical Statistics

- **Attribute level**: Individual resolution status
- **Class level**: Aggregated attribute statistics
- **Package level**: Aggregated class and attribute statistics
- **Schema level**: Aggregated across all packages

### Namespace Management

- Auto-detects XSD namespaces from ShapeChange config
- Derives namespace prefixes from URIs
- Collects unique namespaces across all packages

### Error Handling

- Comprehensive error messages with context
- Graceful degradation (partial resolutions)
- Detailed metadata for debugging

## Files Created

1. [`lib/lutaml/klin/domain/services/mapping_service.rb`](lib/lutaml/klin/domain/services/mapping_service.rb) - Pure domain logic
2. [`lib/lutaml/klin/application/mapping_workflow.rb`](lib/lutaml/klin/application/mapping_workflow.rb) - Application orchestration
3. [`spec/lutaml/klin/domain/services/mapping_service_spec.rb`](spec/lutaml/klin/domain/services/mapping_service_spec.rb) - Service tests
4. [`spec/lutaml/klin/application/mapping_workflow_spec.rb`](spec/lutaml/klin/application/mapping_workflow_spec.rb) - Workflow tests

## Files Modified

1. [`lib/lutaml/klin.rb`](lib/lutaml/klin.rb) - Added require for MappingService
2. [`lib/lutaml/klin/domain/resolution_result.rb`](lib/lutaml/klin/domain/resolution_result.rb) - Added `xsd_element` and `partial?` support

## Architecture Principles

### Separation of Concerns

- **Domain Services**: Pure business logic, no I/O
- **Application Layer**: Orchestration and I/O handling
- **Models**: Data structures with behavior
- **Strategies**: Pluggable resolution methods

### Dependency Injection

- All dependencies injected via constructor
- No global state or singletons
- Easy testing and configuration

### Immutability

- Value objects are immutable (ResolutionResult, ResolutionContext)
- Models are mutable for construction convenience
- Frozen after construction where appropriate

### Single Responsibility

- Each class has one clear purpose
- Methods are focused and composable
- Easy to understand and maintain

## Next Steps

Future enhancements could include:

1. **Interactive CLI** - User-friendly command-line interface
2. **Report Generator** - Human-readable HTML/PDF reports
3. **Validation Engine** - Validate mapping completeness
4. **Mapping Merger** - Combine multiple mapping sources
5. **Diff Tool** - Compare mapping versions
6. **Quality Metrics** - Analyze mapping quality scores

## Conclusion

Phase 4 successfully implements the mapping workflow layer, completing the lutaml-klin LUR+LXR integration. The implementation provides:

- ✅ Clean separation between domain logic and I/O
- ✅ Full integration with Phases 1-3
- ✅ Comprehensive resolution tracking
- ✅ Rich YAML output with statistics
- ✅ Extensible architecture
- ✅ Well-documented API

The mapping workflow enables automatic generation of UML-to-XSD mappings with full traceability, confidence scores, and error reporting - providing a solid foundation for GML application schema generation.