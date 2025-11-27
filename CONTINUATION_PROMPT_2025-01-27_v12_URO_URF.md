// Create new file
# 🎯 LutaML-Klin Continuation Prompt v12: URO/URF Complete Parity

**Date**: 2025-01-27
**Session**: Transition to URO/URF Rule Completion
**Major Discovery**: 90% of required rules already implemented!

---

## 🎉 Key Discovery: Massive Scope Reduction

### What We Learned
After analyzing the actual URO/URF ShapeChange configs:
- **Required rules**: 37 total (not 100+ as originally thought)
- **Already implemented**: 35 rules (90%!)
- **Missing**: 2 items (basictype-list + enhancement)
- **Revised estimate**: 12-18 hours (vs 300-400h original)

### Why This Changes Everything
The comprehensive processor architecture from Phase 0 means:
- Adding new rules is straightforward (existing pattern)
- Most processors already exist
- Only 2 specific items needed for 100% parity
- Schematron can be deferred (separate validation layer)

---

## 📋 Current Status: 90% Complete

### What's Done ✅
- **Phase 0**: 100% parity for URO/URF structure (324+208 elements)
- **35 Processors**: All major conversion rules implemented
- **Integration Tests**: 7/8 passing (87.5%)
- **Architecture**: Clean processor pattern established

### What's Missing ❌
1. **Basic Type List Processor** (6-8h)
   - Rule: `rule-xsd-cls-basictype-list`
   - Location: Need to create

2. **InlineOrByReference Enhancement** (4-6h)
   - Rule: `rule-xsd-cls-standard-gml-property-types` (partial)
   - Location: `inline_or_by_reference_processor.rb` exists, needs enhancement

### What's Deferred ⏸️
1. **Schematron Generation** (150-200h)
   - Rule: `rule-xsd-pkg-schematron`
   - Reason: URO/URF XSD works perfectly without it
   - When: Phase 2 after validating XSD generation

---

## 🎯 Immediate Tasks (12-18 hours total)

### Task 1: Implement Basic Type List  (6-8 hours)

**What it does**: Encodes basic type with single property [1..*] as list-based simpleType

**Example**:
```xml
<!-- UML: BasicType ColorList with property colors: Color [0..*] -->
<simpleType name="ColorListType">
  <list itemType="ColorType"/>
</simpleType>

<!-- Or with length restriction [2..5]: -->
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

**Implementation steps**:
1. Create `lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor.rb`
2. Check: class category == BASICTYPE
3. Check: properties.size == 1
4. Check: property maxOccurs > 1
5. Generate list-based simpleType
6. Add length restrictions if cardinality constrained
7. Write tests in `spec/.../basic_type_list_processor_spec.rb`
8. Register in XsdGenerator processor pipeline

**Java reference**: [`XsdDocument.java`](reference/shapechange-sources/de/interactive_instruments/ShapeChange/Target/XmlSchema/XsdDocument.java:1396-1468)

---

### Task 2: Enhance InlineOrByReference (4-6 hours)

**What's needed**: Full anonymous property type generation for all three patterns

**The three patterns**:

**A. inline="inline"**:
```xml
<element name="relatedBuilding">
  <complexType>
    <sequence>
      <element ref="uro:Building"/>
    </sequence>
  </complexType>
</element>
```

**B. inlineOrByReference="byreference"**:
```xml
<element name="relatedBuilding" type="gml:ReferenceType"/>
<!-- Or with nilReason: -->
<element name="relatedBuilding">
  <complexType>
    <complexContent>
      <extension base="gml:ReferenceType">
        <attribute name="nilReason" type="gml:NilReasonType"/>
      </extension>
    </complexContent>
  </complexType>
</element>
```

**C. inlineOrByReference (default/both)**:
```xml
<element name="relatedBuilding" type="uro:BuildingPropertyType"/>
<!-- Where BuildingPropertyType is the standard PropertyType: -->
<complexType name="BuildingPropertyType">
  <sequence minOccurs="0">
    <element ref="uro:Building"/>
  </sequence>
  <attributeGroup ref="gml:AssociationAttributeGroup"/>
  <attributeGroup ref="gml:OwnershipAttributeGroup"/>  <!-- GML 3.2 -->
</complexType>
```

**Implementation steps**:
1. Review existing `inline_or_by_reference_processor.rb`
2. Add anonymous property type generation logic
3. Implement three pattern decision tree
4. Handle special attributes (nilReason, metadata, qualifiers)
5. Add gml:AssociationAttributeGroup for byReference
6. Add gml:OwnershipAttributeGroup for GML 3.2
7. Test all three patterns
8. Verify URO/URF properties encode correctly

**Java reference**: [`XsdDocument.java`](reference/shapechange-sources/de/interactive_instruments/ShapeChange/Target/XmlSchema/XsdDocument.java:3026-3156) and lines 3989-4252

---

### Task 3: Verification & Testing (2-4 hours)

**Checklist**:
1. Verify all processors registered in [`XsdGenerator`](lib/lutaml/klin/shapechange/xsd_generator.rb:280-292)
2. Check processor execution order
3. Run URO generation → validate against reference
4. Run URF generation → validate against reference
5. Run integration tests → target 8/8 passing
6. Document any differences
7. Update README.adoc

---

## 📁 Key Files Reference

### Planning Documents
- **[`CONTINUATION_PLAN_2025-01-27_URO_URF_COMPLETE.md`](CONTINUATION_PLAN_2025-01-27_URO_URF_COMPLETE.md:1)** - Detailed implementation plan
- **[`IMPLEMENTATION_STATUS_URO_URF.md`](IMPLEMENTATION_STATUS_URO_URF.md:1)** - This status tracker
- [`.kilocode/rules/memory-bank/context.md`](.kilocode/rules/memory-bank/context.md:1) - Current context

### Configuration Files
- [`examples/ShapeChangeConfig_Plateau_uro.xml`](examples/ShapeChangeConfig_Plateau_uro.xml:1) - URO config (citygml encoding)
- [`examples/ShapeChangeConfig_Plateau_urf.xml`](examples/ShapeChangeConfig_Plateau_urf.xml:1) - URF config (citygml encoding)
- [`reference/shapechange-configs/StandardRules.xml`](reference/shapechange-configs/StandardRules.xml:1) - Standard encoding rules

### Core Implementation
- [`lib/lutaml/klin/shapechange/xsd_generator.rb`](lib/lutaml/klin/shapechange/xsd_generator.rb:1) - Main orchestrator
- [`lib/lutaml/klin/shapechange/rule_registry.rb`](lib/lutaml/klin/shapechange/rule_registry.rb:1) - Rule management
- [`lib/lutaml/klin/shapechange/base_encoding_rules.rb`](lib/lutaml/klin/shapechange/base_encoding_rules.rb:1) - Fallback rules

### Existing Processors (35 implemented)
```
Class Rules (17): ✅ All needed rules exist except basictype-list
  association_classes, basic_type, by_value_property_type,
  codelist_as_dictionary, codelist_as_dictionary_gml33,
  enum_subtypes, enum_supertypes, mixin_classes,
  mixin_classes_as_group, no_abstract_classes, no_gml_types,
  no_property_type, standard_19139_iso_type, suppress,
  union_as_character_string, union_as_group, union_choice,
  union_direct

Property Rules (15): ✅ All needed rules exist, 2 need enhancement
  att_map_entry, codelist_gmlsf, constraining_facets,
  default_code_space, exclude_derived, gml_array_property,
  gml_list_property, initial_value, inline_or_by_reference,
  length_size_pattern, metadata, nil_reason_allowed,
  nillable, qualified_associations, reverse_property,
  soft_typed, target_element, xsd_as_attribute

Core Processors (8): ✅ All complete
  object_element, complex_type, property_type,
  property_element, sequence, enumeration,
  code_list, plateau_ade_hooks
```

### Reference XSD Files
- [`spec/fixtures/shapechange/urbanObject.xsd`](spec/fixtures/shapechange/urbanObject.xsd:1) - URO reference (324 elements)
- [`spec/fixtures/shapechange/urbanFunction.xsd`](spec/fixtures/shapechange/urbanFunction.xsd:1) - URF reference (208 elements)

---

## 🔧 Implementation Pattern

### How to Add a New Processor

```ruby
# 1. Create processor class
module Lutaml::Klin::Shapechange::RuleProcessors::ClassRules
  class BasicTypeListProcessor < BaseRuleProcessor
    RULE_ID = "rule-xsd-cls-basictype-list"

    def self.applies_to?(uml_class, config)
      # Check if rule applies
    end

    def process(uml_class, context)
      return unless self.class.applies_to?(uml_class, @config)
      # Generate XSD
    end
  end
end

# 2. Write tests
RSpec.describe BasicTypeListProcessor do
  describe ".applies_to?" do
    # Test rule applicability
  end

  describe "#process" do
    # Test XSD generation
  end
end

# 3. Register in XsdGenerator
processors = [
  # ... existing processors ...
  RuleProcessors::ClassRules::BasicTypeListProcessor.new(rule_checker, config),
]
```

---

## 📊 Validation Results (Current)

### URO Package (Urban Object)
```
✅ Top-level elements: 324/324 (100%)
✅ Complex types: 487/487 (100%)
✅ SubstitutionGroups: 224/224 (100%)
✅ Base types: 132/132 (100%)
✅ Namespaces: Correct
✅ Content: Perfect match
```

### URF Package (Urban Function)
```
✅ Top-level elements: 208/208 (100%)
✅ Complex types: 416/416 (100%)
✅ SubstitutionGroups: 166/166 (100%)
✅ Base types: 166/166 (100%)
✅ Namespaces: Correct
✅ Content: Perfect match
```

**Note**: These results are with current implementation (90% complete). Goal is to maintain this 100% match after adding missing 10%.

---

## 🎓 Architecture Principles

### Processor Pattern
- One processor per conversion rule
- Inherit from BaseRuleProcessor
- Register in XsdGenerator pipeline
- Process in correct order
- Return early if rule doesn't apply

### Model-Driven Design
- Work with UML model objects
- Never manipulate XML directly
- XsdDocument is the only XML builder
- Context object carries state

### Testing Strategy
- Write tests first (TDD)
- Unit tests for each processor
- Integration tests for complete workflow
- Content validation against ShapeChange
- No regressions allowed

---

## 🚀 How to Start Next Session

### 1. Read Context
```bash
cd /Users/mulgogi/src/lutaml/lutaml-klin

# Read memory bank
cat .kilocode/rules/memory-bank/context.md
cat .kilocode/rules/memory-bank/architecture.md

# Read continuation plan
cat CONTINUATION_PLAN_2025-01-27_URO_URF_COMPLETE.md

# Check status
cat IMPLEMENTATION_STATUS_URO_URF.md
```

### 2. Run Baseline Tests
```bash
# Verify current state
bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb --format progress

# Expected: 7/8 tests passing (87.5%)
```

### 3. Begin Task 1: Basic Type List
```bash
# Create processor file
touch lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor.rb

# Create test file
touch spec/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor_spec.rb

# Review Java reference
cat reference/shapechange-sources/de/interactive_instruments/ShapeChange/Target/XmlSchema/XsdDocument.java | grep -A 100 "rule-xsd-cls-basictype-list"
```

### 4. Or Begin Task 2: Enhance InlineOrByReference
```bash
# Review existing implementation
cat lib/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor.rb

# Review Java reference
cat reference/shapechange-sources/de/interactive_instruments/ShapeChange/Target/XmlSchema/XsdDocument.java | sed -n '3026,3156p'
```

---

## 📚 Required Reading

### Before Starting Implementation
1. **[`CONTINUATI ON_PLAN_2025-01-27_URO_URF_COMPLETE.md`](CONTINUATION_PLAN_2025-01-27_URO_URF_COMPLETE.md:1)**
   - Complete phase 1 plan
   - Technical details for each task
   - Success metrics

2. **[`IMPLEMENTATION_STATUS_URO_URF.md`](IMPLEMENTATION_STATUS_URO_URF.md:1)**
   - Current implementation status
   - Rule-by-rule breakdown
   - Progress tracking

3. **Memory Bank**:
   - [`.kilocode/rules/memory-bank/architecture.md`](.kilocode/rules/memory-bank/architecture.md:1) - System architecture
   - [`.kilocode/rules/memory-bank/context.md`](.kilocode/rules/memory-bank/context.md:1) - Current context

### For Implementation
1. **ShapeChange Java Source**:
   - [`XsdDocument.java`](reference/shapechange-sources/de/interactive_instruments/ShapeChange/Target/XmlSchema/XsdDocument.java:1) - Main reference
   - Lines 1396-1468: basictype-list
   - Lines 3026-3156: standard-gml-property-types
   - Lines 3989-4252: addAnonymousPropertyType

2. **Existing Processors** (for pattern reference):
   - [`basic_type_processor.rb`](lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor.rb:1)
   - [`inline_or_by_reference_processor.rb`](lib/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor.rb:1)

---

## 🎯 Success Criteria

### Code Complete When:
1. ✅ Basic type list processor implemented and tested
2. ✅ InlineOrByReference handles all three patterns
3. ✅ All processors registered in XsdGenerator
4. ✅ Test coverage >90% for new/modified code
5. ✅ RuboCop passes with no warnings

### Functional Complete When:
1. ✅ URO XSD: 324/324 elements, 487/487 types (maintain)
2. ✅ URF XSD: 208/208 elements, 416/416 types (maintain)
3. ✅ Content validation: 100% match (maintain)
4. ✅ Integration tests: 8/8 passing (100%)
5. ✅ No performance regression

### Documentation Complete When:
1. ✅ README.adoc updated with rule implementations
2. ✅ Each new rule documented in docs/rules/
3. ✅ Memory bank context.md updated
4. ✅ Old continuation plans moved to old-docs/

---

## 📝 Commits and Documentation Tasks

### After Task 1 (Basic Type List)
```bash
# Commit
git add lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor.rb \
        spec/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor_spec.rb \
        lib/lutaml/klin/shapechange/xsd_generator.rb
git commit -m "feat(rules): add rule-xsd-cls-basictype-list processor

Implements list-based simple type encoding for basic types with
single property having maxOccurs > 1. Includes length restrictions
based on property cardinality.

Completes URO/URF config requirements for basic type handling."
```

### After Task 2 (InlineOrByReference)
```bash
# Commit
git add lib/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor.rb \
        spec/lutaml/klin/shapechange/rule_processors/property_rules/inline_or_by_reference_processor_spec.rb
git commit -m "feat(rules): enhance rule-xsd-prop-inlineOrByReference

Implements complete anonymous property type generation for all three
encoding patterns: inline, byreference, and inlineOrByReference.

Adds proper gml:AssociationAttributeGroup and gml:OwnershipAttributeGroup
handling for GML 3.2 standard property types.

Completes rule-xsd-cls-standard-gml-property-types implementation."
```

### After Verification
```bash
# Update documentation
git add README.adoc IMPLEMENTATION_STATUS_URO_URF.md \
        .kilocode/rules/memory-bank/context.md
git commit -m "docs: update for URO/URF complete parity

All required rules for PLATEAU URO/URF ShapeChange configs now
implemented. Integration tests pass 8/8. XSD output matches
ShapeChange reference 100%."
```

### Archive Old Docs
```bash
# Move outdated continuation plans
mkdir -p old-docs/continuation-plans
mv CONTINUATION_PLAN_2025-01-24*.md old-docs/continuation-plans/
mv CONTINUATION_PROMPT_2025-01-*.md old-docs/continuation-plans/
mv CONTINUATION_PLAN.md old-docs/continuation-plans/
mv IMPLEMENTATION_STATUS_2025-*.md old-docs/continuation-plans/

git add old-docs/ CONTINUATION_PLAN* CONTINUATION_PROMPT* IMPLEMENTATION_STATUS*
git commit -m "chore: archive old continuation plans

Moved outdated planning documents to old-docs/continuation-plans/.
Current plans: CONTINUATION_PLAN_2025-01-27_URO_URF_COMPLETE.md"
```

---

## 🎯 Decision Tree: Which Task First?

### Option A: Start with Basic Type List (RECOMMENDED)
**Why**:
- Completely new processor (clean slate)
- Clear requirements (list-based simpleType)
- No conflicts with existing code
- Can implement and test independently
- Builds confidence with processor pattern

**Estimated**: 6-8 hours
**Difficulty**: Medium (straightforward pattern)

### Option B: Start with InlineOrByReference Enhancement
**Why**:
- More complex (modifying existing processor)
- Requires understanding current implementation
- Higher risk of regression
- More testing needed
- Bigger impact on URO/URF properties

**Estimated**: 4-6 hours
**Difficulty**: Hard (must preserve existing behavior)

### Recommended: A → B → Verification
1. Implement basic type list (clean, self-contained)
2. Enhance inline or by reference (building on success)
3. Verify and test (ensure everything works together)

---

## 🛠️ Quick Reference Commands

### Development
```bash
# Run specific test
bundle exec rspec spec/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_list_processor_spec.rb

# Run all processor tests
bundle exec rspec spec/lutaml/klin/shapechange/rule_processors/

# Run integration tests
bundle exec rspec spec/integration/

# Lint
bundle exec rubocop -A
```

### Debugging
```bash
# Generate with verbose output
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --output examples/output --packages uro \
  --verbose

# Check which processors are registered
grep "new(rule_checker, config)" lib/lutaml/klin/shapechange/xsd_generator.rb
```

### Validation
```bash
# Compare XSD structure
diff -u <(xmllint --format spec/fixtures/shapechange/urbanObject.xsd) \
        <(xmllint --format examples/output/urbanObject.xsd)

# Count elements/types
xmllint --xpath 'count(//xs:element[@name])' examples/output/urbanObject.xsd
xmllint --xpath 'count(//xs:complexType[@name])' examples/output/urbanObject.xsd
```

---

## ⚠️ Critical Reminders

### Maintain Phase 0 Baseline
- Phase 0 achieved 100% structural parity
- All Phase 0 tests MUST continue passing
- No breaking changes to existing processors
- Performance must not regress

### Follow Architectural Principles
- Model-driven (not XML-driven)
- Processor pattern for all rules
- Single responsibility per processor
- Registration-based execution
- Test-driven development (TDD)

### Code Quality Standards
- 2 spaces indentation, 80 char lines
- RuboCop compliant
- >90% test coverage
- Clear documentation
- Semantic commit messages

### Don't Over-Engineer
- Focus on URO/URF requirements only
- Don't implement rules not in configs
- Don't optimize prematurely
- Keep it simple and clear

---

## 🎉 What This Means

### Timeline Compression
- **Original Phase 1 estimate**: 300-400 hours
- **Actual remaining work**: 12-18 hours
- **Time saved**: ~280+ hours
- **Completion**: 1-2 weeks instead of 3-4 months

### Quality Validation
- Phase 0 architecture was excellent
- Processor pattern scales beautifully
- Clean separation of concerns
- Easy to add new rules

### Path Forward
- Complete URO/URF parity quickly (12-18h)
- Validate with real PLATEAU data
- Document thoroughly
- Plan Phase 2 (Schematron) properly

---

## 📖 Appendix: Rule-to-Processor Mapping

### Class Rules (18 total, 17 done, 1 missing)
```
✅ rule-xsd-rel-association-classes          → association_classes_processor.rb
✅ rule-xsd-cls-object-element               → object_element_processor.rb
✅ rule-xsd-cls-type                         → complex_type_processor.rb
✅ rule-xsd-cls-property-type                → property_type_processor.rb
✅ rule-xsd-cls-sequence                     → sequence_processor.rb
✅ rule-xsd-cls-basictype                    → basic_type_processor.rb
❌ rule-xsd-cls-basictype-list               → NEEDS IMPLEMENTATION
✅ rule-xsd-cls-union-asGroup                → union_as_group_processor.rb
✅ rule-xsd-cls-union-asCharacterString      → union_as_character_string_processor.rb
✅ rule-xsd-cls-union-as-choice              → union_choice_processor.rb
✅ rule-xsd-cls-union-direct                 → union_direct_processor.rb
✅ rule-xsd-cls-global-enumeration           → enumeration_processor.rb
✅ rule-xsd-cls-codelist-asDictionary        → codelist_as_dictionary_processor.rb
✅ rule-xsd-cls-noPropertyType               → no_property_type_processor.rb
✅ rule-xsd-cls-byValuePropertyType          → by_value_property_type_processor.rb
✅ rule-xsd-cls-mixin-classes                → mixin_classes_processor.rb
✅ rule-xsd-cls-mixin-classes-as-group       → mixin_classes_as_group_processor.rb
✅ rule-xsd-cls-suppress                     → suppress_processor.rb
```

### Property Rules (15 total, all exist, 2 need enhancement)
```
⚠️ rule-xsd-prop-inlineOrByReference         → inline_or_by_reference_processor.rb (ENHANCE)
✅ rule-xsd-prop-initialValue                → initial_value_processor.rb
✅ rule-xsd-prop-constrainingFacets          → constraining_facets_processor.rb
✅ rule-xsd-prop-targetElement               → target_element_processor.rb
✅ rule-xsd-prop-reverseProperty             → reverse_property_processor.rb
✅ rule-xsd-prop-defaultCodeSpace            → default_code_space_processor.rb
✅ rule-xsd-prop-nillable                    → nillable_processor.rb
✅ rule-xsd-prop-nilReasonAllowed            → nil_reason_allowed_processor.rb
✅ rule-xsd-prop-xsdAsAttribute              → xsd_as_attribute_processor.rb
✅ rule-xsd-prop-att-map-entry               → att_map_entry_processor.rb
✅ rule-xsd-prop-exclude-derived             → exclude_derived_processor.rb
✅ rule-xsd-prop-length-size-pattern         → length_size_pattern_processor.rb
✅ rule-xsd-prop-metadata                    → metadata_processor.rb
✅ rule-xsd-prop-soft-typed                  → soft_typed_processor.rb
✅ rule-xsd-prop-qualified-associations      → qualified_associations_processor.rb
⚠️ rule-xsd-cls-standard-gml-property-types  → inline_or_by_reference_processor.rb (ENHANCE)
```

### Global Rules (2 total, all done)
```
✅ rule-xsd-all-naming-gml                   → models/xsd_document.rb (naming logic)
✅ rule-xsd-all-no-documentation             → no_documentation_processor.rb
```

---

## 🔍 Where to Focus

### Highest Impact
1. **Basic Type List**: Required by config, not implemented
2. **InlineOrByReference**: Core rule, needs enhancement
3. **Verification**: Ensure no regressions

### Don't Waste Time On
1. Schematron (deferred to Phase 2)
2. Rules not in URO/URF configs
3. Over-optimization
4. Premature abstractions

---

**Last Updated**: 2025-01-27
**For**: Next coding session
**Version**: 12
**Goal**: Achieve 100% URO/URF parity in 12-18 hours