#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "json"

# Load the mapping data
mapping_data = YAML.load_file("uro_mapping_data.yaml")

# Convert to JSON for embedding
json_data = mapping_data.to_json

# Create SPA HTML with embedded JSON
html_content = <<~HTML
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PLATEAU URO Package - UML Class Mapping (SPA)</title>
    <style>
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }

      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        line-height: 1.6;
        color: #333;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        min-height: 100vh;
        padding: 2rem;
      }

      .container {
        max-width: 1400px;
        margin: 0 auto;
        background: white;
        border-radius: 20px;
        box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        overflow: hidden;
      }

      header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 3rem 2rem;
        text-align: center;
      }

      h1 {
        font-size: 2.5rem;
        margin-bottom: 0.5rem;
        font-weight: 700;
      }

      .subtitle {
        font-size: 1.2rem;
        opacity: 0.9;
      }

      .summary {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1.5rem;
        padding: 2rem;
        background: #f8f9fa;
        border-bottom: 3px solid #e9ecef;
      }

      .stat-card {
        background: white;
        padding: 1.5rem;
        border-radius: 12px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        text-align: center;
        transition: transform 0.2s, box-shadow 0.2s;
      }

      .stat-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 4px 16px rgba(0,0,0,0.15);
      }

      .stat-number {
        font-size: 2.5rem;
        font-weight: 700;
        color: #667eea;
        margin-bottom: 0.5rem;
      }

      .stat-label {
        color: #666;
        font-size: 0.9rem;
        text-transform: uppercase;
        letter-spacing: 1px;
      }

      .controls {
        padding: 1.5rem 2rem;
        background: white;
        border-bottom: 1px solid #e9ecef;
        display: flex;
        gap: 1rem;
        flex-wrap: wrap;
        align-items: center;
      }

      .search-box {
        flex: 1;
        min-width: 250px;
      }

      .search-box input {
        width: 100%;
        padding: 0.75rem 1rem;
        border: 2px solid #e9ecef;
        border-radius: 8px;
        font-size: 1rem;
        transition: border-color 0.2s;
      }

      .search-box input:focus {
        outline: none;
        border-color: #667eea;
      }

      .filter-buttons {
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
      }

      .filter-btn {
        padding: 0.75rem 1.5rem;
        border: 2px solid #e9ecef;
        background: white;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.2s;
        font-size: 0.9rem;
        font-weight: 500;
      }

      .filter-btn:hover {
        border-color: #667eea;
        background: #f8f9fa;
      }

      .filter-btn.active {
        background: #667eea;
        color: white;
        border-color: #667eea;
      }

      .classes-grid {
        padding: 2rem;
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
        gap: 1.5rem;
      }

      .class-card {
        background: white;
        border: 2px solid #e9ecef;
        border-radius: 12px;
        overflow: hidden;
        transition: all 0.3s;
        cursor: pointer;
      }

      .class-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 24px rgba(0,0,0,0.12);
        border-color: #667eea;
      }

      .class-card.expanded {
        border-color: #667eea;
        box-shadow: 0 8px 24px rgba(102, 126, 234, 0.2);
      }

      .class-header {
        padding: 1.5rem;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
      }

      .class-header-content {
        flex: 1;
      }

      .class-name {
        font-size: 1.3rem;
        font-weight: 600;
        margin-bottom: 0.5rem;
        word-break: break-word;
      }

      .class-stereotype {
        display: inline-block;
        padding: 0.25rem 0.75rem;
        background: rgba(255,255,255,0.2);
        border-radius: 12px;
        font-size: 0.85rem;
        font-weight: 500;
      }

      .expand-icon {
        font-size: 1.5rem;
        transition: transform 0.3s;
      }

      .class-card.expanded .expand-icon {
        transform: rotate(180deg);
      }

      .class-body {
        padding: 1.5rem;
        max-height: 300px;
        overflow: hidden;
        transition: max-height 0.3s ease;
      }

      .class-card.expanded .class-body {
        max-height: none;
      }

      .section-title {
        font-size: 0.85rem;
        font-weight: 700;
        text-transform: uppercase;
        color: #666;
        margin-bottom: 0.75rem;
        margin-top: 1rem;
        letter-spacing: 0.5px;
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }

      .section-title:first-child {
        margin-top: 0;
      }

      .badge {
        background: #667eea;
        color: white;
        padding: 0.15rem 0.5rem;
        border-radius: 10px;
        font-size: 0.75rem;
        font-weight: 600;
      }

      .attributes-list, .associations-list {
        list-style: none;
      }

      .attribute-item {
        padding: 0.6rem;
        margin-bottom: 0.35rem;
        background: #f8f9fa;
        border-radius: 6px;
        font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
        font-size: 0.85rem;
        border-left: 3px solid #667eea;
      }

      .attr-name {
        color: #667eea;
        font-weight: 600;
      }

      .attr-type {
        color: #e83e8c;
      }

      .attr-multiplicity {
        color: #6c757d;
        font-size: 0.8rem;
      }

      .association-item {
        padding: 0.6rem;
        margin-bottom: 0.35rem;
        background: #fff3cd;
        border-left: 3px solid #ffc107;
        border-radius: 6px;
        font-size: 0.85rem;
      }

      .assoc-arrow {
        color: #666;
        font-weight: bold;
      }

      .no-items {
        color: #999;
        font-style: italic;
        font-size: 0.9rem;
        padding: 0.5rem;
      }

      .hidden {
        display: none !important;
      }

      .loading {
        text-align: center;
        padding: 3rem;
        color: #666;
      }

      .results-count {
        padding: 1rem 2rem;
        background: #f8f9fa;
        border-bottom: 1px solid #e9ecef;
        color: #666;
        font-size: 0.9rem;
      }

      footer {
        padding: 2rem;
        text-align: center;
        color: #666;
        background: #f8f9fa;
        border-top: 1px solid #e9ecef;
      }

      @media (max-width: 768px) {
        body {
          padding: 1rem;
        }

        h1 {
          font-size: 1.8rem;
        }

        .classes-grid {
          grid-template-columns: 1fr;
        }

        .controls {
          flex-direction: column;
        }

        .search-box {
          width: 100%;
        }
      }

      .class-id {
        font-size: 0.75rem;
        opacity: 0.8;
        font-family: monospace;
        margin-top: 0.25rem;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <header>
        <h1>PLATEAU URO Package</h1>
        <div class="subtitle">Urban Object (URO) - UML to XSD Mapping (SPA)</div>
      </header>

      <div class="summary" id="summary">
        <div class="loading">Loading statistics...</div>
      </div>

      <div class="controls">
        <div class="search-box">
          <input type="text" id="searchInput" placeholder="🔍 Search classes by name, type, or attribute...">
        </div>
        <div class="filter-buttons" id="filterButtons">
          <button class="filter-btn active" data-filter="all">All</button>
        </div>
      </div>

      <div class="results-count" id="resultsCount"></div>

      <div class="classes-grid" id="classesGrid">
        <div class="loading">Loading classes...</div>
      </div>

      <footer>
        <p><strong>Generated from PLATEAU URO XMI</strong></p>
        <p id="footerInfo">Loading...</p>
      </footer>
    </div>

    <script>
      // Embedded mapping data
      const MAPPING_DATA = #{json_data};

      // Application state
      let currentFilter = 'all';
      let currentSearch = '';
      let expandedCards = new Set();

      // Initialize the application
      document.addEventListener('DOMContentLoaded', () => {
        renderSummary();
        renderFilterButtons();
        renderClasses();
        setupEventListeners();
        updateResultsCount();
        updateFooter();
      });

      function renderSummary() {
        const summary = document.getElementById('summary');
        const stereotypes = MAPPING_DATA.stereotypes;

        let html = `
          <div class="stat-card">
            <div class="stat-number">${MAPPING_DATA.total_classes}</div>
            <div class="stat-label">Total Classes</div>
          </div>
        `;

        Object.entries(stereotypes)
          .sort((a, b) => b[1] - a[1])
          .forEach(([stereotype, count]) => {
            html += `
              <div class="stat-card">
                <div class="stat-number">${count}</div>
                <div class="stat-label">${stereotype}</div>
              </div>
            `;
          });

        summary.innerHTML = html;
      }

      function renderFilterButtons() {
        const container = document.getElementById('filterButtons');
        const stereotypes = Object.keys(MAPPING_DATA.stereotypes).sort();

        let html = '<button class="filter-btn active" data-filter="all">All</button>';
        stereotypes.forEach(stereotype => {
          html += `<button class="filter-btn" data-filter="${stereotype}">${stereotype}</button>`;
        });

        container.innerHTML = html;
      }

      function renderClasses() {
        const grid = document.getElementById('classesGrid');
        const sortedClasses = [...MAPPING_DATA.classes].sort((a, b) =>
          a.name.localeCompare(b.name)
        );

        const html = sortedClasses.map(cls => createClassCard(cls)).join('');
        grid.innerHTML = html;
      }

      function createClassCard(cls) {
        const isExpanded = expandedCards.has(cls.id);
        const expandedClass = isExpanded ? 'expanded' : '';

        return `
          <div class="class-card ${expandedClass}"
               data-id="${cls.id}"
               data-stereotype="${cls.stereotype}"
               data-name="${cls.name.toLowerCase()}"
               data-search-text="${getSearchText(cls)}">
            <div class="class-header" onclick="toggleCard('${cls.id}')">
              <div class="class-header-content">
                <div class="class-name">${cls.name}</div>
                <span class="class-stereotype">«${cls.stereotype}»</span>
                <div class="class-id">${cls.id}</div>
              </div>
              <div class="expand-icon">${isExpanded ? '▲' : '▼'}</div>
            </div>
            <div class="class-body">
              ${renderAttributes(cls.attributes)}
              ${renderAssociations(cls.associations)}
            </div>
          </div>
        `;
      }

      function renderAttributes(attributes) {
        if (!attributes || attributes.length === 0) {
          return `
            <div class="section-title">Attributes</div>
            <div class="no-items">No attributes</div>
          `;
        }

        const attrList = attributes.map(attr => `
          <li class="attribute-item">
            <span class="attr-name">${attr.name}</span>:
            <span class="attr-type">${attr.type || 'unknown'}</span>
            <span class="attr-multiplicity">[${attr.multiplicity}]</span>
          </li>
        `).join('');

        return `
          <div class="section-title">
            Attributes <span class="badge">${attributes.length}</span>
          </div>
          <ul class="attributes-list">${attrList}</ul>
        `;
      }

      function renderAssociations(associations) {
        if (!associations || associations.length === 0) {
          return '';
        }

        const assocList = associations.map(assoc => `
          <li class="association-item">
            <span class="assoc-arrow">→</span> ${assoc.target_class}
            <span class="attr-multiplicity">[${assoc.multiplicity}]</span>
          </li>
        `).join('');

        return `
          <div class="section-title">
            Associations <span class="badge">${associations.length}</span>
          </div>
          <ul class="associations-list">${assocList}</ul>
        `;
      }

      function getSearchText(cls) {
        const attrText = (cls.attributes || [])
          .map(a => `${a.name} ${a.type}`)
          .join(' ');
        const assocText = (cls.associations || [])
          .map(a => a.target_class)
          .join(' ');
        return `${cls.name} ${cls.stereotype} ${attrText} ${assocText}`.toLowerCase();
      }

      function toggleCard(id) {
        if (expandedCards.has(id)) {
          expandedCards.delete(id);
        } else {
          expandedCards.add(id);
        }

        const card = document.querySelector(`[data-id="${id}"]`);
        card.classList.toggle('expanded');
      }

      function setupEventListeners() {
        const searchInput = document.getElementById('searchInput');
        searchInput.addEventListener('input', (e) => {
          currentSearch = e.target.value.toLowerCase();
          filterClasses();
        });

        const filterButtons = document.querySelectorAll('.filter-btn');
        filterButtons.forEach(btn => {
          btn.addEventListener('click', () => {
            filterButtons.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentFilter = btn.dataset.filter;
            filterClasses();
          });
        });
      }

      function filterClasses() {
        const cards = document.querySelectorAll('.class-card');
        let visibleCount = 0;

        cards.forEach(card => {
          const name = card.dataset.name;
          const stereotype = card.dataset.stereotype;
          const searchText = card.dataset.searchText;

          const matchesSearch = searchText.includes(currentSearch);
          const matchesFilter = currentFilter === 'all' || stereotype === currentFilter;

          if (matchesSearch && matchesFilter) {
            card.classList.remove('hidden');
            visibleCount++;
          } else {
            card.classList.add('hidden');
          }
        });

        updateResultsCount(visibleCount);
      }

      function updateResultsCount(count = MAPPING_DATA.total_classes) {
        const resultsCount = document.getElementById('resultsCount');
        resultsCount.textContent = `Showing ${count} of ${MAPPING_DATA.total_classes} classes`;
      }

      function updateFooter() {
        const footer = document.getElementById('footerInfo');
        footer.textContent = `Package: ${MAPPING_DATA.package_name} | Classes: ${MAPPING_DATA.total_classes}`;
      }
    </script>
  </body>
  </html>
HTML

# Write the HTML file
output_file = "uro_mapping_spa.html"
File.write(output_file, html_content)

puts "✓ SPA HTML rendered successfully!"
puts "✓ Output saved to: #{output_file}"
puts "✓ Full data embedded as JSON (#{json_data.length} bytes)"
puts "\nFeatures:"
puts "  - All #{mapping_data[:total_classes]} classes with complete details"
puts "  - Click any class card to expand/collapse"
puts "  - Search across all attributes and associations"
puts "  - Filter by stereotype"
puts "  - No truncation - see all data"
puts "\nOpen the file:"
puts "  open #{output_file}"
