# Continuation Plan: ShapeChange Advanced Features Implementation

**Date**: 2025-01-27
**Version**: 1.0
**Status**: Ready to begin
**Estimated Total Effort**: 800-1,000 hours (6-8 months full-time)

---

## Current Status

### ✅ Completed (Phase 0: Foundation)
- 100% structural parity with ShapeChange for URO/URF packages
- 100% content parity (324/324 URO elements, 208/208 URF elements)
- Default XML Schema namespace implementation
- Config-driven class selection via `appSchemaName`
- UML model as source of truth (no hardcoded lists)
- Basic GML 3.2 encoding (~18-20% of full ShapeChange functionality)
- Automated integration tests (7/8 passing)
- Performance: <100ms LUR loading, ~5-10s XSD generation per package

### 📊 Current Implementation Coverage
- **Object element generation** ✅ (`rule-xsd-cls-object-element`)
- **ComplexType generation** ✅ (`rule-xsd-cls-type`)
- **Property element encoding** ✅ (`rule-xsd-prop-inlineOrByReference` - basic)
- **Multiplicity handling** ✅ (`minOccurs`, `maxOccurs`)
- **Type inheritance** ✅ (`extension` with `base`)
- **PropertyType wrappers** ✅ (`rule-xsd-cls-propertyType`)
- **Default namespace** ✅ (no `xs:` prefix)
- **SubstitutionGroup support** ✅
- **Custom ADE hooks** ✅ (PLATEAU-specific)

---

## Implementation Roadmap

### Phase 1: Must-Have Features (P0) - 300-400 hours

**Goal**: Achieve 50-60% ShapeChange functionality for real-world PLATEAU/CityGML projects

**Priority**: Critical for production use

#### 1.1: Advanced Property Types (100-120 hours)

**Standard GML Property Types** (`rule-xsd-cls-standard-gml-property-types`):
- [ ] Implement `ByReferencePropertyType` pattern
  - Input: UML class with property
  - Output: `<complexType>` with `gml:AssociationAttributeGroup`
  - Files: `lib/lutaml/klin/rule_processors/property_rules/by_reference_processor.rb`
  - Tests: `spec/lutaml/klin/rule_processors/by_reference_processor_spec.rb`
  - Estimate: 15-20 hours

- [ ] Implement inline property encoding
  - Already partially done, needs completion
  - Handle `nillable` attribute
  - Handle `nilReason` attribute
  - Files: Update `property_element_processor.rb`
  - Estimate: 10-15 hours

- [ ] Implement array properties (`gml:ArrayAssociationType`)
  - Pattern: Property with `maxOccurs > 1`
  - Output: Array wrapper type
  - Files: `lib/lutaml/klin/rule_processors/property_rules/array_property_processor.rb`
  - Estimate: 20-25 hours

**ISO 19139 Property Types** (`rule-xsd-cls-standard-19139-property-types`):
- [ ] Implement metadata property patterns
  - CharacterString, DateTime, Real properties
  - Files: `lib/lutaml/klin/rule_processors/property_rules/iso19139_processor.rb`
  - Estimate: 20-25 hours

**SWE Common Property Types** (`rule-xsd-cls-standard-swe-property-types`):
- [ ] Implement SWE Common patterns
  - Quantity, Category, Text properties
  - Files: `lib/lutaml/klin/rule_processors/property_rules/swe_common_processor.rb`
  - Estimate: 20-25 hours

#### 1.2: Code List Support (60-80 hours)

**Code List as Dictionary** (`rule-xsd-cls-codelist-asDictionary`):
- [ ] Implement code list dictionary generation
  - Input: UML Enumeration with `<<CodeList>>` stereotype
  - Output: `<complexType>` with `gml:CodeType` base
  - Dictionary XML generation (separate file)
  - Files: `lib/lutaml/klin/rule_processors/class_rules/codelist_dictionary_processor.rb`
  - Tests: `spec/lutaml/klin/rule_processors/codelist_dictionary_processor_spec.rb`
  - Estimate: 30-35 hours

**Code List Validation** (`rule-xsd-cls-codelist-asDictionaryGml33`):
- [ ] Add GML 3.3 code list validation
  - CodeSpace and codeListValue attributes
  - Files: Update codelist processor
  - Estimate: 20-25 hours

**GMLSF Code Lists** (`rule-xsd-cls-codelist-gmlsf`):
- [ ] Implement GMLSF simplified profiles
  - Files: `lib/lutaml/klin/rule_processors/class_rules/codelist_gmlsf_processor.rb`
  - Estimate: 10-15 hours

#### 1.3: Union Type Handling (60-80 hours)

**Union as Choice** (`rule-xsd-cls-union-as-choice`):
- [ ] Implement `<xs:choice>` generation for unions
  - Input: UML class with `<<Union>>` stereotype
  - Output: `<xs:complexType>` with `<xs:choice>` content model
  - Files: `lib/lutaml/klin/rule_processors/class_rules/union_choice_processor.rb`
  - Tests: `spec/lutaml/klin/rule_processors/union_choice_processor_spec.rb`
  - Estimate: 25-30 hours

**Union as CharacterString** (`rule-xsd-cls-union-asCharacterString`):
- [ ] Implement string union fallback
  - For unions that can' be choice
  - Files: `lib/lutaml/klin/rule_processors/class_rules/union_string_processor.rb`
  - Estimate: 15-20 hours

**Union Direct** (`rule-xsd-cls-union-direct`):
- [ ] Implement `<xs:union>` generation
  - Files: `lib/lutaml/klin/rule_processors/class_rules/union_direct_processor.rb`
  - Estimate: 20-25 hours

#### 1.4: Mixin Support (40-60 hours)

**Mixin Classes as Group** (`rule-xsd-cls-mixin-classes-as-group`):
- [ ] Implement `<xs:group>` generation for mixins
  - Input: UML class with `<<Mixin>>` stereotype
  - Output: `<xs:group>` definition
  - Include group in target classes
  - Files: `lib/lutaml/klin/rule_processors/class_rules/mixin_group_processor.rb`
  - Tests: `spec/lutaml/klin/rule_processors/mixin_group_processor_spec.rb`
  - Estimate: 40-60 hours

#### 1.5: Property Rules Enhancement (40-50 hours)

**Nillable & NilReason** (`rule-xsd-prop-nillable`, `rule-xsd-prop-nilReasonAllowed`):
- [ ] Add nillable attribute support
  - Tagged value: `nillable = true`
  - Output: `nillable="true"` attribute
  - Files: Update property element processor
  - Estimate: 10-12 hours

- [ ] Add nilReason support
  - Output: `<xs:attribute ref="gml:nilReason"/>`
  - Files: Update property element processor
  - Estimate: 8-10 hours

**Inline or By Reference** (`rule-xsd-prop-inlineOrByReference`):
- [ ] Complete byReference implementation
  - Already partially done
  - Add proper `<xs:element ref="..."/>` handling
  - Files: Update property element processor
  - Estimate: 12-15 hours

**GML Array/List Property** (`rule-xsd-prop-gmlArrayProperty`, `rule-xsd-prop-gmlListProperty`):
- [ ] Implement GML array patterns
  - Files: `lib/lutaml/klin/rule_processors/property_rules/gml_array_processor.rb`
  - Estimate: 10-12 hours

---

### Phase 2: Should-Have Features (P1) - 200-300 hours

**Goal**: Achieve 70-80% ShapeChange functionality

#### 2.1: ISO 19139 (Metadata) Encoding (80-100 hours)

**Encoding Rule: `iso19139_2007`**:
- [ ] Implement ISO 19139 encoding rule handler
  - Files: `lib/lutaml/klin/shapechange/encoding_rules/iso19139_2007.rb`
  - Inherits from: `BaseEncodingRules`
  - Estimate: 40-50 hours

- [ ] Implement ISO types (`rule-xsd-cls-standard-19139-isoType`)
  - CharacterString → gco:CharacterString_PropertyType
  - DateTime → gco:DateTime_PropertyType
  - Files: `lib/lutaml/klin/rule_processors/class_rules/iso19139_type_processor.rb`
  - Estimate: 40-50 hours

#### 2.2: Association Classes (60-80 hours)

**Association Classes** (`rule-xsd-rel-association-classes`):
- [ ] Implement association class handling
  - Input: UML AssociationClass
  - Output: Separate `<xs:complexType>` with both associations
  - Files: `lib/lutaml/klin/rule_processors/relation_rules/association_class_processor.rb`
  - Tests: `spec/lutaml/klin/rule_processors/association_class_processor_spec.rb`
  - Estimate: 60-80 hours

#### 2.3: Constraint System (60-80 hours)

**Constraining Facets** (`rule-xsd-prop-constrainingFacets`):
- [ ] Implement XSD facets from OCL/UML constraints
  - minLength, maxLength, pattern, minInclusive, maxInclusive
  - Files: `lib/lutaml/klin/rule_processors/property_rules/facet_processor.rb`
  - Estimate: 40-50 hours

**Length/Size/Pattern** (`rule-xsd-prop-length-size-pattern`):
- [ ] Implement specific facet rules
  - Tagged values: `length`, `size`, `pattern`
  - Files: Update facet processor
  - Estimate: 20-30 hours

#### 2.4: Anonymous Types (20-30 hours)

- [ ] Implement anonymous type generation
  - For properties that don't need global types
  - Files: `lib/lutaml/klin/models/anonymous_type.rb`
  - Estimate: 20-30 hours

---

### Phase 3: Nice-to-Have Features (P2) - 300-400 hours

**Goal**: Achieve 90-95% ShapeChange functionality

#### 3.1: Schematron Generation (150-200 hours)

**Schematron Rules from OCL**:
- [ ] Create Schematron generator subsystem
  - Parse OCL constraints from UML
  - Generate `.sch` files
  - Files: `lib/lutaml/klin/shapechange/schematron_generator.rb`
  - Architecture: Separate generator like XsdGenerator
  - Estimate: 100-120 hours

- [ ] Implement Schematron rule patterns
  - Cardinality rules
  - Type rules
  - Value constraints
  - Files: `lib/lutaml/klin/schematron/rule_*_processor.rb`
  - Estimate: 50-80 hours

#### 3.2: Additional Encoding Rules (80-100 hours)

**GML 3.3** (`iso19136_2007_GML33`):
- [ ] Implement GML 3.3 differences
  - Updated property types
  - New code list mechanisms
  - Files: `lib/lutaml/klin/shapechange/encoding_rules/gml33.rb`
  - Estimate: 40-50 hours

**GML 2.1** (`iso19136_2007_GML21`):
- [ ] Implement GML 2.1 backwards compatibility
  - Older property patterns
  - Files: `lib/lutaml/klin/shapechange/encoding_rules/gml21.rb`
  - Estimate: 40-50 hours

#### 3.3: Advanced Features (70-100 hours)

**Qualified Associations** (`rule-xsd-prop-qualified-associations`):
- [ ] Implement qualified association patterns
  - Files: `lib/lutaml/klin/rule_processors/property_rules/qualified_association_processor.rb`
  - Estimate: 30-40 hours

**Reverse Property** (`rule-xsd-prop-reverseProperty`):
- [ ] Implement bidirectional associations
  - Files: `lib/lutaml/klin/rule_processors/property_rules/reverse_property_processor.rb`
  - Estimate: 20-30 hours

**Soft Typed** (`rule-xsd-prop-soft-typed`):
- [ ] Implement soft type patterns
  - Files: `lib/lutaml/klin/rule_processors/property_rules/soft_typed_processor.rb`
  - Estimate: 20-30 hours

---

### Phase 4: Future Enhancements (P3) - 100-200 hours

#### 4.1: Specialized Encoding Rules (60-80 hours)

**DGIWG Spatial Profile** (`iso19136_2007_DGIWGSP`):
- [ ] Implement DGIWG profile
  - Files: `lib/lutaml/klin/shapechange/encoding_rules/dgiwgsp.rb`
  - Estimate: 30-40 hours

**GML Simple Features** (`rule-xsd-pkg-gmlProfileSchema`):
- [ ] Implement GMLSF profiles (SF0, SF1, SF2)
  - Files: `lib/lutaml/klin/shapechange/encoding_rules/gmlsf.rb`
  - Estimate: 30-40 hours

#### 4.2: Additional Property Rules (40-60 hours)

**Target Element** (`rule-xsd-prop-targetElement`):
- [ ] Implement target element override
  - Estimate: 10-15 hours

**XSD as Attribute** (`rule-xsd-prop-xsdAsAttribute`):
- [ ] Convert properties to XSD attributes
  - Estimate: 15-20 hours

**Initial Value** (`rule-xsd-prop-initialValue`):
- [ ] Add default/fixed value support
  - Estimate: 15-20 hours

---

## Implementation Strategy

### Architecture Patterns to Follow

1. **Strategy Pattern for Rule Processors**
   - Each rule is a processor class
   - Inherits from `BaseProcessor`
   - Registered in `RuleRegistry`
   - Applied in order of priority

2. **Encoding Rule Hierarchy**
   ```
   BaseEncodingRules (abstract)
   ├── Iso19136_2007 (GML 3.2) ✅ Partially implemented
   ├── Iso19136_2007_Gml33 (GML 3.3)
   ├── Iso19136_2007_Gml21 (GML 2.1)
   ├── Iso19139_2007 (Metadata)
   ├── SweCommon
   └── ...
   ```

3. **Processor Chain Pattern**
   ```ruby
   XsdGenerator
     → ClassSelector (filter classes)
     → RuleChecker (check applicable rules)
     → ProcessorChain (apply rule processors in order)
       → ObjectElementProcessor ✅
       → ComplexTypeProcessor ✅
       → PropertyTypeProcessor ✅
       → PropertyElementProcessor ✅ (basic)
       → [New processors as implemented]
     → XsdDocument (build output)
   ```

4. **Model-Driven Architecture**
   - All processors work on UML model objects
   - No direct XML manipulation in processors
   - XsdDocument is the only XML builder

### Development Workflow

For each feature implementation:

1. **Read ShapeChange Source**
   - Files in `reference/shapechange-sources/`
   - Understand exact behavior

2. **Create Processor Class**
   - Location: `lib/lutaml/klin/rule_processors/{category}/{name}_processor.rb`
   - Inherit from `BaseProcessor`
   - Implement `#process(uml_element, context, xsd_doc)` method

3. **Register in RuleRegistry**
   - Add to `lib/lutaml/klin/shapechange/rule_registry.rb`
   - Specify: rule name, processor class, priority, applicability

4. **Write Tests**
   - Location: `spec/lutaml/klin/rule_processors/{name}_processor_spec.rb`
   - Test with real UML models
   - Compare output to ShapeChange reference

5. **Integration Test**
   - Add test case to `spec/integration/complete_shapechange_parity_spec.rb`
   - Use real PLATEAU or CityGML data

6. **Document**
   - Update `README.adoc` with new feature
   - Create `docs/rules/rule-*.adoc` documentation
   - Add examples

### Testing Strategy

1. **Unit Tests** (per processor)
   - Test processor in isolation
   - Mock UML model objects
   - Verify XSD fragments

2. **Integration Tests** (per encoding rule)
   - Test complete XSD generation
   - Use real UML models
   - Compare with ShapeChange output

3. **Regression Tests**
   - `complete_shapechange_parity_spec.rb` must always pass
   - No degradation of existing features

### Performance Targets

- LUR loading: <100ms (maintain)
- XSD generation: <15 seconds per package (with all features)
- Memory usage: <1GB for 1000+ classes

---

## Milestones

### Milestone 1: Phase 1 Complete (3-4 months)
- 50-60% ShapeChange functionality
- Advanced property types working
- Code lists as dictionaries
- Basic union support
- Basic mixin support
- PLATEAU projects can use lutaml-klin for production

### Milestone 2: Phase 2 Complete (5-6 months)
- 70-80% ShapeChange functionality
- ISO 19139 encoding
- Association classes
- Constraint system
- Can handle most real-world GML application schemas

### Milestone 3: Phase 3 Complete (7-8 months)
- 90-95% ShapeChange functionality
- Schematron generation
- Multiple encoding rules
- Advanced features
- Near-complete ShapeChange replacement

### Milestone 4: Full Parity (9-10 months)
- 100% ShapeChange XSD functionality
- All encoding rules
- All conversion rules
- Complete Schematron support
- Full production replacement of ShapeChange

---

## Success Criteria

### Phase 1 Success
- ✅ 95%+ PLATEAU XSD generation correctly
- ✅ All GML 3.2 property types generated correctly
- ✅ Code lists properly encoded as dictionaries
- ✅ nilReason/nillable support working
- ✅ Union types properly handled
- ✅ Test coverage >90% for new features
- ✅ No performance regression

### Final Success
- ✅ 100% ShapeChange XSD generation parity
- ✅ 80%+ PLATEAU Schematron rules generated
- ✅ Multiple encoding rules supported
- ✅ Byte-level output matches ShapeChange (where applicable)
- ✅ Performance: <15 seconds for 1000+ classes
- ✅ Test coverage >85% overall
- ✅ All 100+ ShapeChange conversion rules implemented

---

## Risk Management

### Known Risks

1. **Complexity Underestimation**
   - Risk: 800-1000 hours may be insufficient
   - Mitigation: Phased approach, focus on must-haves first
   
2. **ShapeChange Undocumented Behavior**
   - Risk: Some behaviors not well documented
   - Mitigation: Study Java source code, create test cases

3. **Performance Degradation**
   - Risk: More features = slower generation
   - Mitigation: Performance testing after each phase

4. **Breaking Changes**
   - Risk: New features break existing functionality
   - Mitigation: Comprehensive regression test suite

### Mitigation Strategies

- Maintain backward compatibility
- Use feature flags for experimental features
- Incremental delivery per phase
- Continuous integration testing
- Regular performance benchmarking

---

## Next Steps (Immediate)

1. **Week 1-2**: Implement `ByReferencePropertyType` pattern
2. **Week 3-4**: Implement inline property completion (nillable, nilReason)
3. **Week 5-6**: Implement array property support
4. **Week 7-8**: Begin code list dictionary implementation

---

## Dependencies

### External Gems
- `lutaml` (~> 1.0) - UML repository ✅
- `lutaml-xsd` (~> 1.0) - XSD schema repository ✅
- `lutaml-model` (~> 0.7) - Model serialization ✅
- `moxml` - XML processing ✅
- `nokogiri` - XML builder ✅

### New Dependencies (Potential)
- None currently identified
- Schematron generation may need `schematron-ruby` gem

---

## Conclusion

This plan provides a clear, phased approach to achieving full ShapeChange parity over 8-10 months. By focusing on must-have features first (Phase 1), we can deliver production-ready functionality for PLATEAU projects within 3-4 months, then progressively add more advanced features.

The modular, processor-based architecture allows for parallel development of different features and makes the codebase maintainable and testable.

**Recommended Start**: Phase 1.1 - Advanced Property Types (100-120 hours)

---

**Document Version**: 1.0
**Last Updated**: 2025-01-27
**Status**: Ready for implementation
