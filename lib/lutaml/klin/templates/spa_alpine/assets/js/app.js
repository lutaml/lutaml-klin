/**
 * Alpine.js MappingBrowser Component
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

document.addEventListener('alpine:init', () => {
  Alpine.data('mappingBrowser', () => ({
    // === STATE ===
    data: null,
    searchIndex: null,
    statistics: null,
    expandedPackages: [],
    activeFilters: {
      resolved: true,
      partial: true,
      unresolved: true
    },
    currentView: 'welcome', // 'welcome', 'package', 'class'
    currentPackageId: null,
    currentClassId: null,
    searchQuery: '',
    searchResults: [],
    breadcrumbs: [],
    selectedSchemaIndex: 0, // For multi-schema comparison
    
    // === LIFECYCLE ===
    init() {
      this.loadData();
      this.setupRouting();
    },
    
    /**
     * Load all JSON data (from embedded data or files)
     */
    loadData() {
      try {
        // Try to use embedded data first (avoids CORS issues with file://)
        if (window.MAPPING_DATA && window.SEARCH_INDEX && window.STATISTICS) {
          this.data = window.MAPPING_DATA;
          this.searchIndex = window.SEARCH_INDEX;
          this.statistics = window.STATISTICS;
          return;
        }
        
        // Fall back to fetching from files (requires HTTP server)
        console.warn('Embedded data not found, attempting to fetch from files...');
        fetch('data/mappings.json')
          .then(r => r.json())
          .then(mappings => {
            this.data = mappings;
            return fetch('data/search_index.json');
          })
          .then(r => r.json())
          .then(searchIndex => {
            this.searchIndex = searchIndex;
            return fetch('data/statistics.json');
          })
          .then(r => r.json())
          .then(statistics => {
            this.statistics = statistics;
          })
          .catch(error => {
            console.error('Error loading data:', error);
            alert('Failed to load mapping data. Please check the console for details.');
          });
      } catch (error) {
        console.error('Error in loadData:', error);
      }
    },
    
    /**
     * Setup hash-based routing
     */
    setupRouting() {
      window.addEventListener('hashchange', () => {
        this.handleRouteChange();
      });
      this.handleRouteChange();
    },
    
    // === COMPUTED PROPERTIES ===
    get currentPackage() {
      if (!this.currentPackageId || !this.data) return null;
      return this.data.packages[this.currentPackageId];
    },
    
    get currentClass() {
      if (!this.currentClassId || !this.data) return null;
      return this.data.classes[this.currentClassId];
    },
    
    get filteredPackages() {
      if (!this.data) return [];
      // Convert hash to array for template iteration
      return Object.values(this.data.packages).map(pkg => ({
        ...pkg,
        // Get full class objects from class IDs and filter
        classes: this.getPackageClasses(pkg.id)
      }));
    },
    
    // === HELPERS FOR HASH-BASED DATA ===
    /**
     * Get full class objects for a package (from class IDs)
     */
    getPackageClasses(packageId) {
      const pkg = this.data.packages[packageId];
      if (!pkg || !pkg.classes) return [];
      return pkg.classes
        .map(classId => this.data.classes[classId])
        .filter(cls => cls && this.matchesFilter(cls));
    },
    
    /**
     * Get attribute object by ID
     */
    getAttribute(attrId) {
      return this.data.attributes[attrId];
    },
    
    /**
     * Get full attribute objects for a class (from attribute IDs)
     */
    getClassAttributes(cls) {
      if (!cls || !cls.attributes) return [];
      return cls.attributes
        .map(attrId => this.data.attributes[attrId])
        .filter(attr => attr); // Filter out any missing attributes
    },
    
    /**
     * Check if class matches current filters
     */
    matchesFilter(cls) {
      const status = cls.resolution_status;
      return (status === 'resolved' && this.activeFilters.resolved) ||
             (status === 'partial' && this.activeFilters.partial) ||
             (status === 'unresolved' && this.activeFilters.unresolved);
    },
    
    // === ACTIONS ===
    /**
     * Toggle package expansion
     */
    togglePackage(packageId) {
      const index = this.expandedPackages.indexOf(packageId);
      if (index > -1) {
        this.expandedPackages.splice(index, 1);
      } else {
        this.expandedPackages.push(packageId);
      }
    },
    
    /**
     * Check if package is expanded
     */
    isPackageExpanded(packageId) {
      return this.expandedPackages.includes(packageId);
    },
    
    /**
     * Show package details
     */
    showPackage(packageId) {
      const pkg = this.data.packages[packageId];
      if (!pkg) return;
      
      this.currentView = 'package';
      this.currentPackageId = packageId;
      this.currentClassId = null;
      window.location.hash = `#/packages/${packageId}`;
      
      // Auto-expand package
      if (!this.isPackageExpanded(packageId)) {
        this.togglePackage(packageId);
      }
      
      // Update breadcrumbs
      this.breadcrumbs = [
        { name: 'Packages', url: '#/packages' },
        { name: pkg.name, url: `#/packages/${pkg.id}` }
      ];
    },
    
    /**
     * Show class details
     */
    showClass(classId) {
      const cls = this.data.classes[classId];
      if (!cls) return;
      
      // Find package by checking which package's class list contains this class ID
      let pkg = null;
      for (const [pkgId, pkgData] of Object.entries(this.data.packages)) {
        if (pkgData.classes && pkgData.classes.includes(classId)) {
          pkg = pkgData;
          break;
        }
      }
      
      if (!pkg) return;
      
      this.currentView = 'class';
      this.currentClassId = classId;
      this.currentPackageId = pkg.id;
      
      // Reset schema index when switching classes
      this.selectedSchemaIndex = 0;
      
      window.location.hash = `#/classes/${classId}`;
      
      // Expand package
      if (!this.isPackageExpanded(pkg.id)) {
        this.togglePackage(pkg.id);
      }
      
      // Update breadcrumbs
      this.breadcrumbs = [
        { name: 'Packages', url: '#/packages' },
        { name: pkg.name, url: `#/packages/${pkg.id}` },
        { name: cls.uml_name, url: `#/classes/${cls.id}` }
      ];
    },
    
    /**
     * Handle search input
     */
    handleSearch() {
      if (!this.searchQuery || this.searchQuery.length < 2) {
        this.searchResults = [];
        return;
      }
      
      const query = this.searchQuery.toLowerCase();
      this.searchResults = this.searchIndex.index
        .filter(item => 
          item.title.toLowerCase().includes(query) ||
          item.qualified_name.toLowerCase().includes(query) ||
          (item.keywords && item.keywords.some(k => k.includes(query)))
        )
        .slice(0, 15);
    },
    
    /**
     * Navigate to a search result item
     */
    navigateToResult(type, id) {
      this.searchQuery = '';
      this.searchResults = [];
      
      if (type === 'package') {
        this.showPackage(id);
      } else if (type === 'class') {
        this.showClass(id);
      }
    },
    
    
    /**
     * Handle hash route changes
     */
    handleRouteChange() {
      const hash = window.location.hash;
      
      if (!hash || hash === '#/' || hash === '#/packages') {
        this.currentView = 'welcome';
        this.breadcrumbs = [{ name: 'Packages', url: '#/packages' }];
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
    },
    
    // === HELPERS ===
    /**
     * Get status badge text
     */
    getStatusBadge(status) {
      switch(status) {
        case 'resolved':
          return '✓';
        case 'partial':
          return '⚠';
        case 'unresolved':
          return '✗';
        default:
          return '?';
      }
    },
    
    /**
     * Get status CSS class
     */
    getStatusClass(status) {
      return `badge-${status}`;
    },
    
    /**
     * Get resolution rate color
     */
    getResolutionColor(rate) {
      if (rate >= 90) return 'var(--color-resolved)';
      if (rate >= 50) return 'var(--color-partial)';
      return 'var(--color-unresolved)';
    },
    
    /**
     * Escape HTML to prevent XSS
     */
    escapeHtml(text) {
      if (!text) return '';
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }
  }));
});