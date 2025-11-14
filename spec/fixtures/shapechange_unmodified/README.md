# Unmodified ShapeChange Reference XSD

These XSD files have VBA formatting modifications REMOVED. They represent raw ShapeChange 3.1.0 output.

## Purpose

These files serve as the **true reference** for ShapeChange parity testing. They are the actual output from ShapeChange 3.1.0, before any manual formatting was applied by the Excel VBA program `XSD整形_2024年度用.xlsm`.

## Files

- [`urbanObject.xsd`](urbanObject.xsd:1) - URO (Urban Object) package XSD (VBA modifications removed)
- [`urbanFunction.xsd`](urbanFunction.xsd:1) - URF (Urban Function) package XSD (no VBA modifications present)

## VBA Modifications Removed

From `urbanObject.xsd`, the following were removed:
- **101 lines** of VBA-added content
- **99 element declarations** with `substitutionGroup` attributes
- Comment markers: `整形プログラムによる「_GenericApplicationPropertyOf」関係の追記`

### What Was Removed

The VBA program added global element declarations for URO attributes that should be used as GML application properties (substitution group elements). These elements were inserted at the top of the schema after the namespace declarations.

Examples of removed elements:
```xml
<xs:element name="bldgDataQualityAttribute" type="uro:DataQualityAttributePropertyType"
            substitutionGroup="bldg:_GenericApplicationPropertyOfAbstractBuilding"/>
<xs:element name="bridBaseAttribute" type="uro:ConstructionBaseAttributePropertyType"
            substitutionGroup="brid:_GenericApplicationPropertyOfAbstractBridge"/>
<xs:element name="ifcBuildingAttribute" type="uro:IfcAttributePropertyType"
            substitutionGroup="bldg:_GenericApplicationPropertyOfAbstractBuilding"/>
```

### Why These Were Added by VBA

The VBA formatting program added these global element declarations to make URO extension properties available as GML application properties throughout the schema. This is a post-processing step applied to the raw ShapeChange output.

## Generation Process

1. **Source**: `packages/plateau_schemas.lxr` (extracted from LXR archive)
2. **Script**: [`scripts/remove_vba_modifications.rb`](../../../scripts/remove_vba_modifications.rb:1)
3. **Process**: Identified and removed all content between VBA marker comments

## Usage in Testing

These unmodified files are used in the parity spec [`spec/integration/shapechange_true_parity_spec.rb`](../../integration/shapechange_true_parity_spec.rb:1) to verify that `lutaml-klin` generates XSD that matches the **actual** ShapeChange 3.1.0 output, before any manual post-processing.

## Relationship to VBA-Modified Files

| File | Location | Status |
|------|----------|--------|
| VBA-modified | `packages/plateau_schemas_extracted/schemas/` | As published in PLATEAU |
| Unmodified (this) | `spec/fixtures/shapechange_unmodified/` | True ShapeChange output |
| Generated | `tmp/generated_xsd/` | Our lutaml-klin output |

**Goal**: `Generated` should match `Unmodified`, proving 100% ShapeChange parity.

## See Also

- [`docs/VBA_MODIFICATIONS_ANALYSIS.md`](../../../docs/VBA_MODIFICATIONS_ANALYSIS.md:1) - Detailed analysis of VBA modifications
- [`scripts/analyze_vba_modifications.rb`](../../../scripts/analyze_vba_modifications.rb:1) - VBA modification analysis script