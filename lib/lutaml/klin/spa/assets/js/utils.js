/**
 * Utility Functions Module
 * Common helpers for string manipulation, escaping, formatting
 */

class Utils {
  /**
   * HTML escape to prevent XSS
   * @param {string} text - Text to escape
   * @returns {string} Escaped HTML
   */
  static escapeHtml(text) {
    if (!text) return '';

    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  /**
   * Highlight search matches in text
   * @param {string} text - Text to highlight
   * @param {string} query - Search query
   * @returns {string} HTML with highlighted matches
   */
  static highlightMatch(text, query) {
    if (!query) return this.escapeHtml(text);

    const escaped = this.escapeHtml(text);
    const regex = new RegExp(`(${this.escapeRegex(query)})`, 'gi');

    return escaped.replace(regex, '<mark>$1</mark>');
  }

  /**
   * Escape regex special characters
   * @param {string} text - Text to escape
   * @returns {string} Escaped regex
   */
  static escapeRegex(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  /**
   * Debounce function
   * @param {Function} func - Function to debounce
   * @param {number} wait - Wait time in milliseconds
   * @returns {Function} Debounced function
   */
  static debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }

  /**
   * Format date
   * @param {string} dateString - Date string to format
   * @returns {string} Formatted date
   */
  static formatDate(dateString) {
    if (!dateString) return '';

    const date = new Date(dateString);
    return date.toLocaleDateString(undefined, {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  }

  /**
   * Truncate text
   * @param {string} text - Text to truncate
   * @param {number} maxLength - Maximum length
   * @returns {string} Truncated text
   */
  static truncate(text, maxLength) {
    if (!text || text.length <= maxLength) return text;
    return text.substring(0, maxLength - 3) + '...';
  }
}

export { Utils };