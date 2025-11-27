# 🎯 LutaML-Klin Session Continuation Prompt

**Copy this entire section to start the next session**

---

## Previous Session Summary (2025-01-24 Evening)

### ✅ Completed: Reversion of Wrong Implementation

**Problem**: Property elements were being generated as global declarations with references, when they should be inline within sequences.

**Fixed Files**:
1. `lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb` - Now creates inline declarations
2. `lib/lutaml/klin/shapechange/xsd_generator.rb` - Removed `add_global_property_elements()` call

**Results**:
- Before: 815 top-level declarations (WRONG - 620 were incorrect global property declarations)
- After: 254 top-level declarations (CORRECT - inline attributes, proper structure)
- Target: 324 declarations

---

## 🚨 CRITICAL ISSUE: ReferenceClasses Hack

**Location**: `lib/lutaml/klin/shapechange/xsd_generator.rb` lines 218-220

```ruby
# THIS IS A HACK AND MUST BE REMOVED:
filtered = filtered.select do |uml_class|
  ReferenceClasses.include?(uml_class.name, package_name)
end
```

**Why It's Wrong**:
- Hardcodes class lists from reference XSD files
- Violates architecture: UML should be source of truth, not hardcoded lists
- Causes 70 missing elements (they exist in UML but filtered out by hack)
- File `lib/lutaml/klin/shapechange/reference_classes.rb` contains 179 hardcoded class names

**How ShapeChange Actually Works**:
- Reads `<appSchema>` entries from config
- Gets classes from UML model via `Model.selectedSchemas()`
- Filters by package, stereotypes, names - from UML, not hardcoded lists

---

## 🎯 NEXT TASK: Remove ReferenceClasses Hack

**Priority**: CRITICAL
**Effort**: 4-6 hours
**Goal**: Replace hardcoded filter with proper ShapeChange `selectedSchemas()` logic

### Implementation Plan

#### 1. Create SchemaSelector (1 hour)
```ruby
# lib/lutaml/klin/shapechange/schema_selector.rb
class SchemaSelector
  def initialize(config)
    @config = config
  end

  def selected_schema_names
    # Read <appSchema> entries from config.input_config
    @config.input_config.app_schemas.map(&:name)
  end

  def selected_schema?(package_name)
    selected_schema_names.include?(package_name)
  end
end
```

#### 2. Create ClassSelector (2 hours)
```ruby
# lib/lutaml/klin/shapechange/class_selector.rb
class ClassSelector
  def initialize(schema_selector, uml_repository)
    @schema_selector = schema_selector
    @uml_repository = uml_repository
  end

  def select_classes_for_package(package_name)
    return [] unless @schema_selector.selected_schema?(package_name)

    # Get ALL classes from UML model
    @uml_repository.classes_in_package(package_name)
  end
end
```

#### 3. Update XsdGenerator (1 hour)
Remove lines 218-236 (ReferenceClasses filter).

Replace `uml_repository.classes_in_package()` with:
```ruby
schema_selector = SchemaSelector.new(config)
class_selector = ClassSelector.new(schema_selector, uml_repository)
classes = class_selector.select_classes_for_package(pkg_name)
```

#### 4. Delete ReferenceClasses (5 mins)
```bash
rm lib/lutaml/klin/shapechange/reference_classes.rb
```

Remove `require_relative "reference_classes"` from xsd_generator.rb

#### 5. Test (30 mins)
```bash
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --output examples/output \
  --packages uro

python3 << 'EOF'
import xml.etree.ElementTree as ET
tree = ET.parse('examples/output/urbanObject.xsd')
root = tree.getroot()
elements = root.findall('xs:element', {'xs': 'http://www.w3.org/2001/XMLSchema'})
print(f"Elements: {len(elements)} (target: 324)")
EOF
```

**Expected**: ~324 elements (not 254!)

---

## 📋 Current State

### What Works ✅
- Inline attribute declarations (correct)
- Class object elements
- ComplexType definitions
- PropertyType wrappers
- Valid XSD structure

### What's Wrong ❌
- ReferenceClasses hack filters out 70 valid classes
- Classes from hardcoded list, not UML model
- Violates architecture principle

### Test Command
```bash
cd /Users/mulgogi/src/lutaml/lutaml-klin

# Generate URO XSD
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --output examples/output \
  --packages uro

# Count elements (accurate)
python3 << 'EOF'
import xml.etree.ElementTree as ET
tree = ET.parse('examples/output/urbanObject.xsd')
root = tree.getroot()
ns = {'xs': 'http://www.w3.org/2001/XMLSchema'}
print(f"Our output: {len(root.findall('xs:element', ns))} elements")

ref = ET.parse('spec/fixtures/shapechange/urbanObject.xsd')
print(f"Reference: {len(ref.getroot().findall('xs:element', ns))} elements")
EOF
```

Current output: 254 elements
Target: 324 elements

---

## 📚 Key Files

### To Modify
- `lib/lutaml/klin/shapechange/xsd_generator.rb` (remove ReferenceClasses filter)

### To Create
- `lib/lutaml/klin/shapechange/schema_selector.rb`
- `lib/lutaml/klin/shapechange/class_selector.rb`

### To Delete
- `lib/lutaml/klin/shapechange/reference_classes.rb`

### Reference
- `reference/shapechange-sources/de/interactive_instruments/ShapeChange/ClassSelector.java`
- `examples/ShapeChangeConfig_Plateau_uro.xml` (shows `<appSchema>` structure)

---

## 🎓 Core Principle

**UML is the source of truth.**

Classes should come from the UML model, filtered by config `<appSchema>` entries.

NOT from hardcoded lists in reference_classes.rb.

---

**Status**: Reversion complete, ready to remove ReferenceClasses hack
**Next Session**: Implement proper ShapeChange filtering (4-6 hours)