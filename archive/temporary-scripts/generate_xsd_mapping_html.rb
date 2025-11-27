#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "cgi"
require "fileutils"

puts "=" * 80
puts "PLATEAU XSD Mapping HTML Generator"
puts "=" * 80
puts

# Load the JSON data
json_file = "plateau_xsd_mapping/plateau_xsd_mapping.json"
unless File.exist?(json_file)
  puts "❌ Error: #{json_file} not found"
  puts "Please run generate_full_xsd_mapping.rb first"
  exit 1
end

data = JSON.parse(File.read(json_file))
metadata = data["metadata"]
packages = data["packages"]

puts "Loaded mapping data:"
puts "  Packages: #{metadata['total_packages']}"
puts "  Total Attributes: #{metadata['total_attributes']}"
puts "  Resolution Rate: #{metadata['resolution_rate']}%"
puts

# Create HTML output directory
output_dir = "plateau_xsd_mapping/html"
FileUtils.mkdir_p(output_dir)

# Generate index page
puts "Generating index page..."
index_html = <<~HTML
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PLATEAU UML-to-XSD Mapping Report</title>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        line-height: 1.6;
        color: #333;
        background: #f5f5f5;
      }
      .container {
        max-width: 1400px;
        margin: 0 auto;
        padding: 20px;
      }
      header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 40px 20px;
        margin-bottom: 30px;
        border-radius: 10px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      }
      h1 { font-size: 2.5em; margin-bottom: 10px; }
      .meta-info {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
        gap: 20px;
        margin: 20px 0;
      }
      .meta-card {
        background: white;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      .meta-label { font-size: 0.9em; color: #666; margin-bottom: 5px; }
      .meta-value { font-size: 1.8em; font-weight: bold; color: #667eea; }
      .resolution-bar {
        height: 30px;
        background: #e0e0e0;
        border-radius: 15px;
        overflow: hidden;
        margin-top: 10px;
      }
      .resolution-fill {
        height: 100%;
        background: linear-gradient(90deg, #4caf50 0%, #8bc34a 100%);
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-weight: bold;
        font-size: 0.9em;
      }
      .packages-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
        gap: 20px;
        margin-top: 30px;
      }
      .package-card {
        background: white;
        border-radius: 8px;
        padding: 20px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        transition: transform 0.2s, box-shadow 0.2s;
        text-decoration: none;
        color: inherit;
        display: block;
      }
      .package-card:hover {
        transform: translateY(-5px);
        box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      }
      .package-name {
        font-size: 1.3em;
        font-weight: bold;
        color: #667eea;
        margin-bottom: 15px;
      }
      .package-stats {
        display: flex;
        justify-content: space-between;
        margin-top: 15px;
        padding-top: 15px;
        border-top: 1px solid #eee;
      }
      .stat {
        text-align: center;
      }
      .stat-value {
        font-size: 1.5em;
        font-weight: bold;
        color: #333;
      }
      .stat-label {
        font-size: 0.8em;
        color: #666;
        margin-top: 5px;
      }
      .unresolved-badge {
        background: #ff9800;
        color: white;
        padding: 2px 8px;
        border-radius: 12px;
        font-size: 0.8em;
        font-weight: bold;
      }
      footer {
        text-align: center;
        margin-top: 40px;
        padding: 20px;
        color: #666;
        font-size: 0.9em;
      }
    </style>
  </head>
  <body>
    <div class="container">
      <header>
        <h1>🏗️ PLATEAU UML-to-XSD Mapping Report</h1>
        <p>Comprehensive analysis of UML model to XSD schema mappings</p>
        <p style="margin-top: 10px; opacity: 0.9;">
          Generated: #{metadata['generated_at']}
        </p>
      </header>

      <div class="meta-info">
        <div class="meta-card">
          <div class="meta-label">Total Packages</div>
          <div class="meta-value">#{metadata['total_packages']}</div>
        </div>
        <div class="meta-card">
          <div class="meta-label">Total Attributes</div>
          <div class="meta-value">#{metadata['total_attributes']}</div>
        </div>
        <div class="meta-card">
          <div class="meta-label">Resolved Attributes</div>
          <div class="meta-value">#{metadata['resolved_attributes']}</div>
        </div>
        <div class="meta-card">
          <div class="meta-label">Unresolved Attributes</div>
          <div class="meta-value" style="color: #ff9800;">#{metadata['unresolved_attributes']}</div>
        </div>
      </div>

      <div class="meta-card">
        <div class="meta-label">Resolution Rate</div>
        <div class="resolution-bar">
          <div class="resolution-fill" style="width: #{metadata['resolution_rate']}%">
            #{metadata['resolution_rate']}%
          </div>
        </div>
      </div>

      <h2 style="margin-top: 40px; margin-bottom: 20px; color: #333;">📦 Packages</h2>
      <div class="packages-grid">
HTML

packages.each do |pkg_name, pkg_data|
  total_attrs = pkg_data["classes"].sum { |c| c["attributes"].size }
  unresolved = pkg_data["classes"].sum { |c| c["unresolved_count"] }
  resolution_rate = total_attrs.positive? ? ((total_attrs - unresolved) * 100.0 / total_attrs).round(1) : 0

  # Escape package name for filename
  safe_name = pkg_name.gsub(/[^a-zA-Z0-9_-]/, "_")
  filename = "package_#{safe_name}.html"

  index_html += <<~HTML
    <a href="#{filename}" class="package-card">
      <div class="package-name">#{CGI.escapeHTML(pkg_name)}</div>
      <div class="package-stats">
        <div class="stat">
          <div class="stat-value">#{pkg_data['class_count']}</div>
          <div class="stat-label">Classes</div>
        </div>
        <div class="stat">
          <div class="stat-value">#{total_attrs}</div>
          <div class="stat-label">Attributes</div>
        </div>
        <div class="stat">
          <div class="stat-value">
            #{resolution_rate}%
          </div>
          <div class="stat-label">Resolved</div>
        </div>
      </div>
      #{if unresolved.positive?
          "<div style='margin-top: 10px;'><span class='unresolved-badge'>#{unresolved} Unresolved</span></div>"
        end}
    </a>
  HTML
end

index_html += <<~HTML
      </div>

      <footer>
        <p>Generated by lutaml-klin | XMI: #{File.basename(metadata['xmi_file'])}</p>
      </footer>
    </div>
  </body>
  </html>
HTML

File.write(File.join(output_dir, "index.html"), index_html)
puts "  ✓ Generated index.html"

# Generate individual package pages
packages.each do |pkg_name, pkg_data|
  safe_name = pkg_name.gsub(/[^a-zA-Z0-9_-]/, "_")
  filename = "package_#{safe_name}.html"

  puts "  Generating #{filename}..."

  package_html = <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>#{CGI.escapeHTML(pkg_name)} - PLATEAU Mapping</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          line-height: 1.6;
          color: #333;
          background: #f5f5f5;
        }
        .container {
          max-width: 1400px;
          margin: 0 auto;
          padding: 20px;
        }
        header {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          padding: 30px 20px;
          margin-bottom: 30px;
          border-radius: 10px;
        }
        .breadcrumb {
          margin-bottom: 10px;
          opacity: 0.9;
        }
        .breadcrumb a {
          color: white;
          text-decoration: none;
        }
        .breadcrumb a:hover {
          text-decoration: underline;
        }
        h1 { font-size: 2em; }
        .class-card {
          background: white;
          border-radius: 8px;
          padding: 20px;
          margin-bottom: 20px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .class-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 15px;
          padding-bottom: 15px;
          border-bottom: 2px solid #667eea;
        }
        .class-name {
          font-size: 1.4em;
          font-weight: bold;
          color: #667eea;
        }
        .stereotype-badge {
          background: #e3f2fd;
          color: #1976d2;
          padding: 4px 12px;
          border-radius: 12px;
          font-size: 0.9em;
        }
        .attributes-table {
          width: 100%;
          border-collapse: collapse;
          margin-top: 15px;
        }
        .attributes-table th {
          text-align: left;
          padding: 10px;
          background: #f5f5f5;
          font-weight: 600;
          border-bottom: 2px solid #ddd;
        }
        .attributes-table td {
          padding: 10px;
          border-bottom: 1px solid #eee;
        }
        .resolved {
          background: #e8f5e9;
        }
        .unresolved {
          background: #fff3e0;
        }
        .status-badge {
          padding: 2px 8px;
          border-radius: 10px;
          font-size: 0.85em;
          font-weight: bold;
        }
        .badge-resolved {
          background: #4caf50;
          color: white;
        }
        .badge-unresolved {
          background: #ff9800;
          color: white;
        }
        .type-info {
          font-family: 'Courier New', monospace;
          font-size: 0.9em;
          color: #666;
        }
        .resolution-path {
          font-size: 0.85em;
          color: #4caf50;
          font-style: italic;
          margin-top: 5px;
        }
        footer {
          text-align: center;
          margin-top: 40px;
          padding: 20px;
          color: #666;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <header>
          <div class="breadcrumb">
            <a href="index.html">← Back to All Packages</a>
          </div>
          <h1>📦 #{CGI.escapeHTML(pkg_name)}</h1>
          <p>#{pkg_data['class_count']} classes</p>
        </header>

        <div id="classes">
  HTML

  pkg_data["classes"].each do |cls|
    next unless cls["name"] # Skip classes without names

    package_html += <<~HTML
      <div class="class-card">
        <div class="class-header">
          <div class="class-name">#{CGI.escapeHTML(cls['name'])}</div>
          #{if cls['stereotype']
              "<div class='stereotype-badge'>«#{CGI.escapeHTML(cls['stereotype'])}»</div>"
            end}
        </div>

        #{if cls['attributes'].empty?
            "<p style='color: #999;'>No attributes</p>"
          end}
    HTML

    unless cls["attributes"].empty?
      package_html += <<~HTML
        <table class="attributes-table">
          <thead>
            <tr>
              <th>Attribute</th>
              <th>UML Type</th>
              <th>Multiplicity</th>
              <th>XSD Resolution</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
      HTML

      cls["attributes"].each do |attr|
        row_class = attr["resolved"] ? "resolved" : "unresolved"
        badge_class = attr["resolved"] ? "badge-resolved" : "badge-unresolved"
        status_text = attr["resolved"] ? "✓ Resolved" : "⚠ Unresolved"

        xsd_info = ""
        if attr["xsd_info"]
          info = attr["xsd_info"]
          xsd_info = "#{info['type']}: #{info['name']}"
          if attr["resolution_path"] && !attr["resolution_path"].empty?
            xsd_info += "<div class='resolution-path'>#{CGI.escapeHTML(attr['resolution_path'].first)}</div>"
          end
        else
          xsd_info = "<span style='color: #999;'>Not found in XSD</span>"
        end

        package_html += <<~HTML
          <tr class="#{row_class}">
            <td><strong>#{CGI.escapeHTML(attr['name'])}</strong></td>
            <td class="type-info">#{CGI.escapeHTML(attr['uml_type'] || 'N/A')}</td>
            <td>#{attr['multiplicity']['min']}..#{attr['multiplicity']['max']}</td>
            <td>#{xsd_info}</td>
            <td><span class="status-badge #{badge_class}">#{status_text}</span></td>
          </tr>
        HTML
      end

      package_html += <<~HTML
          </tbody>
        </table>
      HTML
    end

    package_html += <<~HTML
      </div>
    HTML
  end

  package_html += <<~HTML
        </div>

        <footer>
          <p><a href="index.html">← Back to All Packages</a></p>
        </footer>
      </div>
    </body>
    </html>
  HTML

  File.write(File.join(output_dir, filename), package_html)
end

puts
puts "=" * 80
puts "HTML generation complete!"
puts "=" * 80
puts
puts "Output directory: #{output_dir}"
puts "Open in browser: #{File.join(output_dir, 'index.html')}"
puts
