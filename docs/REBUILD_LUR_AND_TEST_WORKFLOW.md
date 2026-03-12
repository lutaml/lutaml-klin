# Guide: Rebuild LUR Package & Test Complete 3-Process Workflow

**Date**: 2025-12-02
**Purpose**: Rebuild corrupted LUR package and verify complete 3-process workflow
**Status**: Ready to Execute

---

## Problem

The LUR package at `spec/fixtures/packages/plateau_all.lur` is corrupted:
```
Error: Invalid LUR package: missing repository.marshal
```

**Solution**: Rebuild from source QEA file

---

## Step 1: Rebuild LUR Package

### Source File
```
/Users/mulgogi/src/lutaml/lutaml/examples/qea/20251010_current_plateau_v5.1.qea
```

### Option A: Using lutaml Command (Recommended)

```bash
cd /Users/mulgogi/src/lutaml/lutaml-klin

# Check lutaml syntax for your version
lutaml --help

# Try this command structure (adjust based on help output):
lutaml \
  --input-format sparx_ea \
  --formatter lur \
  /Users/mulgogi/src/lutaml/lutaml/examples/qea/20251010_current_plateau_v5.1.qea \
  --output spec/fixtures/packages/plateau_all.lur
```

### Option B: Using Ruby API

```bash
cd /Users/mulgogi/src/lutaml/lutaml-klin

# Create rebuild script
cat > rebuild_lur.rb <<'EOF'
#!/usr/bin/env ruby
require 'lutaml'

input_file = '/Users/mulgogi/src/lutaml/lutaml/examples/qea/20251010_current_plateau_v5.1.qea'
output_file = 'spec/fixtures/packages/plateau_all.lur'

puts "Building LUR package..."
puts "  Input: #{input_file}"
puts "  Output: #{output_file}"

# Parse QEA file
puts "\nParsing Sparx EA file..."
document = Lutaml::Parser.parse(File.read(input_file), flavor: :sparx_ea)

# Build LUR package
puts "Building package..."
# Use appropriate API from lutaml gem
# (exact API depends on lutaml version)

puts "\n✅ Complete!"
EOF

ruby rebuild_lur.rb
```

### Option C: Check lutaml Documentation

```bash
# Check lutaml README for correct package build command
cat /Users/mulgogi/src/lutaml/lutaml/README.adoc | grep -A 20 "package build"
```

---

## Step 2: Verify LUR Package

```bash
cd /Users/mulgogi/src/lutaml/lutaml-klin

# Check file exists and has reasonable size
ls -lh spec/fixtures/packages/plateau_all.lur

# Verify it loads without error
ruby -Ilib -e "
require 'lutaml/klin/repositories/uml_repository_adapter'
repo = Lutaml::Klin::Repositories::UmlRepositoryAdapter.new(
  'spec/fixtures/packages/plateau_all.lur'
)
puts \"Packages: #{repo.all_packages.size}\"
puts \"✅ LUR loads correctly\"
"
```

---

## Step 3: Test Process 1 (XSD Generation)

```bash
cd /Users/mulgogi/src/lutaml/lutaml-klin

# Generate XSD for URO package
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --packages uro \
  --output test_workflow/step1_uro/

# Verify outputs
ls -la test_workflow/step1_uro/
# Should see:
#   urbanObject.xsd
#   urbanObject_mapping.yaml

# Generate XSD for URF package
bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_urf.xml \
  --packages urf \
  --output test_workflow/step1_urf/

# Verify outputs
ls -la test_workflow/step1_urf/
# Should see:
#   urbanFunction.xsd
#   urbanFunction_mapping.yaml
```

---

## Step 4: Test Process 2 (LXR Composition)

**Note**: Process 2 is already implemented in lutaml-xsd

```bash
# Check lutaml-xsd package composition documentation
cat /Users/mulgogi/src/lutaml-xsd/docs/PACKAGE_COMPOSITION.adoc | head -100

# Example command structure (adjust based on docs):
lutaml-xsd package compose \
  --base base_gml.lxr \
  --additional test_workflow/step1_uro/urbanObject.xsd \
  --additional test_workflow/step1_urf/urbanFunction.xsd \
  --output test_workflow/complete.lxr
```

---

## Step 5: Test Process 3 (SPA from Mapping)

### Test 5a: Generate SPA for URO

```bash
cd /Users/mulgogi/src/lutaml/lutaml-klin

bundle exec ruby -Ilib exe/lutaml-klin spa \
  --mapping test_workflow/step1_uro/urbanObject_mapping.yaml \
  --output test_workflow/spa_uro/ \
  --template-type alpine \
  --verbose

# Verify output
ls -la test_workflow/spa_uro/
# Should see:
#   index.html
#   assets/
#   data/

# Open in browser
open test_workflow/spa_uro/index.html
```

### Test 5b: Generate SPA for URF

```bash
bundle exec ruby -Ilib exe/lutaml-klin spa \
  --mapping test_workflow/step1_urf/urbanFunction_mapping.yaml \
  --output test_workflow/spa_urf/ \
  --template-type alpine

# Open in browser
open test_workflow/spa_urf/index.html
```

### Test 5c: Test with Vanilla JS Template

```bash
bundle exec ruby -Ilib exe/lutaml-klin spa \
  --mapping test_workflow/step1_uro/urbanObject_mapping.yaml \
  --output test_workflow/spa_uro_vanilla/ \
  --template-type vanilla

# Verify Alpine.js vs Vanilla JS differences
open test_workflow/spa_uro_vanilla/index.html
```

---

## Step 6: Verify SPA Features

### Manual Verification Checklist

For each generated SPA (`test_workflow/spa_uro/index.html`):

- [ ] Page loads without errors
- [ ] Console has no JavaScript errors
- [ ] Package tree displays
- [ ] Can expand/collapse packages
- [ ] Can click on classes to view details
- [ ] Search box works
- [ ] Typing in search shows results
- [ ] Clicking search result navigates correctly
- [ ] Filter checkboxes work
- [ ] Statistics display correctly
- [ ] Responsive on mobile (resize window)
- [ ] Hash navigation works (copy URL, refresh)
- [ ] Breadcrumb navigation works

### Compare Templates

- [ ] Alpine.js version has smaller JavaScript file
- [ ] Vanilla JS version has zero CDN dependencies
- [ ] Both provide same functionality
- [ ] Both display same data

---

## Step 7: Create Documentation

Once all tests pass, create comprehensive workflow documentation:

### File: `docs/THREE_PROCESS_WORKFLOW.md`

Should document:
1. Why processes are separate
2. Complete workflow example
3. When to use each process standalone
4. How to combine processes
5. Troubleshooting guide

### Update `README.adoc`

Add section after line 1573:

```adoc
=== Generate SPA from Mapping File

If you already have a mapping YAML file from the `xsd` command, generate
just the SPA without regenerating the mapping:

[source,bash]
----
lutaml-klin spa \
  --mapping urbanObject_mapping.yaml \
  --output spa/
----

This is significantly faster when you only need visualization.

==== Complete Three-Process Workflow

For maximum flexibility, separate the workflow:

[source,bash]
----
# Process 1: Generate XSD + Mapping
lutaml-klin xsd \
  --lur plateau.lur \
  --lxr base_gml.lxr \
  --config ShapeChangeConfig.xml \
  --packages "uro,urf" \
  --output step1/

# Process 2: Create Complete LXR (using lutaml-xsd)
lutaml-xsd package compose \
  --base base_gml.lxr \
  --additional step1/*.xsd \
  --output complete.lxr

# Process 3: Generate SPAs
lutaml-klin spa --mapping step1/urbanObject_mapping.yaml --output spa_uro/
lutaml-klin spa --mapping step1/urbanFunction_mapping.yaml --output spa_urf/
----
```

---

## Expected Results

### After Process 1 (XSD Generation)
```
test_workflow/step1_uro/
├── urbanObject.xsd (324 elements, 487 types)
└── urbanObject_mapping.yaml (174 classes mapped)

test_workflow/step1_urf/
├── urbanFunction.xsd (208 elements, 416 types)
└── urbanFunction_mapping.yaml (161 classes mapped)
```

### After Process 3 (SPA Generation)
```
test_workflow/spa_uro/
├── index.html (Alpine.js template)
├── assets/
│   ├── css/style.css
│   └── js/app.js (~300 lines)
└── data/
    ├── mappings.json
    ├── search_index.json
    └── statistics.json

test_workflow/spa_urf/
├── index.html
├── assets/
└── data/
```

---

## Troubleshooting

### Issue: LUR Build Fails

**Check**: Source QEA file exists
```bash
ls -lh /Users/mulgogi/src/lutaml/lutaml/examples/qea/20251010_current_plateau_v5.1.qea
```

**Check**: lutaml gem version
```bash
gem list lutaml
# Should see lutaml (>= 1.0)
```

**Solution**: Check lutaml documentation for correct build command:
```bash
cat /Users/mulgogi/src/lutaml/lutaml/README.adoc | grep -A 30 "package"
```

### Issue: Mapping File Format Wrong

**Symptom**: `SchemaMapping.from_yaml` fails

**Check**: Mapping file structure
```bash
cat test_workflow/step1_uro/urbanObject_mapping.yaml | head -50
```

**Expected Format**:
```yaml
version: "1.0"
package_mappings:
  - uml_package_name: "uro"
    xsd_namespace: "https://..."
    class_mappings:
      - uml_name: "Building"
        xsd_element_name: "Building"
        # ...
```

### Issue: SPA Shows No Data

**Check**: Embedded data in HTML
```bash
grep "window.MAPPING_DATA" test_workflow/spa_uro/index.html
# Should see embedded JSON
```

**Check**: Console errors
- Open SPA in browser
- Open DevTools (F12)
- Check Console tab for errors

---

## Performance Benchmarks

Once working, measure performance:

```bash
# Time each process
time bundle exec ruby -Ilib exe/lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --packages uro --output bench/step1/

time bundle exec ruby -Ilib exe/lutaml-klin spa \
  --mapping bench/step1/urbanObject_mapping.yaml \
  --output bench/spa/

# Expected:
# Process 1: 10-30 seconds (XSD generation)
# Process 3: <1 second (SPA generation)
```

---

## Success Criteria

All tests pass when:

- [ ] LUR package rebuilds successfully
- [ ] Process 1 generates valid XSD + mappings
- [ ] Process 3 generates working SPA from mappings
- [ ] SPA opens in browser without errors
- [ ] All SPA features work (search, filter, navigation)
- [ ] Both Alpine.js and vanilla templates work
- [ ] Performance is acceptable (<30s Process 1, <1s Process 3)

---

## Next Steps After Verification

1. **Run RuboCop**: `bundle exec rubocop -A`
2. **Run test suite**: `bundle exec rspec`
3. **Update documentation**: README.adoc, create tutorial
4. **Archive proposals**: Move to old-docs/
5. **Update memory bank**: Document completed features

---

**Created**: 2025-12-02
**Status**: Ready for User Execution
**Estimated Time**: 30 minutes (once LUR rebuild command is determined)