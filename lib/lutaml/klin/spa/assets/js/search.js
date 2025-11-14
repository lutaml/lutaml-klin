/**
 * Search Controller Module
 * Client-side search with debouncing and result filtering
 */

import { Utils } from './utils.js';

class SearchController {
  /**
   * Initialize search controller
   * @param {Object} searchIndex - Search index data
   * @param {Object} navigationController - Navigation controller instance
   */
  constructor(searchIndex, navigationController) {
    this.index = searchIndex;
    this.navigation = navigationController;
    this.searchBox = document.getElementById('item-search');
    this.clearButton = document.querySelector('.search-clear');
    this.resultsContainer = document.getElementById('item-list');

    this.debounceTimer = null;
    this.debounceDelay = 300; // ms

    this.setupSearch();
  }

  /**
   * Setup search event listeners
   */
  setupSearch() {
    if (!this.searchBox) return;

    // Input event with debouncing
    this.searchBox.addEventListener('input', (e) => {
      this.performDebouncedSearch(e.target.value);
      this.updateClearButton(e.target.value);
    });

    // Clear button
    if (this.clearButton) {
      this.clearButton.addEventListener('click', () => {
        this.clearSearch();
      });
    }

    // Keyboard shortcuts
    document.addEventListener('keydown', (e) => {
      // Ctrl+K or Cmd+K to focus search
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        this.searchBox.focus();
      }

      // Escape to clear search
      if (e.key === 'Escape' && this.searchBox === document.activeElement) {
        this.clearSearch();
      }
    });
  }

  /**
   * Perform debounced search
   * @param {string} query - Search query
   */
  performDebouncedSearch(query) {
    // Clear previous timer
    clearTimeout(this.debounceTimer);

    // Set new timer
    this.debounceTimer = setTimeout(() => {
      this.performSearch(query);
    }, this.debounceDelay);
  }

  /**
   * Perform search
   * @param {string} query - Search query
   */
  performSearch(query) {
    if (!query || query.length < 2) {
      this.clearSearchResults();
      return;
    }

    const results = this.search(query.toLowerCase());
    this.renderResults(results, query);
  }

  /**
   * Search in index
   * @param {string} query - Search query (lowercase)
   * @returns {Array} Array of item IDs
   */
  search(query) {
    const results = new Set();

    // Search in index terms
    if (this.index && this.index.terms) {
      for (const [term, itemIds] of Object.entries(this.index.terms)) {
        if (term.toLowerCase().includes(query)) {
          itemIds.forEach(id => results.add(id));
        }
      }
    }

    return Array.from(results).sort();
  }

  /**
   * Render search results
   * @param {Array} results - Array of item IDs
   * @param {string} query - Search query for highlighting
   */
  renderResults(results, query) {
    if (!this.resultsContainer) return;

    this.resultsContainer.innerHTML = '';

    if (results.length === 0) {
      this.resultsContainer.innerHTML = `
        <li class="no-results">No results found</li>
      `;
      return;
    }

    results.forEach(itemId => {
      const item = this.getItemById(itemId);
      if (item) {
        const li = this.createResultItem(item, query);
        this.resultsContainer.appendChild(li);
      }
    });
  }

  /**
   * Create result item element
   * @param {Object} item - Item data
   * @param {string} query - Search query for highlighting
   * @returns {HTMLElement} List item element
   */
  createResultItem(item, query) {
    const li = document.createElement('li');
    li.className = 'item-list-entry search-result';
    li.dataset.itemId = item.id;
    li.tabIndex = 0;
    li.setAttribute('role', 'listitem');

    li.innerHTML = `
      <span class="item-name">${Utils.highlightMatch(item.name, query)}</span>
      <span class="item-namespace">${Utils.escapeHtml(item.prefix || item.namespace || '')}</span>
      <span class="item-category-badge">${this.getCategoryBadge(item.category)}</span>
    `;

    li.addEventListener('click', () => {
      this.navigation.selectItem(item.id);
    });

    li.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        this.navigation.selectItem(item.id);
      }
    });

    return li;
  }

  /**
   * Get item by ID from schema
   * @param {string} itemId - Item identifier
   * @returns {Object|null} Item data or null
   */
  getItemById(itemId) {
    // Search all collections
    const schema = this.navigation.app.schema;

    return schema.elements.find(e => e.id === itemId || e.qualified_name === itemId)
        || schema.complex_types.find(t => t.id === itemId || t.qualified_name === itemId)
        || schema.simple_types.find(t => t.id === itemId || t.qualified_name === itemId)
        || schema.attributes.find(a => a.id === itemId || a.qualified_name === itemId);
  }

  /**
   * Get category badge text
   * @param {string} category - Category name
   * @returns {string} Badge text
   */
  getCategoryBadge(category) {
    const badges = {
      'elements': 'E',
      'complex_types': 'CT',
      'simple_types': 'ST',
      'attributes': 'A'
    };
    return badges[category] || '?';
  }

  /**
   * Clear search input and results
   */
  clearSearch() {
    if (this.searchBox) {
      this.searchBox.value = '';
      this.updateClearButton('');
    }
    this.clearSearchResults();
  }

  /**
   * Clear search results and restore original list
   */
  clearSearchResults() {
    // Restore original item list for current category
    if (this.navigation.state.currentCategory) {
      this.navigation.renderItemList(this.navigation.state.currentCategory);
    } else if (this.resultsContainer) {
      this.resultsContainer.innerHTML = '';
    }
  }

  /**
   * Update clear button visibility
   * @param {string} value - Search input value
   */
  updateClearButton(value) {
    if (!this.clearButton) return;
    this.clearButton.style.display = value ? 'block' : 'none';
  }
}

export { SearchController };