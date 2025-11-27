# Complete ShapeChange Rule Implementation Plan

## Critical Understanding

**Current State**: Only ~7 core rules implemented
**Required**: ALL ~60+ XML Schema rules from ShapeChange

**Your Requirement**:
- ✅ Each rule = Separate processor class OR configuration
- ✅ One responsibility per processor
- ✅ Configuration over code (external YAML/XML)
- ✅ Each processor paired with spec file
- ✅ MECE organization
- ✅ Open/Closed extensibility

## Rule Discovery Process

### Step 1: Catalog ALL Rules from ShapeChange Documentation

**Documentation Source**:
```
/Users/mulgogi/src/external/ShapeChange/shapechange-app/src/docs/asciidoc/targets/xml schema/*.adoc
```

**For each .adoc file**:
1. Extract all `rule-xsd-*` identifiers
2. Read description
3. Identify implementation (ClassInfoImpl.java, XsdDocument.java, etc.)
4. Document parameters and behavior

### Step 2: Categorize Rules by Type

**Categories** (MECE):

1. **Class-level rules** (`rule-xsd-cls-*`)
   - Type generation rules
   - Element generation rules
   - Property type rules

2. **Property-level rules** (`rule-xsd-prop-*`)
   - Property encoding rules
   - Multiplicity rules
   - Constraint rules

3. **Package-level rules** (`rule-xsd-pkg-*`)
   - Namespace rules
   - Import rules

4. **Global rules** (`rule-xsd-all-*`)
   - Naming conventions
   - Documentation rules

## Architecture for Complete Implementation

### Processor Organization

```
lib/lutaml/klin/shapechange/rule_processors/
├── base_rule_processor.rb (exists)
├── class_rules/
│   ├── basic_type_processor.rb           # rule-xsd-cls-basictype
│   ├── object_element_processor.rb       # rule-xsd-cls-object-element (exists)
│   ├── complex_type_processor.rb         # rule-xsd-cls-type (exists)
│   ├── property_type_processor.rb        # rule-xsd-cls-property-type
│   ├── sequence_processor.rb             # rule-xsd-cls-sequence (exists)
│   ├── union_choice_processor.rb         # rule-xsd-cls-union-as-choice
│   ├── union_direct_processor.rb         # rule-xsd-cls-union-direct
│   ├── no_property_type_processor.rb     # rule-xsd-cls-noPropertyType
│   ├── local_enumeration_processor.rb    # rule-xsd-cls-local-enumeration
│   ├── local_basictype_processor.rb      # rule-xsd-cls-local-basictype
│   ├── codelist_gmlsf_processor.rb       # rule-xsd-cls-codelist-gmlsf
│   ├── codelist_asdictionary_processor.rb # rule-xsd-cls-codelist-asDictionary
│   ├── mixin_classes_processor.rb        # rule-xsd-cls-mixin-classes
│   ├── no_abstract_classes_processor.rb  # rule-xsd-cls-no-abstract-classes
│   ├── adehook_processor.rb              # rule-xsd-cls-adehook
│   └── ... (30+ more class rules)
├── property_rules/
│   ├── property_element_processor.rb     # rule-xsd-prop-encode-properties (exists)
│   ├── nillable_processor.rb             # rule-xsd-prop-nillable
│   ├── initial_value_processor.rb        # rule-xsd-prop-initialValue
│   ├── inline_byref_processor.rb         # rule-xsd-prop-inlineOrByReference
│   ├── length_size_pattern_processor.rb  # rule-xsd-prop-length-size-pattern
│   ├── constraining_facets_processor.rb  # rule-xsd-prop-constrainingFacets
│   ├── metadata_processor.rb             # rule-xsd-prop-metadata
│   ├── soft_typed_processor.rb           # rule-xsd-prop-soft-typed
│   └── ... (20+ more property rules)
├── package_rules/
│   ├── gml_profile_schema_processor.rb   # rule-xsd-pkg-gmlProfileSchema
│   └── ... (5+ package rules)
└── naming_rules/
    ├── gml_naming_processor.rb           # rule-xsd-all-naming-gml
    ├── iso19139_naming_processor.rb      # rule-xsd-all-naming-19139
    └── swe_naming_processor.rb           # rule-xsd-all-naming-swe
```

## Implementation Strategy

### Approach A: Processor Per Rule (Full OO)

**When to Use**: Rules with complex logic

**Structure**:
```ruby
class BasicTypeProcessor < BaseRuleProcessor
  RULE_ID = 'rule-xsd-cls-basictype'

  def apply_rule(uml_class, context)
    # Read tagged values
    length = uml_class.tagged_value('length')
    pattern = uml_class.tagged_value('pattern')

    # Generate simpleType with restrictions
    create_basic_type(uml_class, length, pattern)
  end
end
```

**Plus spec**:
```ruby
# spec/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor_spec.rb
RSpec.describe BasicTypeProcessor do
  it "generates simpleType with length restriction" do
    # Test
  end
end
```

### Approach B: Configuration-Driven (When Possible)

**When to Use**: Simple, data-driven rules

**Structure**:
```yaml
# config/rule_behaviors/basictype.yml
rule: rule-xsd-cls-basictype
type: simpleType
facets:
  length: tagged_value
  pattern: tagged_value
  rangeMinimum: tagged_value
  rangeMaximum: tagged_value
base_type: string
```

**Plus generic processor**:
```ruby
class ConfigurableBasicTypeProcessor < BaseRuleProcessor
  def initialize(rule_checker, config, rule_config_file)
    super(rule_checker, config)
    @rule_config = YAML.load_file(rule_config_file)
  end

  def apply_rule(uml_class, context)
    # Apply behavior from @rule_config
  end
end
```

## Phased Implementation Plan

### Phase 1: Catalog (1 week)

**For each .adoc file** in `/Users/mulgogi/src/external/ShapeChange/shapechange-app/src/docs/asciidoc/targets/xml schema/`:

1. Extract all `rule-xsd-*` mentions
2. Read description
3. Find Java implementation
4. Document in `docs/RULE_CATALOG.md`

**Output**: Complete catalog of ~60+ rules with:
- Rule ID
- Description
- Implementation location
- Parameters/behavior
- Priority (required vs optional)

### Phase 2: Prioritize (2 days)

**Group rules by**:
- Must have (breaks XSD without)
- Should have (PLATEAU uses)
- Could have (edge cases)
- Won't have (deprecated/rare)

### Phase 3: Implement Must-Have (2 weeks)

**~20 critical rules** used by PLATEAU:

**Week 1**:
- rule-xsd-cls-basictype
- rule-xsd-cls-union-as-choice
- rule-xsd-cls-union-direct
- rule-xsd-prop-nillable
- rule-xsd-prop-initialValue
- rule-xsd-prop-length-size-pattern
- rule-xsd-prop-constrainingFacets
- rule-xsd-all-naming-gml (enhance)
- rule-xsd-all-naming-19139
- rule-xsd-cls-mixin-classes

**Week 2**:
- rule-xsd-cls-adehook
- rule-xsd-prop-inlineOrByReference
- rule-xsd-prop-metadata
- rule-xsd-cls-codelist-asDictionary
- rule-xsd-cls-enum-supertypes
- rule-xsd-cls-enum-subtypes
- rule-xsd-cls-no-abstract-classes
- rule-xsd-prop-soft-typed
- rule-xsd-prop-targetElement
- rule-xsd-prop-reverseProperty

### Phase 4: Implement Should-Have (1 week)

**~15 additional rules** for completeness

### Phase 5: Testing and Validation (3 days)

**Generate PLATEAU XSD with all rules**:
- Compare against published
- Should match 100%

## File Naming Convention

**Processor**: `rule_processors/{category}/{descriptive_name}_processor.rb`

Examples:
- `rule_processors/class_rules/basic_type_processor.rb`
- `rule_processors/property_rules/nillable_processor.rb`
- `rule_processors/naming_rules/gml_naming_processor.rb`

**Spec**: `spec/lutaml/klin/shapechange/rule_processors/{category}/{descriptive_name}_processor_spec.rb`

**Config** (if applicable): `config/rule_behaviors/{rule_name}.yml`

## Timeline

**Total Estimate**: 4-5 weeks for complete implementation

**Breakdown**:
- Week 1: Catalog all rules (discovery)
- Week 2-3: Implement must-have rules (20 rules)
- Week 4: Implement should-have rules (15 rules)
- Week 5: Testing, validation, documentation

## Success Criteria

✅ All rules from ShapeChange docs cataloged
✅ Each rule has processor class OR configuration
✅ Each processor has corresponding spec
✅ MECE organization (no overlap, complete coverage)
✅ Configuration-driven where possible
✅ OO principles maintained
✅ PLATEAU XSD matches published 100%

This is the comprehensive plan for TRUE complete ShapeChange parity!