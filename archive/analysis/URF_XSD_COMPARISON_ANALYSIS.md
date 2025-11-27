# URF XSD Comparison Analysis

## Executive Summary

Comparison between generated [`final_schemas/urbanFunction.xsd`](../final_schemas/urbanFunction.xsd) and reference [`examples/i-ur/urbanFunction.xsd`](../examples/i-ur/urbanFunction.xsd) reveals **significant structural differences** that prevent the generated XSD from being functionally equivalent to the PLATEAU reference schema.

**Status**: ❌ **NOT EQUIVALENT** - Major fixes required

---

## Comparison Statistics

| Metric | Generated | Reference | Difference |
|--------|-----------|-----------|------------|
| **Elements** | 208 | 696 | -488 (-70%) |
| **ComplexTypes** | 416 | 322 | +94 (+29%) |
| **Missing Elements** | - | 346 | Critical |
| **Extra Elements** | 49 | - | Review needed |
| **Missing ComplexTypes** | - | 4 | Critical |
| **Extra ComplexTypes** | 98 | - | Review needed |

---

## Critical Issues Identified

### 1. Missing Namespace Declarations ❌ CRITICAL

**Problem**: Generated XSD uses wrong namespace prefix and missing required imports.

**Generated**:
```xml
<schema xmlns="http://www.w3.org/2001/XMLSchema"
        xmlns:urf="https://www.geospatial.jp/iur/urf/3.2"
        targetNamespace="https://www.geospatial.jp/iur/urf/3.2">
  <import namespace="http://www.opengis.net/gml/3.2"
          schemaLocation="http://schemas.opengis.net/gml/3.2.1/gml.xsd"/>
</schema>
```

**Reference**:
```xml
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
           xmlns:core="http://www.opengis.net/citygml/2.0"
           xmlns:gml="http://www.opengis.net/gml"
           xmlns:urf="https://www.geospatial.jp/iur/urf/3.2"
           xmlns:uro="https://www.geospatial.jp/iur/uro/3.2"
           targetNamespace="https://www.geospatial.jp/iur/urf/3.2">
  <xs:import namespace="http://www.opengis.net/citygml/2.0"
             schemaLocation="http://schemas.opengis.net/citygml/2.0/cityGMLBase.xsd"/>
  <xs:import namespace="http://www.opengis.net/gml"
             schemaLocation="http://schemas.opengis.net/gml/3.1.1/base/gml.xsd"/>
  <xs:import namespace="https://www.geospatial.jp/iur/uro/3.2"
             schemaLocation="../../uro/3.2/urbanObject.xsd"/>
</xs:schema>
```

**Missing Namespaces**:
- `xmlns:xs` - Should use `xs:` prefix, not default namespace
- `xmlns:core` - CityGML 2.0 core (required for inheritance)
- `xmlns:gml` - GML 3.1.1 (wrong version in generated: uses 3.2)
- `xmlns:uro` - Urban Object types (required for attributes)

**Impact**: Schema validation will fail, types won't resolve correctly.

---

### 2. Missing Property Elements ❌ CRITICAL

**Problem**: Generated XSD defines complexTypes but **omits all property elements** within them.

**Example - Reference has**:
```xml
<xs:element name="Administration" substitutionGroup="urf:_UrbanFunction"
            type="urf:AdministrationType"/>
<xs:complexType name="AdministrationType">
  <xs:complexContent>
    <xs:extension base="urf:_UrbanFunctionType">
      <xs:sequence>
        <xs:element name="urfDmAttribute" maxOccurs="unbounded" minOccurs="0"
                    type="uro:DmAttributePropertyType"/>
      </xs:sequence>
    </xs:extension>
  </xs:complexContent>
</xs:complexType>
```

**Generated has**:
```xml
<element name="Administration" type="urf:AdministrationType"
         substitutionGroup="urf:_UrbanFunction"/>
<complexType name="AdministrationType">
  <complexContent>
    <extension base="urf:_UrbanFunctionType">
      <sequence/>  <!-- EMPTY! Should contain urfDmAttribute -->
    </extension>
  </complexContent>
</complexType>
```

**346 Missing Property Elements** including:
- `id`, `class`, `function`, `usage` (core properties)
- `validFrom`, `validTo`, `legalGrounds` (temporal/legal properties)
- `nominalArea`, `prefecture`, `city` (geographic properties)
- `lod0MultiSurface`, `lod1MultiSurface` (geometry properties)
- Type-specific properties (e.g., `urfDmAttribute`, `boundary`, `urbanParkAttribute`)

**Impact**: Generated schema is structurally empty - cannot represent actual data.

---

### 3. Incorrect Element Generation ⚠️ MAJOR

**Problem**: UrbanPlanningBasicSurveyRecord subtypes generated as top-level elements instead of abstract substitution groups.

**49 Extra Top-Level Elements** (should be part of substitution group):
- `AccomodationType`
- `AreaClassicificationType`
- `CommutingPopulationType`
- `DisasterPreventionBaseType`
- `FloodingDamageType`
- `InlandFloodingDamageType`
- `ItemRecordType`
- `LandPriceAverageType`
- `NumberOfHouseholdsType`
- `SummaryRecordType`
- And 39 more...

**Root Cause**: Generator treating these as independent types rather than extensions of abstract `UrbanPlanningBasicSurveyRecord`.

---

### 4. Missing Core Types ❌ CRITICAL

**4 Missing ComplexTypes**:
1. `NumberOfHouseholdsType` - Required for household data
2. `NumberOfHouseholdsPropertyType` - Property wrapper
3. `TargetType` - Base type for targeted elements
4. `TargetPropertyType` - Property wrapper

**Impact**: Cannot instantiate certain data structures.

---

### 5. Structural Pattern Issues

#### Reference Pattern (Correct):
```xml
<xs:element name="Agreement" substitutionGroup="urf:Zone" type="urf:AgreementType"/>
<xs:complexType name="AgreementType">
  <xs:complexContent>
    <xs:extension base="urf:ZoneType">
      <xs:sequence>
        <xs:element name="applicableArea" minOccurs="0" type="gml:MeasureType"/>
        <xs:element name="expiration" minOccurs="0" type="xs:date"/>
      </xs:sequence>
    </xs:extension>
  </xs:complexContent>
</xs:complexType>
```

#### Generated Pattern (Incorrect):
```xml
<element name="Agreement" type="urf:AgreementType" substitutionGroup="urf:Zone"/>
<complexType name="AgreementType">
  <complexContent>
    <extension base="urf:ZoneType">
      <sequence/>  <!-- EMPTY - missing applicableArea and expiration -->
    </extension>
  </complexContent>
</complexType>
```

---

## Root Cause Analysis

### 1. XSD Generator Issues

**Location**: Likely in [`lib/lutaml/klin/shapechange/processors/xsd_generator.rb`](../lib/lutaml/klin/shapechange/processors/xsd_generator.rb) or related.

**Problems**:
1. **Namespace handling**: Uses default `xmlns` instead of `xmlns:xs` prefix
2. **Property generation**: Not generating `<xs:element>` declarations within `<xs:sequence>` blocks
3. **Import generation**: Missing required imports for core, gml (correct version), uro
4. **Type classification**: Incorrectly treating abstract survey record types as concrete top-level elements

### 2. UML to XSD Mapping

**Probable Issues**:
1. Not processing class **attributes** → XSD **elements**
2. Not processing **associations** → XSD **property elements**
3. Not correctly handling **abstract classes** and **substitution groups**
4. Missing **stereotype** handling for `<<CodeList>>`, `<<DataType>>`, etc.

### 3. Configuration Issues

**Check**:
- [`examples/ShapeChangeConfig_Plateau_urf_for_plateau.xml`](../examples/ShapeChangeConfig_Plateau_urf_for_plateau.xml)
- Encoding rules configuration
- Namespace mappings
- Type mappings

---

## Required Fixes

### Priority 1: CRITICAL (Blocking)

1. **Fix namespace declarations**
   - Change default `xmlns` to `xmlns:xs`
   - Add all required namespace imports
   - Use correct GML version (3.1.1, not 3.2)

2. **Generate property elements**
   - Process class attributes → element declarations
   - Process associations → element references
   - Respect minOccurs/maxOccurs from multiplicity
   - Include proper types and namespaces

3. **Fix abstract type handling**
   - Mark UrbanPlanningBasicSurveyRecord as abstract
   - Use substitutionGroup correctly for subtypes
   - Don't generate top-level elements for abstract types

### Priority 2: MAJOR (Functional)

4. **Add missing types**
   - NumberOfHouseholdsType and property wrapper
   - TargetType and property wrapper

5. **Fix GML import**
   - Use GML 3.1.1, not 3.2
   - Correct schema location

### Priority 3: MINOR (Polish)

6. **Element ordering**
   - Match reference schema element order
   - Group related types together

---

## Validation Steps

After fixes, re-run comparison:

```bash
ruby scripts/compare_xsd.rb
```

**Success Criteria**:
- ✅ Element count matches (696)
- ✅ ComplexType count matches (322)
- ✅ All namespaces present
- ✅ All property elements generated
- ✅ Substitution groups correct
- ✅ No structural differences in diff output

---

## Next Steps

1. **Identify responsible code**:
   - XSD generator class
   - Property generation logic
   - Namespace handling

2. **Implement fixes** (one at a time):
   - Fix namespace declarations
   - Enable property element generation
   - Fix abstract type handling
   - Add missing types

3. **Test incrementally**:
   - Re-run comparison after each fix
   - Track progress toward 100% parity

4. **Document changes**:
   - Update implementation notes
   - Add test cases for fixes

---

## Files to Investigate

1. [`lib/lutaml/klin/shapechange/processors/xsd_generator.rb`](../lib/lutaml/klin/shapechange/processors/xsd_generator.rb)
2. [`lib/lutaml/klin/shapechange/models/xsd/`](../lib/lutaml/klin/shapechange/models/xsd/)
3. [`lib/lutaml/klin/shapechange/encoding_rules/`](../lib/lutaml/klin/shapechange/encoding_rules/)
4. [`examples/ShapeChangeConfig_Plateau_urf_for_plateau.xml`](../examples/ShapeChangeConfig_Plateau_urf_for_plateau.xml)

---

## Conclusion

The generated XSD is **structurally incomplete** and **cannot be used** for data validation or exchange. The primary issues are:

1. Wrong namespace prefix usage
2. Complete absence of property element declarations
3. Incorrect abstract type handling

These are **systematic generation issues** that require fixes to the XSD generator core logic, not just configuration adjustments.

**Estimated Effort**: 2-3 days of focused development to fix generator logic and test all edge cases.