# ShapeChange XSD Generation - Gap Analysis

**Date**: 2025-01-24
**Purpose**: Comprehensive analysis of ShapeChange's XSD generation features vs lutaml-klin implementation
**Scope**: XSD generation ONLY (not JSON, SQL, RDF, or other targets)

---

## Executive Summary

ShapeChange's XmlSchema target is **massive** (~4,519 lines in XmlSchema.java + ~1,492 lines in XsdDocument.java). It implements:

- **20+ encoding rules** (GML 3.2, GML 3.3, GML 2.1, ISO 19139, SWE Common, etc.)
- **100+ conversion rules** (element generation, type generation, property handling, etc.)
- **Complex type mappings** via MapEntry system
- **Schematron constraint generation** from OCL constraints
- **Sophisticated property type generation** (inline, byReference, arrays, qualifiers, etc.)

**Current Status**: lutaml-klin has ~15-20% of ShapeChange's XSD functionality implemented.

**Estimated Effort**: 800-1000 hours to achieve 100% parity (6-8 months full-time)

---

## 1. ShapeChange XSD Architecture

### 1.1 Core Components

```
XmlSchema.java (4,519 lines)
├── initialise() - Setup and configuration
├── process() - Process each class
├── write() - Output XSD files
│
├── Element Generation
│   ├── pObjectElement() - Global elements
│   ├── pPropertyTypes() - Property type generation
│   └── pPropertyTypeWithSubtypes() - Abstract type properties
│
├── Type Generation  
│   ├── pComplexType() - Complex type definitions
│   ├── pGlobalEnumeration() - Enumeration types
│   ├── pGlobalCodeList() - Code list types
│   ├── pGlobalBasicType() - Basic type restrictions
│   └── pGroup() - Attribute groups
│
├── Property Handling
│   ├── addProperty() - Individual property encoding
│   ├── mapPropertyType() - Type mapping
│   ├── processLocalProperties() - Class properties
│   └── addAnonymousPropertyType() - Inline types
│
└── Special Features
    ├── Schematron generation
    ├── Qualifier handling
    ├── Metadata properties
    ├── Code list validation
    └── nilReason support
```

### 1.2 Encoding Rules Supported

ShapeChange supports **20+ encoding rules**:

#### Base Encoding Rules
1. **`*` (core)** - Universal base rules
2. **`iso19136_2007`** - GML 3.2 (ISO 19136:2007)
3. **`gml33`** - GML 3.3
4. **`gml21`** - GML 2.1 (backward compatibility)
5. **`iso19139_2007`** - ISO 19139:2007 metadata
6. **`ogcSweCommon2`** - SWE Common Data Model 2.0

#### Extension Encoding Rules
7. **`iso19136_2007_INSPIRE_Extensions`**
8. **`iso19136_2007_ShapeChange_1.0_Extensions`**
9. **`okstra`** - German road information standard
10. **`citygml`** - CityGML extensions
11. **`citygml-ade`** - CityGML ADEs
12. **`metadata-profile`** - ISO 19139 profiles
13. **`notEncoded`** - Suppression rule
14. **`external`** - External definitions
15. **`iso19136_2007_NoGmlBaseTypes`** - No GML base types

### 1.3 Conversion Rules (100+)

ShapeChange implements **over 100 conversion rules**. Key categories:

#### Required Rules (req-*)
- `req-xsd-pkg-xsdDocument-unique`
- `req-xsd-cls-name-unique`
- `req-xsd-cls-ncname`
- `req-xsd-prop-data-type`
- `req-xsd-prop-value-type-exists`
- `req-xsd-prop-ncname`
- Many more...

#### Package Rules (rule-xsd-pkg-*)
- `rule-xsd-pkg-contained-packages`
- `rule-xsd-pkg-dependencies`
- `rule-xsd-pkg-gmlProfileSchema`
- `rule-xsd-pkg-schematron`
- `rule-xsd-pkg-dgiwgsp`
- `rule-xsd-pkg-gmlsf`

#### Class Rules (rule-xsd-cls-*)
- `rule-xsd-cls-object-element`
- `rule-xsd-cls-type`
- `rule-xsd-cls-sequence`
- `rule-xsd-cls-global-enumeration`
- `rule-xsd-cls-codelist-asDictionary`
- `rule-xsd-cls-noPropertyType`
- `rule-xsd-cls-byValuePropertyType`
- `rule-xsd-cls-standard-gml-property-types`
- `rule-xsd-cls-standard-19139-property-types`
- `rule-xsd-cls-union-as-choice`
- `rule-xsd-cls-union-asGroup`
- `rule-xsd-cls-union-asCharacterString`
- `rule-xsd-cls-mixin-classes`
- `rule-xsd-cls-mixin-classes-as-group`
- `rule-xsd-cls-basictype`
- `rule-xsd-cls-suppress`
- `rule-xsd-cls-adeelement`
- `rule-xsd-cls-adehook`
- ... 30+ more

#### Property Rules (rule-xsd-prop-*)
- `rule-xsd-prop-defaultCodeSpace`
- `rule-xsd-prop-inlineOrByReference`
- `rule-xsd-prop-reverseProperty`
- `rule-xsd-prop-targetElement`
- `rule-xsd-prop-nillable`
- `rule-xsd-prop-nilReasonAllowed`
- `rule-xsd-prop-xsdAsAttribute`
- `rule-xsd-prop-initialValue`
- `rule-xsd-prop-gmlArrayProperty`
- `rule-xsd-prop-gmlListProperty`
- `rule-xsd-prop-qualified-associations`
- `rule-xsd-prop-constrainingFacets`
- `rule-xsd-prop-metadata`
- `rule-xsd-prop-soft-typed`
- ... 20+ more

#### General Rules (rule-xsd-all-*)
- `rule-xsd-all-naming-gml`
- `rule-xsd-all-naming-19139`
- `rule-xsd-all-naming-swe`
- `rule-xsd-all-notEncoded`
- `rule-xsd-all-documentation`
- `rule-xsd-all-tagged-values`
- `rule-xsd-all-descriptorAnnotation`
- ... and more

---

## 2. Current lutaml-klin Implementation

### 2.1 What We Have ✅

**File**: `lib/lutaml/klin/shapechange/xsd_generator.rb` (277 lines)

**Implemented Encoding Rules**:
- Basic `iso19136_2007` support (partial)
- Rule registry system (`RuleRegistry`)
- Rule checking (`RuleChecker`)

**Implemented Rule Processors** (in `lib/lutaml/klin/rule_processors/`):
1. `ObjectElementProcessor` - Generate `<xs:element>` declarations
2. `ComplexTypeProcessor` - Generate `<xs:complexType>` definitions  
3. `SequenceProcessor` - Generate `<xs:sequence>` groups
4. `PropertyElementProcessor` - Generate property elements
5. `PropertyTypeProcessor` - Generate property type wrappers
6. `EnumerationProcessor` - Generate enumeration types
7. `CodeListProcessor` - Generate code list types
8. `UnionAsGroupProcessor` - Generate union as attribute groups

**Implemented Features**:
- Basic element generation
- Basic complex type generation
- Basic property encoding
- Namespace handling
- Package-based XSD document creation
- Import/include handling

**Test Coverage**:
- 5/5 XSD generation integration tests passing
- 1,628 elements generated
- 487 types generated
- 255 classes processed

### 2.2 What's Missing ❌

#### Missing Encoding Rules (~80%)
- GML 3.3 (`gml33`)
- GML 2.1 (`gml21`)
- ISO 19139 (`iso19139_2007`)
- SWE Common (`ogcSweCommon2`)
- INSPIRE extensions
- ShapeChange extensions
- OKSTRA, CityGML, ADE support
- And 10+ more

#### Missing Conversion Rules (~90%)
- Most req-* required rules
- Most package rules (dependencies, profiles, etc.)
- Advanced class rules:
  - Mixin class handling
  - Union type variations (asCharacterString, asGroup, etc.)
  - Basic type restrictions
  - Code list constraints
  - Suppress/ADE rules
- Advanced property rules:
  - inlineOrByReference control
  - nilReason/nillable support
  - Array properties
  - List properties
  - Qualifiers
  - Metadata properties
  - Soft-typed properties
  - Constraining facets
  - Initial values
  - reverseProperty
  - targetElement

#### Missing Features (~85%)
1. **Schematron Generation** - Complete subsystem missing
   - OCL constraint conversion
   - Code list validation rules
   - nilReason checks
   - valueOrNilReason assertions
   
2. **Advanced Type Mappings** - 80% missing
   - MapEntry system (partially implemented)
   - Attribute mappings
   - AttributeGroup mappings
   - Element mappings
   - Complex/simple content distinction
   - xmlReferenceable handling

3. **Property Type Variants** - 90% missing
   - Standard GML property types
   - Standard ISO 19139 property types
   - Standard SWE property types
   - ByValue property types
   - Inline property types
   - Anonymous property types
   - Array property types
   - List property types

4. **Special Encodings** - 95% missing
   - Code list as dictionary (GML 3.2/3.3)
   - Code list URI validation
   - Code list representation handling
   - Anonymous enumerations
   - Anonymous basic types
   - Local enumerations
   - Local basic types

5. **Association Handling** - 70% missing
   - Association classes
   - Qualified associations
   - Bidirectional associations
   - Aggregation/composition semantics

6. **Mixin Support** - 100% missing
   - Mixin as groups
   - Mixin property inclusion
   - Mixin subtypes

7. **Union Types** - 80% missing
   - Union as choice
   - Union as group
   - Union as character string
   - Union direct encoding
   - Union representing feature type sets

8. **Constraint System** - 100% missing
   - Constraining facets (length, pattern, range)
   - Tagged value constraints
   - OCL constraints

---

## 3. Feature Parity Matrix

| Feature Category | ShapeChange | lutaml-klin | Gap % |
|-----------------|-------------|-------------|-------|
| **Encoding Rules** | 20+ | 1 partial | 95% |
| **Conversion Rules** | 100+ | ~15 | 85% |
| **Element Generation** | Complete | Basic | 70% |
| **Type Generation** | Complete | Basic | 75% |
| **Property Handling** | Complete | Basic | 80% |
| **Schematron** | Complete | None | 100% |
| **Type Mappings** | Complete | Partial | 80% |
| **Special Features** | Complete | Minimal | 90% |
| **Overall** | **100%** | **~15-20%** | **80-85%** |

---

## 4. Implementation Effort Estimate

### 4.1 Complexity Analysis

**Lines of Code**:
- ShapeChange XmlSchema: ~6,000 lines (XmlSchema.java + XsdDocument.java)
- Current lutaml-klin: ~1,500 lines (all XSD-related code)
- **Gap**: ~4,500 lines equivalent

### 4.2 Detailed Effort Breakdown

#### Phase 1: Core Encoding Rules (200-250 hours)
- [ ] Complete `iso19136_2007` implementation (40h)
- [ ] Add `gml33` encoding rule (50h)
- [ ] Add `gml21` encoding rule (30h)
- [ ] Add `iso19139_2007` encoding rule (60h)
- [ ] Add `ogcSweCommon2` encoding rule (50h)

#### Phase 2: Conversion Rules (250-300 hours)
- [ ] Package rules (40h)
- [ ] Required rules (60h)
- [ ] Class rules (100h)
- [ ] Property rules (80h)
- [ ] General rules (20h)

#### Phase 3: Property Type Generation (150-180 hours)
- [ ] Standard GML property types (50h)
- [ ] Standard ISO 19139 property types (40h)
- [ ] Standard SWE property types (30h)
- [ ] Anonymous property types (40h)
- [ ] Special property types (arrays, lists, etc.) (30h)

#### Phase 4: Special Encodings (100-120 hours)
- [ ] Code list as dictionary (40h)
- [ ] Code list validation (30h)
- [ ] Anonymous types (enumerations, basic types) (30h)
- [ ] Local types (20h)

#### Phase 5: Association & Union Handling (80-100 hours)
- [ ] Association classes (30h)
- [ ] Qualified associations (20h)
- [ ] Union variations (40h)
- [ ] Bidirectional associations (20h)

#### Phase 6: Mixin Support (60-80 hours)
- [ ] Mixin as groups (30h)
- [ ] Mixin property inclusion (20h)
- [ ] Mixin subtypes (20h)

#### Phase 7: Constraint System (80-100 hours)
- [ ] Constraining facets (40h)
- [ ] Tagged value constraints (30h)
- [ ] OCL constraints (basic) (30h)

#### Phase 8: Schematron Generation (150-200 hours)
- [ ] Schematron schema structure (30h)
- [ ] OCL constraint conversion (60h)
- [ ] Code list assertions (40h)
- [ ] nilReason/value assertions (40h)
- [ ] Custom assertions (30h)

#### Phase 9: Testing & Validation (100-120 hours)
- [ ] Unit tests for all new features (60h)
- [ ] Integration tests (30h)
- [ ] Parity validation with ShapeChange (30h)

#### Phase 10: Documentation (50-70 hours)
- [ ] Update README with all features (20h)
- [ ] Encoding rule documentation (20h)
- [ ] API documentation (20h)

**TOTAL ESTIMATED EFFORT**: **800-1,000 hours** (equivalent to **6-8 months full-time**)

### 4.3 Effort Assumptions

- Assumes developer familiar with:
  - Ruby
  - XML Schema specification
  - GML 3.2 standard
  - ISO 19139 standard
  - UML-to-XSD transformation principles
- Assumes access to:
  - ShapeChange source code (available)
  - ShapeChange documentation
  - Test data and expected outputs
- Assumes iterative development with testing

---

## 5. Prioritization Strategy

### 5.1 Must-Have (Phase 1: 300-400 hours)

**P0 - Critical for PLATEAU compatibility**:
1. Complete `iso19136_2007` (GML 3.2) encoding rule
2. Property type generation (standard GML property types)
3. Code list handling (as dictionary + validation)
4. Advanced property rules:
   - `rule-xsd-prop-inlineOrByReference`
   - `rule-xsd-prop-nillable`
   - `rule-xsd-prop-nilReasonAllowed`
5. Union type handling (as choice, as group)
6. Basic mixin support

**Why**: These are fundamental to generating correct GML 3.2 application schemas.

### 5.2 Should-Have (Phase 2: 200-300 hours)

**P1 - Important for completeness**:
1. `iso19139_2007` encoding rule (metadata)
2. Association class handling
3. Constraining facets
4. Anonymous type generation
5. Code list validation (basic)

**Why**: Needed for proper metadata and validation support.

### 5.3 Nice-to-Have (Phase 3: 300-400 hours)

**P2 - Enhanced features**:
1. Schematron generation (full)
2. `gml33` encoding rule
3. `ogcSweCommon2` encoding rule
4. Advanced constraint handling
5. OCL constraint conversion (advanced)

**Why**: Advanced validation and broader standard support.

### 5.4 Future (Phase 4: 100-200 hours)

**P3 - Specialized support**:
1. `gml21` (backward compatibility)
2. Extension encoding rules (INSPIRE, ShapeChange extensions)
3. OKSTRA support
4. CityGML ADE support

**Why**: Specialized use cases, lower priority.

---

## 6. Recommended Approach

### 6.1 Immediate Next Steps (Next 2-4 weeks)

1. **Complete Phase C (Testing)**
   - Finish model layer tests (60-80 tests)
   - Fix pre-existing test failures (41 tests)
   - Achieve >85% coverage

2. **Document Current State**
   - Update ARCHITECTURE.md with gap analysis
   - Update README with current capabilities
   - Create SHAPECHANGE_PARITY.md document

3. **Start Phase 1 Implementation** (Must-Have features)
   - Begin with completing `iso19136_2007` encoding rule
   - Focus on property type generation improvements
   - Implement code list dictionary handling

### 6.2 Medium Term (2-4 months)

1. Complete P0 Must-Have features
2. Achieve 50% ShapeChange parity
3. Comprehensive testing against PLATEAU data

### 6.3 Long Term (6-12 months)

1. Complete P1 Should-Have features
2. Implement Schematron generation
3. Achieve 80%+ ShapeChange parity
4. Support multiple encoding rules

---

## 7. Risk Assessment

### 7.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Encoding rule complexity | High | High | Incremental implementation, extensive testing |
| ShapeChange behavior undocumented | Medium | High | Reverse engineer from source code |
| Performance issues | Low | Medium | Profile and optimize critical paths |
| Test data unavailable | Low | Medium | Use PLATEAU and synthetic data |

### 7.2 Schedule Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Effort underestimated | Medium | High | Time-box features, MVP approach |
| Dependencies on other work | Low | Medium | Clear interfaces, parallel work |
| Scope creep | Medium | High | Strict prioritization, feature freeze after P0/P1 |

---

## 8. Success Criteria

### 8.1 Phase 1 (Must-Have) Success

- [ ] 95%+ PLATEAU XSD generation correctly
- [ ] All GML 3.2 property types generated correctly
- [ ] Code lists properly encoded as dictionaries
- [ ] nilReason/nillable support working
- [ ] Union types properly handled
- [ ] Test coverage >90% for new features

### 8.2 Full Parity Success

- [ ] 100% PLATEAU XSD generation correctly
- [ ] 80%+ PLATEAU Schematron rules generated
- [ ] Multiple encoding rules supported
- [ ] Byte-level output matches ShapeChange (where applicable)
- [ ] Performance: <10 seconds for 500+ classes
- [ ] Test coverage >85% overall

---

## 9. Conclusion

### 9.1 Current State

lutaml-klin has successfully implemented **basic XSD generation** (~15-20% of ShapeChange). The current implementation:
- Works for simple UML models
- Generates valid XSD
- Handles basic property types
- Processes PLATEAU data (with limitations)

### 9.2 Recommended Path Forward

**GATE 1 (Immediate - 2 weeks)**:
- Complete Phase C (testing)
- Document current state
- Get stakeholder approval for timeline

**GATE 2 (P0 Features - 3-4 months)**:
- Implement Must-Have features
- Achieve 50% parity
- Validate with PLATEAU data

**GATE 3 (P1 Features - 6-8 months)**:
- Implement Should-Have features
- Add Schematron generation
- Achieve 80% parity

**GATE 4 (Full Parity - 12 months)**:
- Complete all features
- Full testing and optimization
- Production ready

### 9.3 Resource Requirements

- **Developer time**: 800-1,000 hours (6-8 months full-time)
- **Testing infrastructure**: Comprehensive test data and expected outputs
- **Documentation**: Ongoing documentation of features and decisions
- **Validation**: Access to ShapeChange for comparison testing

---

**Last Updated**: 2025-01-24
**Status**: Initial gap analysis complete
**Next Action**: Review with stakeholders, approve timeline and priorities