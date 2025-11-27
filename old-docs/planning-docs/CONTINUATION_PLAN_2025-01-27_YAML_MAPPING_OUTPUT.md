# Continuation Plan: YAML Mapping Output Feature

**Date**: 2025-01-27 (post-Phase 1)
**Phase**: Phase 1.5 - YAML Mapping Enhancement
**Status**: 📋 Planning
**Priority**: High (User Requested)

---

## 🎯 Objective

Add YAML mapping output to the XSD generation workflow that documents the complete UML→XSD transformation for each class and attribute.

**User Requirement**: Generate a YAML file alongside XSD schemas that maps:
- Each UML class to its XSD element/type
- Each UML attribute to its XSD property element
- Full transformation traceability

---

## 📊 Current State Analysis

### What Exists Today
1. **XSD Generation**: Works perfectly (100% parity)
2. **Mapping Models**: Already defined in [`lib/lutaml/klin/models/mapping/`](lib/lutaml/klin/models/mapping/)
   - [`SchemaMapping`](lib/lutaml/klin/models/mapping/schema_mapping.rb) - Root container
   - [`PackageMapping`](lib/lutaml/klin/models/mapping/package_mapping.rb) - Package-level mappings
   - [`ClassMapping`](lib/lutaml/klin/models/mapping/class_mapping.rb) - Class transformations
   - [`AttributeMapping`](lib/lutaml/klin/models/mapping/attribute_mapping.rb) - Property mappings
3. **MappingService**: Exists but used for UML↔existing XSD mapping, not XSD generation

### What's Missing
- Integration between XSD generation and mapping output
- Population of mapping models during XSD generation
- YAML serialization of mappings alongside XSD files

---

## 🏗️ Architecture Design

### High-Level Approach

```
XSD Generation Flow (Current):
UML Model → XsdGenerator → Processors → XSD File

XSD Generation Flow (Enhanced):
UML Model → XsdGenerator → Processors → XSD File
                             ↓
                    MappingCollector → YAML File
```

### Component Design

#### 1. MappingCollector Class
**Location**: `lib/lutaml/klin/shapechange/mapping_collector.rb`

**Responsibility**: Collect transformation data during XSD generation

**API**:
```ruby
class MappingCollector
  def initialize(package_name:, package_namespace:, config:)
    @mappings = []
  end

  # Called when a class is processed
  def record_class_mapping(uml_class:, xsd_element:, xsd_type:, context:)
    # Store class transformation
  end

  # Called when an attribute is processed
  def record_attribute_mapping(uml_attribute:, xsd_property:, context:)
    # Store attribute transformation
  end

  # Generate final SchemaMapping model
  def to_schema_mapping
    SchemaMapping.new(...)
  end

  # Serialize to YAML
  def to_yaml
    to_schema_mapping.to_yaml
  end
end
```

#### 2. Enhanced XsdGenerator
**Modification**: [`xsd_generator.rb`](lib/lutaml/klin/shapechange/xsd_generator.rb)

**Changes**:
```ruby
def generate_schema_for_package(pkg_name, output_dir)
  # ... existing code ...
  
  # NEW: Initialize mapping collector
  mapping_collector = MappingCollector.new(
    package_name: pkg_name,
    package_namespace: package_info.ns.strip,
    config: config
  )
  
  # Pass collector to context
  context[:mapping_collector] = mapping_collector
  
  # ... existing processing ...
  
  # NEW: Write YAML mapping file
  mapping_filename = filename.sub('.xsd', '_mapping.yaml')
  mapping_filepath = File.join(package_output_dir, mapping_filename)
  File.write(mapping_filepath, mapping_collector.to_yaml)
  
  # Return includes mapping file info
  { ..., mapping_file: mapping_filepath }
end
```

#### 3. Enhanced Processors
**Modification**: All rule processors that create XSD elements

**Pattern**:
```ruby
def apply_rule(uml_class, context)
  # ... existing XSD generation ...
  
  # NEW: Record mapping if collector present
  if context[:mapping_collector]
    context[:mapping_collector].record_class_mapping(
      uml_class: uml_class,
      xsd_element: element_name,
      xsd_type: type_name,
      context: context
    )
  end
end
```

**Affected Processors**:
- [`ObjectElementProcessor`](lib/lutaml/klin/shapechange/rule_processors/object_element_processor.rb) - Record element declarations
- [`ComplexTypeProcessor`](lib/lutaml/klin/shapechange/rule_processors/complex_type_processor.rb) - Record type definitions
- [`PropertyElementProcessor`](lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb) - Record property mappings
- [`EnumerationProcessor`](lib/lutaml/klin/shapechange/rule_processors/enumeration_processor.rb) - Record enum mappings
- [`BasicTypeProcessor`](lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor.rb) - Record basic type mappings

---

## 📋 YAML Mapping Format

### Example Output Structure

```yaml
---
version: "1.0"
generated_at: "2025-01-27T13:30:00Z"
source_lur: "spec/fixtures/packages/plateau_all.lur"
source_config: "examples/ShapeChangeConfig_Plateau_uro.xml"

package_mappings:
  - uml_package_name: "uro"
    uml_package_path: "PLATEAU::uro"
    xsd_namespace: "https://www.geospatial.jp/iur/uro/3.2"
    xsd_namespace_prefix: "uro"
    xsd_document: "urbanObject.xsd"
    created_at: "2025-01-27T13:30:00Z"
    
    class_mappings:
      - uml_class_name: "Building"
        uml_qualified_name: "PLATEAU::uro::Building"
        uml_stereotype: "FeatureType"
        
        xsd_element_name: "Building"
        xsd_element_type: "uro:BuildingType"
        xsd_element_substitution_group: "bldg:_AbstractBuilding"
        xsd_type_name: "BuildingType"
        xsd_type_base: "bldg:AbstractBuildingType"
        
        transformation_info:
          rules_applied:
            - "rule-xsd-cls-object-element"
            - "rule-xsd-cls-type"
            - "rule-xsd-cls-sequence"
          encoding_rule: "citygml"
          has_property_type: true
          
        attribute_mappings:
          - uml_attribute_name: "class"
            uml_attribute_type: "CodeList"
            uml_multiplicity: "0..1"
            
            xsd_property_name: "class"
            xsd_property_type: "gml:CodeType"
            xsd_min_occurs: "0"
            xsd_max_occurs: "1"
            
            transformation_info:
              type_mapping: "CodeList → gml:CodeType"
              rules_applied:
                - "rule-xsd-prop-encode-properties"
              resolved_via: "XsdMapEntry"
              
          - uml_attribute_name: "measuredHeight"
            uml_attribute_type: "Length"
            uml_multiplicity: "0..1"
            
            xsd_property_name: "measuredHeight"
            xsd_property_type: "gml:LengthType"
            xsd_min_occurs: "0"
            xsd_max_occurs: "1"
            
            transformation_info:
              type_mapping: "Length → gml:LengthType"
              rules_applied:
                - "rule-xsd-prop-encode-properties"
              resolved_via: "XsdMapEntry"

statistics:
  total_classes: 255
  total_attributes: 1847
  resolution_success_rate: 0.95
  rules_applied:
    - "rule-xsd-cls-object-element": 224
    - "rule-xsd-cls-type": 255
    - "rule-xsd-cls-sequence": 255
    - "rule-xsd-prop-encode-properties": 1847
```

---

## 🚀 Implementation Plan

### Phase 1.5A: File Cleanup (1-2h)

#### Task 1.5A.1: Archive Temporary Scripts
**Priority**: High
**Estimated**: 30 minutes

**Files to Archive** (move to `archive/temporary-scripts/`):
```
Root directory .rb files:
- analyze_element_gap.rb
- analyze_substitution_gap.rb
- analyze_wrong_classes.rb
- check_class_provenance.rb
- check_package_paths.rb
- compare_with_reference.rb
- debug_242_xmi.rb
- debug_classes.rb
- debug_property_elements.rb
- debug_property_processing.rb
- debug_xmi_structure.rb
- generate_full_xsd_mapping.rb
- generate_uro_mapping.rb
- generate_xsd_mapping_html.rb
- inspect_qualified_names.rb
- investigate_abstract_classes.rb
- investigate_repository.rb
- render_html.rb
- render_html_spa.rb
- test_attribute_loading.rb
- test_config_integration.rb
- test_correct_filtering.rb
- test_lxr_extractor.rb
- test_mapping_generation.rb
- test_namespace_fix.rb
- test_shapechange_integration.rb
- test_uml_attributes.rb
- test_xmi_fixture.rb
- test_xmi_navigator.rb
- test_xsd_analysis.rb
- test_xsd_analysis_simple.rb
- test_xsd_namespace_fix.rb
- validate_xsd_content.rb
```

**Shell scripts to archive** (move to `archive/temporary-scripts/`):
```
- archive_obsolete_docs.sh
- archive_remaining_docs.sh
```

**HTML/YAML files to archive** (move to `archive/temporary-output/`):
```
- uro_mapping.html
- uro_mapping_spa.html
- uro_mapping_data.yaml
```

**Keep in root** (legitimate tools):
- Gemfile, Gemfile.lock
- lutaml-klin.gemspec
- Rakefile
- README.adoc, ARCHITECTURE.adoc, EXAMPLES.adoc
- .rubocop.yml, .rubocop_todo.yml
- .gitignore, .DS_Store

#### Task 1.5A.2: Archive Test Output Directories
**Priority**: Medium
**Estimated**: 15 minutes

**Directories to archive** (move contents to `archive/test-outputs/`):
```
- debug_output/
- test_output/
- test_final/
- test_proper/
- verified_output/
- final_test_output/
```

**Keep**:
- tmp/ (standard temporary directory)
- examples/ (legitimate examples)

#### Task 1.5A.3: Clean Up TODO
**Priority**: Low
**Estimated**: 15 minutes

**Action**: Move `TODO/` directory contents to `old-docs/todos-2025-01/`

---

### Phase 1.5B: YAML Mapping Implementation (4-6h)

#### Task 1.5B.1: Create MappingCollector
**Priority**: High
**Estimated**: 2-3 hours
**File**: `lib/lutaml/klin/shapechange/mapping_collector.rb`

**Implementation Steps**:
1. Define MappingCollector class
2. Add methods to record class and attribute transformations
3. Build SchemaMapping model from collected data
4. Add YAML serialization support
5. Write comprehensive tests

**Key Methods**:
```ruby
# Record class-level transformation
def record_class_mapping(
  uml_class:,
  xsd_element_name: nil,
  xsd_type_name: nil,
  xsd_element_substitution_group: nil,
  xsd_type_base: nil,
  rules_applied: [],
  context: {}
)

# Record attribute-level transformation
def record_attribute_mapping(
  uml_attribute:,
  xsd_property_name:,
  xsd_property_type:,
  xsd_min_occurs: nil,
  xsd_max_occurs: nil,
  type_mapping_info: nil,
  rules_applied: [],
  context: {}
)

# Get current class being processed (for attribute mappings)
def current_class_mapping

# Generate statistics
def generate_statistics

# Convert to SchemaMapping model
def to_schema_mapping

# Serialize to YAML
def to_yaml
```

#### Task 1.5B.2: Integrate with XsdGenerator
**Priority**: High
**Estimated**: 1 hour
**File**: [`lib/lutaml/klin/shapechange/xsd_generator.rb`](lib/lutaml/klin/shapechange/xsd_generator.rb)

**Changes Required**:
1. Initialize MappingCollector in `generate_schema_for_package()`
2. Pass collector through context to all processors
3. Write YAML file after XSD generation
4. Update return value to include mapping file path

**Code Pattern**:
```ruby
def generate_schema_for_package(pkg_name, output_dir)
  # ... existing setup ...
  
  # NEW: Initialize mapping collector
  mapping_collector = Shapechange::MappingCollector.new(
    package_name: pkg_name,
    package_namespace: package_info.ns.strip,
    package_prefix: package_info.nsabr.strip,
    config: config,
    lur_path: @lur_path,
    config_path: @config_path
  )
  
  # Add to context
  context[:mapping_collector] = mapping_collector
  
  # ... existing processing ...
  
  # NEW: Write YAML mapping
  mapping_filename = filename.sub('.xsd', '_mapping.yaml')
  mapping_filepath = File.join(package_output_dir, mapping_filename)
  File.write(mapping_filepath, mapping_collector.to_yaml)
  
  # Enhanced return value
  {
    package: pkg_name,
    file: filepath,
    mapping_file: mapping_filepath,  # NEW
    namespace: package_info.ns.strip,
    classes_processed: classes.size,
    enums_processed: enums.size
  }
end
```

#### Task 1.5B.3: Enhance Processors
**Priority**: High
**Estimated**: 2 hours
**Files**: Multiple processor files

**Processors to Modify**:

1. **[`ObjectElementProcessor`](lib/lutaml/klin/shapechange/rule_processors/object_element_processor.rb)**
   - Record element name and substitution group
   - Capture transformation metadata

2. **[`ComplexTypeProcessor`](lib/lutaml/klin/shapechange/rule_processors/complex_type_processor.rb)**
   - Record type name and base type
   - Capture extension information

3. **[`PropertyElementProcessor`](lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb)**
   - Record each property transformation
   - Capture multiplicity changes
   - Note type mappings applied

4. **[`EnumerationProcessor`](lib/lutaml/klin/shapechange/rule_processors/enumeration_processor.rb)**
   - Record enumeration to simpleType mapping
   - Capture enumeration values

5. **[`BasicTypeProcessor`](lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor.rb)**
   - Record basic type to XSD type mapping
   - Capture restrictions applied

**Implementation Pattern**:
```ruby
def apply_rule(uml_class, context)
  # ... existing XSD generation ...
  
  # NEW: Record mapping
  collector = context[:mapping_collector]
  if collector
    collector.record_class_mapping(
      uml_class: uml_class,
      xsd_element_name: @element_name,
      xsd_type_name: @type_name,
      rules_applied: ["rule-xsd-cls-object-element"],
      context: {
        stereotype: uml_class.stereotype,
        abstract: uml_class.abstract?
      }
    )
  end
end
```

#### Task 1.5B.4: Enhance Mapping Models
**Priority**: Medium
**Estimated**: 1 hour
**Files**: [`lib/lutaml/klin/models/mapping/*.rb`](lib/lutaml/klin/models/mapping/)

**Enhancements Needed**:
1. Add `transformation_info` field to ClassMapping
2. Add `rules_applied` tracking
3. Add `encoding_rule` field
4. Add statistics summary
5. Ensure proper YAML serialization

**Example Enhancement**:
```ruby
class ClassMapping < Lutaml::Model::Serializable
  # ... existing attributes ...
  
  # NEW: Transformation metadata
  attribute :transformation_info, :hash, default: -> { {} }
  attribute :rules_applied, :string, collection: true
  attribute :encoding_rule, :string
end
```

#### Task 1.5B.5: Add CLI Option
**Priority**: Medium
**Estimated**: 30 minutes
**File**: [`lib/lutaml/klin/commands/xsd_generate_command.rb`](lib/lutaml/klin/commands/xsd_generate_command.rb)

**New Options**:
```ruby
option :generate_mapping,
  type: :boolean,
  default: true,
  desc: "Generate YAML mapping file alongside XSD (default: true)"

option :mapping_output_dir,
  type: :string,
  aliases: "-m",
  desc: "Custom output directory for mapping files (default: same as XSD)"
```

#### Task 1.5B.6: Write Tests
**Priority**: High
**Estimated**: 1-2 hours

**Test Files to Create/Update**:
1. `spec/lutaml/klin/shapechange/mapping_collector_spec.rb`
   - Test recording class mappings
   - Test recording attribute mappings
   - Test YAML serialization
   - Test statistics generation

2. `spec/integration/xsd_with_mapping_output_spec.rb`
   - Test complete workflow with mapping output
   - Verify YAML file created alongside XSD
   - Validate YAML structure and content
   - Check mapping accuracy

**Test Pattern**:
```ruby
it "generates YAML mapping alongside XSD" do
  result = generator.generate_schemas(["uro"], output_dir)
  
  # Check XSD exists
  expect(File.exist?(result[:file])).to be true
  
  # Check YAML mapping exists
  expect(File.exist?(result[:mapping_file])).to be true
  
  # Load and validate YAML
  mapping = YAML.load_file(result[:mapping_file])
  expect(mapping["package_mappings"]).not_to be_empty
  expect(mapping["class_mappings"].size).to be > 0
end
```

---

## 📁 File Cleanup Plan (Task 1.5A)

### Todo Checklist

1. **Create Archive Directories**
   ```bash
   mkdir -p archive/temporary-scripts
   mkdir -p archive/temporary-output
   mkdir -p archive/test-outputs
   mkdir -p old-docs/todos-2025-01
   ```

2. **Archive Temporary Ruby Scripts**
   ```bash
   mv analyze_*.rb archive/temporary-scripts/
   mv check_*.rb archive/temporary-scripts/
   mv compare_*.rb archive/temporary-scripts/
   mv debug_*.rb archive/temporary-scripts/
   mv generate_*.rb archive/temporary-scripts/
   mv inspect_*.rb archive/temporary-scripts/
   mv investigate_*.rb archive/temporary-scripts/
   mv render_*.rb archive/temporary-scripts/
   mv test_*.rb archive/temporary-scripts/
   mv validate_*.rb archive/temporary-scripts/
   ```

3. **Archive Shell Scripts**
   ```bash
   mv archive_*.sh archive/temporary-scripts/
   ```

4. **Archive Temporary Output**
   ```bash
   mv uro_mapping*.* archive/temporary-output/
   ```

5. **Archive Test Directories**
   ```bash
   mv debug_output archive/test-outputs/
   mv test_output archive/test-outputs/
   mv test_final archive/test-outputs/
   mv test_proper archive/test-outputs/
   mv verified_output archive/test-outputs/
   mv final_test_output archive/test-outputs/
   ```

6. **Archive TODOs**
   ```bash
   mv TODO/ old-docs/todos-2025-01/
   ```

7. **Commit Cleanup**
   ```bash
   git add -A
   git commit -m "chore: archive temporary scripts and test outputs
   
   - Move 30+ temporary .rb scripts to archive/temporary-scripts/
   - Move test output directories to archive/test-outputs/
   - Move TODO directory to old-docs/todos-2025-01/
   - Clean root directory for production release"
   ```

---

## 🔄 Implementation Workflow

### Step-by-Step Execution

#### Week 1: File Cleanup + Core Implementation
**Days 1-2**: File cleanup (Task 1.5A)
- Archive all temporary files
- Clean up root directory
- Prepare for production release

**Days 3-4**: MappingCollector implementation (Task 1.5B.1)
- Create MappingCollector class
- Implement recording methods
- Add YAML serialization
- Write unit tests

**Day 5**: Integration (Task 1.5B.2)
- Integrate with XsdGenerator
- Update context passing
- Test basic workflow

#### Week 2: Processor Enhancement + Testing
**Days 6-7**: Processor updates (Task 1.5B.3)
- Enhance ObjectElementProcessor
- Enhance ComplexTypeProcessor
- Enhance PropertyElementProcessor
- Enhance EnumerationProcessor
- Enhance BasicTypeProcessor

**Day 8**: Model enhancement (Task 1.5B.4)
- Update mapping models
- Add transformation metadata fields
- Ensure proper serialization

**Day 9**: CLI and integration tests (Task 1.5B.5, 1.5B.6)
- Add CLI options
- Write integration tests
- Verify end-to-end workflow

**Day 10**: Documentation and polish
- Update README with mapping feature
- Add usage examples
- Create user guide

---

## 📝 YAML Mapping Use Cases

### Use Case 1: Documentation Generation
**Need**: Generate human-readable documentation of UML→XSD transformation

**Benefit**: 
- Understand how each UML class maps to XSD
- Document design decisions
- Create traceability matrix

### Use Case 2: Validation
**Need**: Verify that XSD schema matches intended UML model

**Benefit**:
- Catch transformation errors
- Ensure completeness
- Validate type mappings

### Use Case 3: Round-Trip Engineering
**Need**: Recreate UML model from XSD schema

**Benefit**:
- Reverse engineering support
- Model synchronization
- Migration support

### Use Case 4: Analysis
**Need**: Analyze transformation patterns and statistics

**Benefit**:
- Identify common patterns
- Optimize transformations
- Generate reports

---

## 🎯 Success Criteria

### Functional Requirements
- [ ] YAML file generated alongside each XSD file
- [ ] All class transformations recorded
- [ ] All attribute transformations recorded
- [ ] Full transformation traceability included
- [ ] Statistics and metrics provided

### Quality Requirements
- [ ] Zero regressions in XSD generation
- [ ] All existing tests still passing (8/8)
- [ ] New tests for mapping functionality
- [ ] RuboCop compliant code
- [ ] Comprehensive documentation

### Performance Requirements
- [ ] Mapping collection adds <10% overhead
- [ ] YAML files under 5MB for typical packages
- [ ] No memory issues with large models

---

## 📊 Expected Output Examples

### Simple Class Example

**UML**:
```
Class: DmAttribute
Stereotype: DataType
Attributes:
  - key: String [1..1]
  - value: String [1..1]
```

**Generated YAML**:
```yaml
uml_class_name: "DmAttribute"
uml_stereotype: "DataType"
xsd_element_name: "DmAttribute"
xsd_type_name: "DmAttributeType"
has_property_type: true

attribute_mappings:
  - uml_name: "key"
    uml_type: "String"
    xsd_name: "key"
    xsd_type: "xs:string"
    
  - uml_name: "value"
    uml_type: "String"
    xsd_name: "value"
    xsd_type: "xs:string"
```

### Complex Class Example

**UML**:
```
Class: Building
Stereotype: FeatureType
Extends: bldg::AbstractBuilding
Attributes:
  - class: CodeList [0..1]
  - measuredHeight: Length [0..1]
  - usage: CodeList [0..*]
```

**Generated YAML**:
```yaml
uml_class_name: "Building"
uml_stereotype: "FeatureType"
xsd_element_name: "Building"
xsd_element_substitution_group: "bldg:_AbstractBuilding"
xsd_type_name: "BuildingType"
xsd_type_base: "bldg:AbstractBuildingType"
has_property_type: true

attribute_mappings:
  - uml_name: "class"
    uml_type: "CodeList"
    uml_multiplicity: "0..1"
    xsd_name: "class"
    xsd_type: "gml:CodeType"
    xsd_min_occurs: "0"
    type_mapping: "CodeList → gml:CodeType (via XsdMapEntry)"
    
  - uml_name: "measuredHeight"
    uml_type: "Length"
    uml_multiplicity: "0..1"
    xsd_name: "measuredHeight"
    xsd_type: "gml:LengthType"
    xsd_min_occurs: "0"
    type_mapping: "Length → gml:LengthType (via XsdMapEntry)"
    
  - uml_name: "usage"
    uml_type: "CodeList"
    uml_multiplicity: "0..*"
    xsd_name: "usage"
    xsd_type: "gml:CodeType"
    xsd_min_occurs: "0"
    xsd_max_occurs: "unbounded"
    type_mapping: "CodeList → gml:CodeType (via XsdMapEntry)"
```

---

## 🔍 Technical Considerations

### 1. Performance Impact
**Concern**: Collecting mappings shouldn't slow down XSD generation

**Mitigation**:
- Use in-memory collection (no I/O during processing)
- Write YAML only at end
- Make mapping generation optional via CLI flag

### 2. Memory Usage
**Concern**: Large models might consume excessive memory

**Mitigation**:
- Store only essential transformation data
- Use string references, not full objects
- Clear collector after file written

### 3. Backward Compatibility
**Concern**: Existing workflows shouldn't break

**Mitigation**:
- Make mapping generation optional (but enabled by default)
- No changes to XSD output
- All existing tests must still pass

### 4. Thread Safety
**Concern**: Future parallel processing might have issues

**Mitigation**:
- Design collector to be thread-safe
- One collector per package (no shared state)
- Immutable mapping records

---

## 📖 Documentation Updates

### README.adoc Additions

**New Section**: "YAML Mapping Output"
```adoc
== YAML Mapping Output

When generating XSD schemas, lutaml-klin automatically creates a YAML mapping
file that documents the complete UML→XSD transformation.

=== Structure

Each mapping file contains:

* Package-level metadata
* Class transformations
* Attribute transformations
* Statistics and metrics
* Traceability information

=== Example Usage

[source,bash]
----
# Generate XSD with mapping
lutaml-klin xsd \
  --lur model.lur \
  --config config.xml \
  --output out/ \
  --packages uro

# Output:
#   out/urbanObject.xsd         (XSD schema)
#   out/urbanObject_mapping.yaml (transformation map)
----

=== Disable Mapping Generation

If you only need XSD output:

[source,bash]
----
lutaml-klin xsd \
  --lur model.lur \
  --config config.xml \
  --output out/ \
  --packages uro \
  --no-generate-mapping
----
```

### New Documentation File

**File**: `docs/features/yaml-mapping-output.adoc`

**Content**:
- Detailed YAML format specification
- Complete examples
- Use case descriptions
- Integration guide

---

## 🧪 Testing Strategy

### Unit Tests
**File**: `spec/lutaml/klin/shapechange/mapping_collector_spec.rb`

**Test Cases**:
```ruby
describe MappingCollector do
  describe "#record_class_mapping" do
    it "stores class transformation data"
    it "handles multiple classes"
    it "tracks rules applied"
  end
  
  describe "#record_attribute_mapping" do
    it "stores attribute transformation data"
    it "associates with current class"
    it "handles multiplicity"
    it "tracks type mappings"
  end
  
  describe "#to_schema_mapping" do
    it "builds valid SchemaMapping model"
    it "includes all recorded classes"
    it "includes all recorded attributes"
    it "generates statistics"
  end
  
  describe "#to_yaml" do
    it "serializes to valid YAML"
    it "preserves all transformation data"
    it "is parseable by YAML.load"
  end
end
```

### Integration Tests
**File**: `spec/integration/yaml_mapping_generation_spec.rb`

**Test Cases**:
```ruby
describe "YAML Mapping Generation" do
  context "for URO package" do
    it "generates mapping file alongside XSD"
    it "includes all 255 classes"
    it "includes all attributes"
    it "has correct statistics"
  end
  
  context "for URF package" do
    it "generates mapping file alongside XSD"
    it "includes all 208 classes"
    it "has correct statistics"
  end
  
  context "with --no-generate-mapping" do
    it "skips mapping file generation"
    it "still generates XSD correctly"
  end
end
```

---

## 📋 Implementation Checklist

### Phase 1.5A: Cleanup (1-2h)
- [ ] Create archive directories
- [ ] Move temporary .rb scripts to archive/
- [ ] Move shell scripts to archive/
- [ ] Move test output directories to archive/
- [ ] Move TODO directory to old-docs/
- [ ] Commit cleanup changes

### Phase 1.5B: YAML Mapping (4-6h)
- [ ] Create MappingCollector class (2-3h)
- [ ] Integrate with XsdGenerator (1h)
- [ ] Enhance 5 key processors (2h)
- [ ] Update mapping models (1h)
- [ ] Add CLI option (30min)
- [ ] Write unit tests (1h)
- [ ] Write integration tests (1h)
- [ ] Update README documentation (30min)
- [ ] Create feature documentation (30min)
- [ ] Test end-to-end workflow (30min)

**Total Estimated**: 6-8 hours (1-2 weeks part-time)

---

## 🎯 Success Metrics

### Completion Criteria
- [ ] YAML mapping files generated for both URO and URF
- [ ] All class transformations documented in YAML
- [ ] All attribute transformations documented in YAML
- [ ] Statistics section includes counts and percentages
- [ ] CLI option to enable/disable mapping generation
- [ ] All existing tests still passing (8/8 = 100%)
- [ ] New tests for mapping functionality passing
- [ ] RuboCop compliant, zero warnings
- [ ] Documentation updated with examples

### Quality Gates
- [ ] Zero regressions in XSD generation
- [ ] Mapping overhead <10%
- [ ] YAML files are valid and parseable
- [ ] All transformation data preserved
- [ ] Code review approved

---

## 💡 Future Enhancements (Phase 1.6+)

### Beyond YAML: Additional Formats
1. **JSON Mapping**: For web applications
2. **GraphQL Schema**: For API documentation
3. **Markdown Report**: Human-readable transformation report
4. **CSV Export**: For spreadsheet analysis

### Advanced Features
1. **Diff Support**: Compare mappings across versions
2. **Merge Support**: Combine mappings from multiple packages
3. **Validation**: Verify XSD matches mapping
4. **Reverse Mapping**: XSD→UML direction

---

**Plan Version**: 1.0
**Created**: 2025-01-27
**Status**: Ready for implementation
**Estimated Total**: 8-10 hours (cleanup + implementation)
**Priority**: High (user requested)