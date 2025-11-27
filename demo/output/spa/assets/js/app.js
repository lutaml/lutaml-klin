/**
 * MappingBrowserApp - Client-side SPA for browsing UML-XSD mappings
 *
 * Features:
 * - Package tree navigation with expand/collapse
 * - Real-time search with keyword matching
 * - Status filtering (resolved/partial/unresolved)
 * - Detailed class and attribute views
 * - Statistics dashboard
 * - Hash-based routing for deep linking
 * - Responsive design
 */
class MappingBrowserApp {
  constructor() {
    this.data = null;
    this.searchIndex = null;
    this.statistics = null;
    this.currentView = 'packages';
    this.expandedPackages = new Set();
    this.activeFilters = {
      resolved: true,
      partial: true,
      unresolved: true
    };
  }

  /**
   * Initialize the application
   */
  async init() {
    try {
      this.showLoading();
      await this.loadData();
      this.setupEventListeners();
      this.renderPackageTree();
      this.renderStatistics();
      this.handleRouteChange();
      this.hideLoading();
    } catch (error) {
      console.error('Failed to initialize app:', error);
      this.showError('Failed to load mapping data. Please check the console for details.');
    }
  }

  /**
   * Load all JSON data (from embedded data or files)
   */
  async loadData() {
    try {
      // Try to use embedded data first (avoids CORS issues with file://)
      if (window.MAPPING_DATA && window.SEARCH_INDEX && window.STATISTICS) {
        this.data = window.MAPPING_DATA;
        this.searchIndex = window.SEARCH_INDEX;
        this.statistics = window.STATISTICS;
        return;
      }

      // Fall back to fetching from files (requires HTTP server)
      const [mappings, searchIndex, statistics] = await Promise.all([
        fetch('data/mappings.json').then(r => {
          if (!r.ok) throw new Error(`Failed to load mappings.json: ${r.statusText}`);
          return r.json();
        }),
        fetch('data/search_index.json').then(r => {
          if (!r.ok) throw new Error(`Failed to load search_index.json: ${r.statusText}`);
          return r.json();
        }),
        fetch('data/statistics.json').then(r => {
          if (!r.ok) throw new Error(`Failed to load statistics.json: ${r.statusText}`);
          return r.json();
        })
      ]);

      this.data = mappings;
      this.searchIndex = searchIndex;
      this.statistics = statistics;
    } catch (error) {
      console.error('Error loading data:', error);
      throw error;
    }
  }

  /**
   * Setup all event listeners
   */
  setupEventListeners() {
    // Search input
    const searchInput = document.getElementById('search');
    searchInput.addEventListener('input', (e) => this.handleSearch(e.target.value));

    // Click outside search results to close
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.search-container')) {
        this.hideSearchResults();
      }
    });

    // Filter checkboxes
    document.getElementById('filter-resolved').addEventListener('change', (e) => {
      this.activeFilters.resolved = e.target.checked;
      this.renderPackageTree();
    });

    document.getElementById('filter-partial').addEventListener('change', (e) => {
      this.activeFilters.partial = e.target.checked;
      this.renderPackageTree();
    });

    document.getElementById('filter-unresolved').addEventListener('change', (e) => {
      this.activeFilters.unresolved = e.target.checked;
      this.renderPackageTree();
    });

    // Hash change for routing
    window.addEventListener('hashchange', () => this.handleRouteChange());

    // Keyboard navigation
    searchInput.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        this.hideSearchResults();
        searchInput.blur();
      }
    });
  }

  /**
   * Render the package tree in the sidebar
   */
  renderPackageTree() {
    const tree = document.getElementById('package-tree');
    if (!this.data || !this.data.packages) {
      tree.innerHTML = '<p class="error">No packages found</p>';
      return;
    }

    tree.innerHTML = this.data.packages.map(pkg => {
      const isExpanded = this.expandedPackages.has(pkg.id);
      const filteredClasses = this.filterClasses(pkg.classes || []);

      return `
        <div class="package-item ${isExpanded ? 'expanded' : ''}"
             onclick="app.togglePackage('${pkg.id}')"
             role="treeitem"
             aria-expanded="${isExpanded}">
          <span>${isExpanded ? '📂' : '📁'}</span> ${this.escapeHtml(pkg.name)}
          <span style="float: right; font-size: 0.85em; color: #666;">
            ${filteredClasses.length}
          </span>
        </div>
        ${isExpanded ? `
          <div class="class-list" role="group">
            ${filteredClasses.map(cls => `
              <div class="class-item ${this.isActive('class', cls.id) ? 'active' : ''}"
                   onclick="app.showClass('${cls.id}'); event.stopPropagation();"
                   role="treeitem">
                ${this.getStatusBadge(cls.resolution_status)} ${this.escapeHtml(cls.uml_name)}
              </div>
            `).join('')}
          </div>
        ` : ''}
      `;
    }).join('');
  }

  /**
   * Filter classes based on active status filters
   */
  filterClasses(classes) {
    return classes.filter(cls => {
      const status = cls.resolution_status;
      return (status === 'resolved' && this.activeFilters.resolved) ||
             (status === 'partial' && this.activeFilters.partial) ||
             (status === 'unresolved' && this.activeFilters.unresolved);
    });
  }

  /**
   * Toggle package expansion
   */
  togglePackage(packageId) {
    if (this.expandedPackages.has(packageId)) {
      this.expandedPackages.delete(packageId);
    } else {
      this.expandedPackages.add(packageId);
    }
    this.renderPackageTree();
  }

  /**
   * Render statistics in sidebar
   */
  renderStatistics() {
    const statsDiv = document.getElementById('statistics');
    if (!this.statistics || !this.statistics.summary) {
      statsDiv.innerHTML = '<p class="error">No statistics available</p>';
      return;
    }

    const summary = this.statistics.summary;
    const resolutionRate = summary.resolution_rate || 0;

    statsDiv.innerHTML = `
      <div class="stats-summary">
        <p>
          <strong>Packages</strong>
          <span>${summary.total_packages || 0}</span>
        </p>
        <p>
          <strong>Classes</strong>
          <span>${summary.resolved_classes}/${summary.total_classes}</span>
        </p>
        <p>
          <strong>Attributes</strong>
          <span>${summary.resolved_attributes}/${summary.total_attributes}</span>
        </p>
        <p>
          <strong>Resolution</strong>
          <span style="color: ${this.getResolutionColor(resolutionRate)}">
            ${resolutionRate.toFixed(1)}%
          </span>
        </p>
      </div>
    `;
  }

  /**
   * Show package details
   */
  showPackage(packageId) {
    const pkg = this.data.packages.find(p => p.id === packageId);
    if (!pkg) return;

    // Expand package if not already expanded
    if (!this.expandedPackages.has(packageId)) {
      this.togglePackage(packageId);
    }

    const filteredClasses = this.filterClasses(pkg.classes || []);

    this.updateBreadcrumb([
      { name: 'Packages', url: '#/packages' },
      { name: pkg.name, url: `#/packages/${pkg.id}` }
    ]);

    const details = document.getElementById('details');
    details.innerHTML = `
      <h2>📦 ${this.escapeHtml(pkg.name)}</h2>

      <div class="detail-section">
        <h3>Package Information</h3>
        <div class="detail-row">
          <div class="detail-label">Qualified Name:</div>
          <div class="detail-value"><code>${this.escapeHtml(pkg.qualified_name)}</code></div>
        </div>
        <div class="detail-row">
          <div class="detail-label">Namespace:</div>
          <div class="detail-value"><code>${this.escapeHtml(pkg.namespace)}</code></div>
        </div>
        ${pkg.namespace_prefix ? `
          <div class="detail-row">
            <div class="detail-label">Prefix:</div>
            <div class="detail-value"><code>${this.escapeHtml(pkg.namespace_prefix)}</code></div>
          </div>
        ` : ''}
        ${pkg.schema_location ? `
          <div class="detail-row">
            <div class="detail-label">Schema Location:</div>
            <div class="detail-value"><code>${this.escapeHtml(pkg.schema_location)}</code></div>
          </div>
        ` : ''}
      </div>

      <h3>Classes (${filteredClasses.length})</h3>
      <table>
        <thead>
          <tr>
            <th>Status</th>
            <th>UML Name</th>
            <th>XSD Type</th>
            <th>Method</th>
          </tr>
        </thead>
        <tbody>
          ${filteredClasses.map(cls => `
            <tr onclick="app.showClass('${cls.id}')" style="cursor: pointer;">
              <td>${this.getStatusBadge(cls.resolution_status)}</td>
              <td><strong>${this.escapeHtml(cls.uml_name)}</strong></td>
              <td><code>${this.escapeHtml(cls.xsd_type_name || 'N/A')}</code></td>
              <td>${this.escapeHtml(cls.resolution_method || 'N/A')}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `;
  }

  /**
   * Show class details
   */
  showClass(classId) {
    let cls = null;
    let pkg = null;

    for (const p of this.data.packages) {
      cls = p.classes.find(c => c.id === classId);
      if (cls) {
        pkg = p;
        break;
      }
    }

    if (!cls || !pkg) return;

    // Update hash for deep linking
    window.location.hash = `#/classes/${classId}`;

    // Expand package and update tree
    if (!this.expandedPackages.has(pkg.id)) {
      this.expandedPackages.add(pkg.id);
      this.renderPackageTree();
    }

    this.updateBreadcrumb([
      { name: 'Packages', url: '#/packages' },
      { name: pkg.name, url: `#/packages/${pkg.id}` },
      { name: cls.uml_name, url: `#/classes/${cls.id}` }
    ]);

    const details = document.getElementById('details');
    details.innerHTML = `
      <h2>${this.getStatusBadge(cls.resolution_status)} ${this.escapeHtml(cls.uml_name)}</h2>

      <div class="detail-section">
        <h3>Class Information</h3>
        <div class="detail-row">
          <div class="detail-label">Qualified Name:</div>
          <div class="detail-value"><code>${this.escapeHtml(cls.uml_qualified_name || 'N/A')}</code></div>
        </div>
        ${cls.uml_stereotype ? `
          <div class="detail-row">
            <div class="detail-label">Stereotype:</div>
            <div class="detail-value"><code>${this.escapeHtml(cls.uml_stereotype)}</code></div>
          </div>
        ` : ''}
        ${cls.uml_documentation ? `
          <div class="detail-row">
            <div class="detail-label">UML Documentation:</div>
            <div class="detail-value">${this.escapeHtml(cls.uml_documentation)}</div>
          </div>
        ` : ''}
      </div>

      <div class="detail-section">
        <h3>XSD Mapping</h3>
        <div class="detail-row">
          <div class="detail-label">XSD Namespace:</div>
          <div class="detail-value"><code>${this.escapeHtml(cls.xsd_namespace || 'N/A')}</code></div>
        </div>
        <div class="detail-row">
          <div class="detail-label">XSD Element:</div>
          <div class="detail-value"><code>${this.escapeHtml(cls.xsd_element_name || 'N/A')}</code></div>
        </div>
        <div class="detail-row">
          <div class="detail-label">XSD Type:</div>
          <div class="detail-value"><code>${this.escapeHtml(cls.xsd_type_name || 'N/A')}</code></div>
        </div>
        ${cls.xsd_documentation ? `
          <div class="detail-row">
            <div class="detail-label">XSD Documentation:</div>
            <div class="detail-value">${this.escapeHtml(cls.xsd_documentation)}</div>
          </div>
        ` : ''}
      </div>

      <div class="detail-section">
        <h3>Resolution Details</h3>
        <div class="detail-row">
          <div class="detail-label">Status:</div>
          <div class="detail-value">${this.getStatusBadge(cls.resolution_status)} ${cls.resolution_status}</div>
        </div>
        <div class="detail-row">
          <div class="detail-label">Method:</div>
          <div class="detail-value">${this.escapeHtml(cls.resolution_method || 'N/A')}</div>
        </div>
        ${cls.resolution_confidence !== undefined && cls.resolution_confidence !== null ? `
          <div class="detail-row">
            <div class="detail-label">Confidence:</div>
            <div class="detail-value">${(cls.resolution_confidence * 100).toFixed(0)}%</div>
          </div>
        ` : ''}
      </div>

      <h3>Attributes (${cls.attributes ? cls.attributes.length : 0})</h3>
      ${cls.attributes && cls.attributes.length > 0 ? `
        <table>
          <thead>
            <tr>
              <th>Status</th>
              <th>UML Name</th>
              <th>UML Type</th>
              <th>XSD Type</th>
              <th>Multiplicity</th>
            </tr>
          </thead>
          <tbody>
            ${cls.attributes.map(attr => `
              <tr>
                <td>${this.getStatusBadge(attr.resolution_status)}</td>
                <td><strong>${this.escapeHtml(attr.uml_name)}</strong></td>
                <td><code>${this.escapeHtml(attr.uml_type || 'N/A')}</code></td>
                <td><code>${this.escapeHtml(attr.xsd_type || 'N/A')}</code></td>
                <td>${this.escapeHtml(attr.uml_multiplicity || '1')}</td>
              </tr>
              ${attr.resolution_error ? `
                <tr>
                  <td colspan="5" style="background-color: #fff5f5; color: var(--color-unresolved); font-size: 0.9em;">
                    <strong>Error:</strong> ${this.escapeHtml(attr.resolution_error)}
                  </td>
                </tr>
              ` : ''}
            `).join('')}
          </tbody>
        </table>
      ` : '<p>No attributes defined.</p>'}
    `;
  }

  /**
   * Handle search input
   */
  handleSearch(query) {
    if (!query || query.length < 2) {
      this.hideSearchResults();
      return;
    }

    const lowerQuery = query.toLowerCase();
    const results = this.searchIndex.index.filter(item => {
      return item.title.toLowerCase().includes(lowerQuery) ||
             item.qualified_name.toLowerCase().includes(lowerQuery) ||
             (item.keywords && item.keywords.some(k => k.includes(lowerQuery)));
    }).slice(0, 15);

    this.displaySearchResults(results);
  }

  /**
   * Display search results
   */
  displaySearchResults(results) {
    const resultsDiv = document.getElementById('search-results');

    if (results.length === 0) {
      resultsDiv.innerHTML = '<div style="padding: 1rem; color: var(--color-text-muted);">No results found</div>';
    } else {
      resultsDiv.innerHTML = results.map(item => `
        <div class="search-result-item"
             onclick="app.navigateToItem('${item.type}', '${item.id}')"
             role="option">
          <strong>${this.escapeHtml(item.title)}</strong>
          <span class="type-badge">${item.type}</span>
          ${item.resolution_status ? this.getStatusBadge(item.resolution_status) : ''}
          <div style="font-size: 0.85em; color: var(--color-text-muted); margin-top: 0.25rem;">
            ${this.escapeHtml(item.qualified_name)}
          </div>
        </div>
      `).join('');
    }

    resultsDiv.classList.remove('hidden');
  }

  /**
   * Hide search results
   */
  hideSearchResults() {
    document.getElementById('search-results').classList.add('hidden');
  }

  /**
   * Navigate to a search result item
   */
  navigateToItem(type, id) {
    this.hideSearchResults();
    document.getElementById('search').value = '';

    if (type === 'package') {
      this.showPackage(id);
      window.location.hash = `#/packages/${id}`;
    } else if (type === 'class') {
      this.showClass(id);
    }
  }

  /**
   * Handle hash route changes
   */
  handleRouteChange() {
    const hash = window.location.hash;

    if (!hash || hash === '#/' || hash === '#/packages') {
      // Show welcome message
      this.updateBreadcrumb([{ name: 'Packages', url: '#/packages' }]);
      return;
    }

    // Parse route
    const match = hash.match(/#\/(packages|classes)\/(.+)/);
    if (match) {
      const [, type, id] = match;
      if (type === 'packages') {
        this.showPackage(id);
      } else if (type === 'classes') {
        this.showClass(id);
      }
    }
  }

  /**
   * Update breadcrumb navigation
   */
  updateBreadcrumb(items) {
    const breadcrumb = document.getElementById('breadcrumb');
    if (!items || items.length === 0) {
      breadcrumb.innerHTML = '';
      return;
    }

    breadcrumb.innerHTML = items.map((item, index) => {
      const isLast = index === items.length - 1;
      if (isLast) {
        return `<span>${this.escapeHtml(item.name)}</span>`;
      }
      return `
        <a href="${item.url}">${this.escapeHtml(item.name)}</a>
        <span class="separator">›</span>
      `;
    }).join('');
  }

  /**
   * Get status badge HTML
   */
  getStatusBadge(status) {
    switch(status) {
      case 'resolved':
        return '<span class="badge-resolved" title="Resolved">✓</span>';
      case 'partial':
        return '<span class="badge-partial" title="Partially Resolved">⚠</span>';
      case 'unresolved':
        return '<span class="badge-unresolved" title="Unresolved">✗</span>';
      default:
        return '<span title="Unknown">?</span>';
    }
  }

  /**
   * Get resolution rate color
   */
  getResolutionColor(rate) {
    if (rate >= 90) return 'var(--color-resolved)';
    if (rate >= 50) return 'var(--color-partial)';
    return 'var(--color-unresolved)';
  }

  /**
   * Check if item is active
   */
  isActive(type, id) {
    const hash = window.location.hash;
    return hash.includes(`/${type}s/${id}`);
  }

  /**
   * Escape HTML to prevent XSS
   */
  escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  /**
   * Show loading indicator
   */
  showLoading() {
    const details = document.getElementById('details');
    details.innerHTML = '<div style="text-align: center; padding: 4rem;"><div class="loading"></div><p>Loading mapping data...</p></div>';
  }

  /**
   * Hide loading indicator
   */
  hideLoading() {
    // Loading is hidden when content is rendered
  }

  /**
   * Show error message
   */
  showError(message) {
    const details = document.getElementById('details');
    details.innerHTML = `<p class="error">${this.escapeHtml(message)}</p>`;
  }
}

// Initialize app when DOM is ready
let app;
document.addEventListener('DOMContentLoaded', () => {
  app = new MappingBrowserApp();
  app.init();
});