/**
 * Navigation Controller Module
 * Three-tier navigation state management and rendering
 */

import { Utils } from './utils.js';

class NavigationController {
  /**
   * Initialize navigation controller
   * @param {Object} schema - Schema data
   * @param {Object} app - Main application instance
   */
  constructor(schema, app) {
    this.schema = schema;
    this.app = app;
    this.state = {
      currentSchema: null,      // Tier 1
      currentCategory: null,    // Tier 2
      currentItem: null,        // Tier 3
      breadcrumbs: []
    };

    this.initNavigation();
  }

  /**
   * Initialize navigation system
   */
  initNavigation() {
    // Initialize tier 1 (schema selector)
    this.setupSchemaSelector();

    // Initialize tier 2 (category list)
    this.setupCategoryList();

    // Initialize tier 3 (item list)
    this.setupItemList();

    // Select first schema by default
    if (this.schema.schemas && this.schema.schemas.length > 0) {
      this.selectSchema(this.schema.schemas[0].id);
    }
  }

  /**
   * Setup schema selector (tier 1)
   */
  setupSchemaSelector() {
    const selector = document.getElementById('schema-selector');
    if (!selector) return;

    selector.addEventListener('change', (e) => {
      this.selectSchema(e.target.value);
    });
  }

  /**
   * Setup category list (tier 2)
   */
  setupCategoryList() {
    const categories = document.querySelectorAll('.category-item');

    categories.forEach(cat => {
      cat.addEventListener('click', () => {
        const categoryId = cat.dataset.category;
        this.selectCategory(categoryId);
      });

      // Keyboard navigation
      cat.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          const categoryId = cat.dataset.category;
          this.selectCategory(categoryId);
        }
      });
    });
  }

  /**
   * Setup item list (tier 3)
   * Event delegation handled in renderItemList
   */
  setupItemList() {
    // Item list is dynamically populated
    // Event delegation is handled when rendering
  }

  /**
   * Select schema (tier 1)
   * @param {string} schemaId - Schema identifier
   */
  selectSchema(schemaId) {
    this.state.currentSchema = schemaId;
    this.state.currentCategory = null;
    this.state.currentItem = null;

    // Update schema info display
    const schema = this.schema.schemas.find(s => s.id === schemaId);
    if (schema) {
      this.updateSchemaInfo(schema);
      this.updateCategoryCounts(schema);
    }

    // Clear item list
    this.clearItemList();

    // Update breadcrumbs
    this.updateBreadcrumbs();

    // Update URL
    if (this.app.router) {
      this.app.router.updateURL();
    }

    // Render welcome screen
    if (this.app.renderer) {
      this.app.renderer.renderWelcome(schema);
    }
  }

  /**
   * Select category (tier 2)
   * @param {string} categoryId - Category identifier
   */
  selectCategory(categoryId) {
    if (!this.state.currentSchema) return;

    this.state.currentCategory = categoryId;
    this.state.currentItem = null;

    // Update UI
    this.highlightCategory(categoryId);
    this.renderItemList(categoryId);

    // Update breadcrumbs
    this.updateBreadcrumbs();

    // Update URL
    if (this.app.router) {
      this.app.router.updateURL();
    }

    // Clear content or show category intro
    if (this.app.renderer) {
      this.app.renderer.renderCategoryIntro(categoryId);
    }
  }

  /**
   * Select item (tier 3)
   * @param {string} itemId - Item identifier
   */
  selectItem(itemId) {
    this.state.currentItem = itemId;

    // Highlight item in list
    this.highlightItem(itemId);

    // Render item details
    if (this.app.renderer) {
      this.app.renderer.renderItem(itemId);
    }

    // Update breadcrumbs
    this.updateBreadcrumbs();

    // Update URL
    if (this.app.router) {
      this.app.router.updateURL();
    }

    // Close mobile nav if open
    this.closeMobileNav();
  }

  /**
   * Render item list for category
   * @param {string} categoryId - Category identifier
   */
  renderItemList(categoryId) {
    const items = this.getItemsForCategory(
      this.state.currentSchema,
      categoryId
    );

    const itemList = document.getElementById('item-list');
    if (!itemList) return;

    itemList.innerHTML = '';

    if (items.length === 0) {
      itemList.innerHTML = '<li class="no-items">No items in this category</li>';
      return;
    }

    items.forEach(item => {
      const li = this.createItemElement(item);
      itemList.appendChild(li);
    });
  }

  /**
   * Create item list element
   * @param {Object} item - Item data
   * @returns {HTMLElement} List item element
   */
  createItemElement(item) {
    const li = document.createElement('li');
    li.className = 'item-list-entry';
    li.dataset.itemId = item.id;
    li.tabIndex = 0;
    li.setAttribute('role', 'listitem');

    li.innerHTML = `
      <span class="item-name">${Utils.escapeHtml(item.name)}</span>
      <span class="item-namespace">${Utils.escapeHtml(item.prefix || item.namespace || '')}</span>
    `;

    li.addEventListener('click', () => this.selectItem(item.id));
    li.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        this.selectItem(item.id);
      }
    });

    return li;
  }

  /**
   * Get items for category and schema
   * @param {string} schemaId - Schema identifier
   * @param {string} categoryId - Category identifier
   * @returns {Array} Array of items
   */
  getItemsForCategory(schemaId, categoryId) {
    let items = [];

    switch (categoryId) {
      case 'elements':
        items = this.schema.elements.filter(e => e.schema_id === schemaId);
        break;
      case 'complex-types':
        items = this.schema.complex_types.filter(t => t.schema_id === schemaId);
        break;
      case 'simple-types':
        items = this.schema.simple_types.filter(t => t.schema_id === schemaId);
        break;
      case 'attributes':
        items = this.schema.attributes.filter(a => a.schema_id === schemaId);
        break;
    }

    // Sort alphabetically
    return items.sort((a, b) => a.name.localeCompare(b.name));
  }

  /**
   * Navigate to cross-reference
   * @param {string} referenceId - Reference identifier
   */
  navigateToReference(referenceId) {
    // Parse reference ID (format: "prefix:name")
    const item = this.resolveReference(referenceId);

    if (!item) {
      console.warn(`Reference not found: ${referenceId}`);
      return;
    }

    // Update all three tiers
    this.state.currentSchema = item.schema_id;
    this.state.currentCategory = item.category;
    this.state.currentItem = item.id;

    // Update selector
    const selector = document.getElementById('schema-selector');
    if (selector) {
      selector.value = item.schema_id;
    }

    // Re-render navigation
    const schema = this.schema.schemas.find(s => s.id === item.schema_id);
    if (schema) {
      this.updateSchemaInfo(schema);
      this.updateCategoryCounts(schema);
    }
    this.highlightCategory(item.category);
    this.renderItemList(item.category);
    this.highlightItem(item.id);

    // Render item
    if (this.app.renderer) {
      this.app.renderer.renderItem(item.id);
    }

    // Update breadcrumbs and URL
    this.updateBreadcrumbs();
    if (this.app.router) {
      this.app.router.updateURL();
    }

    // Scroll to item in list
    this.scrollToItem(item.id);
  }

  /**
   * Resolve reference to item
   * @param {string} referenceId - Reference identifier
   * @returns {Object|null} Item data or null
   */
  resolveReference(referenceId) {
    // Try to find in elements
    let item = this.schema.elements.find(e =>
      e.qualified_name === referenceId || e.id === referenceId
    );
    if (item) {
      item.category = 'elements';
      return item;
    }

    // Try complex types
    item = this.schema.complex_types.find(t =>
      t.qualified_name === referenceId || t.id === referenceId
    );
    if (item) {
      item.category = 'complex-types';
      return item;
    }

    // Try simple types
    item = this.schema.simple_types.find(t =>
      t.qualified_name === referenceId || t.id === referenceId
    );
    if (item) {
      item.category = 'simple-types';
      return item;
    }

    // Try attributes
    item = this.schema.attributes.find(a =>
      a.qualified_name === referenceId || a.id === referenceId
    );
    if (item) {
      item.category = 'attributes';
      return item;
    }

    return null;
  }

  /**
   * Update breadcrumbs
   */
  updateBreadcrumbs() {
    const breadcrumbs = [];

    if (this.state.currentSchema) {
      const schema = this.schema.schemas.find(s => s.id === this.state.currentSchema);
      if (schema) {
        breadcrumbs.push({
          text: schema.name,
          link: `#/${schema.id}`
        });
      }
    }

    if (this.state.currentCategory) {
      breadcrumbs.push({
        text: this.getCategoryDisplayName(this.state.currentCategory),
        link: `#/${this.state.currentSchema}/${this.state.currentCategory}`
      });
    }

    if (this.state.currentItem) {
      const item = this.getCurrentItem();
      if (item) {
        breadcrumbs.push({
          text: item.name,
          link: `#/${this.state.currentSchema}/${this.state.currentCategory}/${item.id}`
        });
      }
    }

    this.renderBreadcrumbs(breadcrumbs);
  }

  /**
   * Render breadcrumbs
   * @param {Array} breadcrumbs - Array of breadcrumb objects
   */
  renderBreadcrumbs(breadcrumbs) {
    const breadcrumbList = document.querySelector('.breadcrumb-list');
    if (!breadcrumbList) return;

    breadcrumbList.innerHTML = '';

    breadcrumbs.forEach((crumb, index) => {
      const li = document.createElement('li');
      li.className = 'breadcrumb-item';

      if (index === breadcrumbs.length - 1) {
        li.setAttribute('aria-current', 'page');
        li.innerHTML = `<span>${Utils.escapeHtml(crumb.text)}</span>`;
      } else {
        li.innerHTML = `<a href="${crumb.link}">${Utils.escapeHtml(crumb.text)}</a>`;
      }

      breadcrumbList.appendChild(li);

      // Add separator
      if (index < breadcrumbs.length - 1) {
        const sep = document.createElement('li');
        sep.className = 'breadcrumb-separator';
        sep.setAttribute('aria-hidden', 'true');
        sep.textContent = '/';
        breadcrumbList.appendChild(sep);
      }
    });
  }

  /**
   * Get category display name
   * @param {string} categoryId - Category identifier
   * @returns {string} Display name
   */
  getCategoryDisplayName(categoryId) {
    const names = {
      'elements': 'Elements',
      'complex-types': 'Complex Types',
      'simple-types': 'Simple Types',
      'attributes': 'Attributes'
    };
    return names[categoryId] || categoryId;
  }

  /**
   * Get current item
   * @returns {Object|null} Current item or null
   */
  getCurrentItem() {
    if (!this.state.currentItem) return null;
    return this.resolveReference(this.state.currentItem);
  }

  /**
   * Update schema info display
   * @param {Object} schema - Schema data
   */
  updateSchemaInfo(schema) {
    const versionEl = document.querySelector('.schema-version');
    const nsEl = document.querySelector('.schema-namespace');

    if (versionEl) versionEl.textContent = `v${schema.version || ''}`;
    if (nsEl) nsEl.textContent = schema.namespace || '';
  }

  /**
   * Update category counts
   * @param {Object} schema - Schema data
   */
  updateCategoryCounts(schema) {
    const counts = schema.components || {};
    const categories = document.querySelectorAll('.category-item');

    categories.forEach(cat => {
      const categoryId = cat.dataset.category;
      const countEl = cat.querySelector('.category-count');

      if (countEl) {
        let count = 0;
        switch (categoryId) {
          case 'elements': count = counts.elements || 0; break;
          case 'complex-types': count = counts.complex_types || 0; break;
          case 'simple-types': count = counts.simple_types || 0; break;
          case 'attributes': count = counts.attributes || 0; break;
        }
        countEl.textContent = count;
      }
    });
  }

  /**
   * Highlight active category
   * @param {string} categoryId - Category identifier
   */
  highlightCategory(categoryId) {
    document.querySelectorAll('.category-item').forEach(cat => {
      cat.classList.toggle('active', cat.dataset.category === categoryId);
    });
  }

  /**
   * Highlight active item
   * @param {string} itemId - Item identifier
   */
  highlightItem(itemId) {
    document.querySelectorAll('.item-list-entry').forEach(item => {
      item.classList.toggle('active', item.dataset.itemId === itemId);
    });
  }

  /**
   * Scroll to item in list
   * @param {string} itemId - Item identifier
   */
  scrollToItem(itemId) {
    const item = document.querySelector(`.item-list-entry[data-item-id="${itemId}"]`);
    if (item) {
      item.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }

  /**
   * Clear item list
   */
  clearItemList() {
    const itemList = document.getElementById('item-list');
    if (itemList) {
      itemList.innerHTML = '';
    }
  }

  /**
   * Close mobile navigation
   */
  closeMobileNav() {
    const sidebar = document.querySelector('.sidebar');
    const overlay = document.querySelector('.nav-overlay');

    if (sidebar) sidebar.classList.remove('active');
    if (overlay) overlay.classList.remove('visible');
  }
}

export { NavigationController };