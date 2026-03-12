# Continuation Plan: SPA Enhancement for UML Navigation & XML Instances

**Date**: 2025-12-02  
**Phase**: SPA Enhancement  
**Priority**: P0 (Critical UX Improvement)  
**Estimated Duration**: 6-8 hours

---

## Context

The current SPA implementation shows mappings but lacks:
1. **UML-focused navigation** (packages → classes) like lutaml
2. **Detailed UML class view** with attributes, types, stereotypes
3. **XML instance examples** showing how UML maps to XML like lutaml-xsd
4. **Proper type resolution** with clickable type links

**Reference Implementations**:
- lutaml: `/Users/mulgogi/src/lutaml/lutaml/templates/static_site/`
- lutaml-xsd: `/Users/mulgogi/src/lutaml/lutaml-xsd/lib/lutaml/xsd/spa/templates/`

---

## Phase 1: Data Model Enhancement (2 hours)

### Task 1.1: Enhance SPA Data Generation

**File**: `lib/lutaml/klin/domain/services/spa_generator.rb`

**Current**: Generates package-centric data
**Target**: Generate UML-centric data with full class details

**Requirements**:
```ruby
{
  packages: {
    "pkg-id": {
      id: "pkg-id",
      name: "uro",
      qualified_name: "ModelRoot::i-UR::uro",
      classes: ["class-1", "class-2", ...]
    }
  },
  classes: {
    "class-1": {
      id: "class-1",
      name: "Building",
      qualified_name: "ModelRoot::i-UR::uro::Building",
      package_id: "pkg-id",
      stereotype: "FeatureType",
      definition: "...",
      
      # UML data
      attributes: ["attr-1", "attr-2", ...],
      generalizations: ["parent-class-id"],
      associations: ["assoc-1", ...],
      
      # XSD mapping data
      xsd_element_name: "Building",
      xsd_type_name: "BuildingType",
      xsd_namespace: "https://...",
      resolution_status: "resolved"
    }
  },
  attributes: {
    "attr-1": {
      id: "attr-1",
      name: "class",
      
      # UML data
      uml_type: "CharacterString",
      uml_multiplicity: "0..1",
      visibility: "public",
      definition: "...",
      
      # XSD mapping data
      xsd_name: "class",
      xsd_type: "gml:CodeType",
      xsd_min_occurs: "0",
      xsd_max_occurs: "1",
      resolution_status: "resolved",
      resolution_method: "shapechange_mapping"
    }
  }
}
```

**Methods to Add**:
- `generate_classes_json(schema_mapping)` - Extract class data
- `generate_attributes_json(schema_mapping)` - Extract attribute data
- `generate_xml_instance(class_data, attributes)` - Generate sample XML

### Task 1.2: XML Instance Generator

**New File**: `lib/lutaml/klin/domain/services/xml_instance_generator.rb`

**Purpose**: Generate sample XML instances showing UML→XSD mapping

**Example Output**:
```xml
<uro:Building gml:id="building-1">
  <!-- UML: class : CharacterString [0..1] -->
  <!-- XSD: class : gml:CodeType -->
  <uro:class codeSpace="...">residential</uro:class>
  
  <!-- UML: function : CharacterString [0..*] -->
  <!-- XSD: function : gml:CodeType -->
  <uro:function>housing</uro:function>
  <uro:function>commercial</uro:function>
</uro:Building>
```

**Methods**:
- `generate_instance(class_mapping, options = {})` - Main method
- `generate_element(attribute_mapping)` - Per-attribute XML
- `add_comments(xml, uml_data, xsd_data)` - Add UML/XSD comments

---

## Phase 2: Template Restructuring (3 hours)

### Task 2.1: Update Alpine.js Template

**File**: `lib/lutaml/klin/templates/spa_alpine/index.html`

**Changes**:
1. Update data structure to use classes-first model
2. Add UML class detail view component
3. Add XML instance display component

**New Components**:
```html
<template x-if="currentView === 'class'">
  <div x-html="classDetailTemplate(data.classes[currentClass])"></div>
</template>
```

### Task 2.2: Create Class Detail Component

**File**: `lib/lutaml/klin/templates/spa_alpine/components/class_detail.html`

**Based on**: `/Users/mulgogi/src/lutaml/lutaml/templates/static_site/components/class_details.liquid`

**Sections**:
1. Class header (name, stereotype, abstract)
2. Metadata (qualified name, package, stereotypes)
3. Definition/description
4. Inheritance (generalizations, specializations)
5. **Attributes table** with UML→XSD mapping
6. **XML Instance Example**
7. Associations
8. Operations (if present)

**Attributes Table Enhancement**:
```html
<table class="attributes-table">
  <thead>
    <tr>
      <th>Name</th>
      <th>UML Type</th>
      <th>XSD Type</th>
      <th>Cardinality (UML)</th>
      <th>Occurs (XSD)</th>
      <th>Status</th>
    </tr>
  </thead>
  <tbody>
    <tr x-for="attrId in cls.attributes">
      <td>
        <code x-text="data.attributes[attrId].name"></code>
        <div class="definition" x-text="data.attributes[attrId].definition"></div>
      </td>
      <td><code x-text="data.attributes[attrId].uml_type"></code></td>
      <td>
        <code x-text="data.attributes[attrId].xsd_type"></code>
        <span class="type-kind">(simple/complex)</span>
      </td>
      <td><code x-text="data.attributes[attrId].uml_multiplicity"></code></td>
      <td><code x-text="`${data.attributes[attrId].xsd_min_occurs}..${data.attributes[attrId].xsd_max_occurs}`"></code></td>
      <td>
        <span class="status-badge" :class="data.attributes[attrId].resolution_status">
          <span x-text="data.attributes[attrId].resolution_status"></span>
        </span>
      </td>
    </tr>
  </tbody>
</table>
```

### Task 2.3: Create XML Instance Component

**File**: `lib/lutaml/klin/templates/spa_alpine/components/xml_instance.html`

**Based on**: `/Users/mulgogi/src/lutaml/lutaml-xsd/lib/lutaml/xsd/spa/templates/components/type_detail.html.liquid`

**Features**:
1. Syntax-highlighted XML
2. Collapsible sections for complex elements
3. UML/XSD mapping annotations in comments
4. Copy-to-clipboard button

**Example**:
```html
<div class="xml-instance-section">
  <h4>Sample XML Instance</h4>
  <div class="xml-controls">
    <button @click="copyXml()">📋 Copy</button>
    <button @click="downloadXml()">⬇️ Download</button>
  </div>
  <pre class="xml-code"><code class="language-xml" x-text="cls.xml_instance"></code></pre>
  <div class="xml-legend">
    <p><strong>Legend:</strong></p>
    <ul>
      <li>Comments show UML attribute → XSD element mapping</li>
      <li>Cardinality: UML [min..max] → XSD minOccurs/maxOccurs</li>
      <li>Type mapping: UML type → XSD type (simple/complex)</li>
    </ul>
  </div>
</div>
```

### Task 2.4: Update Sidebar Navigation

**File**: `lib/lutaml/klin/templates/spa_alpine/components/sidebar.html`

**Based on**: `/Users/mulgogi/src/lutaml/lutaml/templates/static_site/components/sidebar.liquid`

**Structure**:
```html
<div class="sidebar">
  <h2>Packages</h2>
  <div class="package-tree">
    <template x-for="pkgId in Object.keys(data.packages)">
      <div class="package-node">
        <button @click="togglePackage(pkgId)" class="package-toggle">
          <span x-text="expandedPackages.has(pkgId) ? '▼' : '▶'"></span>
          <span x-text="data.packages[pkgId].name"></span>
        </button>
        
        <div x-show="expandedPackages.has(pkgId)" class="class-list">
          <template x-for="classId in data.packages[pkgId].classes">
            <button 
              @click="selectClass(classId)"
              class="class-item"
              :class="{ active: currentClass === classId }">
              <span class="class-icon">C</span>
              <span x-text="data.classes[classId].name"></span>
              <span class="stereotype" x-text="data.classes[classId].stereotype"></span>
            </button>
          </template>
        </div>
      </div>
    </template>
  </div>
</div>
```

---

## Phase 3: Application Logic Enhancement (2 hours)

### Task 3.1: Update App.js State Management

**File**: `lib/lutaml/klin/templates/spa_alpine/assets/js/app.js`

**New State**:
```javascript
{
  // Navigation state
  currentView: 'packages', // or 'class', 'package'
  currentPackage: null,
  currentClass: null,
  expandedPackages: new Set(),
  
  // UI state
  sidebarVisible: true,
  xmlInstanceExpanded: true,
  searchQuery: '',
  
  // Data
  data: {}, // Loaded from embedded/linked data
  
  // Methods
  selectPackage(pkgId) { /* ... */ },
  selectClass(classId) { /* ... */ },
  togglePackage(pkgId) { /* ... */ },
  expandAll() { /* ... */ },
  collapseAll() { /* ... */ },
  getAssociationTarget(assoc, classId) { /* ... */ },
  findClassByName(name) { /* ... */ },
  isUmlBasicType(type) { /* ... */ }
}
```

### Task 3.2: Add XML Utilities

**File**: `lib/lutaml/klin/templates/spa_alpine/assets/js/xml_utils.js`

**Methods**:
```javascript
class XmlUtils {
  static highlightXml(xmlString) { /* Syntax highlight */ }
  static formatXml(xmlString) { /* Pretty print */ }
  static copyToClipboard(text) { /* Copy XML */ }
  static downloadXml(xml, filename) { /* Download as file */ }
}
```

### Task 3.3: Update Search Index

**File**: `lib/lutaml/klin/domain/services/spa_generator.rb`

**Method**: `generate_search_index`

**Enhancement**: Include UML class names, attributes, types in search index

```ruby
{
  index: [
    {
      type: 'class',
      id: 'class-1',
      title: 'Building',
      qualified_name: 'ModelRoot::i-UR::uro::Building',
      package: 'uro',
      stereotype: 'FeatureType',
      keywords: ['building', 'featuretype', 'uro']
    },
    {
      type: 'attribute',
      id: 'attr-1',
      class_id: 'class-1',
      title: 'class',
      uml_type: 'CharacterString',
      xsd_type: 'gml:CodeType',
      keywords: ['class', 'characterstring', 'codetype']
    }
  ]
}
```

---

## Phase 4: Styling & Polish (1 hour)

### Task 4.1: Update CSS

**File**: `lib/lutaml/klin/templates/spa_alpine/assets/css/style.css`

**Add Styles For**:
1. UML class detail layout
2. Attributes table with dual columns (UML/XSD)
3. XML instance code block with syntax highlighting
4. Type badges (resolved, partial, unresolved)
5. Stereotype badges
6. Package tree navigation
7. Collapsible sections

**Reference**: 
- lutaml: Modern, clean UML styling
- lutaml-xsd: Schema documentation styling

### Task 4.2: Add Syntax Highlighting

**Library**: Prism.js or highlight.js (CDN)

**Files to Update**:
- `index.html` - Add CDN link
- `xml_instance.html` - Add language class
- `app.js` - Trigger highlighting after render

---

## Phase 5: Testing & Documentation (1 hour)

### Task 5.1: Manual Testing

**Test Cases**:
1. ✅ Package navigation works
2. ✅ Class selection updates URL hash
3. ✅ Attributes show UML and XSD data
4. ✅ XML instance displays correctly
5. ✅ Type links navigate to other classes
6. ✅ Search finds classes and attributes
7. ✅ Mobile responsive
8. ✅ Copy/download XML works

### Task 5.2: Update Documentation

**Files**:
- `docs/SPA_GENERATOR.md` - Add UML navigation section
- `docs/THREE_PROCESS_WORKFLOW.md` - Update SPA examples
- `README.adoc` - Update SPA features list

---

## Implementation Order

### Session 1: Data Model (2 hours)
1. Enhance `spa_generator.rb` with classes/attributes JSON
2. Create `xml_instance_generator.rb`
3. Test data generation with URO package

### Session 2: Templates (3 hours)
4. Create `class_detail.html` component
5. Create `xml_instance.html` component  
6. Update `sidebar.html` for UML navigation
7. Update `index.html` main template

### Session 3: Logic & Styling (2 hours)
8. Update `app.js` state management
9. Create `xml_utils.js`
10. Update `style.css` with new styles
11. Add syntax highlighting

### Session 4: Testing & Polish (1 hour)
12. Manual testing of all features
13. Fix bugs and polish UX
14. Update documentation

---

## Success Criteria

✅ **UML Navigation**:
- Sidebar shows package tree
- Can expand/collapse packages
- Shows classes under each package
- Click class → shows class detail

✅ **Class Detail Page**:
- Shows UML class information (name, stereotype, definition)
- Shows inheritance and associations
- **Attributes table** with UML and XSD columns
- Shows resolution status per attribute

✅ **XML Instance**:
- Displays sample XML for the class
- Shows UML→XSD mapping in comments
- Syntax highlighted and formatted
- Can copy/download XML

✅ **Type Resolution**:
- Type links navigate to referenced classes
- UML basic types identified
- Unresolved types marked clearly

✅ **Search & Navigation**:
- Search works for classes and attributes
- Hash-based routing for deep linking
- Breadcrumb navigation
- Responsive on mobile

---

## File Changes Summary

### New Files (4)
1. `lib/lutaml/klin/domain/services/xml_instance_generator.rb`
2. `lib/lutaml/klin/templates/spa_alpine/components/class_detail.html`
3. `lib/lutaml/klin/templates/spa_alpine/components/xml_instance.html`
4. `lib/lutaml/klin/templates/spa_alpine/assets/js/xml_utils.js`

### Modified Files (7)
1. `lib/lutaml/klin/domain/services/spa_generator.rb` - Enhanced data generation
2. `lib/lutaml/klin/templates/spa_alpine/index.html` - Updated structure
3. `lib/lutaml/klin/templates/spa_alpine/components/sidebar.html` - UML navigation
4. `lib/lutaml/klin/templates/spa_alpine/assets/js/app.js` - State management
5. `lib/lutaml/klin/templates/spa_alpine/assets/css/style.css` - New styles
6. `docs/SPA_GENERATOR.md` - Documentation
7. `README.adoc` - Feature list

---

## Risks & Mitigation

**Risk 1**: Data model too large for embedded mode
- **Mitigation**: Add data mode parameter, support linked JSON files

**Risk 2**: XML generation complex for nested structures
- **Mitigation**: Start with simple attributes, add nesting iteratively

**Risk 3**: Breaking existing SPA functionality
- **Mitigation**: Create new template variant first, test thoroughly

---

## Dependencies

- Alpine.js (already included)
- Prism.js or Highlight.js (for XML syntax highlighting)
- No new Ruby gems required

---

## Notes

- Follow lutaml's UML navigation pattern closely
- Adopt lutaml-xsd's XML instance display style
- Maintain current template selection (Alpine/Vanilla)
- Ensure backward compatibility with existing SPAs

---

**Prepared**: 2025-12-02 23:15 UTC+8  
**Status**: Ready for implementation  
**Next Session**: Start with Phase 1 - Data Model Enhancement