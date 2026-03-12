# Process Separation Analysis & Feature Requests

**Date**: 2025-11-30
**Status**: Analysis Complete - Feature Requests Required

---

## Problem Statement

The current implementation mixes three distinct processes that should be completely separate and composable. This violates separation of concerns and prevents users from running each process independently.

## Required Processes (Should Be Separate)

### Process 1: XSD Generation from UML
**INPUT**:
- LUR package (UML model)
- ShapeChange configuration
- Base LXR package (GML, ISO 19xxx standards)

**OUTPUT**:
- Generated XSD files (URO.xsd, URF.xsd, etc.)
- Mapping YAML file (UML↔XSD mappings)

**Current Tool**: `lutaml-klin xsd`

**Status**: ✅ **CORRECTLY IMPLEMENTED**

**Example**:
```bash
lutaml-klin xsd \
  --lur plateau_all.lur \
  --config ShapeChangeConfig_Plateau.xml \
  --packages "uro,urf" \
  --output generated_schemas/
```

**Output**:
```
generated_schemas/
├── urbanObject.xsd
├── urbanObject_mapping.yaml
├── urbanFunction.xsd
└── urbanFunction_mapping.yaml
```

---

### Process 2: Create Complete LXR from XSDs
**INPUT**:
- Base XSD LXR (GML, ISO standards) OR base XSD files
- Newly generated XSD files (from Process 1)

**OUTPUT**:
- NEW LXR package containing ALL schemas (base + generated)

**Required Tool**: `lutaml-xsd package build` with **merge mode**

**Status**: ❌ **NOT IMPLEMENTED** - Feature request needed for lutaml-xsd

**Desired Example**:
```bash
# Option A: Merge two LXR packages
lutaml-xsd package merge \
  --base-lxr base_schemas.lxr \
  --additional-xsd generated_schemas/*.xsd \
  --output complete_schemas.lxr

# Option B: Build from mixed sources
lutaml-xsd package build \
  --lxr base_schemas.lxr \
  --xsd-dir generated_schemas/ \
  --output complete_schemas.lxr
```

**Desired Output**:
```
complete_schemas.lxr (contains):
  - GML 3.2 schemas (from base)
  - ISO 19xxx schemas (from base)  
  - URO schemas (newly added)
  - URF schemas (newly added)
```

---

### Process 3: SPA Generation from Complete Model
**INPUT**:
- LUR package (UML model)
- Complete LXR package (all schemas from Process 2)
- Mapping YAML file (from Process 1)

**OUTPUT**:
- Interactive SPA website

**Current Tool**: `lutaml-klin spa` OR `lutaml-klin process`

**Status**: ⚠️ **PARTIALLY IMPLEMENTED** - Issues identified

**Current Example (Problematic)**:
```bash
# This re-generates mappings instead of using existing ones
lutaml-klin process \
  --lur plateau_all.lur \
  --lxr complete_schemas.lxr \
  --config config.xml \
  --spa
```

**Desired Example**:
```bash
# Should accept pre-generated mapping file
lutaml-klin spa \
  --lur plateau_all.lur \
  --lxr complete_schemas.lxr \
  --mapping urbanObject_mapping.yaml \
  --output spa/
```

---

## Current Implementation Issues

### Issue 1: ProcessingWorkflow Mixes All Processes

**File**: `lib/lutaml/klin/application/processing_workflow.rb`

**Problem**: `ProcessingWorkflow.execute()` does:
1. Loads repositories (LUR + LXR)
2. Generates mappings (Process 1 logic mixed in)
3. Generates SPA (Process 3)

**Should Be**: Process 3 ONLY
- Takes LUR + LXR + PRE-GENERATED mapping file
- Generates SPA visualization

**Fix Required**: Refactor to accept `mapping_file_path` parameter

---

### Issue 2: XsdGenerator Mixed with Mapping Generation

**File**: `lib/lutaml/klin/shapechange/xsd_generator.rb`

**Current Behavior**: Generates XSD + mapping YAML together

**Status**: ✅ This is actually CORRECT for Process 1

**No Change Needed**: XSD and mapping should be generated together atomically

---

### Issue 3: No LXR Merge Capability

**Missing Feature**: Cannot merge base LXR with generated XSDs

**Impact**: Users cannot create a complete LXR package containing both:
- Standard base schemas (GML, ISO)
- Newly generated schemas (URO, URF)

**Fix Required**: Feature request to lutaml-xsd project

---

### Issue 4: SPA Workflow Doesn't Accept Mapping Files

**File**: `lib/lutaml/klin/application/spa_workflow.rb`

**Problem**: 
- `SpaWorkflow.generate_spa()` accepts `SchemaMapping` object, not file path
- No CLI command to generate SPA from existing mapping file

**Should Be**:
```ruby
SpaWorkflow.generate_spa_from_file(
  mapping_file_path: "urbanObject_mapping.yaml",
  output_path: "spa/"
)
```

**Fix Required**: Add file-based input option

---

## Correct Process Flow

### Complete Workflow (All 3 Processes)

```bash
# PROCESS 1: Generate XSD + Mapping
lutaml-klin xsd \
  --lur plateau_all.lur \
  --lxr base_schemas.lxr \
  --config ShapeChangeConfig_Plateau.xml \
  --packages "uro,urf" \
  --output step1_output/

# PROCESS 2: Create Complete LXR (MISSING TOOL!)
lutaml-xsd package merge \
  --base-lxr base_schemas.lxr \
  --additional-xsd step1_output/*.xsd \
  --output complete_schemas.lxr

# PROCESS 3: Generate SPA (NEEDS FIX!)
lutaml-klin spa \
  --lur plateau_all.lur \
  --lxr complete_schemas.lxr \
  --mapping step1_output/urbanObject_mapping.yaml \
  --output spa/
```

---

## Feature Requests Needed

### For lutaml-xsd Project

#### Feature Request 1: LXR Package Merge Command

**Command**: `lutaml-xsd package merge`

**Purpose**: Merge multiple XSD sources into single LXR package

**API**:
```bash
lutaml-xsd package merge \
  --base-lxr base_schemas.lxr \
  --additional-xsd dir1/*.xsd \
  --additional-xsd dir2/*.xsd \
  --output merged.lxr \
  --name "Complete Schema Repository" \
  --version "3.2"
```

**Options**:
- `--base-lxr PATH` - Base LXR package to merge into
- `--additional-xsd GLOB` - Additional XSD files (can repeat)
- `--additional-lxr PATH` - Additional LXR packages to merge (can repeat)
- `--output PATH` - Output LXR file
- `--name STRING` - Package name
- `--version STRING` - Package version
- `--conflict-resolution MODE` - How to handle conflicts (error/override/keep-first)

**Behavior**:
1. Load base LXR package
2. Parse additional XSD files
3. Detect namespace conflicts
4. Merge schemas into single repository
5. Write unified LXR package

---

#### Feature Request 2: LXR Package Build from Mixed Sources

**Command**: `lutaml-xsd package build` (enhancement)

**Purpose**: Build LXR from both existing LXR and XSD files

**API**:
```bash
lutaml-xsd package build \
  --lxr-base base_schemas.lxr \
  --xsd-dir generated_schemas/ \
  --namespaces namespaces.yaml \
  --output complete.lxr
```

**New Options**:
- `--lxr-base PATH` - Base LXR to include (optional)
- `--xsd-dir PATH` - Directory with XSD files (existing)
- `--xsd-file PATH` - Individual XSD file (can repeat)
- `--namespaces PATH` - Namespace configuration (existing)

**Behavior**: Include schemas from both LXR base and XSD files

---

### For lutaml-klin Project

#### Feature Request 3: SPA from Mapping File

**Command**: `lutaml-klin spa` (enhancement)

**Purpose**: Generate SPA from pre-existing mapping file

**API**:
```bash
lutaml-klin spa \
  --mapping mapping.yaml \
  --output spa/ \
  --template-type alpine
```

**Changes Needed**:

1. **SpaWorkflow Enhancement**:
```ruby
class SpaWorkflow
  # New method: Load mapping from YAML file
  def generate_spa_from_file(
    mapping_file_path:,
    output_path:,
    template_type: :alpine,
    data_mode: :embedded
  )
    # Load SchemaMapping from YAML
    mapping = Models::Mapping::SchemaMapping.from_yaml(
      File.read(mapping_file_path)
    )
    
    # Generate SPA (existing method)
    generate_spa(mapping, output_path, 
                 template_type: template_type,
                 data_mode: data_mode)
  end
end
```

2. **CLI Command**:
```ruby
desc "spa", "Generate SPA from mapping file"
method_option :mapping, type: :string, required: true,
  desc: "Path to mapping YAML file"
method_option :output, type: :string, required: true,
  desc: "Output directory for SPA"
method_option :template_type, type: :string, default: "alpine",
  enum: ["alpine", "vanilla"]
method_option :data_mode, type: :string, default: "embedded",
  enum: ["embedded", "linked"]
def spa
  # Implementation
end
```

---

#### Feature Request 4: ProcessingWorkflow Refactor

**Purpose**: Separate Process 3 from Process 1

**Changes Needed**:

1. **Current `process` command** - Keep but clarify it does Processes 1+3 together
2. **New workflow**: Accept pre-generated mappings

**API**:
```ruby
# Current (keeps both Process 1 + 3)
ProcessingWorkflow.execute(
  lur_path:, lxr_path:, config_path:,
  generate_mappings: true, generate_spa: true
)

# New (Process 3 only, with existing mapping)
ProcessingWorkflow.execute_from_mapping(
  mapping_file_path:,
  lxr_path: nil,  # optional, for validation
  generate_spa: true,
  validate: true
)
```

---

## Implementation Priority

### P0 (Critical for Proper Separation)
1. ✅ **lutaml-xsd**: LXR merge capability (Feature Request 1)
2. ✅ **lutaml-klin**: SPA from mapping file (Feature Request 3)

### P1 (Important for Workflow Clarity)
3. ⚠️ **lutaml-klin**: ProcessingWorkflow refactor (Feature Request 4)
4. ⚠️ **Documentation**: Update all docs to show 3 separate processes

### P2 (Nice to Have)
5. ◯ **lutaml-xsd**: Build from mixed sources (Feature Request 2)

---

## Conclusion

The Alpine.js SPA feature is complete and working, but the overall architecture needs these feature requests to properly separate the three distinct processes:

1. **Process 1** (XSD Generation): ✅ Works correctly
2. **Process 2** (LXR Merge): ❌ Missing - needs lutaml-xsd feature
3. **Process 3** (SPA from Mapping): ⚠️ Partially works, needs enhancement

All feature requests documented above should be filed with the respective projects.