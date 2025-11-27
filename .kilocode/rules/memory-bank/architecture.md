# System Architecture

## Overview

LutaML Klin follows a clean 4-layer architecture with strict separation of concerns:

1. **Input Layer**: Pre-built packages (LUR/LXR)
2. **Application Layer**: Workflow orchestration
3. **Domain Layer**: Business logic and resolution
4. **Output Layer**: Mappings, reports, SPA

## Architecture Diagram

```
┌────────────────────────────────────────────────────────────┐
│  Input: Pre-built Packages (Built Once, Used Many Times)   │
│                                                             │
│  LUR Package (.lur)     LXR Package (.lxr)                 │
│  UML Model from XMI     XSD Schemas                        │
│  Built by: lutaml       Built by: lutaml-xsd               │
│  Load time: <100ms      Load time: <100ms                  │
└────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│  lutaml-klin: Pure Orchestration (No Parsing!)             │
│                                                             │
│  1. Load LUR → UmlRepository API                           │
│  2. Load LXR → SchemaRepository API                        │
│  3. Load ShapeChange Config                                │
│  4. Execute Resolution (Strategy Pattern)                  │
│  5. Generate Outputs (YAML, Reports, SPA)                  │
└────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│  Output: Three Formats                                      │
│                                                             │
│  ├─ YAML Mappings (per package)                            │
│  ├─ Validation Reports (JSON/Markdown)                     │
│  └─ SPA Website (Interactive HTML/JS)                      │
└────────────────────────────────────────────────────────────┘
```

## Layer 1: Input (Repository Adapters)

### UmlRepositoryAdapter
**Location**: `lib/lutaml/klin/repositories/uml_repository_adapter.rb`

Wraps the lutaml gem's UmlRepository API:
- `find_package(path)` - Find package by UML path
- `find_class(qualified_name)` - Find class by qualified name
- `classes_in_package(path, recursive:)` - Get classes in package
- `enums_in_package(path, recursive:)` - Get enums in package
- `all_packages()` - List all packages

### SchemaRepositoryAdapter
**Location**: `lib/lutaml/klin/repositories/schema_repository_adapter.rb`

Wraps the lutaml-xsd gem's SchemaRepository API:
- `find_type(name, namespace:)` - Find XSD type
- `find_element(name, namespace:)` - Find XSD element
- `all_namespaces()` - List all namespaces
- `types_in_namespace(namespace)` - Get types by namespace

### ShapeChange ConfigParser
**Location**: `lib/lutaml/klin/shapechange/config_parser.rb`

Parses ShapeChange XML configurations:
- Extracts encoding rules
- Parses XSD map entries (type mappings)
- Reads package info and namespaces
- Resolves XInclude references

## Layer 2: Application (Workflows)

### ProcessingWorkflow
**Location**: `lib/lutaml/klin/application/processing_workflow.rb`

Main orchestrator for complete workflows:
- Loads repositories (LUR + LXR)
- Filters packages using glob patterns
- Coordinates mapping, validation, and SPA generation
- Returns comprehensive ProcessingResult

Key method: `execute(lur_path:, lxr_path:, config_path:, ...)`

### MappingWorkflow
**Location**: `lib/lutaml/klin/application/mapping_workflow.rb`

Orchestrates UML-to-XSD mapping generation:
- `generate_mapping_for_package(package_path)` - Map single package
- `generate_mappings_for_packages(paths)` - Map multiple packages
- `save_mapping(mapping, output_path)` - Save to YAML

Delegates mapping logic to MappingService in domain layer.

### ValidationWorkflow
**Location**: `lib/lutaml/klin/application/validation_workflow.rb`

Generates validation reports:
- Analyzes resolution statistics
- Identifies unresolved types
- Produces JSON and Markdown reports

### SpaWorkflow
**Location**: `lib/lutaml/klin/application/spa_workflow.rb`

Generates interactive SPA website:
- Renders Liquid templates
- Creates search indexes
- Supports embedded or linked data modes

### LookupWorkflow
**Location**: `lib/lutaml/klin/application/lookup_workflow.rb`

Bidirectional lookup queries:
- `lookup_uml_to_xsd(identifier)` - Find XSD for UML
- `lookup_xsd_to_uml(identifier)` - Find UML for XSD
- `auto_lookup(identifier)` - Auto-detect direction

## Layer 3: Domain (Business Logic)

### ResolutionEngine
**Location**: `lib/lutaml/klin/domain/resolution_engine.rb`

Coordinates multiple resolution strategies:
- Strategy pattern implementation
- Tries strategies in order until resolution succeeds
- Returns ResolutionResult with full metadata

### Resolution Strategies

#### 1. TypeOverrideStrategy
**Location**: `lib/lutaml/klin/domain/strategies/type_override_strategy.rb`
- Highest priority
- User-defined type mappings from YAML
- Confidence: 1.0

#### 2. ShapeChangeMappingStrategy
**Location**: `lib/lutaml/klin/domain/strategies/shapechange_strategy.rb`
- Maps types using ShapeChange XsdMapEntry rules
- Filters by encoding rule
- Confidence: 0.9

#### 3. DomainTypeStrategy
**Location**: `lib/lutaml/klin/domain/strategies/domain_type_strategy.rb`
- Handles custom UML classes
- Creates type names from class names
- Confidence: 0.85

#### 4. SchemaRepositoryStrategy
**Location**: `lib/lutaml/klin/domain/strategies/schema_repository_strategy.rb`
- Lowest priority
- Looks up types in LXR package
- Confidence: 0.95

### MappingService
**Location**: `lib/lutaml/klin/domain/services/mapping_service.rb`

Pure domain logic for mapping:
- `map_class_to_xsd(uml_class, xsd_namespace, context)` - Map class
- `map_attribute_to_xsd(uml_attribute, context)` - Map attribute
- `map_multiplicity(multiplicity)` - Convert UML to XSD occurs

No I/O operations - all pure business logic.

### TransformationAnalyzer
**Location**: `lib/lutaml/klin/domain/services/transformation_analyzer.rb`

Predicts ShapeChange transformations:
- Analyzes UML stereotypes
- Predicts element/type names
- Determines XML serialization patterns
- Provides fallback when schemas unavailable

### ValidationService
**Location**: `lib/lutaml/klin/domain/services/validation_service.rb`

Validates mappings:
- Checks resolution status
- Calculates statistics
- Identifies issues

### PackageFilter
**Location**: `lib/lutaml/klin/domain/services/package_filter.rb`

Filters packages using glob patterns:
- Supports `**` for wildcards
- Handles `::` namespace separators
- Regex pattern matching

## Layer 4: Output (Models)

### Mapping Models
All in `lib/lutaml/klin/models/mapping/`:

```
SchemaMapping (root container)
├── version: String
├── generated_at: String
├── source_lur, source_lxr, source_config: String
├── traceability: String (YAML-serialized hash)
├── package_mappings: Array<PackageMapping>
└── namespaces: Array<String>

PackageMapping
├── uml_name, uml_package_name: String
├── xsd_namespace, xsd_namespace_prefix: String
├── class_mappings: Array<ClassMapping>
├── created_at: String
└── resolution_statistics: String (YAML)

ClassMapping
├── uml_name, uml_qualified_name, uml_stereotype: String
├── xsd_element_name, xsd_type_name, xsd_namespace: String
├── resolution_status, resolution_method: String
├── resolution_confidence: Float
└── attribute_mappings: Array<AttributeMapping>

AttributeMapping
├── uml_name, uml_type, uml_multiplicity: String
├── xsd_name, xsd_type: String
├── xsd_min_occurs, xsd_max_occurs: String
├── resolution_status, resolution_method: String
└── resolution_error: String
```

All models inherit from `Lutaml::Model::Serializable` for automatic YAML/JSON serialization.

## XSD Generation Pipeline

### XsdGenerator
**Location**: `lib/lutaml/klin/shapechange/xsd_generator.rb`

Orchestrates XSD schema generation:
- Loads UML classes from LUR
- Applies encoding rules
- Coordinates rule processors
- Writes XSD files

### Rule Processors
All in `lib/lutaml/klin/rule_processors/`:

- `ObjectElementProcessor` - Generate `<xs:element>` declarations
- `ComplexTypeProcessor` - Generate `<xs:complexType>` definitions
- `SequenceProcessor` - Generate `<xs:sequence>` groups
- `PropertyElementProcessor` - Generate property elements
- `PropertyTypeProcessor` - Generate property type wrappers
- `EnumerationProcessor` - Generate enumeration types
- `CodeListProcessor` - Generate code list types

## CLI Layer

### Cli
**Location**: `lib/lutaml/klin/cli.rb`

Thor-based CLI with commands:
- `process` - Complete workflow
- `xsd` - Generate XSD schemas
- `lookup`, `lookup-uml`, `lookup-xsd` - Query mappings
- `create-lxr` - Build LXR packages
- `spa` - Generate SPA website
- `generate`, `merge`, `validate`, `report` - Legacy commands

## Key Design Patterns

### Strategy Pattern
ResolutionEngine uses ordered strategies for type resolution. Easy to add new strategies without modifying engine.

### Repository Pattern
UmlRepositoryAdapter and SchemaRepositoryAdapter abstract data access. Can swap implementations without affecting workflows.

### Workflow Pattern
Each workflow (Mapping, Validation, SPA, Lookup) is a separate class with single responsibility. Easy to test and compose.

### Value Object Pattern
ResolutionResult, ResolutionContext, ValidationResult are immutable value objects. Thread-safe and predictable.

### Model-Driven Architecture
All data structures use Lutaml::Model::Serializable. Automatic serialization, validation, and documentation.

## Source Code Organization

```
lib/lutaml/klin/
├── cli.rb                    # Thor CLI
├── version.rb                # Gem version
│
├── application/              # Layer 2: Workflows
│   ├── processing_workflow.rb
│   ├── mapping_workflow.rb
│   ├── validation_workflow.rb
│   ├── spa_workflow.rb
│   └── lookup_workflow.rb
│
├── domain/                   # Layer 3: Business Logic
│   ├── resolution_engine.rb
│   ├── resolution_context.rb
│   ├── resolution_result.rb
│   ├── validation_result.rb
│   ├── lookup_result.rb
│   ├── processing_result.rb
│   │
│   ├── strategies/           # Resolution strategies
│   │   ├── base_strategy.rb
│   │   ├── type_override_strategy.rb
│   │   ├── shapechange_strategy.rb
│   │   ├── domain_type_strategy.rb
│   │   └── schema_repository_strategy.rb
│   │
│   ├── services/             # Domain services
│   │   ├── mapping_service.rb
│   │   ├── validation_service.rb
│   │   ├── lookup_service.rb
│   │   ├── spa_generator.rb
│   │   ├── package_filter.rb
│   │   └── transformation_analyzer.rb
│   │
│   └── reporters/            # Report generators
│       ├── json_reporter.rb
│       └── markdown_reporter.rb
│
├── repositories/             # Layer 1: Adapters
│   ├── uml_repository_adapter.rb
│   └── schema_repository_adapter.rb
│
├── models/                   # Data models
│   ├── mapping/              # Mapping models
│   │   ├── schema_mapping.rb
│   │   ├── package_mapping.rb
│   │   ├── class_mapping.rb
│   │   └── attribute_mapping.rb
│   └── uml/                  # UML models (legacy)
│
├── shapechange/              # ShapeChange integration
│   ├── config_parser.rb
│   ├── xsd_generator.rb
│   ├── rule_registry.rb
│   ├── rule_checker.rb
│   └── models/
│       ├── config/           # Config models
│       └── xsd_document.rb
│
└── commands/                 # CLI commands
    ├── process_command.rb
    ├── xsd_generate_command.rb
    ├── create_lxr_command.rb
    └── ...
```

## Data Flow: Complete Processing

```
1. User Input
   └─→ lur_path, lxr_path, config_path, package_filter

2. ProcessingWorkflow.execute()
   ├─→ Load Repositories
   │   ├─→ UmlRepositoryAdapter.new(lur_path)
   │   └─→ SchemaRepositoryAdapter.new(lxr_path)
   │
   ├─→ Load Configuration
   │   └─→ ConfigParser.parse_file(config_path)
   │
   ├─→ Filter Packages
   │   └─→ PackageFilter.filter_packages(all_packages)
   │
   ├─→ Generate Mappings
   │   └─→ MappingWorkflow.generate_mappings_for_packages()
   │       └─→ MappingService.map_class_to_xsd()
   │           └─→ ResolutionEngine.resolve()
   │               └─→ [TypeOverride → ShapeChange → DomainType → SchemaRepository]
   │
   ├─→ Validate Mappings (optional)
   │   └─→ ValidationWorkflow.validate_and_report()
   │
   └─→ Generate SPA (optional)
       └─→ SpaWorkflow.generate_spa()

3. Output
   ├─→ mappings/*.yaml
   ├─→ validation/validation_report.{json,md}
   └─→ spa/index.html
```

## Critical Implementation Paths

### Type Resolution Path
1. UML attribute has type "CharacterString"
2. Create ResolutionContext with repositories and config
3. ResolutionEngine.resolve(attribute, context)
4. Try TypeOverrideStrategy → finds "string" → return resolved
5. MappingService extracts result → builds AttributeMapping
6. Serialize to YAML with full traceability

### XSD Generation Path
1. UML class "Building" with stereotype "FeatureType"
2. XsdGenerator.process_class(building)
3. ObjectElementProcessor → creates `<xs:element name="Building">`
4. ComplexTypeProcessor → creates `<xs:complexType name="BuildingType">`
5. SequenceProcessor → creates `<xs:sequence>` for properties
6. PropertyElementProcessor → creates property elements
7. XsdDocument.to_xml() → writes XSD file

## Performance Characteristics

- **LUR Loading**: <100ms for 662 classes
- **LXR Loading**: <100ms for 2764 types
- **Mapping Generation**: ~10 seconds for 174 classes
- **Resolution Rate**: >90% for PLATEAU data
- **Memory Usage**: Moderate (packages cached in memory)