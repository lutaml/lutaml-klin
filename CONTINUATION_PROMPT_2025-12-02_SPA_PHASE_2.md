# Continuation Prompt: SPA Enhancement - Phase 2 Start

**Session**: Next Session  
**Date**: 2025-12-02+  
**Phase**: Phase 2 - Template Updates  
**Priority**: P0 (Critical UX Improvement)  
**Estimated Duration**: 3 hours

---

## Quick Context

### What Was Done

✅ **Phase 1 Complete** (2025-12-02):
- Enhanced SPA data model from package-centric to UML-centric
- Created XML instance generator with UML/XSD mapping comments
- Tests: 16/16 passing ✅
- RuboCop: 0 violations ✅
- Verified with 174 classes, 961 attributes ✅

**Data Structure Now**:
```json
{
  "metadata": { version, generated_at, total_classes, ... },
  "packages": { "pkg-id": { name, classes: [...] } },
  "classes": { "class-id": { name, attributes: [...], xml_instance, ... } },
  "attributes": { "attr-id": { uml_type, xsd_type, ... } }
}
```

### What's Next

Phase 2: Update Alpine.js/Liquid templates to use new data structure and display UML navigation.

---

## Your Mission: Phase 2 Task 2.1 - Update Index Template

Update the main SPA template to use the new data structure.

---

## Implementation Steps

### Step 1: Read Current Template

First, examine the current template structure:

```bash
# Read these files
lib/lutaml/klin/templates/alpine/index.html.liquid
lib/lutaml/klin/templates/alpine/css/styles.css
```

### Step 2: Update Data Initialization

**File**: [`lib/lutaml/klin/templates/alpine/index.html.liquid`](lib/lutaml/klin/templates/alpine/index.html.liquid:1)

Find the Alpine.js initialization and update:

```javascript
// OLD (array-based)
Alpine.store('app', {
  data: {{ mappings_json }},
  currentView: 'packages',
  currentPackage: null,
  sidebarVisible: true
});

// NEW (hash-based with class focus)
Alpine.store('app', {
  data: {{ mappings_json }},
  currentView: 'classes',      // NEW: default to class list
  currentPackage: null,
  currentClass: null,           // NEW: track current class
  sidebarVisible: true,
  
  // NEW: Navigation methods
  selectClass(classId) {
    this.currentClass = classId;
    this.currentView = 'class-detail';
  },
  
  selectPackage(packageId) {
    this.currentPackage = packageId;
    this.currentView = 'package-detail';
  }
});
```

### Step 3: Add Utility Functions

Add these helper functions in a `<script>` tag:

```javascript
// Helper to get class by ID
function getClass(classId) {
  return Alpine.store('app').data.classes[classId];
}

// Helper to get attribute by ID  
function getAttribute(attrId) {
  return Alpine.store('app').data.attributes[attrId];
}

// Helper to get package by ID
function getPackage(pkgId) {
  return Alpine.store('app').data.packages[pkgId];
}

// Helper to get classes for a package
function getPackageClasses(pkgId) {
  const pkg = getPackage(pkgId);
  return pkg ? pkg.classes.map(cid => getClass(cid)) : [];
}
```

### Step 4: Test the Update

```bash
# Generate SPA with updated template
bundle exec ruby -Ilib exe/lutaml-klin spa \
  --mapping test_workflow/step1_uro/urbanObject_mapping.yaml \
  --output test_phase2/spa_step1/

# Verify it loads without errors
open test_phase2/spa_step1/index.html

# Check browser console for errors
# Verify data structure is accessible in Alpine.js
```

### Step 5: Verify Data Access

In browser console, test:

```javascript
// Should return object with metadata, packages, classes, attributes
Alpine.store('app').data

// Should return hash of packages
Alpine.store('app').data.packages

// Should return hash of classes
Alpine.store('app').data.classes

// Get first class
Object.values(Alpine.store('app').data.classes)[0]

// Should include xml_instance
Object.values(Alpine.store('app').data.classes)[0].xml_instance
```

---

## Success Criteria for Step 1

Before proceeding:

- [ ] Template uses `data.packages` as hash (not array)
- [ ] Template can access `data.classes` hash
- [ ] Template can access `data.attributes` hash
- [ ] Utility functions work in browser console
- [ ] No JavaScript errors in console
- [ ] SPA loads without visual breaking

---

## After Task 2.1: Move to Task 2.2

Once Task 2.1 is verified working, proceed to Task 2.2: Create Package Tree Component.

See [`CONTINUATION_PLAN_2025-12-02_SPA_PHASE_2-5.md`](CONTINUATION_PLAN_2025-12-02_SPA_PHASE_2-5.md:1) for full details.

---

## Key Files

### To Modify
- [`lib/lutaml/klin/templates/alpine/index.html.liquid`](lib/lutaml/klin/templates/alpine/index.html.liquid:1)

### To Create (in subsequent tasks)
- `lib/lutaml/klin/templates/alpine/components/package_tree.html.liquid`
- `lib/lutaml/klin/templates/alpine/components/class_detail.html.liquid`

### Reference Files
- `/Users/mulgogi/src/lutaml/lutaml/templates/static_site/components/class_details.liquid`
- `/Users/mulgogi/src/lutaml/lutaml/templates/static_site/components/sidebar.liquid`
- `/Users/mulgogi/src/lutaml/lutaml-xsd/lib/lutaml/xsd/spa/templates/components/type_detail.html.liquid`

---

## Testing Commands

```bash
# Generate SPA
bundle exec ruby -Ilib exe/lutaml-klin spa \
  --mapping test_workflow/step1_uro/urbanObject_mapping.yaml \
  --output test_phase2/spa/

# Open in browser
open test_phase2/spa/index.html

# Check RuboCop (if modifying Ruby code)
bundle exec rubocop lib/lutaml/klin/

# Run tests (if tests exist for this)
bundle exec rspec spec/lutaml/klin/
```

---

## Common Issues & Solutions

### Issue: "Cannot read property 'classes' of undefined"

**Cause**: Data structure not properly initialized  
**Solution**: Ensure `{{ mappings_json }}` is rendered correctly

### Issue: "Alpine is not defined"

**Cause**: Alpine.js not loaded before script  
**Solution**: Move Alpine.js initialization after Alpine.js script tag

### Issue: Template renders old structure

**Cause**: Browser cache  
**Solution**: Hard refresh (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)

---

## Documentation References

- **Phase 1 Summary**: See completion message above
- **Full Plan**: [`CONTINUATION_PLAN_2025-12-02_SPA_PHASE_2-5.md`](CONTINUATION_PLAN_2025-12-02_SPA_PHASE_2-5.md:1)
- **Status Tracker**: [`IMPLEMENTATION_STATUS_2025-12-02_SPA_ENHANCEMENT.md`](IMPLEMENTATION_STATUS_2025-12-02_SPA_ENHANCEMENT.md:1)

---

**Prepared**: 2025-12-02 23:30 UTC+8  
**Status**: Ready to implement  
**Estimated Time**: 45 minutes  
**Next Action**: → Modify index.html.liquid to use hash-based data structure