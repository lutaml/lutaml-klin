/**
 * Content Renderer Module
 * Renders component details with cross-reference links
 */

import { Utils } from './utils.js';

class ContentRenderer {
  /**
   * Initialize renderer
   * @param {Object} schema - Schema data
   * @param {Object} app - Main application instance
   */
  constructor(schema, app) {
    this.schema = schema;
    this.app = app;
    this.container = document.getElementById('content-body');
  }

  /**
   * Render item by ID
   * @param {string} itemId - Item identifier
   */
  renderItem(itemId) {
    const item = this.getItemById(itemId);
    if (!item) {
      this.renderError(`Item not found: ${itemId}`);
      return;
    }

    // Render based on category
    let html = '';
    switch (item.category) {
      case 'elements':
        html = this.renderElement(item);
        break;
      case 'complex_types':
        html = this.renderComplexType(item);
        break;
      case 'simple_types':
        html = this.renderSimpleType(item);
        break;
      case 'attributes':
        html = this.renderAttribute(item);
        break;
      default:
        html = this.renderGeneric(item);
    }

    this.container.innerHTML = html;
    this.attachEventHandlers();
  }

  /**
   * Render element details
   * @param {Object} element - Element data
   * @returns {string} HTML content
   */
  renderElement(element) {
    return `
      <article class="component-detail element-detail">
        <header class="component-header">
          <h1 class="component-name">
            <span class="prefix">${Utils.escapeHtml(element.prefix)}:</span>${Utils.escapeHtml(element.name)}
          </h1>
          <div class="component-meta">
            <span class="badge category-badge">Element</span>
            ${element.abstract ? '<span class="badge abstract-badge">Abstract</span>' : ''}
            <span class="namespace-badge">${Utils.escapeHtml(element.namespace)}</span>
          </div>
        </header>

        ${element.documentation ? this.renderDocumentation(element.documentation) : ''}
        ${element.type ? this.renderTypeInfo(element) : ''}
        ${element.cross_references ? this.renderCrossReferences(element.cross_references) : ''}
        ${element.uml_mapping ? this.renderUmlMapping(element.uml_mapping, element) : ''}
      </article>
    `;
  }

  /**
   * Render complex type details
   * @param {Object} type - Complex type data
   * @returns {string} HTML content
   */
  renderComplexType(type) {
    return `
      <article class="component-detail type-detail">
        <header class="component-header">
          <h1 class="component-name">
            <span class="prefix">${Utils.escapeHtml(type.prefix)}:</span>${Utils.escapeHtml(type.name)}
          </h1>
          <div class="component-meta">
            <span class="badge category-badge">Complex Type</span>
            ${type.abstract ? '<span class="badge abstract-badge">Abstract</span>' : ''}
          </div>
        </header>

        ${type.documentation ? this.renderDocumentation(type.documentation) : ''}
        ${type.base_type ? this.renderInheritance(type.base_type) : ''}
        ${type.structure ? this.renderStructure(type.structure) : ''}
        ${type.cross_references ? this.renderCrossReferences(type.cross_references) : ''}
        ${type.uml_mapping ? this.renderUmlMapping(type.uml_mapping, type) : ''}
      </article>
    `;
  }

  /**
   * Render simple type details
   * @param {Object} type - Simple type data
   * @returns {string} HTML content
   */
  renderSimpleType(type) {
    return `
      <article class="component-detail type-detail">
        <header class="component-header">
          <h1 class="component-name">
            <span class="prefix">${Utils.escapeHtml(type.prefix)}:</span>${Utils.escapeHtml(type.name)}
          </h1>
          <div class="component-meta">
            <span class="badge category-badge">Simple Type</span>
          </div>
        </header>

        ${type.documentation ? this.renderDocumentation(type.documentation) : ''}
        ${type.base_type ? this.renderBaseType(type.base_type) : ''}
        ${type.restrictions ? this.renderRestrictions(type.restrictions) : ''}
        ${type.cross_references ? this.renderCrossReferences(type.cross_references) : ''}
      </article>
    `;
  }

  /**
   * Render attribute details
   * @param {Object} attribute - Attribute data
   * @returns {string} HTML content
   */
  renderAttribute(attribute) {
    return `
      <article class="component-detail attribute-detail">
        <header class="component-header">
          <h1 class="component-name">
            <span class="prefix">${Utils.escapeHtml(attribute.prefix)}:</span>${Utils.escapeHtml(attribute.name)}
          </h1>
          <div class="component-meta">
            <span class="badge category-badge">Attribute</span>
          </div>
        </header>

        ${attribute.documentation ? this.renderDocumentation(attribute.documentation) : ''}
        ${attribute.type ? this.renderAttributeType(attribute) : ''}
        ${attribute.cross_references ? this.renderCrossReferences(attribute.cross_references) : ''}
      </article>
    `;
  }

  /**
   * Render generic component (fallback)
   * @param {Object} item - Item data
   * @returns {string} HTML content
   */
  renderGeneric(item) {
    return `
      <article class="component-detail">
        <header class="component-header">
          <h1 class="component-name">${Utils.escapeHtml(item.name)}</h1>
        </header>
        ${item.documentation ? this.renderDocumentation(item.documentation) : ''}
      </article>
    `;
  }

  /**
   * Render documentation section
   * @param {string} doc - Documentation text
   * @returns {string} HTML content
   */
  renderDocumentation(doc) {
    return `
      <section class="documentation">
        <h2>Documentation</h2>
        <p>${Utils.escapeHtml(doc)}</p>
      </section>
    `;
  }

  /**
   * Render type information
   * @param {Object} element - Element data
   * @returns {string} HTML content
   */
  renderTypeInfo(element) {
    return `
      <section class="type-info">
        <h2>Type Information</h2>
        <dl>
          <dt>Type:</dt>
          <dd>
            <a href="#" class="type-link" data-ref="${Utils.escapeHtml(element.type)}">
              ${Utils.escapeHtml(element.type)}
            </a>
          </dd>

          ${element.substitution_group ? `
            <dt>Substitution Group:</dt>
            <dd>
              <a href="#" class="type-link" data-ref="${Utils.escapeHtml(element.substitution_group)}">
                ${Utils.escapeHtml(element.substitution_group)}
              </a>
            </dd>
          ` : ''}

          <dt>Cardinality:</dt>
          <dd>${element.min_occurs || 0}..${element.max_occurs || 'unbounded'}</dd>
        </dl>
      </section>
    `;
  }

  /**
   * Render inheritance information
   * @param {string} baseType - Base type
   * @returns {string} HTML content
   */
  renderInheritance(baseType) {
    return `
      <section class="inheritance">
        <h2>Inheritance</h2>
        <p>
          Extends:
          <a href="#" class="type-link" data-ref="${Utils.escapeHtml(baseType)}">
            ${Utils.escapeHtml(baseType)}
          </a>
        </p>
      </section>
    `;
  }

  /**
   * Render base type information
   * @param {string} baseType - Base type
   * @returns {string} HTML content
   */
  renderBaseType(baseType) {
    return `
      <section class="base-type">
        <h2>Base Type</h2>
        <p>
          <a href="#" class="type-link" data-ref="${Utils.escapeHtml(baseType)}">
            ${Utils.escapeHtml(baseType)}
          </a>
        </p>
      </section>
    `;
  }

  /**
   * Render attribute type information
   * @param {Object} attribute - Attribute data
   * @returns {string} HTML content
   */
  renderAttributeType(attribute) {
    return `
      <section class="type-info">
        <h2>Type</h2>
        <p>
          <a href="#" class="type-link" data-ref="${Utils.escapeHtml(attribute.type)}">
            ${Utils.escapeHtml(attribute.type)}
          </a>
        </p>
      </section>
    `;
  }

  /**
   * Render structure information
   * @param {Object} structure - Structure data
   * @returns {string} HTML content
   */
  renderStructure(structure) {
    if (!structure || !structure.elements || structure.elements.length === 0) {
      return '';
    }

    return `
      <section class="structure">
        <h2>Structure</h2>
        <ul class="structure-list">
          ${structure.elements.map(elem => `
            <li>
              <strong>${Utils.escapeHtml(elem.name)}</strong>
              ${elem.type ? `: ${Utils.escapeHtml(elem.type)}` : ''}
              ${elem.cardinality ? ` [${elem.cardinality}]` : ''}
            </li>
          `).join('')}
        </ul>
      </section>
    `;
  }

  /**
   * Render restrictions
   * @param {Object} restrictions - Restrictions data
   * @returns {string} HTML content
   */
  renderRestrictions(restrictions) {
    if (!restrictions) return '';

    return `
      <section class="restrictions">
        <h2>Restrictions</h2>
        <dl>
          ${restrictions.pattern ? `<dt>Pattern:</dt><dd><code>${Utils.escapeHtml(restrictions.pattern)}</code></dd>` : ''}
          ${restrictions.minLength ? `<dt>Min Length:</dt><dd>${restrictions.minLength}</dd>` : ''}
          ${restrictions.maxLength ? `<dt>Max Length:</dt><dd>${restrictions.maxLength}</dd>` : ''}
          ${restrictions.enumeration ? `<dt>Values:</dt><dd>${restrictions.enumeration.map(v => Utils.escapeHtml(v)).join(', ')}</dd>` : ''}
        </dl>
      </section>
    `;
  }

  /**
   * Render cross-references
   * @param {Object} refs - Cross-reference data
   * @returns {string} HTML content
   */
  renderCrossReferences(refs) {
    if (!refs) return '';

    let html = '<section class="cross-references"><h2>Cross References</h2>';

    if (refs.type_ref) {
      html += `
        <div class="ref-section">
          <h3>Type</h3>
          <a href="#" class="ref-link" data-ref="${Utils.escapeHtml(refs.type_ref)}">
            ${Utils.escapeHtml(refs.type_ref)}
          </a>
        </div>
      `;
    }

    if (refs.base_type_ref) {
      html += `
        <div class="ref-section">
          <h3>Base Type</h3>
          <a href="#" class="ref-link" data-ref="${Utils.escapeHtml(refs.base_type_ref)}">
            ${Utils.escapeHtml(refs.base_type_ref)}
          </a>
        </div>
      `;
    }

    if (refs.used_by && refs.used_by.length > 0) {
      html += '<div class="ref-section"><h3>Used By</h3><ul class="ref-list">';
      refs.used_by.forEach(ref => {
        html += `<li><a href="#" class="ref-link" data-ref="${Utils.escapeHtml(ref)}">${Utils.escapeHtml(ref)}</a></li>`;
      });
      html += '</ul></div>';
    }

    if (refs.uses_types && refs.uses_types.length > 0) {
      html += '<div class="ref-section"><h3>Uses Types</h3><ul class="ref-list">';
      refs.uses_types.forEach(ref => {
        html += `<li><a href="#" class="ref-link" data-ref="${Utils.escapeHtml(ref)}">${Utils.escapeHtml(ref)}</a></li>`;
      });
      html += '</ul></div>';
    }

    html += '</section>';
    return html;
  }

  /**
   * Render UML mapping
   * @param {Object} mapping - UML mapping data
   * @param {Object} item - Item data
   * @returns {string} HTML content
   */
  renderUmlMapping(mapping, item) {
    if (!mapping) return '';

    return `
      <section class="uml-mapping">
        <h2>UML Mapping</h2>
        <dl class="mapping-details">
          <dt>UML Class:</dt>
          <dd class="uml-class">${Utils.escapeHtml(mapping.uml_class)}</dd>

          <dt>UML Package:</dt>
          <dd class="uml-package">${Utils.escapeHtml(mapping.uml_package)}</dd>

          <dt>Stereotype:</dt>
          <dd><span class="stereotype-badge">${Utils.escapeHtml(mapping.stereotype)}</span></dd>

          <dt>Resolution Strategy:</dt>
          <dd><span class="strategy-badge">${Utils.escapeHtml(mapping.resolution_strategy)}</span></dd>
        </dl>

        <div class="mapping-diagram">
          <div class="mapping-flow">
            <div class="mapping-source">
              <strong>UML</strong>
              <span>${Utils.escapeHtml(mapping.uml_class)}</span>
            </div>
            <div class="mapping-arrow">
              <span class="strategy-label">${Utils.escapeHtml(mapping.resolution_strategy)}</span>
              →
            </div>
            <div class="mapping-target">
              <strong>XSD</strong>
              <span>${Utils.escapeHtml(item.qualified_name || item.name)}</span>
            </div>
          </div>
        </div>
      </section>
    `;
  }

  /**
   * Render welcome screen
   * @param {Object} schema - Schema data
   */
  renderWelcome(schema) {
    this.container.innerHTML = `
      <div class="welcome-content">
        <h1>${Utils.escapeHtml(schema.name)}</h1>
        <p class="schema-description">${Utils.escapeHtml(schema.description || '')}</p>
        <p class="select-category">Select a category from the sidebar to browse components.</p>
      </div>
    `;
  }

  /**
   * Render category intro
   * @param {string} categoryId - Category identifier
   */
  renderCategoryIntro(categoryId) {
    const intros = {
      'elements': 'XSD elements define the structure of XML documents.',
      'complex-types': 'Complex types define structures with elements and attributes.',
      'simple-types': 'Simple types define data type restrictions and patterns.',
      'attributes': 'Attributes provide additional information for elements.'
    };

    this.container.innerHTML = `
      <div class="category-intro">
        <h1>${this.getCategoryDisplayName(categoryId)}</h1>
        <p>${intros[categoryId] || ''}</p>
        <p>Select an item from the list to view details.</p>
      </div>
    `;
  }

  /**
   * Render error message
   * @param {string} message - Error message
   */
  renderError(message) {
    this.container.innerHTML = `
      <div class="error-message">
        <h1>Error</h1>
        <p>${Utils.escapeHtml(message)}</p>
      </div>
    `;
  }

  /**
   * Attach event handlers to rendered content
   */
  attachEventHandlers() {
    // Attach click handlers to all reference links
    const refLinks = this.container.querySelectorAll('.ref-link, .type-link');

    refLinks.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const ref = link.dataset.ref;
        this.app.navigation.navigateToReference(ref);
      });
    });
  }

  /**
   * Get item by ID
   * @param {string} itemId - Item identifier
   * @returns {Object|null} Item data or null
   */
  getItemById(itemId) {
    return this.schema.elements.find(e => e.id === itemId || e.qualified_name === itemId)
        || this.schema.complex_types.find(t => t.id === itemId || t.qualified_name === itemId)
        || this.schema.simple_types.find(t => t.id === itemId || t.qualified_name === itemId)
        || this.schema.attributes.find(a => a.id === itemId || a.qualified_name === itemId);
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
}

export { ContentRenderer };