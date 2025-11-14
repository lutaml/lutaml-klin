/**
 * URL Router Module
 * Hash-based routing for bookmarkable pages
 */

class Router {
  /**
   * Initialize router
   * @param {Object} app - Main application instance
   */
  constructor(app) {
    this.app = app;
    this.routes = this.defineRoutes();
    this.setupHashChange();
  }

  /**
   * Define route patterns and handlers
   * @returns {Array} Route definitions
   */
  defineRoutes() {
    return [
      {
        pattern: /^#\/([^\/]+)$/,
        handler: (schemaId) => {
          this.app.navigation.selectSchema(schemaId);
        }
      },
      {
        pattern: /^#\/([^\/]+)\/([^\/]+)$/,
        handler: (schemaId, categoryId) => {
          this.app.navigation.selectSchema(schemaId);
          this.app.navigation.selectCategory(categoryId);
        }
      },
      {
        pattern: /^#\/([^\/]+)\/([^\/]+)\/([^\/]+)$/,
        handler: (schemaId, categoryId, itemId) => {
          this.app.navigation.selectSchema(schemaId);
          this.app.navigation.selectCategory(categoryId);
          this.app.navigation.selectItem(decodeURIComponent(itemId));
        }
      }
    ];
  }

  /**
   * Setup hash change event listener
   */
  setupHashChange() {
    window.addEventListener('hashchange', () => {
      this.handleRoute(window.location.hash);
    });
  }

  /**
   * Handle initial route on page load
   */
  handleInitialRoute() {
    const hash = window.location.hash;
    if (hash) {
      this.handleRoute(hash);
    }
  }

  /**
   * Handle route by matching pattern
   * @param {string} hash - URL hash
   */
  handleRoute(hash) {
    for (const route of this.routes) {
      const match = hash.match(route.pattern);
      if (match) {
        route.handler.apply(this, match.slice(1));
        return;
      }
    }
  }

  /**
   * Update URL based on current navigation state
   */
  updateURL() {
    const state = this.app.navigation.state;
    let hash = '';

    if (state.currentSchema) {
      hash = `#/${state.currentSchema}`;

      if (state.currentCategory) {
        hash += `/${state.currentCategory}`;

        if (state.currentItem) {
          hash += `/${encodeURIComponent(state.currentItem)}`;
        }
      }
    }

    // Only update if different
    if (window.location.hash !== hash) {
      window.location.hash = hash;
    }
  }
}

export { Router };