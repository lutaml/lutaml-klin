# Continuation Plan: SPA Enhancement Phases 2-5

**Session**: Next Session  
**Date**: 2025-12-02+  
**Phase**: Phases 2-5 (Template Updates, Logic, Styling, Testing)  
**Priority**: P0 (Critical UX Improvement)  
**Estimated Duration**: 7 hours remaining (Phase 2: 3h, Phase 3: 2h, Phase 4: 1h, Phase 5: 1h)

---

## Context

### Phase 1 Complete ✅

**Completed** (2025-12-02):
- ✅ Enhanced SPA data model from package-centric to UML-centric
- ✅ Created XML instance generator with mapping comments
- ✅ Integrated XML generation into SPA workflow
- ✅ Updated all tests (16/16 passing)
- ✅ RuboCop clean (0 violations)
- ✅ Verified with real PLATEAU data (174 classes, 961 attributes)

**Result**: Data structure now provides:
```json
{
  "metadata": { ... },
  "packages": { "pkg-id": { classes: ["class-id", ...] } },
  "classes": { "class-id": { attributes: [...], xml_instance: "..." } },
  "attributes": { "attr-id": { uml_type, xsd_type, ... } }
}
```

---

## Remaining Phases Overview

| Phase | Tasks | Duration | Status |
|-------|-------|----------|--------|
| Phase 2: Templates | 4 tasks | 3h | ⏸️ Ready |
| Phase 3: Logic | 3 tasks | 2h | ⏸️ Blocked |
| Phase 4: Styling | 2 tasks | 1h | ⏸️ Blocked |
| Phase 5: Testing | 2 tasks | 1h | ⏸️ Blocked |

---

## Phase 2: Template Updates (3 hours)

Update Alpine.js/Liquid templates to use new data structure and display UML navigation.

### Task 2.1: Update Index Template (45 min)

**File**: `lib/lutaml/klin/templates/alpine/index.html.liquid`

**Current State**:
- Uses array-based packages
- Package-centric navigation

**Required Changes**:

1. **Update data initialization**:
```javascript
// OLD
const data = {{ mappings_json }};

// NEW
const data = {{ mappings_json }};
// Now data.packages is a hash, data.classes is a hash, data.attributes is a hash
```

2. **Update Alpine.js data structure**:
```javascript
Alpine.store('app', {
  data: data,
  currentView: 'classes',  // NEW: default to class list
  currentPackage: null,
  currentClass: null,       // NEW
  sidebarVisible: true
});
```

3. **Add utility functions**:
```javascript
// Helper to get class by ID
function getClass(id) {
  return data.classes[id];
}

// Helper to get attribute by ID
function getAttribute(id) {
  return data.attributes[id];
}

// Helper to get package by ID
function getPackage(id) {
  return data.packages[id];
}
```

### Task 2.2: Create Package Tree Component (60 min)

**File**: `lib/lutaml/klin/templates/alpine/components/package_tree.html.liquid` (NEW)

**Purpose**: Hierarchical UML navigation (Package → Classes)

**Implementation**:
```liquid
<div class="package-tree" x-data="packageTree">
  <template x-for="(pkg, pkgId) in data.packages" :key="pkgId">
    <details class="package-node" :open="expandedPackages.includes(pkgId)">
      <summary @click="togglePackage(pkgId)">
        <span class="package-icon">📦</span>
        <span x-text="pkg.name"></span>
        <span class="badge" x-text="pkg.classes.length"></span>
      </summary>
      
      <div class="package-classes">
        <template x-for="classId in pkg.classes" :key="classId">
          <button 
            class="class-item"
            :class="{ 'active': currentClass === classId }"
            @click="selectClass(classId)"
            x-data="{ cls: data.classes[classId] }">
            <span class="class-icon">🏛️</span>
            <span x-text="cls.name"></span>
            <span class="resolution-badge" 
                  :data-status="cls.resolution_status"
                  x-text="cls.resolution_status"></span>
          </button>
        </template>
      </div>
    </details>
  </template>
</div>

<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('packageTree', () => ({
    expandedPackages: [],
    
    togglePackage(pkgId) {
      const index = this.expandedPackages.indexOf(pkgId);
      if (index > -1) {
        this.expandedPackages.splice(index, 1);
      } else {
        this.expandedPackages.push(pkgId);
      }
    },
    
    selectClass(classId) {
      Alpine.store('app').currentClass = classId;
      Alpine.store('app').currentView = 'class-detail';
    }
  }));
});
</script>
```

### Task 2.3: Create Class Detail Component (75 min)

**File**: `lib/lutaml/klin/templates/alpine/components/class_detail.html.liquid` (NEW)

**Purpose**: Show complete class information with UML and XSD mappings

**Sections**:
1. Class header (name, stereotype, package)
2. UML metadata (qualified name, definition)
3. XSD mapping info (element name, type name, namespace)
4. Attributes table with UML→XSD mapping
5. XML instance example
6. Inheritance (when available)

**Implementation** (abbreviated):
```liquid
<div class="class-detail" x-show="currentView === 'class-detail'" x-data="classDetail">
  <div class="class-header">
    <h1 x-text="cls.name"></h1>
    <span class="badge" x-text="cls.stereotype"></span>
  </div>

  <!-- UML Section -->
  <section class="uml-info">
    <h2>UML Information</h2>
    <dl>
      <dt>Qualified Name</dt>
      <dd><code x-text="cls.qualified_name"></code></dd>
      
      <dt>Package</dt>
      <dd>
        <button @click="selectPackage(cls.package_id)" 
                x-text="data.packages[cls.package_id].name"></button>
      </dd>
      
      <dt>Definition</dt>
      <dd x-show="cls.definition" x-text="cls.definition"></dd>
    </dl>
  </section>

  <!-- XSD Mapping Section -->
  <section class="xsd-mapping">
    <h2>XSD Mapping</h2>
    <dl>
      <dt>Element Name</dt>
      <dd><code x-text="cls.xsd_element_name"></code></dd>
      
      <dt>Type Name</dt>
      <dd><code x-text="cls.xsd_type_name"></code></dd>
      
      <dt>Namespace</dt>
      <dd><code x-text="cls.xsd_namespace"></code></dd>
      
      <dt>Resolution</dt>
      <dd>
        <span class="badge" :data-status="cls.resolution_status" 
              x-text="cls.resolution_status"></span>
        <span x-show="cls.resolution_method" 
              x-text="`via ${cls.resolution_method}`"></span>
      </dd>
    </dl>
  </section>

  <!-- Attributes Table -->
  <section class="attributes-section">
    <h2>Attributes (<span x-text="cls.attributes.length"></span>)</h2>
    <table class="attributes-table">
      <thead>
        <tr>
          <th>Name</th>
          <th>UML Type</th>
          <th>XSD Type</th>
          <th>Cardinality</th>
          <th>Resolution</th>
        </tr>
      </thead>
      <tbody>
        <template x-for="attrId in cls.attributes" :key="attrId">
          <tr x-data="{ attr: data.attributes[attrId] }">
            <td><code x-text="attr.name"></code></td>
            <td><code x-text="attr.uml_type"></code></td>
            <td><code x-text="attr.xsd_type"></code></td>
            <td>
              <code x-text="`${attr.xsd_min_occurs}..${attr.xsd_max_occurs}`"></code>
            </td>
            <td>
              <span class="badge" :data-status="attr.resolution_status" 
                    x-text="attr.resolution_status"></span>
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </section>

  <!-- XML Instance Example -->
  <section class="xml-instance">
    <h2>XML Instance Example</h2>
    <pre><code x-text="cls.xml_instance"></code></pre>
  </section>
</div>

<script>
document.addEventListener('alpine:init', () => {
  Alpine.data('classDetail', () => ({
    get cls() {
      const classId = Alpine.store('app').currentClass;
      return this.data.classes[classId] || {};
    }
  }));
});
</script>
```

### Task 2.4: Update Main Template (30 min)

**File**: `lib/lutaml/klin/templates/alpine/index.html.liquid`

**Changes**:
1. Include new components:
```liquid
{% include 'components/package_tree.html' %}
{% include 'components/class_detail.html' %}
```

2. Update layout structure:
```html
<div class="app-container">
  <aside class="sidebar">
    {% include 'components/package_tree.html' %}
  </aside>
  
  <main class="main-content">
    <div class="view-container">
      {% include 'components/class_detail.html' %}
    </div>
  </main>
</div>
```

3. Update navigation logic:
```javascript
Alpine.store('app', {
  // ... existing ...
  
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

---

## Phase 3: Application Logic (2 hours)

### Task 3.1: Implement Navigation Logic (60 min)

**File**: `lib/lutaml/klin/templates/alpine/js/app.js` (NEW or update inline)

**Features**:
1. Class selection and navigation
2. Package filtering
3. Search functionality
4. State management
5. URL routing (optional)

**Implementation**:
```javascript
// Navigation state management
Alpine.store('navigation', {
  history: [],
  
  goToClass(classId) {
    this.history.push({ type: 'class', id: classId });
    Alpine.store('app').selectClass(classId);
  },
  
  goBack() {
    if (this.history.length > 1) {
      this.history.pop();
      const prev = this.history[this.history.length - 1];
      if (prev.type === 'class') {
        Alpine.store('app').selectClass(prev.id);
      }
    }
  }
});

// Search functionality
Alpine.data('search', () => ({
  query: '',
  results: [],
  
  search() {
    if (this.query.length < 2) {
      this.results = [];
      return;
    }
    
    const q = this.query.toLowerCase();
    this.results = Object.values(data.classes).filter(cls => 
      cls.name.toLowerCase().includes(q) ||
      cls.qualified_name.toLowerCase().includes(q)
    );
  }
}));
```

### Task 3.2: Add XML Syntax Highlighting (30 min)

**Dependencies**: Prism.js or highlight.js

**Implementation**:
```javascript
// Add syntax highlighting to XML instances
Alpine.effect(() => {
  const xmlBlocks = document.querySelectorAll('.xml-instance code');
  xmlBlocks.forEach(block => {
    if (window.Prism) {
      Prism.highlightElement(block);
    }
  });
});
```

**Template Update**:
```liquid
<pre><code class="language-xml" x-text="cls.xml_instance"></code></pre>
```

### Task 3.3: Add Responsive Behavior (30 min)

**Features**:
1. Mobile sidebar toggle
2. Responsive table layout
3. Touch-friendly navigation

**Implementation**:
```javascript
Alpine.data('responsive', () => ({
  isMobile: window.innerWidth < 768,
  sidebarOpen: window.innerWidth >= 768,
  
  init() {
    window.addEventListener('resize', () => {
      this.isMobile = window.innerWidth < 768;
      this.sidebarOpen = window.innerWidth >= 768;
    });
  },
  
  toggleSidebar() {
    this.sidebarOpen = !this.sidebarOpen;
  }
}));
```

---

## Phase 4: Styling (1 hour)

### Task 4.1: Update Styles for UML Navigation (45 min)

**File**: `lib/lutaml/klin/templates/alpine/css/styles.css`

**Additions**:
```css
/* Package Tree */
.package-tree {
  padding: 1rem;
}

.package-node {
  margin-bottom: 0.5rem;
}

.package-node summary {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem;
  cursor: pointer;
  border-radius: 4px;
  transition: background 0.2s;
}

.package-node summary:hover {
  background: var(--bg-tertiary);
}

.package-classes {
  margin-left: 1.5rem;
  margin-top: 0.5rem;
}

.class-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem;
  width: 100%;
  text-align: left;
  border: none;
  background: transparent;
  cursor: pointer;
  border-radius: 4px;
  transition: background 0.2s;
}

.class-item:hover {
  background: var(--bg-tertiary);
}

.class-item.active {
  background: var(--color-primary);
  color: white;
}

/* Class Detail */
.class-detail {
  padding: 2rem;
  max-width: 1200px;
}

.class-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid var(--border-medium);
}

.attributes-table {
  width: 100%;
  border-collapse: collapse;
  margin: 1rem 0;
}

.attributes-table th,
.attributes-table td {
  padding: 0.75rem;
  text-align: left;
  border-bottom: 1px solid var(--border-light);
}

.attributes-table th {
  background: var(--bg-tertiary);
  font-weight: 600;
}

/* XML Instance */
.xml-instance {
  margin-top: 2rem;
}

.xml-instance pre {
  background: var(--bg-tertiary);
  padding: 1rem;
  border-radius: 4px;
  overflow-x: auto;
}

.xml-instance code {
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
  line-height: 1.5;
}

/* Resolution badges */
.resolution-badge[data-status="resolved"] {
  background: var(--color-success);
}

.resolution-badge[data-status="partial"] {
  background: var(--color-warning);
}

.resolution-badge[data-status="unresolved"] {
  background: var(--color-error);
}
```

### Task 4.2: Add Responsive Styles (15 min)

**Mobile optimizations**:
```css
@media (max-width: 768px) {
  .app-container {
    flex-direction: column;
  }
  
  .sidebar {
    position: fixed;
    left: -100%;
    transition: left 0.3s;
    z-index: 1000;
  }
  
  .sidebar.open {
    left: 0;
  }
  
  .attributes-table {
    display: block;
    overflow-x: auto;
  }
}
```

---

## Phase 5: Testing & Documentation (1 hour)

### Task 5.1: Integration Testing (45 min)

**Create**: `spec/integration/spa_navigation_spec.rb`

**Test Cases**:
1. **Package tree renders correctly**
   - All packages displayed
   - Classes nested properly
   - Counts accurate

2. **Class selection works**
   - Clicking class loads detail view
   - All class data displayed
   - XML instance rendered

3. **Navigation state**
   - Back button works
   - State persists across views
   - URL updates (if implemented)

4. **Search functionality**
   - Finds classes by name
   - Finds by qualified name
   - Highlights matches

5. **Responsive behavior**
   - Sidebar toggles on mobile
   - Tables scroll on mobile

**Implementation**:
```ruby
RSpec.describe "SPA Navigation", type: :feature do
  let(:mapping_file) { "test_workflow/step1_uro/urbanObject_mapping.yaml" }
  let(:output_dir) { "tmp/spa_test" }
  
  before do
    # Generate SPA
    cmd = "bundle exec ruby -Ilib exe/lutaml-klin spa " \
          "--mapping #{mapping_file} --output #{output_dir}"
    system(cmd)
  end
  
  it "renders package tree with classes" do
    html = File.read("#{output_dir}/index.html")
    expect(html).to include("data.packages")
    expect(html).to include("data.classes")
    expect(html).to include("package-tree")
  end
  
  it "includes class detail component" do
    html = File.read("#{output_dir}/index.html")
    expect(html).to include("class-detail")
    expect(html).to include("xml-instance")
  end
  
  it "includes all required metadata" do
    json = JSON.parse(File.read("#{output_dir}/data/mappings.json"))
    expect(json["metadata"]).to include("version", "generated_at")
    expect(json["packages"]).to be_a(Hash)
    expect(json["classes"]).to be_a(Hash)
    expect(json["attributes"]).to be_a(Hash)
  end
end
```

### Task 5.2: Update Documentation (15 min)

**Update**: `README.adoc` - SPA section

**Add**:
```adoc
=== SPA Features

The generated SPA provides:

* **UML-Focused Navigation**: Browse by package and class hierarchy
* **Complete Class Details**: View UML properties, XSD mappings, and relationships
* **XML Instance Examples**: Sample XML for each class showing UML↔XSD mappings
* **Interactive Search**: Find classes by name or qualified name
* **Responsive Design**: Works on desktop, tablet, and mobile

==== Class Detail View

Each class detail page shows:

* UML metadata (qualified name, stereotype, definition)
* XSD mapping information (element name, type name, namespace)
* Attributes table with UML type → XSD type mappings
* XML instance example with commented mappings
* Resolution status and confidence scores

Example XML instance:

[source,xml]
----
<!-- UML: sectionID : xs:string [0..1] -->
<!-- XSD: sectionID : xs:string -->
<uro:sectionID>Sample sectionID 1</uro:sectionID>
----
```

---

## Success Criteria

### Phase 2 Complete When:
- [ ] Package tree component renders all packages and classes
- [ ] Class detail component displays all sections
- [ ] Templates use new data structure correctly
- [ ] RuboCop clean

### Phase 3 Complete When:
- [ ] Navigation between classes works
- [ ] Search functionality operational
- [ ] XML syntax highlighting active
- [ ] Responsive behavior works on mobile

### Phase 4 Complete When:
- [ ] UML navigation styles applied
- [ ] Class detail page styled
- [ ] Responsive styles work on all devices
- [ ] Consistent with lutaml/lutaml-xsd design

### Phase 5 Complete When:
- [ ] Integration tests pass
- [ ] Documentation updated
- [ ] All manual tests verified
- [ ] No regressions in existing features

---

## Reference Files

**Study These**:
- `/Users/mulgogi/src/lutaml/lutaml/templates/static_site/components/class_details.liquid`
- `/Users/mulgogi/src/lutaml/lutaml/templates/static_site/components/sidebar.liquid`
- `/Users/mulgogi/src/lutaml/lutaml-xsd/lib/lutaml/xsd/spa/templates/components/type_detail.html.liquid`

**Current SPA Templates**:
- `lib/lutaml/klin/templates/alpine/index.html.liquid`
- `lib/lutaml/klin/templates/alpine/css/styles.css`

---

## Testing Commands

```bash
# Generate SPA
bundle exec ruby -Ilib exe/lutaml-klin spa \
  --mapping test_workflow/step1_uro/urbanObject_mapping.yaml \
  --output test_phase2/spa/

# Open in browser
open test_phase2/spa/index.html

# Run integration tests
bundle exec rspec spec/integration/spa_navigation_spec.rb

# Check all tests
bundle exec rspec

# Verify RuboCop
bundle exec rubocop lib/lutaml/klin/
```

---

**Prepared**: 2025-12-02 23:28 UTC+8  
**Status**: Phase 1 Complete → Phase 2 Ready  
**Estimated Remaining**: 7 hours  
**Next Action**: → Start Phase 2 Task 2.1 (Update Index Template)