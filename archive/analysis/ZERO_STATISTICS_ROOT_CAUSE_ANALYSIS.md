# Root Cause Analysis: "0/0" Statistics Issue

## Problem Statement

The processing completes but shows:
```
📊  Statistics:
   • Packages processed: 0
   • Classes: 0/0 resolved (0.0%)
   • Attributes: 0/0 resolved
```

This suggests **no mappings were created**, not that resolution failed.

## Hypothesis Tree

### H1: No Classes Found ❓
**If true**: `classes_in_package()` returns empty array

**Check**:
- Does LUR package have classes for "uro"?
- Is package name matching working?
- Are classes being filtered out?

**Evidence**: Package filtering shows "uro → uro (255 classes)" so classes EXIST

**Conclusion**: ❌ Classes are found during filtering

### H2: Statistics Calculation Error ✅ LIKELY
**If true**: `PackageMapping.calculate_statistics()` returns zeros

**Check**:
- How does `calculate_statistics()` work?
- What does it count?
- Is the data structure correct?

**Evidence**: Processing shows all 255 classes being processed in verbose output

**Conclusion**: ✅ Likely issue - statistics method bug

### H3: Mapping Models Not Populated ✅ LIKELY
**If true**: ClassMapping/AttributeMapping objects created but empty

**Check**:
- Are mappings being created?
- Are they added to PackageMapping?
- Are resolution details populated?

**Evidence**: Verbose shows attributes being processed but all showing `✗ none`

**Conclusion**: ✅ Likely - mappings created but resolution_status not set

## Investigation Plan

### Step 1: Check PackageMapping Statistics Method

**File**: [`lib/lutaml/klin/models/mapping/package_mapping.rb`](lib/lutaml/klin/models/mapping/package_mapping.rb)

**Look for**:
```ruby
def calculate_statistics
  # What does this method return?
  # How does it count resolved vs unresolved?
end

def resolution_rate
  # How is this calculated?
end
```

### Step 2: Check SchemaMapping Statistics Method

**File**: [`lib/lutaml/klin/models/mapping/schema_mapping.rb`](lib/lutaml/klin/models/mapping/schema_mapping.rb)

**Look for**:
```ruby
def calculate_statistics
  # How are package statistics aggregated?
end
```

### Step 3: Check ProcessingResult Display

**File**: [`lib/lutaml/klin/commands/process_command.rb`](lib/lutaml/klin/commands/process_command.rb)

**Look for**: How statistics are displayed in summary

### Step 4: Verify Mapping Creation

**Add debug output** to MappingWorkflow:

```ruby
def generate_mapping_for_package(package_path, ...)
  uml_classes = uml_repository.classes_in_package(package_path, recursive: recursive)

  puts "DEBUG: Found #{uml_classes.size} classes"

  class_mappings = uml_classes.map.with_index do |uml_class, idx|
    cm = build_class_mapping(uml_class, xsd_namespace, ...)
    puts "DEBUG: Created mapping for #{uml_class.name} with #{cm.attribute_mappings.size} attributes"
    cm
  end

  pkg_mapping = PackageMapping.new.tap do |pm|
    pm.class_mappings = class_mappings
    puts "DEBUG: PackageMapping has #{pm.class_mappings.size} class mappings"
  end
end
```

## Most Likely Root Cause

**Hypothesis**: The statistics are calculated from `class_mappings` array, but:

1. Either `class_mappings` is empty (unlikely - verbose shows 255 classes)
2. Or statistics method doesn't count properly
3. Or resolution_status field isn't set correctly

**Evidence**:
- Verbose shows: "Processing class: X" for all 255 classes
- Verbose shows: `✗ none` for all attributes
- But summary shows: "0/0"

**Most Likely**:
- Mappings ARE created
- Resolution status is always "unresolved"
- Statistics method counts resolved/unresolved
- Since ALL are unresolved, both numbers are zero?

**Wait**: "0/0" means ZERO total, not "0 resolved out of total"

**Actual Root Cause**: The class_mappings array is NOT being added to PackageMapping!

## The Real Issue (Most Likely)

Look at [`MappingWorkflow.generate_mapping_for_package()`](lib/lutaml/klin/application/mapping_workflow.rb:116-148):

```ruby
def generate_mapping_for_package(package_path, recursive: false)
  # ... find package ...
  # ... get classes ...

  class_mappings = uml_classes.map do |uml_class|
    build_class_mapping(uml_class, xsd_namespace)
  end

  # 5. Build and return PackageMapping
  Mapping::PackageMapping.new.tap do |pkg_mapping|
    pkg_mapping.class_mappings = class_mappings  # ← IS THIS LINE WORKING?
    # ...
  end
end
```

**Check if**:
- `class_mappings` is populated
- `.class_mappings=` assignment works
- PackageMapping model has `class_mappings` attribute

## Action Plan

### Immediate (Code Mode)

1. Add debug logging to verify:
   - How many classes found
   - How many mappings created
   - What's in the PackageMapping object

2. Check PackageMapping model:
   - Does it have `class_mappings` attribute?
   - Is it a collection?
   - Can it be assigned?

3. Check statistics calculation:
   - Read the actual implementation
   - Understand counting logic
   - Fix if broken

### Expected Fix

Most likely one of:
- Missing attribute definition
- Wrong method name
- Statistics method not counting the data

**Once fixed**, should see real numbers like "Classes: 950/1141 resolved (83%)"

## Summary

The "0/0" is a **data structure issue**, not a resolution issue. The system is processing classes and attributes (verbose shows this), but the statistics calculation returns zero, suggesting the data isn't being stored correctly in the PackageMapping/SchemaMapping models.

**Next**: Code Mode to investigate and fix the data structure issue.