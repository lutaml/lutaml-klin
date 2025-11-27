# 🎯 LutaML-Klin Continuation Plan - Post-Reversion

**Version**: v9 - Correct Implementation Restored
**Date**: 2025-01-25 02:05 UTC+8
**Status**: ✅ Inline attributes fixed, ⚠️ ReferenceClasses hack must be removed
**Copy this entire prompt to start the next session**

---

## 🎉 Completed Work: Reversion Successful

### What Was Fixed (2025-01-24 Evening)

We successfully reverted an incorrect implementation that was creating global property element declarations when it should have been creating inline attribute declarations within sequences.

### Files Modified

#### 1. `lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb` ✅
**Status**: REVERTED to correct inline approach

**What was wrong**:
```ruby
# WRONG: Registered global property elements
xsd_doc.register_property_element(name: prop_name, type: xsd_type)

# Created references in sequences
prop_ref = xsd_doc.create_element("element")
prop_ref["ref"] = "#{context[:prefix]}:#{prop_name}"
sequence.add_child(prop_ref)
```

**What's correct now**:
```ruby
# CORRECT: Create inline element declaration
prop_element = xsd_doc.create_element("element")
prop_element["name"] = prop_name
prop_element["type"] = xsd_type
add_multiplicity(prop_element, attribute)

# Add directly to sequence (inline)
sequence.add_child(prop_element)
```

#### 2. `lib/lutaml/klin/shapechange/xsd_generator.rb` ✅
**Status**: Removed incorrect method call

Removed line 170: `xsd_doc.add_global_property_elements`

#### 3. `lib/lutaml/klin/shapechange/models/xsd_document.rb` ✅
**Status**: Kept as-is (methods may be useful later)

The `register_property_element()` and `add_global_property_elements()` methods remain but are unused.

### Results After Reversion

**Before (WRONG)**:
- Top-level declarations: **815** (195 class + 620 wrong property declarations)

**After (CORRECT)**:
- Top-level declarations: **254** ✅
  - With substitutionGroup: 195
  - Without substitutionGroup: 59
- Total complexTypes: 324 ✅

**Reference XSD (Target)**:
- Top-level declarations: **324**
  - With substitutionGroup: 224
  - Without substitutionGroup: 100

**Gap**: 70 missing elements (254 vs 324)

---

## 🚨 CRITICAL ISSUE IDENTIFIED: ReferenceClasses Hack

### The Problem

Line 218-220 in `lib/lutaml/klin/shapechange/xsd_generator.rb`:

```ruby
# Filter 0: Reference-based filter (temporary fix)
# Skip classes not in ShapeChange reference output
# TODO: Replace with proper ShapeChange appSchemaName filtering logic
initial_count = filtered.size
filtered = filtered.select do |uml_class|
  ReferenceClasses.include?(uml_class.name, package_name)
end
```

### Why This Is Wrong

1. **Hardcodes class lists** extracted from reference XSD files
2. **Defeats UML as source of truth** - UML model defines classes, not hardcoded lists
3. **Causes the 70 missing elements** - classes exist in UML but not in hack list
4. **Not how ShapeChange works** - ShapeChange uses `Model.selectedSchemas()` and `ClassSelector`

### The ReferenceClasses File

`lib/lutaml/klin/shapechange/reference_classes.rb` contains:
- `URO` constant: 178 hardcoded class names
- `URF` constant: 170 hardcoded class names
- Comment admits it's temporary: "TODO: Replace with proper ShapeChange appSchemaName filtering logic"

This entire file should be **DELETED** once proper filtering is implemented.

---

## 📖 How ShapeChange Actually Works

### ShapeChange's Filtering Logic

From `ClassSelector.java`:

```java
public SortedSet<ClassInfo> selectClasses(Model m, Set<PackageInfo> owners) {
    SortedSet<ClassInfo> result = new TreeSet<ClassInfo>();

    // Get schemas marked in config <appSchema> sections
    SortedSet<? extends PackageInfo> selectedSchemas = m.selectedSchemas();

    // Gather all classes contained in selected schemas
    for (PackageInfo selSchema : selectedSchemas) {
        selSchemaClasses.addAll(m.classes(selSchema));
    }

    // Filter by: package ownership, name patterns, stereotypes
    for (ClassInfo ci : selSchemaClasses) {
        if ((owners == null || owners.contains(ci.pkg()))
                && nameMatches(namePattern, ci)
                && oneStereotypeMatches(stereotypePattern, ci)) {
            result.add(ci);
        }
    }

    return result;
}
```

### Key Points

1. **`selectedSchemas()`** - Returns packages marked as `<appSchema>` in config
2. **`m.classes(selSchema)`** - Gets all classes from UML model in that package
3. **Filtering** - By package ownership, name patterns, stereotypes
4. **No hardcoded lists** - Everything comes from UML and config

---

## 🎯 NEXT PRIORITY: Remove ReferenceClasses Hack

### Task Overview

**Goal**: Remove the ReferenceClasses hack and implement proper ShapeChange `selectedSchemas()` filtering

**Effort**: 4-6 hours

**Impact**: HIGH - Fixes the 70 missing elements and makes implementation correct

### Implementation Steps

#### Step 1: Understand Config Structure (30 mins)

Read how `<input>` and `<appSchema>` are defined in ShapeChange configs:

```bash
cat examples/ShapeChangeConfig_Plateau_uro.xml
```

Look for:
```xml
<input>
  <appSchema>
    <name>uro</name>  <!-- This is what selectedSchemas() returns -->
    <targetNamespace>https://www.geospatial.jp/iur/uro/3.2</targetNamespace>
  </appSchema>
</input>
```

#### Step 2: Check UML Repository API (30 mins)

Verify that `uml_repository` from lutaml gem supports:
- Getting all packages
- Getting classes in a package (already used)
- Package hierarchy/ownership

```ruby
# Test in Ruby console
require_relative 'lib/lutaml/klin'

lur_path = 'spec/fixtures/packages/plateau_all.lur'
repo = Lutaml::XMI::Repository.new(lur_path)

# How many classes in 'uro' package?
classes = repo.classes_in_package('uro')
puts "URO classes: #{classes.size}"

# Are there more classes if we search recursively?
# Check if repository supports recursive option
```

#### Step 3: Implement selectedSchemas() Logic (2 hours)

Create `lib/lutaml/klin/shapechange/schema_selector.rb`:

```ruby
module Lutaml::Klin::Shapechange
  class SchemaSelector
    def initialize(config)
      @config = config
    end

    # Returns package names that are marked as appSchema in config
    def selected_schema_names
      @config.input_config.app_schemas.map(&:name)
    end

    # Check if a package is a selected schema
    def selected_schema?(package_name)
      selected_schema_names.include?(package_name)
    end
  end
end
```

#### Step 4: Implement ClassSelector Logic (2 hours)

Create `lib/lutaml/klin/shapechange/class_selector.rb`:

```ruby
module Lutaml::Klin::Shapechange
  class ClassSelector
    def initialize(schema_selector, uml_repository)
      @schema_selector = schema_selector
      @uml_repository = uml_repository
    end

    # Returns classes from selected schemas
    def select_classes_for_package(package_name)
      # Only proceed if this package is a selected schema
      return [] unless @schema_selector.selected_schema?(package_name)

      # Get all classes from UML repository
      classes = @uml_repository.classes_in_package(package_name)

      # Could add additional filtering here:
      # - Name patterns
      # - Stereotype patterns
      # - Package ownership checks

      classes
    end
  end
end
```

#### Step 5: Update XsdGenerator (1 hour)

Remove the ReferenceClasses hack in `xsd_generator.rb`:

```ruby
# BEFORE (lines 215-236):
def apply_suppression_filters(classes, rule_checker, package_name)
  filtered = classes

  # Filter 0: Reference-based filter (temporary fix)  ← DELETE THIS
  initial_count = filtered.size
  filtered = filtered.select do |uml_class|
    ReferenceClasses.include?(uml_class.name, package_name)
  end
  # ... rest of filters
end

# AFTER:
def apply_suppression_filters(classes, rule_checker, package_name)
  filtered = classes

  # Filtering is already done by ClassSelector  ← ADD COMMENT
  # Only includes classes from selected schemas

  # Filter 1: rule-xsd-all-notEncoded
  if rule_checker.rule_enabled?('rule-xsd-all-notEncoded')
    filtered = filtered.reject do |uml_class|
      has_not_encoded_tag?(uml_class)
    end
  end
  # ... rest of filters
end
```

Update `generate_schema_for_package`:

```ruby
def generate_schema_for_package(pkg_name, output_dir)
  # ... existing code ...

  # NEW: Use ClassSelector instead of uml_repository directly
  schema_selector = SchemaSelector.new(config)
  class_selector = ClassSelector.new(schema_selector, uml_repository)

  classes = class_selector.select_classes_for_package(pkg_name)

  # Apply remaining suppression filters
  classes = apply_suppression_filters(classes, rule_checker, pkg_name)

  # ... rest of method ...
end
```

#### Step 6: Delete ReferenceClasses (5 mins)

```bash
rm lib/lutaml/klin/shapechange/reference_classes.rb
```

Remove require statement from `xsd_generator.rb`.

#### Step 7: Test (30 mins)

```bash
# Generate URO XSD
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --output examples/output \
  --packages uro

# Count elements
python3 << 'EOF'
import xml.etree.ElementTree as ET
tree = ET.parse('examples/output/urbanObject.xsd')
root = tree.getroot()
ns = {'xs': 'http://www.w3.org/2001/XMLSchema'}
elements = root.findall('xs:element', ns)
print(f"Top-level elements: {len(elements)}")
print(f"Target: 324")
EOF
```

Expected result: **324 elements** (or very close), not 254!

---

## 📊 Current State Summary

### What Works ✅

1. ✅ Inline attribute declarations (correct XSD pattern)
2. ✅ Class object elements generated properly
3. ✅ ComplexType definitions with proper structure
4. ✅ PropertyType wrappers with element refs
5. ✅ Namespace imports working correctly
6. ✅ Valid XSD structure

### What's Wrong ❌

1. ❌ ReferenceClasses hack filters out 70 valid classes
2. ❌ Classes come from hardcoded list, not UML model
3. ❌ Violates architecture principle: UML is source of truth

### Test Commands

```bash
# Generate XSD
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --output examples/output \
  --packages uro

# Count top-level elements (accurate method)
python3 << 'EOF'
import xml.etree.ElementTree as ET
tree = ET.parse('examples/output/urbanObject.xsd')
root = tree.getroot()
ns = {'xs': 'http://www.w3.org/2001/XMLSchema'}
elements = root.findall('xs:element', ns)
print(f"Elements: {len(elements)}")
EOF

# Compare with reference
python3 << 'EOF'
import xml.etree.ElementTree as ET
ref = ET.parse('spec/fixtures/shapechange/urbanObject.xsd')
print(f"Reference: {len(ref.getroot().findall('xs:element', {'xs': 'http://www.w3.org/2001/XMLSchema'}))}")
EOF
```

---

## 📁 Key Files Reference

### Files to Modify
```
lib/lutaml/klin/shapechange/xsd_generator.rb (remove hack, use ClassSelector)
lib/lutaml/klin/shapechange/reference_classes.rb (DELETE)
```

### Files to Create
```
lib/lutaml/klin/shapechange/schema_selector.rb (new)
lib/lutaml/klin/shapechange/class_selector.rb (new)
```

### Reference Files
```
spec/fixtures/shapechange/urbanObject.xsd (target - 324 elements)
examples/output/urbanObject.xsd (current output - 254 elements)
examples/ShapeChangeConfig_Plateau_uro.xml (config with <appSchema>)
reference/shapechange-sources/de/interactive_instruments/ShapeChange/ClassSelector.java
```

---

## 🧪 Verification Checklist

After implementing proper filtering:

- [ ] ReferenceClasses.rb file deleted
- [ ] No require for reference_classes in any file
- [ ] SchemaSelector reads <appSchema> from config
- [ ] ClassSelector uses UML repository API
- [ ] XsdGenerator uses ClassSelector, not hardcoded filter
- [ ] URO package generates ~324 elements (not 254)
- [ ] No test failures
- [ ] RuboCop passes

---

## 📚 Architecture Principles

### Core Principle: UML is Source of Truth

1. **UML Model Defines Classes** - Not hardcoded lists, not reference XSDs
2. **Config Defines Selection** - `<appSchema>` entries specify which packages
3. **Filtering is Dynamic** - Based on stereotypes, names, ownership from UML
4. **No Hardcoded Data** - Implementation should work with ANY UML model

### Pattern to Follow

```
UML Model (LUR) → Config (<appSchema>) → ClassSelector → XsdGenerator → XSD Output
```

NOT:

```
UML Model → ReferenceClasses Hardcoded List → XsdGenerator → XSD Output ❌
```

---

## 🎓 Key Learnings

### 1. XSD Element Types

**Top-level declarations** (what we count):
```xml
<xs:element name="Building" type="uro:BuildingType"/>
```

**Inline property declarations** (correct, don't count):
```xml
<xs:complexType name="BuildingType">
  <xs:sequence>
    <xs:element name="height" type="xs:double"/>
  </xs:sequence>
</xs:complexType>
```

### 2. Counting Method

Use XML parser to count only direct children of `<xs:schema>`:

```python
import xml.etree.ElementTree as ET
tree = ET.parse('file.xsd')
root = tree.getroot()
elements = root.findall('xs:element', {'xs': '...'})
print(len(elements))  # Correct count
```

NOT: `grep -c '<xs:element name='` (counts inline too!)

### 3. ShapeChange Pattern

- One element per class (class object element)
- One complexType per class (type definition)
- One PropertyType per class (wrapper)
- Attributes inline in sequences
- No global property declarations

---

## 💡 Session Start Checklist

When starting the next session:

- [ ] Read this continuation plan completely
- [ ] Understand ReferenceClasses is a **HACK to be removed**
- [ ] Understand proper ShapeChange filtering uses `selectedSchemas()` and UML
- [ ] Review ShapeChange ClassSelector.java if needed
- [ ] Start with Step 1: Understand config structure
- [ ] Create SchemaSelector and ClassSelector classes
- [ ] Remove ReferenceClasses hack from xsd_generator.rb
- [ ] Delete reference_classes.rb file
- [ ] Test that element count reaches ~324

---

**Session End**: 2025-01-25 02:05 UTC+8
**Status**: ✅ Reversion complete, inline attributes working
** Next**: Remove ReferenceClasses hack, implement proper filtering
**Estimated Time**: 4-6 hours

---