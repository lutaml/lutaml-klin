# Lutaml-Klin Mapping Workflow Architecture

## Purpose

This document explains how lutaml-klin orchestrates the complete UML-to-XSD mapping workflow, combining LUR packages (UML models), LXR packages (XSD schemas), and ShapeChange configurations to generate comprehensive mappings and interactive documentation.

## Overview

Lutaml-klin serves as a **pure orchestration layer** that:

1. **Loads pre-built packages** (LUR + LXR) for fast access
2. **Applies ShapeChange transformation rules** to correlate UML with XSD
3. **Generates three outputs**: YAML mappings, validation reports, and interactive SPA website

**Key Principle**: No parsing—all heavy lifting done by package creation tools (lutaml, lutaml-xsd). Lutaml-klin focuses purely on orchestration and mapping logic.

## Complete Workflow Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                         INPUT LAYER                               │
│  (Built Once, Used Many Times)                                   │
└──────────────────────────────────────────────────────────────────┘
                              │
      ┌───────────────────────┼───────────────────────┐
      │                       │                       │
      ▼                       ▼                       ▼
┌──────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  LUR Package │    │  LXR Package     │    │  ShapeChange     │
│              │    │                  │    │  Configuration   │
│  .lur file   │    │  .lxr file       │    │  .xml file       │
│              │    │                  │    │                  │
│  Built by:   │    │  Built by:       │    │  Contains:       │
│  lutaml      │    │  lutaml-xsd      │    │  • Encoding      │
│              │    │                  │    │    rules         │
│  Contains:   │    │  Contains:       │    │  • Type mappings │
│  • Packages  │    │  • Elements      │    │  • Namespaces    │
│  • Classes   │    │  • Types         │    │  • Package info  │
│  • Attributes│    │  • Namespaces    │    │                  │
│              │    │                  │    │                  │
│  Load: <100ms│    │  Load: <100ms    │    │  Parse: <50ms    │
└──────┬───────┘    └────────┬─────────┘    └─────────┬────────┘
       │                     │                         │
       └─────────────────────┼─────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                    ORCHESTRATION LAYER                            │
│                      (lutaml-klin)                                │
└──────────────────────────────────────────────────────────────────┘
                             │
        Step 1: Load Repositories
                             │
                             ▼
            ┌────────────────────────────────┐
            │  Repository Adapters           │
            │  • UmlRepositoryAdapter        │
            │  • SchemaRepositoryAdapter     │
            │  • ConfigParser                │
            └────────────────┬───────────────┘
                             │
        Step 2: Initialize Resolution Engine
                             │
                             ▼
            ┌────────────────────────────────┐
            │  Type Resolution Engine        │
            │  (Strategy Pattern)            │
            │                                │
            │  Priority-ordered strategies:  │
            │  1. TypeOverrideStrategy       │
            │  2. ShapeChangeMappingStrategy │
            │  3. SchemaRepositoryStrategy   │
            │  4. DomainTypeStrategy         │
            └────────────────┬───────────────┘
                             │
        Step 3: Process Packages
                             │
                             ▼
            ┌────────────────────────────────┐
            │  Processing Workflow           │
            │  • Filter packages by pattern  │
            │  • For each package:           │
            │    - Get UML classes           │
            │    - Resolve XSD types         │
            │    - Map attributes            │
            │    - Track resolution status   │
            └────────────────┬───────────────┘
                             │
        Step 4: Generate Outputs
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌────────────┐  ┌────────────┐  ┌────────────┐
    │   YAML     │  │ Validation │  │    SPA     │
    │  Mappings  │  │  Reports   │  │  Website   │
    └────────────┘  └────────────┘  └────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                         OUTPUT LAYER                              │
└──────────────────────────────────────────────────────────────────┘
```

## Input Components Detailed

### 1. LUR Package (UML Repository)

**Created by**: `lutaml xmi package build model.xmi -o model.lur`

**Contains**:
```
UML Model Hierarchy
├─ Packages (with qualified names)
│  ├─ Full name: "ModelRoot::i-UR::urf"
│  ├─ Namespace: "https://www.geospatial.jp/iur/urf/3.2"
│  └─ Version: "3.2"
├─ Classes (with stereotypes)
│  ├─ Name, qualified name
│  ├─ Stereotype: "FeatureType", "DataType", "CodeList"
│  ├─ Base class references
│  └─ Documentation
└─ Attributes (with types and cardinality)
   ├─ Name, type reference
   ├─ Multiplicity: min..max
   └─ Initial values
```

**API Access**:
```ruby
uml_repo.find_package("ModelRoot::i-UR::urf")
uml_repo.classes_in_package("ModelRoot::i-UR::urf")
uml_repo.find_classes_by_stereotype("featureType")
```

### 2. LXR Package (XSD Repository)

**Created by**: `lutaml-xsd package build schemas_config.yaml -o schemas.lxr`

**Contains**:
```
XSD Schema Repository
├─ Elements (global definitions)
│  ├─ Name, type reference
│  ├─ Namespace
│  └─ Substitution group
├─ Complex Types
│  ├─ Name, namespace
│  ├─ Content model (sequence/choice)
│  ├─ Base type (for extensions)
│  └─ Properties/attributes
└─ Simple Types
   ├─ Name, base type
   ├─ Restrictions (enums, patterns)
   └─ Unions
```

**API Access**:
```ruby
xsd_repo.find_element("Building", namespace: "https://...")
xsd_repo.find_type("BuildingType", namespace: "https://...")
xsd_repo.list_types_in_namespace("https://...")
```

### 3. ShapeChange Configuration

**Structure**:
```xml
<ShapeChangeConfiguration>
  <!-- Package information -->
  <input>
    <packages>
      <PackageInfo packageName="uro"
                   ns="https://www.geospatial.jp/iur/uro/3.2"
                   nsabr="uro"
                   xsdDocument="urbanObject.xsd"/>
    </packages>

    <!-- Type mappings -->
    <xsdMapEntries>
      <XsdMapEntry type="CharacterString"
                   xmlType="xs:string"
                   xsdEncodingRules="iso19136_2007"/>
    </xsdMapEntries>

    <!-- Namespace declarations -->
    <xmlNamespaces>
      <XmlNamespace nsabr="gml"
                    ns="http://www.opengis.net/gml/3.2"
                    location="http://schemas.opengis.net/gml/3.2.1/gml.xsd"/>
    </xmlNamespaces>
  </input>

  <!-- Encoding rules -->
  <rules>
    <EncodingRule name="iso19136_2007" extends="gml32">
      <rule name="rule-xsd-cls-object-element"/>
      <rule name="rule-xsd-cls-standard-gml-property-types"/>
      <!-- ... more rules ... -->
    </EncodingRule>
  </rules>
</ShapeChangeConfiguration>
```

**Parsed Into**:
```ruby
config.package_infos       # Package metadata
config.xsd_map_entries     # Type mappings
config.xml_namespaces      # Namespace definitions
config.encoding_rules      # Transformation rules
```

## Type Resolution Architecture

### Multi-Strategy Resolution (Priority Order)

```
┌─────────────────────────────────────────────────────────────┐
│              Type Resolution Request                         │
│  Input: UML type name (e.g., "CharacterString")             │
└─────────────────────────┬───────────────────────────────────┘
                          │
              Try Strategy 1: TypeOverrideStrategy
                          │
                          ▼
            ┌──────────────────────────────┐
            │  User-defined overrides      │
            │  From: --type-overrides file │
            │  Priority: HIGHEST (1.0)     │
            │  Example:                    │
            │    CharacterString → string  │
            └──────────┬──────────┬────────┘
                       │ Found?   │
                 YES ──┘          └── NO
                  │                  │
                  │     Try Strategy 2: ShapeChangeMappingStrategy
                  │                  │
                  │                  ▼
                  │    ┌──────────────────────────────┐
                  │    │  ShapeChange XsdMapEntry     │
                  │    │  From: config xsdMapEntries  │
                  │    │  Priority: HIGH (0.95)       │
                  │    │  Example:                    │
                  │    │    CharacterString →         │
                  │    │    xs:string (iso19136_2007) │
                  │    └──────────┬──────────┬────────┘
                  │               │ Found?   │
                  │         YES ──┘          └── NO
                  │          │                  │
                  │          │     Try Strategy 3: SchemaRepositoryStrategy
                  │          │                  │
                  │          │                  ▼
                  │          │    ┌──────────────────────────────┐
                  │          │    │  Direct XSD schema lookup    │
                  │          │    │  From: LXR package           │
                  │          │    │  Priority: MEDIUM (0.85)     │
                  │          │    │  Searches for:               │
                  │          │    │    • Element with same name  │
                  │          │    │    • Type with same name     │
                  │          │    └──────────┬──────────┬────────┘
                  │          │               │ Found?   │
                  │          │         YES ──┘          └── NO
                  │          │          │                  │
                  │          │          │     Try Strategy 4: DomainTypeStrategy
                  │          │          │                  │
                  │          │          │                  ▼
                  │          │          │    ┌──────────────────────────────┐
                  │          │          │    │  Domain type inference       │
                  │          │          │    │  Priority: LOW (0.70)        │
                  │          │          │    │  Heuristics:                 │
                  │          │          │    │    • Class in same package   │
                  │          │          │    │    • Name pattern matching   │
                  │          │          │    └──────────┬──────────┬────────┘
                  │          │          │               │ Found?   │
                  │          │          │         YES ──┘          └── NO
                  │          │          │          │                  │
                  │          │          │          │             UNRESOLVED
                  └──────────┴──────────┴──────────┴─────────────────┘
                                        │
                                        ▼
                            ┌────────────────────────┐
                            │  Resolution Result     │
                            │                        │
                            │  • status: resolved    │
                            │  • method: strategy    │
                            │  • confidence: 0.0-1.0 │
                            │  • metadata: {...}     │
                            └────────────────────────┘
```

### Resolution Result Structure

```ruby
{
  status: :resolved,              # :resolved, :partial, :unresolved
  method: "shapechange_mapping",  # Which strategy succeeded
  confidence: 0.95,               # Confidence score (0.0-1.0)
  xsd_type: "xs:string",          # Resolved XSD type
  xsd_namespace: "http://...",    # Full namespace URI
  metadata: {                     # Additional information
    map_entry_id: "...",
    encoding_rule: "iso19136_2007"
  }
}
```

## Processing Workflow Details

### Step 1: Package Selection

```ruby
# User specifies package filter
--packages "ModelRoot::i-UR::**"

# System finds matching packages
packages = uml_repo.find_packages_matching("ModelRoot::i-UR::**")
# Returns: ["ModelRoot::i-UR::urf", "ModelRoot::i-UR::uro", ...]
```

### Step 2: Class Processing

For each package, process all classes:

```ruby
package = uml_repo.find_package("ModelRoot::i-UR::urf")
classes = uml_repo.classes_in_package(package.qualified_name)

classes.each do |uml_class|
  # Create class mapping
  class_mapping = process_class(uml_class)

  # Process attributes
  uml_class.attributes.each do |attr|
    attr_mapping = process_attribute(attr, class_mapping)
    class_mapping.add_attribute_mapping(attr_mapping)
  end
end
```

### Step 3: Type Resolution per Attribute

```ruby
def process_attribute(uml_attribute, class_mapping)
  # Get UML type name
  uml_type = uml_attribute.type  # e.g., "CharacterString"

  # Try resolution strategies in order
  result = resolution_engine.resolve_type(
    uml_type,
    context: {
      uml_class: class_mapping.uml_class,
      package: class_mapping.package,
      encoding_rule: "iso19136_2007"
    }
  )

  # Create attribute mapping with result
  AttributeMapping.new(
    uml_name: uml_attribute.name,
    uml_type: uml_type,
    uml_multiplicity: uml_attribute.cardinality,
    xsd_name: transform_name(uml_attribute.name),
    xsd_type: result.xsd_type,
    xsd_namespace: result.xsd_namespace,
    resolution_status: result.status,
    resolution_method: result.method,
    resolution_confidence: result.confidence
  )
end
```

### Step 4: Namespace Resolution

```ruby
def resolve_namespace(xsd_type)
  # Extract prefix (e.g., "gml:CodeType" → "gml")
  prefix = xsd_type.split(':').first

  # Look up in config
  ns_info = config.xml_namespaces.find { |ns| ns.nsabr == prefix }

  return ns_info.ns if ns_info

  # Fallback: search in LXR
  xsd_repo.find_namespace_for_prefix(prefix)
end
```

## Output Generation

### Output 1: YAML Mappings

**Per-package YAML files** with complete traceability:

```yaml
---
version: "1.0"
generated_at: "2025-01-14T08:58:00Z"

# Source traceability
source_lur: "packages/plateau_all.lur"
source_lxr: "packages/plateau_schemas.lxr"
source_config: "reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml"

# Package information
uml_package_name: "ModelRoot::i-UR::urf"
xsd_namespace: "https://www.geospatial.jp/iur/urf/3.2"
xsd_namespace_prefix: "urf"

# Resolution statistics
resolution_statistics:
  total_classes: 208
  resolved_classes: 208
  resolution_rate: 1.0
  total_attributes: 847
  resolved_attributes: 847
  attribute_resolution_rate: 1.0

# Traceability metadata
traceability:
  resolution_strategies:
    - "TypeOverrideStrategy"
    - "ShapeChangeMappingStrategy"
    - "SchemaRepositoryStrategy"
    - "DomainTypeStrategy"
  lxr_package_info:
    name: "PLATEAU Schema Repository"
    version: "3.2"
    total_types: 2764
    namespaces: 34
  lur_package_info:
    total_classes: 662
    total_packages: 58

# Mappings
class_mappings:
  - uml_name: "UrbanPlanningArea"
    uml_qualified_name: "ModelRoot::i-UR::urf::UrbanPlanningArea"
    uml_stereotype: "FeatureType"
    xsd_element_name: "UrbanPlanningArea"
    xsd_type_name: "urf:UrbanPlanningAreaType"
    xsd_namespace: "https://www.geospatial.jp/iur/urf/3.2"
    resolution_status: "resolved"
    resolution_method: "schema_repository"
    resolution_confidence: 0.85

    attribute_mappings:
      - uml_name: "areaType"
        uml_type: "CharacterString"
        uml_multiplicity: "0..1"
        xsd_name: "areaType"
        xsd_type: "xs:string"
        xsd_namespace: "http://www.w3.org/2001/XMLSchema"
        xsd_min_occurs: 0
        xsd_max_occurs: 1
        resolution_status: "resolved"
        resolution_method: "shapechange_mapping"
        resolution_confidence: 0.95
```

### Output 2: Validation Reports

**JSON Report** (machine-readable):
```json
{
  "version": "1.0",
  "generated_at": "2025-01-14T08:58:00Z",
  "statistics": {
    "total_packages": 2,
    "total_classes": 255,
    "resolved_classes": 255,
    "resolution_rate": 1.0,
    "by_strategy": {
      "shapechange_mapping": 194,
      "domain_type": 61
    }
  },
  "packages": [...],
  "issues": []
}
```

**Markdown Report** (human-readable):
```markdown
# Validation Report

Generated: 2025-01-14 08:58:00 UTC

## Summary
- Total Classes: 255
- Resolved: 255 (100%)
- By Strategy:
  - ShapeChange Mapping: 194 (76.1%)
  - Domain Type: 61 (23.9%)

## Package: ModelRoot::i-UR::urf
Resolution Rate: 100%
Classes: 208
```

### Output 3: Interactive SPA Website

**Generated Structure**:
```
output/spa/
├── index.html                    # Main application
├── assets/
│   ├── css/
│   │   └── style.css            # Responsive styling
│   └── js/
│       ├── app.js               # Main application logic
│       └── search.js            # Search and filter
└── data/
    └── mappings.json            # Embedded mapping data
```

**Features**:
- **Search**: Full-text search across all classes and attributes
- **Filter**: By package, stereotype, resolution status, method
- **Navigate**: Tree view of package hierarchy
- **Details**: Click any class to see complete mapping details
- **Statistics**: Real-time resolution rate dashboard
- **Export**: Download filtered results as JSON/YAML
- **Responsive**: Works on desktop, tablet, mobile

## Architecture Layers

### Layer 1: Presentation (CLI + SPA)

**Responsibilities**:
- Parse command-line arguments
- Display progress and results
- Handle user interaction (in SPA)

**Components**:
- `Cli` - Thor-based command interface
- `ProcessCommand`, `XsdGenerateCommand`, etc.
- SPA website (HTML + JavaScript)

### Layer 2: Application (Workflows)

**Responsibilities**:
- Orchestrate multi-step processes
- Coordinate between repositories
- Transform data for output

**Components**:
- `ProcessingWorkflow` - Complete mapping generation workflow
- `ValidationWorkflow` - Generate validation reports
- `SpaWorkflow` - Generate interactive website
- `LookupWorkflow` - Query mappings bidirectionally

### Layer 3: Domain (Core Logic)

**Responsibilities**:
- Type resolution logic
- Mapping generation rules
- Validation rules
- Business logic

**Components**:
- `TypeResolutionEngine` - Strategy pattern coordinator
- Resolution strategies:
  - `TypeOverrideStrategy`
  - `ShapeChangeMappingStrategy`
  - `SchemaRepositoryStrategy`
  - `DomainTypeStrategy`
- `MappingGenerator` - Create mapping models
- `ValidationService` - Validate mappings

### Layer 4: Infrastructure (Repositories + Adapters)

**Responsibilities**:
- Load and access data
- Abstract external dependencies
- Provide clean APIs

**Components**:
- `UmlRepositoryAdapter` - Wraps Lutaml::UmlRepository
- `SchemaRepositoryAdapter` - Wraps lutaml-xsd SchemaRepository
- `ConfigParser` - Parse ShapeChange XML
- `XIncludeResolver` - Resolve xi:include references

## Data Flow Example

**Scenario**: Process PLATEAU URF package

```
1. User Command:
   lutaml-klin process \
     --lur plateau_all.lur \
     --lxr plateau_schemas.lxr \
     --config ShapeChangeConfig_Plateau_urf.xml \
     --packages "**::urf" \
     --output output/

2. Load Inputs (~200ms):
   ├─ Load LUR: ~80ms → UmlRepository with 662 classes
   ├─ Load LXR: ~70ms → SchemaRepository with 2764 types
   └─ Parse Config: ~50ms → Config with 87 type mappings

3. Find Packages (~10ms):
   └─ Pattern "**::urf" matches: ["ModelRoot::i-UR::urf"]

4. Process Package (~2000ms):
   ├─ Get classes: 208 classes
   ├─ For each class (~10ms each):
   │  ├─ Resolve XSD element (schema repository lookup)
   │  ├─ Resolve XSD type (schema repository lookup)
   │  └─ For each attribute (~2ms each):
   │     ├─ Resolve attribute type (strategy pattern)
   │     ├─ Determine XSD name (transformation rules)
   │     └─ Record resolution metadata
   └─ Create PackageMapping model

5. Generate YAML (~100ms):
   └─ Serialize PackageMapping to YAML with Lutaml::Model

6. Generate Validation (~50ms):
   ├─ Calculate statistics
   ├─ Identify issues
   └─ Write JSON + Markdown reports

7. Generate SPA (~200ms):
   ├─ Convert YAML to JSON
   ├─ Generate HTML structure
   ├─ Embed mapping data
   └─ Write assets (CSS/JS)

Total Time: ~2.6 seconds
```

## Design Patterns Used

### 1. Strategy Pattern (Type Resolution)

```ruby
class TypeResolutionEngine
  def initialize
    @strategies = [
      TypeOverrideStrategy.new,
      ShapeChangeMappingStrategy.new,
      SchemaRepositoryStrategy.new,
      DomainTypeStrategy.new
    ]
  end

  def resolve_type(uml_type, context)
    @strategies.each do |strategy|
      result = strategy.resolve(uml_type, context)
      return result if result.resolved?
    end

    ResolutionResult.unresolved(uml_type)
  end
end
```

### 2. Adapter Pattern (Repository Access)

```ruby
class UmlRepositoryAdapter
  def initialize(lur_path)
    @repository = Lutaml::UmlRepository::Repository.from_package(lur_path)
  end

  # Adapt lutaml API to lutaml-klin needs
  def find_package(path)
    @repository.find_package(path)
  end

  def classes_in_package(path, recursive: false)
    @repository.classes_in_package(path, recursive: recursive)
  end
end
```

### 3. Builder Pattern (Output Generation)

```ruby
class SpaBuilder
  def build(mapping)
    @html = HtmlBuilder.new
    @html.add_header(title: "UML-XSD Mappings")
    @html.add_navigation(packages: mapping.packages)
    @html.add_content(mappings: mapping.class_mappings)
    @html.add_assets(css: styles, js: scripts)
    @html.build
  end
end
```

### 4. Template Method Pattern (Workflows)

```ruby
class BaseWorkflow
  def execute
    validate_inputs
    load_data
    process_data
    generate_output
  end

  # Subclasses override these
  def load_data; end
  def process_data; end
  def generate_output; end
end
```

## Performance Characteristics

### Package Loading

```
Component           Time    Method
─────────────────────────────────────────
LUR package load    80ms    Lutaml::UmlRepository.from_package
LXR package load    70ms    Lutaml::Xsd::SchemaRepository.from_package
Config parse        50ms    ConfigParser.parse_file
─────────────────────────────────────────
Total load time     200ms   One-time initialization
```

### Processing Performance

```
Operation                   Time/Item   Total (208 classes)
──────────────────────────────────────────────────────────
Class lookup                0.1ms       20ms
XSD type resolution         2ms         416ms
Attribute processing        0.5ms       423ms (847 attrs)
YAML generation            0.5ms       104ms
──────────────────────────────────────────────────────────
Total processing           ~10ms/class  ~2.1 seconds
```

### Output Generation

```
Output              Time    Size
───────────────────────────────────
YAML mapping        100ms   ~500KB
Validation JSON     30ms    ~50KB
Validation MD       20ms    ~30KB
SPA website         200ms   ~200KB
───────────────────────────────────
Total output        350ms   ~780KB
```

## Extensibility Points

### Custom Resolution Strategies

```ruby
class CustomTypeStrategy < BaseResolutionStrategy
  def resolve(uml_type, context)
    # Custom logic here
    if custom_condition?(uml_type)
      return ResolutionResult.resolved(
        xsd_type: custom_mapping(uml_type),
        confidence: 0.80
      )
    end

    ResolutionResult.unresolved
  end
end

# Register in engine
engine.add_strategy(CustomTypeStrategy.new, priority: 5)
```

### Custom Output Formats

```ruby
class CustomOutputFormatter
  def format(mapping)
    # Transform mapping to custom format
    # e.g., Excel, PDF, GraphQL schema, etc.
  end
end

# Use in workflow
workflow.add_formatter(CustomOutputFormatter.new)
```

### Custom Validation Rules

```ruby
class CustomValidationRule
  def validate(class_mapping)
    issues = []

    # Custom validation logic
    if custom_check_fails?(class_mapping)
      issues << ValidationIssue.new(
        severity: :warning,
        message: "Custom validation failed"
      )
    end

    issues
  end
end

# Register rule
validation_workflow.add_rule(CustomValidationRule.new)
```

## ShapeChange Integration Specifics

### How ShapeChange Config is Used

**1. Package Information**:
```xml
<PackageInfo packageName="uro"
             ns="https://www.geospatial.jp/iur/uro/3.2"
             nsabr="uro"/>
```
→ Maps UML package name to XSD namespace and prefix

**2. Type Mappings**:
```xml
<XsdMapEntry type="CharacterString"
             xmlType="xs:string"
             xsdEncodingRules="iso19136_2007"/>
```
→ Defines how UML types transform to XSD types

**3. Encoding Rules**:
```xml
<EncodingRule name="iso19136_2007" extends="gml32">
  <rule name="rule-xsd-cls-standard-gml-property-types"/>
</EncodingRule>
```
→ Specifies which transformation rules apply

### Encoding Rule Application

Lutaml-klin applies ShapeChange encoding rules for:

- **Property naming**: Whether to use original name or transform
- **Type wrapping**: Whether to create PropertyType wrappers
- **Multiplicity**: How to encode min/maxOccurs
- **Inheritance**: How to handle base classes
- **Stereotypes**: Special handling for FeatureType, DataType, etc.

## Comparison with ShapeChange

| Aspect | ShapeChange (Java) | lutaml-klin (Ruby) |
|--------|-------------------|-------------------|
| **Input Parsing** | Parses XMI every time | Pre-built LUR (parse once) |
| **Schema Parsing** | Parses XSD every time | Pre-built LXR (parse once) |
| **Load Time** | ~5-10 seconds | ~200ms (25-50x faster) |
| **Output** | XSD schema files | YAML mappings + Reports + SPA |
| **Purpose** | Transform UML → XSD | Document UML ↔ XSD mappings |
| **Extensibility** | Java plugins | Ruby strategies/processors |
| **Interactive** | No | Yes (SPA website) |

## Use Cases

### Use Case 1: Documentation Generation

**Goal**: Create comprehensive documentation of UML-XSD mappings

**Workflow**:
```bash
lutaml-klin process \
  --lur model.lur \
  --lxr schemas.lxr \
  --config config.xml \
  --packages "**" \
  --output docs/mappings/
```

**Output**: Complete mapping documentation with SPA for browsing

### Use Case 2: Mapping Validation

**Goal**: Verify that all UML classes map to XSD correctly

**Workflow**:
```bash
lutaml-klin process \
  --lur model.lur \
  --lxr schemas.lxr \
  --config config.xml \
  --packages "**" \
  --output validation/ \
  --no-generate-spa

# Check resolution rate
cat validation/validation/validation_report.md
```

**Output**: Validation reports identifying unmapped classes

### Use Case 3: CI/CD Integration

**Goal**: Continuous validation of mappings in build pipeline

**Workflow**:
```bash
#!/bin/bash
lutaml-klin process --lur ... --lxr ... --config ... --output build/
RATE=$(cat build/validation/validation_report.json | jq '.statistics.overall_resolution_rate')
if (( $(echo "$RATE < 0.95" | bc) )); then exit 1; fi
```

**Output**: Automated quality gates

### Use Case 4: Interactive Exploration

**Goal**: Allow stakeholders to explore mappings interactively

**Workflow**:
```bash
lutaml-klin process \
  --lur model.lur \
  --lxr schemas.lxr \
  --config config.xml \
  --packages "**" \
  --output public/

# Deploy SPA
cp -r public/spa/* /var/www/html/mappings/
```

**Output**: Public website for exploring mappings

## Benefits of Architecture

✅ **Performance**: Pre-built packages load 25-50x faster than XML parsing
✅ **Reliability**: Packages validated at build time
✅ **Traceability**: Complete audit trail from source to output
✅ **Extensibility**: Strategy pattern allows custom resolution logic
✅ **Scalability**: Efficient lookups handle large models (1000+ classes)
✅ **Maintainability**: Clean separation of concerns, SOLID principles
✅ **Testability**: Each layer independently testable
✅ **Usability**: Single command does everything

## Future Enhancements

### Planned Features

1. **Bidirectional XSD Generation**: Generate XSD from existing mappings
2. **Diff Tool**: Compare mappings across versions
3. **Merge Conflict Resolution**: Smart merging of overlapping mappings
4. **GraphQL Schema**: Generate GraphQL from mappings
5. **OpenAPI Spec**: Generate OpenAPI from UML
6. **Custom Exporters**: Plugin system for custom formats

### Architecture Support

The current architecture supports these enhancements without major refactoring:

- **Strategy pattern** allows adding new resolution strategies
- **Workflow pattern** allows adding new processing workflows
- **Builder pattern** allows adding new output formats
- **Adapter pattern** allows integrating new repositories

## Conclusion

Lutaml-klin's architecture provides:

1. **Clean separation** between input loading, processing, and output
2. **Extensible design** through Strategy and Builder patterns
3. **High performance** through pre-built packages
4. **Complete traceability** through metadata capture
5. **Interactive exploration** through SPA generation

The system is production-ready for mapping documentation and validation, with XSD generation capabilities actively being developed.