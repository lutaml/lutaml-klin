
# Enhanced HTML SPA Architecture Plan for XSD Schema Documentation

**Version:** 1.0
**Date:** 2025-10-31
**Status:** Architectural Design

## Executive Summary

This document defines a comprehensive architecture for an Enhanced HTML Single Page Application (SPA) generator that produces interactive, navigable documentation websites from XSD schemas. The SPA integrates with lutaml-xsd's LXR packages and lutaml-klin's YAML mappings to provide a unified documentation solution for both PLATEAU urban planning schemas and general XSD schema repositories.

### Key Design Decisions

Based on requirements clarification:

1. **Dual Use Case Support**: Equal weight to PLATEAU and general XSD documentation with bidirectional mapping
2. **Pre-Computed Cross-References**: All element-to-type, inheritance, and dependency relationships computed at generation time
3. **Merged Data Sources**: Combines LXR package metadata with YAML mapping traceability
4. **Basic Text Search**: Efficient client-side search across element/type names

### Architecture Goals

- **Hierarchical Three-Tier Navigation**: Schema → Component Category → Individual Items
- **Dynamic Content Loading**: Embedded JSON with client-side rendering
- **Dual Deployment Modes**: Single embedded HTML OR multi-file site structure
- **Responsive Design**: Desktop documentation + mobile reference
- **SEO-Friendly**: Proper URL routing and breadcrumbs

---

## 1. System Architecture

### 1.1 High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Input Sources                              │
├─────────────────────────────────────────────────────────────┤
│  LXR Package        YAML Mappings        UML Repository      │
│  (lutaml-xsd)       (lutaml-klin)        (Optional)          │
│      │                   │                    │              │
│      └───────────────────┼────────────────────┘              │
│                          ▼                                    │
├─────────────────────────────────────────────────────────────┤
│              Data Extraction & Merging Layer                 │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐    │
│  │  LXR Reader  │  │ YAML Parser   │  │ Cross-Ref    │    │
│  │              │  │               │  │ Generator    │    │
│  └──────┬───────┘  └──────┬────────┘  └──────┬───────┘    │
│         └──────────────────┼───────────────────┘            │
│                            ▼                                 │
│              ┌─────────────────────────┐                    │
│              │   Unified Schema Model  │                    │
│              │   (Internal JSON)       │                    │
│              └────────────┬────────────┘                    │
├─────────────────────────────────────────────────────────────┤
│                 SPA Generation Layer                         │
│  ┌──────────────┐  ┌───────────────┐  ┌──────────────┐    │
│  │  Template    │  │  JSON         │  │  Asset       │    │
│  │  Generator   │  │  Optimizer    │  │  Builder     │    │
│  └──────┬───────┘  └──────┬────────┘  └──────┬───────┘    │
│         └──────────────────┼───────────────────┘            │
│                            ▼                                 │
├─────────────────────────────────────────────────────────────┤
│                    Output Modes                              │
│  ┌────────────────────┐         ┌──────────────────────┐   │
│  │  Embedded Mode     │         │   Multi-File Mode    │   │
│  │  - Single HTML     │         │   - index.html       │   │
│  │  - Inlined CSS/JS  │         │   - data/*.json      │   │
│  │  - Embedded JSON   │         │   - assets/css/*     │   │
│  │                    │         │   - assets/js/*      │   │
│  └────────────────────┘         └──────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Core Components

#### 1.2.1 SPA Generator (Ruby)

**File**: `lib/lutaml/klin/spa/generator.rb`

**Responsibility**: Orchestrate SPA generation from LXR + YAML sources

**Class Structure**:
```ruby
module Lutaml::Klin::Spa
  class Generator
    # Primary interface
    def generate(lxr_path, yaml_path = nil, options = {})
      # 1. Load and merge data sources
      # 2. Build cross-reference index
      # 3. Generate navigation structure
      # 4. Render templates
      # 5. Output SPA (embedded or multi-file)
    end
  end
end
```

#### 1.2.2 Data Model (Ruby)

**File**: `lib/lutaml/klin/spa/models/unified_schema.rb`

**Unified Schema Model** that merges LXR and YAML data:

```ruby
module Lutaml::Klin::Spa::Models
  class UnifiedSchema < Lutaml::Model::Serializable
    attribute :metadata, SchemaMetadata
    attribute :namespaces, Namespace, collection: true
    attribute :elements, Element, collection: true
    attribute :complex_types, ComplexType, collection: true
    attribute :simple_types, SimpleType, collection: true
    attribute :cross_references, CrossReferenceIndex
    attribute :search_index, SearchIndex
  end

  class SchemaMetadata
    attribute :name, :string
    attribute :version, :string
    attribute :description, :string
    attribute :source_lxr, :string
    attribute :source_yaml, :string
    attribute :generated_at, :string
    attribute :traceability, Traceability # From YAML
  end

  class CrossReferenceIndex
    attribute :element_to_type, :hash      # element_name => type_name
    attribute :type_hierarchy, :hash       # type_name => [parent_types]
    attribute :type_dependencies, :hash    # type_name => [dependent_types]
    attribute :attribute_references, :hash # attr_name => [using_types]
  end
end
```

#### 1.2.3 Template Engine (ERB)

**Files**: `lib/lutaml/klin/spa/templates/`

- `index.html.erb` - Main HTML structure
- `navigation.html.erb` - Three-tier navigation component
- `content.html.erb` - Content display templates
- `embedded.html.erb` - Single-file embedded template
- `multi_file.html.erb` - Multi-file index template

---

## 2. Three-Tier Navigation Architecture

### 2.1 Navigation Hierarchy

```
Tier 1: Schema Level
├── PLATEAU Schemas
│   ├── URF (Urban Function)
│   ├── URO (Urban Object)
│   └── CityGML 2.0
├── ISO/TC 211 Schemas
│   ├── ISO 19115 (Metadata)
│   ├── ISO 19139 (XML)
│   └── ISO 19136 (GML)
└── Custom Schemas
    └── [User-defined]

Tier 2: Component Category (per schema)
├── Elements
├── Complex Types
├── Simple Types
├── Attributes
├── Attribute Groups
└── Groups

Tier 3: Individual Items (per category)
├── [Alphabetical list]
├── [Namespace-grouped list]
└── [Filtered/Searched results]
```

### 2.2 Navigation State Management

```javascript
// navigation-state.js
class NavigationState {
  constructor() {
    this.currentSchema = null;     // Tier 1
    this.currentCategory = null;   // Tier 2
    this.currentItem = null;       // Tier 3
    this.breadcrumbs = [];
    this.history = [];
  }

  // Navigate to schema
  selectSchema(schemaId) {
    this.currentSchema = schemaId;
    this.currentCategory = null;
    this.currentItem = null;
    this.updateBreadcrumbs();
    this.render();
  }

  // Navigate to category within schema
  selectCategory(categoryId) {
    this.currentCategory = categoryId;
    this.currentItem = null;
    this.updateBreadcrumbs();
    this.render();
  }

  // Navigate to specific item
  selectItem(itemId) {
    this.currentItem = itemId;
    this.updateBreadcrumbs();
    this.render();
  }

  // Cross-reference navigation
  navigateToReference(referenceId) {
    // Resolve reference to schema/category/item
    // Update all three tiers accordingly
    this.selectItem(referenceId);
  }
}
```

### 2.3 Sidebar Navigation Component

```html
<!-- Navigation Structure -->
<nav id="schema-navigation" class="sidebar">
  <!-- Tier 1: Schema Selector -->
  <div class="nav-tier nav-tier-1">
    <h3>Schemas</h3>
    <select id="schema-selector" class="schema-select">
      <option value="plateau-urf">PLATEAU URF</option>
      <option value="plateau-uro">PLATEAU URO</option>
      <option value="citygml-2.0">CityGML 2.0</option>
    </select>
  </div>

  <!-- Tier 2: Category Navigation -->
  <div class="nav-tier nav-tier-2">
    <h4>Components</h4>
    <ul class="category-list">
      <li class="category-item" data-category="elements">
        <i class="icon-element"></i> Elements
        <span class="count">127</span>
      </li>
      <li class="category-item" data-category="complex-types">
        <i class="icon-type"></i> Complex Types
        <span class="count">203</span>
      </li>
      <li class="category-item" data-category="simple-types">
        <i class="icon-simple"></i> Simple Types
        <span class="count">45</span>
      </li>
      <li class="category-item" data-category="attributes">
        <i class="icon-attr"></i> Attributes
        <span class="count">89</span>
      </li>
    </ul>
  </div>

  <!-- Tier 3: Item List -->
  <div class="nav-tier nav-tier-3">
    <div class="search-box">
      <input type="text" id="item-search" placeholder="Search items...">
    </div>
    <ul class="item-list">
      <!-- Dynamically populated -->
    </ul>
  </div>
</nav>
```

---

## 3. Data Structure & JSON Schema

### 3.1 Embedded JSON Structure

The SPA embeds a comprehensive JSON data structure containing all schema information and pre-computed cross-references.

```json
{
  "metadata": {
    "name": "PLATEAU Schema Documentation",
    "version": "3.2",
    "description": "i-UR Urban Planning schemas with dependencies",
    "source_lxr": "packages/plateau_schemas.lxr",
    "source_yaml": "mappings/plateau_uro_mapping.yaml",
    "generated_at": "2025-10-31T16:00:00+09:00",
    "generator_version": "lutaml-klin 1.0.0",
    "traceability": {
      "resolution_strategies": ["TypeOverrideStrategy", "SchemaRepositoryStrategy"],
      "lxr_package_info": {
        "name": "PLATEAU Schema Repository",
        "version": "3.2",
        "total_types": 2764,
        "namespaces": 34
      }
    }
  },

  "schemas": [
    {
      "id": "plateau-urf",
      "name": "PLATEAU Urban Function (URF)",
      "namespace": "https://www.geospatial.jp/iur/urf/3.2",
      "prefix": "urf",
      "description": "Urban planning and zoning regulations",
      "version": "3.2",
      "components": {
        "elements": 127,
        "complex_types": 203,
        "simple_types": 45,
        "attributes": 89
      }
    }
  ],

  "elements": {
    "urf:UrbanPlanningArea": {
      "id": "urf:UrbanPlanningArea",
      "name": "UrbanPlanningArea",
      "namespace": "https://www.geospatial.jp/iur/urf/3.2",
      "prefix": "urf",
      "schema_id": "plateau-urf",
      "type": "urf:UrbanPlanningAreaType",
      "substitution_group": "gml:AbstractFeature",
      "abstract": false,
      "documentation": "Represents an urban planning area designation",
      "category": "elements",

      "cross_references": {
        "type_ref": "urf:UrbanPlanningAreaType",
        "substitution_group_ref": "gml:AbstractFeature",
        "used_by": [],
        "related_elements": ["urf:Zoning", "urf:District"]
      }
    }
  },

  "complex_types": {
    "urf:UrbanPlanningAreaType": {
      "id": "urf:UrbanPlanningAreaType",
      "name": "UrbanPlanningAreaType",
      "namespace": "https://www.geospatial.jp/iur/urf/3.2",
      "prefix": "urf",
      "schema_id": "plateau-urf",
      "base_type": "gml:AbstractFeatureType",
      "abstract
": false,
      "documentation": "Complex type for urban planning areas with geometry and attributes",
      "category": "complex_types",

      "structure": {
        "content_type": "complex_content",
        "base": "gml:AbstractFeatureType",
        "elements": [
          {
            "name": "areaClassificationType",
            "type": "gml:CodeType",
            "min_occurs": 0,
            "max_occurs": 1
          },
          {
            "name": "geometry",
            "type": "gml:GeometryPropertyType",
            "min_occurs": 1,
            "max_occurs": 1
          }
        ],
        "attributes": [
          {
            "name": "id",
            "type": "xs:ID",
            "use": "required"
          }
        ]
      },

      "cross_references": {
        "base_type_ref": "gml:AbstractFeatureType",
        "used_by_elements": ["urf:UrbanPlanningArea"],
        "uses_types": ["gml:CodeType", "gml:GeometryPropertyType"],
        "child_types": [],
        "related_types": ["urf:ZoningType", "urf:DistrictType"]
      },

      "uml_mapping": {
        "uml_class": "UrbanPlanningArea",
        "uml_package": "Conceptual Models::i-UR::Urban Planning ADE 3.2::urf",
        "stereotype": "featureType",
        "resolution_strategy": "SchemaRepositoryStrategy"
      }
    }
  },

  "cross_reference_index": {
    "element_to_type": {
      "urf:UrbanPlanningArea": "urf:UrbanPlanningAreaType",
      "gml:name": "gml:CodeType"
    },

    "type_hierarchy": {
      "urf:UrbanPlanningAreaType": {
        "parents": ["gml:AbstractFeatureType", "gml:AbstractGMLType"],
        "children": [],
        "depth": 2
      }
    },

    "type_dependencies": {
      "urf:UrbanPlanningAreaType": {
        "requires": ["gml:CodeType", "gml:GeometryPropertyType", "xs:ID"],
        "required_by": []
      }
    },

    "namespace_index": {
      "https://www.geospatial.jp/iur/urf/3.2": {
        "prefix": "urf",
        "elements": ["UrbanPlanningArea", "Zoning", "District"],
        "types": ["UrbanPlanningAreaType", "ZoningType", "DistrictType"]
      }
    }
  },

  "search_index": {
    "terms": {
      "urbanplanningarea": ["urf:UrbanPlanningArea", "urf:UrbanPlanningAreaType"],
      "urban": ["urf:UrbanPlanningArea", "urf:UrbanFunction", "uro:UrbanObject"],
      "planning": ["urf:UrbanPlanningArea", "urf:PlanningDistrict"],
      "codetype": ["gml:CodeType"],
      "feature": ["gml:AbstractFeature", "urf:UrbanPlanningArea"]
    },

    "by_namespace": {
      "urf": ["UrbanPlanningArea", "Zoning", "District"],
      "gml": ["AbstractFeature", "CodeType", "GeometryPropertyType"]
    }
  }
}
```

---

## 4. Component Architecture (Ruby)

### 4.1 Module Structure

```
lib/lutaml/klin/spa/
├── generator.rb                   # Main SPA generator
├── data_loader.rb                 # Load and merge data sources
├── cross_reference_builder.rb     # Build cross-reference index
├── search_index_builder.rb        # Build search index
├── template_renderer.rb           # ERB template rendering
├── asset_bundler.rb               # Bundle CSS/JS assets
├── output_writer.rb               # Write SPA output
│
├── models/
│   ├── unified_schema.rb          # Merged schema model
│   ├── schema_metadata.rb         # Metadata model
│   ├── element.rb                 # Element model
│   ├── complex_type.rb            # Complex type model
│   ├── simple_type.rb             # Simple type model
│   ├── cross_reference_index.rb   # Cross-ref model
│   └── search_index.rb            # Search index model
│
├── templates/
│   ├── embedded.html.erb          # Single-file template
│   ├── multi_file/
│   │   ├── index.html.erb         # Multi-file index
│   │   ├── schema.html.erb        # Schema page template
│   │   └── component.html.erb     # Component detail template
│   └── partials/
│       ├── _navigation.html.erb   # Navigation component
│       ├── _breadcrumbs.html.erb  # Breadcrumb component
│       ├── _search.html.erb       # Search component
│       └── _detail.html.erb       # Detail view component
│
└── assets/
    ├── css/
    │   ├── main.css               # Main stylesheet
    │   ├── navigation.css         # Navigation styles
    │   ├── content.css            # Content styles
    │   └── responsive.css         # Mobile styles
    └── js/
        ├── app.js                 # Main application
        ├── navigation.js          # Navigation controller
        ├── search.js              # Search functionality
        ├── renderer.js            # Content renderer
        └── utils.js               # Utility functions
```

### 4.2 Generator Class Architecture

```ruby
module Lutaml
  module Klin
    module Spa
      class Generator
        attr_reader :options, :data_loader, :cross_ref_builder,
                    :search_builder, :template_renderer, :asset_bundler

        def initialize(options = {})
          @options = normalize_options(options)

          # Dependency injection
          @data_loader = DataLoader.new
          @cross_ref_builder = CrossReferenceBuilder.new
          @search_builder = SearchIndexBuilder.new
          @template_renderer = TemplateRenderer.new
          @asset_bundler = AssetBundler.new
          @output_writer = OutputWriter.new
        end

        def generate(lxr_path, yaml_path = nil, output_dir = nil)
          # 1. Load data sources
          lxr_data = @data_loader.load_lxr(lxr_path)
          yaml_data = yaml_path ? @data_loader.load_yaml(yaml_path) : nil

          # 2. Merge data sources
          unified_schema = @data_loader.merge(lxr_data, yaml_data)

          # 3. Build cross-reference index
          cross_refs = @cross_ref_builder.build(unified_schema)
          unified_schema.cross_references = cross_refs

          # 4. Build search index
          search_index = @search_builder.build(unified_schema)
          unified_schema.search_index = search_index

          # 5. Generate navigation structure
          navigation = build_navigation(unified_schema)

          # 6. Render templates based on mode
          if @options[:mode] == :embedded
            render_embedded(unified_schema, navigation, output_dir)
          else
            render_multi_file(unified_schema, navigation, output_dir)
          end
        end

        private

        def build_navigation(schema)
          NavigationBuilder.new.build(schema)
        end

        def render_embedded(schema, navigation, output_dir)
          # Single HTML file with inlined assets and JSON
          html = @template_renderer.render_template(
            'embedded.html.erb',
            schema: schema,
            navigation: navigation,
            css: @asset_bundler.inline_css,
            js: @asset_bundler.inline_js,
            data: schema.to_json
          )

          @output_writer.write_file(
            File.join(output_dir, 'index.html'),
            html
          )
        end

        def render_multi_file(schema, navigation, output_dir)
          # Multiple files with external assets
          # index.html + data/*.json + assets/css/* + assets/js/*

          # Write index
          html = @template_renderer.render_template(
            'multi_file/index.html.erb',
            navigation: navigation,
            metadata: schema.metadata
          )
          @output_writer.write_file(
            File.join(output_dir, 'index.html'),
            html
          )

          # Write data files
          @output_writer.write_json(
            File.join(output_dir, 'data/schema.json'),
            schema
          )
          @output_writer.write_json(
            File.join(output_dir, 'data/cross_refs.json'),
            schema.cross_references
          )
          @output_writer.write_json(
            File.join(output_dir, 'data/search_index.json'),
            schema.search_index
          )

          # Write assets
          @asset_bundler.copy_assets(output_dir)
        end
      end
    end
  end
end
```

### 4.3 Data Loader Architecture

```ruby
module Lutaml::Klin::Spa
  class DataLoader
    def load_lxr(lxr_path)
      # Load LXR package via lutaml-xsd
      repo = Lutaml::Xsd::SchemaRepository.from_package(lxr_path)

      # Extract comprehensive schema data
      {
        metadata: extract_lxr_metadata(repo),
        elements: extract_elements(repo),
        complex_types: extract_complex_types(repo),
        simple_types: extract_simple_types(repo),
        namespaces: extract_namespaces(repo),
        statistics: repo.statistics
      }
    end

    def load_yaml(yaml_path)
      # Load YAML mapping file
      content = YAML.load_file(yaml_path)

      # Extract traceability and UML mapping info
      {
        traceability: content.dig('schema_mapping', 'traceability'),
        source: content.dig('schema_mapping', 'source'),
        mappings: extract_uml_mappings(content['mapping'])
      }
    end

    def merge(lxr_data, yaml_data)
      # Create unified schema model
      schema = Models::UnifiedSchema.new

      # Merge metadata
      schema.metadata = merge_metadata(lxr_data[:metadata], yaml_data)

      # Enrich XSD data with UML mapping information
      schema.elements = enrich_with_mappings(
        lxr_data[:elements],
        yaml_data&.dig(:mappings)
      )

      schema.complex_types = enrich_with_mappings(
        lxr_data[:complex_types],
        yaml_data&.dig(:mappings)
      )

      # Copy namespaces and statistics
      schema.namespaces = lxr_data[:namespaces]
      schema.statistics = lxr_data[:statistics]

      schema
    end

    private

    def enrich_with_mappings(xsd_items, uml_mappings)
      return xsd_items unless uml_mappings

      xsd_items.map do |item|
        # Find corresponding UML mapping
        mapping = find_mapping(item, uml_mappings)

        if mapping
          item.uml_mapping = {
            uml_class: mapping[:class_name],
            uml_package: mapping[:package_path],
            stereotype: mapping[:stereotype],
            resolution_strategy: mapping[:resolution_strategy]
          }
        end

        item
      end
    end
  end
end
```

### 4.4 Cross-Reference Builder

```ruby
module Lutaml::Klin::Spa
  class CrossReferenceBuilder
    def build(unified_schema)
      index = Models::CrossReferenceIndex.new

      # Build element-to-type mappings
      index.element_to_type = build_element_type_map(unified_schema.elements)

      # Build type hierarchy
      index.type_hierarchy = build_type_hierarchy(
        unified_schema.complex_types,
        unified_schema.simple_types
      )

      # Build type dependency graph
      index.type_dependencies = build_dependency_graph(unified_schema)

      # Build attribute reference index
      index.attribute_references = build_attribute_index(unified_schema)

      # Build namespace index
      index.namespace_index = build_namespace_index(unified_schema)

      index
    end

    private

    def build_element_type_map(elements)
      elements.each_with_object({}) do |elem, hash|
        hash[elem.qualified_name] = elem.type if elem.type
      end
    end

    def build_type_hierarchy(complex_types, simple_types)
      all_types = complex_types + simple_types

      all_types.each_with_object({}) do |type, hash|
        hash[type.qualified_name] = {
          parents: find_parent_types(type, all_types),
          children: find_child_types(type, all_types),
          depth: calculate_inheritance_depth(type, all_types)
        }
      end
    end

    def build_dependency_graph(schema)
      schema.complex_types.each_with_object({}) do |type, hash|
        hash[type.qualified_name] = {
          requires: extract_required_types(type),
          required_by: find_types_requiring(type, schema)
        }
      end
    end
  end
end
```

---

## 5. Frontend Architecture (JavaScript)

### 5.1 Application Structure

```javascript
// assets/js/app.js - Main application
class SchemaDocApp {
  constructor(dataSource) {
    // Load data based on mode
    this.dataSource = dataSource; // 'embedded' or 'external'
    this.schema = null;
    this.navigation = null;
    this.search = null;
    this.renderer = null;
    this.router = null;

    this.init();
  }

  async init() {
    // Load schema data
    this.schema = await this.loadSchema();

    // Initialize components
    this.navigation = new NavigationController(this.schema);
    this.search = new SearchController(this.schema.search_index);
    this.renderer = new ContentRenderer(this.schema);
    this.router = new Router(this);

    // Setup event listeners
    this.setupEventListeners();

    // Initial render
    this.router.handleInitialRoute();
  }

  async loadSchema() {
    if (this.dataSource === 'embedded') {
      // Access embedded JSON from script tag
      return JSON.parse(
        document.getElementById('schema-data').textContent
      );
    } else {
      // Fetch from external JSON files
      const [schema, crossRefs, searchIndex] = await Promise.all([
        fetch('data/schema.json').then(r => r.json()),
        fetch('data/cross_refs.json').then(r => r.json()),
        fetch('data/search_index.json').then(r => r.json())
      ]);

      schema.cross_references = crossRefs;
      schema.search_index = searchIndex;
      return schema;
    }
  }
}

// Initialize on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  // Detect mode from page structure
  const mode = document.getElementById('schema-data') ? 'embedded' : 'external';
  window.app = new SchemaDocApp(mode);
});
```

### 5.2 Navigation Controller

```javascript
// assets/js/navigation.js
class NavigationController {
  constructor(schema) {
    this.schema = schema;
    this.state = {
      currentSchema: null,     // Tier 1
      currentCategory: null,   // Tier 2
      currentItem: null,       // Tier 3
      breadcrumbs: [],
      history: []
    };

    this.initNavigation();
  }

  initNavigation() {
    // Populate tier 1 (schemas)
    this.renderSchemaSelector();

    // Setup tier 2 event listeners
    this.setupCategoryListeners();

    // Setup tier 3 item list
    this.setupItemListeners();
  }

  renderSchemaSelector() {
    const selector = document.getElementById('schema-selector');
    this.schema.schemas.forEach(s => {
      const option = document.createElement('option');
      option.value = s.id;
      option.textContent = s.name;
      selector.appendChild(option);
    });

    selector.addEventListener('change', (e) => {
      this.selectSchema(e.target.value);
    });
  }

  selectSchema(schemaId) {
    this.state.currentSchema = schemaId;
    this.state.currentCategory = null;
    this.state.currentItem = null;

    this.renderCategories(schemaId);
    this.updateBreadcrumbs();
    this.updateURL();
  }

  renderCategories(schemaId) {
    const schema = this.schema.schemas.find(s => s.id === schemaId);
    const categoryList = document.querySelector('.category-list');

    categoryList.innerHTML = '';

    const categories = [
      { id: 'elements', name: 'Elements', icon: 'icon-element', count: schema.components.elements },
      { id: 'complex-types', name: 'Complex Types', icon: 'icon-type', count: schema.components.complex_types },
      { id: 'simple-types', name: 'Simple Types', icon: 'icon-simple', count: schema.components.simple_types },
      { id: 'attributes', name: 'Attributes', icon: 'icon-attr', count: schema.components.attributes }
    ];

    categories.forEach(cat => {
      const li = this.createCategoryItem(cat);
      categoryList.appendChild(li);
    });
  }

  selectCategory(categoryId) {
    this.state.currentCategory = categoryId;
    this.state.currentItem = null;

    this.renderItemList(categoryId);
    this.updateBreadcrumbs();
    this.updateURL();
  }

  renderItemList(categoryId) {
    const schemaId = this.state.currentSchema;
    const items = this.getItemsForCategory(schemaId, categoryId);
    const itemList = document.querySelector('.item-list');

    itemList.innerHTML = '';

    items.forEach(item => {
      const li = document.createElement('li');
      li.className = 'item-list-entry';
      li.dataset.itemId = item.id;
      li.innerHTML = `
        <span class="item-name">${item.name}</span>
        <span class="item-namespace">${item.prefix}</span>
      `;
      li.addEventListener('click', () => this.selectItem(item.id));
      itemList.appendChild(li);
    });
  }

  selectItem(itemId) {
    this.state.currentItem = itemId;

    // Render item details
    window.app.renderer.renderItem(itemId);

    this.updateBreadcrumbs();
    this.updateURL();
  }

  // Cross-reference navigation
  navigateToReference(referenceId) {
    // Parse reference ID (format: "<namespace>:<name>" or "{uri}name")
    const item = this.resolveReference(referenceId);

    if (item) {
      // Update all three tiers
      this.state.currentSchema = item.schema_id;
      this.state.currentCategory = item.category;
      this.state.currentItem = item.id;

      // Re-render navigation
      this.renderSchemaSelector();
      this.renderCategories(item.schema_id);
      this.renderItemList(item.category);

      // Scroll to item
      this.scrollToItem(item.id);

      this.updateBreadcrumbs();
      this.updateURL();
    }
  }

  updateBreadcrumbs() {
    const breadcrumbs = [];

    if (this.state.currentSchema) {
      const schema = this.schema.schemas.find(s => s.id === this.state.currentSchema);
      breadcrumbs.push({ text: schema.name, link: `#/${schema.id}` });
    }

    if (this.state.currentCategory) {
      breadcrumbs.push({
        text: this.getCategoryName(this.state.currentCategory),
        link: `#/${this.state.currentSchema}/${this.state.currentCategory}`
      });
    }

    if (this.state.currentItem) {
      const item = this.getItem(this.state.currentItem);
      breadcrumbs.push({
        text: item.name,
        link: `#/${this.state.currentSchema}/${this.state.currentCategory}/${item.id}`
      });
    }

    this.renderBreadcrumbs(breadcrumbs);
  }
}
```

### 5.3 Search Controller

```javascript
// assets/js/search.js
class SearchController {
  constructor(searchIndex) {
    this.index = searchIndex;
    this.searchBox = document.getElementById('item-search');
    this.resultsContainer = document.querySelector('.item-list');

    this.setupSearch();
  }

  setupSearch() {
    this.searchBox.addEventListener('input', (e) => {
      this.performSearch(e.target.value);
    });
  }

  performSearch(query) {
    if (!query || query.length < 2) {
      this.clearSearch();
      return;
    }

    const results = this.search(query.toLowerCase());
    this.renderResults(results);
  }

  search(query) {
    const results = [];

    // Search in index terms
    for (const [term, itemIds] of Ob
ject.entries(this.index.terms)) {
      if (term.includes(query)) {
        results.push(...itemIds);
      }
    }

    // Search in item names directly
    for (const [id, item] of Object.entries(this.schema.elements)) {
      if (item.name.toLowerCase().includes(query)) {
        results.push(id);
      }
    }

    // Deduplicate and sort
    return [...new Set(results)].sort();
  }

  renderResults(results) {
    this.resultsContainer.innerHTML = '';

    if (results.length === 0) {
      this.resultsContainer.innerHTML = '<li class="no-results">No results found</li>';
      return;
    }

    results.forEach(itemId => {
      const item = this.getItemById(itemId);
      if (item) {
        const li = this.createResultItem(item);
        this.resultsContainer.appendChild(li);
      }
    });
  }
}
```

### 5.4 Content Renderer

```javascript
// assets/js/renderer.js
class ContentRenderer {
  constructor(schema) {
    this.schema = schema;
    this.container = document.getElementById('content-area');
    this.templateCache = new Map();
  }

  renderItem(itemId) {
    const item = this.getItemById(itemId);
    if (!item) return;

    // Select appropriate template based on item category
    const template = this.getTemplate(item.category);
    const html = this.renderTemplate(template, item);

    this.container.innerHTML = html;
    this.attachEventHandlers();
  }

  renderTemplate(template, item) {
    return template
      .replace('{{name}}', this.escapeHtml(item.name))
      .replace('{{namespace}}', this.escapeHtml(item.namespace))
      .replace('{{documentation}}', this.renderDocumentation(item.documentation))
      .replace('{{structure}}', this.renderStructure(item))
      .replace('{{cross_refs}}', this.renderCrossReferences(item))
      .replace('{{uml_mapping}}', this.renderUmlMapping(item.uml_mapping));
  }

  renderCrossReferences(item) {
    if (!item.cross_references) return '';

    const refs = item.cross_references;
    let html = '<div class="cross-references">';

    // Type reference
    if (refs.type_ref) {
      html += `<div class="ref-section">
        <h4>Type</h4>
        <a href="#" class="type-link" data-ref="${refs.type_ref}">
          ${refs.type_ref}
        </a>
      </div>`;
    }

    // Base type (inheritance)
    if (refs.base_type_ref) {
      html += `<div class="ref-section">
        <h4>Extends</h4>
        <a href="#" class="type-link" data-ref="${refs.base_type_ref}">
          ${refs.base_type_ref}
        </a>
      </div>`;
    }

    // Used by
    if (refs.used_by && refs.used_by.length > 0) {
      html += '<div class="ref-section"><h4>Used By</h4><ul>';
      refs.used_by.forEach(ref => {
        html += `<li><a href="#" class="ref-link" data-ref="${ref}">${ref}</a></li>`;
      });
      html += '</ul></div>';
    }

    // Uses types
    if (refs.uses_types && refs.uses_types.length > 0) {
      html += '<div class="ref-section"><h4>Uses Types</h4><ul>';
      refs.uses_types.forEach(ref => {
        html += `<li><a href="#" class="ref-link" data-ref="${ref}">${ref}</a></li>`;
      });
      html += '</ul></div>';
    }

    html += '</div>';
    return html;
  }

  renderUmlMapping(mapping) {
    if (!mapping) return '';

    return `<div class="uml-mapping">
      <h4>UML Mapping</h4>
      <dl>
        <dt>UML Class:</dt>
        <dd>${mapping.uml_class}</dd>

        <dt>UML Package:</dt>
        <dd>${mapping.uml_package}</dd>

        <dt>Stereotype:</dt>
        <dd><span class="stereotype">${mapping.stereotype}</span></dd>

        <dt>Resolution Strategy:</dt>
        <dd><span class="strategy">${mapping.resolution_strategy}</span></dd>
      </dl>
    </div>`;
  }

  attachEventHandlers() {
    // Attach click handlers to cross-reference links
    document.querySelectorAll('.ref-link, .type-link').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const ref = e.target.dataset.ref;
        window.app.navigation.navigateToReference(ref);
      });
    });
  }
}
```

---

## 6. Deployment Modes

### 6.1 Embedded Mode (Single HTML File)

**Structure**:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>PLATEAU Schema Documentation</title>
  <style>
    /* Inlined CSS - all styles embedded */
    <%= inline_css %>
  </style>
</head>
<body>
  <!-- Navigation and content structure -->
  <%= navigation_html %>
  <%= content_html %>

  <!-- Embedded JSON data -->
  <script id="schema-data" type="application/json">
    <%= schema_json %>
  </script>

  <!-- Inlined JavaScript -->
  <script>
    <%= inline_js %>
  </script>
</body>
</html>
```

**Advantages**:
- Single file distribution
- No external dependencies
- Offline-capable immediately
- Easy email/sharing

**Disadvantages**:
- Larger file size
- No browser caching of assets
- Harder to update styles separately

### 6.2 Multi-File Mode (Site Structure)

**Directory Structure**:
```
output_site/
├── index.html                    # Main entry point
├── data/
│   ├── schema.json              # Main schema data
│   ├── elements.json            # Elements index
│   ├── complex_types.json       # Complex types index
│   ├── simple_types.json        # Simple types index
│   ├── cross_refs.json          # Cross-reference index
│   └── search_index.json        # Search index
├── assets/
│   ├── css/
│   │   ├── main.css             # Core styles
│   │   ├── navigation.css       # Navigation styles
│   │   ├── content.css          # Content styles
│   │   ├── syntax.css           # XSD syntax highlighting
│   │   └── responsive.css       # Mobile responsive
│   ├── js/
│   │   ├── app.js               # Main application
│   │   ├── navigation.js        # Navigation controller
│   │   ├── search.js            # Search functionality
│   │   ├── renderer.js          # Content renderer
│   │   ├── router.js            # URL routing
│   │   └── utils.js             # Utilities
│   └── icons/
│       ├── element.svg          # Element icon
│       ├── type.svg             # Type icon
│       └── attribute.svg        # Attribute icon
└── README.md                     # Site information
```

**Advantages**:
- Browser caching of assets
- Easier style customization
- Smaller initial load
- Better for large schemas

**Disadvantages**:
- Multiple file distribution
- Requires web server (or file:// with CORS handling)

---

## 7. Responsive Design Strategy

### 7.1 Breakpoints

```css
/* Desktop - Full three-tier navigation */
@media (min-width: 1024px) {
  .sidebar {
    width: 320px;
    display: grid;
    grid-template-columns: 1fr;
    grid-template-rows: auto auto 1fr;
  }

  .nav-tier {
    display: block;
  }

  .content-area {
    margin-left: 320px;
  }
}

/* Tablet - Collapsible tiers */
@media (min-width: 768px) and (max-width: 1023px) {
  .sidebar {
    width: 280px;
  }

  .nav-tier-3 {
    max-height: 400px;
    overflow-y: auto;
  }
}

/* Mobile - Hamburger menu */
@media (max-width: 767px) {
  .sidebar {
    position: fixed;
    left: -100%;
    width: 80%;
    height: 100%;
    transition: left 0.3s ease;
  }

  .sidebar.active {
    left: 0;
  }

  .hamburger-menu {
    display: block;
  }
}
```

### 7.2 Mobile Navigation Pattern

```javascript
// Mobile nav toggle
class MobileNavigation {
  constructor() {
    this.sidebar = document.querySelector('.sidebar');
    this.hamburger = document.querySelector('.hamburger-menu');
    this.overlay = document.querySelector('.nav-overlay');

    this.setupToggle();
  }

  setupToggle() {
    this.hamburger.addEventListener('click', () => {
      this.sidebar.classList.toggle('active');
      this.overlay.classList.toggle('visible');
    });

    this.overlay.addEventListener('click', () => {
      this.sidebar.classList.remove('active');
      this.overlay.classList.remove('visible');
    });

    // Close on item selection (mobile only)
    if (window.innerWidth < 768) {
      document.querySelectorAll('.item-list-entry').forEach(item => {
        item.addEventListener('click', () => {
          this.sidebar.classList.remove('active');
          this.overlay.classList.remove('visible');
        });
      });
    }
  }
}
```

---

## 8. Generation Pipeline Architecture

### 8.1 Generation Workflow

```
┌──────────────────────────────────────┐
│   Input: LXR Package + YAML Mapping │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│     DataLoader.load_and_merge()      │
│  - Load LXR via lutaml-xsd           │
│  - Parse YAML mappings               │
│  - Create UnifiedSchema model        │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│  CrossReferenceBuilder.build()       │
│  - Element → Type mappings           │
│  - Type hierarchy (inheritance)      │
│  - Dependency graph                  │
│  - Attribute references              │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│   SearchIndexBuilder.build()         │
│  - Tokenize names                    │
│  - Build term → item mappings        │
│  - Namespace indexing                │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│  NavigationBuilder.build()           │
│  - Tier 1: Schema list               │
│  - Tier 2: Categories per schema     │
│  - Tier 3: Items per category        │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────┬───────────────┐
│  Embedded Mode       │  Multi-File   │
│  TemplateRenderer    │  Mode         │
│  - Single HTML       │  Template     │
│  - Inline CSS/JS     │  Renderer     │
│  - Embedded JSON     │  - index.html │
│                      │  - data/*.json│
│                      │  - assets/*   │
└──────────────────────┴───────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│         Output: SPA Website          │
│  - Navigable documentation           │
│  - Cross-referenced types            │
│  - Searchable elements               │
│  - Responsive design                 │
└──────────────────────────────────────┘
```

### 8.2 CLI Integration

```bash
# New CLI command: spa
lutaml-klin spa [OPTIONS] SOURCE OUTPUT

OPTIONS:
  --lxr PATH                LXR package path (required for XSD-only mode)
  --yaml PATH               YAML mapping path (optional, adds UML traceability)
  --mode MODE               embedded|multi-file (default: multi-file)
  --title TITLE             Website title (default: from metadata)
  --theme THEME             UI theme: default|plateau|dark (default: default)
  --include-stats           Include repository statistics page
  --custom-css PATH         Custom CSS file to include
  --custom-js PATH          Custom JavaScript file to include
  --base-url URL            Base URL for multi-file mode (default: /)

EXAMPLES:
  # Generate from LXR only (general XSD documentation)
  lutaml-klin spa --lxr schemas.lxr --output docs/

  # Generate with PLATEAU mapping (includes UML traceability)
  lutaml-klin spa \
    --lxr plateau_schemas.lxr \
    --yaml mappings/uro_mapping.yaml \
    --output plateau_docs/ \
    --title "PLATEAU URO Documentation"

  # Generate single embedded HTML
  lutaml-klin spa \
    --lxr schemas.lxr \
    --mode embedded \
    --output schema_doc.html

  # Generate with custom theme
  lutaml-klin spa \
    --lxr plateau_schemas.lxr \
    --yaml mappings/urf_mapping.yaml \
    --theme plateau \
    --include-stats \
    --output urf_docs/
```

---

## 9. Template Architecture

### 9.1 Template Hierarchy

```
templates/
├── base/
│   ├── layout.html.erb           # Base layout structure
│   └── head.html.erb             # Common <head> content
│
├── embedded/
│   └── single.html.erb           # Complete embedded template
│
├── multi_file/
│   ├── index.html.erb            # Multi-file index
│   ├── schema.html.erb           # Schema-level page
│   └── component.html.erb        # Component detail page
│
└── partials/
    ├── _navigation.html.erb      # Three-tier navigation
    ├── _breadcrumbs.html.erb     # Breadcrumb trail
    ├── _search.html.erb          # Search box
    ├── _element_detail.html.erb  # Element detail view
    ├── _type_detail.html.erb     # Type detail view
    ├── _cross_refs.html.erb      # Cross-references section
    ├── _uml_mapping.html.erb     # UML mapping section
    └── _statistics.html.erb      # Statistics dashboard
```

### 9.2 Base Layout Template

```erb
<!-- templates/base/layout.html.erb -->
<!DOCTYPE html>
<html lang="en" data-theme="<%= theme %>">
<head>
  <%= render_partial('base/head') %>
  <title><%= metadata.name %> - XSD Schema Documentation</title>

  <% if mode == :embedded %>
    <style><%= inline_css %></style>
  <% else %>
    <link rel="stylesheet" href="assets/css/main.css">
    <link rel="stylesheet" href="assets/css/navigation.css">
    <link rel="stylesheet" href="assets/css/content.css">
    <link rel="stylesheet" href="assets/css/responsive.css">
  <% end %>
</head>
<body>
  <div class="app-container">
    <!-- Three-tier navigation sidebar -->
    <nav class="sidebar">
      <%= render_partial('partials/_navigation', schema: schema) %>
    </nav>

    <!-- Main content area -->
    <main class="content-area">
      <%= render_partial('partials/_breadcrumbs') %>

      <div id="content-body">
        <%= yield %>
      </div>
    </main>
  </div>

  <!-- Data embedding -->
  <% if mode == :embedded %>
    <script id="schema-data" type="application/json">
      <%= schema.to_json %>
    </script>
    <script><%= inline_js %></script>
  <% else %>
    <script src="assets/js/app.js"></script>
  <% end %>
</body>
</html>
```

### 9.3 Navigation Partial

```erb
<!-- templates/partials/_navigation.html.erb -->
<div class="nav-container">
  <!-- Tier 1: Schema Selector -->
  <div class="nav-tier nav-tier-1">
    <h3>Schemas</h3>
    <select id="schema-selector" class="schema-select">
      <% schemas.each do |schema| %>
        <option value="<%= schema.id %>" data-namespace="<%= schema.namespace %>">
          <%= schema.name %>
        </option>
      <% end %>
    </select>
    <div class="schema-info">
      <span class="schema-version"></span>
      <span class="schema-namespace"></span>
    </div>
  </div>

  <!-- Tier 2: Category List -->
  <div class="nav-tier nav-tier-2">
    <h4>Components</h4>
    <ul class="category-list">
      <li class="category-item" data-category="elements">
        <svg class="icon" use="#icon-element"></svg>
        <span class="category-name">Elements</span>
        <span class="category-count"></span>
      </li>
      <li class="category-item" data-category="complex-types">
        <svg class="icon" use="#icon-type"></svg>
        <span class="category-name">Complex Types</span>
        <span class="category-count"></span>
      </li>
      <li class="category-item" data-category="simple-types">
        <svg class="icon" use="#icon-simple"></svg>
        <span class="category-name">Simple Types</span>
        <span class="category-count"></span>
      </li>
      <li class="category-item" data-category="attributes">
        <svg class="icon" use="#icon-attr"></svg>
        <span class="category-name">Attributes</span>
        <span class="category-count"></span>
      </li>
    </ul>
  </div>

  <!-- Tier 3: Item List with Search -->
  <div class="nav-tier nav-tier-3">
    <div class="search-container">
      <%= render_partial('partials/_search') %>
    </div>
    <ul class="item-list" id="item-list">
      <!-- Dynamically populated by JavaScript -->
    </ul>
  </div>
</div>

<!-- SVG Icon Definitions -->
<svg style="display: none;">
  <defs>
    <symbol id="icon-element" viewBox="0 0 24 24">
      <rect x="3" y="3" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2"/>
      <path d="M 8 12 L 16 12 M 12 8 L 12 16" stroke="currentColor" stroke-width="2"/>
    </symbol>
    <symbol id="icon-type" viewBox="0 0 24 24">
      <circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/>
      <text x="12" y="16" text-anchor="middle" font-size="10" fill="currentColor">T</text>
    </symbol>
    <!-- Additional icons -->
  </defs>
</svg>
```

---

## 10. Styling Architecture

### 10.1 CSS Organization (BEM Methodology)

```css
/* assets/css/main.css - Core layout */

/* Variables */
:root {
  --primary-color: #2563eb;
  --secondary-color: #64748b;
  --background: #ffffff;
  --surface: #f8fafc;
  --text-primary: #0f172a;
  --text-secondary: #475569;
  --border: #e2e8f0;
  --shadow: rgba(0, 0, 0, 0.1);

  --sidebar-width: 320px;
  --header-height: 64px;
  --spacing-unit: 8px;
}

/* Dark theme */
[data-theme="dark"] {
  --primary-color: #3b82f6;
  --background: #0f172a;
  --surface: #1e293b;
  --text-primary: #f1f5f9;
  --text-secondary: #cbd5e1;
  --border: #334155;
}

/* PLATEAU theme */
[data-theme="plateau"] {
  --primary-color: #059669;
  --secondary-color: #0891b2;
}

/* Layout */
.app-container {
  display: grid;
  grid-template-columns: var(--sidebar-width) 1fr;
  height: 100vh;
  overflow: hidden;
}

.sidebar {
  background: var(--surface);
  border-right: 1px solid var(--border);
  display: grid;
  grid-template-rows: auto auto 1fr;
  overflow: hidden;
}

.content-area {
  padding: calc(var(--spacing-unit) * 3);
  overflow-y: auto;
}
```

```css
/* assets/css/navigation.css - Navigation components */

/* Tier 1: Schema Selector */
.nav-tier-1 {
  padding: calc(var(--spacing-unit) * 2);
  border-bottom: 1px solid var(--border);
}

.schema-select {
  width: 100%;
  padding: calc(var(--spacing-unit) * 1.5);
  border: 1px solid var(--border);
  border-radius: 4px;
  background: var(--background);
  font-size: 14px;
}

.schema-info {
  margin-top: var(--spacing-unit);
  font-size: 12px;
  color: var(--text-secondary);
}

/* Tier 2: Category List */
.nav-tier-2 {
  padding: calc(var(--spacing-unit) * 2);
  border-bottom: 1px solid var(--border);
}

.category-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.category-item {
  display: flex;
  align-items: center;
  padding: calc(var(--spacing-unit) * 1.5);
  margin-bottom: var(--spacing-unit);
  cursor: pointer;
  border-radius: 4px;
  transition: background 0.2s ease;
}

.category-item:hover {
  background: var(--background);
}

.category-item.active {
  background: var(--primary-color);
  color: white;
}

.category-item .icon {
  width: 20px;
  height: 20px;
  margin-right: var(--spacing-unit);
}

.category-count {
  margin-left: auto;
  background: var(--border);
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
}

/* Tier 3: Item List */
.nav-tier-3 {
  padding: calc(var(--spacing-unit) * 2);
  overflow-y: auto;
}

.item-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.item-list-entry {
  padding: calc(var(--spacing-unit) * 1.5);
  margin-bottom: 4px;
  cursor: pointer;
  border-radius: 4px;
  transition: background 0.2s ease;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.item-list-entry:hover {
  background: var(--background);
}

.item-list-entry.active {
  background: var(--primary-color);
  color: white;
}

.item-namespace {
  font-size: 11px;
  color: var(--text-secondary);
  font-family: monospace;
}
```

---

## 11. Implementation Phases

### Phase 1: Core Infrastructure (Week 1, 12-16 hours)

**Goal**: Establish data models and extraction pipeline

#### Tasks:
1. **Create SPA Models** (4 hours)
   - `UnifiedSchema`, `SchemaMetadata`, `CrossReferenceIndex`, `SearchIndex`
   - Full Lutaml::Model serialization support
   - Comprehensive spec tests

2. **Implement DataLoader** (4 hours)
   - LXR package loading via lutaml-xsd
   - YAML mapping parsing
   - Data merging algorithm
   - Spec tests

3. **Implement CrossReferenceBuilder** (4-6 hours)
   - Element-to-type mapping
   - Type hierarchy computation
   - Dependency graph building
   - Spec tests

4. **Implement SearchIndexBuilder** (2-4 hours)
   - Term tokenization
   - Index construction
   - Namespace indexing
   - Spec tests

**Deliverables**:
- `lib/lutaml/klin/spa/models/*.rb` (7 files)
- `lib/lutaml/klin/spa/data_loader.rb`
- `lib/lutaml/klin/spa/cross_reference_builder.rb`
- `lib/lutaml/klin/spa/search_index_builder.rb`
- `spec/lutaml/klin/spa/*_spec.rb` (comprehensive tests)

### Phase 2: Template System (Week 2, 8-12 hours)

**Goal**: Create template rendering system

#### Tasks:
1. **Base Templates** (3-4 hours)
   - Layout templates (embedded + multi-file)
   - Head partial with meta tags
   - Navigation partial
   - Spec tests for template rendering

2. **Component Partials** (3-4 hours)
   - Element detail view
   - Type detail view
   - Cross-reference display
   - UML mapping display

3. **Template Renderer** (2-4 hours)
   - ERB rendering engine
   - Partial support
   - Variable binding
   - Spec tests

**Deliverables**:
- `lib/lutaml/klin/spa/templates/*.erb` (8-10 templates)
- `lib/lutaml/klin/spa/template_renderer.rb`
- `spec/lutaml/klin/spa/template_renderer_spec.rb`

### Phase 3: Frontend Assets (Week 3, 12-16 hours)

**Goal**: Implement JavaScript application and CSS styling

#### Tasks:
1. **Core JavaScript** (6-8 hours)
   - `app.js` - Main application
   - `navigation.js` - Navigation controller
   - `search.js` - Search functionality
   - `renderer.js` - Content renderer
   - `router.js` - URL routing

2. **Styling** (4-6 hours)
   - `main.css` - Core layout
   - `navigation.css` - Navigation styling
   - `content.css` - Content styling
   - `responsive.css` - Mobile responsive
   - Theme variants (default, PLATEAU, dark)

3. **Asset Bundling** (2 hours)
   - `lib/lutaml/klin/spa/asset_bundler.rb`
   - Inline CSS/JS for embedded mode
   - Copy external assets for multi-file mode

**Deliverables**:
- `lib/lutaml/klin/spa/assets/css/*.css` (5 files)
- `lib/lutaml/klin/spa/assets/js/*.js` (6 files)
- `lib/lutaml/klin/spa/asset_bundler.rb`
- `spec/lutaml/klin/spa/asset_bundler_spec.rb`

### Phase 4: Generator Integration (Week 4, 8-10 hours)

**Goal**: Integrate all components and create CLI command

#### Tasks:
1. **Main Generator** (4-5 hours)
   - `lib/lutaml/klin/spa/generator.rb`
   - Orchestrate all components
   - Output mode selection
   - Spec tests

2. **CLI Command** (2-3 hours)
   - `lib/lutaml/klin/commands/spa_command.rb`
   - Integrate with existing CLI
   - Help documentation
   - Spec tests

3. **End-to-End Testing** (2-3 hours)
   - Integration tests with real PLATEAU data
   - Test both embedded and multi-file modes
   - Performance validation

**Deliverables**:
- `lib/lutaml/klin/spa/generator.rb`
- `lib/lutaml/klin/commands/spa_command.rb`
- Updated `lib/lutaml/klin/cli.rb`
- `spec/integration/spa_generation_spec.rb`

---

## 12. Advanced Features

### 12.1 Bidirectional PLATEAU ↔ XSD Mapping

**Architecture**: Maintain bidirectional links between UML and XSD representations

```javascript
// Mapping Display Component
class MappingDisplay {
  renderBidirectionalMapping(item) {
    const html = `
      <div class="mapping-panel">
        <!-- UML → XSD direction -->
        <div class="mapping-direction">
          <h4>UML to XSD Mapping</h4>
          <div class="mapping-chain">
            <div class="mapping-source">
              <strong>UML Class:</strong> ${item.uml_mapping.uml_class}
              <br><small>Package: ${item.uml_mapping.uml_package}</small>
            </div>

            <div class="mapping-arrow">
              <span class="strategy-label">${item.uml_mapping.resolution_strategy}</span>
              →
            </div>

            <div class="mapping-target">
              <strong>XSD Element:</strong> ${item.qualified_name}
              <br><strong>XSD Type:</strong> ${item.type}
            </div>
          </div>
        </div>

        <!-- XSD → UML direction -->
        <div class="mapping-direction reverse">
          <h4>XSD to UML Mapping</h4>
          <div class="mapping-chain">
            <div class="mapping-source">
              <strong>XSD Element:</strong> ${item.qualified_name}
              <br><small>Namespace: ${item.namespace}</small>
            </div>

            <div class="mapping-arrow">
              ←
              <span class="strategy-label">Reverse Lookup</span>
            </div>

            <div class="mapping-target">
              <strong>UML Class:</strong> ${item.uml_mapping.uml_class}
              <br><strong>Stereotype:</strong> ${item.uml_mapping.stereotype}
            </div>
          </div>
        </div>
      </div>
    `;

    return html;
  }
}
```

### 12.2 Statistics Dashboard

**Component**: Repository-wide statistics visualization

```javascript
class StatisticsDashboard {
  render(statistics) {
    return `
      <div class="statistics-dashboard">
        <div class="stat-card">
          <h3>Repository Overview</h3>
          <dl class="stat-list">
            <dt>Total Schemas:</dt>
            <dd>${statistics.total_schemas}</dd>

            <dt>Total Namespaces:</dt>
            <dd>${statistics.total_namespaces}</dd>

            <dt>Total Types:</dt>
            <dd>${statistics.total_types}</dd>
          </dl>
        </div>

        <div class="stat-card">
          <h3>Component Breakdown</h3>
          <div class="component-chart">
            ${this.renderChart(statistics.types_by_category)}
          </div>
        </div>

        <div class="stat-card">
          <h3>Namespace Distribution</h3>
          <ul class="namespace-list">
            ${this.renderNamespaceList(statistics.namespaces)}
          </ul>
        </div>

        <div class="stat-card">
          <h3>Traceability Information</h3>
          <dl class="trace-info">
            <dt>LXR Package:</dt>
            <dd>${statistics.lxr_package_info.name} v${statistics.lxr_package_info.version}</dd>

            <dt>Generated:</dt>
            <dd>${statistics.generated_at}</dd>

            <dt>Resolution Strategies:</dt>
            <dd>${statistics.resolution_strategies.join(', ')}</dd>
          </dl>
        </div>
      </div>
    `;
  }
}
```

---

## 13. URL Routing and SEO

### 13.1 URL Structure

```
# Schema-level
/#/plateau-urf
/#/citygml-2.0

# Category-level
/#/plateau-urf/elements
/#/plateau-urf/complex-types

# Item-level
/#/plateau-urf/elements/UrbanPlanningArea
/#/plateau-urf/complex-types/UrbanPlanningAreaType

# Cross-reference navigation preserves context
/#/plateau-urf/complex-types/UrbanPlanningAreaType?ref=gml:CodeType
```

### 13.2 Router Implementation

```javascript
class Router {
  constructor(app) {
    this.app = app;
    this.routes = new Map();

    this.setupRoutes();
    this.setupHashChange();
  }

  setupRoutes() {
    // Route patterns
    this.routes.set(/^#\/([^\/]+)$/, (schema) => {
      this.app.navigation.selectSchema(schema);
    });

    this.routes.set(/^#\/([^\/]+)\/([^\/]+)$/, (schema, category) => {
      this.app.navigation.selectSchema(schema);
      this.app.navigation.selectCategory(category);
    });

    this.routes.set(/^#\/([^\/]+)\/([^\/]+)\/([^\/]+)$/, (schema, category, item) => {
      this.app.navigation.selectSchema(schema);
      this.app.navigation.selectCategory(category);
      this.app.navigation.selectItem(item);
    });
  }

  setupHashChange() {
    window.addEventListener('hashchange', () => {
      this.handleRoute(window.location.hash);
    });
  }

  handleRoute(hash) {
    for (const [pattern, handler] of this.routes) {
      const match = hash.match(pattern);
      if (match) {
        handler.apply(this, match.slice(1));
        return;
      }
    }
  }

  updateURL(schema, category, item) {
    let hash = `#/${schema}`;
    if (category) hash += `/${category}`;
    if (item) hash += `/${item}`;

    window.location.hash = hash;
  }
}
```

---

## 14. Testing Strategy

### 14.1 Ruby Component Tests

```ruby
# Unit tests for each component
RSpec.describe Lutaml::Klin::Spa::Generator do
  describe "#generate" do
    it "generates embedded SPA from LXR package"
    it "generates multi-file SPA from LXR package"
    it "merges LXR and YAML data correctly"
    it "includes traceability information"
  end
end

RSpec.describe Lutaml::Klin::Spa::DataLoader do
  it "loads LXR package via lutaml-xsd"
  it "parses YAML mapping files"
  it "merges data sources correctly"
  it "enriches XSD data with UML mappings"
end

RSpec.describe Lutaml::Klin::Spa::CrossReferenceBuilder do
  it "builds element-to-type mappings"
  it "computes type hierarchies"
  it "builds dependency graphs"
  it "creates namespace indexes"
end
```

### 14.2 Frontend Tests (Optional)

Using a JavaScript testing framework (e.g., Jest):

```javascript
describe('NavigationController', () => {
  it('should navigate between schemas', () => {
    // Test tier 1 navigation
  });

  it('should filter items by category', () => {
    // Test tier 2 navigation
  });

  it('should navigate to item detail', () => {
    // Test tier 3 navigation
  });

  it('should follow cross-references', () => {
    // Test reference navigation
  });
});

describe('SearchController', () => {
  it('should search by element name', () => {});
  it('should search by type name', () => {});
  it('should filter by namespace', () => {});
});
```

### 14.3 Integration Tests

```ruby
RSpec.describe "PLATEAU SPA Generation", :integration do
  let(:lxr_path) { "packages/plateau_schemas.lxr" }
  let(:yaml_path) { "plateau_xsd_mapping/plateau_xsd_mapping.yaml" }
  let(:output_dir) { "tmp/spa_test" }

  it "generates complete SPA from PLATEAU data" do
    generator = Lutaml::Klin::Spa::Generator.new

    generator.generate(lxr_path, yaml_path, output_dir)

    # Verify output structure
    expect(File.exist?(File.join(output_dir, 'index.html'))).to be true
    expect(File.exist?(File.join(output_dir, 'data/schema.json'))).to be true
    expect(Dir.exist?(File.join(output_dir, 'assets'))).to be true
  end

  it "generates embedded single-file SPA" do
    generator = Lutaml::Klin::Spa::Generator.new(mode: :embedded)

    output_file = File.join(output_dir, 'plateau_docs.html')
    generator.generate(lxr_path, yaml_path, output_file)

    # Verify single file
    expect(File.exist?(output_file)).to be true

    # Verify embedded JSON
    content = File.read(output_file)
    expect(content).to include('<script id="schema-data"')
    expect(content).to include('UrbanPlanningArea')
  end
end
```

---

## 15. Example Output

### 15.1 Generated Embedded HTML (Excerpt)

```html
<!DOCTYPE html>
<html lang="en" data-theme="default">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PLATEAU Schema Documentation</title>
  <style>
    /* Inlined CSS (all styles) */
    :root { --primary-color: #2563eb; /* ... */ }
    .app-container { display: grid; /* ... */ }
    /* ... complete CSS inlined ... */
  </style>
</head>
<body>
  <div class="app-container">
    <nav class="sidebar">
      <!-- Three-tier navigation -->
    </nav>
    <main class="content-area">
      <div id="content-body">
        <!-- Dynamic content rendered here -->
      </div>
    </main>
  </div>

  <!-- Embedded schema data -->
  <script id="schema-data" type="application/json">
    {
      "metadata": { "name": "PLATEAU Schema Repository", ... },
      "schemas": [...],
      "elements": {...},
      "complex_types": {...},
      "cross_reference_index": {...},
      "search_index": {...}
    }
  </script>

  <!-- Inlined JavaScript (all scripts) -->
  <script>
    class SchemaDocApp { /* ... */ }
    class NavigationController { /* ... */ }
    class SearchController { /* ... */ }
    class ContentRenderer { /* ... */ }
    // ... complete JS inlined ...

    // Initialize
    document.addEventListener('DOMContentLoaded', () => {
      window.app = new SchemaDocApp('embedded');
    });
  </script>
</body>
</html>
```

### 15.2 Generated Multi-File Structure

```
output/
├── index.html                  # Main entry point
├── data/
│   ├── schema.json            # 1.2 MB - Core schema data
│   ├── elements.json          # 450 KB - Elements index
│   ├── complex_types.json     # 720 KB - Complex types
│   ├── simple_types.json      # 180 KB - Simple types
│   ├── cross_refs.json        # 320 KB - Cross-references
│   └── search_index.json      # 85 KB - Search index
│
├── assets/
│   ├── css/
│   │   ├── main.css           # 12 KB
│   │   ├── navigation.css     # 8 KB
│   │   ├── content.css        # 15 KB
│   │   ├── syntax.css         # 6 KB
│   │   └── responsive.css     # 9 KB
│   │
│   ├── js/
│   │   ├── app.js             # 8 KB
│   │   ├── navigation.js      # 12 KB
│   │   ├── search.js          # 7 KB
│   │   ├── renderer.js        # 15 KB
│   │   ├── router.js          # 5 KB
│   │   └── utils.js           # 4 KB
│   │
│   └── icons/
│       ├── element.svg        # 1 KB
│       ├── type.svg           # 1 KB
│       ├── attribute.svg      # 1 KB
│       └── logo.svg           # 2 KB
│
└── README.md                   # Site documentation
```

---

## 16. Performance Optimization

### 16.1 Data Loading Strategies

**Lazy Loading for Large Schemas**:

```javascript
class LazyLoader {
  constructor(schema) {
    this.schema = schema;
    this.loadedCategories = new Set();
  }

  async loadCategory(schemaId, categoryId) {
    const key = `${schemaId}/${categoryId}`;

    if (this.loadedCategories.has(key)) {
      return this.getCachedCategory(key);
    }

    // Fetch category data on demand
    const data = await fetch(`data/${schemaId}/${categoryId}.json`).then(r => r.json());

    this.cacheCategory(key, data);
    this.loadedCategories.add(key);

    return data;
  }
}
```

### 16.2 Search Optimization

**Indexed Search with Debouncing**:

```javascript
class OptimizedSearch {
  constructor(index) {
    this.index = index;
    this.debounceTimer = null;
    this.resultCache = new Map();
  }

  search(query, callback) {
    // Debounce search
    clearTimeout(this.debounceTimer);

    this.debounceTimer = setTimeout(() => {
      // Check cache
      if (this.resultCache.has(query)) {
        callback(this.resultCache.get(query));
        return;
      }

      // Perform search
      const results = this.performIndexedSearch(query);

      // Cache results
      this.resultCache.set(query, results);

      callback(results);
    }, 300); // 300ms debounce
  }

  performIndexedSearch(query) {
    // Use pre-built index for O(1) lookup
    const normalizedQuery = query.toLowerCase();
    return this.index.terms[normalizedQuery] || [];
  }
}
```

---

## 17. Accessibility and SEO

### 17.1 Accessibility Features

```html
<!-- Semantic HTML -->
<nav aria-label="Schema navigation">
  <div role="navigation" aria-label="Tier 1: Schema selector">
    <select aria-label="Select schema">...</select>
  </div>

  <div role="navigation" aria-label="Tier 2: Component categories">
    <ul role="list">
      <li role="listitem">
        <button aria-label="View elements" aria-expanded="false">
          Elements
        </button>
      </li>
    </ul>
  </div>
</nav>

<!-- ARIA live regions for dynamic content -->
<div id="content-body" aria-live="polite" aria-atomic="true">
  <!-- Content updates announced to screen readers -->
</div>

<!-- Keyboard navigation -->
<script>
  document.addEventListener('keydown', (e) => {
    // Arrow keys for navigation
    // Tab for focus management
    // Enter to select items
  });
</script>
```

### 17.2 SEO Optimization

```html
<!-- Meta tags for search engines -->
<head>
  <meta name="description" content="<%= metadata.description %>">
  <meta name="keywords" content="XSD, XML Schema, <%= schema_names.join(', ') %>">

  <!-- Open Graph -->
  <meta property="og:title" content="<%= metadata.name %>">
  <meta property="og:description" content="<%= metadata.description %>">
  <meta property="og:type" content="website">

  <!-- Structured data -->
  <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "TechArticle",
      "name": "<%= metadata.name %>",
      "description": "<%= metadata.description %>",
      "version": "<%= metadata.version %>",
      "datePublished": "<%= metadata.generated_at %>"
    }
  </script>
</head>
```

---

## 18. Implementation Checklist

### Pre-Implementation
- [ ] Review existing SPA demos in `demo/` directory
- [ ] Analyze PLATEAU-specific requirements
- [ ] Design JSON schema for unified data model
- [ ] Create wireframes for navigation and content layout

### Phase 1: Core Infrastructure (Week 1)
- [ ] Create Lutaml::Model-based schema models
- [ ] Implement DataLoader with LXR/YAML merging
- [ ] Implement CrossReferenceBuilder
- [ ] Implement SearchIndexBuilder
- [ ] Write comprehensive unit tests

### Phase 2: Template System (Week 2)
- [ ] Create base layout templates
- [ ] Create component partials
- [ ] Implement TemplateRenderer
- [ ] Test template rendering with sample data

### Phase 3: Frontend Assets (Week 3)
- [ ] Implement JavaScript application
- [ ] Create CSS stylesheets with themes
- [ ] Implement AssetBundler
- [ ] Test in multiple browsers

### Phase 4: Integration (Week 4)
- [ ] Implement main Generator class
- [ ] Create SPA CLI command
- [ ] End-to-end integration testing
- [ ] Performance optimization
- [ ] Documentation and examples

### Post-Implementation
- [ ] User acceptance testing
- [ ] Performance profiling
- [ ] Accessibility audit
- [ ] Documentation polish

---

## 19. Success Criteria

### Functional Requirements ✅
- [ ] Three-tier hierarchical navigation working
- [ ] Cross-references navigate correctly
- [ ] Search finds elements and types by name
- [ ] Both embedded and multi-file modes working
- [ ] Responsive design on desktop/mobile
- [ ] PLATEAU and general XSD support
- [ ] UML mapping display (bidirectional)
- [ ] Traceability information visible

### Quality Requirements
- [ ] All Ruby components have comprehensive tests
- [ ] JavaScript code follows best practices
- [ ] CSS is organized and themeable
- [ ] Accessibility standards met (WCAG 2.1 AA)
- [ ] SEO-friendly structure
- [ ] Cross-browser compatibility

### Performance Requirements
- [ ] Initial page load < 2 seconds (multi-file mode)
- [ ] Search results < 100ms
- [ ] Navigation transitions < 50ms
- [ ] Embedded HTML < 5MB for typical schemas
- [ ] Mobile-friendly performance

---

## 20. Future Enhancements

### Advanced Features
1. **Visual Schema Diagram**: SVG-based type hierarchy visualization
2. **Export Functionality**: Export individual component definitions as XSD
3. **Comparison Mode**: Compare two schema versions side-by-side
4. **Custom Annotations**: User-added notes and bookmarks
5. **Print Optimization**: Printer-friendly CSS for documentation

### Integration Points
1. **lutaml-xsd Liquid Templates**: Generate documentation using existing Liquid methods
2. **CI/CD Integration**: Automated SPA generation in GitHub Actions
3. **API Endpoint**: Serve schema data as REST API
4. **Plugin System**: Allow custom renderers and themes

---

## Conclusion

This Enhanced HTML SPA Architecture provides a comprehensive, flexible solution for generating interactive XSD schema documentation from LXR packages and YAML mappings.

**Key Strengths**:
- Clean OO architecture in Ruby layer
- Modern JavaScript SPA patterns
- Dual deployment modes (embedded/multi-file)
- Pre-computed cross-references for performance
- Bidirectional PLATEAU ↔ XSD mapping support
- Comprehensive traceability from UML to XSD

**Implementation Timeline**: 4 weeks (40-54 hours total)

**Next Step**: Begin Phase 1 implementation with core infrastructure and data models.