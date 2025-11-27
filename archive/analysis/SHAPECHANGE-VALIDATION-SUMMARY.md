# ShapeChange Compatibility Validation - Final Summary

**Date:** 2025-11-11
**Task:** Validate lutaml-klin XSD output against ShapeChange reference
**Status:** ⚠️ VALIDATION FAILED - CRITICAL ISSUES IDENTIFIED

---

## Executive Summary

Comprehensive testing reveals that **lutaml-klin XSD generation is fundamentally broken** and cannot produce ShapeChange-compatible output for PLATEAU data. The generated schemas are **74% incomplete** due to missing property serialization.

### Validation Results

| Schema | Elements | Complex Types | Simple Types | ADE Hooks | Status |
|--------|----------|---------------|--------------|-----------|--------|
| **urbanObject (URO)** | 26% | 143% | 0% | 93% | ❌ FAIL |
| **urbanFunction (URF)** | 30% | 129% | N/A | N/A | ❌ FAIL |

**Overall Compatibility:** **0%** - Not compatible with ShapeChange

---

## Critical Findings

### 🔴 Issue #1: No Property Serialization (BLOCKER)

**Severity:** CRITICAL - Blocks all usage
**Impact:** 70-74% of schema content missing

**Evidence:**
- URO: 1,234 elements expected, 324 generated (missing 910)
- URF: 696 elements expected, 208 generated (missing 488)
- All complex type `<xs:sequence>` elements are **EMPTY**

**Example Comparison:**

```xml
<!-- ShapeChange Reference (urbanObject.xsd line 186-211) -->
<xs:complexType name="BridgeFunctionalAttributeType">
  <xs:sequence>
    <xs:element name="directionType" minOccurs="0" type="gml:CodeType"/>
    <xs:element name="userType" minOccurs="0" type="gml:CodeType"/>
  </xs:sequence>
</xs:complexType>

<!-- lutaml-klin Generated -->
<complexType name="BridgeFunctionalAttributeType">
  <sequence/>  <!-- ❌ COMPLETELY EMPTY -->
</complexType>
```

**Root Cause:**
[`PropertyElementProcessor`](lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb:22) calls `uml_class.attributes` which returns `[]` (empty array).

**Diagnosis:**
1. Either UML properties are not loaded from LUR files
2. Or the property accessor method is incorrect
3. The processor pipeline reaches but doesn't execute property serialization

---

### 🔴 Issue #2: Wrong GML Version (HIGH)

**Severity:** HIGH - Schema imports broken
**Impact:** Schemas won't validate against CityGML

**Problem:**
- ShapeChange uses: `http://www.opengis.net/gml` (GML 3.1.1)
- lutaml-klin uses: `http://www.opengis.net/gml/3.2` (GML 3.2.1)

**Location:** [`xsd_document.rb:163-169`](lib/lutaml/klin/shapechange/models/xsd_document.rb:163)

**Fix:** Make GML version configurable based on encoding rule

---

### 🔴 Issue #3: Missing Core Imports (HIGH)

**Severity:** HIGH - Cross-references fail
**Impact:** Type resolution broken

**Missing Imports:**
- URO: Missing `http://www.opengis.net/citygml/2.0`
- URF: Missing `http://www.opengis.net/citygml/2.0`, `https://www.geospatial.jp/iur/uro/3.2`

**Fix:** Implement automatic import detection from type references

---

### 🟡 Issue #4: Typo in Class Name (MEDIUM)

**Problem:** `AbstructConstruction` should be `AbstractConstruction`

**This is in the SOURCE LUR file**, not the generator.

**Fix:** Correct in `packages/plateau_all.lur`

---

### 🟡 Issue #5: Missing Enumerations (MEDIUM)

**Missing 8 simpleType enumerations:**
- `ConditionOfConstructionValue`
- `HightStatusValue`
- `IFCStateEnum`
- `IfcElementCompositionEnum`
- `IfcSIPrefix`
- `IfcTransportElementTypeEnum`
- `IfcUnitEnum`
- `ifcInternalOrExternalEnum`

**Fix:** Debug enumeration processor

---

### 🟡 Issue #6: Incorrect Substitution Groups (MEDIUM)

**Examples:**
- `_BoundarySurface`: Uses `uro:_CityObject` instead of `core:_CityObject`
- `UtilityNetworkElement`: Uses `uro:CityFurniture` instead of `frn:CityFurniture`
- `PublicLand`: Uses `uro:LandUse` instead of `luse:LandUse`
- `Waterway`: Uses `uro:TrafficComplex` instead of `tran:TransportationComplex`

**Fix:** Improve type reference resolution to use correct external namespaces

---

### 🟡 Issue #7: Missing Abstract Attributes (MEDIUM)

Several elements missing `abstract="true"`:
- `_BoundarySurface`
- `UtilityLink`
- `UtilityNetworkElement`
- `UtilityNode`
- `UtilityNodeContainer`

**Fix:** Transfer UML `isAbstract` to XSD `abstract` attribute

---

### 🟢 Issue #8: Missing attributeFormDefault (LOW)

Schema should have `attributeFormDefault="unqualified"` to match ShapeChange.

---

## Key Statistics

### urbanObject (URO)

```
Reference (ShapeChange):
  Imports: 12
  Elements: 1,234
  Complex Types: 341
  Simple Types: 8
  ADE Hooks: 99

Generated (lutaml-klin):
  Imports: 11 (-8%)
  Elements: 324 (-74% ❌)
  Complex Types: 487 (+43%)
  Simple Types: 0 (-100% ❌)
  ADE Hooks: 92 (-7%)
```

### urbanFunction (URF)

```
Reference (ShapeChange):
  Imports: 3
  Elements: 696
  Complex Types: 322
  Simple Types: 0
  ADE Hooks: 0

Generated (lutaml-klin):
  Imports: 1 (-67% ❌)
  Elements: 208 (-70% ❌)
  Complex Types: 416 (+29%)
  Simple Types: 0 (✓)
  ADE Hooks: 0 (✓)
```

---

## Architecture Analysis

### Current Pipeline (BROKEN)

```
1. Load UML from LUR ✅
   ↓
2. Find package & classes ✅
   ↓
3. For each class:
   a. ObjectElementProcessor ✅
      → Creates <xs:element name="ClassName"/>
   b. ComplexTypeProcessor ✅
      → Creates <xs:complexType name="ClassNameType">
      → Sets up extension if needed
   c. SequenceProcessor ✅
      → Creates <xs:sequence/>
   d. PropertyElementProcessor ❌ BROKEN
      → Should add property elements
      → Line 22: attributes = uml_class.attributes || []
      → Returns [] (empty!)
   e. Result: Empty sequences ❌
```

### Why Properties Are Missing

**Hypothesis 1:** `uml_class.attributes` method is wrong
- The lutaml-xmi API may use different method names
- Possible correct methods: `.properties`, `.owned_attributes`, `.attributes()`

**Hypothesis 2:** Properties not loaded from LUR
- LUR package may be missing property data
- Serialization may be incomplete during LUR creation

**Hypothesis 3:** Properties filtered out
- Some encoding rule may be suppressing properties
- Check `rule-xsd-prop-notEncoded` or similar rules

---

## Recommended Next Steps

### Phase 1: Diagnose Property Access (Immediate)

1. **Verify LUR Contains Properties**
   ```bash
   # Check raw LUR content
   unzip -l packages/plateau_all.lur | grep -i property
   ```

2. **Check lutaml-xmi API**
   - Read lutaml-xmi documentation
   - Test property access methods directly
   - Update `PropertyElementProcessor` to use correct API

3. **Add Debug Logging**
   - Log when PropertyElementProcessor is called
   - Log what `uml_class.attributes` returns
   - Log property count for each class

### Phase 2: Fix Property Serialization (Critical)

**File:** [`property_element_processor.rb`](lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb:22)

**Change Line 22 from:**
```ruby
attributes = uml_class.attributes || []
```

**To:** (depending on correct API)
```ruby
attributes = uml_class.properties || uml_class.owned_attributes || []
```

**Or add fallback:**
```ruby
attributes = begin
  uml_class.attributes
rescue NoMethodError
  uml_class.properties || uml_class.owned_attributes || []
end
```

### Phase 3: Fix Other Issues

1. **GML Version**
   - [`xsd_document.rb:163`](lib/lutaml/klin/shapechange/models/xsd_document.rb:163)
   - Add `gml_version` parameter, default to "3.1.1" for CityGML

2. **Imports**
   - Add import detection logic
   - Scan type references before generating schema
   - Add required namespace imports

3. **Substitution Groups**
   - Fix namespace resolution
   - Use external namespace prefixes for base types

4. **Abstract Attributes**
   - Ensure `is_abstract` transfers to `abstract="true"`

5. **Enumerations**
   - Debug why simpleTypes not generated
   - Check EnumerationProcessor

6. **Source Typo**
   - Fix in LUR: `AbstructConstruction` → `AbstractConstruction`

### Phase 4: Regenerate and Validate

1. Apply all fixes
2. Regenerate XSD for URO and URF
3. Run comparison script again
4. Verify 100% compatibility achieved

---

## Testing Strategy

### Minimal Test Case

Create a test with single class:

**Input (UML):**
```
Class: TestBuilding
  extends: Building
  properties:
    - name: testProperty
      type: CharacterString
      cardinality: 0..1
```

**Expected Output (XSD):**
```xml
<xs:element name="TestBuilding" type="uro:TestBuildingType"/>
<xs:complexType name="TestBuildingType">
  <xs:complexContent>
    <xs:extension base="bldg:BuildingType">
      <xs:sequence>
        <xs:element name="testProperty" minOccurs="0" type="xs:string"/>
      </xs:sequence>
    </xs:extension>
  </xs:complexContent>
</xs:complexType>
```

If this fails, the PR<truncated>