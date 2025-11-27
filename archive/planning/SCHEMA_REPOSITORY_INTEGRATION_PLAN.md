# SchemaRepository Integration Architecture Plan
## Integrating lutaml-xsd LXR Packages for Complete UML-to-XSD Mapping

## Executive Summary

This document outlines the architecture for integrating lutaml-xsd's `SchemaRepository` and LXR (LutaML XSD Repository) packages into lutaml-klin to enable complete, production-ready UML-to-XSD mapping with full type resolution capabilities.

**Key Benefits**:
- **Instant schema loading**: Pre-serialized LXR packages load in milliseconds
- **Namespace-aware resolution**: Resolve types across multiple schemas using qualified names
- **Cross-schema references**: Automatic resolution of imports and includes
- **Pre-built indexes**: Fast lookups without parsing overhead
- **Validation support**: Comprehensive schema validation and statistics
- **Offline capable**: Self-contained packages with all dependencies

**Integration Points**:
1. Repository initialization from LXR packages
2. Namespace configuration and prefix mapping
3. Type resolution using SchemaRepository API
4. Element and attribute matching
5. Resolution metadata tracking
6. Validation and statistics

## Current State Analysis

### What lutaml-xsd Provides

From the lutaml-xsd README, the SchemaRepository provides:

```ruby
# Load pre-built LXR package
repo = Lutaml::Xsd::SchemaRepository.from_package('schemas.lxr')

# Namespace configuration (auto-loaded from package)
repo.add_namespace_mapping(prefix: 'gml', uri: 'http://www.opengis.net/gml/3.2')

# Type resolution (multiple formats supported)
result = repo.find_type('gml:CodeType')               # Prefixed
result = repo.find_type('{http://...}CodeType')       # Clark notation
result = repo.find_type('CodeType')                   # Unprefixed search

# Component finding
element = repo.find_element('gml:Point')
attr = repo.find_attribute('xml:id')
group = repo.find_group('gml:StandardObjectProperties')

# Statistics and validation
stats = repo.statistics
validation = repo.validate
```

**Key Features**:
- Pre-serialized schemas (instant loading)
- Pre-built type indexes (fast qualified name lookups)
- Namespace-aware queries
- Cross-schema resolution
- Validation capabilities

### What lutaml-klin Currently Has

From the existing codebase:

1. **XmiNavigator**: Parses UML from XMI files
2. **ConfigParser**: Reads ShapeChange configurations
3. **MappingGenerator**: Creates YAML mappings
4. **XsdAnalyzer**: Currently uses moxml for XSD parsing (to be replaced)

### Integration Goals

Replace the current XsdAnalyzer with SchemaRepository integration to achieve:

1. **Faster resolution**: Use pre-built indexes instead of parsing
2. **Better accuracy**: Namespace-aware type resolution
3. **Cross-schema support**: Resolve types across all imported schemas
4. **Metadata tracking**: Record how each type was resolved
5. **Validation**: Verify mapping completeness using schema statistics

## Architectural Design

### Layer 1: Infrastructure - Repository Adapters

Create adapter classes to wrap lutaml-xsd repositories and provide lutaml-klin-specific interfaces.

```ruby
# lib/lutaml/klin/repositories/schema_repository_adapter.rb
module Lutaml
  module Klin
    module Repositories
      # Adapter wrapping lutaml-xsd SchemaRepository
      class SchemaRepositoryAdapter
        attr_reader :repository, :namespace_mappings

        # Initialize from LXR package
        def self.from_package(lxr_path, namespace_mappings: [])
          repo = Lutaml::Xsd::SchemaRepository.from_package(lxr_path)

          # Configure namespace mappings
          namespace_mappings.each do |mapping|
            repo.add_namespace_mapping(
              prefix: mapping[:prefix],
              uri: mapping[:uri]
            )
          end

          new(repo)
        end

        # Initialize from direct XSD files
        def self.from_schemas(schema_paths, namespace_mappings: [],
                             schema_location_mappings: [])
          repo = Lutaml::Xsd::SchemaRepository.new

          # Configure namespaces
          namespace_mappings.each do |mapping|
            repo.add_namespace_mapping(
              prefix: mapping[:prefix],
              uri: mapping[:uri]
            )
          end

          # Parse each schema
          schema_paths.each do |path|
            content = File.read(path)
            repo.parse_schema(
              content: content,
              location: File.dirname(path),
              schema_mappings: schema_location_mappings
            )
          end

          new(repo)
        end

        def initialize(repository)
          @repository = repository
        end

        # Find XSD type by qualified name
        # Returns TypeResolutionResult
        def resolve_type(qualified_name)
          result = @repository.find_type(qualified_name)

          if result.resolved?
            TypeResolutionResult.new(
              status: :resolved,
              qualified_name: result.qname,
              namespace: result.namespace,
              local_name: result.local_name,
              definition: result.definition,
              method: :schema_repository,
              confidence: 1.0,
              metadata: {
                schema_file: result.schema_location,
                type_class: result.definition.class.name
              }
            )
          else
            TypeResolutionResult.new(
              status: :unresolved,
              qualified_name: qualified_name,
              error: "Type not found in schema repository"
            )
          end
        end

        # Find XSD element by qualified name
        def find_element(qualified_name)
          @repository.find_element(qualified_name)
        end

        # Find XSD attribute by qualified name
        def find_attribute(qualified_name)
          @repository.find_attribute(qualified_name)
        end

        # Get all types in a namespace
        def types_in_namespace(namespace_uri)
          @repository.types_in_namespace(namespace_uri)
        end

        # Get repository statistics
        def statistics
          @repository.statistics
        end

        # Validate schema consistency
        def validate
          @repository.validate
        end

        # List all namespaces
        def namespaces
          @repository.namespaces
        end

        # Check if namespace exists
        def namespace?(uri)
          @repository.namespace?(uri)
        end
      end
    end
  end
end
```

### Layer 2: Domain - Resolution Strategy

Integrate SchemaRepository as a resolution strategy in the existing resolution engine.

```ruby
# lib/lutaml/klin/domain/resolution/schema_repository_strategy.rb
module Lutaml
  module Klin
    module Domain
      module Resolution
        # Strategy for resolving types via SchemaRepository
        class SchemaRepositoryStrategy < ResolutionStrategy
          def initialize(repository_adapter)
            @repository = repository_adapter
          end

          def name
            :schema_repository
          end

          def applicable?(source, context)
            # Always applicable as primary resolution method
            true
          end

          def resolve(source, context:)
            # Try multiple name formats in priority order
            candidates = build_name_candidates(source, context)

            candidates.each do |candidate|
              result = @repository.resolve_type(candidate[:qualified_name])

              if result.resolved?
                return ResolutionResult.resolved(
                  target: result.definition,
                  method: :schema_repository,
                  confidence: candidate[:confidence],
                  metadata: {
                    qualified_name: result.qualified_name,
                    namespace: result.namespace,
                    local_name: result.local_name,
                    candidate_format: candidate[:format],
                    schema_file: result.schema_location
                  }
                )
              end
            end

            # Not found in repository
            ResolutionResult.unresolved(
              error: "Type not found in schema repository",
              metadata: {
                attempted_names: candidates.map { |c| c[:qualified_name] },
                source_type: source.type,
                available_namespaces: @repository.namespaces
              }
            )
          end

          private

          def build_name_candidates(source, context)
            candidates = []

            # 1. Try exact type as-is (highest priority)
            candidates << {
              qualified_name: source.type,
              format: :exact,
              confidence: 1.0
            }

            # 2. Try with namespace prefix (if type has ::)
            if source.type.include?('::')
              prefix, local_name = source.type.split('::', 2)
              candidates << {
                qualified_name: "#{prefix}:#{local_name}",
                format: :prefixed,
                confidence: 0.95
              }
            end

            # 3. Try with default namespace
            if context.default_namespace_prefix
              candidates << {
                qualified_name: "#{context.default_namespace_prefix}:#{source.type}",
                format: :default_namespace,
                confidence: 0.8
              }
            end

            # 4. Try unprefixed search (lowest priority)
            candidates << {
              qualified_name: source.type.split('::').last,
              format: :unprefixed,
              confidence: 0.5
            }

            candidates
          end
        end
      end
    end
  end
end
```

### Layer 3: Application - Integration Workflow

Update the MappingGenerator to use SchemaRepository.

```ruby
# lib/lutaml/klin/mapping_generator.rb (UPDATED)
module Lutaml
  module Klin
    class MappingGenerator
      def initialize(config:, xmi_navigator:, schema_repository:)
        @config = config
        @xmi = xmi_navigator
        @schema_repo = schema_repository
        @resolution_engine = build_resolution_engine
      end

      def generate_mapping(package_name)
        # 1. Load UML package
        uml_package = @xmi.find_package(package_name)
        raise "Package not found: #{package_name}" unless uml_package

        # 2. Build resolution context
        context = build_resolution_context

        # 3. Map each class
        class_mappings = uml_package.classes.map do |uml_class|
          map_class(uml_class, context: context)
        end

        # 4. Create package mapping
        Models::Mapping::PackageMapping.new(
          package: uml_package.name,
          namespace: determine_namespace(uml_package, context),
          classes: class_mappings,
          metadata: {
            source_xmi: @xmi.source_file,
            config_file: @config.source_file,
            resolution_statistics: calculate_resolution_stats(class_mappings),
            generated_at: Time.now.iso8601
          }
        )
      end

      private

      def build_resolution_engine
        Domain::Resolution::ResolutionEngine.new(
          strategies: [
            # Priority 1: User overrides (highest priority)
            Domain::Resolution::TypeOverrideStrategy.new(@config.type_overrides),

            # Priority 2: SchemaRepository (lutaml-xsd integration)
            Domain::Resolution::SchemaRepositoryStrategy.new(@schema_repo),

            # Priority 3: ShapeChange type mappings
            Domain::Resolution::ShapeChangeStrategy.new(@config.type_mappings),

            # Priority 4: Namespace-based inference (fallback)
            Domain::Resolution::NamespaceStrategy.new(@config.namespaces)
          ]
        )
      end

      def map_class(uml_class, context:)
        # Resolve class type
        type_resolution = @resolution_engine.resolve(uml_class, context: context)

        # Map attributes
        attribute_mappings = uml_class.attributes.map do |attr|
          map_attribute(attr, context: context)
        end

        Models::Mapping::ClassMapping.new(
          uml_class: uml_class,
          xsd_type: type_resolution.target,
          resolution_result: type_resolution,
          attribute_mappings: attribute_mappings
        )
      end

      def map_attribute(attribute, context:)
        # Resolve attribute type
        type_resolution = @resolution_engine.resolve(attribute, context: context)

        # Find corresponding XSD element (if exists)
        xsd_element = find_xsd_element(attribute, type_resolution, context)

        Models::Mapping::AttributeMapping.new(
          uml_attribute: attribute,
          xsd_element: xsd_element,
          xsd_type: type_resolution.target,
          resolution_result: type_resolution
        )
      end

      def find_xsd_element(attribute, type_resolution, context)
        # Try to find XSD element matching this attribute
        element_name = determine_element_name(attribute, context)
        @schema_repo.find_element(element_name)
      end
    end
  end
end
```

### Layer 4: CLI - Command Integration

Update CLI to support LXR packages.

```ruby
# lib/lutaml/klin/cli.rb (UPDATED)
module Lutaml
  module Klin
    class Cli < Thor
      desc "generate CONFIG XMI LXR OUTPUT", "Generate YAML mapping using LXR package"
      option :package, type: :string, required: true,
             desc: "UML package name to process"
      option :namespace_mappings, type: :string,
             desc: "YAML file with namespace prefix mappings"
      option :verbose, type: :boolean, default: false
      def generate(config_path, xmi_path, lxr_path, output_path)
        # Load namespace mappings
        ns_mappings = load_namespace_mappings(options[:namespace_mappings])

        # Initialize repositories
        schema_repo = Repositories::SchemaRepositoryAdapter.from_package(
          lxr_path,
          namespace_mappings: ns_mappings
        )

        uml_repo = Repositories::UmlRepositoryAdapter.new(xmi_path)

        # Parse config
        config = Shapechange::ConfigParser.parse(config_path)

        # Generate mapping
        generator = MappingGenerator.new(
          config: config,
          xmi_navigator: XmiNavigator.new(uml_repo),
          schema_repository: schema_repo
        )

        mapping = generator.generate_mapping(options[:package])

        # Write output
        File.write(output_path, mapping.to_yaml)

        puts "✓ Mapping generated: #{output_path}"
        display_statistics(mapping)
      end

      private

      def load_namespace_mappings(file_path)
        return [] unless file_path

        YAML.load_file(file_path).fetch('namespace_mappings', [])
      end

      def display_statistics(mapping)
        stats = mapping.statistics

        puts "\nStatistics:"
        puts "  Total classes: #{stats[:total_classes]}"
        puts "  Resolved classes: #{stats[:resolved_classes]}"
        puts "  Resolution rate: #{(stats[:resolution_rate] * 100).round(1)}%"
        puts "  Total attributes: #{stats[:total_attributes]}"
        puts "  Resolved attributes: #{stats[:resolved_attributes]}"
      end
    end
  end
end
```

## Data Flow Architecture

### Complete Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│                     COMPLETE MAPPING WORKFLOW                   │
│                                                                  │
│  ┌──────────────┐                                               │
│  │  Input 1:    │                                               │
│  │  LXR Package │                                               │
│  │  (.lxr file) │                                               │
│  └──────┬───────┘                                               │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────────────────┐                                │
│  │ SchemaRepositoryAdapter     │                                │
│  │ - Load pre-serialized       │                                │
│  │ - Configure namespaces      │                                │
│  │ - Pre-built type index      │                                │
│  └──────────┬──────────────────┘                                │
│             │                                                    │
│  ┌──────────┴──────────┐                                        │
│  │  Input 2:           │                                        │
│  │  UML XMI File       │                                        │
│  │  (.xmi)             │                                        │
│  └──────────┬──────────┘                                        │
│             │                                                    │
│             ▼                                                    │
│  ┌─────────────────────────────┐                                │
│  │ XmiNavigator                │                                │
│  │ - Parse UML packages        │                                │
│  │ - Extract classes           │                                │
│  │ - Extract attributes        │                                │
│  └──────────┬──────────────────┘                                │
│             │                                                    │
│  ┌──────────┴──────────┐                                        │
│  │  Input 3:           │                                        │
│  │  ShapeChange Config │                                        │
│  │  (.xml)             │                                        │
│  └──────────┬──────────┘                                        │
│             │                                                    │
│             ▼                                                    │
│  ┌─────────────────────────────┐                                │
│  │ ConfigParser                │                                │
│  │ - Encoding rules            │                                │
│  │ - Type mappings             │                                │
│  │ - Namespace config          │                                │
│  └──────────┬──────────────────┘                                │
│             │                                                    │
│             ▼                                                    │
│  ┌─────────────────────────────────────────────────────┐        │
│  │ ResolutionEngine (Strategy Pattern)                 │        │
│  │                                                      │        │
│  │  1. TypeOverrideStrategy      (Priority 1)          │        │
│  │     ├─ User-defined overrides                       │        │
│  │     └─ Fix malformed type names                     │        │
│  │                                                      │        │
│  │  2. SchemaRepositoryStrategy  (Priority 2) ◄────────┼────┐   │
│  │     ├─ Query LXR package                            │    │   │
│  │     ├─ Namespace-aware lookup                       │    │   │
│  │     ├─ Cross-schema resolution                      │    │   │
│  │     └─ Instant type index                           │    │   │
│  │                                                      │    │   │
│  │  3. ShapeChangeStrategy       (Priority 3)          │    │   │
│  │     ├─ Standard GML mappings                        │    │   │
│  │     └─ ISO type mappings                            │    │   │
│  │                                                      │    │   │
│  │  4. NamespaceStrategy         (Priority 4)          │    │   │
│  │     └─ Infer from namespace prefix                  │    │   │
│  │                                                      │    │   │
│  └──────────────────────┬──────────────────────────────┘    │   │
│                         │                                    │   │
│                         ▼                                    │   │
│  ┌─────────────────────────────────────────────────────┐    │   │
│  │ MappingGenerator                                    │    │   │
│  │  For each UML Class:                                │    │   │
│  │    ├─ Resolve XSD type ─────────────────────────────┼────┘   │
│  │    │                                                 │        │
│  │    └─ For each Attribute:                           │        │
│  │       ├─ Resolve XSD type ──────────────────────────┼────┐   │
│  │       └─ Find XSD element ──────────────────────────┼────┤   │
│  │                                                      │    │   │
│  └──────────────────────┬───────────────────────────────┘    │   │
│                         │                                    │   │
│                         ▼                                    ▼   ▼
│  ┌───────────────────────────────────────────────────────────────┐
│  │ Output: PackageMapping (Rich Domain Model)                   │
│  │  ├─ Package metadata                                         │
│  │  ├─ ClassMappings                                            │
│  │  │   ├─ UML class info                                       │
│  │  │   ├─ XSD type (resolved)                                  │
│  │  │   ├─ ResolutionResult (method, confidence, metadata)      │
│  │  │   └─ AttributeMappings                                    │
│  │  │       ├─ UML attribute info                               │
│  │  │       ├─ XSD element (if found)                           │
│  │  │       ├─ XSD type (resolved)                              │
│  │  │       └─ ResolutionResult (method, confidence, metadata)  │
│  │  └─ Statistics (resolution rates, counts, etc.)              │
│  └───────────────────────┬───────────────────────────────────────┘
│                          │                                         │
│                          ▼                                         │
│  ┌───────────────────────────────────────────────────────────────┐
│  │ YAML Serialization                                            │
│  │  - Human-readable mapping file                                │
│  │  - Full resolution metadata                                   │
│  │  - Traceability (method used for each resolution)             │
│  └───────────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Foundation (2-3 hours)

1. **Create SchemaRepositoryAdapter** (1 hour)
   - Implement `from_package()` class method
   - Implement `from_schemas()` class method
   - Implement `resolve_type()`, `find_element()`, `find_attribute()`
   - Add comprehensive tests

2. **Create SchemaRepositoryStrategy** (1 hour)
   - Implement resolution strategy interface
   - Build name candidate generation
   - Add priority-based resolution
   - Add comprehensive tests

3. **Update TypeResolutionResult** (30 min)
   - Add schema_repository metadata fields
   - Support qualified name tracking
   - Add namespace information

### Phase 2: Integration (3-4 hours)

1. **Update MappingGenerator** (2 hours)
   - Accept SchemaRepositoryAdapter in constructor
   - Build resolution engine with new strategy
   - Update class and attribute mapping logic
   - Update tests to use mock repository

2. **Update CLI** (1 hour)
   - Add `--lxr` option to generate command
   - Add `--namespace-mappings` option
   - Update help text and examples
   - Add integration tests

3. **Create Helper Scripts** (1 hour)
   - Script to build LXR packages from XSD directories
   - Script to validate LXR packages
   - Script to inspect LXR package contents

### Phase 3: Testing (2-3 hours)

1. **Unit Tests** (1 hour)
   - Test SchemaRepositoryAdapter with mock repository
   - Test SchemaRepositoryStrategy with various name formats
   - Test name candidate generation

2. **Integration Tests** (1-2 hours)
   - Build test LXR package from fixtures
   - Test complete mapping workflow with LXR
   - Verify resolution priority order
   - Test statistics and validation

### Phase 4: Documentation (1-2 hours)

1. **Update README** (30 min)
   - Add LXR package usage section
   - Update installation instructions
   - Add examples

2. **Create Architecture Doc** (30 min)
   - Document integration points
   - Explain resolution strategies
   - Show data flow diagrams

3. **Create Usage Guide** (30 min)
   - How to build LXR packages
   - How to use with lutaml-klin
   - Troubleshooting tips

## Example Usage

### Building LXR Package

```bash
# In lutaml-xsd directory
cd ~/src/lutaml/lutaml-xsd

# Create configuration
cat > config/plateau_schemas.yaml <<EOF
files:
  - /path/to/urbanObject.xsd
  - /path/to/urbanFunction.xsd

schema_location_mappings:
  - from: !ruby/regexp /(?:\.\.\/)+gml\/(.+\.xsd)$/
    to: "/path/to/gml/\\1"

namespace_mappings:
  - prefix: "uro"
    uri: "https://www.geospatial.jp/iur/uro/3.2"
  - prefix: "urf"
    uri: "https://www.geospatial.jp/iur/urf/3.2"
  - prefix: "gml"
    uri: "http://www.opengis.net/gml/3.2"
EOF

# Build package
bundle exec lutaml-xsd package build \
  config/plateau_schemas.yaml \
  --name "PLATEAU Schemas" \
  --version "3.2" \
  --xsd-mode include_all \
  --resolution-mode resolved \
  --serialization-format marshal \
  --output pkg/plateau.lxr \
  --validate
```

### Using LXR Package with lutaml-klin

```bash
# In lutaml-klin directory
cd ~/src/lutaml/lutaml-klin

# Generate mapping using LXR package
bundle exec exe/lutaml-klin generate \
  config/shapechange.xml \
  sources/xmi/plateau.xmi \
  pkg/plateau.lxr \
  output/mapping.yaml \
  --package "uro" \
  --namespace-mappings config/namespaces.yaml \
  --verbose

# Output shows resolution method for each type
# ✓ Resolved uro:BuildingType via schema_repository (confidence: 1.0)
# ✓ Resolved gml:CodeType via schema_repository (confidence: 1.0)
# ⚠ Unresolved xs::string - trying type_override
# ✓ Resolved xs::string → xs:string via type_override (confidence: 1.0)
```

### Programmatic Usage

```ruby
require 'lutaml/klin'

# Load LXR package
schema_repo = Lutaml::Klin::Repositories::SchemaRepositoryAdapter.from_package(
  'pkg/plateau.lxr',
  namespace_mappings: [
    { prefix: 'uro', uri: 'https://www.geospatial.jp/iur/uro/3.2' },
    { prefix: 'gml', uri: 'http://www.opengis.net/gml/3.2' }
  ]
)

# Query repository
result = schema_repo.resolve_type('gml:CodeType')
puts "Found: #{result.qualified_name}" if result.resolved?

# Get statistics
stats = schema_repo.statistics
puts "Total types: #{stats[:total_types]}"
puts "Namespaces: #{stats[:total_namespaces]}"

# Use in mapping generation
config = Lutaml::Klin::Shapechange::ConfigParser.parse('config.xml')
xmi = Lutaml::Klin::XmiNavigator.new('model.xmi')

generator = Lutaml::Klin::MappingGenerator.new(
  config: config,
  xmi_navigator: xmi,
  schema_repository: schema_repo
)

mapping = generator.generate_mapping('uro')
puts mapping.to_yaml
```

## Success Criteria

### Functional Requirements

- ✅ Load LXR packages in < 100ms
- ✅ Resolve qualified names in all three formats (prefixed, Clark, unprefixed)
- ✅ Achieve >95% resolution rate for PLATEAU schemas
- ✅ Track resolution method for each type
- ✅ Support multiple namespaces
- ✅ Handle cross-schema references

### Quality Requirements

- ✅ All tests passing
- ✅ Rubocop compliant
- ✅ Comprehensive documentation
- ✅ Examples work as documented
- ✅ Performance acceptable (<5s for complete PLATEAU mapping)

### Integration Requirements

- ✅ Works with existing CLI
- ✅ Compatible with ShapeChange configs
- ✅ Supports type overrides
- ✅ Generates valid YAML output

## Next Steps

1. **Immediate**: Create SchemaRepositoryAdapter
2. **Short term**: Implement SchemaRepositoryStrategy
3. **Medium term**: Update MappingGenerator
4. **Long term**: Full PLATEAU mapping test

**Estimated Total Time**: 8-12 hours

This integration will complete the lutaml-klin architecture, providing production-ready UML-to-XSD mapping with full schema awareness and validation.