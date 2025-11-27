# ShapeChange Encoding Rules Documentation

## Overview

Encoding rules in ShapeChange define how UML model elements (classes, attributes, associations) are transformed into XML Schema (XSD) elements, types, and structures. They are fundamental to the UML-to-XSD conversion process.

## Conceptual Model

### What Are Encoding Rules?

Encoding rules are named sets of transformation rules that control:
- How UML classes map to XSD complex types
- How UML attributes map to XSD elements/attributes
- How UML associations map to XSD elements
- What naming conventions to use
- Which GML/ISO standards to follow
- What special handling to apply (code lists, enumerations, etc.)

### Key Characteristics

1. **Named Identifiers**: Each encoding rule has a unique name (e.g., "iso19136_2007", "citygml")
2. **Inheritance/Extension**: Encoding rules can extend other encoding rules, forming a hierarchy
3. **Rule Collections**: Each encoding rule contains a set of individual conversion rules
4. **Case-Insensitive**: Rule names are compared case-insensitively in ShapeChange

## Architecture

### Encoding Rule Structure

```
EncodingRule
├── name: String (identifier, e.g., "iso19136_2007")
├── extends: String (optional, name of parent encoding rule)
└── rules: List<String> (individual conversion rule identifiers)
```

### Rule Inheritance Chain

Encoding rules form inheritance chains through the `extends` attribute:

```
iso19136_2007 (base GML 3.2 rules)
    ↑
    └── iso19136_2007_ShapeChange_1.0_Extensions
            ↑
            └── citygml (CityGML-specific rules)
```

When checking if a rule applies to an encoding rule, ShapeChange traverses the entire inheritance chain.

### Rule Registry

ShapeChange maintains a `RuleRegistry` that:
1. Stores all known encoding rules and their relationships
2. Tracks which conversion rules belong to which encoding rules
3. Resolves inheritance chains when checking rule applicability
4. Validates encoding rule definitions

## Standard Encoding Rules

### From StandardRules.xml

Based on the downloaded configuration files, the following standard encoding rules are defined:

#### 1. iso19136_2007_INSPIRE_Extensions
- **Extends**: gml33
- **Purpose**: INSPIRE-specific extensions to GML 3.3
- **Key Rules**:
  - `req-all-all-documentation`
  - `req-xsd-pkg-targetNamespace`
  - `req-xsd-cls-codelist-asDictionary-true`
  - `req-xsd-cls-codelist-extensibility-values`
  - `rule-xsd-prop-nillable`

#### 2. okstra
- **Extends**: iso19136_2007
- **Purpose**: OKSTRA (German road information standard)
- **Key Rules**:
  - `rule-xsd-cls-no-base-class`
  - `rule-xsd-cls-no-abstract-classes`
  - `rule-xsd-cls-okstra-schluesseltabelle`
  - `rule-xsd-cls-okstra-lifecycle`

#### 3. gml21
- **Extends**: iso19136_2007
- **Purpose**: GML 2.1 backward compatibility
- **Key Rules**:
  - `rule-xsd-cls-codelist-anonymous-xlink`
  - `rule-xsd-all-gml21`

#### 4. notEncoded
- **Extends**: * (all encoding rules)
- **Purpose**: Suppress encoding for certain elements
- **Key Rules**:
  - `rule-xsd-all-notEncoded`
  - `rule-json-all-notEncoded`
  - `rule-sql-all-notEncoded`
  - `rule-cdb-all-notEncoded`

#### 5. citygml-ade
- **Extends**: iso19136_2007
- **Purpose**: CityGML Application Domain Extensions
- **Key Rules**:
  - `req-xsd-cls-suppress-supertype`
  - `req-xsd-cls-suppress-subtype`
  - `rule-xsd-cls-suppress`
  - `rule-xsd-cls-adeelement`
  - `rule-xsd-cls-mixin-classes`

#### 6. metadata-profile
- **Extends**: iso19139_2007
- **Purpose**: ISO 19139 metadata profiles
- **Key Rules**:
  - `rule-xsd-cls-standard-19139-isoType`
  - `req-xsd-cls-suppress-supertype`
  - `rule-xsd-pkg-schematron`

#### 7. iso19136_2007_ShapeChange_1.0_Extensions
- **Extends**: iso19136_2007
- **Purpose**: ShapeChange-specific enhancements to GML 3.2
- **Key Rules**:
  - `req-xsd-cls-mixin-supertypes`
  - `rule-xsd-cls-union-asCharacterString`
  - `rule-xsd-cls-union-asGroup`
  - `rule-xsd-cls-basictype`
  - `rule-xsd-cls-codelist-constraints`
  - `rule-xsd-prop-exclude-derived`
  - `rule-xsd-prop-xsdAsAttribute`
  - `rule-xsd-prop-initialValue`
  - `rule-xsd-pkg-schematron`

#### 8. external
- **Extends**: * (all encoding rules)
- **Purpose**: Mark elements as externally defined
- **Key Rules**:
  - `rule-xsd-all-notEncoded`

#### 9. iso19136_2007_NoGmlBaseTypes
- **Extends**: * (all encoding rules)
- **Purpose**: GML encoding without GML base types
- **Key Rules**:
  - `rule-xsd-cls-no-gml-types`
  - `rule-xsd-all-naming-gml`
  - `rule-xsd-cls-global-enumeration`
  - `rule-xsd-cls-standard-gml-property-types`

## GML 3.2 Encoding Rule (iso19136_2007)

### Source
- ISO 19136:2007 (Geographic information — Geography Markup Language)
- GML 3.2, Annex E
- [OGC Document](https://portal.opengeospatial.org/files/?artifact_id=20509)

### Core Conversion Rules

#### 1. rule-xsd-cls-codelist-asDictionary
If the tagged value `asDictionary` of a code list is not 'true', create a global type for the code list; otherwise reference code list values using `gml:CodeType`.

#### 2. rule-xsd-all-naming-gml
Use the naming strategy for schema components as specified by GML 3.2:
- PropertyType suffix for property types
- Type suffix for value types
- Specific naming patterns for associations

#### 3. rule-xsd-cls-noPropertyType
If the tagged value `noPropertyType` of a feature type, class, data type, or union type is 'true', suppress property type creation.

#### 4. rule-xsd-cls-byValuePropertyType
If the tagged value `byValuePropertyType` of a feature type or class is 'true', create an additional by-value property type.

#### 5. rule-xsd-cls-standard-gml-property-types
Reuse property types or create anonymous property types according to GML 3.2 standards.

#### 6. rule-xsd-pkg-gmlProfileSchema
Include `gmlProfileSchema` appinfo if the tagged value is set on the application schema package.

#### 7. rule-xsd-prop-defaultCodeSpace
Include `defaultCodeSpace` appinfo when applicable for code list properties.

#### 8. rule-xsd-prop-inlineOrByReference
Take tagged value `inlineOrByReference` on properties into account when setting the type of a property element.

#### 9. rule-xsd-prop-reverseProperty
Include `reversePropertyName` appinfo when applicable for bidirectional associations.

#### 10. rule-xsd-prop-targetElement
Include `targetElement` appinfo if a property is byReference.

#### 11. rule-xsd-cls-global-enumeration
Convert enumerations to global types rather than inline types.

## PLATEAU Configuration Example

From `ShapeChangeConfig_Plateau_urf.xml`:

```xml
<EncodingRule name="citygml" extends="iso19136_2007">
    <rule name="rule-xsd-rel-association-classes"/>
    <rule name="rule-xsd-cls-basictype"/>
    <rule name="rule-xsd-cls-union-asGroup"/>
    <rule name="rule-xsd-prop-initialValue"/>
    <rule name="rule-xsd-pkg-schematron"/>
</EncodingRule>
```

This encoding rule:
1. Extends the base GML 3.2 encoding rule (`iso19136_2007`)
2. Adds 5 additional conversion rules specific to CityGML transformation
3. Inherits all rules from `iso19136_2007`

## How Encoding Rules Are Applied

### 1. Configuration Phase
- Encoding rules are defined in XML configuration files
- Rules can be included via xi:include for modularity
- ShapeChange loads all encoding rule definitions into the `RuleRegistry`

### 2. Resolution Phase
When ShapeChange needs to check if a conversion rule applies:

```java
// Pseudocode from RuleRegistry.java
boolean hasRule(String ruleId, String encodingRuleId) {
    // Start with the specified encoding rule
    while (encodingRuleId != null) {
        // Check if rule is directly in this encoding rule
        if (ruleExistsIn(ruleId, encodingRuleId)) {
            return true;
        }
        // Move to parent encoding rule (if any)
        encodingRuleId = extendsEncRule(encodingRuleId);
    }
    return false;
}
```

### 3. Application Phase
- Each target (XSD, JSON, SQL, etc.) registers its supported conversion rules
- During transformation, the target checks if each rule is enabled for the current encoding rule
- Rules are applied in a specific order defined by the target implementation

## Type Mappings

Encoding rules work in conjunction with **XSD Map Entries** which define UML type to XSD type mappings. For example:

```xml
<XsdMapEntry type="CharacterString"
             xsdEncodingRules="iso19136_2007"
             xmlPropertyType="gml:CodeType"
             xmlType="string"
             xmlTypeContent="simple"
             xmlTypeType="complex"/>
```

This means: For the `iso19136_2007` encoding rule, UML type `CharacterString` maps to XSD `gml:CodeType` (a complex type with simple content based on `string`).

## Rule Naming Conventions

Conversion rules follow these naming patterns:

### Prefix Meanings
- **req-**: Required rule (must be applied for conformance)
- **rule-**: Optional rule (can be selectively enabled)
- **rec-**: Recommended rule (should be applied but not mandatory)

### Scope Indicators
- **xsd-**: Applies to XML Schema transformation
- **json-**: Applies to JSON transformation
- **sql-**: Applies to SQL/database transformation
- **all-**: Applies to all model elements
- **pkg-**: Applies to packages
- **cls-**: Applies to classes
- **prop-**: Applies to properties (attributes/associations)

### Examples
- `req-xsd-pkg-targetNamespace`: Required rule for XSD packages regarding targetNamespace
- `rule-xsd-cls-basictype`: Optional rule for XSD classes about basic types
- `rule-xsd-prop-nillable`: Optional rule for XSD properties about nillability

## Summary of Downloaded Reference Files

### Configuration Files (15 files in `reference/shapechange-configs/`)

1. **Main Config**:
   - `ShapeChangeConfig_Plateau_urf.xml` - PLATEAU-specific configuration

2. **Standard Definitions** (from shapechange.net):
   - `StandardAliases.xml` - Stereotype aliases
   - `StandardRules.xml` - Standard encoding rule definitions
   - `StandardNamespaces.xml` - Standard XML namespace definitions
   - `StandardMapEntries.xml` - Master map entries file (includes 10 more files)

3. **ISO Standard Map Entries** (type mappings per ISO standard):
   - `StandardMapEntries_iso19136_2007.xml` - GML 3.2 types
   - `StandardMapEntries_iso19139_2007.xml` - ISO 19139 metadata types
   - `StandardMapEntries_iso19107.xml` - Spatial schema types
   - `StandardMapEntries_iso19108.xml` - Temporal schema types
   - `StandardMapEntries_iso19111.xml` - Spatial referencing types
   - `StandardMapEntries_iso19115.xml` - Metadata types
   - `StandardMapEntries_iso19123.xml` - Coverage geometry types
   - `StandardMapEntries_iso19156.xml` - Observations and Measurements
   - `StandardMapEntries_sweCommon.xml` - SWE Common Data Model
   - `StandardMapEntries_gmlcov.xml` - GML Coverage types

### Source Code
- Extracted ShapeChange 3.1.0 sources in `reference/shapechange-sources/`
- Key file: `RuleRegistry.java` - Core encoding rule management implementation

## Implementation Notes for lutaml-klin

When implementing encoding rule support in lutaml-klin:

1. **Parse Encoding Rules**: Extract encoding rule definitions from configuration
2. **Build Inheritance Chain**: Resolve the `extends` relationships
3. **Match Rules**: Implement rule matching that follows the inheritance chain
4. **Apply to Mappings**: Use encoding rules to determine which transformation rules apply
5. **Document in YAML**: Include encoding rule context in generated YAML mappings

### Example YAML Output

```yaml
mapping:
  uml_class: Building
  xsd_element: BuildingType
  encoding_rule: citygml
  inherited_from: iso19136_2007
  applied_rules:
    - rule-xsd-cls-basictype
    - rule-xsd-prop-initialValue
    - rule-xsd-all-naming-gml  # inherited
```

## References

- ShapeChange Documentation: `/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/documentation/`
- GML 3.2 Standard: ISO 19136:2007
- ShapeChange Config Schema: `http://www.interactive-instruments.de/ShapeChange/Configuration/1.1`
- Standard Rules: `https://shapechange.net/resources/config/StandardRules.xml`
