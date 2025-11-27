# frozen_string_literal: true

require "json"
require "fileutils"
require_relative "../domain/services/spa_generator"

module Lutaml
  module Klin
    module Application
      # SpaWorkflow orchestrates the generation of a Single Page Application
      # for browsing UML-to-XSD mappings.
      #
      # This is the main application layer component that coordinates:
      # - Creating output directory structure
      # - Generating JSON data files
      # - Copying HTML/CSS/JS assets
      # - Managing file I/O operations
      #
      # The workflow follows these principles:
      # - **Pure orchestration** - delegates business logic to SpaGenerator
      # - **I/O handling** - this layer handles all file operations
      # - **Error handling** - comprehensive error reporting
      #
      # @example Basic usage
      #   workflow = SpaWorkflow.new
      #   output_path = workflow.generate_spa(
      #     schema_mapping,
      #     "output/spa",
      #     title: "My UML-XSD Mappings"
      #   )
      #   puts "SPA generated at #{output_path}"
      class SpaWorkflow
        # @return [SpaGenerator] The SPA generator service
        attr_reader :spa_generator

        # Template directory path (relative to this file)
        TEMPLATE_DIR = File.expand_path("../../templates/spa", __dir__)

        # Initialize the SPA workflow
        #
        # @param spa_generator [SpaGenerator] Optional custom SPA generator
        def initialize(spa_generator: nil)
          @spa_generator = spa_generator ||
                           Domain::Services::SpaGenerator.new
        end

        # Generate a complete SPA for the given schema mapping
        #
        # This method:
        # 1. Creates output directory structure (_site by default)
        # 2. Generates JSON data files
        # 3. Copies HTML/CSS/JS assets with embedded or linked data
        # 4. Returns the output directory path
        #
        # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
        # @param output_path [String] Output directory path (defaults to "_site")
        # @param options [Hash] Additional options
        # @option options [String] :title Custom title for the SPA
        # @option options [String] :description Custom description
        # @option options [Symbol] :data_mode :embedded (default) or :linked
        # @return [String] Path to the generated SPA directory
        #
        # @raise [RuntimeError] if generation fails
        #
        # @example Generate with embedded data (default, works with file://)
        #   workflow.generate_spa(mapping, "_site")
        #
        # @example Generate with linked data (requires HTTP server)
        #   workflow.generate_spa(mapping, "_site", data_mode: :linked)
        def generate_spa(schema_mapping, output_path = "_site", options = {})
          # Default to embedded mode for better out-of-the-box experience
          options[:data_mode] ||= :embedded

          # 1. Create directory structure
          create_directories(output_path)

          # 2. Generate JSON data files (always, for linked mode or backup)
          data_files = generate_data_files(schema_mapping, output_path)

          # 3. Generate/copy HTML/CSS/JS assets
          generate_assets(output_path, data_files, options)

          output_path
        rescue StandardError => e
          raise "Failed to generate SPA: #{e.message}"
        end

        private

        # Create the output directory structure
        #
        # Creates:
        # - output_path/
        # - output_path/data/
        # - output_path/assets/
        # - output_path/assets/css/
        # - output_path/assets/js/
        #
        # @param output_path [String] Base output path
        def create_directories(output_path)
          FileUtils.mkdir_p(output_path)
          FileUtils.mkdir_p(File.join(output_path, "data"))
          FileUtils.mkdir_p(File.join(output_path, "assets", "css"))
          FileUtils.mkdir_p(File.join(output_path, "assets", "js"))
        end

        # Generate JSON data files
        #
        # Creates:
        # - data/mappings.json - Complete mapping data
        # - data/search_index.json - Search index
        # - data/statistics.json - Statistics summary
        #
        # @param schema_mapping [Mapping::SchemaMapping] The schema mapping
        # @param output_path [String] Base output path
        # @return [Hash] Generated data structures
        def generate_data_files(schema_mapping, output_path)
          data_dir = File.join(output_path, "data")

          # Generate mappings.json
          mappings_data = spa_generator.generate_mappings_json(schema_mapping)
          write_json_file(
            File.join(data_dir, "mappings.json"),
            mappings_data
          )

          # Generate search_index.json
          search_index = spa_generator.generate_search_index(schema_mapping)
          write_json_file(
            File.join(data_dir, "search_index.json"),
            search_index
          )

          # Generate statistics.json
          statistics = spa_generator.generate_statistics(schema_mapping)
          write_json_file(
            File.join(data_dir, "statistics.json"),
            statistics
          )

          # Return data for embedding if needed
          {
            mappings: mappings_data,
            search_index: search_index,
            statistics: statistics
          }
        end

        # Generate or copy HTML/CSS/JS assets
        #
        # If templates exist, copies them. Otherwise, generates minimal assets.
        #
        # @param output_path [String] Base output path
        # @param data_files [Hash] Generated data structures
        # @param options [Hash] Generation options
        def generate_assets(output_path, data_files, options)
          if templates_exist?
            copy_templates(output_path, data_files, options)
          else
            generate_minimal_assets(output_path, data_files, options)
          end
        end

        # Check if template files exist
        #
        # @return [Boolean] true if template directory exists
        def templates_exist?
          File.directory?(TEMPLATE_DIR)
        end

        # Copy template files to output directory and inject data
        #
        # @param output_path [String] Base output path
        # @param data_files [Hash] Generated data structures
        # @param options [Hash] Options (e.g., title, data_mode)
        def copy_templates(output_path, data_files, options)
          # Read template HTML
          template_html = File.read(File.join(TEMPLATE_DIR, "index.html"))

          # Inject data based on mode
          html_with_data = if options[:data_mode] == :embedded
            # Embedded mode - inject JSON directly into HTML
            template_html
                             .gsub("%<MAPPINGS_JSON>s", JSON.generate(data_files[:mappings]))
                             .gsub("%<SEARCH_INDEX_JSON>s", JSON.generate(data_files[:search_index]))
                             .gsub("%<STATISTICS_JSON>s", JSON.generate(data_files[:statistics]))
          else
            # Linked mode - use empty placeholders, load from files
            template_html
                             .gsub("%<MAPPINGS_JSON>s", "{}")
                             .gsub("%<SEARCH_INDEX_JSON>s", "{}")
                             .gsub("%<STATISTICS_JSON>s", "{}")
                           end

          # Write HTML
          File.write(File.join(output_path, "index.html"), html_with_data)

          # Copy CSS
          css_source = File.join(TEMPLATE_DIR, "assets", "css", "style.css")
          if File.exist?(css_source)
            FileUtils.cp(
              css_source,
              File.join(output_path, "assets", "css", "style.css")
            )
          end

          # Copy JavaScript
          js_source = File.join(TEMPLATE_DIR, "assets", "js", "app.js")
          return unless File.exist?(js_source)

          FileUtils.cp(
            js_source,
            File.join(output_path, "assets", "js", "app.js")
          )
        end

        # Generate minimal HTML/CSS/JS assets inline
        #
        # Used as fallback when templates don't exist.
        #
        # @param output_path [String] Base output path
        # @param data_files [Hash] Generated data structures
        # @param options [Hash] Generation options
        def generate_minimal_assets(output_path, data_files, options)
          title = options[:title] || "UML-XSD Mapping Browser"
          data_mode = options[:data_mode] || :embedded

          # Generate minimal index.html with embedded data
          html_content = generate_minimal_html(title, data_files, data_mode)
          File.write(
            File.join(output_path, "index.html"),
            html_content
          )

          # Generate minimal CSS
          css_content = generate_minimal_css
          File.write(
            File.join(output_path, "assets", "css", "style.css"),
            css_content
          )

          # Generate minimal JavaScript
          js_content = generate_minimal_js
          File.write(
            File.join(output_path, "assets", "js", "app.js"),
            js_content
          )
        end

        # Generate minimal HTML content
        #
        # @param title [String] Page title
        # @param data_files [Hash] Generated data structures
        # @param data_mode [Symbol] :embedded or :linked
        # @return [String] HTML content
        def generate_minimal_html(title, data_files, data_mode)
          # Prepare data injection
          data_script = if data_mode == :embedded
                          <<~SCRIPT
                            <script id="embedded-data">
                              window.MAPPING_DATA = #{JSON.generate(data_files[:mappings])};
                              window.SEARCH_INDEX = #{JSON.generate(data_files[:search_index])};
                              window.STATISTICS = #{JSON.generate(data_files[:statistics])};
                            </script>
                          SCRIPT
                        else
                          "<script id=\"embedded-data\">/* Data loaded from separate files */</script>"
                        end

          <<~HTML
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>#{title}</title>
              <link rel="stylesheet" href="assets/css/style.css">
              #{data_script}
            </head>
            <body>
              <div id="app">
                <header>
                  <h1>#{title}</h1>
                  <div class="search-container">
                    <input type="text" id="search" placeholder="Search classes, attributes..." autocomplete="off">
                    <div id="search-results" class="search-results hidden"></div>
                  </div>
                </header>

                <div class="main-content">
                  <aside class="sidebar">
                    <h2>Packages</h2>
                    <div id="package-tree"></div>

                    <h2>Filters</h2>
                    <div class="filters">
                      <label><input type="checkbox" id="filter-resolved" checked> ✓ Resolved</label>
                      <label><input type="checkbox" id="filter-partial" checked> ⚠ Partial</label>
                      <label><input type="checkbox" id="filter-unresolved" checked> ✗ Unresolved</label>
                    </div>

                    <h2>Statistics</h2>
                    <div id="statistics"></div>
                  </aside>

                  <main class="content">
                    <div id="breadcrumb"></div>
                    <div id="details">
                      <p class="welcome">Select a package or class to view details.</p>
                    </div>
                  </main>
                </div>
              </div>

              <script src="assets/js/app.js"></script>
            </body>
            </html>
          HTML
        end

        # Generate minimal CSS content
        #
        # @return [String] CSS content
        def generate_minimal_css
          <<~CSS
            /* Root variables */
            :root {
              --color-resolved: #28a745;
              --color-partial: #ffc107;
              --color-unresolved: #dc3545;
              --color-bg: #ffffff;
              --color-bg-alt: #f8f9fa;
              --color-text: #212529;
              --color-border: #dee2e6;
              --color-primary: #007bff;
            }

            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }

            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
              color: var(--color-text);
              background-color: var(--color-bg);
              line-height: 1.6;
            }

            header {
              background-color: var(--color-primary);
              color: white;
              padding: 1rem 2rem;
              box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            }

            header h1 {
              margin-bottom: 0.5rem;
              font-size: 1.5rem;
            }

            .search-container {
              position: relative;
              max-width: 600px;
            }

            #search {
              width: 100%;
              padding: 0.5rem 1rem;
              border: none;
              border-radius: 4px;
              font-size: 1rem;
            }

            .search-results {
              position: absolute;
              top: 100%;
              left: 0;
              right: 0;
              background: white;
              border: 1px solid var(--color-border);
              border-radius: 4px;
              margin-top: 0.5rem;
              max-height: 400px;
              overflow-y: auto;
              box-shadow: 0 4px 6px rgba(0,0,0,0.1);
              z-index: 100;
            }

            .search-results.hidden {
              display: none;
            }

            .main-content {
              display: grid;
              grid-template-columns: 300px 1fr;
              gap: 0;
              min-height: calc(100vh - 100px);
            }

            .sidebar {
              background-color: var(--color-bg-alt);
              padding: 1.5rem;
              border-right: 1px solid var(--color-border);
              overflow-y: auto;
            }

            .sidebar h2 {
              font-size: 1.1rem;
              margin: 1.5rem 0 0.75rem 0;
              padding-bottom: 0.5rem;
              border-bottom: 2px solid var(--color-border);
            }

            .sidebar h2:first-child {
              margin-top: 0;
            }

            .filters label {
              display: block;
              margin: 0.5rem 0;
              cursor: pointer;
            }

            .filters input[type="checkbox"] {
              margin-right: 0.5rem;
            }

            .content {
              padding: 2rem;
              overflow-y: auto;
            }

            .badge-resolved { color: var(--color-resolved); font-weight: bold; }
            .badge-partial { color: var(--color-partial); font-weight: bold; }
            .badge-unresolved { color: var(--color-unresolved); font-weight: bold; }

            .package-item, .class-item {
              cursor: pointer;
              padding: 0.5rem;
              margin: 0.25rem 0;
              border-radius: 4px;
              transition: background-color 0.2s;
            }

            .package-item:hover, .class-item:hover {
              background-color: rgba(0,0,0,0.05);
            }

            .class-item {
              margin-left: 1rem;
              font-size: 0.9rem;
            }

            table {
              width: 100%;
              border-collapse: collapse;
              margin: 1rem 0;
            }

            th, td {
              padding: 0.75rem;
              text-align: left;
              border-bottom: 1px solid var(--color-border);
            }

            th {
              background-color: var(--color-bg-alt);
              font-weight: 600;
            }

            .welcome {
              color: #6c757d;
              font-style: italic;
            }

            @media (max-width: 768px) {
              .main-content {
                grid-template-columns: 1fr;
              }

              .sidebar {
                border-right: none;
                border-bottom: 1px solid var(--color-border);
              }
            }
          CSS
        end

        # Generate minimal JavaScript content
        #
        # @return [String] JavaScript content
        def generate_minimal_js
          <<~JS
            class MappingBrowserApp {
              constructor() {
                this.data = null;
                this.searchIndex = null;
                this.statistics = null;
                this.currentView = 'packages';
              }

              async init() {
                try {
                  await this.loadData();
                  this.setupEventListeners();
                  this.renderPackageTree();
                  this.renderStatistics();
                } catch (error) {
                  console.error('Failed to initialize app:', error);
                  document.getElementById('details').innerHTML = '<p class="error">Failed to load data. Please check the console for details.</p>';
                }
              }

              async loadData() {
                const [mappings, searchIndex, statistics] = await Promise.all([
                  fetch('data/mappings.json').then(r => r.json()),
                  fetch('data/search_index.json').then(r => r.json()),
                  fetch('data/statistics.json').then(r => r.json())
                ]);

                this.data = mappings;
                this.searchIndex = searchIndex;
                this.statistics = statistics;
              }

              setupEventListeners() {
                const searchInput = document.getElementById('search');
                searchInput.addEventListener('input', (e) => this.handleSearch(e.target.value));

                document.getElementById('filter-resolved').addEventListener('change', () => this.filterByStatus());
                document.getElementById('filter-partial').addEventListener('change', () => this.filterByStatus());
                document.getElementById('filter-unresolved').addEventListener('change', () => this.filterByStatus());
              }

              renderPackageTree() {
                const tree = document.getElementById('package-tree');
                tree.innerHTML = this.data.packages.map(pkg => `
                  <div class="package-item" onclick="app.showPackage('${pkg.id}')">
                    📦 ${pkg.name}
                  </div>
                `).join('');
              }

              renderStatistics() {
                const statsDiv = document.getElementById('statistics');
                const summary = this.statistics.summary;

                statsDiv.innerHTML = `
                  <div class="stats-summary">
                    <p><strong>Packages:</strong> ${summary.total_packages}</p>
                    <p><strong>Classes:</strong> ${summary.resolved_classes}/${summary.total_classes}</p>
                    <p><strong>Attributes:</strong> ${summary.resolved_attributes}/${summary.total_attributes}</p>
                    <p><strong>Resolution Rate:</strong> ${summary.resolution_rate.toFixed(1)}%</p>
                  </div>
                `;
              }

              showPackage(packageId) {
                const pkg = this.data.packages.find(p => p.id === packageId);
                if (!pkg) return;

                const details = document.getElementById('details');
                details.innerHTML = `
                  <h2>${pkg.name}</h2>
                  <p><strong>Namespace:</strong> ${pkg.namespace}</p>
                  <h3>Classes</h3>
                  <div class="classes-list">
                    ${pkg.classes.map(cls => `
                      <div class="class-item" onclick="app.showClass('${cls.id}')">
                        ${this.getStatusBadge(cls.resolution_status)} ${cls.uml_name}
                      </div>
                    `).join('')}
                  </div>
                `;
              }

              showClass(classId) {
                let cls = null;
                for (const pkg of this.data.packages) {
                  cls = pkg.classes.find(c => c.id === classId);
                  if (cls) break;
                }

                if (!cls) return;

                const details = document.getElementById('details');
                details.innerHTML = `
                  <h2>${cls.uml_name} ${this.getStatusBadge(cls.resolution_status)}</h2>
                  <p><strong>XSD Type:</strong> ${cls.xsd_type_name || 'N/A'}</p>
                  <p><strong>Resolution Method:</strong> ${cls.resolution_method || 'N/A'}</p>
                  ${cls.uml_documentation ? `<p><em>${cls.uml_documentation}</em></p>` : ''}

                  <h3>Attributes</h3>
                  <table>
                    <thead>
                      <tr>
                        <th>UML Name</th>
                        <th>UML Type</th>
                        <th>XSD Type</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      ${cls.attributes.map(attr => `
                        <tr>
                          <td>${attr.uml_name}</td>
                          <td>${attr.uml_type || 'N/A'}</td>
                          <td>${attr.xsd_type || 'N/A'}</td>
                          <td>${this.getStatusBadge(attr.resolution_status)}</td>
                        </tr>
                      `).join('')}
                    </tbody>
                  </table>
                `;
              }

              getStatusBadge(status) {
                switch(status) {
                  case 'resolved': return '<span class="badge-resolved">✓</span>';
                  case 'partial': return '<span class="badge-partial">⚠</span>';
                  default: return '<span class="badge-unresolved">✗</span>';
                }
              }

              handleSearch(query) {
                if (!query || query.length < 2) {
                  document.getElementById('search-results').classList.add('hidden');
                  return;
                }

                const results = this.searchIndex.index.filter(item =>
                  item.title.toLowerCase().includes(query.toLowerCase()) ||
                  item.keywords.some(k => k.includes(query.toLowerCase()))
                ).slice(0, 10);

                const resultsDiv = document.getElementById('search-results');
                if (results.length === 0) {
                  resultsDiv.innerHTML = '<div style="padding: 1rem;">No results found</div>';
                } else {
                  resultsDiv.innerHTML = results.map(item => `
                    <div class="search-result-item" style="padding: 0.75rem; border-bottom: 1px solid #ddd; cursor: pointer;"
                         onclick="app.navigateToItem('${item.type}', '${item.id}')">
                      <strong>${item.title}</strong> <span style="color: #666;">(${item.type})</span>
                    </div>
                  `).join('');
                }
                resultsDiv.classList.remove('hidden');
              }

              navigateToItem(type, id) {
                document.getElementById('search-results').classList.add('hidden');
                document.getElementById('search').value = '';

                if (type === 'package') {
                  this.showPackage(id);
                } else if (type === 'class') {
                  this.showClass(id);
                }
              }

              filterByStatus() {
                // TODO: Implement filtering
                console.log('Filter status changed');
              }
            }

            // Initialize app when DOM is ready
            let app;
            document.addEventListener('DOMContentLoaded', () => {
              app = new MappingBrowserApp();
              app.init();
            });
          JS
        end

        # Write JSON data to file with pretty formatting
        #
        # @param path [String] File path
        # @param data [Hash] Data to write
        def write_json_file(path, data)
          File.write(path, JSON.pretty_generate(data))
        end
      end
    end
  end
end
