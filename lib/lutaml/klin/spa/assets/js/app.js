/**
 * Main Application Module
 * ES6 Module - No bundling required, runs directly in modern browsers
 */

import { NavigationController } from './navigation.js';
import { SearchController } from './search.js';
import { ContentRenderer } from './renderer.js';
import { Router } from './router.js';
import { Utils } from './utils.js';

class SchemaDocApp {
  /**
   * Initialize application
   */
  constructor() {
    this.dataSource = this.detectDataSource();
    this.schema = null;
    this.navigation = null;
    this.search = null;
    this.renderer = null;
    this.router = null;

    this.init();
  }

  /**
   * Detect data source (embedded or external)
   * @returns {string} Data source type
   */
  detectDataSource() {
    // Check if embedded mode (schema-data script tag exists)
    return document.getElementById('schema-data') ? 'embedded' : 'external';
  }

  /**
   * Initialize application
   */
  async init() {
    try {
      // Load schema data
      this.schema = await this.loadSchema();

      // Initialize controllers
      this.navigation = new NavigationController(this.schema, this);
      this.search = new SearchController(this.schema.search_index || {}, this.navigation);
      this.renderer = new ContentRenderer(this.schema, this);
      this.router = new Router(this);

      // Setup global event listeners
      this.setupEventListeners();

      // Handle initial route
      this.router.handleInitialRoute();

      console.log('[App] Initialized successfully');
    } catch (error) {
      console.error('[App] Initialization failed:', error);
      this.showError('Failed to load schema documentation. Please refresh the page.');
    }
  }

  /**
   * Load schema data from embedded or external source
   * @returns {Promise<Object>} Schema data
   */
  async loadSchema() {
    if (this.dataSource === 'embedded') {
      // Load from embedded JSON
      const dataEl = document.getElementById('schema-data');
      if (!dataEl) {
        throw new Error('Embedded schema data not found');
      }

      return JSON.parse(dataEl.textContent);
    } else {
      // Load from external JSON files
      try {
        const [schema, crossRefs, searchIndex] = await Promise.all([
          fetch('data/schema.json').then(r => r.json()),
          fetch('data/cross_refs.json').then(r => r.json()).catch(() => ({})),
          fetch('data/search_index.json').then(r => r.json()).catch(() => ({}))
        ]);

        // Merge data
        schema.cross_references = crossRefs;
        schema.search_index = searchIndex;

        return schema;
      } catch (error) {
        throw new Error(`Failed to fetch schema data: ${error.message}`);
      }
    }
  }

  /**
   * Setup global event listeners
   */
  setupEventListeners() {
    // Mobile nav toggle
    const hamburger = document.querySelector('.hamburger-menu');
    const sidebar = document.querySelector('.sidebar');
    const overlay = document.querySelector('.nav-overlay');

    if (hamburger && sidebar && overlay) {
      hamburger.addEventListener('click', () => {
        sidebar.classList.toggle('active');
        overlay.classList.toggle('visible');
      });

      overlay.addEventListener('click', () => {
        sidebar.classList.remove('active');
        overlay.classList.remove('visible');
      });
    }

    // Theme toggle (if button exists)
    const themeToggle = document.getElementById('theme-toggle');
    if (themeToggle) {
      themeToggle.addEventListener('click', () => this.toggleTheme());
    }

    // Load saved theme preference
    const savedTheme = localStorage.getItem('theme');
    if (savedTheme) {
      document.documentElement.dataset.theme = savedTheme;
    }
  }

  /**
   * Toggle theme (dark/light)
   */
  toggleTheme() {
    const html = document.documentElement;
    const currentTheme = html.dataset.theme || 'default';
    const newTheme = currentTheme === 'dark' ? 'default' : 'dark';
    html.dataset.theme = newTheme;
    localStorage.setItem('theme', newTheme);
  }

  /**
   * Show error message
   * @param {string} message - Error message
   */
  showError(message) {
    const contentBody = document.getElementById('content-body');
    if (contentBody) {
      contentBody.innerHTML = `
        <div class="error-message">
          <h1>Error</h1>
          <p>${Utils.escapeHtml(message)}</p>
        </div>
      `;
    }
  }
}

// Initialize app when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    window.app = new SchemaDocApp();
  });
} else {
  window.app = new SchemaDocApp();
}

export { SchemaDocApp };