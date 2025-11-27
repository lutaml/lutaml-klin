# ShapeChange Transformation Algorithm: UML to XSD

## Critical Understanding: What ShapeChange Actually Does

### ShapeChange = XSD Generator (NOT Mapping Generator!)

```
ShapeChange Input:  XMI file + Config XML
ShapeChange Output: XSD files (urbanFunction.xsd, building.xsd, etc.)
ShapeChange Process: Direct UML→XSD transformation and file generation
```

**Example**:
```
UML Class: Building (stereotype=«FeatureType»)
  Attribute: yearOfConstruction (type=xs::gYear, multiplicity=0..1)

ShapeChange generates:
  <xs:element name="Building" type="BuildingType" substitutionGroup="core:_CityObject"/>
  <xs:complexType name="BuildingType">
    <xs:complexContent>
      <xs:extension base="core:AbstractBuildingType">
        <xs:sequence>
          <xs:element name="yearOfConstruction" type="xs:gYear" minOccurs="0"/>
        </xs:sequence>
      </xs:extension>
    </xs:complexContent>
  </xs:complexType>
```

### lutaml-klin = Mapping Documentation Generator (NOT XSD Generator!)

```
lutaml-klin Input:  XMI file + XSD files + Config XML
lutaml-klin Output: YAML mapping documentation
lutaml-klin Process: Document how UML maps to existing XSD
```

**Example**:
```yaml
- uml_class: Building
  uml_stereotype: FeatureType
  xsd_element: Building
  xsd_type: BuildingType
  attributes:
    - uml_name: yearOfConstruction
      uml_type: xs::gYear
      xsd_element: yearOfConstruction
      xsd_type: xs:gYear
      resolution_method: shapechange_rule
```

## The Gap: Understanding vs Generating

### What We've Been Trying (Wrong Approach)

**Assumption**: "Use ShapeChange config to map UML types to XSD types"

**Reality**: ShapeChange doesn't just map - it **GENERATES** the XSD!

**The Problem**:
- ShapeChange config tells HOW to generate XSD
- But we're trying to use it to map to EXISTING XSD
- These are different problems!

### What We Actually Need

**For Mapping Documentation**:

1. **Load UML Model** (from LUR)
   - Get classes, attributes, types

2. **Load EXISTING XSD Schemas** (from LXR)
   - Get elements, types, documentation

3. **Match UML to XSD** using multiple strategies:
   - **Strategy A**: Direct name matching (what worked for 5.9%)
   - **Strategy B**: ShapeChange naming rules (what to generate → what exists)
   - **Strategy C**: Type equivalence (CharacterString → string)
   - **Strategy D**: Namespace resolution (uro::Building → uro:BuildingType)

4. **Document the Mapping**
   - Which UML class maps to which XSD element
   - Which UML attribute maps to which XSD element
   - What transformation happened (if any)

## ShapeChange Transformation Algorithm (Simplified)

### For UML Class → XSD

```java
// From XmlSchema.java:177-447
public void process(ClassInfo ci) {
    int cat = ci.category();  // FEATURE, DATATYPE, ENUMERATION, etc.

    // Step 1: Create object element (if applicable)
    switch (cat) {
        case FEATURE:
        case DATATYPE:
        case OBJECT:
            if (ci.matches("rule-xsd-cls-object-element")) {
                xsd.pObjectElement(ci, cibase);
                // Creates: <xs:element name="Building" type="BuildingType"/>
            }
            break;
    }

    // Step 2: Create content model (complex type)
    switch (cat) {
        case FEATURE:
        case DATATYPE:
        case OBJECT:
            if (ci.matches("rule-xsd-cls-type")) {
                Element propertyHook = xsd.pComplexType(ci, cibase, schDoc);
                // Creates: <xs:complexType name="BuildingType">...</xs:complexType>

                if (ci.matches("rule-xsd-cls-local-properties")) {
                    xsd.processLocalProperties(ci, propertyHook, schDoc);
                    // Processes all attributes of this class
                }
            }
            break;
    }

    // Step 3: Create property type (for references)
    switch (cat) {
        case FEATURE:
        case DATATYPE:
        case OBJECT:
            if (ci.matches("rule-xsd-cls-type")) {
                xsd.pPropertyTypes(ci);
                // Creates: <xs:complexType name="BuildingPropertyType">...</xs:complexType>
            }
            break;
    }
}
```

### For UML Attribute → XSD

```java
// In XsdDocument.processLocalProperties()
void processLocalProperties(ClassInfo ci, Element propertyHook, SchematronSchema schDoc) {
    for (PropertyInfo pi : ci.properties().values()) {
        // Determine if element or attribute
        boolean isXmlAttribute = implementedAsXmlAttribute(pi);

        if (isXmlAttribute) {
            // Create XML attribute
            createXmlAttribute(pi, propertyHook);
            // <xs:attribute name="id" type="xs:ID"/>
        } else {
            // Create XML element
            createXmlElement(pi, propertyHook);
            // <xs:element name="yearOfConstruction" type="xs:gYear"/>
        }
    }
}
```

### Type Resolution in ShapeChange

```java
// From XmlSchema.java:740-756
public boolean isSimpleType(ClassInfo ci, String ciName, String propiEncodingRule) {
    if (ci != null) {
        // Check if class has simple content indicator
        Boolean indicatorSimpleType = indicatorForObjectElementWithSimpleContent(ci);
        isSimple = !classHasObjectElement(ci) || (indicatorSimpleType != null && indicatorSimpleType);
    } else {
        // Look up in map entries
        String tname = ciName;
        MapEntry me = options.typeMapEntry(tname, propiEncodingRule);
        if (me != null)
            isSimple = me.p2.equalsIgnoreCase("simple/simple") || me.p2.equalsIgnoreCase("complex/simple");
    }
    return isSimple;
}
```

## How lutaml-klin Should Use This Knowledge

### Current Problem

**lutaml-klin is trying to**:
1. Use ShapeChange config for type mapping
2. But ShapeChange config is for GENERATION, not mapping to existing XSD

**The "0/0" statistics suggest**: MappingService isn't creating ANY mappings because it doesn't know the transformation rules!

### Solution: Implement Transformation Algorithm for Mapping

**Instead of generating XSD, document what WOULD be generated**:

```ruby
class UmlToXsdMapper
  def map_class(uml_class, xsd_repository, config)
    # 1. Determine what ShapeChange WOULD generate
    expected_element_name = apply_naming_rules(uml_class.name, config)
    expected_type_name = expected_element_name + "Type"

    # 2. Find that element/type in existing XSD (from LXR)
    xsd_element = xsd_repository.find_element(
      name: expected_element_name,
      namespace: determine_namespace(uml_class)
    )

    xsd_type = xsd_repository.find_type(
      name: expected_type_name,
      namespace: determine_namespace(uml_class)
    )

    # 3. Document the mapping
    ClassMapping.new(
      uml_name: uml_class.name,
      xsd_element: xsd_element&.name,
      xsd_type: xsd_type&.name,
      transformation: {
        naming_rule: "rule-xsd-all-naming-gml",
        expected: expected_element_name,
        found: xsd_element ? "yes" : "no"
      }
    )
  end

  def map_attribute(uml_attr, uml_class, xsd_type, config)
    # 1. Determine what ShapeChange WOULD generate
    is_xml_attribute = should_be_xml_attribute?(uml_attr, config)
    xml_name = uml_attr.name  # Keep as-is for GML

    # 2. Get XSD type from config or class
    xsd_attr_type = resolve_attribute_type(uml_attr.type, config)

    # 3. Find in existing XSD
    if is_xml_attribute
      xsd_attr = xsd_type&.attributes&.find { |a| a.name == xml_name }
    else
      xsd_element = xsd_type&.elements&.find { |e| e.name == xml_name }
    end

    # 4. Document the mapping
    AttributeMapping.new(
      uml_name: uml_attr.name,
      xsd_name: xml_name,
      xsd_type: xsd_attr_type,
      is_attribute: is_xml_attribute,
      found_in_xsd: xsd_attr || xsd_element ? "yes" : "no"
    )
  end

  private

  def should_be_xml_attribute?(uml_attr, config)
    # Rule: xsdAsAttribute tagged value
    return true if uml_attr.tagged_value("xsdAsAttribute") == "true"

    # Rule: Simple types with max multiplicity 1
    map_entry = config.find_type_mapping(uml_attr.type)
    return false unless map_entry

    map_entry.xml_type_type == "simple" &&
      map_entry.xml_type_content == "simple" &&
      uml_attr.multiplicity.upper == 1
  end

  def resolve_attribute_type(uml_type, config)
    # Look up in XsdMapEntry
    map_entry = config.find_type_mapping(uml_type)
    map_entry&.xml_type || uml_type
  end
end
```

## Corrected Implementation Plan

### Phase 1D: Implement Transformation-Aware Mapping (URGENT)

**Goal**: Create mappings by understanding ShapeChange's transformation logic

**Tasks**:

1. **Create TransformationAnalyzer** (NEW!)
   ```ruby
   class TransformationAnalyzer
     # Analyze what ShapeChange WOULD do
     def analyze_class_transformation(uml_class, config)
       {
         element_name: apply_naming_rules(uml_class.name, config),
         type_name: apply_naming_rules(uml_class.name, config) + "Type",
         property_type_name: apply_naming_rules(uml_class.name, config) + "PropertyType",
         namespace: determine_namespace(uml_class, config)
       }
     end

     def analyze_property_transformation(uml_property, config)
       {
         xml_name: uml_property.name,  # GML keeps UML name
         is_attribute: should_be_attribute?(uml_property),
         xsd_type: resolve_type(uml_property.type, config)
       }
     end
   end
   ```

2. **Update MappingService to Use Analyzer**
   ```ruby
   class MappingService
     def map_attribute_to_xsd(uml_attr, context)
       # Analyze transformation
       analysis = context.transformation_analyzer.analyze_property_transformation(
         uml_attr,
         context.shapechange_config
       )

       # Try to find in XSD
       xsd_component = context.xsd_repository.find_element(
         name: analysis[:xml_name],
         namespace: determine_namespace(uml_attr.in_class)
       )

       {
         uml_name: uml_attr.name,
         xsd_name: analysis[:xml_name],
         xsd_type: analysis[:xsd_type],
         is_attribute: analysis[:is_attribute],
         found_in_xsd: !xsd_component.nil?,
         transformation: analysis
       }
     end
   end
   ```

3. **Implement Core Transformation Rules**
   - `rule-xsd-all-naming-gml`: Element naming (keep UML name)
   - `rule-xsd-prop-xsdAsAttribute`: Force XML attribute
   - Type mapping via XsdMapEntry

### Expected Results After Phase 1D

```
[5/255] BridgeFunctionalAttribute (DataType)

  Transformation analysis:
    Expected element: BridgeFunctionalAttribute
    Expected type: BridgeFunctionalAttributeType
    Namespace: uro

  [1/2] directionType
    UML type: gml::CodeType
    Analysis:
      → XML element: directionType (GML naming rule)
      → XSD type: gml:CodeType (from XsdMapEntry)
      → Is attribute: false

    XSD lookup:
      ✓ Found element in uro schema
      ✓ Type validated via LXR

    ✅ MAPPED (100% confidence)

  [2/2] userType
    ✓ Analysis → directionType element, gml:CodeType type
    ✓ Found in XSD
    ✅ MAPPED

Resolution Statistics:
  Total: 1,141 attributes
  Mapped: 950+ (>83%)
  Confidence:
    - Exact match: 800 (70%)
    - Type mapping: 150 (13%)
    - Not found: 191 (17%)
```

## Summary

**The Gap**:
- ShapeChange: UML → XSD generation (creates files)
- lutaml-klin: UML → XSD mapping (documents relationship)

**The Fix**:
- Implement TransformationAnalyzer that understands ShapeChange rules
- Use it to predict what XSD SHOULD exist
- Match predictions against actual XSD (from LXR)
- Document as mappings

**Expected Impact**: Enable >80% mapping resolution by understanding transformation intent

This is a higher-level architectural solution that properly separates:
- Transformation analysis (what would ShapeChange generate?)
- XSD lookup (does it exist in reality?)
- Mapping documentation (how do they relate?)

All following OO principles, MECE, and separation of concerns!