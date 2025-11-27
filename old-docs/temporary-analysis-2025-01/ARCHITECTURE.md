# LutaML-Klin Architecture

**Version**: 1.0
**Date**: 2025-01-22
**Status**: In Development

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Domain Model](#domain-model)
3. [System Architecture](#system-architecture)
4. [The 4-Step Vision](#the-4-step-vision)
5. [Implementation Status](#implementation-status)
6. [Design Principles](#design-principles)

---

## Executive Summary

LutaML-Klin is a Ruby-based UML-to-XSD transformation orchestrator that bridges ShapeChange workflows with the LutaML modeling ecosystem. It provides:

1. **XSD Generation**: Transform UML models (LUR) to XSD schemas using ShapeChange rules
2. **Mapping Capture**: Document UML↔XSD transformations as YAML mappings
3. **Mixed Repository**: Combine UML, XSD, and mappings in LMR packages
4. **Interactive Navigation**: SPA for exploring UML↔XSD relationships

---

## Domain Model

### Domain Separation (MECE Principle)

#### UML Domain
- **Purpose**: Represents conceptual models and their structure
- **Source**: QEA files, XMI files
- **Package Format**: LUR (LutaML UML Repository) - Ruby Marshal binary
- **Handled By**: `lutaml` gem
- **Key Entities**:
  - Package: Container for model elements
  - Class: UML class with attributes, operations, generalizations
  - Enum: Enumeration types
  - DataType: Primitive and structured types
  - Association: Relationships between classes

#### XSD Domain
- **Purpose**: Represents XML Schema definitions for data exchange
- **Source**: XSD files
- **Package Format**: LXR (LutaML XSD Repository) - Ruby Marshal binary
- **Handled By**: `lutaml-xsd` gem
- **Key Entities**:
  - Schema: XSD schema document
  - ComplexType: Complex type definitions
  - SimpleType: Simple type definitions
  - Element: Element declarations
  - Attribute: Attribute declarations

#### Transformation Domain
- **Purpose**: Defines rules for UML→XSD transformation
- **Source**: ShapeChange configuration XML
- **Handled By**: `lutaml-klin` (this gem)
- **Key Entities**:
  - EncodingRule: Named set of transformation rules
  - XsdMapEntry: Type mapping (UML type → XSD type)
  - PackageInfo: Package metadata (namespace, xmlns, version)
  - RuleProcessor: Applies specific transformation rules

#### Mapping Domain
- **Purpose**: Documents the bidirectional UML↔XSD relationships
- **Source**: Generated during transformation
- **Package Format**: YAML files, LMR packages (future)
- **Handled By**: `lutaml-klin`
- **Key Entities**:
  - SchemaMapping: Root mapping container
  - PackageMapping: UML package ↔ XSD namespace mapping
  - ClassMapping: UML class ↔ XSD type/element mapping
  - AttributeMapping: UML attribute ↔ XSD element/attribute mapping

---

## System Architecture

### Layered Architecture (4 Layers)

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Repository Adapters (Infrastructure)               │
│ ─────────────────────────────────────────────────────────── │
│ UmlRepositoryAdapter  │  SchemaRepositoryAdapter            │
│ (wraps lutaml)        │  (wraps lutaml-xsd)                 │
│ - Load LUR packages   │  - Load LXR packages                │
│ - Query UML elements  │  - Query XSD elements               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Application Workflows (Use Cases)                  │
│ ─────────────────────────────────────────────────────────── │
│ ProcessingWorkflow   │  MappingWorkflow                     │
│ ValidationWorkflow   │  SpaWorkflow                         │
│ LookupWorkflow       │  XsdGenerationWorkflow               │
│ - Orchestrate flows  │  - Handle I/O                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: Domain Services & Logic (Pure Business Logic)      │
│ ─────────────────────────────────────────────────────────── │
│ ResolutionEngine     │  MappingService                      │
│ ValidationService    │  TransformationAnalyzer              │
│ PackageFilter        │  XsdGenerator                        │
│ - NO I/O operations  │  - Pure transformations              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: Models (Data Structures)                           │
│ ─────────────────────────────────────────────────────────── │
│ SchemaMapping        │  ResolutionResult                    │
│ PackageMapping       │  ValidationResult                    │
│ ClassMapping         │  ProcessingResult                    │
│ AttributeMapping     │  XsdDocument                         │
│ - Lutaml::Model::Serializable                               │
└─────────────────────────────────────────────────────────────┘
```

### Design Patterns

#### Strategy Pattern (ResolutionEngine)
- **Purpose**: Flexible type resolution with pluggable strategies
- **Strategies**:
  1. TypeOverrideStrategy (user overrides, confidence: 1.0)
  2. ShapeChangeMappingStrategy (config mappings, confidence: 0.9)
  3. DomainTypeStrategy (UML class inference, confidence: 0.85)
  4. SchemaRepositoryStrategy (LXR lookup, confidence: 0.95)
- **Extensibility**: Add new strategies without modifying engine

#### Repository Pattern (Data Access)
- **Purpose**: Abstract data access from business logic
- **Implementations**:
  - UmlRepositoryAdapter (wraps lutaml API)
  - SchemaRepositoryAdapter (wraps lutaml-xsd API)
- **Extensibility**: Swap implementations without affecting workflows

#### Workflow Pattern (Orchestration)
- **Purpose**: Single responsibility per workflow
- **Workflows**:
  - ProcessingWorkflow: Complete end-to-end processing
  - MappingWorkflow: UML→XSD mapping generation
  - ValidationWorkflow: Validation report generation
  - SpaWorkflow: SPA website generation
  - LookupWorkflow: Bidirectional lookups
- **Extensibility**: Add new workflows without modifying existing ones

#### Template Method Pattern (Rule Processors)
- **Purpose**: Extensible XSD generation rules
- **Base**: BaseRuleProcessor defines template
- **Implementations**:
  - ObjectElementProcessor
  - ComplexTypeProcessor
  - SequenceProcessor
  - PropertyElementProcessor
  - EnumerationProcessor
  - CodeListProcessor
- **Extensibility**: Add new processors via rule registry

---

## The 4-Step Vision

### Step 1: XSD Generation ✅ **COMPLETE**

**Goal**: Generate ShapeChange-compatible XSD from LUR + ShapeChange config

**Input**:
- LUR package (UML model)
- ShapeChange configuration XML

**Process**:
1. Load UML repository from LUR
2. Parse ShapeChange configuration
3. Apply encoding rules
4. Generate XSD schemas

**Output**:
- XSD files (identical to ShapeChange output)

**Status**: ✅ Complete - 5/5 integration tests passing

**Key Components**:
- [`XsdGenerator`](lib/lutaml/klin/shapechange/xsd_generator.rb:26) - Main orchestrator
- [`ConfigParser`](lib/lutaml/klin/shapechange/config_parser.rb:14) - Parse ShapeChange XML
- [`RuleRegistry`](lib/lutaml/klin/shapechange/rule_registry.rb) - Manage encoding rules
- Rule Processors - Apply transformation rules

---

### Step 2: Mapping Capture 🔄 **IN PROGRESS**

**Goal**: Document UML↔XSD transformations as structured mappings

**Input**:
- LUR package
- LXR package
- ShapeChange configuration

**Process**:
1. During XSD generation, capture each transformation decision
2. Record:
   - UML element → XSD element mapping
   - Resolution method used
   - Confidence level
   - Transformation rules applied
3. Export to YAML format

**Output**:
- YAML mapping files (per package)
- Includes full traceability metadata

**Status**: 🔄 In Progress - Mapping generation exists, needs validation

**Key Components**:
- [`MappingService`](lib/lutaml/klin/domain/services/mapping_service.rb:20) - Generate mappings
- [`ResolutionEngine`](lib/lutaml/klin/domain/resolution_engine.rb:16) - Resolve types with metadata
- Mapping Models:
  - [`SchemaMapping`](lib/lutaml/klin/models/mapping/schema_mapping.rb) - Root container
  - [`PackageMapping`](lib/lutaml/klin/models/mapping/package_mapping.rb) - Package level
  - [`ClassMapping`](lib/lutaml/klin/models/mapping/class_mapping.rb) - Class level
  - [`AttributeMapping`](lib/lutaml/klin/models/mapping/attribute_mapping.rb) - Attribute level

**YAML Format**:
```yaml
version: "1.0"
generated_at: "2025-01-22T10:00:00Z"
source_lur: "plateau_uro.lur"
source_lxr: "plateau_schemas.lxr"
source_config: "ShapeChangeConfig.xml"

package_mappings:
  - uml_name: "ModelRoot::i-UR::uro"
    uml_package_name: "uro"
    xsd_namespace: "https://www.geospatial.jp/iur/uro/3.2"
    xsd_namespace_prefix: "uro"

    class_mappings:
      - uml_name: "Building"
        uml_qualified_name: "ModelRoot::i-UR::uro::Building"
        uml_stereotype: "FeatureType"
        xsd_element_name: "Building"
        xsd_type_name: "BuildingType"
        xsd_namespace: "https://www.geospatial.jp/iur/uro/3.2"
        resolution_status: "resolved"
        resolution_method: "domain_type_inference"
        resolution_confidence: 0.90

        attribute_mappings:
          - uml_name: "height"
            uml_type: "Length"
            uml_multiplicity: "0..1"
            xsd_name: "height"
            xsd_type: "gml:LengthType"
            xsd_min_occurs: "0"
            xsd_max_occurs: "1"
            resolution_status: "resolved"
            resolution_method: "shapechange_mapping"
```

---

### Step 3: Mixed Repository (LMR) ⏱️ **NOT STARTED**

**Goal**: Create unified repository containing UML + XSD + Mappings

**LMR Package Structure**:
```
example.lmr/
├── metadata.yaml              # LMR metadata
├── uml/
│   └── model.lur             # UML repository (binary)
├── xsd/
│   └── schemas.lxr           # XSD repository (binary)
└── mappings/
    ├── mapping_index.yaml    # Mapping index
    └── packages/
        ├── package1.yaml     # Per-package mappings
        └── package2.yaml
```

**LMR Metadata** (`metadata.yaml`):
```yaml
lmr_version: "1.0"
created_at: "2025-01-22T10:00:00Z"
created_by: "lutaml-klin 0.2.0"

repositories:
  uml:
    format: "lur"
    path: "uml/model.lur"
    classes: 662
    packages: 58

  xsd:
    format: "lxr"
    path: "xsd/schemas.lxr"
    types: 2764
    namespaces: 12

mappings:
  format: "yaml"
  path: "mappings/"
  packages: 58
  classes: 662
  resolution_rate: 0.92
```

**Key Components** (TO BE IMPLEMENTED):
- `LmrBuilder` - Build LMR packages
- `LmrRepository` - Query LMR data
- `LmrSerializer` - Serialize/deserialize LMR
- `LmrValidator` - Validate LMR structure

**API Design**:
```ruby
# Create LMR
builder = Lutaml::Klin::LmrBuilder.new
builder.add_uml_repository(lur_path)
builder.add_xsd_repository(lxr_path)
builder.add_mappings(mapping_path)
builder.build("output.lmr")

# Query LMR
lmr = Lutaml::Klin::LmrRepository.load("output.lmr")

# Navigate UML → XSD
uml_class = lmr.uml.find_class("Building")
xsd_mapping = lmr.mappings.find_for_uml_class(uml_class)
xsd_type = lmr.xsd.find_type(xsd_mapping.xsd_type_name)

# Navigate XSD → UML
xsd_element = lmr.xsd.find_element("Building")
uml_mapping = lmr.mappings.find_for_xsd_element(xsd_element)
uml_class = lmr.uml.find_class(uml_mapping.uml_qualified_name)
```

---

### Step 4: Interactive SPA ⏱️ **NOT STARTED**

**Goal**: Generate Single Page Application for exploring UML↔XSD relationships

**Input**:
- LMR package

**Features**:
1. **UML View**:
   - Browse UML packages, classes, attributes
   - View class diagrams
   - See relationships (generalizations, associations)

2. **XSD View**:
   - Browse XSD namespaces, types, elements
   - View schema structure
   - See type hierarchies

3. **Bidirectional Navigation**:
   - Click UML class → see XSD realization
   - Click XSD type → see UML source
   - Highlight mapping confidence/method

4. **Search & Filter**:
   - Search by name across both domains
   - Filter by stereotype, namespace, resolution status
   - Find unresolved mappings

5. **Mapping Visualization**:
   - Graph view of UML↔XSD relationships
   - Color-code by confidence level
   - Show transformation rules applied

**Output**:
- Self-contained HTML/CSS/JS website
- No server required (all data embedded)
- Responsive design

**Technology Stack**:
- **Templating**: Liquid (already used by lutaml)
- **Frontend**: Vanilla JS + CSS (no dependencies)
- **Data**: JSON embedded in HTML
- **Search**: Client-side full-text search

**Key Components** (TO BE IMPLEMENTED):
- `SpaGenerator` - Generate SPA from LMR
- `LiquidTemplates` - Liquid templates for pages
- `AssetBuilder` - Build CSS/JS assets
- `SearchIndexBuilder` - Build search index

**SPA Structure**:
```
spa/
├── index.html                # Main entry point
├── assets/
│   ├── css/
│   │   └── style.css        # Styles
│   └── js/
│       ├── app.js           # Main application
│       ├── navigation.js    # Navigation logic
│       └── search.js        # Search functionality
├── data/
│   ├── uml/
│   │   └── packages.json    # UML data
│   ├── xsd/
│   │   └── namespaces.json  # XSD data
│   └── mappings/
│       └── index.json       # Mapping data
└── views/
    ├── uml/
    │   ├── package.html     # UML package view
    │   └── class.html       # UML class view
    └── xsd/
        ├── namespace.html   # XSD namespace view
        └── type.html        # XSD type view
```

---

## Implementation Status

### Completed Features ✅

1. **Repository Adapters**:
   - UmlRepositoryAdapter (wraps lutaml)
   - SchemaRepositoryAdapter (wraps lutaml-xsd)

2. **XSD Generation**:
   - XsdGenerator with rule-based processing
   - ShapeChange configuration parsing
   - Encoding rule application
   - XSD document generation

3. **Mapping Generation**:
   - MappingService for UML→XSD mapping
   - ResolutionEngine with strategy pattern
   - Mapping models (Schema, Package, Class, Attribute)
   - YAML export

4. **Workflows**:
   - ProcessingWorkflow (end-to-end)
   - MappingWorkflow
   - ValidationWorkflow
   - LookupWorkflow

### In Progress 🔄

1. **Mapping Validation**:
   - Validate mappings against LXR
   - Calculate parity with ShapeChange
   - Generate validation reports

2. **Test Coverage**:
   - Comprehensive unit tests
   - Integration tests
   - Edge case coverage

### Not Started ⏱️

1. **LMR (Step 3)**:
   - LMR package format
   - LMR builder
   - LMR repository
   - Bidirectional queries

2. **SPA (Step 4)**:
   - SPA generator
   - Templates
   - Frontend JavaScript
   - Search functionality

---

## Design Principles

### Object-Oriented Design

1. **Single Responsibility Principle**:
   - Each class has one reason to change
   - `XsdGenerator` orchestrates, processors handle rules
   - `MappingService` creates mappings, strategies resolve types

2. **Open/Closed Principle**:
   - Open for extension, closed for modification
   - Add new strategies without changing `ResolutionEngine`
   - Add new processors without changing `XsdGenerator`

3. **Dependency Inversion**:
   - Depend on abstractions, not concretions
   - Workflows depend on repository interfaces
   - Services depend on strategy interfaces

4. **Interface Segregation**:
   - Clients shouldn't depend on unused interfaces
   - Repository adapters expose only needed methods
   - Strategies implement minimal interface

### MECE (Mutually Exclusive, Collectively Exhaustive)

1. **Domain Separation**:
   - UML, XSD, Transformation, Mapping domains are distinct
   - No overlap between domains
   - Complete coverage of all concerns

2. **Layer Separation**:
   - Infrastructure, Application, Domain, Models
   - Clear boundaries between layers
   - No layer skipping

3. **Component Responsibility**:
   - Each component handles distinct concern
   - No component overlap
   - All concerns handled

### Separation of Concerns

1. **Domain Layer**:
   - **ZERO I/O operations**
   - Pure business logic
   - Testable in isolation

2. **Application Layer**:
   - Orchestration + I/O
   - Coordinates domain services
   - Handles external interactions

3. **Infrastructure Layer**:
   - External system access
   - File I/O, network I/O
   - Repository implementations

4. **Model Layer**:
   - Data structures only
   - Serialization logic
   - Validation rules

### Extensibility

1. **Strategy Pattern**:
   - Add resolution strategies
   - Add validation strategies

2. **Registry Pattern**:
   - Add encoding rules
   - Add rule processors

3. **Template Method**:
   - Override specific steps
   - Customize behavior

4. **Plugin Architecture** (Future):
   - Load custom transformations
   - Extend mapping formats

---

## Performance Considerations

### Current Performance

- **LUR Loading**: <100ms for 662 classes
- **LXR Loading**: <100ms for 2764 types
- **Mapping Generation**: ~10 seconds for 174 classes
- **Resolution Rate**: >90% for PLATEAU data
- **Memory Usage**: Moderate (packages cached)

### Optimization Strategies

1. **Lazy Loading**:
   - Load UML elements on-demand
   - Cache frequently accessed data

2. **Parallel Processing** (Future):
   - Process packages in parallel
   - Async resolution strategies

3. **Incremental Updates** (Future):
   - Only process changed classes
   - Differential mapping generation

---

## Security Considerations

1. **Input Validation**:
   - File paths validated
   - XML input sanitized (XXE protection)
   - Marshal data verified

2. **Output Safety**:
   - Safe YAML serialization
   - Path traversal prevention
   - Proper file permissions

---

## Testing Strategy

### Unit Tests
- Test individual components in isolation
- Mock external dependencies
- Fast execution (<1 second)

### Integration Tests
- Test complete workflows
- Use real LUR/LXR packages
- Verify actual output

### Edge Cases
- Circular dependencies
- Missing referenced types
- Invalid configurations
- Malformed packages

---

## Future Enhancements

1. **JSON Serialization**:
   - Replace Marshal with JSON for portability
   - Cross-language compatibility

2. **Streaming Processing**:
   - Handle very large models
   - Reduce memory footprint

3. **Plugin System**:
   - Custom transformations
   - Custom validation rules

4. **REST API**:
   - Web service for transformations
   - Remote repository access

---

**End of Architecture Document**