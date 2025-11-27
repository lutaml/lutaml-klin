# Technical Details

## Technologies Used

### Core Language & Framework
- **Ruby**: 2.7.0+ required
- **Thor**: CLI framework for command-line interface
- **Lutaml::Model**: Serialization framework for model-driven architecture

### Key Dependencies

#### LutaML Ecosystem
- **lutaml** (~> 1.0): UML repository and LUR package support
- **lutaml-xsd** (~> 1.0): XSD schema repository and LXR package support
- **lutaml-model** (~> 0.7): Model-based serialization framework
- **moxml**: XML processing with Nokogiri adapter

#### Templating & Web
- **liquid**: Template engine for SPA generation
- **sqlite3**: Database support (for future features)

#### Testing & Quality
- **rspec**: BDD testing framework (389 tests)
- **rubocop**: Ruby code style checker
- **rubocop-rake**: RuboCop rules for Rake
- **rubocop-rspec**: RuboCop rules for RSpec
- **rubocop-performance**: Performance-focused RuboCop rules

## Development Setup

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lutaml/lutaml-klin.git
   cd lutaml-klin
   ```

2. **Install dependencies**:
   ```bash
   bundle install
   ```

3. **Run tests**:
   ```bash
   bundle exec rake spec
   ```

4. **Run linter**:
   ```bash
   bundle exec rubocop -A
   ```

### Project Structure

```
lutaml-klin/
├── exe/
│   └── lutaml-klin           # Executable entry point
├── lib/
│   └── lutaml/klin/          # Main library code
│       ├── cli.rb            # CLI entry point
│       ├── version.rb        # Version constant
│       ├── application/      # Application workflows
│       ├── domain/           # Business logic
│       ├── repositories/     # Data adapters
│       ├── models/           # Data models
│       ├── shapechange/      # ShapeChange integration
│       └── commands/         # CLI command implementations
├── spec/                     # Test suite
│   ├── lutaml/klin/         # Unit tests
│   └── integration/          # Integration tests
├── examples/                 # Usage examples
├── reference/                # Reference data
│   └── shapechange-configs/  # ShapeChange configurations
├── Gemfile                   # Dependency specification
├── lutaml-klin.gemspec       # Gem specification
├── Rakefile                  # Task definitions
└── README.adoc               # Documentation
```

## Technical Constraints

### Performance Requirements
- **LUR Loading**: Must complete in <100ms for 662 classes
- **LXR Loading**: Must complete in <100ms for 2764 types
- **Mapping Generation**: Target <10 seconds for 174 classes
- **Resolution Rate**: Achieve >90% successful type resolution

### Memory Constraints
- Packages cached in memory after loading
- Moderate memory usage expected
- No streaming required for current data sizes

### Compatibility Requirements
- **Ruby Version**: 2.7.0 or higher
- **ShapeChange**: Compatible with ShapeChange encoding rules
- **File Formats**:
  - Input: XMI (via LUR), XSD (via LXR), XML (ShapeChange config)
  - Output: YAML, JSON, Markdown, HTML

## Architecture Patterns

### Model-Driven Architecture
All data structures inherit from `Lutaml::Model::Serializable`:
- Automatic YAML/JSON/XML serialization
- Type validation
- Clear API boundaries
- Self-documenting models

### Strategy Pattern
Used in ResolutionEngine for flexible type resolution:
- Easy to add new strategies
- Ordered execution
- First success wins
- Graceful fallback

### Repository Pattern
Adapters abstract data access:
- UmlRepositoryAdapter wraps lutaml API
- SchemaRepositoryAdapter wraps lutaml-xsd API
- Can swap implementations without workflow changes

### Workflow Pattern
Each workflow is a dedicated class:
- Single responsibility
- Easy to test
- Composable
- Clear separation of concerns

## Code Style & Conventions

### Ruby Style
- 2 spaces for indentation (no tabs)
- Max line length: 80 characters
- Use `require_relative` for local files
- Always use `attr_reader`, `attr_writer`, `attr_accessor`
- Follow RuboCop rules

### Class Organization
- One class per file (generally)
- File names match class names in snake_case
- Classes under 700 lines
- Methods under 50 lines

### Testing Conventions
- One test file per class/module
- Use `let` for test data
- No mocks or stubs
- Fixtures in `spec/fixtures/`
- Integration tests in `spec/integration/`

### Documentation
- All public methods documented
- Use YARD format for API documentation
- README in AsciiDoc format
- Examples for all major features

## File Formats

### LUR Package (.lur)
- Built by: `lutaml xmi package build`
- Contains: Serialized UML repository
- Format: Ruby Marshal (binary)
- Load time: <100ms

### LXR Package (.lxr)
- Built by: `lutaml-xsd package build`
- Contains: Serialized XSD schema repository
- Format: Ruby Marshal (binary)
- Load time: <100ms

### Mapping Files (.yaml)
- Format: YAML
- Schema: SchemaMapping / PackageMapping
- Includes: Full traceability metadata

### Configuration Files (.xml)
- Format: XML (ShapeChange compatible)
- Contains: Encoding rules, type mappings, namespaces
- Supports: XInclude references

## Testing Strategy

### Unit Tests
- Test individual components in isolation
- Mock external dependencies
- Fast execution
- Located in `spec/lutaml/klin/`

### Integration Tests
- Test complete workflows
- Use real LUR/LXR packages
- Verify actual output
- Located in `spec/integration/`

### Test Data
- PLATEAU URO package (174 classes)
- Real-world complexity
- Representative of production use
- Fixtures in `spec/fixtures/`

### Running Tests

```bash
# All tests
bundle exec rake spec

# Specific file
bundle exec rspec spec/lutaml/klin/application/mapping_workflow_spec.rb

# Integration tests
bundle exec rspec spec/integration/

# With coverage
COVERAGE=true bundle exec rake spec

# With RuboCop
bundle exec rubocop -A
```

## Build & Release

### Version Management
- Version defined in `lib/lutaml/klin/version.rb`
- Semantic versioning (MAJOR.MINOR.PATCH)
- Current version: 0.1.0

### Gem Building
```bash
gem build lutaml-klin.gemspec
```

### Gem Installation
```bash
gem install lutaml-klin-0.1.0.gem
```

## Environment Variables

### Optional Configuration
- `SHAPECHANGE_CONFIG_DIR`: Override ShapeChange config directory
- `COVERAGE`: Enable coverage reporting in tests

### Cache Directory
- Default: `.lutaml-klin/cache`
- Configurable via CLI: `--lxr-cache-dir`
- Stores auto-generated LXR packages

## Known Limitations

### Current Limitations
1. **Enumeration Support**: Requires `enums_in_package` in lutaml-xmi
2. **Documentation Annotations**: xs:annotation not yet generated in XSD
3. **Binary Formats**: Marshal format not portable across Ruby versions

### Future Enhancements
1. JSON serialization for LUR/LXR packages (portability)
2. Plugin system for custom transformations
3. Parallel processing for large datasets
4. Incremental updates for changed classes only

## Integration Points

### With LutaML
- Loads UML models via Repository API
- Uses Package, Class, Attribute models
- Delegates all UML parsing to lutaml

### With LutaML-XSD
- Loads XSD schemas via SchemaRepository API
- Uses Type and Element models
- Delegates all XSD parsing to lutaml-xsd

### With ShapeChange
- Reads ShapeChange XML configurations
- Applies encoding rules
- Uses type mappings (XsdMapEntry)
- Generates compatible XSD output

## Performance Optimization

### Current Optimizations
- Pre-built packages avoid XML parsing
- In-memory caching of loaded packages
- Lazy loading of repository adapters
- Memoization of type lookups

### Profiling
Use Ruby's built-in profiler:
```bash
ruby -rprofile exe/lutaml-klin process \
  --lur model.lur --lxr schemas.lxr \
  --config config.xml --output out/
```

## Security Considerations

### Input Validation
- File paths validated before reading
- XML input sanitized (XXE protection via Nokogiri)
- File size limits considered

### Output Safety
- Safe YAML serialization (no unsafe deserialization)
- Output paths validated (no directory traversal)
- Appropriate file permissions

## Troubleshooting

### Common Issues

1. **"LUR package not found"**
   - Verify file path is correct
   - Ensure LUR was built with lutaml

2. **"No packages matched filter"**
   - Check package names with `--verbose`
   - Use wildcards: `**::packagename`
   - Try processing all: `--packages "**"`

3. **Low resolution rate**
   - Review ShapeChange configuration
   - Check type overrides
   - Use `--verbose` to see resolution attempts

### Debug Mode
Use `--verbose` flag for detailed output:
```bash
lutaml-klin process --lur model.lur ... --verbose
```