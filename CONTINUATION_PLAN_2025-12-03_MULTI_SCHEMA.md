# Continuation Plan: Multi-Schema SPA Support

**Session**: Next Session  
**Date**: 2025-12-03+  
**Phase**: Phase 6 - Multi-Schema Support (2.5-3 hours remaining)  
**Priority**: P0 (Critical Feature)

---

## Context: What's Been Completed

### ✅ Phase 1-4: Base SPA Implementation (Previous Session)
- Enhanced data model to hash-based structure (packages, classes, attributes)
- Created XML instance generator with mapping comments
- Integrated Prism.js for syntax highlighting
- Package tree navigation with expand/collapse
- Class detail view with UML and XSD information
- Responsive design
- All 16 tests passing

### ✅ Phase 5.1: Testing & Bug Fixes (This Session - 1 hour)
**Critical Bug Fixed**: Template placeholder replacement
- **Issue**: `%{MAPPINGS_JSON}` wasn't being replaced with actual data
- **Root Cause**: Template used `%{...}` but replacement used `%<...>s` format
- **Fix**: Updated [`spa_workflow.rb:286-298`](lib/lutaml/klin/application/spa_workflow.rb:286) to use correct format
- **Result**: Data now properly embedded in HTML

**Integration Tests Created**:
- **File**: [`spec/integration/spa_navigation_spec.rb`](spec/integration/spa_navigation_spec.rb:1) (338 lines)
- **Coverage**: HTML structure, data files, asset files, data consistency, XML instances, statistics
- **Status**: 4 examples passing (partial run before cancellation)

### ✅ Phase 6.1: CLI & Command Foundation (This Session - 30 min)
**Updated CLI**:
- **File**: [`lib/lutaml/klin/cli.rb:541`](lib/lutaml/klin/cli.rb:541)
- **Change**: `option :mapping, type: :array` (was `:string`)
- **Usage**: `--mapping file1.yaml --mapping file2.yaml`

**Updated SpaCommand**:
- **File**: [`lib/lutaml/klin/commands/spa_command.rb`](lib/lutaml/klin/commands/spa_command.rb:1)
- **Changes**:
  - Accepts array of mapping files
  - Validates all files exist
  - Displays multi-file configuration
  - Calls `generate_spa_from_files()` (not yet implemented)

---

## Remaining Work: Tasks 6.2-6.5 (2.5-3 hours)

### Task 6.2: Implement Mapping Merger (1.5 hours)

**Objective**: Create `generate_spa_from_files()` method that merges multiple mapping YAMLs by UML class.

#### Step 1: Add Method to SpaWorkflow (45 min)

**File**: [`lib/lutaml/klin/application/spa_workflow.rb`](lib/lutaml/klin/application/spa_workflow.rb:1)

**Implementation**:
```ruby
# Generate SPA from multiple mapping files (multi-schema comparison)
#
# @param mapping_file_paths [Array<String>] Paths to mapping YAML files
# @param output_path [String] Output directory path
# @param options [Hash] Additional options
# @return [String] Path to generated SPA directory
def generate_spa_from_files(
  mapping_file_paths:,
  output_path:,
  template_type: :alpine,
  data_mode: :embedded,
  title: nil
)
  # 1. Load all SchemaMapping objects
  schema_mappings = mapping_file_paths.map do |path|
    raise ArgumentError, "File not found: #{path}" unless File.exist?(path)
    
    yaml_content = File.read(path)
    mapping = Lutaml::Klin::Mapping::SchemaMapping.from_yaml(yaml_content)
    
    # Extract schema name from file or mapping metadata
    schema_name = extract_schema_name(path, mapping)
    
    { name: schema_name, mapping: mapping, path: path }
  end
  
  # 2. Merge mappings by UML class qualified name
  merged_mapping = merge_schema_mappings(schema_mappings)
  
  # 3. Generate SPA with merged data
  options = {
    template_type: template_type,
    data_mode: data_mode
  }
  options[:title] = title if title
  
  generate_spa(merged_mapping, output_path, options)
end

private

# Extract schema name from filename or mapping metadata
#
# @param file_path [String] Path to mapping file
# @param mapping [SchemaMapping] The schema mapping object
# @return [String] Schema name (e.g., "URO", "URF")
def extract_schema_name(file_path, mapping)
  # Try to get from mapping metadata
  if mapping.package_mappings&.first&.uml_name
    return mapping.package_mappings.first.uml_name
  end
  
  # Fall back to filename
  basename = File.basename(file_path, ".*")
  # urbanObject_mapping.yaml → URO
  # urbanFunction_mapping.yaml → URF
  if basename.include?("Object")
    "URO"
  elsif basename.include?("Function")
    "URF"
  else
    basename.split("_").first.upcase
  end
end

# Merge multiple schema mappings into one with multi-schema support
#
# @param schema_mappings [Array<Hash>] Array of {name:, mapping:, path:}
# @return [SchemaMapping] Merged schema mapping
def merge_schema_mappings(schema_mappings)
  # Start with first mapping as base
  base_mapping = schema_mappings.first[:mapping]
  
  # Create merged mapping structure
  merged = Lutaml::Klin::Mapping::SchemaMapping.new(
    version: base_mapping.version,
    generated_at: Time.now.utc.iso8601,
    source_lur: base_mapping.source_lur,
    source_lxr: base_mapping.source_lxr,
    source_config: base_mapping.source_config
  )
  
  # Build lookup table: qualified_name => [schema_name => class_mapping]
  class_lookup = Hash.new { |h, k| h[k] = {} }
  
  schema_mappings.each do |schema_data|
    schema_name = schema_data[:name]
    mapping = schema_data[:mapping]
    
    mapping.package_mappings.each do |pkg|
      (pkg.class_mappings || []).each do |cls|
        qualified_name = cls.uml_qualified_name || 
                         "#{pkg.uml_package_name}::#{cls.uml_name}"
        
        class_lookup[qualified_name][schema_name] = {
          class_mapping: cls,
          package_mapping: pkg
        }
      end
    end
  end
  
  # Create merged package mappings
  merged.package_mappings = []
  
  # Group by package name
  package_groups = {}
  class_lookup.each do |qualified_name, schemas|
    # Get package name from first schema
    first_pkg = schemas.values.first[:package_mapping]
    pkg_name = first_pkg.uml_package_name
    
    package_groups[pkg_name] ||= {
      package_info: first_pkg,
      classes: {}
    }
    
    package_groups[pkg_name][:classes][qualified_name] = schemas
  end
  
  # Build merged packages
  package_groups.each do |pkg_name, data|
    pkg_info = data[:package_info]
    
    merged_pkg = Lutaml::Klin::Mapping::PackageMapping.new(
      uml_name: pkg_info.uml_name,
      uml_package_name: pkg_info.uml_package_name,
      xsd_namespace: pkg_info.xsd_namespace,
      xsd_namespace_prefix: pkg_info.xsd_namespace_prefix,
      created_at: Time.now.utc.iso8601
    )
    
    # Build merged classes with multi-schema data
    merged_pkg.class_mappings = data[:classes].map do |qualified_name, schemas|
      # Create multi-schema class mapping
      create_multi_schema_class(qualified_name, schemas)
    end
    
    merged.package_mappings << merged_pkg
  end
  
  merged
end

# Create a ClassMapping with multiple schema variants
#
# @param qualified_name [String] UML qualified name
# @param schemas [Hash] Hash of schema_name => {class_mapping:, package_mapping:}
# @return [ClassMapping] Merged class mapping with schemas array
def create_multi_schema_class(qualified_name, schemas)
  # Use first schema as base for UML data
  first_schema = schemas.values.first
  base_class = first_schema[:class_mapping]
  
  # Create new class mapping with base UML data
  merged_class = Lutaml::Klin::Mapping::ClassMapping.new(
    uml_name: base_class.uml_name,
    uml_qualified_name: qualified_name,
    uml_stereotype: base_class.uml_stereotype,
    uml_documentation: base_class.uml_documentation
  )
  
  # Add multi-schema metadata (custom field for SPA)
  merged_class.schemas = schemas.map do |schema_name, data|
    cls = data[:class_mapping]
    {
      schema_name: schema_name,
      xsd_namespace: cls.xsd_namespace,
      xsd_element_name: cls.xsd_element_name,
      xsd_type_name: cls.xsd_type_name,
      xsd_documentation: cls.xsd_documentation,
      resolution_status: cls.resolution_status,
      resolution_method: cls.resolution_method,
      resolution_confidence: cls.resolution_confidence,
      attribute_mappings: cls.attribute_mappings
    }
  end
  
  merged_class
end
```

#### Step 2: Update ClassMapping Model (15 min)

**File**: [`lib/lutaml/klin/models/mapping/class_mapping.rb`](lib/lutaml/klin/models/mapping/class_mapping.rb:1)

Add `schemas` attribute:
```ruby
class ClassMapping < Lutaml::Model::Serializable
  attribute :uml_name, Lutaml::Model::Type::String
  attribute :uml_qualified_name, Lutaml::Model::Type::String
  # ... existing attributes ...
  
  # Multi-schema support: array of schema-specific mappings
  attribute :schemas, Lutaml::Model::Type::Array, default: -> { [] }
end
```

#### Step 3: Handle Backward Compatibility (30 min)

Ensure single-schema SPAs still work by detecting schema count in SpaGenerator.

---

### Task 6.3: Update SpaGenerator Data Model (1 hour)

**Objective**: Modify data generation to support multi-schema structure.

#### Step 1: Update `generate_classes_json` (45 min)

**File**: [`lib/lutaml/klin/domain/services/spa_generator.rb:178`](lib/lutaml/klin/domain/services/spa_generator.rb:178)

**Changes**:
```ruby
def generate_classes_json(schema_mapping)
  classes = {}
  
  schema_mapping.package_mappings.each do |pkg|
    pkg_id = generate_package_id(pkg)
    
    (pkg.class_mappings || []).each do |cls|
      class_id = generate_class_id(cls, pkg)
      
      # Check for multi-schema data
      if cls.schemas && !cls.schemas.empty?
        # Multi-schema mode: include all schema variants
        classes[class_id] = {
          id: class_id,
          name: cls.uml_name,
          qualified_name: cls.uml_qualified_name,
          package_id: pkg_id,
          stereotype: cls.uml_stereotype,
          definition: cls.uml_documentation,
          is_abstract: false,
          
          # Multi-schema structure
          schemas: cls.schemas.map do |schema|
            {
              schema_name: schema[:schema_name],
              xsd_element_name: schema[:xsd_element_name],
              xsd_type_name: schema[:xsd_type_name],
              xsd_namespace: schema[:xsd_namespace],
              resolution_status: schema[:resolution_status],
              resolution_method: schema[:resolution_method],
              resolution_confidence: schema[:resolution_confidence],
              
              # Generate XML instance for this schema
              xml_instance: generate_xml_for_schema(cls, schema),
              
              # Attributes specific to this schema
              attributes: generate_attributes_for_schema(cls, schema)
            }
          ]
        }
      else
        # Single-schema mode (backward compatible)
        classes[class_id] = {
          id: class_id,
          name: cls.uml_name,
          # ... existing single-schema structure ...
          schemas: [
            {
              schema_name: pkg.uml_name,
              xsd_element_name: cls.xsd_element_name,
              # ... etc ...
            }
          ]
        }
      end
    end
  end
  
  classes
end

def generate_xml_for_schema(cls, schema)
  xml_generator = XmlInstanceGenerator.new
  
  # Convert schema hash to attribute mapping format
  class_data = {
    name: cls.uml_name,
    xsd_element_name: schema[:xsd_element_name],
    xsd_type_name: schema[:xsd_type_name],
    xsd_namespace: schema[:xsd_namespace]
  }
  
  attributes = schema[:attribute_mappings]&.map do |attr|
    {
      name: attr.uml_name,
      uml_type: attr.uml_type,
      xsd_name: attr.xsd_name,
      xsd_type: attr.xsd_type,
      xsd_min_occurs: attr.xsd_min_occurs,
      xsd_max_occurs: attr.xsd_max_occurs
    }
  end || []
  
  xml_generator.generate_instance(
    class_data,
    attributes,
    include_comments: true,
    include_sample_values: true
  )
end
```

#### Step 2: Update Search Index (15 min)

Update search to include schema names in keywords.

---

### Task 6.4: Update Templates (30 min)

**Objective**: Add UI for schema comparison.

#### Step 1: Update Class Detail View (20 min)

**File**: [`lib/lutaml/klin/templates/spa_alpine/index.html:230`](lib/lutaml/klin/templates/spa_alpine/index.html:230)

Add schema selector:
```html
<div x-show="currentView === 'class' && currentClass">
  <h2>
    <span x-text="currentClass?.uml_name"></span>
  </h2>
  
  <!-- Schema Selector (if multiple schemas) -->
  <div x-show="currentClass?.schemas && currentClass.schemas.length > 1" 
       class="schema-selector">
    <h3>Compare Schemas:</h3>
    <div class="schema-tabs">
      <template x-for="(schema, index) in currentClass?.schemas" :key="index">
        <button 
          class="schema-tab"
          :class="{ 'active': selectedSchemaIndex === index }"
          @click="selectedSchemaIndex = index"
          x-text="schema.schema_name">
        </button>
      </template>
    </div>
  </div>
  
  <!-- Schema Details -->
  <template x-for="(schema, index) in currentClass?.schemas" :key="index">
    <div x-show="selectedSchemaIndex === index" class="schema-details">
      <div class="detail-section">
        <h3>Schema: <span x-text="schema.schema_name"></span></h3>
        <div class="detail-row">
          <div class="detail-label">XSD Namespace:</div>
          <div class="detail-value"><code x-text="schema.xsd_namespace"></code></div>
        </div>
        <div class="detail-row">
          <div class="detail-label">XSD Element:</div>
          <div class="detail-value"><code x-text="schema.xsd_element_name"></code></div>
        </div>
        <div class="detail-row">
          <div class="detail-label">XSD Type:</div>
          <div class="detail-value"><code x-text="schema.xsd_type_name"></code></div>
        </div>
      </div>
      
      <!-- XML Instance for this schema -->
      <div class="detail-section xml-instance-section">
        <h3>📄 XML Instance Example</h3>
        <pre class="xml-preview"><code class="language-markup" 
          x-text="schema.xml_instance" 
          x-init="$nextTick(() => Prism && Prism.highlightElement($el))"></code></pre>
      </div>
    </div>
  </template>
</div>
```

#### Step 2: Update Alpine.js State (10 min)

**File**: [`lib/lutaml/klin/templates/spa_alpine/assets/js/app.js:26`](lib/lutaml/klin/templates/spa_alpine/assets/js/app.js:26)

Add schema selection state:
```javascript
Alpine.data('mappingBrowser', () => ({
  // ... existing state ...
  selectedSchemaIndex: 0, // NEW: Track selected schema
  
  // ... existing methods ...
  
  showClass(classId) {
    // ... existing code ...
    
    // Reset schema index when switching classes
    this.selectedSchemaIndex = 0;
  }
}));
```

---

### Task 6.5: Add Multi-Schema Tests (30 min)

**Objective**: Test multi-schema SPA generation.

#### Create Test File

**File**: `spec/integration/multi_schema_spa_spec.rb` (NEW)

```ruby
# frozen_string_literal: true

require "spec_helper"
require "json"
require "fileutils"

RSpec.describe "Multi-Schema SPA", type: :integration do
  let(:uro_mapping) { "test_workflow/step1_uro/urbanObject_mapping.yaml" }
  let(:urf_mapping) { "test_workflow/step1_urf/urbanFunction_mapping.yaml" }
  let(:output_dir) { "tmp/multi_schema_spa_test" }

  before do
    skip "URF mapping not available" unless File.exist?(urf_mapping)
    
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)
  end

  after do
    FileUtils.rm_rf(output_dir) if File.exist?(output_dir)
  end

  describe "Multi-Schema Generation" do
    it "generates SPA from multiple mapping files" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      output = `#{cmd} 2>&1`
      expect($CHILD_STATUS.exitstatus).to eq(0), "Generation failed: #{output}"
      
      expect(File).to exist(File.join(output_dir, "index.html"))
      expect(File).to exist(File.join(output_dir, "data", "mappings.json"))
    end

    it "merges classes by UML qualified name" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      system(cmd)
      
      data = JSON.parse(File.read(File.join(output_dir, "data", "mappings.json")))
      classes = data["classes"]
      
      # Find a class that should exist in both schemas
      multi_schema_class = classes.values.find do |cls|
        cls["schemas"] && cls["schemas"].size > 1
      end
      
      expect(multi_schema_class).not_to be_nil, "No multi-schema classes found"
      expect(multi_schema_class["schemas"]).to be_an(Array)
      expect(multi_schema_class["schemas"].size).to be >= 2
    end

    it "includes schema names in multi-schema classes" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      system(cmd)
      
      data = JSON.parse(File.read(File.join(output_dir, "data", "mappings.json")))
      multi_schema_class = data["classes"].values.find do |cls|
        cls["schemas"]&.size.to_i > 1
      end
      
      schemas = multi_schema_class["schemas"]
      schema_names = schemas.map { |s| s["schema_name"] }
      
      expect(schema_names).to include("URO")
      expect(schema_names).to include("URF")
    end

    it "generates separate XML instances per schema" do
      cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
            "--mapping #{uro_mapping} " \
            "--mapping #{urf_mapping} " \
            "--output #{output_dir}"
      
      system(cmd)
      
      data = JSON.parse(File.read(File.join(output_dir, "data", "mappings.json")))
      multi_schema_class = data["classes"].values.find do |cls|
        cls["schemas"]&.size.to_i > 1
      end
      
      schemas = multi_schema_class["schemas"]
      
      schemas.each do |schema|
        expect(schema).to have_key("xml_instance")
        expect(schema["xml_instance"]).to include("<?xml")
        expect(schema["xml_instance"]).to include(schema["xsd_namespace"])
      end
    end
  end
end
```

---

## Success Criteria

### Task 6.2 Complete When:
- [ ] `generate_spa_from_files()` method exists
- [ ] `merge_schema_mappings()` merges by UML qualified name
- [ ] ClassMapping has `schemas` attribute
- [ ] Single-schema mode still works (backward compatible)

### Task 6.3 Complete When:
- [ ] `generate_classes_json` outputs multi-schema structure
- [ ] Each schema has separate XML instance
- [ ] Search index includes schema names

### Task 6.4 Complete When:
- [ ] Schema selector tabs render
- [ ] Clicking tab switches displayed schema
- [ ] XML instance updates per schema
- [ ] Styling matches existing design

### Task 6.5 Complete When:
- [ ] Multi-schema tests pass
- [ ] Tests verify merging logic
- [ ] Tests verify separate XML instances

---

## Testing Commands

### Generate Multi-Schema SPA
```bash
bundle exec ruby -Ilib exe/lutaml-klin spa \
  --mapping test_workflow/step1_uro/urbanObject_mapping.yaml \
  --mapping test_workflow/step1_urf/urbanFunction_mapping.yaml \
  --output test_multi_schema/spa/
```

### Run Multi-Schema Tests
```bash
bundle exec rspec spec/integration/multi_schema_spa_spec.rb --format documentation
```

### Run All Tests
```bash
bundle exec rspec
```

---

## Files to Modify

1. **lib/lutaml/klin/application/spa_workflow.rb** - Add `generate_spa_from_files()`, `merge_schema_mappings()`
2. **lib/lutaml/klin/models/mapping/class_mapping.rb** - Add `schemas` attribute
3. **lib/lutaml/klin/domain/services/spa_generator.rb** - Update `generate_classes_json()`
4. **lib/lutaml/klin/templates/spa_alpine/index.html** - Add schema selector UI
5. **lib/lutaml/klin/templates/spa_alpine/assets/js/app.js** - Add schema state
6. **lib/lutaml/klin/templates/spa_alpine/assets/css/style.css** - Add schema tab styles
7. **spec/integration/multi_schema_spa_spec.rb** - NEW: Multi-schema tests

---

## Implementation Order

1. ✅ CLI accepts array (DONE)
2. ✅ SpaCommand handles array (DONE)
3. → **Start Here**: Add `generate_spa_from_files()` to SpaWorkflow
4. Add `merge_schema_mappings()` helper
5. Update ClassMapping model
6. Update SpaGenerator data generation
7. Update templates (schema selector)
8. Add CSS for schema tabs
9. Update Alpine.js state
10. Create multi-schema tests
11. Verify all tests pass
12. Update documentation

---

**Last Updated**: 2025-12-03 09:16 UTC+8  
**Status**: Phase 6.1 Complete → Phase 6.2 Ready to Start  
**Estimated Remaining**: 2.5-3 hours