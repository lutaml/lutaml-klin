# ShapeChange Compatibility Validation - Critical Findings

**Generated:** 2025-11-11
**Status:** ⚠️ CRITICAL ISSUES IDENTIFIED

## Executive Summary

The comparison between lutaml-klin-generated XSD and ShapeChange reference output reveals **CRITICAL compatibility issues** that prevent lutaml-klin from producing functionally equivalent schemas for PLATEAU data.

### Severity Assessment

**BLOCKER** - The generated XSD schemas are **semantically incomplete** and cannot be used as replacements for ShapeChange output.

---

## Critical Issue #1: Missing Property/Attribute Serialization 🔴

### Impact: BLOCKER

**The most severe issue:** UML class properties and attributes are **NOT being serialized** into XSD element sequences.

### Evidence

#### urbanObject (URO)
- **Reference:** 1,234 elements
- **Generated:** 324 elements
- **Missing:** 910 elements (74% missing)

#### urbanFunction (URF)
- **Reference:** 696 elements
- **Generated:** 208 elements
- **Missing:** 488 elements (70% missing)

### Root Cause

Looking at the ShapeChange reference output, complex types contain full property definitions:

```xml
<!-- ShapeChange Reference -->
<xs:complexType name="AppurtenanceType">
  <xs:complexContent>
    <xs:extension base="uro:UtilityNodeType">
      <xs:sequence>
        <xs:element name="appurtenanceType" minOccurs="0" type="gml:CodeType"/>
      </xs:sequence>
    </xs:extension>
  </xs:complexContent>
</xs:complexType>
```

But lutaml-klin generates **empty sequences**:

```xml
<!-- lutaml-klin Generated -->
<complexType name="AppurtenanceType">
  <complexContent>
    <extension base="uro:UtilityNodeType">
      <sequence/>  <!-- ❌ EMPTY! -->
    </extension>
  </complexContent>
</complexType>
```

### Diagnosis

The XSD generation pipeline is **not processing UML properties/attributes**. The processors create:
1. ✅ Object element declarations
2. ✅ Complex type definitions
3. ✅ Property type wrappers
4. ❌ **Property elements within sequences** ← MISSING

**Files to investigate:**
- [`lib/lutaml/klin/shapechange/rule_processors/sequence_processor.rb`](lib/lutaml/klin/shapechange/rule_processors/sequence_processor.rb)
- [`lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb`](lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb)

---

## Critical Issue #2: Wrong GML Version 🔴

### Impact: HIGH - Schema Validation Failure

**ShapeChange uses:** GML 3.1.1 (`http://www.opengis.net/gml`)
**lutaml-klin uses:** GML 3.2.1 (`http://www.opengis.net/gml/3.2`)

### Evidence

```xml
<!-- ShapeChange Reference -->
<xs:import namespace="http://www.opengis.net/gml"
           schemaLocation="http://schemas.opengis.net/gml/3.1.1/base/gml.xsd"/>

<!-- lutaml-klin Generated -->
<import namespace="http://www.opengis.net/gml/3.2"
        schemaLocation="http://schemas.opengis.net/gml/3.2.1/gml.xsd"/>
```

### Root Cause

The standard imports in [`lib/lutaml/klin/shapechange/models/xsd_document.rb:163-169`](lib/lutaml/klin/shapechange/models/xsd_document.rb:163) hardcode GML 3.2:

```ruby
def add_standard_imports
  # GML 3.2 is the standard for geometric types
  add_import(
    namespace: "http://www.opengis.net/gml/3.2",
    location: "http://schemas.opengis.net/gml/3.2.1/gml.xsd"
  )
end
```

This should be **configurable** based on the encoding rule.

---

## Critical Issue #3: Missing Core Imports 🔴

### Impact: HIGH - Schema Cannot Resolve Types

Missing critical namespace imports:
- ❌ `http://www.opengis.net/citygml/2.0` (core CityGML)
- ❌ Individual CityGML module namespaces in some cases

### Root Cause

Import generation logic does not:
1. Detect cross-package type references
2. Add required namespace imports automatically
3. Include standard CityGML imports for ADE schemas

---

## Critical Issue #4: Typo in UML Class Name 🟡

### Impact: MEDIUM - Name Mismatch

**Reference:** `AbstractConstruction`
**Generated:** `AbstructConstruction` (typo: missing "a")

### Root Cause

This typo exists in the **source LUR file** (`packages/plateau_all.lur`). The typo propagates to all generated outputs.

**Fix:** Correct in LUR source file.

---

## Critical Issue #5: Missing Simple Types (Enumerations) 🟡

### Impact: MEDIUM - Type Validation Incomplete

Missing 8 enumeration types:
- `ConditionOfConstructionValue`
- `HightStatusValue`
- `IFCStateEnum`
- `IfcElementCompositionEnum`
- `IfcSIPrefix`
- `IfcTransportElementTypeEnum`
- `IfcUnitEnum`
- `ifcInternalOrExternalEnum`

### Root Cause

Enumeration processor may not be:
1. Detecting all UML enumerations
2. Applying correct enumeration encoding rules
3. Generating `<xs:simpleType>` with restrictions

---

## Critical Issue #6: Incorrect Substitution Groups 🟡

### Impact: MEDIUM - Type Hierarchy Broken

Many elements reference wrong base types:

| Element | Reference | Generated | Issue |
|---------|-----------|-----------|-------|
| `_BoundarySurface` | `core:_CityObject` | `uro:_CityObject` | Wrong namespace |
| `ConstructionInstallation` | `core:_CityObject` | `uro:_CityObject` | Wrong namespace |
| `UtilityNetworkElement` | `frn:CityFurniture` | `uro:CityFurniture` | Wrong namespace |
| `PublicLand` | `luse:LandUse` | `uro:LandUse` | Wrong namespace |
| `Waterway` | `tran:TransportationComplex` | `uro:TrafficComplex` | Wrong type name |

### Root Cause

Substitution group resolution is using **local namespaces** instead of **external CityGML namespaces** when referencing base CityGML types.

---

## Critical Issue #7: Missing Abstract Attributes 🟡

### Impact: MEDIUM - Instantiation Control Lost

Several abstract elements missing `abstract="true"`:
- `_BoundarySurface`
- `UtilityLink`
- `UtilityNetworkElement`
- `UtilityNode`
- `UtilityNodeContainer`

### Root Cause

Abstract marker from UML `isAbstract` not being transferred to XSD `abstract` attribute.

---

## Critical Issue #8: Missing attributeFormDefault 🟢

### Impact: LOW - Syntactic Difference

**Reference:** `attributeFormDefault="unqualified"`
**Generated:** Missing

While this is technically valid (defaults to "unqualified"), it should match ShapeChange for consistency.

---

## Statistical Summary

### urbanObject (URO)

| Metric | Reference | Generated | Match | Gap |
|--------|-----------|-----------|-------|-----|
| Imports | 12 | 11 | ✗ | -1 (8%) |
| Elements | 1,234 | 324 | ✗ | **-910 (74%)** |
| Complex Types | 341 | 487 | ✗ | +146 |
| Simple Types | 8 | 0 | ✗ | **-8 (100%)** |
| ADE Hooks | 99 | 92 | ✗ | -7 (7%) |

### urbanFunction (URF)

| Metric | Reference | Generated | Match | Gap |
|--------|-----------|-----------|-------|-----|
| Imports | 3 | 1 | ✗ | -2 (67%) |
| Elements | 696 | 208 | ✗ | **-488 (70%)** |
| Complex Types | 322 | 416 | ✗ | +94 |
| Simple Types | 0 | 0 | ✓ | 0 |
| ADE Hooks | 0 | 0 | ✓ | 0 |

---

## Root Cause Analysis

### Primary Issue: Property Serialization Pipeline Broken

The XSD generation has a **fundamental architectural flaw** in the property serialization pipeline:

1. ✅ **Phase 1: Class Processing** - Classes are detected and processed
2. ✅ **Phase 2: Type Definition** - Complex types are created
3. ✅ **Phase 3: Inheritance** - Extension/restriction handled
4. ❌ **Phase 4: Property Serialization** - **BROKEN** - Properties not added to sequences
5. ❌ **Phase 5: Type Mapping** - **BROKEN** - XSD types not resolved

**The sequence processor creates empty `<xs:sequence/>` elements but never populates them with property elements.**

### Secondary Issues

2. **GML Version Hardcoded** - Should be configurable per encoding rule
3. **Import Detection Missing** - No cross-package dependency analysis
4. **Type Resolution Incomplete** - External type references not resolved to proper namespaces

---

## Hypothesized Data Flow Issue

```
UML Repository (LUR)
    ↓
  Classes & Properties Loaded ✅
    ↓
  ObjectElementProcessor ✅
    → Creates <xs:element name="ClassName"/>
    ↓
  ComplexTypeProcessor ✅
    → Creates <xs:complexType name="ClassNameType">
    ↓
  SequenceProcessor ✅
    → Creates <xs:sequence/>
    ↓
  PropertyElementProcessor ❌ NOT CALLED OR NOT WORKING
    → Should add <xs:element name="propertyName" type="..."/>
    ↓
  Result: Empty sequences!
```

---

## Recommended Fix Priority

### P0 - BLOCKER (Must Fix)
1. ✅ **Fix property serialization** - Properties must be added to sequences
2. ✅ **Fix GML version configuration** - Use GML 3.1.1 for CityGML
3. ✅ **Fix import generation** - Add required CityGML imports

### P1 - HIGH (Should Fix)
4. **Fix substitution groups** - Use correct external namespaces
5. **Fix abstract attributes** - Transfer UML `isAbstract` to XSD
6. **Add simple type generation** - Generate enumerations

### P2 - MEDIUM (Nice to Fix)
7. Fix typo: `AbstructConstruction` → `AbstractConstruction` (in LUR source)
8. Add `attributeFormDefault="unqualified"` to schema element

---

## Next Steps

1. **Investigate property serialization code path**
   - Read [`PropertyElementProcessor`](lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb)
   - Read [`SequenceProcessor`](lib/lutaml/klin/shapechange/rule_processors/sequence_processor.rb)
   - Determine why properties are not being added to sequences

2. **Add logging to trace property processing**
   - Add debug output showing which properties are being processed
   - Log why properties might be skipped

3. **Review UML property access patterns**
   - Verify UML repository correctly exposes class properties
   - Check if properties have required metadata (type, cardinality)

4. **Create minimal test case**
   - Generate XSD for single class with 1-2 properties
   - Verify property elements appear in sequence
   - Debug from minimal example

5. **Fix and regenerate**
   - Apply fixes to property serialization
   - Regenerate XSD schemas
   - Re-run comparison script
   - Verify 100% compatibility

---

## Conclusion

**Current Status:** ❌ INCOMPATIBLE

lutaml-klin XSD generation is **fundamentally broken** due to missing property serialization. The generated schemas are **structurally incomplete** and cannot be used as ShapeChange replacements.

**Estimated Effort:** High - Requires architectural fix to property serialization pipeline.

**Blocking:** All downstream PLATEAU schema validation and usage.