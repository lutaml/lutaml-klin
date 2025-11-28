# Continuation Plan: YAML Mapping Feature - Final Phase

**Date**: 2025-01-27 (evening session)
**Phase**: Phase 1.5B - Final Implementation
**Status**: 🔧 70% Complete - Critical Path Remaining
**Priority**: 🚨 HIGH - Deadline Pressure

---

## 📊 Current Status Summary

### ✅ Completed (70%)
1. **Architecture & Models** (100%)
   - ✅ TransformationInfo model created
   - ✅ ClassMapping enhanced with transformation_info
   - ✅ AttributeMapping enhanced with transformation_info
   - ✅ All using lutaml-model with proper YAML serialization

2. **Core MappingCollector** (100%)
   - ✅ Full OOP/DRY/MECE implementation
   - ✅ Passive observer pattern
   - ✅ 329 lines, comprehensive functionality

3. **XsdGenerator Integration** (100%)
   - ✅ MappingCollector initialization
   - ✅ Context passing to processors
   - ✅ YAML file writing

4. **Processor Enhancements** (40%)
   - ✅ ObjectElementProcessor - element mapping
   - ✅ ComplexTypeProcessor - type mapping
   - ⏸️ PropertyElementProcessor - CRITICAL, NOT DONE
   - ⏸️ EnumerationProcessor - NOT DONE
   - ⏸️ BasicTypeProcessor - NOT DONE

### ⏸️ Remaining (30%)
- PropertyElementProcessor enhancement (CRITICAL)
- EnumerationProcessor + BasicTypeProcessor enhancements
- CLI option integration
- Integration tests
- Documentation updates

---

## 🎯 Critical Path to Completion (3-4h)

### Phase 1: Core Functionality (2h)

#### Task 1.1: PropertyElementProcessor Enhancement ⚠️ CRITICAL
**Priority**: P0
**Time**: 1 hour
**File**: `lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb`

**Why Critical**: This handles ALL attribute mappings - 1847 attributes in URO alone!

**Implementation**:
```ruby
# Add to PropertyElementProcessor
def record_property_mapping(uml_attribute, xsd_property_name, xsd_type, context)
  collector = context[:mapping_collector]
  return unless collector

  # Extract multiplicity
  min_occurs, max_occurs = extract_occurs(uml_attribute)

  collector.record_attribute_mapping(
    uml_attribute: uml_attribute,
    xsd_property_name: xsd_property_name,
    xsd_property_type: xsd_type,
    xsd_min_occurs: min_occurs,
    xsd_max_occurs: max_occurs,
    type_mapping_info: extract_type_mapping_info(uml_attribute, xsd_type, context),
    rules_applied: ["rule-xsd-prop-encode-properties"],
    context: {
      encoding_rule: context[:config]&.target_config&.dig(:default_encoding_rule)
    }
  )
end

def extract_type_mapping_info(uml_attribute, xsd_type, context)
  source = determine_type_source(uml_attribute, xsd_type, context)
  description = "#{uml_attribute.type&.name} → #{xsd_type}"
  
  {
    source: source,
    description: description
  }
end
```

#### Task 1.2: EnumerationProcessor + BasicTypeProcessor
**Priority**: P0
**Time**: 30 minutes
**Files**: 
- `lib/lutaml/klin/shapechange/rule_processors/enumeration_processor.rb`
- `lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor.rb`

**Pattern** (same for both):
```ruby
# Record mapping after XSD generation
if context[:mapping_collector]
  context[:mapping_collector].record_class_mapping(
    uml_class: uml_enum,
    xsd_element_name: uml_enum.name,
    xsd_type_name: "#{uml_enum.name}Type",
    rules_applied: [RULE_ID],
    context: { encoding_rule: context[:config]&.target_config&.dig(:default_encoding_rule) }
  )
end
```

#### Task 1.3: CLI Integration
**Priority**: P1
**Time**: 30 minutes
**Files**:
- `lib/lutaml/klin/commands/xsd_generate_command.rb`
- CLI command callers

**Changes**:
```ruby
# In xsd_generate_command.rb
option :generate_mapping,
  type: :boolean,
  default: true,
  desc: "Generate YAML mapping file alongside XSD (default: true)"

# Pass to XsdGenerator
generator = Shapechange::XsdGenerator.new(
  uml_repository,
  config,
  lur_path: options[:lur],
  config_path: options[:config],
  generate_mapping: options[:generate_mapping]
)
```

### Phase 2: Testing & Quality (1h)

#### Task 2.1: Integration Test
**Priority**: P0
**Time**: 30 minutes
**File**: `spec/integration/yaml_mapping_generation_spec.rb`

**Minimal Test**:
```ruby
describe "YAML Mapping Generation" do
  it "generates mapping file alongside XSD for URO" do
    generator = Shapechange::XsdGenerator.new(
      uml_repository, config,
      lur_path: lur_path,
      config_path: config_path,
      generate_mapping: true
    )
    
    results = generator.generate_schemas(["uro"], output_dir)
    result = results.first
    
    # Verify XSD exists
    expect(File.exist?(result[:file])).to be true
    
    # Verify YAML mapping exists
    expect(File.exist?(result[:mapping_file])).to be true
    
    # Load and validate YAML
    mapping = YAML.load_file(result[:mapping_file])
    expect(mapping["package_mappings"]).not_to be_empty
    expect(mapping["package_mappings"][0]["class_mappings"].size).to be > 0
  end
end
```

#### Task 2.2: Existing Tests + RuboCop
**Priority**: P0
**Time**: 30 minutes

```bash
# Run existing tests - must pass!
bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb

# Fix any RuboCop issues
bundle exec rubocop -A

# Run all tests
bundle exec rake spec
```

### Phase 3: Documentation (1h)

#### Task 3.1: README.adoc Update
**Priority**: P1
**Time**: 30 minutes
**File**: `README.adoc`

**Add Section**:
```adoc
== YAML Mapping Output

When generating XSD schemas, lutaml-klin automatically creates YAML mapping files that document the complete UML→XSD transformation.

=== Overview

Each mapping file contains:

* Package metadata (namespace, prefix)
* Class mappings (UML class → XSD element/type)
* Attribute mappings (UML attribute → XSD property)
* Transformation rules applied
* Statistics and metrics

=== Usage

[source,bash]
----
# Generate XSD with mapping (default)
bundle exec lutaml-klin xsd \
  --lur model.lur \
  --config config.xml \
  --output out/ \
  --packages uro

# Output:
#   out/urbanObject.xsd              # XSD schema
#   out/urbanObject_mapping.yaml     # YAML mapping

# Disable mapping generation
bundle exec lutaml-klin xsd \
  --lur model.lur \
  --config config.xml \
  --output out/ \
  --packages uro \
  --no-generate-mapping
----

=== YAML Format

[source,yaml]
----
version: "1.0"
generated_at: "2025-01-27T14:30:00Z"
source_lur: "model.lur"
source_config: "config.xml"

package_mappings:
  - uml_package_name: "uro"
    xsd_namespace: "https://www.geospatial.jp/iur/uro/3.2"
    
    class_mappings:
      - uml_name: "Building"
        uml_stereotype: "FeatureType"
        xsd_element_name: "Building"
        xsd_type_name: "BuildingType"
        
        transformation_info:
          rules_applied:
            - "rule-xsd-cls-object-element"
            - "rule-xsd-cls-type"
----

See link:docs/features/yaml-mapping-output.adoc[YAML Mapping Output] for complete documentation.
```

#### Task 3.2: Feature Documentation
**Priority**: P2
**Time**: 30 minutes
**File**: `docs/features/yaml-mapping-output.adoc`

Create comprehensive feature documentation with:
- Architecture overview
- Use cases
- Complete YAML format specification
- Examples for different transformation patterns
- API usage examples

---

## 📋 Compressed Implementation Plan (Deadline Mode)

### Session 1: Core (2h) ⚠️ CRITICAL
```
Hour 1:
[x] PropertyElementProcessor enhancement (60 min)
  [x] Add record_property_mapping method
  [x] Integrate with apply_rule
  [x] Handle type mapping info extraction

Hour 2:
[x] EnumerationProcessor enhancement (15 min)
[x] BasicTypeProcessor enhancement (15 min)
[x] CLI option integration (15 min)
[x] Quick smoke test (15 min)
```

### Session 2: Testing & Docs (1.5h)
```
[x] Integration test (30 min)
[x] Run existing tests + RuboCop (30 min)
[x] README.adoc update (30 min)
```

### Session 3: Polish (0.5h) - Optional
```
[x] Feature documentation (30 min)
[x] Archive outdated docs
[x] Final commit
```

**Total Critical Path**: 2 hours
**Total with Documentation**: 3.5 hours

---

## 🎯 Success Criteria (Must All Pass)

### Functional
- [ ] YAML mapping file generated alongside every XSD file
- [ ] All class transformations recorded (255 for URO, 208 for URF)
- [ ] All attribute transformations recorded (1847 for URO)
- [ ] CLI option `--generate-mapping` / `--no-generate-mapping` works
- [ ] YAML files are valid and parseable

### Quality
- [ ] All existing tests still passing (8/8 = 100%)
- [ ] New integration test passing
- [ ] RuboCop passes with zero violations
- [ ] Performance overhead <10%
- [ ] YAML files <5MB

### Documentation
- [ ] README.adoc updated with YAML mapping section
- [ ] Feature documentation exists (optional)
- [ ] Outdated docs archived

---

## 🚀 Quick Start Command

```bash
# Continue implementation - start with PropertyElementProcessor
bundle exec lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --output examples/output \
  --packages uro

# After implementation, verify YAML exists
ls -lh examples/output/urbanObject_mapping.yaml

# Test
bundle exec rspec spec/integration/yaml_mapping_generation_spec.rb
bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb
```

---

## 🔧 Architecture Notes (Remember!)

### OOP Principles Applied
- **Single Responsibility**: MappingCollector only collects, doesn't generate
- **Open/Closed**: Easy to add new processors without modifying collector
- **Composition**: Delegates to lutaml-model classes
- **Encapsulation**: All transformation data properly encapsulated

### DRY Implementation
- Zero duplication - leverages lutaml-model framework
- Reuses existing ClassMapping/AttributeMapping models
- Single source of truth for transformation metadata

### MECE Structure
- Each transformation aspect tracked exactly once
- No overlaps between processors
- Clear boundaries of responsibility

---

## 📊 Files Modified Summary

### Created (3 files)
1. `lib/lutaml/klin/models/mapping/transformation_info.rb` (73 lines)
2. `lib/lutaml/klin/shapechange/mapping_collector.rb` (329 lines)
3. `spec/integration/yaml_mapping_generation_spec.rb` (TBD)

### Modified (6 files)
1. `lib/lutaml/klin/models/mapping/class_mapping.rb` (+3 lines)
2. `lib/lutaml/klin/models/mapping/attribute_mapping.rb` (+3 lines)
3. `lib/lutaml/klin/shapechange/xsd_generator.rb` (+30 lines)
4. `lib/lutaml/klin/shapechange/rule_processors/object_element_processor.rb` (+20 lines)
5. `lib/lutaml/klin/shapechange/rule_processors/complex_type_processor.rb` (+20 lines)
6. `lib/lutaml/klin/commands/xsd_generate_command.rb` (TBD)

### To Modify (3 files)
1. `lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb`
2. `lib/lutaml/klin/shapechange/rule_processors/enumeration_processor.rb`
3. `lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor.rb`

### Documentation (2 files)
1. `README.adoc` (update)
2. `docs/features/yaml-mapping-output.adoc` (create)

---

## 💡 Known Issues & Gotchas

### Issue 1: PropertyElementProcessor Anonymous Types
- Phase 1 implemented anonymous property type generation
- Need to ensure mapping collector handles these correctly
- Check for Pattern A/B/C anonymous types

### Issue 2: Cross-Package Properties
- Phase 1 final fixed cross-package property filtering
- Ensure mapping collector respects `is_cross_package_property?` check
- Don't record mappings for properties from external packages

### Issue 3: Multiple Rules per Class
- ObjectElementProcessor records class mapping first
- ComplexTypeProcessor updates it with type info
- Ensure we're updating, not creating duplicate mappings

---

## 🎉 Expected Final Output

### For URO Package
```
examples/output/
├── urbanObject.xsd (100% parity with ShapeChange)
└── urbanObject_mapping.yaml (NEW!)
    ├── 255 class mappings
    ├── 1847 attribute mappings
    ├── Full transformation traceability
    └── ~2-3 MB file size
```

### For URF Package
```
examples/output/
├── urbanFunction.xsd (100% parity with ShapeChange)
└── urbanFunction_mapping.yaml (NEW!)
    ├── 208 class mappings
    ├── Full transformation traceability
    └── ~1-2 MB file size
```

---

**Plan Version**: 2.0 (Final)
**Created**: 2025-01-27 evening
**Status**: Ready for final push
**Critical Path**: 2 hours
**Total**: 3.5 hours with documentation
**Priority**: 🚨 HIGH - Deadline Mode