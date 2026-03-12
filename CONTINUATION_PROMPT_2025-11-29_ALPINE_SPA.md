# Continuation Prompt: Alpine.js SPA Implementation

**Session**: Next Implementation Session
**Date**: 2025-11-29+
**Phase**: Phase 1 - Alpine.js Template Creation
**Estimated Duration**: 2-3 hours

---

## Quick Context

You are implementing an Alpine.js-based Single Page Application (SPA) for visualizing UML-to-XSD mappings from YAML files. The planning phase is complete. Now you need to start the implementation.

**Current Files**: `20251010_current_plateau_v5.1.lur` and `urban_function.lxr` are available for testing.

---

## What to Read First

1. **📋 MUST READ**: [`CONTINUATION_PLAN_2025-11-29_ALPINE_SPA.md`](CONTINUATION_PLAN_2025-11-29_ALPINE_SPA.md:1)
   - Complete architectural design
   - Detailed component structure
   - Full HTML/JS/CSS templates

2. **📊 Status Tracker**: [`IMPLEMENTATION_STATUS_2025-11-29_ALPINE_SPA.md`](IMPLEMENTATION_STATUS_2025-11-29_ALPINE_SPA.md:1)
   - Current progress
   - Task breakdown
   - Success criteria

3. **🔍 Reference**: Existing vanilla JS implementation
   - [`lib/lutaml/klin/application/spa_workflow.rb`](lib/lutaml/klin/application/spa_workflow.rb:1)
   - [`lib/lutaml/klin/domain/services/spa_generator.rb`](lib/lutaml/klin/domain/services/spa_generator.rb:1)
   - [`demo/output/_site/index.html`](demo/output/_site/index.html:1)
   - [`demo/output/_site/assets/js/app.js`](demo/output/_site/assets/js/app.js:1)

---

## Your Mission: Phase 1 Start

Create three Alpine.js template files that replicate the vanilla JS SPA functionality with improved maintainability.

### Task 1.1: Create Alpine.js HTML Template (1 hour)

**Create**: `lib/lutaml/klin/templates/spa_alpine/index.html`

**Key Requirements**:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <!-- Alpine.js CDN -->
  <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
  
  <!-- Embedded data with template variables -->
  <script>
    window.MAPPING_DATA = %<MAPPINGS_JSON>s;
    window.SEARCH_INDEX = %<SEARCH_INDEX_JSON>s;
    window.STATISTICS = %<STATISTICS_JSON>s;
  </script>
</head>
<body>
  <div x-data="mappingBrowser" x-cloak>
    <!-- Header with search -->
    <!-- Sidebar with package tree, filters, stats -->
    <!-- Main content with welcome/package/class views -->
  </div>
</body>
</html>
```

**Copy the complete HTML template from the continuation plan** (lines 420-650).

### Task 1.2: Create Alpine.js Component (1 hour)

**Create**: `lib/lutaml/klin/templates/spa_alpine/assets/js/app.js`

**Key Structure**:
```javascript
document.addEventListener('alpine:init', () => {
  Alpine.data('mappingBrowser', () => ({
    // State
    data: null,
    searchIndex: null,
    statistics: null,
    expandedPackages: [],
    activeFilters: { resolved: true, partial: true, unresolved: true },
    currentView: 'welcome',
    currentPackageId: null,
    currentClassId: null,
    searchQuery: '',
    searchResults: [],
    
    // Lifecycle
    init() { this.loadData(); this.setupRouting(); },
    
    // Computed
    get currentPackage() { /* ... */ },
    get currentClass() { /* ... */ },
    get filteredPackages() { /* ... */ },
    
    // Actions
    togglePackage(id) { /* ... */ },
    showPackage(id) { /* ... */ },
    showClass(id) { /* ... */ },
    handleSearch() { /* ... */ },
    
    // Helpers
    getStatusBadge(status) { /* ... */ },
    getStatusClass(status) { /* ... */ }
  }));
});
```

**Copy the complete JS component from the continuation plan** (lines 125-280).

### Task 1.3: Create Enhanced CSS (30 min)

**Create**: `lib/lutaml/klin/templates/spa_alpine/assets/css/style.css`

**Copy CSS from existing vanilla template** and add:
```css
[x-cloak] { display: none !important; }
.type-badge { /* ... */ }
.result-subtitle { /* ... */ }
.error-row { /* ... */ }
.detail-section { /* ... */ }
```

---

## Step-by-Step Instructions

### Step 1: Create Directory Structure
```bash
mkdir -p lib/lutaml/klin/templates/spa_alpine/assets/js
mkdir -p lib/lutaml/klin/templates/spa_alpine/assets/css
```

### Step 2: Create index.html
Use `write_to_file` tool to create the HTML template:
- **Path**: `lib/lutaml/klin/templates/spa_alpine/index.html`
- **Content**: Copy from continuation plan (lines 420-650)
- **Verify**: Contains Alpine.js CDN, template variables, x-data component

### Step 3: Create app.js
Use `write_to_file` tool to create the JavaScript component:
- **Path**: `lib/lutaml/klin/templates/spa_alpine/assets/js/app.js`
- **Content**: Copy from continuation plan (lines 125-280)
- **Verify**: Contains Alpine.data component with all methods

### Step 4: Create style.css
Use `read_file` to get existing CSS, then use `write_to_file`:
- **Path**: `lib/lutaml/klin/templates/spa_alpine/assets/css/style.css`
- **Content**: Existing CSS + Alpine.js specific styles
- **Verify**: Contains [x-cloak] and new classes

### Step 5: Verify Files
```bash
ls -la lib/lutaml/klin/templates/spa_alpine/
# Should show: index.html, assets/
ls -la lib/lutaml/klin/templates/spa_alpine/assets/
# Should show: css/, js/
```

---

## Testing After Phase 1

Once all three files are created, test manually:

1. **Create a test HTML file** by copying index.html and replacing template variables with actual data
2. **Open in browser** with `file://` protocol
3. **Verify**:
   - [ ] Alpine.js loads (no console errors)
   - [ ] Data appears (from window.MAPPING_DATA)
   - [ ] Package tree renders
   - [ ] Search box works
   - [ ] Filters work
   - [ ] Can navigate to package/class views

---

## After Phase 1 Completion

Update status tracker and continue to **Phase 2: Workflow Enhancement**:

1. Update [`IMPLEMENTATION_STATUS_2025-11-29_ALPINE_SPA.md`](IMPLEMENTATION_STATUS_2025-11-29_ALPINE_SPA.md:1)
2. Mark Phase 1 tasks as complete
3. Start Phase 2: Modify [`lib/lutaml/klin/application/spa_workflow.rb`](lib/lutaml/klin/application/spa_workflow.rb:1)

---

## Key Architecture Principles

Remember these throughout implementation:

1. **Object-Oriented**: Use proper classes, separation of concerns
2. **MECE**: Mutually Exclusive, Collectively Exhaustive
3. **Declarative over Imperative**: Alpine.js templates are declarative
4. **Backward Compatible**: Don't break existing vanilla JS template
5. **Open/Closed**: Extensible but closed for modification
6. **Single Responsibility**: Each component has one job

---

## Common Pitfalls to Avoid

❌ **Don't**:
- Don't modify existing vanilla JS templates
- Don't break backward compatibility
- Don't use hardcoded data (use template variables)
- Don't skip error handling
- Don't forget accessibility (ARIA attributes)

✅ **Do**:
- Create new Alpine.js templates in new directory
- Keep existing templates working
- Use template variables (`%<MAPPINGS_JSON>s`, etc.)
- Add proper error handling
- Include ARIA labels for accessibility

---

## Success Criteria for Phase 1

Before moving to Phase 2, verify:

- [x] Three files created in correct locations
- [x] HTML contains Alpine.js CDN link
- [x] HTML uses x-data, x-model, x-show, x-for
- [x] JS component has all required methods
- [x] CSS includes Alpine.js specific styles
- [x] Template variables properly placed
- [x] No syntax errors (validate with linter)
- [x] Can be tested standalone

---

## Estimated Timeline

```
Phase 1 Breakdown:
├─ Task 1.1: HTML Template    → 1 hour
├─ Task 1.2: JS Component     → 1 hour  
├─ Task 1.3: CSS Enhancement  → 30 min
└─ Testing & Verification     → 30 min
                        Total: 3 hours
```

---

## Resources

### Alpine.js Documentation
- **Official Docs**: https://alpinejs.dev/
- **x-data**: Component state
- **x-model**: Two-way binding
- **x-show/x-if**: Conditional rendering
- **x-for**: List rendering
- **@click/@input**: Event handling

### Existing Code to Reference
- Vanilla JS SPA: [`demo/output/_site/`](demo/output/_site/)
- SPA Generator: [`lib/lutaml/klin/domain/services/spa_generator.rb`](lib/lutaml/klin/domain/services/spa_generator.rb:1)
- Workflow: [`lib/lutaml/klin/application/spa_workflow.rb`](lib/lutaml/klin/application/spa_workflow.rb:1)

---

## Quick Start Command

When you start the next session, begin with:

```
Read these files in order:
1. CONTINUATION_PROMPT_2025-11-29_ALPINE_SPA.md (this file)
2. CONTINUATION_PLAN_2025-11-29_ALPINE_SPA.md
3. IMPLEMENTATION_STATUS_2025-11-29_ALPINE_SPA.md

Then create:
1. lib/lutaml/klin/templates/spa_alpine/index.html
2. lib/lutaml/klin/templates/spa_alpine/assets/js/app.js
3. lib/lutaml/klin/templates/spa_alpine/assets/css/style.css
```

---

**Prepared**: 2025-11-29
**Status**: Ready for Implementation
**Next Action**: → Create Alpine.js HTML Template (Task 1.1)