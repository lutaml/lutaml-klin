# Three-Process Workflow Guide

**Version**: 1.0  
**Date**: 2025-12-02  
**Status**: Production

---

## Overview

LutaML Klin supports a flexible three-process workflow that separates XSD generation, LXR package creation, and SPA visualization into independent steps. This provides maximum flexibility and efficiency for iterative development.

---

## Why Separate Processes?

### Traditional Single-Process Approach

```bash
lutaml-klin process --lur model.lur --lxr schemas.lxr --config config.xml --output out/
```

**Pros**: Simple, one command  
**Cons**: Must regenerate everything even for small changes

### Three-Process Approach

```bash
# Process 1: XSD + Mapping
lutaml-klin xsd --lur model.lur --config config.xml --output step1/

# Process 2: LXR Package (optional, handled by lutaml-xsd)
# Uses lutaml-xsd package composition

# Process 3: SPA
lutaml-klin spa --mapping step1/mapping.yaml --output spa/
```

**Pros**: 
- Fast iteration (only regenerate what changed)
- Independent deployment
- Flexible composability

**Cons**: 
- More commands (mitigated by scripts)

---

## Complete Workflow Example: PLATEAU URO/URF

### Step 1: Generate XSD Schemas with Mappings

Generate XSD schemas from UML and create mapping YAML files:

```bash
# Generate URO (Urban Object) schemas
lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --packages uro \
  --output workflow/step1_uro/

# Generate URF (Urban Function) schemas
lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_urf.xml \
  --packages urf \
  --output workflow/step1_urf/
```

**Outputs** (per package):
```
workflow/
├── step1_uro/
│   ├── urbanObject.xsd           # Generated XSD schema
│   └── urbanObject_mapping.yaml  # Complete UML→XSD mapping
└── step1_urf/
    ├── urbanFunction.xsd
    └── urbanFunction_mapping.yaml
```

**Use Cases**:
- Initial schema generation from UML
- Schema updates after UML model changes
- Creating base schemas for extension

### Step 2: Create Complete LXR Package (Optional)

**Note**: This step uses the `lutaml-xsd` gem's package composition feature, not lutaml-klin.

If you need a comprehensive LXR package combining multiple source schemas:

```bash
# Using lutaml-xsd package composition (see lutaml-xsd docs)
lutaml-xsd package compose \
  --sources workflow/step1_uro/urbanObject.xsd \
           workflow/step1_urf/urbanFunction.xsd \
           external/gml/gml.xsd \
  --output workflow/step2/complete_schemas.lxr \
  --name "PLATEAU Complete Schemas" \
  --version "3.2"
```

**Outputs**:
```
workflow/step2/
└── complete_schemas.lxr  # Merged LXR package
```

**Use Cases**:
- Creating schema packages for distribution
- Combining generated + external schemas
- Building reusable schema repositories

### Step 3: Generate Interactive SPAs

Generate separate SPA websites for each package mapping:

```bash
# Generate URO SPA (Alpine.js template)
lutaml-klin spa \
  --mapping workflow/step1_uro/urbanObject_mapping.yaml \
  --output workflow/spa_uro/ \
  --template-type alpine

# Generate URF SPA (Vanilla JS template)
lutaml-klin spa \
  --mapping workflow/step1_urf/urbanFunction_mapping.yaml \
  --output workflow/spa_urf/ \
  --template-type vanilla
```

**Outputs** (per SPA):
```
workflow/
├── spa_uro/
│   ├── index.html          # Interactive website
│   ├── assets/
│   │   ├── css/style.css
│   │   └── js/app.js
│   └── data/
│       ├── mappings.json
│       ├── search_index.json
│       └── statistics.json
└── spa_urf/
    └── [same structure]
```

**Use Cases**:
- Creating documentation websites
- Interactive schema browsing
- Sharing mappings with stakeholders
- Quick visualization updates

---

## Process Details

### Process 1: XSD Generation (`xsd` command)

**Purpose**: Generate XSD schemas from UML with complete traceability

**Input**:
- LUR package (.lur)
- ShapeChange configuration (.xml)
- Package filter (e.g., "uro,urf")

**Output**:
- XSD schema files (.xsd)
- Mapping YAML files (.yaml)

**Key Features**:
- 37 conversion rules (100% ShapeChange parity for PLATEAU)
- Complete transformation tracking
- Per-package mapping files

**Performance**: ~10 seconds for 174 classes

**Example**:
```bash
lutaml-klin xsd \
  --lur model.lur \
  --config config.xml \
  --packages "uro,urf" \
  --output step1/ \
  --verbose
```

### Process 2: LXR Package Composition (lutaml-xsd)

**Purpose**: Create comprehensive schema repository packages

**Input**:
- Multiple XSD schema files
- Configuration for package metadata

**Output**:
- LXR package (.lxr)

**Key Features**:
- Merges multiple schema sources
- Fast loading (<100ms vs seconds for XSD parsing)
- Reusable across projects

**Note**: This process uses the `lutaml-xsd` gem. See [lutaml-xsd documentation](https://github.com/lutaml/lutaml-xsd) for details.

### Process 3: SPA Generation (`spa` command)

**Purpose**: Generate interactive visualization from mapping files

**Input**:
- Mapping YAML file (.yaml)

**Output**:
- Complete SPA website (HTML/CSS/JS)

**Key Features**:
- Two template types (Alpine.js, Vanilla JS)
- Search and filtering
- Package hierarchy navigation
- Statistics dashboard

**Performance**: <1 second for most mappings

**Example**:
```bash
lutaml-klin spa \
  --mapping step1/mapping.yaml \
  --output spa/ \
  --template-type alpine
```

---

## When to Use Each Process

### Use Process 1 When:
- ✅ UML model has changed
- ✅ Need to regenerate XSD schemas
- ✅ Want updated mappings
- ✅ Testing transformation rules

### Use Process 2 When:
- ✅ Combining multiple schema sources
- ✅ Creating distributable packages
- ✅ Need fast schema loading
- ✅ Building reusable repositories

### Skip Process 2 When:
- ✅ Working with single package
- ✅ Don't need LXR composition
- ✅ Using existing LXR packages

### Use Process 3 When:
- ✅ Need visualization updates
- ✅ Testing different templates
- ✅ Mapping file changed
- ✅ Creating documentation

---

## Performance Comparison

### Single Process (`process` command)

```bash
time lutaml-klin process --lur model.lur --lxr schemas.lxr --config config.xml --output out/
# Total time: ~12 seconds
```

### Three-Process Workflow

```bash
# Initial run (all three)
time lutaml-klin xsd --lur model.lur --config config.xml --output step1/  # ~10s
time lutaml-klin spa --mapping step1/mapping.yaml --output spa/          # ~1s
# Total time: ~11 seconds (similar)

# Subsequent runs (SPA only)
time lutaml-klin spa --mapping step1/mapping.yaml --output spa/          # ~1s
# Total time: 1 second (11x faster!)
```

**Benefit**: After initial generation, updates are 10-90% faster depending on what changed.

---

## Automation Scripts

### Complete Workflow Script

```bash
#!/bin/bash
# workflow.sh - Complete three-process workflow

set -e

echo "=== Process 1: XSD Generation ==="
lutaml-klin xsd \
  --lur packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --packages uro \
  --output output/step1_uro/

echo "=== Process 3: SPA Generation ==="
lutaml-klin spa \
  --mapping output/step1_uro/urbanObject_mapping.yaml \
  --output output/spa_uro/ \
  --template-type alpine

echo "=== Complete! ==="
echo "XSD: output/step1_uro/urbanObject.xsd"
echo "Mapping: output/step1_uro/urbanObject_mapping.yaml"
echo "SPA: output/spa_uro/index.html"
```

### SPA-Only Update Script

```bash
#!/bin/bash
# update-spa.sh - Fast SPA regeneration

set -e

echo "=== Regenerating SPAs ==="
lutaml-klin spa \
  --mapping output/step1_uro/urbanObject_mapping.yaml \
  --output output/spa_uro/

echo "=== Done! ==="
open output/spa_uro/index.html
```

---

## Troubleshooting

### Issue: "Mapping file not found"

**Cause**: Process 1 hasn't run yet or output path is wrong

**Solution**:
```bash
# Check if mapping file exists
ls -la step1/urbanObject_mapping.yaml

# Regenerate if missing
lutaml-klin xsd --lur model.lur --config config.xml --packages uro --output step1/
```

### Issue: "Invalid mapping file"

**Cause**: Corrupted YAML or wrong file format

**Solution**:
```bash
# Validate YAML syntax
ruby -ryaml -e "YAML.load_file('step1/urbanObject_mapping.yaml')"

# Regenerate mapping
lutaml-klin xsd --lur model.lur --config config.xml --packages uro --output step1/
```

### Issue: SPA not loading correctly

**Cause**: JavaScript errors or missing data

**Solution**:
```bash
# Check browser console for errors
open spa/index.html

# Regenerate with embedded data
lutaml-klin spa \
  --mapping step1/mapping.yaml \
  --output spa/ \
  --template-type alpine \
  --verbose
```

---

## Best Practices

### 1. Version Control

Commit mapping files separately from generated XSD/SPA:

```
.gitignore:
*.xsd              # Generated schemas (regenerate from UML)
spa/               # Generated websites (regenerate from mapping)

Git tracked:
*_mapping.yaml     # Mapping files (important documentation)
```

### 2. Directory Organization

Use clear directory structure:

```
project/
├── packages/           # Source packages
│   ├── model.lur
│   └── schemas.lxr
├── config/             # Configurations
│   └── shapechange.xml
├── workflow/           # Three-process outputs
│   ├── step1_xsd/      # Process 1 outputs
│   ├── step2_lxr/      # Process 2 outputs (optional)
│   └── step3_spa/      # Process 3 outputs
└── scripts/            # Automation scripts
    ├── workflow.sh
    └── update-spa.sh
```

### 3. CI/CD Integration

```yaml
# .github/workflows/mappings.yml
- name: Generate schemas
  run: lutaml-klin xsd --lur model.lur --config config.xml --output dist/

- name: Generate SPA
  run: lutaml-klin spa --mapping dist/mapping.yaml --output docs/

- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    publish_dir: ./docs
```

---

## Summary

The three-process workflow provides:

1. **Process 1 (XSD)**: Generate schemas + mappings from UML
2. **Process 2 (LXR)**: Compose comprehensive schema packages (optional)
3. **Process 3 (SPA)**: Create interactive visualizations

**Key Benefits**:
- Fast iteration (only regenerate what changed)
- Independent deployment
- Clear separation of concerns
- Flexible composability

**When to Use**:
- Large projects with multiple packages
- Iterative development workflows
- Documentation-first approaches
- CI/CD pipelines

---

**See Also**:
- [README.adoc](../README.adoc) - Complete lutaml-klin documentation
- [SPA_GENERATOR.md](SPA_GENERATOR.md) - SPA generation details
- [lutaml-xsd documentation](https://github.com/lutaml/lutaml-xsd) - LXR package composition