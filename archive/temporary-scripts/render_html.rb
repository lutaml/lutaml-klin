#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "erb"

# Load the mapping data
mapping_data = YAML.load_file("uro_mapping_data.yaml")

# HTML template with embedded CSS
html_template = ERB.new(<<~HTML)
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PLATEAU URO Package - UML Class Mapping</title>
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
        grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
        gap: 1.5rem;
      }

      .class-card {
        background: white;
        border: 2px solid #e9ecef;
        border-radius: 12px;
        overflow: hidden;
        transition: all 0.3s;
      }

      .class-card:hover {
        transform: translateY(-4px);
        box-shadow: 0 8px 24px rgba(0,0,0,0.12);
        border-color: #667eea;
      }

      .class-header {
        padding: 1.5rem;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
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

      .class-body {
        padding: 1.5rem;
      }

      .section-title {
        font-size: 0.85rem;
        font-weight: 700;
        text-transform: uppercase;
        color: #666;
        margin-bottom: 0.75rem;
        letter-spacing: 0.5px;
      }

      .attributes-list {
        list-style: none;
        margin-bottom: 1.5rem;
      }

      .attribute-item {
        padding: 0.5rem;
        margin-bottom: 0.25rem;
        background: #f8f9fa;
        border-radius: 6px;
        font-family: 'Monaco', 'Menlo', monospace;
        font-size: 0.85rem;
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

      .associations-list {
        list-style: none;
      }

      .association-item {
        padding: 0.5rem;
        margin-bottom: 0.25rem;
        background: #fff3cd;
        border-left: 3px solid #ffc107;
        border-radius: 4px;
        font-size: 0.85rem;
      }

      .assoc-arrow {
        color: #666;
      }

      .no-items {
        color: #999;
        font-style: italic;
        font-size: 0.9rem;
      }

      .hidden {
        display: none !important;
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
    </style>
  </head>
  <body>
    <div class="container">
      <header>
        <h1>PLATEAU URO Package</h1>
        <div class="subtitle">Urban Object (URO) - UML to XSD Mapping</div>
      </header>

      <div class="summary">
        <div class="stat-card">
          <div class="stat-number"><%= mapping_data[:total_classes] %></div>
          <div class="stat-label">Total Classes</div>
        </div>
        <% mapping_data[:stereotypes].sort_by { |_, count| -count }.each do |stereotype, count| %>
          <div class="stat-card">
            <div class="stat-number"><%= count %></div>
            <div class="stat-label"><%= stereotype %></div>
          </div>
        <% end %>
      </div>

      <div class="controls">
        <div class="search-box">
          <input type="text" id="searchInput" placeholder="🔍 Search classes by name...">
        </div>
        <div class="filter-buttons">
          <button class="filter-btn active" data-filter="all">All</button>
          <% mapping_data[:stereotypes].keys.sort.each do |stereotype| %>
            <button class="filter-btn" data-filter="<%= stereotype %>"><%= stereotype %></button>
          <% end %>
        </div>
      </div>

      <div class="classes-grid" id="classesGrid">
        <% mapping_data[:classes].sort_by { |c| c[:name] }.each do |cls| %>
          <div class="class-card" data-stereotype="<%= cls[:stereotype] %>" data-name="<%= cls[:name].downcase %>">
            <div class="class-header">
              <div class="class-name"><%= cls[:name] %></div>
              <span class="class-stereotype">«<%= cls[:stereotype] %>»</span>
            </div>
            <div class="class-body">
              <% if cls[:attributes].any? %>
                <div class="section-title">Attributes (<%= cls[:attributes].size %>)</div>
                <ul class="attributes-list">
                  <% cls[:attributes].first(5).each do |attr| %>
                    <li class="attribute-item">
                      <span class="attr-name"><%= attr[:name] %></span>:
                      <span class="attr-type"><%= attr[:type] %></span>
                      <span class="attr-multiplicity">[<%= attr[:multiplicity] %>]</span>
                    </li>
                  <% end %>
                  <% if cls[:attributes].size > 5 %>
                    <li class="no-items">... and <%= cls[:attributes].size - 5 %> more</li>
                  <% end %>
                </ul>
              <% else %>
                <div class="section-title">Attributes</div>
                <div class="no-items">No attributes</div>
              <% end %>

              <% if cls[:associations].any? %>
                <div class="section-title">Associations (<%= cls[:associations].size %>)</div>
                <ul class="associations-list">
                  <% cls[:associations].first(3).each do |assoc| %>
                    <li class="association-item">
                      <span class="assoc-arrow">→</span> <%= assoc[:target_class] %>
                      <span class="attr-multiplicity">[<%= assoc[:multiplicity] %>]</span>
                    </li>
                  <% end %>
                  <% if cls[:associations].size > 3 %>
                    <li class="no-items">... and <%= cls[:associations].size - 3 %> more</li>
                  <% end %>
                </ul>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>

      <footer>
        <p><strong>Generated from PLATEAU URO XMI</strong></p>
        <p>Package: <%= mapping_data[:package_name] %> | Classes: <%= mapping_data[:total_classes] %></p>
      </footer>
    </div>

    <script>
      // Search functionality
      const searchInput = document.getElementById('searchInput');
      const classCards = document.querySelectorAll('.class-card');
      const filterButtons = document.querySelectorAll('.filter-btn');

      let currentFilter = 'all';

      searchInput.addEventListener('input', (e) => {
        const searchTerm = e.target.value.toLowerCase();
        filterClasses(searchTerm, currentFilter);
      });

      filterButtons.forEach(btn => {
        btn.addEventListener('click', () => {
          filterButtons.forEach(b => b.classList.remove('active'));
          btn.classList.add('active');
          currentFilter = btn.dataset.filter;
          const searchTerm = searchInput.value.toLowerCase();
          filterClasses(searchTerm, currentFilter);
        });
      });

      function filterClasses(searchTerm, stereotype) {
        classCards.forEach(card => {
          const name = card.dataset.name;
          const cardStereotype = card.dataset.stereotype;
          const matchesSearch = name.includes(searchTerm);
          const matchesFilter = stereotype === 'all' || cardStereotype === stereotype;

          if (matchesSearch && matchesFilter) {
            card.classList.remove('hidden');
          } else {
            card.classList.add('hidden');
          }
        });
      }
    </script>
  </body>
  </html>
HTML

# Render and save
html_output = html_template.result(binding)
output_file = "uro_mapping.html"
File.write(output_file, html_output)

puts "✓ HTML rendered successfully!"
puts "✓ Output saved to: #{output_file}"
puts "\nOpen the file in your browser to view the mapping:"
puts "  open #{output_file}"
