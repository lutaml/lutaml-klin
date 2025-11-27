# Dual Publication Strategy: Mapping Documentation + XSD Generation

## Vision: lutaml-klin as Complete ShapeChange Alternative

### Current Capability (Phase 1-2: Complete)

**What We Have Now**:
```
lutaml-klin process \
  --lur model.lur \
  --lxr schemas.lxr \
  --config shapechange.xml

Output:
  - YAML mapping documentation
  - Validation reports
  - Interactive SPA website
```

**Purpose**: Document how UML maps to EXISTING XSD

### Future Capability (Phase 3: Dual Publication)

**What We Need**:
```
lutaml-klin generate \
  --lur model.lur \
  --config shapechange.xml \
  --output output/

Output:
  - XSD files (urbanFunction.xsd, urbanObject.xsd, etc.)
  - YAML mapping documentation
  - Validation reports
  - Interactive SPA website
```

**Purpose**: GENERATE XSD files from UML (like ShapeChange) + Document them

## Why Dual Publication?

### Use Case 1: Schema Evolution

**Scenario**: Update PLATEAU UML model with new attributes

**Without XSD Generation**:
1. Update UML in Enterprise Architect
2. Run ShapeChange separately to generate XSD
3. Run lutaml-klin to document mappings
4. Manual verification

**With Dual Publication**:
1. Update UML in Enterprise Architect
2. Run lutaml-klin once:
   - Generates XSD files
   - Creates mapping documentation
   - Builds validation reports
   - Updates SPA website
3. Everything synchronized!

### Use Case 2: Schema Customization

**Scenario**: Create custom encoding rules for project-specific requirements

**With Dual Publication**:
- Modify ShapeChange config
- lutaml-klin generates both:
  - Custom XSD files with new rules
  - Documentation of what changed
- Side-by-side comparison of standard vs custom

### Use Case 3: Documentation + Distribution

**Scenario**: Publish schema package

**Dual Publication Output**:
```
release/
├── schemas/                  # XSD files for implementers
│   ├── urbanFunction.xsd
│   └── urbanObject.xsd
├── documentation/            # Human-readable docs
│   ├── mappings/
│   │   ├── uro.yaml
│   │   └── urf.yaml
│   └── spa/
│       └── index.html        # Interactive browser
└── validation/
    └── report.json           # Quality metrics
```

## Implementation Roadmap

### Phase 3A: Core XSD Generator (4-5 weeks)

**Goal**: Generate valid XSD files from UML

**Architecture**:

```
┌────────────────────────────────────────┐
│       XSD Generation Workflow           │
└────────────────────────────────────────┘

Input: LUR Package + ShapeChange Config
  ↓
┌─────────────────┐
│ UML Model       │
│ Loader          │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ Transformation  │ ← Optional: TypeConverter, Flattener
│ Pipeline        │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ XSD Generator   │
│ Engine          │
└────────┬────────┘
         │
         ├─ Package → Schema File
         ├─ Class → ComplexType + Element
         ├─ Attribute → Element/Attribute
         └─ Encoding Rules Application
         │
         ↓
┌─────────────────┐
│ XSD Files       │ ← urbanFunction.xsd, urbanObject.xsd
└─────────────────┘
```

**Components to Build**:

1. **XsdGenerator Service** (Domain Layer)
   ```ruby
   class XsdGenerator
     def initialize(encoding_rules)
       @rules = encoding_rules
     end

     def generate_schema(uml_package, config)
       # Create XSD document
       schema = build_schema_element(uml_package)

       # Add imports/includes
       add_dependencies(schema, uml_package, config)

       # Process classes
       uml_package.classes.each do |uml_class|
         process_class(uml_class, schema, config)
       end

       schema
     end

     private

     def process_class(uml_class, schema, config)
       case uml_class.stereotype
       when 'FeatureType'
         create_feature_type(uml_class, schema, config)
       when 'DataType'
         create_data_type(uml_class, schema, config)
       when 'CodeList'
         create_code_list(uml_class, schema, config)
       when 'Enumeration'
         create_enumeration(uml_class, schema, config)
       end
     end
   end
   ```

2. **ComplexTypeBuilder** (Domain Layer)
   ```ruby
   class ComplexTypeBuilder
     def build_feature_type(uml_class, config)
       # Generate:
       # 1. <xs:element name="Building" type="BuildingType"/>
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
       #      ... property type ...
       #    </xs:complexType>
     end
   end
   ```

3. **PropertyBuilder** (Domain Layer)
   ```ruby
   class PropertyBuilder
     def build_property(uml_attribute, config)
       if should_be_xml_attribute?(uml_attribute, config)
         build_xml_attribute(uml_attribute, config)
       else
         build_xml_element(uml_attribute, config)
       end
     end

     def should_be_xml_attribute?(uml_attr, config)
       # Check tagged values
       return true if uml_attr.tagged_value('xsdAsAttribute') == 'true'

       # Check if simple type with multiplicity 1
       type_mapping = config.find_type_mapping(uml_attr.type)
       return false unless type_mapping

       type_mapping.xml_type_type == 'simple' &&
         uml_attr.multiplicity.upper == 1
     end
   end
   ```

4. **EncodingRulesEngine** (Domain Layer)
   ```ruby
   class EncodingRulesEngine
     def initialize(encoding_rule, config)
       @encoding_rule = encoding_rule
       @config = config
     end

     def applies?(rule_name)
       # Check if rule applies to current encoding rule
       # Following ShapeChange's inheritance chain
       encoding_rule_def = @config.encoding_rules.find { |er| er.name == @encoding_rule }
       return false unless encoding_rule_def

       encoding_rule_def.has_rule?(rule_name, @config.encoding_rules)
     end
   end
   ```

5. **XsdWriter** (Infrastructure Layer)
   ```ruby
   class XsdWriter
     def write_schema(schema, output_path)
       # Serialize to XML with proper formatting
       # Add namespace declarations
       # Write to file
     end
   end
   ```

**Implementation Tasks**:

1. ✅ Study ShapeChange XmlSchema target (from reference sources) - 1 week
2. ⏳ Implement XsdGenerator service - 1 week
3. ⏳ Implement ComplexTypeBuilder - 3 days
4. ⏳ Implement PropertyBuilder - 3 days
5. ⏳ Implement EncodingRulesEngine - 1 week
6. ⏳ Implement XsdWriter - 2 days
7. ⏳ Integration testing - 1 week
8. ⏳ Comparison with ShapeChange output - 3 days

**Total Effort**: 4-5 weeks

### Phase 3B: Dual Publication Integration (1 week)

**Goal**: Generate BOTH XSD files AND mapping documentation in one command

**Architecture**:

```ruby
class DualPublicationWorkflow
  def execute(lur_path:, config_path:, output_path:, packages:)
    # Load sources
    uml_repo = load_lur(lur_path)
    config = load_shapechange_config(config_path)

    # Generate XSD files
    xsd_generator = XsdGenerator.new(config)
    xsd_files = packages.map do |pkg|
      xsd_generator.generate_schema(uml_repo.find_package(pkg), config)
    end

    # Write XSD files
    xsd_dir = File.join(output_path, 'schemas')
    xsd_files.each { |xsd| write_xsd(xsd, xsd_dir) }

    # Load generated XSD into LXR
    lxr_builder = LxrBuilder.new
    lxr_package = lxr_builder.build_from_xsd_files(xsd_files, config)

    # Generate mapping documentation
    mapping_workflow = MappingWorkflow.new(
      uml_repository: uml_repo,
      xsd_repository: lxr_package.repository,
      shapechange_config: config
    )

    mappings = mapping_workflow.generate_mappings(packages)

    # Output structure
    {
      xsd_files: xsd_dir,               # For implementers
      mappings: File.join(output_path, 'mappings'),  # For documentation
      validation: File.join(output_path, 'validation'),
      spa: File.join(output_path, 'spa')
    }
  end
end
```

**Command Interface**:

```bash
# Generate everything
lutaml-klin generate \
  --lur packages/plateau_all.lur \
  --config ShapeChangeConfig_Plateau_urf.xml \
  --packages "uro,urf" \
  --output release/

# Output:
# release/
# ├── schemas/          # XSD files (ShapeChange compatible)
# ├── mappings/         # YAML documentation
# ├── validation/       # Quality reports
# └── spa/              # Interactive browser
```

### Phase 3C: Validation and Comparison (1 week)

**Goal**: Ensure lutaml-klin XSD output is identical to ShapeChange

**Validation Strategy**:

1. **Structural Validation**:
   ```ruby
   class XsdValidator
     def compare_with_shapechange(lutaml_xsd, shapechange_xsd)
       {
         same_elements: compare_elements(lutaml_xsd, shapechange_xsd),
         same_types: compare_types(lutaml_xsd, shapechange_xsd),
         same_imports: compare_imports(lutaml_xsd, shapechange_xsd),
         differences: list_differences(lutaml_xsd, shapechange_xsd)
       }
     end
   end
   ```

2. **Semantic Validation**:
   - Parse both XSD with lutaml-xsd
   - Compare type structures
   - Verify namespace mappings
   - Check documentation annotations

3. **Test Suite**:
   ```ruby
   RSpec.describe 'XSD Generation' do
     it 'generates same elements as ShapeChange' do
       lutaml_output = generate_with_lutaml(test_xmi, test_config)
       shapechange_output = load_shapechange_reference(test_case)

       expect(lutaml_output.elements).to match_array(shapechange_output.elements)
     end
   end
   ```

## Benefits of Dual Publication

### For Users

1. **Single Tool**: One command for everything
2. **Consistency**: XSD and documentation always in sync
3. **Traceability**: Documentation shows how XSD was generated
4. **Validation**: Built-in quality checks

### For Developers

1. **ShapeChange Replacement**: Ruby-based alternative
2. **Easier Customization**: Modify encoding rules in Ruby
3. **Better Testing**: RSpec test suite
4. **Modern Architecture**: OO, MECE, separation of concerns

### For Projects

1. **Automated Workflow**: CI/CD integration
2. **Version Control**: Track XSD evolution
3. **Quality Assurance**: Validation reports
4. **Documentation**: Always up-to-date

## Implementation Priority

### Current Focus (Immediate)

**Continue improving mapping quality**:
- ✅ ShapeChange compatibility (76% achieved)
- ⏳ Improve to 90%+ resolution
- ⏳ Add LXR validation enhancement
- ⏳ Complete SPA features

### Phase 3 (Next 6 weeks)

**Add XSD generation**:
- Study ShapeChange algorithm (1 week)
- Implement core generator (4 weeks)
- Validate against ShapeChange (1 week)

### Phase 4 (Future)

**Advanced features**:
- OCL constraint translation to Schematron
- Multiple encoding rule support
- Custom transformation pipelines

## Current Status vs Dual Publication

### What We Have ✅

```
Input:  LUR + LXR + ShapeChange Config
↓
Process: Map UML to existing XSD
↓
Output: YAML + Validation + SPA
```

**Status**: PRODUCTION READY

### What We Need for Dual Publication ⏳

```
Input:  LUR + ShapeChange Config (NO LXR!)
↓
Process: Generate XSD from UML
↓
Output: XSD + YAML + Validation + SPA
```

**Status**: PLANNED (Phase 3)

## Recommendation

**Continue with current focus**:
1. Complete quality improvements to 90%+ resolution
2. Enhance SPA features and user experience
3. Add comprehensive test coverage
4. Document current capabilities fully

**Then proceed to Phase 3** when current functionality is polished and well-tested.

**Dual publication is a natural next step** but requires substantial work (4-5 weeks) to properly replicate ShapeChange's XSD generation algorithm.

The architecture is designed to support it - we have:
- ✅ TransformationAnalyzer (understands ShapeChange intent)
- ✅ EncodingRulesEngine (planned, easy to add)
- ✅ Clean separation of concerns
- ✅ Strategy pattern for extensibility

**We're well-positioned for Phase 3 when ready!**