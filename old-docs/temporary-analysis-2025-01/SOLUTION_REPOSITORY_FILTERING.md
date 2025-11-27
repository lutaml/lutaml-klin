# Solution: Repository Over-Inclusion Issue

## Problem Summary

**Discovered**: 2025-01-24
**Status**: Root cause identified, solution pending

### The Issue

When querying `classes_in_package("urf")`, the repository returns **208 classes**, but the reference XSD only contains types for **157 classes**. The **51 extra classes** are causing our generated XSD to have:
- 1,097 elements (vs 857 target) = +240 elements (+28%)
- 416 types (vs 322 target) = +94 types (+29%)

### The 51 Wrong Classes

**Breakdown by stereotype:**
- 40 DataType classes (e.g., `AccomodationType`, `AreaClassicificationType`)
- 7 FeatureType classes (e.g., `HousingLandDevelopmentStatus`, `IndicationMark`)
- 2 Union classes
- 1 ADEElement (`CityObjectGroup`)
- 1 with no stereotype (`FloodingDamage`)

**Examples:**
- `AccomodationType` - NOT in reference
- `AreaClassicificationType` - NOT in reference
- `CityObjectGroup` - ADEElement, should be in URO not URF
- `CommutingPopulationType` - NOT in reference
- `DisasterPreventionBaseType` - NOT in reference

### Why Filtering Failed

**Attempted approaches:**
1. ✅ **Suppression rules** - Implemented but not applicable (rules not in URF config)
2. ❌ **Package boundary check** - Failed (all classes have `package.nil?`)
3. ❌ **Visibility filtering** - All classes are public
4. ❌ **TaggedValue filtering** - No distinguishing tagged values found
5. ❌ **package_path attribute** - All classes return empty string

### Root Cause Analysis

The classes ARE in the UML package in Enterprise Architect. The issue is:
1. **LUR was built correctly** - All 208 classes exist in that package in the UML
2. **ShapeChange has additional logic** - It filters out 51 classes that we can't detect
3. **No class-level indicators** - The classes have no attributes we can use to filter them

**Package paths in repository:**
```ruby
# Actual path in index:
"ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.1::urf"

# But classes_in_package uses relative matching:
classes_in_package("urf")  # Matches ANY package ending with "urf"
```

## Possible Solutions

### Option 1: Reference-Based Filtering (Temporary Workaround)

Create a "known good" list from the reference XSD and use it to filter.

**Pros:**
- Immediate fix
- Guarantees correctness for PLATEAU

**Cons:**
- Not generic
- Requires maintenance
- Doesn't solve root cause

**Implementation:**
```ruby
# In XsdGenerator
REFERENCE_URF_CLASSES = [
  "Administration", "Agreement", "CensusBlock", 
  # ... 157 total classes from reference
].freeze

def apply_reference_filter(classes, package_name)
  return classes unless REFERENCE_URF_CLASSES

  classes.select do |c|
    REFERENCE_URF_CLASSES.include?(c.name)
  end
end
```

### Option 2: ShapeChange appSchemaName Logic (Proper Solution)

Investigate and implement ShapeChange's actual selection logic.

**ShapeChange uses:**
```xml
<parameter name="appSchemaName" value="urf"/>
<PackageInfo packageName=" urf" ns="..." xsdDocument="urbanFunction.xsd" version="3.2.1"/>
```

**Need to investigate:**
- How does ShapeChange resolve `appSchemaName="urf"` to actual packages?
- Does it use `PackageInfo` entries for filtering?
- Are there additional rules we're missing?

**Implementation approach:**
1. Read ShapeChange source code for `appSchemaName` handling
2. Check if `PackageInfo.packageName` is used as a filter
3. Implement equivalent logic in our code

### Option 3: Fix LUR Building (Long-term)

If classes shouldn't be in the package, fix how LUR is built.

**Need to check:**
- Is the EA model structure correct?
- Are classes correctly assigned to packages in EA?
- Is `lutaml` package parsing logic correct?

## Recommended Approach

**Phase 1 (Immediate - 1-2h):**
1. Create reference class list from URF XSD
2. Implement reference-based filter in XsdGenerator
3. Test with URF package - verify counts match

**Phase 2 (Proper Fix - 4-6h):**
1. Study ShapeChange's ClassSelector.java
2. Check how `appSchemaName` filters classes
3. Implement proper application schema logic
4. Remove reference-based filter

**Phase 3 (Validation - 2-3h):**
1. Test with both URF and URO packages
2. Verify against multiple reference XSDs
3. Document the selection logic

## Implementation Plan

### Immediate Fix (Reference-Based)

```ruby
# lib/lutaml/klin/shapechange/xsd_generator.rb

class XsdGenerator
  # Generated from reference XSD
  REFERENCE_CLASSES = {
    'urf' => %w[
      Administration Agreement CensusBlock DevelopmentProject
      # ... 157 total from urbanFunction.xsd
    ],
    'uro' => %w[
      # ... from urbanObject.xsd
    ]
  }.freeze

  def process_class(uml_class, xsd_document, rule_checker)
    # Apply reference filter before processing
    package_name = extract_package_name(config)
    
    if REFERENCE_CLASSES.key?(package_name)
      unless REFERENCE_CLASSES[package_name].include?(uml_class.name)
        log_filtered_class(uml_class, package_name)
        return
      end
    end
    
    # Continue with normal processing
    # ...
  end
end
```

### Proper Fix (ShapeChange Logic)

Study these ShapeChange files:
- `de/interactive_instruments/ShapeChange/ClassSelector.java`
- `de/interactive_instruments/ShapeChange/Target/XmlSchema/XmlSchema.java`
- `de/interactive_instruments/ShapeChange/Options.java` - appSchemaName handling

## Current Status

**Completed:**
- ✅ Investigation of repository behavior
- ✅ Identification of 51 wrong classes
- ✅ Analysis of class attributes
- ✅ Confirmation classes exist in UML
- ✅ Verification against reference XSD

**Next Steps:**
1. Extract class list from reference XSD
2. Implement reference-based filter
3. Test URF generation
4. Verify counts match (857 elements, 322 types)

## Files to Modify

1. `lib/lutaml/klin/shapechange/xsd_generator.rb` - Add filtering logic
2. `lib/lutaml/klin/shapechange/reference_classes.rb` - Class lists (new file)
3. Update tests to verify filtering

## Success Criteria

**Immediate:**
- URF: 857 ±10 elements, 322 ±10 types
- URO: 1,401 ±10 elements, 341 ±10 types
- No `CityObjectGroup` in URF
- No `AccomodationType` in URF

**Long-term:**
- Generic solution works for any application schema
- No hardcoded class lists
- Matches ShapeChange behavior exactly