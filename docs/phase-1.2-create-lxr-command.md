# Phase 1.2: Create-lxr CLI Command

## Overview

Phase 1.2 implements a CLI command for creating LXR (LutaML XSD Repository) packages from either ShapeChange configurations or manual XSD file collections. This phase builds on Phase 1.1's [`LxrExtractor`](../lib/lutaml/klin/shapechange/lxr_extractor.rb) to provide a complete workflow for LXR package creation.

## Architecture

The implementation follows clean architecture principles with strict separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    CLI Interface (Thor)                      │
│                  create-lxr command                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              CreateLxrCommand (Orchestrator)                 │
│  Responsibility: Coordinate workflow, no business logic     │
└──┬────────────────┬─────────────────┬──────────────────────┘
   │                │                 │
   ▼                ▼                 ▼
┌──────────┐  ┌──────────┐    ┌─────────────┐
│  Input   │  │  Config  │    │  Package    │
│ Strategy │→ │ Builder  │ →  │  Builder    │
└──────────┘  └──────────┘    └─────────────┘
     │
     ├── ShapeChangeInputStrategy
     └── ManualInputStrategy
```

### Component Responsibilities

1. **[`InputStrategy`](../lib/lutaml/klin/lxr/input_strategy.rb)** (Strategy Pattern)
   - Extract schema information from different sources
   - Two concrete strategies:
     - `ShapeChangeInputStrategy`: Uses Phase 1.1 LxrExtractor
     - `ManualInputStrategy`: Direct XSD files + namespace config

2. **[`ConfigBuilder`](../lib/lutaml/klin/lxr/config_builder.rb)** (Builder Pattern)
   - Transform schema info into lutaml-xsd package configuration
   - Handle serialization format conversion
   - External configuration via YAML

3. **[`PackageBuilder`](../lib/lutaml/klin/lxr/package_builder.rb)** (Adapter Pattern)
   - Interface to lutaml-xsd CLI
   - Execute package build commands
   - Validate created packages

4. **[`CreateLxrCommand`](../lib/lutaml/klin/commands/create_lxr_command.rb)** (Command Pattern)
   - Orchestrate the complete workflow
   - Dependency injection of all components
   - Error handling and reporting

## File Structure

```
lib/lutaml/klin/
├── lxr/
│   ├── errors.rb                    # Custom error classes
│   ├── input_strategy.rb            # Strategy pattern for inputs
│   ├── config_builder.rb            # Build lutaml-xsd configs
│   └── package_builder.rb           # Interface to lutaml-xsd
├── commands/
│   └── create_lxr_command.rb        # Main command orchestrator
└── cli.rb                            # Updated with create-lxr

spec/lutaml/klin/
├── lxr/
│   ├── input_strategy_spec.rb       # Strategy tests (321 lines)
│   ├── config_builder_spec.rb       # Builder tests (286 lines)
│   └── package_builder_spec.rb      # Package builder tests (225 lines)
├── commands/
│   └── create_lxr_command_spec.rb   # Command tests (302 lines)
└── integration/
    └── create_lxr_workflow_spec.rb  # Integration tests (285 lines)

examples/
└── lxr_namespaces.yaml              # Example namespace config
```

## Usage

### From ShapeChange Configuration

```bash
# Basic usage
lutaml-klin create-lxr output.lxr --shapechange config.xml

# With package metadata
lutaml-klin create-lxr plateau_schemas.lxr \
  --shapechange reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml \
  --name "PLATEAU v5.0 Schemas" \
  --version "5.0.0" \
  --description "PLATEAU v5.0 XSD schema repository"

# With validation
lutaml-klin create-lxr output.lxr \
  --shapechange config.xml \
  --validate \
  --verbose
```

### From Manual XSD Collection

```bash
# Basic usage with namespace config
lutaml-klin create-lxr output.lxr \
  --xsd-dir final_schemas/ \
  --namespaces examples/lxr_namespaces.yaml

# Full options
lutaml-klin create-lxr plateau_schemas.lxr \
  --xsd-dir final_schemas/ \
  --namespaces examples/lxr_namespaces.yaml \
  --name "PLATEAU Schemas" \
  --version "5.0.0" \
  --xsd-mode include_all \
  --resolution-mode resolved \
  --format marshal \
  --validate \
  --verbose
```

### CLI Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--shapechange PATH` | String | - | Path to ShapeChange configuration |
| `--xsd-dir PATH` | String | - | Directory containing XSD files |
| `--namespaces PATH` | String | - | YAML file with namespace mappings |
| `--xsd-mode MODE` | String | `include_all` | XSD bundling: `include_all`, `allow_external` |
| `--resolution-mode MODE` | String | `resolved` | Resolution: `resolved`, `bare` |
| `--format FORMAT` | String | `marshal` | Serialization: `marshal`, `json`, `yaml`, `parse` |
| `--name NAME` | String | `lxr_package` | Package name |
| `--version VERSION` | String | `1.0.0` | Package version |
| `--description DESC` | String | - | Package description |
| `--validate` | Boolean | `false` | Validate package after creation |
| `--verbose` | Boolean | `false` | Enable verbose output |

## Design Patterns

### 1. Strategy Pattern (Input Sources)

**Problem**: Need to support multiple input sources (ShapeChange config OR manual XSD files)

**Solution**: Define `InputStrategy` base class with two concrete implementations

```ruby
# Base strategy
class InputStrategy
  def extract_schema_info
    raise NotImplementedError
  end
end

# ShapeChange strategy
class ShapeChangeInputStrategy < InputStrategy
  def extract_schema_info
    extractor.extract_schema_info(config_path)
  end
end

# Manual strategy
class ManualInputStrategy < InputStrategy
  def extract_schema_info
    {
      xsd_files: collect_xsd_files,
      namespace_mappings: load_namespace_mappings,
      schema_location_mappings: []
    }
  end
end
```

**Benefits**:
- Open/Closed Principle: Easy to add new input sources
- Single Responsibility: Each strategy handles one source type
- Mutually Exclusive, Collectively Exhaustive (MECE)

### 2. Builder Pattern (Configuration)

**Problem**: Complex configuration with many optional parameters

**Solution**: `ConfigBuilder` encapsulates configuration construction

```ruby
config = ConfigBuilder.new(
  xsd_mode: "include_all",
  resolution_mode: "resolved",
  serialization_format: "marshal"
).build(schema_info, metadata)
```

**Benefits**:
- Separation of Concerns: Configuration building isolated
- Validation: Options validated at construction time
- Extensibility: Easy to add new configuration options

### 3. Command Pattern (Orchestration)

**Problem**: Need to coordinate multiple steps with error handling

**Solution**: `CreateLxrCommand` orchestrates the workflow

```ruby
class CreateLxrCommand
  def run
    schema_info = extract_schema_info
    config = build_configuration(schema_info)
    result = create_package(config)
    report_results(result)
  end
end
```

**Benefits**:
- Single Responsibility: Only orchestration logic
- Dependency Injection: All components injected
- Testability: Easy to mock components

### 4. Adapter Pattern (External Tool)

**Problem**: Need to interface with external lutaml-xsd CLI

**Solution**: `PackageBuilder` adapts to lutaml-xsd command line interface

```ruby
class PackageBuilder
  def build(config_hash, output_path, options)
    # Create temporary config file
    # Execute lutaml-xsd command
    # Validate results
  end
end
```

**Benefits**:
- Isolation: External tool changes don't affect core logic
- Testability: Can mock external command execution
- Error Handling: Centralized command execution logic

## Error Handling

Custom error hierarchy for clear error messages:

```ruby
class LxrCreationError < StandardError; end
class InvalidInputError < LxrCreationError; end
class PackageBuildError < LxrCreationError; end
class ValidationError < LxrCreationError; end
class ConfigurationError < LxrCreationError; end
```

All errors caught at command level with appropriate exit codes:
- Exit 0: Success
- Exit 1: Any error

## Configuration Files

### Namespace Configuration Example

[`examples/lxr_namespaces.yaml`](../examples/lxr_namespaces.yaml):

```yaml
namespace_mappings:
  # PLATEAU i-UR namespaces
  - prefix: "urf"
    uri: "https://www.geospatial.jp/iur/urf/3.2"

  - prefix: "uro"
    uri: "https://www.geospatial.jp/iur/uro/3.2"

  # OGC GML namespaces
  - prefix: "gml"
    uri: "http://www.opengis.net/gml/3.2"
```

### Generated Package Configuration

The `ConfigBuilder` generates lutaml-xsd compatible YAML:

```yaml
package:
  name: "PLATEAU Schemas"
  version: "5.0.0"
  description: "PLATEAU v5.0 XSD schemas"

schemas:
  files:
    - schema1.xsd
    - schema2.xsd

options:
  xsd_mode: include_all
  resolution_mode: resolved
  serialization_format: marshal

namespaces:
  - prefix: urf
    uri: https://www.geospatial.jp/iur/urf/3.2
  - prefix: gml
    uri: http://www.opengis.net/gml/3.2
```

## Testing

### Test Coverage

All components have comprehensive test coverage:

1. **Unit Tests** (1,134 lines total)
   - [`input_strategy_spec.rb`](../spec/lutaml/klin/lxr/input_strategy_spec.rb): 321 lines
   - [`config_builder_spec.rb`](../spec/lutaml/klin/lxr/config_builder_spec.rb): 286 lines
   - [`package_builder_spec.rb`](../spec/lutaml/klin/lxr/package_builder_spec.rb): 225 lines
   - [`create_lxr_command_spec.rb`](../spec/lutaml/klin/commands/create_lxr_command_spec.rb): 302 lines

2. **Integration Tests**
   - [`create_lxr_workflow_spec.rb`](../spec/integration/create_lxr_workflow_spec.rb): 285 lines
   - Tests complete end-to-end workflow
   - Tests both input strategies
   - Tests error handling

### Running Tests

```bash
# Run all LXR-related tests
bundle exec rspec spec/lutaml/klin/lxr/

# Run command tests
bundle exec rspec spec/lutaml/klin/commands/create_lxr_command_spec.rb

# Run integration tests
bundle exec rspec spec/integration/create_lxr_workflow_spec.rb

# Run with coverage
bundle exec rspec --format documentation
```

## Dependencies

### External Dependencies

- **lutaml-xsd**: Required for package building
  ```bash
  gem install lutaml-xsd
  ```

### Internal Dependencies

- **Phase 1.1**: [`LxrExtractor`](../lib/lutaml/klin/shapechange/lxr_extractor.rb)
  - Used by `ShapeChangeInputStrategy`
  - Extracts schema info from ShapeChange configs

## Integration with Existing Code

### CLI Integration

The `create-lxr` command integrates seamlessly with existing commands:

```ruby
# lib/lutaml/klin/cli.rb
require_relative "commands/create_lxr_command"

class Cli < Thor
  desc "create-lxr OUTPUT_PATH", "Create LXR package..."
  option :shapechange, type: :string
  option :xsd_dir, type: :string
  # ... more options
  def create_lxr(output_path)
    Commands::CreateLxrCommand.new(options.merge(output: output_path)).run
  end
end
```

### LxrExtractor Integration

`ShapeChangeInputStrategy` uses Phase 1.1's `LxrExtractor`:

```ruby
class ShapeChangeInputStrategy < InputStrategy
  def initialize(config_path:, extractor: nil)
    @extractor = extractor || Shapechange::LxrExtractor.new
  end

  def extract_schema_info
    extractor.extract_schema_info(config_path)
  end
end
```

## Architectural Principles Applied

### 1. MECE (Mutually Exclusive, Collectively Exhaustive)

- Input strategies are mutually exclusive (ShapeChange OR Manual)
- Collectively exhaustive (covers all input scenarios)
- Error types are mutually exclusive
- Configuration options cover all scenarios

### 2. Single Responsibility Principle

Each class has one clear responsibility:
- `InputStrategy`: Extract schema information
- `ConfigBuilder`: Build configuration
- `PackageBuilder`: Execute package creation
- `CreateLxrCommand`: Orchestrate workflow

### 3. Open/Closed Principle

- Easy to add new `InputStrategy` implementations
- Easy to add new configuration options
- Easy to add new validation rules
- Core classes don't need modification for extensions

### 4. Dependency Injection

All components use dependency injection:

```ruby
def initialize(options = {})
  @input_strategy = create_input_strategy
  @config_builder = create_config_builder
  @package_builder = create_package_builder
end
```

### 5. External Configuration

No hardcoded values:
- Namespace mappings in YAML files
- Configuration options as parameters
- Package metadata configurable
- All paths configurable

## Future Enhancements

### Potential Additions

1. **Additional Input Strategies**
   - `XmiInputStrategy`: Extract from UML XMI files
   - `DatabaseInputStrategy`: Load from schema database
   - `GitInputStrategy`: Clone and process from Git repos

2. **Validation Enhancements**
   - Schema validation using XSD
   - Namespace consistency checks
   - Circular dependency detection

3. **Package Management**
   - List installed packages
   - Update existing packages
   - Merge multiple packages
   - Package dependency resolution

4. **CI/CD Integration**
   - GitHub Actions workflow
   - Automated package publishing
   - Version management

## Success Criteria (All Met ✅)

- ✅ Clean OO architecture with separation of concerns
- ✅ MECE design for input strategies
- ✅ External configuration support via YAML
- ✅ Comprehensive test coverage (1,419 lines of tests)
- ✅ Works with both ShapeChange configs and manual input
- ✅ Proper error handling with clear messages
- ✅ Follows open/close principle for extensibility
- ✅ CLI integrated smoothly with existing commands
- ✅ Documentation and examples provided
- ✅ No hardcoded values or magic strings

## Related Documentation

- [Phase 1.1: LXR Extractor](phase-1.1-lxr-extractor.md)
- [LutaML-XSD Integration](../LUTAML-XSD-INTEGRATION-MAPPING-PLAN.adoc)
- [Requirements](req-000.md)