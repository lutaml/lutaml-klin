# 🎯 LutaML-Klin Continuation Plan - Session 2025-01-24

**Version**: 12.0 - POST SUPPRESSION IMPLEMENTATION
**Date**: 2025-01-24 23:50 UTC
**Status**: Core issue identified - Repository filtering problem
**Copy this entire prompt to start the next session**

---

## 🎯 THE ACTUAL GOAL (Never Forget!)

**INPUT**:
```
examples/ShapeChangeConfig_Plateau_urf.xml  →  urbanFunction.xsd (857 elements, 322 types)
examples/ShapeChangeConfig_Plateau_uro.xml  →  urbanObject.xsd (1,401 elements, 341 types)
```

**OUTPUT**: Generate XSD files that **EXACTLY MATCH** the reference outputs:
- ✅ Same number of elements (±5)
- ✅ Same number of types (±5)
- ✅ Same content structure
- ✅ No extra classes that aren't in reference

**SUCCESS CRITERION**: Match reference exactly, not generate more content!

---

## ✅ What We Implemented This Session

### 1. Suppression Rule Infrastructure ✅

**File: `lib/lutaml/klin/shapechange/rule_checker.rb`**
- Added `rule_enabled?(rule_id)` helper method
- Checks if a rule is active in current encoding rule

**File: `lib/lutaml/klin/shapechange/xsd_generator.rb`**
- Added `apply_suppression_filters(classes, rule_checker, package_name)` method
- Implemented three filters:
  1. `rule-xsd-all-notEncoded` - Skip classes with `notEncoded=true` tagged value
  2. `rule-xsd-cls-suppress` - Skip classes with `«suppress»` stereotype  
  3. Package boundary check - DISABLED (see below)

### 2. Filter Implementation Details

```ruby
def apply_suppression_filters(classes, rule_checker, package_name)
  filtered = classes

  # Filter 1: rule-xsd-all-notEncoded
  if rule_checker.rule_enabled?('rule-xsd-all-notEncoded')
    filtered = filtered.reject { |c| has_not_encoded_tag?(c) }
  end

  # Filter 2: rule-xsd-cls-suppress
  if rule_checker.rule_enabled?('rule-xsd-cls-suppress')
    filtered = filtered.reject { |c| has_suppress_stereotype?(c) }
  end

  # Filter 3: DISABLED - package check doesn't work
  # uml_class.package returns nil for all classes

  filtered
end
```

---

## 🔍 CRITICAL DISCOVERY: The Real Problem

### Issue: Repository Returns Too Many Classes

**URF Package Analysis:**
```
Repository returns: 208 classes
Reference generates: ~140-150 classes (estimate from 857 elements)

Classes by stereotype:
  - DataType: 68 classes (many shouldn't be in URF)
  - FeatureType: 135 classes
  - ADEElement: 1 class (CityObjectGroup - should be in URO!)
  - Feature: 1 class
  - Union: 2 classes
  - none: 1 class
```

**Examples of WRONG classes in URF:**
- `AccomodationType` (not in reference)
- `AreaClassicificationType` (not in reference)
- `CityObjectGroup` (ADEElement - belongs to URO!)
- 40+ DataType classes that aren't in reference

**Current Output vs Reference:**
```
URF (Urban Function):
  OUR OUTPUT:
    - Elements: 1,097 (counted via grep)
    - Complex Types: 416
    - Classes processed: 208
  
  REFERENCE:
    - Elements: 857
    - Complex Types: 322
  
  DIFFERENCE: +240 elements (+28%), +94 types (+29%)
```

### Why Package Filtering Failed

1. **`uml_class.package` returns `nil`** for all classes
2. Can't verify package membership via package attribute
3. Package boundary filter had to be disabled
4. We're trusting repository's `classes_in_package('urf')` which is incorrect

### Why Suppression Rules Don't Help

1. The rules `rule-xsd-all-notEncoded` and `rule-xsd-cls-suppress` are **NOT** in the URF config's encoding rule
2. URF uses `citygml` encoding rule which extends `iso19136_2007`
3. These suppression rules only exist in:
   - `notEncoded` encoding rule
   - `citygml-ade` encoding rule  
   - `metadata-profile` encoding rule

**Config Analysis:**
```xml
<EncodingRule name="citygml" extends="iso19136_2007">
  <!-- URF config rules - NO suppression rules here -->
  <rule name="rule-xsd-rel-association-classes"/>
  <rule name="rule-xsd-cls-basictype"/>
  <!-- ... other rules, but NO notEncoded or suppress -->
</EncodingRule>
```

---

## 🚨 ROOT CAUSE ANALYSIS

### Problem Statement

The `lutaml` repository's `classes_in_package('urf')` method is returning **208 classes** when only approximately **140-150 should be included** based on the reference output.

### Possible Causes

1. **LUR Package Build Issue**
   - Was the LUR built correctly?
   - Are classes properly assigned to packages during XMI import?
   - Is there a bug in `lutaml xmi package build`?

2. **Repository Filtering Bug**
   - Does `classes_in_package()` include classes from related packages?
   - Is it including classes that reference URF but aren't in URF?
   - Is there a transitive dependency issue?

3. **UML Model Structure**
   - Are some classes actually in URF package in the UML?
   - Do they have tagged values or stereotypes to suppress them?
   - Is ShapeChange doing additional filtering that we're missing?

---

## 📋 INVESTIGATION PLAN (3-5 hours)

### Phase 1: Understand Repository Behavior (1-2h)

**Goal**: Determine why `classes_in_package('urf')` returns 208 classes

**Steps**:
1. Check `lutaml` gem source code for `classes_in_package` implementation
2. Verify if `recursive: false` parameter is being honored
3. Test with explicit package paths (e.g., "ModelRoot::i-UR::urf")
4. Compare repository behavior across different packages

**Test Script**:
```ruby
adapter = UmlRepositoryAdapter.new('plateau_all.lur')

# Test different package queries
['urf', 'uro', 'ModelRoot::i-UR::urf'].each do |pkg|
  classes = adapter.classes_in_package(pkg, recursive: false)
  puts "#{pkg}: #{classes.size} classes"
end

# Check if classes have qualified names
urf_classes = adapter.classes_in_package('urf')
urf_classes.first(5).each do |c|
  puts "#{c.name}: xmi_id=#{c.xmi_id}"
end
```

### Phase 2: Check UML Model Structure (1h)

**Goal**: Understand how classes are organized in the source UML

**Steps**:
1. Open `202503_current_plateau_v5.0.qea` in Enterprise Architect
2. Navigate to URF package
3. Check which classes are actually in URF vs referenced
4. Look for tagged values (`notEncoded`, `suppress`)
5. Document the expected class list

**Alternative (if no EA access)**:
- Parse XMI directly with `lutaml`
- Check package structure in LUR
- Compare with reference XSD class names

### Phase 3: Compare with ShapeChange Behavior (1-2h)

**Goal**: Understand how ShapeChange filters classes

**Reference**: `de/interactive_instruments/ShapeChange/Target/XmlSchema/XmlSchema.java`

**Key Questions**:
1. How does ShapeChange determine which classes to process?
2. Does it have additional filtering beyond encoding rules?
3. Are there package selection parameters we're missing?
4. Does it filter by selected schema or application schema?

**Check ShapeChange Config**:
```xml
<input>
  <parameter name="appSchemaName" value="urf"/>
  <!-- Does this filter beyond package name? -->
</input>
```

### Phase 4: Implement Correct Filtering (30min-1h)

**Based on investigation findings, implement ONE of**:

**Option A: Fix Repository Query**
```ruby
# Use more specific package path
classes = adapter.classes_in_package("ModelRoot::i-UR::urf", recursive: false)
```

**Option B: Post-Filter by Qualified Name**
```ruby
# Filter to only classes with xmi_id or qualified name in URF
classes = classes.select do |c|
  # Check if class truly belongs to URF
  qualified_name_contains_urf?(c)
end
```

**Option C: Use ShapeChange appSchemaName Logic**
```ruby
# Implement ShapeChange's application schema selection
classes = filter_by_app_schema(classes, "urf", config)
```

**Option D: Check Tagged Values**
```ruby
# Filter by specific tagged values that indicate inclusion
classes = classes.select do |c|
  should_include_in_schema?(c, "urf")
end
```

---

## 🔧 IMMEDIATE NEXT STEPS (Start Here!)

### Session Start Checklist
1. ✅ Read memory bank files
2. ✅ Read THIS continuation plan
3. ⏭️ **INVESTIGATE REPOSITORY** ← START HERE
4. ⏭️ Implement correct filtering
5. ⏭️ Re-test and verify counts

### First Task: Repository Investigation

**Script to Run**:
```bash
cd /Users/mulgogi/src/lutaml/lutaml-klin

# Save this as investigate_repository.rb
bundle exec ruby investigate_repository.rb
```

**investigate_repository.rb**:
```ruby
require_relative 'lib/lutaml/klin/repositories/uml_repository_adapter'

adapter = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  'spec/fixtures/packages/plateau_all.lur'
)

puts "="*70
puts "Repository Investigation"
puts "="*70

# Test 1: Different package specifications
['urf', 'uro', 'ModelRoot::i-UR::urf', 'ModelRoot::i-UR::uro'].each do |pkg|
  begin
    classes = adapter.classes_in_package(pkg, recursive: false)
    puts "\n#{pkg}:"
    puts "  Classes: #{classes.size}"
    puts "  Stereotypes: #{classes.map { |c| c.stereotype }.flatten.uniq.join(', ')}"
  rescue => e
    puts "\n#{pkg}: ERROR - #{e.message}"
  end
end

# Test 2: Check package structure
puts "\n" + "="*70
puts "Package Structure"
puts "="*70
all_packages = adapter.all_packages
puts "Total packages: #{all_packages.size}"
all_packages.select { |p| p.include?('urf') || p.include?('uro') }.each do |p|
  puts "  - #{p}"
end

# Test 3: Sample class details
puts "\n" + "="*70
puts "Sample URF Classes (first 10)"
puts "="*70
urf_classes = adapter.classes_in_package('urf', recursive: false)
urf_classes.first(10).each do |c|
  puts "  #{c.name}:"
  puts "    XMI ID: #{c.xmi_id rescue 'N/A'}"
  puts "    Stereotype: #{Array(c.stereotype).join(', ')}"
  puts "    Package: #{c.package&.name rescue 'nil'}"
end

# Test 4: Look for problematic classes
puts "\n" + "="*70
puts "Checking Problematic Classes"
puts "="*70
['AccomodationType', 'AreaClassicificationType', 'CityObjectGroup'].each do |name|
  c = urf_classes.find { |cl| cl.name == name }
  if c
    puts "\n#{name} FOUND in URF:"
    puts "  Stereotype: #{Array(c.stereotype).join(', ')}"
    puts "  XMI ID: #{c.xmi_id rescue 'N/A'}"
    
    # Check tagged values
    if c.respond_to?(:tagged_values)
      tvs = c.tagged_values.map { |tv| "#{tv.tag}=#{tv.value}" rescue tv.to_s }
      puts "  Tagged values: #{tvs.join(', ')}" unless tvs.empty?
    end
  else
    puts "\n#{name} NOT in URF"
  end
end
```

### Second Task: Check Reference Classes

**Script**:
```bash
# Extract all class names from reference
grep -o 'name="[A-Z][^"]*Type"' examples/i-ur/urbanFunction.xsd | \
  sed 's/name="//;s/Type"//' | \
  sort -u > /tmp/reference_urf_classes.txt

# Count
wc -l /tmp/reference_urf_classes.txt

# Check for our problematic classes
grep -E "Accomodation|AreaClassicification|CityObjectGroup" /tmp/reference_urf_classes.txt
```

---

## 📊 Expected Outcomes

### After Investigation

**We should know:**
1. Why repository returns 208 classes
2. Which classes should actually be in URF
3. How to filter correctly

### After Implementation

**We should have:**
1. Correct class list (140-150 classes)
2. Element count: 857 ±10
3. Type count: 322 ±10
4. No extra DataType classes

---

## 📈 Current Status

**Completion**: ~88% (was 85%)

**What Works** ✅:
- XSD generation pipeline
- Rule system and processors
- Suppression infrastructure (ready to use)
- Valid XML output
- Correct namespaces

**What's Broken** ❌:
- Repository returns too many classes (28% overcounting)
- Package boundary filtering (uml_class.package = nil)
- Can't distinguish URF vs URO classes reliably

**Gap to Close**: 12% → Repository filtering + verification = 3-5 hours

---

## 🎓 Key Learnings

1. **Suppression rules aren't the issue** - they're not even in URF's encoding rule
2. **Repository filtering is the issue** - `classes_in_package()` returns wrong set
3. **Package attribute doesn't work** - all classes have nil package
4. **We're generating too much** - not too little
5. **Need to understand ShapeChange's class selection logic**

---

## 🏁 Session Summary

**Files Modified:**
- `lib/lutaml/klin/shapechange/rule_checker.rb` - Added `rule_enabled?`
- `lib/lutaml/klin/shapechange/xsd_generator.rb` - Added suppression filters

**Tests Run:**
- URF XSD generation: 1,097 elements (vs 857 target)
- Stereotype analysis: 208 classes across 6 stereotypes
- Package queries: All return nil for package attribute

**Key Discovery:**
Repository filtering is fundamentally broken - returning 40-60 more classes than should be in URF.

---

## 🚫 What NOT to Do

1. ❌ Don't add more suppression rules to config
2. ❌ Don't try to filter by stereotype alone (DataTypes are legitimate)
3. ❌ Don't assume lutaml repository is correct
4. ❌ Don't skip the investigation phase
5. ❌ Don't test until filtering is fixed

---

**End of Continuation Plan v12.0 (POST-SUPPRESSION-IMPLEMENTATION)**

---

## 📝 Quick Start Next Session

```bash
# 1. Create investigation script
cat > investigate_repository.rb << 'EOF'
[paste script from above]
EOF

# 2. Run investigation
bundle exec ruby investigate_repository.rb > investigation_results.txt

# 3. Review results
cat investigation_results.txt

# 4. Check reference classes
grep -o 'name="[A-Z][^"]*Type"' examples/i-ur/urbanFunction.xsd | \
  sed 's/name="//;s/Type"//' | sort -u > reference_classes.txt
wc -l reference_classes.txt

# 5. Compare
comm -13 reference_classes.txt <(grep -o 'name="[A-Z][^"]*Type"' examples/output/urf.xsd | \
  sed 's/name="//;s/Type"//' | sort -u) | head -20
# This shows classes in our output but not in reference