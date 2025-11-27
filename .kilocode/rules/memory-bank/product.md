# Product Overview

## What is LutaML Klin?

LutaML Klin is a Ruby-based tool that **fully replaces ShapeChange's XSD generation functionality**. It transforms UML models to XSD schemas following ShapeChange's encoding rules and conversion rules, providing 100% feature parity with ShapeChange's XmlSchema target.

## Why Does It Exist?

### Problem Statement
Organizations working with complex geospatial standards (like PLATEAU, CityGML, ISO standards) currently rely on ShapeChange (Java-based) for UML-to-XSD transformation. However:
- ShapeChange is Java-based and doesn't integrate well with Ruby toolchains
- No Ruby-native alternative exists with full feature parity
- Need for a tool that integrates with the LutaML ecosystem

**Critical Requirement**: We must **fully replace** ShapeChange's XSD generation functionality, not just provide compatibility. This means implementing 100% of ShapeChange's encoding rules, conversion rules, and features.

### Core Value Propositions

1. **Full ShapeChange Parity**: 100% feature parity with ShapeChange's XSD generation
2. **Performance**: Uses pre-built LUR/LXR packages that load in <100ms vs seconds for XML parsing
3. **Ruby Native**: Integrates seamlessly with Ribose's Ruby-based toolchain
4. **Traceability**: Generates comprehensive mapping documentation with resolution tracking
5. **Interactive**: Produces Single Page Application (SPA) websites for exploring mappings

## How It Works

### Architecture Overview

LutaML Klin follows a clean 4-layer architecture:

```
Layer 1: Input (Pre-built Packages)
├─ LUR Package (.lur) - UML model from XMI
└─ LXR Package (.lxr) - XSD schemas

Layer 2: Orchestration
├─ ProcessingWorkflow - Main coordinator
├─ MappingWorkflow - UML↔XSD mapping
├─ ValidationWorkflow - Validation reports
├─ SpaWorkflow - Interactive website
└─ LookupWorkflow - Bidirectional queries

Layer 3: Domain Logic
├─ ResolutionEngine - Type resolution with strategies
├─ MappingService - Pure mapping logic
├─ ValidationService - Mapping validation
├─ TransformationAnalyzer - ShapeChange compatibility
└─ XsdGenerator - ShapeChange-compatible XSD generation

Layer 4: Output
├─ YAML mappings (per package)
├─ Validation reports (JSON/Markdown)
├─ SPA website (HTML/JS/CSS)
└─ XSD schemas (ShapeChange-compatible)
```

### Core Workflows

#### 1. XSD Generation (Primary)
Generate ShapeChange-compatible XSD schemas from UML:
- Loads UML from LUR package (fast)
- Applies encoding rules from ShapeChange config
- Implements 100% of ShapeChange conversion rules
- Generates XSD with proper namespaces and types
- Outputs schemas following GML/ISO 19136 conventions
- **Required**: Full feature parity with ShapeChange

#### 2. Complete Processing Workflow
Users run a single `process` command that:
- Loads UML from LUR package
- Loads XSD schemas from LXR package (optional)
- Parses ShapeChange configuration
- Filters packages by pattern
- Resolves types using multiple strategies
- Generates mappings, reports, and SPA

#### 3. Bidirectional Lookup
Query mappings in both directions:
- UML→XSD: Find XSD element for UML class/attribute
- XSD→UML: Find UML elements mapped to XSD type
- Interactive REPL mode for exploration

### Key Features Required for ShapeChange Parity

1. **20+ Encoding Rules**: GML 3.2, GML 3.3, GML 2.1, ISO 19139, SWE Common, etc.
2. **100+ Conversion Rules**: Element generation, type generation, property handling, etc.
3. **Schematron Generation**: Complete subsystem for constraint validation
4. **Advanced Type Mappings**: MapEntry system with all variants
5. **Property Type Variants**: Standard GML/ISO/SWE property types
6. **Special Encodings**: Code lists, enumerations, basic types, unions
7. **Association Handling**: Association classes, qualified associations
8. **Mixin Support**: Mixin as groups, property inclusion
9. **Union Types**: All variants (choice, group, character string, etc.)
10. **Constraint System**: Facets, tagged values, OCL constraints

### Current Implementation Status

**Implemented (~15-20%)**:
- Basic GML 3.2 encoding rule (partial)
- Basic element/type generation
- Basic property encoding
- Package-based XSD document creation
- Import/include handling
- 5/5 integration tests passing for simple cases

**Missing (~80-85%)**:
- 19+ encoding rules
- 85+ conversion rules
- Schematron generation (100%)
- Advanced property types (90%)
- Code list validation (95%)
- Mixin support (100%)
- Union variations (80%)
- Association classes (70%)
- Constraint system (100%)

See `SHAPECHANGE_XSD_GAP_ANALYSIS.md` for complete details.

## Primary Use Cases

### 1. PLATEAU Urban Planning Data
Process Japanese PLATEAU geospatial standards:
- 662 UML classes across 58 packages
- Complex i-UR (Urban Planning ADE) schemas
- Generate mappings for URO (Urban Object) and URF (Urban Function) packages
- **Requires**: Full GML 3.2 support, mixin classes, union types

### 2. CityGML Standards
Work with OGC CityGML standards:
- Building, Transportation, Vegetation modules
- GML 3.2 base schemas
- ISO 19xxx standard integrations
- **Requires**: Full encoding rule support, ADEs

### 3. Custom GML Application Schemas
Create custom GML-based schemas:
- Define encoding rules
- Generate XSD from UML
- Validate against existing schemas
- **Requires**: Complete ShapeChange parity

## Implementation Roadmap

### Phase 1: Must-Have (P0) - 300-400 hours
- Complete `iso19136_2007` (GML 3.2)
- Standard GML property types
- Code list as dictionary + validation
- inlineOrByReference, nillable, nilReason
- Union type handling
- Basic mixin support

### Phase 2: Should-Have (P1) - 200-300 hours
- `iso19139_2007` (metadata)
- Association classes
- Constraining facets
- Anonymous types

### Phase 3: Nice-to-Have (P2) - 300-400 hours
- Schematron generation
- Additional encoding rules
- Advanced constraints

### Phase 4: Future (P3) - 100-200 hours
- Specialized encoding rules

**Total Estimated Effort**: 800-1,000 hours (6-8 months full-time)

## Success Metrics

### Phase 1 Success (Must-Have)
- 95%+ PLATEAU XSD generation correctly
- All GML 3.2 property types generated correctly
- Code lists properly encoded as dictionaries
- nilReason/nillable support working
- Union types properly handled
- Test coverage >90% for new features

### Full Parity Success
- 100% PLATEAU XSD generation correctly
- 80%+ PLATEAU Schematron rules generated
- Multiple encoding rules supported
- Byte-level output matches ShapeChange (where applicable)
- Performance: <10 seconds for 500+ classes
- Test coverage >85% overall
- **All 100+ ShapeChange conversion rules implemented**

## Target Users

1. **Data Modelers**: Creating and maintaining UML↔XSD mappings
2. **Standards Developers**: Working on geospatial/GML standards
3. **Documentation Teams**: Need interactive schema documentation
4. **Integration Engineers**: Building systems that consume these standards
5. **Organizations**: Needing ShapeChange replacement in Ruby environments

## Critical Notes

⚠️ **SCOPE CLARIFICATION**: This project aims to **fully replace** ShapeChange's XSD generation functionality, not just provide compatibility. This requires implementing:
- All 20+ encoding rules
- All 100+ conversion rules
- Complete Schematron generation
- All special features and edge cases

This is a **significantly larger scope** than initially understood and requires 800-1,000 hours of development effort to completion.