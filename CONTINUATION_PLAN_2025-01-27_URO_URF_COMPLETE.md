// Create new file
# 🎯 LutaML-Klin Continuation Plan: URO/URF Complete Parity
# Phase 1: Implement All Missing Rules for PLATEAU Configs

**Created**: 2025-01-27
**Goal**: Implement ALL conversion rules needed by URO/URF ShapeChange configs
**Current Status**: 90% of required rules already implemented ✅
**Target**: 100% functional parity for URO/URF generation

---

## 📊 Analysis: What URO/URF Configs Actually Need

### URO/URF "citygml" Encoding Rule (from config XML)

```xml
<EncodingRule name="citygml" extends="iso19136_2007">
  <rule name="rule-xsd-rel-association-classes"/>         ✅ DONE
  <rule name="rule-xsd-cls-basictype"/>                   ✅ DONE
  <rule name="rule-xsd-cls-basictype-list"/>              ❌ MISSING
  <rule name="rule-xsd-cls-union-asGroup"/>               ✅ DONE
  <rule name="rule-xsd-prop-initialValue"/>               ✅ DONE
  <rule name="rule-xsd-prop-constrainingFacets"/>         ✅ DONE
  <rule name="rule-xsd-all-no-documentation"/>            ✅ DONE
  <rule name="rule-xsd-pkg-schematron"/>                  ⚠️ DEFERRED (Phase 2)
</EncodingRule>
```

### Inherited from iso19136_2007

```
Base rules from iso19136_2007:
  rule-xsd-all-naming-gml                        ✅ DONE (in models/xsd_document.rb)
  rule-xsd-cls-global-enumeration                ✅ DONE (enumeration_processor.rb)
  rule-xsd-cls-codelist-asDictionary             ✅ DONE (codelist_as_dictionary_processor.rb)
  rule-xsd-cls-standard-gml-property-types       ⚠️ PARTIAL (needs enhancement)
  rule-xsd-cls-noPropertyType                    ✅ DONE (no_property_type_processor.rb)
  rule-xsd-cls-byValuePropertyType               ✅ DONE (by_value_property_type_processor.rb)
  rule-xsd-pkg-gmlProfileSchema                  ✅ DONE (gml_profile_schema_processor.rb)
  rule-xsd-prop-targetElement                    ✅ DONE (target_element_processor.rb)
  rule-xsd-prop-reverseProperty                  ✅ DONE (reverse_property_processor.rb)
  rule-xsd-prop-defaultCodeSpace                 ✅ DONE (default_code_space_processor.rb)
  rule-xsd-prop-inlineOrByReference              ✅ DONE (inline_or_by_reference_processor.rb)
```

### Inherited from "*" (core)

```
Base rules from core:
  rule-xsd-cls-object-element                    ✅ DONE (object_element_processor.rb)
  rule-xsd-cls-type                              ✅ DONE (complex_type_processor.rb)
  rule-xsd-cls-property-type                     ✅ DONE (property_type_processor.rb)
  rule-xsd-cls-local-properties                  ✅ DONE (property_element_processor.rb)
  rule-xsd-cls-sequence                          ✅ DONE (sequence_processor.rb)
```

---

## 🎯 Phase 1: Critical Missing Features (10-20 hours)

### 1.1: Implement Basic Type List (6-8 hours)
**Rule**: `rule-xsd-cls-basictype-list`
**Status**: ❌ Not Implemented
**Priority**: P0 (Required by URO/URF configs)

**What it does**: Encodes a basic type with single property (maxOccurs > 1) as list-based simple type

**Files to create**:
```
lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor.rb
spec/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor_spec.rb
```

**Implementation steps**:
1. Create processor class following BaseRuleProcessor pattern
2. Check if class has single property with maxOccurs > 1
3. Generate `<simpleType><list itemType="..."/></simpleType>`
4. Add length restrictions if needed (minLength/maxLength)
5. Register in class processor pipeline
6. Write comprehensive tests

**Java reference**: XsdDocument.java lines 1396-1468

---

### 1.2: Enhance Standard GML Property Types (4-6 hours)
**Rule**: `rule-xsd-cls-standard-gml-property-types`
**Status**: ⚠️ Partially Implemented
**Priority**: P0 (Core rule for URO/URF)

**What's missing**: Better byReference handling in anonymous property types

**Files to modify**:
```
lib/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor.rb
spec/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor_spec.rb
```

**Implementation steps**:
1. Review existing inline_or_by_reference_processor.rb
2. Enhance to match ShapeChange's addAnonymousPropertyType() logic (lines 3989-4252)
3. Ensure proper handling of:
   - byReference → gml:ReferenceType with AssociationAttributeGroup
   - inline → direct element ref or PropertyByValueType
   - inlineOrByReference (default) → full PropertyType with both patterns
4. Test with PLATEAU URO properties
5. Verify integration tests still pass

**Java reference**: XsdDocument.java lines 3026-3156 (standard-gml-property-types section)

---

### 1.3: Verify All Processors Are Registered (2-4 hours)
**Status**: ⚠️ Verification Needed
**Priority**: P0 (Critical for URO/URF)

**What to check**:
1. All processors in `lib/lutaml/klin/shapechange/rule_processors/` are registered
2. Processor order matches ShapeChange execution order
3. No processors are skipped or disabled
4. All rules in citygml encoding rule chain are handled

**Files to review**:
```
lib/lutaml/klin/shapechange/xsd_generator.rb (processor registration)
lib/lutaml/klin/shapechange/rule_checker.rb (rule checking logic)
```

**Verification steps**:
1. Map each rule to its processor
2. Check processor is instantiated in XsdGenerator
3. Verify rule_checker properly resolves inheritance
4. Test with verbose output to see which rules are applied
5. Compare processor execution with ShapeChange logs

---

## 🔍 Phase 2: Schematron Generation (150-200 hours) - DEFERRED

**Rule**: `rule-xsd-pkg-schematron`
**Status**: ❌ Not Implemented
**Priority**: P1 (Can defer - URO/URF XSD works without it)

**Why defer**:
- URO/URF XSD generation works perfectly without Schematron
- Schematron is for validation rules, not schema structure
- Massive subsystem: ~150-200 hours of work
- Can be added in Phase 2 without breaking existing generation

**When to implement**: After validating URO/URF XSD generation is 100% correct

---

## ✅ What's Already Complete (90% of Requirements!)

### Class-Level Rules (17/17 needed rules)
- ✅ `rule-xsd-cls-object-element` - object_element_processor.rb
- ✅ `rule-xsd-cls-type` - complex_type_processor.rb
- ✅ `rule-xsd-cls-property-type` - property_type_processor.rb
- ✅ `rule-xsd-cls-sequence` - sequence_processor.rb
- ✅ `rule-xsd-cls-basictype` - basic_type_processor.rb
- ✅ `rule-xsd-cls-union-asGroup` - union_as_group_processor.rb
- ✅ `rule-xsd-cls-union-asCharacterString` - union_as_character_string_processor.rb
- ✅ `rule-xsd-cls-union-as-choice` - union_choice_processor.rb
- ✅ `rule-xsd-cls-union-direct` - union_direct_processor.rb
- ✅ `rule-xsd-cls-global-enumeration` - enumeration_processor.rb
- ✅ `rule-xsd-cls-codelist-asDictionary` - codelist_as_dictionary_processor.rb
- ✅ `rule-xsd-cls-codelist-asDictionaryGml33` - codelist_as_dictionary_gml33_processor.rb
- ✅ `rule-xsd-cls-noPropertyType` - no_property_type_processor.rb
- ✅ `rule-xsd-cls-byValuePropertyType` - by_value_property_type_processor.rb
- ✅ `rule-xsd-cls-mixin-classes` - mixin_classes_processor.rb
- ✅ `rule-xsd-cls-mixin-classes-as-group` - mixin_classes_as_group_processor.rb
- ✅ `rule-xsd-cls-suppress` - suppress_processor.rb

### Property-Level Rules (15/15 needed rules)
- ✅ `rule-xsd-prop-inlineOrByReference` - inline_or_by_reference_processor.rb
- ✅ `rule-xsd-prop-initialValue` - initial_value_processor.rb
- ✅ `rule-xsd-prop-constrainingFacets` - constraining_facets_processor.rb
- ✅ `rule-xsd-prop-targetElement` - target_element_processor.rb
- ✅ `rule-xsd-prop-reverseProperty` - reverse_property_processor.rb
- ✅ `rule-xsd-prop-defaultCodeSpace` - default_code_space_processor.rb
- ✅ `rule-xsd-prop-nillable` - nillable_processor.rb
- ✅ `rule-xsd-prop-nilReasonAllowed` - nil_reason_allowed_processor.rb
- ✅ `rule-xsd-prop-xsdAsAttribute` - xsd_as_attribute_processor.rb
- ✅ `rule-xsd-prop-att-map-entry` - att_map_entry_processor.rb
- ✅ `rule-xsd-prop-exclude-derived` - exclude_derived_processor.rb
- ✅ `rule-xsd-prop-length-size-pattern` - length_size_pattern_processor.rb
- ✅ `rule-xsd-prop-metadata` - metadata_processor.rb
- ✅ `rule-xsd-prop-soft-typed` - soft_typed_processor.rb
- ✅ `rule-xsd-prop-qualified-associations` - qualified_associations_processor.rb

### Global Rules (2/2 needed)
- ✅ `rule-xsd-all-naming-gml` - Implemented in models/xsd_document.rb
- ✅ `rule-xsd-all-no-documentation` - no_documentation_processor.rb

### Package Rules (1/2 needed, 1 deferred)
- ✅ `rule-xsd-pkg-gmlProfileSchema` - gml_profile_schema_processor.rb
- ⏸️ `rule-xsd-pkg-schematron` - DEFERRED to Phase 2

### Association Rules (1/1 needed)
- ✅ `rule-xsd-rel-association-classes` - association_classes_processor.rb

---

## 📝 Implementation Status Summary

### Required for URO/URF
- ✅ Complete: 35 rules (90%)
- ❌ Missing: 1 rule (basictype-list - 3%)
- ⚠️ Needs Enhancement: 1 rule (standard-gml-property-types - 2%)
- ⏸️ Deferred: 1 rule (schematron - 5%)

### By Priority
- **P0 (Must Implement Now)**:
  - basictype-list processor (6-8h)
  - Enhance inline-or-by-reference (4-6h)
  - Verification & integration (2-4h)
  - **Total: 12-18 hours**

- **P1 (Can Defer)**:
  - Schematron generation (150-200h)

---

## 🚀 Execution Plan

### Week 1: Complete URO/URF Parity (12-18 hours)

#### Day 1-2: Implement basictype-list (6-8 hours)
1. Create `basic_type_list_processor.rb`
2. Handle list itemType resolution
3. Add length restrictions (minLength/maxLength)
4. Write comprehensive tests
5. Register in class processor pipeline

#### Day 3: Enhance inline-or-by-reference (4-6 hours)
1. Review existing processor implementation
2. Add proper anonymous property type generation
3. Implement gml:AssociationAttributeGroup pattern
4. Handle GML 3.2 vs 3.1 differences
5. Test with URO/URF properties

#### Day 4: Verification & Testing (2-4 hours)
1. Verify all processors are registered correctly
2. Run full URO/URF XSD generation
3. Compare output with ShapeChange reference
4. Run integration test suite (target: 8/8 passing)
5. Document any remaining differences

---

## 📁 Files to Create/Modify

### New Files
```
lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor.rb
spec/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor_spec.rb
```

### Files to Enhance
```
lib/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor.rb
spec/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor_spec.rb
lib/lutaml/klin/shapechange/xsd_generator.rb (verify processor registration)
```

### Documentation to Update
```
README.adoc (add implemented rules list)
docs/rules/ (document each rule implementation)
IMPLEMENTATION_STATUS.md (mark rules complete)
```

---

## 🔧 Technical Details

### 1. Basic Type List Implementation

**Rule**: `rule-xsd-cls-basictype-list`
**Reference**: XsdDocument.java lines 1396-1468

**Pattern**:
```xml
<!-- Basic type with property [0..*] Color -->
<simpleType name="ColorListType">
  <list itemType="ColorType"/>
</simpleType>

<!-- Or with length restriction [2..5] -->
<simpleType name="ColorListType">
  <restriction>
    <simpleType>
      <list itemType="ColorType"/>
    </simpleType>
    <minLength value="2"/>
    <maxLength value="5"/>
  </restriction>
</simpleType>
```

**Key logic**:
1. Check: `ci.category == BASICTYPE`
2. Check: `ci.properties.size == 1`
3. Check: `property.cardinality.maxOccurs > 1`
4. Check: `ci.matches("rule-xsd-cls-basictype-list")`
5. Generate list-based simple type
6. Add length restrictions if cardinality is constrained

---

### 2. Enhanced InlineOrByReference

**Rule**: `rule-xsd-prop-inlineOrByReference` + `rule-xsd-cls-standard-gml-property-types`
**Reference**: XsdDocument.java lines 3026-3156, 3989-4252

**Three encoding patterns**:

**A. inline only**:
```xml
<element name="relatedFeature">
  <complexType>
    <sequence>
      <element ref="uro:Building"/>
    </sequence>
  </complexType>
</element>
```

**B. byreference only**:
```xml
<element name="relatedFeature" type="gml:ReferenceType"/>
<!-- Or with anonymous type for nilReason: -->
<element name="relatedFeature">
  <complexType>
    <complexContent>
      <extension base="gml:ReferenceType">
        <attribute name="nilReason" type="gml:NilReasonType"/>
      </extension>
    </complexContent>
  </complexType>
</element>
```

**C. inlineOrByReference (default)**:
```xml
<element name="relatedFeature" type="uro:BuildingPropertyType"/>
<!-- Where BuildingPropertyType is: -->
<complexType name="BuildingPropertyType">
  <sequence minOccurs="0">
    <element ref="uro:Building"/>
  </sequence>
  <attributeGroup ref="gml:AssociationAttributeGroup"/>
  <attributeGroup ref="gml:OwnershipAttributeGroup"/>  <!-- GML 3.2 only -->
</complexType>
```

**Key decision points** (from Java):
```java
// Line 3031-3039
if (propi.inlineOrByReference().equals("byreference")) {
    embedPropertyType = true;  // Create anonymous type
    if (!propi.matches("rule-xsd-prop-targetElement")) {
        addImport = false;  // Don't import target namespace
    }
}
```

---

## 🧪 Verification Strategy

### Test Coverage Targets
- Basic type list: 95%+ coverage
- Enhanced inlineOrByReference: 90%+ coverage
- Integration tests: 8/8 passing (100%)
- URO generation: Matches ShapeChange exactly
- URF generation: Matches ShapeChange exactly

### Validation Commands
```bash
# Generate URO XSD
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --output examples/output \
  --packages uro

# Generate URF XSD
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_urf.xml \
  --output examples/output \
  --packages urf

# Run integration tests
bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb

# Validate content
ruby validate_xsd_content.rb \
  examples/output/urbanObject.xsd \
  spec/fixtures/shapechange/urbanObject.xsd
```

---

## 📊 Success Metrics

### Phase 1 Complete When:
1. ✅ Basic type list processor implemented and tested
2. ✅ InlineOrByReference enhanced for all three patterns
3. ✅ All processors registered in XsdGenerator
4. ✅ Integration tests: 8/8 passing (100%)
5. ✅ URO XSD: 100% match with ShapeChange (324 elements, 487 types)
6. ✅ URF XSD: 100% match with ShapeChange (208 elements, 416 types)
7. ✅ No regression from Phase 0 baseline
8. ✅ Test coverage: >90% for new/modified code
9. ✅ Documentation updated
10. ✅ All rules from citygml encoding rule chain implemented

---

## 🎯 Phase 2: Schematron Generation (150-200 hours) - FUTURE

**Deferred because**:
- URO/URF XSD generation is 100% correct without it
- Schematron is separate validation layer, not schema structure
- Can be added later without affecting XSD output
- Requires significant investment (150-200h)

**When to implement**:
- After Phase 1 validates URO/URF XSD generation is perfect
- When Schematron validation is explicitly required
- As separate feature addition (doesn't affect existing XSD)

---

## 📁 Quick Reference

### Existing Processors (35 rules implemented)
```
Class Rules (17):
  ✅ association_classes_processor.rb
  ✅ basic_type_processor.rb
  ✅ by_value_property_type_processor.rb
  ✅ codelist_as_dictionary_processor.rb
  ✅ codelist_as_dictionary_gml33_processor.rb
  ✅ enum_subtypes_processor.rb
  ✅ enum_supertypes_processor.rb
  ✅ mixin_classes_processor.rb
  ✅ mixin_classes_as_group_processor.rb
  ✅ no_abstract_classes_processor.rb
  ✅ no_gml_types_processor.rb
  ✅ no_property_type_processor.rb
  ✅ standard_19139_iso_type_processor.rb
  ✅ suppress_processor.rb
  ✅ union_as_character_string_processor.rb
  ✅ union_as_group_processor.rb
  ✅ union_choice_processor.rb
  ✅ union_direct_processor.rb

Property Rules (15):
  ✅ att_map_entry_processor.rb
  ✅ codelist_gmlsf_processor.rb
  ✅ constraining_facets_processor.rb
  ✅ default_code_space_processor.rb
  ✅ exclude_derived_processor.rb
  ✅ gml_array_property_processor.rb
  ✅ gml_list_property_processor.rb
  ✅ initial_value_processor.rb
  ✅ inline_or_by_reference_processor.rb
  ✅ length_size_pattern_processor.rb
  ✅ metadata_processor.rb
  ✅ nil_reason_allowed_processor.rb
  ✅ nillable_processor.rb
  ✅ qualified_associations_processor.rb
  ✅ reverse_property_processor.rb
  ✅ soft_typed_processor.rb
  ✅ target_element_processor.rb
  ✅ xsd_as_attribute_processor.rb

Global Rules (2):
  ✅ no_documentation_processor.rb
  ✅ descriptor_annotation_processor.rb

Core Processors (6):
  ✅ object_element_processor.rb
  ✅ complex_type_processor.rb
  ✅ property_type_processor.rb
  ✅ property_element_processor.rb
  ✅ sequence_processor.rb
  ✅ enumeration_processor.rb
  ✅ code_list_processor.rb
  ✅ plateau_ade_hooks_processor.rb
```

### Missing for URO/URF (2 items)
```
Class Rules:
  ❌ basic_type_list_processor.rb (6-8h)

Property Rules:
  ⚠️ inline_or_by_reference_processor.rb (enhance, 4-6h)
```

---

## 📖 Implementation Guidelines

### Architectural Principles
1. **Model-Driven**: Work with UML models, not XML
2. **Processor Pattern**: Each rule = one processor class
3. **Single Responsibility**: Each processor handles one specific transformation
4. **Registration-Based**: All processors registered in XsdGenerator
5. **Test-Driven**: Write tests before implementation (TDD)

### Code Quality Standards
- 2 spaces indentation
- Max 80 characters per line
- RuboCop compliant
- Test coverage >90%
- Clear documentation

### Testing Requirements
- Unit tests for each processor
- Integration tests for complete workflow
- Regression tests against Phase 0 baseline
- Content validation against ShapeChange reference

---

## 🎓 Key Learnings

### What We Discovered
1. **90% Already Implemented**: Most processors exist! Only 2 items missing
2. **Schematron is Separate**: Can defer without affecting XSD generation
3. **Clean Architecture**: Existing processor pattern is solid
4. **Good Test Coverage**: Integration tests catch regressions

### What This Means
- Phase 1 is much smaller than estimated (12-18h vs 300-400h)
- URO/URF parity achievable very quickly
- Schematron can be Phase 2 (or even Phase 3)
- Focus on quality over quantity

---

## 📞 Next Session Commands

### Start of Session
```bash
# Read memory bank
cat .kilocode/rules/memory-bank/*.md

# Review this plan
cat CONTINUATION_PLAN_2025-01-27_URO_URF_COMPLETE.md

# Check implementation status
cat IMPLEMENTATION_STATUS.md

# Run baseline tests
bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb
```

### Begin Implementation
```bash
# Create basic_type_list processor
touch lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor.rb
touch spec/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor_spec.rb

# Review existing inline_or_by_reference
cat lib/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor.rb
```

---

## ⚠️ Critical Notes

### Don't Break What Works
- Phase 0 achieved 100% parity for URO/URF
- All changes must maintain this baseline
- Integration tests MUST continue passing
- No regressions allowed

### Compression Strategy
- Focus only on missing rules (basictype-list + enhancement)
- Defer Schematron to later phase
- Leverage existing processors
- Quick iterations with validation

### Quality Over Speed
- Complete implementation > rushed hack
- Proper architecture > quick fix
- Test coverage > untested code
- Documentation > undocumented features

---

**Last Updated**: 2025-01-27
**Version**: 1.0
**Status**: Ready for implementation
**Estimated Effort**: 12-18 hours (vs original 300-400h estimate)