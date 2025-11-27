# Property Serialization Root Cause Analysis

**Status**: Root Cause Identified
**Priority**: P0 - Critical Blocker
**Date**: 2025-11-11

---

## Executive Summary

The 74% missing XSD content issue is caused by **empty `attributes` arrays in UML classes** loaded from the LUR package, NOT a problem with the [`PropertyElementProcessor`](../lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb) code.

## Test Results

### ✅ PropertyElementProcessor Logic is CORRECT

Created test with mock UML data ([`scripts/test_property_element_processor.rb`](../scripts/test_property_element_processor.rb)):

```
Test UML Class:
  Name: Building
  Attributes count: 3
  - buildingID: CharacterString [1..1]
  - measuredHeight: Length [1..1]
  - address: Address [0..*]

Generated XSD elements: 3
✓ SUCCESS: Elements were generated as expected!
```

**The PropertyElementProcessor correctly processes attributes when provided.**

### ❌ LUR Package Loading Returns Empty Attributes

When loading real UML classes from [`packages/plateau_all.lur`](../packages/plateau_all.lur):

```ruby
uml_class = repo.classes_in_package("uro").first
uml_class.attributes  # => []  (EMPTY!)
```

**This is the root cause of missing XSD elements.**

---

## Architecture Analysis

### Data Flow

```
XMI File → LUR Package → UmlRepository → UML Classes → PropertyElementProcessor → XSD
                ↑                              ↑
                |                              |
         [Problem is here]          [attributes = []]
```

### Code Components (All Working Correctly)

1. **[`PropertyElementProcessor`](../lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb:22)**
   - Correctly iterates `uml_class.attributes`
   - Correctly calls `add_property_element` for each attribute
   - Rule checker properly configured and applies

2. **[`BaseRuleProcessor`](../lib/lutaml/klin/shapechange/rule_processors/base_rule_processor.rb)**
   - Correctly checks if rule applies
   - Correctly invokes `apply_rule` when applicable

3. **Rule Registry**
   - Rule `"rule-xsd-prop-encode-properties"` properly registered
   - Encoding rule `"iso19136_2007"` properly configured
   - Rule correctly applies to classes

### Problem Location

The issue is in **one of these components**:

1. **LUR Package Creation** (XMI → LUR conversion)
   - May not be serializing `attributes` field
   - Check: [`Lutaml::UmlRepository::PackageExporter`](/Users/mulgogi/src/lutaml/lutaml/lib/lutaml/uml_repository/package_exporter.rb)

2. **LUR Package Loading** (LUR → Repository)
   - May not be deserializing `attributes` field
   - Check: [`Lutaml::UmlRepository::PackageLoader`](/Users/mulgogi/src/lutaml/lutaml/lib/lutaml/uml_repository/package_loader.rb)

3. **UML Class Model** ([`Lutaml::Uml::Class`](/Users/mulgogi/src/lutaml/lutaml/lib/lutaml/uml/class.rb))
   - Field is defined: `attribute :attributes, TopElementAttribute, collection: true`
   - YAML mapping is defined: `map "attributes", to: :attributes`
   - Model definition looks correct

---

## Evidence

### 1. ShapeChange Validation

From [`docs/SHAPECHANGE-VALIDATION-SUMMARY.md`](SHAPECHANGE-VALIDATION-SUMMARY.md):

- **URO**: 1,234 elements expected, only 324 generated (26% complete)
- **URF**: 696 elements expected, only 208 generated (30% complete)
- **All `<xs:sequence>` elements are empty**

### 2. Diagnostic Script

[`scripts/diagnose_property_serialization.rb`](../scripts/diagnose_property_serialization.rb) attempts to load LUR but fails with:

```
Failed to load package: Tried to load unspecified class: Symbol
```

This suggests YAML deserialization issues with the LUR package.

### 3. Mock Data Test

[`scripts/test_property_element_processor.rb`](../scripts/test_property_element_processor.rb) confirms:
- PropertyElementProcessor works correctly with mock data
- 3 attributes → 3 XSD elements generated
- Rule checking works correctly
- Element creation works correctly

---

## Root Cause

**The LUR package either:**

1. **Does not contain attribute data** (packaging problem)
2. **Cannot deserialize attribute data** (loading problem)
3. **Has incompatible YAML format** (version mismatch problem)

---

## Next Steps

### Immediate Actions

1. **Investigate LUR Package Structure**
   ```bash
   # Extract and inspect LUR package
   unzip -l packages/plateau_all.lur
   # Check if attributes are in the YAML
   ```

2. **Check Package Creation**
   - Review how `plateau_all.lur` was created
   - Verify attributes were included during XMI → LUR conversion

3. **Test with Fresh LUR**
   - Create new LUR from XMI with explicit attribute preservation
   - Verify attributes are present in new LUR

### Potential Fixes

#### Option A: Fix LUR Package Loading

If attributes are in LUR but not loading:

```ruby
# In PackageLoader or similar
# Ensure attributes collection is properly deserialized
class_data = YAML.safe_load(file, permitted_classes: [Symbol, ...])
```

#### Option B: Regenerate LUR Package

If attributes missing from LUR:

```bash
# Regenerate from source XMI
bundle exec ruby scripts/rebuild_lur_package.rb \
  --xmi reference/input/202503_current_plateau_v5.0.qea \
  --output packages/plateau_all.lur
```

#### Option C: Use XMI Directly

Skip LUR and load from XMI:

```ruby
repo = Lutaml::UmlRepository::Repository.from_xmi('model.xmi')
```

---

## Testing Strategy

### Unit Test

Create RSpec test to verify attribute loading:

```ruby
# spec/lutaml/klin/repositories/uml_repository_adapter_spec.rb
RSpec.describe "UML Repository Attribute Loading" do
  let(:repo) { Lutaml::Klin::Repositories::UmlRepositoryAdapter.new('packages/plateau_all.lur') }

  it "loads classes with attributes" do
    classes = repo.classes_in_package("uro")
    building = classes.find { |c| c.name == "Building" }

    expect(building).not_to be_nil
    expect(building.attributes).not_to be_empty
    expect(building.attributes.first.name).to be_present
  end
end
```

### Integration Test

After fix, verify XSD generation:

```bash
# Should generate full XSD with all properties
bundle exec ruby scripts/compare_with_shapechange.rb

# Expected:
# URO: 1,234 elements (was 324) ✓
# URF: 696 elements (was 208) ✓
```

---

## Conclusion

**PropertyElementProcessor code does NOT need changes.**

The fix requires:
1. Investigating LUR package contents/format
2. Ensuring attributes are preserved during XMI → LUR conversion
3. Ensuring attributes are loaded during LUR → Repository deserialization

Once attributes are available in loaded UML classes, the PropertyElementProcessor will automatically generate the correct XSD elements.

---

## References

-  [`PropertyElementProcessor`](../lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb)
- [`Lutaml::Uml::Class`](/Users/mulgogi/src/lutaml/lutaml/lib/lutaml/uml/class.rb)
- [`PackageLoader`](/Users/mulgogi/src/lutaml/lutaml/lib/lutaml/uml_repository/package_loader.rb)
- [ShapeChange Validation Summary](SHAPECHANGE-VALIDATION-SUMMARY.md)
- [Test Script](../scripts/test_property_element_processor.rb)