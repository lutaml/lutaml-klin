# SPA Website and Validation Command Architecture

## Overview

This document extends the SchemaRepository integration architecture with two new features:

1. **SPA Website Generator**: Interactive web application for browsing UML-to-XSD mappings
2. **Validation Command**: Report generation for resolution status and missing mappings

## Feature 1: SPA Website Generator

### Purpose

Generate a static Single Page Application (SPA) website that provides:
- Interactive UML-to-XSD mapping browser
- Search functionality (like just-the-docs in Jekyll)
- Resolution status indicators (resolved/unresolved)
- Full annotation and documentation display
- Client-side filtering and navigation

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│            SPA Generation Data Flow                          │
└─────────────────────────────────────────────────────────────┘

Input: YAML Mappings + XMI + LXR Package
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Package      │  │ XMI File     │  │ LXR Package  │
│ Mappings     │  │ (annotations)│  │ (XSD docs)   │
│ (YAML)       │  │              │  │              │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
                         ▼
                ┌────────────────────┐
                │  SpaGenerator      │
                │                    │
                │ 1. Parse YAML      │
                │ 2. Extract XMI     │
                │    annotations     │
                │ 3. Extract XSD     │
                │    documentation   │
                │ 4. Build index     │
                │ 5. Generate JSON   │
                │ 6. Generate HTML   │
                └─────────┬──────────┘
                          │
                          ▼
          ┌───────────────────────────────┐
          │  SPA Output Directory         │
          │                               │
          │  ├─ index.html               │
          │  ├─ data/                    │
          │  │   ├─ mappings.json        │
          │  │   ├─ packages.json        │
          │  │   └─ search_index.json    │
          │  ├─ assets/                  │
          │  │   ├─ css/                 │
          │  │   └─ js/                  │
          │  └─ README.md                │
          └───────────────────────────────┘
```

### JSON Data Format

#### mappings.json Structure

```json
{
  "version": "1.0",
  "generated_at": "2025-10-25T09:00:00Z",
  "metadata": {
    "xmi_file": "20251010-242.xmi",
    "config_file": "ShapeChangeConfig_Plateau_urf.xml",
    "lxr_package": "plateau_schemas.lxr"
  },
  "packages": [
    {
      "id": "pkg_urf",
      "name": "i-UR::Urban Planning ADE 3.2::urf",
      "namespace": "https://www.geospatial.jp/iur/urf/3.2",
      "classes": [
        {
          "id": "class_urban_planning_area",
          "uml_name": "UrbanPlanningArea",
          "xsd_name": "UrbanPlanningAreaType",
          "xsd_element": "urf:UrbanPlanningArea",
          "stereotype": "featureType",
          "resolved": true,
          "documentation": {
            "uml": "Represents an urban planning designated area...",
            "xsd": "Complex type for urban planning area features..."
          },
          "attributes": [
            {
              "id": "attr_area_classification",
              "uml_name": "areaClassificationType",
              "uml_type": "urf::AreaClassificationType",
              "xsd_name": "urf:areaClassificationType",
              "xsd_type": "gml:CodeType",
              "xsd_namespace": "http://www.opengis.net/gml/3.2",
              "resolved": true,
              "resolution_method": "schema_repository",
              "min_occurs": "0",
              "max_occurs": "1",
              "documentation": {
                "uml": "Classification of the area type...",
                "xsd": "gml:CodeType is a generalized type..."
              }
            },
            {
              "id": "attr_unresolved_example",
              "uml_name": "customProperty",
              "uml_type": "CustomType",
              "resolved": false,
              "resolution_error": "Type not found in SchemaRepository",
              "documentation": {
                "uml": "A custom property..."
              }
            }
          ]
        }
      ]
    }
  ],
  "statistics": {
    "total_packages": 3,
    "total_classes": 174,
    "total_attributes": 1250,
    "resolved_classes": 170,
    "resolved_attributes": 1200,
    "unresolved_classes": 4,
    "unresolved_attributes": 50,
    "resolution_rate": 0.96
  }
}
```

#### search_index.json Structure

```json
{
  "index": [
    {
      "id": "class_urban_planning_area",
      "type": "class",
      "title": "UrbanPlanningArea",
      "package": "i-UR::urf",
      "xsd_name": "UrbanPlanningAreaType",
      "keywords": ["urban", "planning", "area", "urf"],
      "url": "#/packages/pkg_urf/classes/class_urban_planning_area"
    },
    {
      "id": "attr_area_classification",
      "type": "attribute",
      "title": "areaClassificationType",
      "parent_class": "UrbanPlanningArea",
      "xsd_type": "gml:CodeType",
      "keywords": ["area", "classification", "type", "code"],
      "url": "#/packages/pkg_urf/classes/class_urban_planning_area/attributes/attr_area_classification"
    }
  ]
}
```

### SPA Frontend Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              SPA Frontend Architecture                       │
└─────────────────────────────────────────────────────────────┘

Technology Stack:
- HTML5 + CSS3 (no build step required)
- Vanilla JavaScript (ES6+)
- Client-side routing (hash-based)
- Local JSON data loading

Components:
┌───────────────────────────────────────────────────────┐
│  index.html (Single Page)                             │
│                                                        │
│  ┌──────────────────────────────────────────────┐    │
│  │  Header                                       │    │
│  │  ├─ Title: "PLATEAU UML-XSD Mappings"       │    │
│  │  └─ Search Box (with autocomplete)           │    │
│  └──────────────────────────────────────────────┘    │
│                                                        │
│  ┌──────────────┐  ┌───────────────────────────┐    │
│  │  Sidebar     │  │  Main Content              │    │
│  │              │  │                            │    │
│  │  Package     │  │  ┌──────────────────────┐ │    │
│  │  Tree        │  │  │  Breadcrumb Nav      │ │    │
│  │  ├─ i-UR     │  │  └──────────────────────┘ │    │
│  │  │  ├─ urf   │  │                            │    │
│  │  │  └─ uro   │  │  Class/Attribute Details   │    │
│  │  └─ CityGML  │  │  ┌──────────────────────┐ │    │
│  │              │  │  │  UML Information     │ │    │
│  │  Filters     │  │  │  └─ Name             │ │    │
│  │  ☑ Resolved  │  │  │  └─ Type             │ │    │
│  │  ☑ Unresolved│  │  │  └─ Documentation    │ │    │
│  │              │  │  └──────────────────────┘ │    │
│  │  Statistics  │  │                            │    │
│  │  ├─ Classes  │  │  ┌──────────────────────┐ │    │
│  │  │  170/174  │  │  │  XSD Mapping         │ │    │
│  │  └─ Attrs    │  │  │  └─ Element          │ │    │
│  │     1200/1250│  │  │  └─ Type             │ │    │
│  └──────────────┘  │  │  └─ Namespace        │ │    │
│                    │  │  └─ Documentation    │ │    │
│                    │  │  └─ Resolution Status│ │    │
│                    │  └──────────────────────┘ │    │
│                    └───────────────────────────┘    │
└───────────────────────────────────────────────────────┘
```

### Key Features

1. **Search & Filter**
   - Fuzzy search across class/attribute names
   - Filter by resolution status
   - Filter by package
   - Real-time results

2. **Navigation**
   - Hash-based routing (no server required)
   - Breadcrumb navigation
   - Package tree navigation
   - Direct links to classes/attributes

3. **Resolution Status Indicators**
   - ✓ Green badge: Fully resolved
   - ⚠ Yellow badge: Partially resolved (class resolved, some attrs unresolved)
   - ✗ Red badge: Unresolved
   - Hover for resolution details

4. **Documentation Display**
   - UML documentation from XMI
   - XSD documentation from schemas
   - Resolution path trace
   - ShapeChange rule references

### CLI Integration

```bash
# Generate SPA from YAML mappings
lutaml-klin generate-spa \
  --input output/urf_mapping.yaml \
  --xmi sources/xmi/20251010-242.xmi \
  --lxr pkg/plateau_schemas.lxr \
  --output spa/

# Options:
#   --title "Custom Title"
#   --theme (light|dark)
#   --include-unresolved (default: true)
#   --search-min-length 2 (minimum chars for search)
```

## Feature 2: Validation Command

### Purpose

Validate UML-to-XSD mapping completeness and generate reports:
- Check if all UML packages can be resolved
- Identify missing classes, attributes, types
- Support package filtering syntax
- Generate both machine-readable (JSON) and human-readable (Markdown) reports

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│            Validation Command Data Flow                      │
└─────────────────────────────────────────────────────────────┘

Input: XMI + Config + LXR + Package Filter
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ XMI File     │  │ ShapeChange  │  │ LXR Package  │
│              │  │ Config       │  │              │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └─────────────────┼─────────────────┘
                         │
                         ▼
                ┌────────────────────────────┐
                │  ValidationCommand         │
                │                            │
                │ 1. Parse package filter    │
                │ 2. Load XMI packages       │
                │ 3. Load SchemaRepository   │
                │ 4. For each package:       │
                │    a. Find namespace       │
                │    b. For each class:      │
                │       - Resolve XSD type   │
                │       - For each attr:     │
                │         * Resolve type     │
                │         * Track status     │
                │ 5. Generate report         │
                └─────────┬──────────────────┘
                          │
                          ▼
              ┌────────────────────────────┐
              │  Validation Report         │
              │                            │
              │  ├─ validation_report.json │
              │  └─ validation_report.md   │
              └────────────────────────────┘
```

### Package Filter Syntax

```ruby
# Filter patterns (inspired by Ruby/RSpec syntax):
#
# 1. Exact package name
"i-UR::Urban Planning ADE 3.2::urf"

# 2. Wildcard patterns
"i-UR::*::urf"                 # Any intermediate package
"i-UR::**"                     # All packages under i-UR
"**::urf"                      # Any package ending with urf

# 3. Regular expressions
/^i-UR::/                      # All i-UR packages
/CityGML.*::building/          # CityGML building packages

# 4. Multiple filters (OR logic)
["i-UR::*::urf", "i-UR::*::uro"]

# 5. Exclusions (NOT logic)
{
  include: ["i-UR::**"],
  exclude: ["**::deprecated"]
}
```

### Validation Report Format

#### JSON Format (validation_report.json)

```json
{
  "version": "1.0",
  "generated_at": "2025-10-25T09:00:00Z",
  "summary": {
    "total_packages": 3,
    "total_classes": 174,
    "total_attributes": 1250,
    "resolved_packages": 3,
    "resolved_classes": 170,
    "resolved_attributes": 1200,
    "unresolved_classes": 4,
    "unresolved_attributes": 50,
    "resolution_rate": 0.96,
    "status": "partial"
  },
  "packages": [
    {
      "name": "i-UR::urf",
      "namespace": "https://www.geospatial.jp/iur/urf/3.2",
      "status": "resolved",
      "classes": {
        "total": 58,
        "resolved": 56,
        "unresolved": 2
      },
      "attributes": {
        "total": 450,
        "resolved": 440,
        "unresolved": 10
      },
      "unresolved_items": [
        {
          "type": "class",
          "uml_name": "DeprecatedClass",
          "reason": "No matching XSD complex type found",
          "suggestions": []
        },
        {
          "type": "attribute",
          "class": "UrbanPlanningArea",
          "uml_name": "customProperty",
          "uml_type": "CustomType",
          "reason": "Type not found in SchemaRepository",
          "suggestions": [
            "Check if type is defined in a different namespace",
            "Verify ShapeChange type mapping configuration"
          ]
        }
      ]
    }
  ],
  "global_issues": [
    {
      "severity": "warning",
      "message": "4 classes could not be resolved to XSD types",
      "affected_packages": ["i-UR::urf", "CityGML::building"]
    },
    {
      "severity": "info",
      "message": "Overall resolution rate of 96% is acceptable"
    }
  ]
}
```

#### Markdown Format (validation_report.md)

```markdown
# UML-to-XSD Validation Report

Generated: 2025-10-25T09:00:00Z

## Summary

| Metric | Value | Status |
|--------|-------|--------|
| Overall Resolution Rate | 96% | ⚠ Partial |
| Packages | 3/3 | ✓ All resolved |
| Classes | 170/174 | ⚠ 4 unresolved |
| Attributes | 1200/1250 | ⚠ 50 unresolved |

## Package Details

### i-UR::Urban Planning ADE 3.2::urf

**Status**: ✓ Resolved
**Namespace**: `https://www.geospatial.jp/iur/urf/3.2`

**Statistics**:
- Classes: 56/58 (96.6%)
- Attributes: 440/450 (97.8%)

#### Unresolved Items

##### Class: DeprecatedClass
- **Reason**: No matching XSD complex type found
- **Suggestions**: None available

##### Attribute: UrbanPlanningArea.customProperty
- **UML Type**: CustomType
- **Reason**: Type not found in SchemaRepository
- **Suggestions**:
  - Check if type is defined in a different namespace
  - Verify ShapeChange type mapping configuration

---

## Global Issues

### ⚠ Warnings

- 4 classes could not be resolved to XSD types
  - Affected packages: i-UR::urf, CityGML::building

### ℹ Info

- Overall resolution rate of 96% is acceptable
```

### CLI Integration

```bash
# Basic validation (all packages)
lutaml-klin validate \
  --xmi sources/xmi/20251010-242.xmi \
  --config reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml \
  --lxr pkg/plateau_schemas.lxr

# With package filter
lutaml-klin validate \
  --xmi sources/xmi/20251010-242.xmi \
  --config config.xml \
  --lxr pkg/schemas.lxr \
  --packages "i-UR::**"

# With output options
lutaml-klin validate \
  --xmi sources/xmi/20251010-242.xmi \
  --config config.xml \
  --lxr pkg/schemas.lxr \
  --packages "i-UR::**" \
  --output-json validation_report.json \
  --output-md validation_report.md \
  --fail-on-unresolved  # Exit code 1 if any unresolved items

# Exclude patterns
lutaml-klin validate \
  --xmi sources/xmi/20251010-242.xmi \
  --config config.xml \
  --lxr pkg/schemas.lxr \
  --packages "i-UR::**" \
  --exclude "**::deprecated"
```

## Implementation Plan

### Phase 1: Data Model Extensions (2-3 hours)

**Goal**: Extend mapping models to support resolution status and documentation

**Tasks**:
1. Add resolution status fields to mapping models
2. Add documentation fields (UML and XSD)
3. Add resolution error tracking
4. Update YAML serialization

**Deliverables**:
- Enhanced `ClassMapping` with resolution status
- Enhanced `AttributeMapping` with resolution error
- Documentation model

### Phase 2: SPA Generator Component (6-8 hours)

**Goal**: Create component to generate SPA from YAML mappings

**Tasks**:
1. Create `SpaGenerator` class
2. Implement JSON data generation
3. Create HTML template (index.html)
4. Create CSS styling
5. Create JavaScript application logic
6. Implement search functionality
7. Write tests

**Deliverables**:
- `lib/lutaml/klin/spa_generator.rb`
- `lib/lutaml/klin/templates/spa/` directory with assets
- `spec/lutaml/klin/spa_generator_spec.rb`

### Phase 3: Validation Command (4-6 hours)

**Goal**: Implement validation command with reporting

**Tasks**:
1. Create `ValidationCommand` class
2. Implement package filter parser
3. Implement resolution checking logic
4. Create JSON report generator
5. Create Markdown report generator
6. Add CLI integration
7. Write tests

**Deliverables**:
- `lib/lutaml/klin/commands/validation_command.rb`
- `lib/lutaml/klin/package_filter.rb`
- `lib/lutaml/klin/validation_reporter.rb`
- `spec/lutaml/klin/commands/validation_command_spec.rb`

### Phase 4: CLI Integration (2-3 hours)

**Goal**: Add new commands to CLI

**Tasks**:
1. Add `generate-spa` command
2. Add `validate` command
3. Update help text
4. Create command option classes

**Deliverables**:
- Updated `lib/lutaml/klin/cli.rb`
- Command help documentation

### Phase 5: Integration & Testing (3-4 hours)

**Goal**: End-to-end testing with PLATEAU data

**Tasks**:
1. Generate SPA for PLATEAU URF package
2. Run validation on all PLATEAU packages
3. Verify SPA functionality in browser
4. Test package filtering
5. Performance testing

**Deliverables**:
- `spec/integration/spa_generation_spec.rb`
- `spec/integration/validation_command_spec.rb`
- Sample generated SPA website

### Phase 6: Documentation (2-3 hours)

**Goal**: Document new features

**Tasks**:
1. Update README with SPA and validation examples
2. Create SPA usage guide
3. Create validation usage guide
4. Document package filter syntax

**Deliverables**:
- Updated `README.adoc`
- `docs/SPA_GENERATION.md`
- `docs/VALIDATION.md`
- `docs/PACKAGE_FILTERS.md`

## Total Estimated Time

**19-27 hours** for complete SPA and validation feature implementation

## Key Design Decisions

### Decision 1: Static SPA vs. Server-Based Application

**Choice**: Static SPA with no build step required

**Rationale**:
- Easy deployment (just copy files)
- No server required
- Works offline
- Simple to host (GitHub Pages, etc.)
- Vanilla JS avoids dependency hell

**Trade-offs**:
- Limited real-time features (acceptable)
- Client-side search only (fast enough for datasets)

### Decision 2: Validation as Separate Command vs. Integrated into Generate

**Choice**: Separate `validate` command

**Rationale**:
- Single responsibility principle
- Can validate without generating full mappings
- Faster feedback loop
- Useful for CI/CD pipelines

**Trade-offs**:
- Users run two commands instead of one (acceptable)
- Slight code duplication (managed with shared modules)

### Decision 3: Package Filter Syntax

**Choice**: String patterns with wildcards and regex support

**Rationale**:
- Familiar to users (glob-like patterns)
- Flexible (regex for complex cases)
- Easy to write and read
- Composable (include/exclude)

**Trade-offs**:
- Need to implement parser (manageable complexity)

## Integration with SchemaRepository Architecture

The SPA and validation features build on top of the SchemaRepository integration:

```
SchemaRepository (Foundation)
       ↓
MappingGenerator (Enhanced with resolution tracking)
       ↓
       ├──→ SpaGenerator (Consumes enhanced mappings)
       └──→ ValidationCommand (Uses resolution status)
```

Both features leverage:
- SchemaRepository's qualified name resolution
- Type resolution tracking from MappingGenerator
- LXR package system for XSD documentation
- Namespace-aware type lookup capabilities

## Success Criteria

### SPA Generator
- [ ] Generates working HTML/CSS/JS from YAML
- [ ] Search returns correct results in <100ms
- [ ] Displays both resolved and unresolved items
- [ ] Shows UML and XSD documentation
- [ ] Works in all modern browsers
- [ ] Mobile-responsive design

### Validation Command
- [ ] Correctly filters packages by pattern
- [ ] Identifies all unresolved items
- [ ] Generates accurate statistics
- [ ] Produces valid JSON and Markdown reports
- [ ] Provides actionable suggestions
- [ ] Completes in reasonable time (<30s for PLATEAU)

## Conclusion

These two features complete the lutaml-klin toolchain:

1. **LXR Packages** → Fast schema loading
2. **SchemaRepository** → Namespace-aware resolution
3. **Validation** → Quality assurance
4. **SPA Generation** → User-friendly browsing

Together, they provide a complete workflow from UML model to interactive documentation with full traceability and validation.