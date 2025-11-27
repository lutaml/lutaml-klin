# Enhanced HTML SPA Usage Guide

## Overview

The Enhanced HTML Single Page Application (SPA) generator creates interactive, browser-based documentation for XSD schemas. It provides modern navigation, search, and cross-reference capabilities through a responsive web interface.

## Quick Start

### Generate Multi-File SPA

```bash
lutaml-klin spa docs/ --lxr schemas.lxr
```

Generates:
```
docs/
├── index.html
├── data/
│   ├── schema.json
│   ├── cross_refs.json
│   └── search_index.json
└── assets/
    ├── css/
    │   ├── main.css
    │   ├── navigation.css
    │   ├── content.css
    │   └── responsive.css
    └── js/
        ├── app.js
        ├── navigation.js
        ├── search.js
        ├── renderer.js
        ├── router.js
        └── utils.js
```

### Generate Embedded Single-File SPA

```bash
lutaml-klin spa schema_doc.html --lxr schemas.lxr --mode embedded
```

Generates a single `schema_doc.html` file with all assets embedded.

## Command-Line Interface

### Basic Usage

```bash
lutaml-klin spa OUTPUT --lxr LXR_PATH [OPTIONS]
```

### Required Options

- `--lxr PATH`: Path to LXR (LutaML XSD Repository) package file

### Optional Options

- `--yaml PATH`: Path to YAML mapping file (adds UML traceability)
- `--mode MODE`: Output mode - `multi-file` (default) or `embedded`
- `--theme THEME`: UI theme - `default`, `dark`, or `plateau`
- `--title TITLE`: Custom website title
- `--template-dir DIR`: Custom template directory
- `--assets-dir DIR`: Custom assets directory
- `--verbose`: Enable verbose output

### Examples

#### Multi-File Mode (Default)

```bash
# Basic multi-file SPA
lutaml-klin spa docs/ --lxr schemas.lxr

# With custom theme
lutaml-klin spa docs/ --lxr schemas.lxr --theme dark

# With verbose output
lutaml-klin spa docs/ --lxr schemas.lxr --verbose
```

#### Embedded Mode

```bash
# Single HTML file
lutaml-klin spa schema.html --lxr schemas.lxr --mode embedded

# With custom title
lutaml-klin spa schema.html \
  --lxr schemas.lxr \
  --mode embedded \
  --title "My Schema Documentation"
```

#### With PLATEAU UML Mapping

```bash
# Add UML traceability information
lutaml-klin spa uro_docs/ \
  --lxr plateau_schemas.lxr \
  --yaml mappings/uro_mapping.yaml \
  --theme plateau \
  --verbose
```

This adds:
- UML class and package information
- Resolution strategy display
- Bidirectional UML ↔ XSD mapping visualization

## Ruby API

### Generate Complete SPA

```ruby
require '

lutaml/klin/spa'

# Generate multi-file SPA
Lutaml::Klin::Spa.generate(
  'packages/schemas.lxr',
  yaml_path: 'mappings/mapping.yaml',
  output: 'docs/',
  mode: :multi_file,
  theme: 'default',
  verbose: true
)

# Generate embedded SPA
Lutaml::Klin::Spa.generate(
  'packages/schemas.lxr',
  output: 'schema.html',
  mode: :embedded,
  theme: 'dark'
)
```

### Process Data Without Generating HTML

```ruby
# Just load and process schema data
schema = Lutaml::Klin::Spa.process(
  'packages/schemas.lxr',
  yaml_path: 'mappings/mapping.yaml',
  verbose: true
)

# Access processed data
puts "Name: #{schema.metadata.name}"
puts "Schemas: #{schema.schemas.size}"
puts "Elements: #{schema.elements.size}"
puts "Search terms: #{schema.search_index.terms.size}"

# Export as JSON
require 'json'
File.write('schema_data.json', JSON.pretty_generate(schema.to_h))
```

### Advanced Usage with Generator

```ruby
require 'lutaml/klin/spa/generator'

generator = Lutaml::Klin::Spa::Generator.new(
  mode: :multi_file,
  theme: 'plateau',
  title: 'PLATEAU Schema Documentation',
  verbose: true
)

schema = generator.generate(
  'packages/plateau.lxr',
  'mappings/plateau.yaml',
  'output/plateau_docs'
)

puts "Generated #{schema.schemas.size} schema packages"
```

## Features

### Three-Tier Navigation

Navigate through your schemas with an intuitive hierarchy:

1. **Tier 1: Schema Selection** - Choose from available schema packages
2. **Tier 2: Category Selection** - Browse elements, types, or attributes
3. **Tier 3: Item Selection** - View detailed component information

### Client-Side Search

- **Fast Filtering**: Index-based search with instant results
- **Highlighting**: Search terms highlighted in results
- **Keyboard Shortcuts**:
  - `Ctrl+K` / `Cmd+K` - Focus search
  - `Escape` - Clear search

### Cross-References

- **Click to Navigate**: Cross-reference links navigate to related types
- **Type Hierarchy**: See inheritance and composition relationships
- **Bidirectional**: Navigate from types to elements and back

### UML Mapping Display (with YAML)

When a YAML mapping file is provided:
- View UML class and package information
- See resolution strategies used
- Understand UML → XSD transformations

### Responsive Design

- **Desktop**: Full three-column layout with sidebar navigation
- **Mobile**: Hamburger menu with overlay sidebar
- **Touch-Friendly**: Large tap targets, smooth transitions

### Themes

Three built-in themes:

1. **default**: Clean, professional light theme
2. **dark**: Easy-on-the-eyes dark theme
3. **plateau**: PLATEAU project branding

## Viewing Generated SPAs

### Multi-File Mode

Multi-file SPAs must be served via HTTP(S), not opened directly as `file://`:

```bash
# Using Python's built-in server
cd output_directory
python3 -m http.server 8000

# Then open http://localhost:8000
```

```bash
# Using Ruby's WEBrick
cd output_directory
ruby -run -ehttpd . -p8000

# Then open http://localhost:8000
```

```bash
# Using PHP (if installed)
cd output_directory
php -S localhost:8000

# Then open http://localhost:8000
```

### Embedded Mode

Embedded SPAs can be opened directly in a browser:

```bash
open schema_doc.html
# or
firefox schema_doc.html
# or
chrome schema_doc.html
```

## Browser Support

Modern browsers with ES6+ support (2018+):

- ✅ Chrome 60+
- ✅ Firefox 60+
- ✅ Safari 12+
- ✅ Edge 79+

Required JavaScript features:
- ES6 modules (`import`/`export`)
- ES6 classes
- Arrow functions
- Template literals
- `async`/`await`
- Fetch API
- Promises

## Troubleshooting

### Embedded Mode File Too Large

**Problem**: Single HTML file exceeds browser limits (>20MB)

**Solution**: Use multi-file mode for large schemas:

```bash
lutaml-klin spa docs/ --lxr large_schema.lxr --mode multi-file
```

### JavaScript Not Loading (Multi-File Mode)

**Problem**: Blank page or console errors about CORS

**Solution**: Serve via HTTP server, not `file://`:

```bash
cd output_dir
python3 -m http.server 8000
# Open http://localhost:8000
```

### Search Not Working

**Problem**: Search returns no results

**Solution**:
1. Check that `data/search_index.json` exists
2. Verify schema was generated successfully
3. Try regenerating with `--verbose` flag

###  Styles Not Rendering Correctly

**Problem**: Page appears unstyled

**Solution**:
1. For multi-file: Ensure `assets/css/` directory exists
2. For embedded: Regenerate SPA
3. Check browser console for errors

### UML Mapping Not Showing

**Problem**: UML information missing despite providing YAML

**Solution**:
1. Verify YAML file path is correct
2. Check YAML file format (see YAML schema docs)
3. Use `--verbose` to see mapping process

## Performance Considerations

### Large Schemas

For schemas with 1000+ components:

- Use **multi-file mode** for better performance
- Consider splitting into multiple smaller LXR packages
- Embedded mode may result in large file sizes

### Search Performance

- Search is client-side and very fast (<100ms)
- No server-side processing required
- Scales well up to ~5000 searchable items

## Customization

### Custom Templates

Provide your own Liquid templates:

```bash
lutaml-klin spa docs/ \
  --lxr schemas.lxr \
  --template-dir custom_templates/
```

Template structure:
```
custom_templates/
├── embedded.liquid          # For embedded mode
└── multi_file/
    ├── index.liquid         # Main HTML template
    └── index_content.liquid # Content partial
```

### Custom Assets

Provide your own CSS/JS:

```bash
lutaml-klin spa docs/ \
  --lxr schemas.lxr \
  --assets-dir custom_assets/
```

Asset structure:
```
custom_assets/
├── css/
│   ├── main.css
│   ├── navigation.css
│   ├── content.css
│   └── responsive.css
└── js/
    ├── app.js
    ├── navigation.js
    ├── search.js
    ├── renderer.js
    ├── router.js
    └── utils.js
```

## Best Practices

### For Documentation

1. **Use Descriptive Titles**: Provide `--title` for clarity
2. **Include UML Mapping**: When available, use `--yaml` for traceability
3. **Choose Appropriate Mode**:
   - Multi-file: Better for large teams, version control
   - Embedded: Better for sharing single files

### For Deployment

1. **Multi-File Mode**: Easier to cache, better performance
2. **Use CDN**: Host assets on CDN for faster loading
3. **Enable Compression**: Gzip/Brotli for smaller transfers
4. **Set Cache Headers**: Cache static assets aggressively

### For Development

1. **Use Verbose Mode**: Debug generation issues
2. **Test Both Modes**: Ensure compatibility
3. **Validate LXR**: Ensure LXR package is well-formed
4. **Check Browser Console**: Monitor for JavaScript errors

## Integration Examples

### CI/CD Pipeline

```yaml
# .github/workflows/docs.yml
name: Generate Schema Documentation

on:
  push:
    branches: [main]

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'

      - name: Install lutaml-klin
        run: gem install lutaml-klin

      - name: Generate SPA
        run: |
          lutaml-klin spa docs/ \
            --lxr packages/schemas.lxr \
            --yaml mappings/mapping.yaml \
            --theme default \
            --verbose

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./docs
```

### Makefile Integration

```makefile
.PHONY: docs docs-embedded docs-clean

docs:
	lutaml-klin spa docs/ \
		--lxr packages/schemas.lxr \
		--yaml mappings/mapping.yaml \
		--verbose

docs-embedded:
	lutaml-klin spa schema_doc.html \
		--lxr packages/schemas.lxr \
		--mode embedded \
		--theme dark

docs-clean:
	rm -rf docs/ schema_doc.html

docs-serve: docs
	cd docs && python3 -m http.server 8000
```

## FAQ

### Q: Can I use SPA without an LXR package?

A: No, an LXR package is required. Use `lutaml-klin create-lxr` to create one from XSD files.

### Q: What's the difference between multi-file and embedded mode?

A:
- **Multi-file**: Separate HTML, CSS, JS, JSON files - better for large schemas
- **Embedded**: Single HTML file with everything inline - better for sharing

### Q: Do I need a web server for embedded mode?

A: No, embedded mode can be opened directly in a browser. Multi-file mode requires HTTP server.

### Q: Can I customize the look and feel?

A: Yes, use `--theme` for built-in themes or `--assets-dir` for custom CSS/JS.

### Q: How do I add UML traceability?

A: Provide a YAML mapping file with `--yaml` option.

### Q: Is the SPA mobile-friendly?

A: Yes, it includes responsive design with hamburger menu for mobile devices.

## Support

For issues, questions, or contributions:

- **GitHub**: https://github.com/lutaml/lutaml-klin
- **Documentation**: https://github.com/lutaml/lutaml-klin/tree/main/docs
- **Examples**: https://github.com/lutaml/lutaml-klin/tree/main/examples

## See Also

- [SPA Architecture Plan](HTML-SPA-ARCHITECTURE-PLAN.md)
- [SPA Phase 2 Implementation](SPA-PHASE-2-IMPLEMENTATION-SUMMARY.md)
- [SPA Phase 3 Implementation](SPA-PHASE-3-IMPLEMENTATION-SUMMARY.md)
- [LXR Package Creation Guide](../README.adoc)