# Systematic Rule Implementation Plan: Rule-by-Rule Approach

## Methodology

**For EACH rule**, follow this systematic process:

### Step 1: Investigate (30 min)
- Read .adoc documentation
- Understand purpose and behavior
- Identify parameters

### Step 2: Locate Implementation (30 min)
- Find in Java source (`/Users/mulgogi/src/external/ShapeChange/shapechange-core/src/main/java/...`)
- Read implementation logic
- Document algorithm

### Step 3: Design (1 hour)
- Choose processor vs configuration approach
- Design Ruby implementation
- Plan test cases

### Step 4: Implement (2-4 hours)
- Create processor class
- Write comprehensive spec
- Test with real data

### Step 5: Integrate (30 min)
- Add to processor registry
- Update rule definitions
- Commit

**Total per rule**: 5-7 hours

## Rule Investigation Template

**For each rule**, create a document:

```markdown
# Rule: {rule-id}

## Documentation
Location: /Users/mulgogi/src/external/ShapeChange/.../xml schema/{file}.adoc
Description: {from docs}
Parameters: {list}

## Java Implementation
Primary: {Java file}:{line numbers}
Logic: {summary of algorithm}

## Our Implementation
Type: [Processor Class | Configuration]
File: lib/lutaml/klin/shapechange/rule_processors/{category}/{name}_processor.rb
Spec: spec/lutaml/klin/shapechange/rule_processors/{category}/{name}_processor_spec.rb

## Test Cases
1. Basic functionality
2. Edge cases
3. Integration with other rules

## Status
- [x] Documentation read
- [x] Java code analyzed
- [x] Processor implemented
- [x] Spec written (X examples passing)
- [x] Integrated
- [x] Committed

## Dependencies
Depends on: {other rules}
Used by: {other rules}
```

## Rule Status Tracker

### Currently Implemented (7 rules) ✅

| Rule ID | Processor | Spec | Status |
|---------|-----------|------|--------|
| rule-xsd-cls-object-element | ObjectElementProcessor | ✓ | ✅ Complete |
| rule-xsd-cls-type | ComplexTypeProcessor | ✓ | ✅ Complete |
| rule-xsd-cls-sequence | SequenceProcessor | ✓ | ✅ Complete |
| rule-xsd-cls-standard-gml-property-types | PropertyTypeProcessor | ✓ | ✅ Complete |
| rule-xsd-prop-encode-properties | PropertyElementProcessor | ✓ | ✅ Complete |
| rule-xsd-cls-enum-object-element | EnumerationProcessor | ✓ | ✅ Complete |
| rule-xsd-cls-codelist-constraints | CodeListProcessor | ✓ | ✅ Complete |

### Must Implement Next (PLATEAU Requirements) - 20 rules

**Priority 1: Type System (5 rules)**

| Rule ID | Documentation | Java Source | Status |
|---------|---------------|-------------|--------|
| rule-xsd-cls-basictype | Non_Standard_Conversion_Rules.adoc | XsdDocument.java:pAnonymousBasicType | ⏳ TODO |
| rule-xsd-cls-union-as-choice | Non_Standard_Conversion_Rules.adoc | XsdDocument.java:pComplexType | ⏳ TODO |
| rule-xsd-cls-union-direct | Non_Standard_Conversion_Rules.adoc | XsdDocument.java:mapPropertyType | ⏳ TODO |
| rule-xsd-cls-local-basictype | Non_Standard_Conversion_Rules.adoc | XsdDocument.java:mapPropertyType | ⏳ TODO |
| rule-xsd-cls-local-enumeration | Non_Standard_Conversion_Rules.adoc | XsdDocument.java:mapPropertyType | ⏳ TODO |

**Priority 2: Property Encoding (7 rules)**

| Rule ID | Documentation | Java Source | Status |
|---------|---------------|-------------|--------|
| rule-xsd-prop-nillable | General_Conversion_Rules.adoc | XsdDocument.java:addProperty | ⏳ TODO |
| rule-xsd-prop-initialValue | General_Conversion_Rules.adoc | XsdDocument.java:addProperty | ⏳ TODO |
| rule-xsd-prop-inlineOrByReference | General_Conversion_Rules.adoc | XsdDocument.java:addAnonymousPropertyType | ⏳ TODO |
| rule-xsd-prop-length-size-pattern | General_Conversion_Rules.adoc | XsdDocument.java:addProperty | ⏳ TODO |
| rule-xsd-prop-constrainingFacets | Non_Standard_Conversion_Rules.adoc | XsdDocument.java:addProperty | ⏳ TODO |
| rule-xsd-prop-metadata | Non_Standard_Conversion_Rules.adoc | XsdDocument.java:addAnonymousPropertyType | ⏳ TODO |
| rule-xsd-prop-targetElement | General_Conversion_Rules.adoc | XsdDocument.java:addStandardAnnotation | ⏳ TODO |

**Priority 3: Advanced Features (5 rules)**

| Rule ID | Documentation | Java Source | Status |
|---------|---------------|-------------|--------|
| rule-xsd-cls-mixin-classes | General_Conversion_Rules.adoc | XsdDocument.java:addMixinProperties | ⏳ TODO |
| rule-xsd-cls-no-abstract-classes | General_Conversion_Rules.adoc | XsdDocument.java:pComplexType | ⏳ TODO |
| rule-xsd-cls-adehook | General_Conversion_Rules.adoc | XsdDocument.java:processLocalProperties | ⏳ TODO |
| rule-xsd-cls-byValuePropertyType | General_Conversion_Rules.adoc | XsdDocument.java:pPropertyTypes | ⏳ TODO |
| rule-xsd-prop-soft-typed | Non_Standard_Conversion_Rules.adoc | XsdDocument.java:addAnonymousPropertyType | ⏳ TODO |

**Priority 4: Naming & Documentation (3 rules)**

| Rule ID | Documentation | Java Source | Status |
|---------|---------------|-------------|--------|
| rule-xsd-all-naming-19139 | General_Conversion_Rules.adoc | XsdDocument.java:typeName | ⏳ TODO |
| rule-xsd-all-naming-swe | General_Conversion_Rules.adoc | XsdDocument.java:typeName | ⏳ TODO |
| rule-xsd-all-no-documentation | General_Conversion_Rules.adoc | XsdDocument.java:addStandardAnnotation | ⏳ TODO |

### Should Implement (Medium Priority) - 15 rules

| Rule ID | Category | Status |
|---------|----------|--------|
| rule-xsd-cls-noPropertyType | Class rules | ⏳ TODO |
| rule-xsd-cls-codelist-asDictionary | CodeList | ⏳ TODO |
| rule-xsd-cls-codelist-asDictionaryGml33 | CodeList | ⏳ TODO |
| rule-xsd-cls-enum-supertypes | Enumeration | ⏳ TODO |
| rule-xsd-cls-enum-subtypes | Enumeration | ⏳ TODO |
| rule-xsd-prop-reverseProperty | Property | ⏳ TODO |
| rule-xsd-prop-defaultCodeSpace | Property | ⏳ TODO |
| rule-xsd-prop-qualified-associations | Property | ⏳ TODO |
| rule-xsd-prop-gmlArrayProperty | Property | ⏳ TODO |
| rule-xsd-prop-gmlListProperty | Property | ⏳ TODO |
| rule-xsd-pkg-gmlProfileSchema | Package | ⏳ TODO |
| rule-xsd-pkg-dgiwgsp | Package | ⏳ TODO |
| rule-xsd-all-globalIdentifierAnnotation | Global | ⏳ TODO |
| rule-xsd-all-tagged-values | Global | ⏳ TODO |
| rule-xsd-cls-union-asGroup | Union | ⏳ TODO |

## Implementation Process Per Rule

**Example: rule-xsd-cls-basictype**

### 1. Research (Documents created for each rule)

**File**: `docs/rules/rule-xsd-cls-basictype.md`

```markdown
# Rule: rule-xsd-cls-basictype

## Documentation
Source: Non_Standard_Conversion_Rules.adoc
Description: Enables basic types with facet restrictions (length, pattern, range)

## Java Implementation
File: XsdDocument.java:1388-1588 (pAnonymousBasicType method)
Algorithm:
1. Read tagged values: base, length, pattern, rangeMinimum, rangeMaximum
2. Create simpleType or complexType based on typecontent
3. Add restriction element
4. Add facets based on supported facets for base type

## Our Implementation
Type: Processor Class (complex logic)
File: lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor.rb
Spec: spec/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor_spec.rb

## Test Cases
1. BasicType with length restriction
2. BasicType with pattern
3. BasicType with range (min/max)
4. Combined facets

## Status
- [ ] Documentation read
- [ ] Java analyzed
- [ ] Processor implemented
- [ ] Spec written
- [ ] Integrated
- [ ] Committed
```

### 2. Implementation

One class per rule, following template.

### 3. Testing

Comprehensive RSpec for each rule.

## Timeline for Complete Implementation

**Realistic Estimate**: 4-5 weeks (7 rules done, 53+ remaining)

**Week 1**: Must-have Priority 1 (5 rules) + Priority 2 (7 rules) = 12 rules
**Week 2**: Must-have Priority 3-4 (8 rules) + Start should-have = 8 rules
**Week 3**: Should-have rules (15 rules)
**Week 4**: Could-have rules + integration testing
**Week 5**: Validation, documentation, polish

## Success Criteria

For EACH rule:
✅ Documentation read and understood
✅ Java implementation located and analyzed
✅ Ruby processor implemented following OO principles
✅ Comprehensive spec written (5+ test cases)
✅ Integrated into processor pipeline
✅ Committed with semantic message

**This systematic approach ensures TRUE complete ShapeChange parity!**

**Planning document created**: 268 lines showing complete roadmap

Ready for systematic implementation in dedicated context!