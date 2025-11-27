# ShapeChange Replication Plan: Full UML-to-XSD Transformation

## Executive Summary

This plan outlines the strategy to fully replicate ShapeChange's UML-to-XSD transformation capabilities in lutaml-klin, enabling both:
1. **Mapping generation** (current goal): UML-to-XSD mappings with >95% resolution
2. **XSD generation** (future goal): Full ShapeChange-compatible XSD output

## Background: Previous Work Analysis

### Previous 5.9% Resolution (plateau_xsd_mapping/)

**Approach**: Simple XSD element name matching

```ruby
# Previous approach (simplified)
def match_attribute(uml_attr, xsd_schema)
  # Direct name match: bldgDmAttribute → <xs:element name="bldgDmAttribute"/>
  xsd_element = xsd_schema.elements.find { |e| e.name == uml_attr.name }

  if xsd_element
    {
      status: :resolved,
      xsd_element: xsd_element.name,
      resolution_path: "Matched element: #{xsd_schema.namespace}:element:#{xsd_element.name}"
    }
  else
    { status: :unresolved }
  end
end
```

**Results**:
- ✓ Resolved: 132/2,223 attributes (5.9%)
- ✓ Matched: URO extension attributes (bldgDmAttribute, buildingDetailAttribute, etc.)
- ✗ Unmatched: Standard CityGML attributes (class, function, usage, lod2Solid, etc.)

**Why Low Resolution**:
1. No type transformation (CharacterString → string)
2. No encoding rules (UML property → XSD element/attribute)
3. No GML property types (_Solid → gml:SolidPropertyType)
4. Only matched exact element names

## ShapeChange Transformation Architecture

### High-Level Flow

```
XMI (UML Model)
  ↓
[1] Load & Parse UML Model (ClassInfo, PropertyInfo, AssociationInfo)
  ↓
[2] Apply Transformations (optional: TypeConverter, Flattener, etc.)
  ↓
[3] Load Configuration (encoding rules, type maps, namespaces)
  ↓
[4] Execute XmlSchema Target
     ├─ For each UML Package → XSD Schema file
     ├─ For each UML Class:
     │   ├─ Determine XSD complexType name (rule-xsd-all-naming-gml)
     │   ├─ Create complexType definition
     │   ├─ Create property type (FeaturePropertyType)
     │   ├─ For each UML Property:
     │   │   ├─ Apply encoding rules (element vs attribute)
     │   │   ├─ Determine XSD type (from XsdMapEntry or class type)
     │   │   ├─ Apply naming rules
     │   │   └─ Generate XSD element/attribute
     │   └─ Handle inheritance (base type references)
     └─ Write XSD files
  ↓
XSD Schemas (urbanFunction.xsd, urbanObject.xsd, etc.)
```

### Core Components

**1. Model Interface** (`Model/ClassInfo.java`, `PropertyInfo.java`):
- Abstract UML model representation
- Independent of UML tool (EA, XMI 1.0, Generic XML)
- Provides: classes, attributes, associations, stereotypes, tagged values

**2. MapEntries** (`MapEntry.java`, XSD map entries):
- UML type → XSD type mappings
- Filtered by encoding rule
- Includes property type information

**3. Encoding Rules** (`RuleRegistry.java`):
- Named rule sets with inheritance
- Rule enablement checking
- Context-dependent application

**4. XmlSchema Target** (`Target/XmlSchema/XmlSchema.java`):
- Main transformation engine
- Applies encoding rules
- Generates XSD output

## Two-Phase Implementation Plan

### Phase 1: Fix Current Mapping Generation (IMMEDIATE)

**Goal**: Achieve >95% UML-to-XSD mapping resolution using ShapeChange config

**Scope**: Generate YAML mappings, NOT XSD files

**Components to Fix**:

1. ✅ **ConfigParser** (working, needs encoding rule extraction)
2. ❌ **ShapeChangeConfiguration** (needs helper methods)
3. ❌ **Resolution Strategies** (needs real ShapeChange logic)
4. ✅ **XsdMapEntry lookup** (working in parser)

**Key Insight**: We don't need to replicate ShapeChange's XSD generation, just understand its mapping logic!

**Implementation**:

```ruby
# Updated ShapeChangeStrategy
class ShapeChangeMappingStrategy
  def resolve(uml_attr, context)
    # 1. Find type mapping from config
    map_entry = context.config.find_type_mapping(
      uml_attr.type,
      encoding_rule: "citygml"
    )

    return unless map_entry

    # 2. Determine element vs attribute
    is_xml_attribute = determine_xml_attribute(uml_attr, context)

    # 3. Apply naming rules
    xml_name = apply_naming_rules(uml_attr.name, context)

    # 4. Get XSD type
    xsd_type = map_entry.xml_type  # e.g., "string", "gml:CodeType"

    # 5. Validate with LXR
    lxr_result = context.lxr_repository.resolve_type(
      qualified_name: xsd_type
    )

    ResolutionResult.resolved(
      target: xsd_type,
      xml_name: xml_name,
      is_attribute: is_xml_attribute,
      method: :shapechange_rule,
      confidence: 1.0,
      metadata: {
        xsd_definition: lxr_result.type,
        map_entry_rule: map_entry.xsd_encoding_rules
      }
    )
  end

  private

  def determine_xml_attribute(uml_attr, context)
    # Simple heuristic for now:
    # - id, href, codeSpace → attribute
    # - Everything else → element
    %w[id href codeSpace].include?(uml_attr.name)
  end

  def apply_naming_rules(uml_name, context)
    # For now, keep UML name as-is
    # Later: apply camelCase, prefix rules, etc.
    uml_name
  end
end
```

**Expected Result**: >90% resolution using XsdMapEntry lookups

### Phase 2: Full ShapeChange Replication (FUTURE)

**Goal**: Generate XSD files compatible with ShapeChange output

**Scope**: Implement `lutaml-klin shapechange` command

**Required Components**:

1. **Full Encoding Rule Engine**:
   - Rule registry with inheritance
   - All GML 3.2 standard rules
   - All CityGML extension rules

2. **XSD Generator**:
   - ComplexType generation
   - PropertyType generation
   - Element/attribute generation
   - Import/include management

3. **Transformation Pipeline**:
   - Type converter support
   - Flattening support
   - Descriptor transformation

4. **Validation**:
   - Compare with ShapeChange output
   - Verify XSD schema validity
   - Test with PLATEAU schemas

## Current Task: Phase 1 Implementation

### Task 1: Review Previous Mapping Generator

**Objective**: Understand what achieved 5.9% resolution

**Files to Review**:
- Source code that generated `plateau_xsd_mapping/html/package_bldg.html`
- Previous XSD analyzer implementation
- Element matching logic

**Expected Learnings**:
- How URO extension attributes were matched
- Why standard CityGML attributes weren't matched
- What XSD parsing approach was used

### Task 2: Fix ConfigParser (Current Implementation)

**Current Status**:
- ✅ Parses XML correctly
- ✅ Extracts `xsd_map_entries` (20 from config + hundreds from includes)
- ✅ Extracts `xml_namespaces` (29 mappings)
- ✅ Extracts `package_infos` (12 packages)
- ❌ Doesn't extract `encoding_rules`

**What to Add**:

```ruby
# In ConfigParser.parse_content()
config.encoding_rules = extract_encoding_rules(doc)

def extract_encoding_rules(doc)
  doc.xpath("//rules/EncodingRule").map do |node|
    EncodingRule.new(
      name: node["name"],
      extends: node["extends"],
      rules: node.xpath("rule").map { |r| r["name"] }
    )
  end
end
```

### Task 3: Enhance ShapeChangeConfiguration

**Add Helper Methods**:

```ruby
class ShapeChangeConfiguration
  # Find namespace for UML package
  def namespace_for_package(package_path)
    simple_name = package_path.split('::').last.strip

    # Match PackageInfo by name (handles spaces in config)
    pkg_info = package_infos.find do |pi|
      pi.package_name&.strip == simple_name
    end

    pkg_info&.ns&.strip
  end

  # Find XsdMapEntry for UML type
  def find_type_mapping(uml_type, encoding_rule: "citygml")
    # Clean up type name (handle gml::CodeType, xs::string, etc.)
    clean_type = uml_type.gsub('::', ':')

    xsd_map_entries.find do |entry|
      entry.type&.strip == clean_type &&
      entry.applies_to?(encoding_rule)
    end
  end

  # Get prefix for namespace
  def prefix_for_namespace(namespace_uri)
    namespace_uri = namespace_uri&.strip

    # Try xml_namespaces
    xml_ns = xml_namespaces.find { |ns| ns.ns&.strip == namespace_uri }
    return xml_ns.nsabr&.strip if xml_ns

    # Try package_infos
    pkg_info = package_infos.find { |pi| pi.ns&.strip == namespace_uri }
    pkg_info&.nsabr&.strip
  end
end
```

### Task 4: Fix ProcessingWorkflow Stub

**Current Problem**:

```ruby
# Line 250-266: STUB implementation
def load_shapechange_config(config_path)
  Object.new.tap do |config|
    def config.namespace_for_package(package_path)
      "http://example.org/#{parts.last.downcase}"  # FAKE!
    end
  end
end
```

**Fix**: Use real parser

```ruby
def load_shapechange_config(config_path)
  parser = Shapechange::ConfigParser.new
  config = parser.parse_file(config_path)
  config
rescue StandardError => e
  raise "Failed to load ShapeChange configuration: #{e.message}"
end
```

### Task 5: Update XsdMapEntry Model

**Add**: Missing attributes and `applies_to?` method

```ruby
class XsdMapEntry < Lutaml::Model::Serializable
  attribute :type, :string              # e.g., "CharacterString", "gml::CodeType"
  attribute :xsd_encoding_rules, :string # e.g., "iso19136_2007 gml33 citygml"
  attribute :xml_type, :string          # e.g., "string", "gml:CodeType"
  attribute :xml_property_type, :string # e.g., "gml:CodePropertyType"
  attribute :xml_element, :string       # e.g., "gml:Code"
  attribute :xml_type_type, :string     # "simple" or "complex"
  attribute :xml_type_content, :string  # "simple" or "complex"

  # Check if this mapping applies to an encoding rule
  def applies_to?(encoding_rule_name)
    return true unless xsd_encoding_rules

    # xsd_encoding_rules is space-separated list
    xsd_encoding_rules.split.include?(encoding_rule_name)
  end
end
```

## Expected Results After Phase 1 Fix

### Resolution Statistics

```
Package: uro (255 classes, 1,141 attributes)

Resolution:
  ✅ Resolved: 1,050+ (>92%)
  ❌ Unresolved: <100 (8%)

By method:
  ✓ shapechange_rule: 950 (83%) ← Via XsdMapEntry
    - CharacterString → string
    - Integer → integer
    - gml::CodeType → gml:CodeType
    - etc.

  ✓ lxr_direct: 100 (9%) ← Via LXR namespace lookup
    - uro::BuildingDetailAttribute → uro:BuildingDetailAttribute

  ✗ unresolved: <100 (8%) ← No mapping available
    - Custom types not in XsdMapEntry
    - Complex associations
```

### Sample Verbose Output

```
[5/255] BridgeFunctionalAttribute (DataType)

  [1/2] directionType
    UML type: gml::CodeType

    ShapeChange lookup:
      ✓ Found XsdMapEntry
      UML: gml::CodeType
      XSD: gml:CodeType (from config line 80)
      Encoding rule: citygml

    LXR validation:
      ✓ Type exists: gml:CodeType
      Namespace: http://www.opengis.net/gml/3.2
      Schema: basicTypes.xsd
      Definition: ComplexType with simpleContent

    ✅ RESOLVED (shapechange_rule, 100%)

  [2/2] userType
    UML type: gml::CodeType
    ✓ XsdMapEntry → gml:CodeType
    ✓ LXR validated
    ✅ RESOLVED (shapechange_rule, 100%)
```

## Phase 2: Full ShapeChange Replication (Future Work)

### Overview

Create a `lutaml-klin shapechange` command that generates XSD files from XMI, fully replicating ShapeChange's transformation algorithm.

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│         lutaml-klin shapechange Command                  │
└─────────────────────────────────────────────────────────┘

Input:
  - XMI file (from Enterprise Architect or generic)
  - ShapeChange config XML
  - Encoding rule selection

     ↓

┌─────────────────┐
│  UML Model      │ ← Load via lutaml (UmlRepository)
│  Loader         │   - Parse XMI
└────────┬────────┘   - Build ClassInfo/PropertyInfo tree
         │
         ↓
┌─────────────────┐
│ Transformation  │ ← Apply transformations
│ Pipeline        │   - TypeConverter (type substitution)
└────────┬────────┘   - Flattener (inline associations)
         │            - DescriptorTransformer
         ↓            - etc.
┌─────────────────┐
│ XSD Generator   │ ← Core transformation engine
│ Engine          │
└────────┬────────┘
         │
         ├─ Package Processor
         │   └─ For each UML package → XSD schema
         │
         ├─ Class Processor
         │   ├─ Apply stereotype rules (FeatureType, DataType, CodeList)
         │   ├─ Create complexType
         │   ├─ Create property type
         │   └─ Handle inheritance
         │
         ├─ Property Processor
         │   ├─ Determine element vs attribute
         │   ├─ Apply type mappings (XsdMapEntry)
         │   ├─ Apply naming rules
         │   ├─ Handle multiplicity
         │   └─ Add annotations
         │
         └─ Output Writer
             └─ Write XSD files

     ↓

Output:
  - urbanFunction.xsd
  - urbanObject.xsd
  - building.xsd
  - etc.
```

### Required Encoding Rules Implementation

**From iso19136_2007 (GML 3.2)**:

1. `rule-xsd-all-naming-gml`: Property type suffix, type suffix
2. `rule-xsd-cls-standard-gml-property-types`: Reuse vs inline property types
3. `rule-xsd-cls-no-base-class`: Suppress base class encoding
4. `rule-xsd-prop-att-map-entry`: Use XsdMapEntry for type mapping
5. `rule-xsd-cls-global-enumeration`: Global enumeration types
6. `rule-xsd-cls-codelist-asDictionary`: Code list handling

**From citygml extension**:

7. `rule-xsd-rel-association-classes`: Association class encoding
8. `rule-xsd-cls-basictype`: Basic type with facets
9. `rule-xsd-cls-union-asGroup`: Union as group
10. `rule-xsd-prop-initialValue`: Initial value → default
11. `rule-xsd-pkg-schematron`: Schematron constraints

### Key Transformation Logic

**Class to ComplexType**:

```ruby
class ClassProcessor
  def process_class(uml_class, encoding_rule)
    # 1. Determine stereotype handling
    case uml_class.stereotype
    when "FeatureType"
      create_feature_type(uml_class, encoding_rule)
    when "DataType"
      create_data_type(uml_class, encoding_rule)
    when "CodeList"
      create_code_list(uml_class, encoding_rule)
    when "Enumeration"
      create_enumeration(uml_class, encoding_rule)
    end
  end

  def create_feature_type(uml_class, encoding_rule)
    # Generate:
    # 1. <xs:element name="Building" type="BuildingType" substitutionGroup="gml:AbstractFeature"/>
    # 2. <xs:complexType name="BuildingType">
    #      <xs:complexContent>
    #        <xs:extension base="gml:AbstractFeatureType">
    #          <xs:sequence>
    #            ... properties ...
    #          </xs:sequence>
    #        </xs:extension>
    #      </xs:complexContent>
    #    </xs:complexType>
    # 3. <xs:complexType name="BuildingPropertyType">
    #      <xs:sequence minOccurs="0">
    #        <xs:element ref="Building"/>
    #      </xs:sequence>
    #      <xs:attributeGroup ref="gml:AssociationAttributeGroup"/>
    #    </xs:complexType>
  end
end
```

**Property to Element/Attribute**:

```ruby
class PropertyProcessor
  def process_property(uml_property, uml_class, context)
    # 1. Get type mapping
    map_entry = context.config.find_type_mapping(uml_property.type)

    # 2. Determine if XML attribute or element
    is_attribute = should_be_xml_attribute?(uml_property, context)

    # 3. Generate XSD
    if is_attribute
      generate_xml_attribute(uml_property, map_entry)
    else
      generate_xml_element(uml_property, map_entry, context)
    end
  end

  def should_be_xml_attribute?(uml_property, context)
    # Check tagged values
    return true if uml_property.tagged_value("xsdAsAttribute") == "true"

    # Check if basic type
    map_entry = context.config.find_type_mapping(uml_property.type)
    return false unless map_entry

    # Simple types can be attributes
    map_entry.xml_type_type == "simple" &&
      map_entry.xml_type_content == "simple" &&
      uml_property.multiplicity.upper == 1
  end
end
```

## Implementation Phases

### Phase 1A: Fix Current System (Week 1)

**Priority**: P0 (Blocking)

1. [ ] Replace stub config with real ConfigParser
2. [ ] Add helper methods to ShapeChangeConfiguration
3. [ ] Extract encoding rules in ConfigParser
4. [ ] Create EncodingRule model
5. [ ] Update XsdMapEntry model
6. [ ] Test with PLATEAU config
7. [ ] Verify >90% resolution rate

**Expected Outcome**: Working mapping generation with ShapeChange config

**Timeline**: 2-3 days

### Phase 1B: Enhance Resolution (Week 2)

**Priority**: P1 (Important)

8. [ ] Implement element vs attribute logic
9. [ ] Implement naming rules
10. [ ] Add property type information
11. [ ] Handle inheritance properly
12. [ ] Achieve >95% resolution

**Timeline**: 2-3 days

### Phase 2A: Study ShapeChange (Week 3-4)

**Priority**: P2 (Future)

13. [ ] Read ShapeChange XmlSchema target source
14. [ ] Extract transformation algorithms
15. [ ] Document encoding rule behaviors
16. [ ] Create test fixtures from ShapeChange JAR

**Timeline**: 1 week

### Phase 2B: Implement XSD Generation (Week 5-8)

**Priority**: P3 (Long-term)

17. [ ] Implement basic XSD generator
18. [ ] Implement encoding rules engine
19. [ ] Add GML property type generation
20. [ ] Add inheritance handling
21. [ ] Add annotation support
22. [ ] Validate against ShapeChange output

**Timeline**: 3-4 weeks

## Success Criteria

### Phase 1 (Mapping Generation)

✅ **Functional**:
- [ ] Load ShapeChange config successfully
- [ ] Extract all XsdMapEntry data
- [ ] Resolve >95% of PLATEAU URO attributes
- [ ] Generate complete YAML mappings
- [ ] LXR validation for all resolved types

✅ **Quality**:
- [ ] Type mappings match ShapeChange config
- [ ] Namespace mappings correct
- [ ] Package mappings correct
- [ ] Resolution metadata complete

### Phase 2 (XSD Generation)

✅ **Functional**:
- [ ] Generate valid XSD files
- [ ] Match ShapeChange output structure
- [ ] Support all GML 3.2 rules
- [ ] Support CityGML extensions

✅ **Quality**:
- [ ] XSD validates against W3C schema
- [ ] Output identical to ShapeChange for test cases
- [ ] All encoding rules implemented
- [ ] Comprehensive test coverage

## Next Immediate Actions

1. **Code Mode: Replace config stub** (15 minutes)
2. **Code Mode: Add helper methods** (30 minutes)
3. **Code Mode: Extract encoding rules** (30 minutes)
4. **Test: Run full pipeline** (10 minutes)
5. **Verify: Check resolution rate** (5 minutes)

**Expected**: >90% resolution rate after fixes

## Long-Term Vision

```bash
# Phase 1: Mapping generation (CURRENT)
lutaml-klin process \
  --lur packages/plateau_all.lur \
  --lxr packages/plateau_schemas.lxr \
  --config ShapeChangeConfig_Plateau_urf.xml \
  --packages "uro" \
  --output _site

# Phase 2: XSD generation (FUTURE)
lutaml-klin shapechange \
  --xmi sources/xmi/20251010-242.xmi \
  --config ShapeChangeConfig_Plateau_urf.xml \
  --output xsd/ \
  --packages "urf,uro" \
  --encoding-rule citygml

# Output: xsd/urbanFunction.xsd, xsd/urbanObject.xsd
# Compatible with ShapeChange 3.1.0 output
```

## Summary

**Phase 1** (Current): Fix config stub → >95% mapping resolution
**Phase 2** (Future): Full ShapeChange replication → XSD generation

**Immediate Focus**: Phase 1A (fix config stub, add helper methods)

**Timeline**:
- Phase 1: 1 week
- Phase 2: 4-5 weeks

The plan balances immediate needs (working mappings) with long-term goals (full ShapeChange compatibility). 🚀