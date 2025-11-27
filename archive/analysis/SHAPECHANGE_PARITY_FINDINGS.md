# ShapeChange 100% Parity Investigation - Findings

**Date**: 2025-10-29
**Investigation**: Achieving 100% ShapeChange Parity

## Summary

The investigation confirms that **existing "reference" XSD files have been manually modified** and are not pure ShapeChange output. This validates the need for fresh reference generation, but technical blockers prevent immediate ShapeChange execution.

## Key Findings

### 1. Source Files Located ✅

#### XMI Files Found
- `/Users/mulgogi/src/lutaml/lutaml-klin/spec/fixtures/xmi/plateau_minimal.xmi` (minimal test fixture)
- `/Users/mulgogi/src/lutaml/lutaml/spec/fixtures/plateau_all_packages_export.xmi` (full export)
- `/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/plateau_all_packages_export.xmi` (duplicate)

#### Enterprise Architect Model Found
- `/Users/mulgogi/src/mn/mn-samples-plateau/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/202503_current_plateau_v5.0.qea`
- `/Users/mulgogi/src/mn/mn-samples-plateau/20251010_current_plateau_v5.0_Ron-san-Modify.qea` (modified version)

**Status**: ✅ Input files available

### 2. ShapeChange Tool Located ✅

**JAR**: `/Users/mulgogi/src/mn/mn-samples-plateau/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/ShapeChange-3.1.0.jar`
**Version**: 3.1.0
**Status**: ✅ Tool available

### 3. Existing XSD Has Manual Modifications ⚠️

**File**: `/Users/mulgogi/src/mn/mn-samples-plateau/reference-docs/xsd/i-ur/urbanObject.xsd`

**Evidence** (line 16):
```xml
<!-- =================== 整形プログラムによる「_GenericApplicationPropertyOf」関係の追記　↓　 ================ -->
```

Translation: "Additions by formatting program for '_GenericApplicationPropertyOf' relationships"

This **confirms** that the "reference" XSD in the LXR package has been manually post-processed and is NOT pure ShapeChange output.

**Files**:
- `urbanObject.xsd` (178K) - manually modified
- `urbanFunction.xsd` (138K) - status unknown

### 4. ShapeChange Configuration Issues ❌

**Config Files**:
- Project: `reference/shapechange-configs/ShapeChangeConfig_Reference.xml`
- Original: `/Users/mulgogi/src/mn/mn-samples-plateau/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/ShapeChangeConfig_Plateau_uro.xml`

**Blockers**:

1. **Schema Validation Error**:
   ```
   Failed to read schema document 'http://shapechange.net/resources/schema/ShapeChangeConfiguration.xsd'
   ```
   - Online schema not accessible
   - No local schema copy available

2. **Windows Path References** (line 102):
   ```xml
   <xi:include href="D:\ShapeChange\challengebatch\StandardNamespaces-v31.xml" />
   ```
   - Hardcoded Windows path
   - File does not exist on macOS

3. **Network Dependency**:
   ```xml
   <xi:include href="http://shapechange.net/resources/config/StandardAliases.xml"/>
   <xi:include href="http://shapechange.net/resources/config/StandardRules.xml"/>
   <xi:include href="http://shapechange.net/resources/config/StandardNamespaces.xml"/>
   <xi:include href="http://shapechange.net/resources/config/StandardMapEntries.xml"/>
   ```
   - Requires internet connectivity
   - May require VPN or proxy configuration

## Current Status

### Completed ✅
- [x] Located XMI input files
- [x] Located QEA Enterprise Architect model
- [x] Located ShapeChange 3.1.0 JAR
- [x] Confirmed existing XSD has manual modifications
- [x] Copied QEA file to project (`reference/input/202503_current_plateau_v5.0.qea`)
- [x] Created generation script (`scripts/generate_shapechange_reference.sh`)
- [x] Created local ShapeChange config

### Blocked ❌
- [ ] Execute ShapeChange to generate fresh reference XSD
  - Blocker: Config validation errors
  - Blocker: Missing local schema files
  - Blocker: Network dependencies

## Alternative Approaches

Since direct ShapeChange execution is blocked, we have several alternatives:

### Option A: Fix ShapeChange Configuration
**Effort**: Medium
**Steps**:
1. Download ShapeChange XSD schema locally
2. Locate or create `StandardNamespaces-v31.xml`
3. Download all xi:include referenced files
4. Update config to use local file paths
5. Re-run ShapeChange

**Pros**: Gets pure ShapeChange output
**Cons**: Requires network access and file hunting

### Option B: Use Existing XMI for Direct Comparison
**Effort**: Low
**Steps**:
1. Use `plateau_all_packages_export.xmi` as source of truth
2. Compare lutaml-klin output against XMI structure
3. Validate that XMI → XSD transformation is correct
4. Focus on model accuracy, not ShapeChange parity

**Pros**: No ShapeChange dependency
**Cons**: Different validation approach

### Option C: Reverse-Engineer "Clean" XSD
**Effort**: High
**Steps**:
1. Take manually-modified XSD
2. Identify and remove manual additions
3. Document what was removed
4. Use as approximate reference

**Pros**: Quick baseline
**Cons**: May miss unknown modifications

### Option D: Request Fresh ShapeChange XSD from PLATEAU Team
**Effort**: Low
**Steps**:
1. Contact PLATEAU/i-UR team
2. Request unmodified ShapeChange output
3. Use as gold standard

**Pros**: Authoritative source
**Cons**: External dependency

## Recommended Path Forward

**Phase 1: Immediate (Use XMI)**
1. Use `plateau_all_packages_export.xmi` as source of truth
2. Validate lutaml-klin against XMI structure
3. Create model-level comparison tests
4. Achieve "XMI parity" first

**Phase 2: Medium-term (Fix ShapeChange)**
1. Download required ShapeChange config files
2. Create fully local ShapeChange setup
3. Generate fresh reference XSD
4. Compare against our XMI-validated output
5. Document any differences

**Phase 3: Long-term (100% Parity)**
1. Identify root causes of differences
2. Fix lutaml-klin implementation
3. Re-validate against fresh ShapeChange output
4. Achieve true 100% ShapeChange parity

## Files Created

- `reference/input/202503_current_plateau_v5.0.qea` - PLATEAU EA model (copied)
- `reference/shapechange-configs/ShapeChangeConfig_Reference.xml` - Local config
- `scripts/generate_shapechange_reference.sh` - Generation script
- `docs/SHAPECHANGE_PARITY_FINDINGS.md` - This document

## Next Steps

1. **Decision Required**: Choose validation approach (A, B, C, or D)
2. **If Option B (XMI)**: Create XMI-based validation tests
3. **If Option A (Fix ShapeChange)**: Locate and download missing config files
4. **Document**: Update 100% Parity Plan with chosen approach

## References

- ShapeChange: http://shapechange.net/
- PLATEAU XSD: https://www.geospatial.jp/iur/schemas/
- Original Plan: `docs/100_PERCENT_PARITY_PLAN.md`