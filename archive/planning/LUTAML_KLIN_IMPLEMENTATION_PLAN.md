# lutaml-klin Implementation Plan: LUR+LXR Mapping & SPA Generation

## Overview

This document provides the complete implementation plan for lutaml-klin, now that both lutaml-xmi (LUR packages) and lutaml-xsd (LXR packages) provide repository systems. The implementation focuses on:

1. **Pure orchestration** - No XMI/XSD parsing, only package loading
2. **Resolution-based mapping** - Strategy pattern for flexible type resolution
3. **YAML export** - Machine-readable mapping files
4. **SPA generation** - Interactive website showing resolved/unresolved mappings
5. **Validation** - Comprehensive reports on mapping completeness

## Architectural Foundation

```
┌────────────────────────────────────────────────────────────┐
│  lutaml-klin: Pure Orchestration Layer                     │
│                                                             │
│  Inputs:                                                    │
│    ├─ LUR package (from lutaml-xmi)                        │
│    ├─ LXR package (from lutaml-xsd)                        │
│    └─ ShapeChange config (XML)                             │
│                                                             │
│  Processing:                                                │
│    ├─ Load repositories (instant <200ms)                   │
│    ├─ Apply resolution strategies                          │
│    ├─ Build mapping models                                 │
│    └─ Track resolution status                              │
│                                                             │
│  Outputs:                                                   │
│    ├─ YAML mappings (per package)                          │
│    ├─ Validation reports (JSON/Markdown)                   │
│    └─ SPA website (interactive HTML/JS)                    │
└────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Core Infrastructure (6-8 hours)

#### 1.1 Repository Adapters (2-3h)

Create thin wrappers around LUR and LXR APIs for lutaml-klin's needs.

**File**: `lib/lutaml/klin/repositories/uml_repository_adapter.rb`

```ruby
module Lutaml::Klin::Repositories
  # Adapter for lutaml-xmi UmlRepository
  class UmlRepositoryAdapter
    def initialize(lur_path)
      require 'lutaml/xmi'
      @repository = Lutaml::Xmi::UmlRepository.from_package(lur_path)
    end

    def find_package(path)
      @repository.find_package(path)
    end

    def classes_in_package(package_path, recursive: false)
      @repository.classes_in_package(package_path, recursive: recursive)
    end

    def statistics
      @repository.statistics
    end
  end
end
```

**File**: `lib/lutaml/klin/repositories/xsd_repository_adapter.rb`

```ruby
module Lutaml::Klin::Repositories
  # Adapter for lutaml-xsd SchemaRepository
  class XsdRepositoryAdapter
    def initialize(lxr_path)
      require 'lutaml/xsd'
      @repository = Lutaml::Xsd::SchemaRepository.from_package(lxr_path)
    end

    def resolve_type(qualified_name)
      @repository.resolve_type(qualified_name: qualified_name)
    end

    def find_type(name, namespace: nil)
      @repository.find_type(name: name, namespace: namespace)
    end

    def statistics
      @repository.statistics
    end
  end
end
```

#### 1.2 Domain Models (2-3h)

Enhanced mapping models with resolution tracking.

**File**: `lib/lutaml/klin/domain/models/mapping_result.rb`

```ruby
module Lutaml::Klin::Domain::Models
  # Immutable mapping result with full resolution chain
  class MappingResult < Lutaml::Model::Serializable
    attribute :package_mapping, PackageMapping
    attribute :statistics, Hash
    attribute :metadata, Hash

    yaml do
      map "package_mapping", to: :package_mapping
      map "statistics", to: :statistics
      map "metadata", to: :metadata
    end

    def resolution_rate
      return 1.0 if statistics[:total_attributes] == 0
      statistics[:resolved_attributes].to_f / statistics[:total_attributes]
    end
  end

  # Package-level mapping
  class PackageMapping < Lutaml::Model::Serializable
    attribute :uml_package_path, :string
    attribute :xsd_namespace, :string
    attribute :class_mappings, ClassMapping, collection: true
    attribute :created_at, :string

    yaml do
      map "uml_package_path", to: :uml_package_path
      map "xsd_namespace", to: :xsd_namespace
      map "class_mappings", to: :class_mappings
      map "created_at", to: :created_at
    end
  end

  # Class-level mapping with resolution status
  class ClassMapping < Lutaml::Model::Serializable
    attribute :uml_class_name, :string
    attribute :uml_qualified_name, :string
    attribute :uml_stereotype, :string
    attribute :uml_documentation, :string

    attribute :xsd_element_name, :string
    attribute :xsd_type_name, :string
    attribute :xsd_namespace, :string
    attribute :xsd_documentation, :string

    attribute :resolution_status, :string  # resolved, partial, unresolved
    attribute :resolution_method, :string  # override, shapechange, repository
    attribute :resolution_confidence, :float

    attribute :attribute_mappings, AttributeMapping, collection: true

    yaml do
      map "uml_class_name", to: :uml_class_name
      map "uml_qualified_name", to: :uml_qualified_name
      map "uml_stereotype", to: :uml_stereotype
      map "uml_documentation", to: :uml_documentation
      map "xsd_element_name", to: :xsd_element_name
      map "xsd_type_name", to: :xsd_type_name
      map "xsd_namespace", to: :xsd_namespace
      map "xsd_documentation", to: :xsd_documentation
      map "resolution_status", to: :resolution_status
      map "resolution_method", to: :resolution_method
      map "resolution_confidence", to: :resolution_confidence
      map "attribute_mappings", to: :attribute_mappings
    end

    def fully_resolved?
      resolution_status == 'resolved' &&
        attribute_mappings.all? { |am| am.resolution_status == 'resolved' }
    end
  end

  # Attribute-level mapping with resolution details
  class AttributeMapping < Lutaml::Model::Serializable
    attribute :uml_attribute_name, :string
    attribute :uml_type, :string
    attribute :uml_multiplicity, :string
    attribute :uml_documentation, :string

    attribute :xsd_element_name, :string
    attribute :xsd_type_name, :string
    attribute :xsd_namespace, :string
    attribute :xsd_min_occurs, :string
    attribute :xsd_max_occurs, :string
    attribute :xsd_documentation, :string

    attribute :resolution_status, :string
    attribute :resolution_method, :string
    attribute :resolution_error, :string

    yaml do
      map "uml_attribute_name", to: :uml_attribute_name
      map "uml_type", to: :uml_type
      map "uml_multiplicity", to: :uml_multiplicity
      map "uml_documentation", to: :uml_documentation
      map "xsd_element_name", to: :xsd_element_name
      map "xsd_type_name", to: :xsd_type_name
      map "xsd_namespace", to: :xsd_namespace
      map "xsd_min_occurs", to: :xsd_min_occurs
      map "xsd_max_occurs", to: :xsd_max_occurs
      map "xsd_documentation", to: :xsd_documentation
      map "resolution_status", to: :resolution_status
      map "resolution_method", to: :resolution_method
      map "resolution_error", to: :resolution_error
    end
  end
end
```

#### 1.3 Resolution Strategies (2h)

**File**: `lib/lutaml/klin/domain/services/resolution_engine.rb`

```ruby
module Lutaml::Klin::Domain::Services
  # Resolution engine using strategy pattern
  class ResolutionEngine
    def initialize(strategies)
      @strategies = strategies
    end

    def resolve(uml_element, context:)
      @strategies.each do |strategy|
        next unless strategy.applicable?(uml_element, context)

        result = strategy.resolve(uml_element, context: context)
        return result if result.resolved?
      end

      # Return unresolved result
      ResolutionResult.new(
        status: 'unresolved',
        error: "No strategy could resolve #{uml_element.name}",
        metadata: {
          attempted_strategies: @strategies.map(&:class).map(&:name)
        }
      )
    end
  end

  # Base strategy class
  class ResolutionStrategy
    def applicable?(uml_element, context)
      raise NotImplementedError
    end

    def resolve(uml_element, context:)
      raise NotImplementedError
    end
  end

  # Type override strategy (highest priority)
  class TypeOverrideStrategy < ResolutionStrategy
    def applicable?(uml_element, context)
      context.type_overrides&.key?(uml_element.type)
    end

    def resolve(uml_element, context:)
      override_type = context.type_overrides[uml_element.type]

      # Now resolve the override type via XSD repository
      xsd_result = context.xsd_repository.resolve_type(override_type)

      if xsd_result.found?
        ResolutionResult.new(
          status: 'resolved',
          xsd_type: xsd_result.type,
          xsd_namespace: xsd_result.namespace,
          method: 'type_override',
          confidence: 1.0
        )
      else
        ResolutionResult.new(
          status: 'unresolved',
          error: "Override type #{override_type} not found in XSD repository"
        )
      end
    end
  end

  # ShapeChange mapping strategy
  class ShapeChangeMappingStrategy < ResolutionStrategy
    def applicable?(uml_element, context)
      context.shapechange_config.has_type_mapping?(uml_element.type)
    end

    def resolve(uml_element, context:)
      mapping = context.shapechange_config.find_type_mapping(uml_element.type)
      xsd_type = mapping.xml_type

      # Resolve via XSD repository
      xsd_result = context.xsd_repository.resolve_type(xsd_type)

      if xsd_result.found?
        ResolutionResult.new(
          status: 'resolved',
          xsd_type: xsd_result.type,
          xsd_namespace: xsd_result.namespace,
          method: 'shapechange_mapping',
          confidence: 0.95,
          metadata: { encoding_rule: mapping.encoding_rule }
        )
      else
        ResolutionResult.new(
          status: 'unresolved',
          error: "Mapped type #{xsd_type} not found in XSD repository"
        )
      end
    end
  end

  # XSD repository resolution (fallback)
  class XsdRepositoryStrategy < ResolutionStrategy
    def applicable?(uml_element, context)
      true  # Always applicable as fallback
    end

    def resolve(uml_element, context:)
      # Normalize UML type name (EA uses "::" instead of ":")
      normalized_type = uml_element.type.gsub('::', ':')

      xsd_result = context.xsd_repository.resolve_type(normalized_type)

      if xsd_result.found?
        ResolutionResult.new(
          status: 'resolved',
          xsd_type: xsd_result.type,
          xsd_namespace: xsd_result.namespace,
          method: 'xsd_repository',
          confidence: 0.9,
          metadata: { schema_file: xsd_result.schema_file }
        )
      else
        ResolutionResult.new(
          status: 'unresolved',
          error: "Type #{normalized_type} not found in XSD repository"
        )
      end
    end
  end

  # Resolution result value object
  class ResolutionResult
    attr_reader :status, :xsd_type, :xsd_namespace, :method,
                :confidence, :error, :metadata

    def initialize(attributes)
      @status = attributes[:status]
      @xsd_type = attributes[:xsd_type]
      @xsd_namespace = attributes[:xsd_namespace]
      @method = attributes[:method]
      @confidence = attributes[:confidence] || 0.0
      @error = attributes[:error]
      @metadata = attributes[:metadata] || {}
    end

    def resolved?
      status == 'resolved'
    end
  end
end
```

### Phase 2: Mapping Workflow (8-10 hours)

#### 2.1 Mapping Service (4-5h)

**File**: `lib/lutaml/klin/application/mapping_workflow.rb`

```ruby
module Lutaml::Klin::Application
  class MappingWorkflow
    def initialize(uml_repository:, xsd_repository:, shapechange_config:,
                   type_overrides: {})
      @uml_repo = uml_repository
      @xsd_repo = xsd_repository
      @config = shapechange_config
      @type_overrides = type_overrides

      # Build resolution engine with strategies
      @resolution_engine = Domain::Services::ResolutionEngine.new([
        Domain::Services::TypeOverrideStrategy.new,
        Domain::Services::ShapeChangeMappingStrategy.new,
        Domain::Services::XsdRepositoryStrategy.new
      ])
    end

    def build_mapping_for_package(uml_package_path)
      # Find UML package
      uml_package = @uml_repo.find_package(uml_package_path)
      raise ArgumentError, "Package not found: #{uml_package_path}" unless uml_package

      # Determine XSD namespace for this package
      xsd_namespace = determine_namespace(uml_package)

      # Get all classes in package
      uml_classes = @uml_repo.classes_in_package(uml_package_path)

      # Build class mappings
      class_mappings = uml_classes.map do |uml_class|
        build_class_mapping(uml_class, xsd_namespace)
      end

      # Create package mapping
      Domain::Models::PackageMapping.new(
        uml_package_path: uml_package_path,
        xsd_namespace: xsd_namespace,
        class_mappings: class_mappings,
        created_at: Time.now.utc.iso8601
      )
    end

    private

    def build_class_mapping(uml_class, xsd_namespace)
      # Resolve class to XSD type
      class_resolution = resolve_class_to_xsd_type(uml_class, xsd_namespace)

      # Build attribute mappings
      attribute_mappings = uml_class.attributes.map do |uml_attr|
        build_attribute_mapping(uml_attr, class_resolution)
      end

      # Determine overall resolution status
      resolution_status = determine_resolution_status(
        class_resolution,
        attribute_mappings
      )

      Domain::Models::ClassMapping.new(
        uml_class_name: uml_class.name,
        uml_qualified_name: uml_class.qualified_name,
        uml_stereotype: uml_class.stereotype,
        uml_documentation: uml_class.documentation,
        xsd_element_name: class_resolution[:element_name],
        xsd_type_name: class_resolution[:type_name],
        xsd_namespace: class_resolution[:namespace],
        xsd_documentation: class_resolution[:documentation],
        resolution_status: resolution_status,
        resolution_method: class_resolution[:method],
        resolution_confidence: class_resolution[:confidence],
        attribute_mappings: attribute_mappings
      )
    end

    def build_attribute_mapping(uml_attr, class_resolution_context)
      # Create resolution context
      context = ResolutionContext.new(
        xsd_repository: @xsd_repo,
        shapechange_config: @config,
        type_overrides: @type_overrides
      )

      # Resolve attribute type
      resolution = @resolution_engine.resolve(uml_attr, context: context)

      if resolution.resolved?
        Domain::Models::AttributeMapping.new(
          uml_attribute_name: uml_attr.name,
          uml_type: uml_attr.type,
          uml_multiplicity: uml_attr.multiplicity,
          uml_documentation: uml_attr.documentation,
          xsd_element_name: derive_xsd_element_name(uml_attr),
          xsd_type_name: resolution.xsd_type.name,
          xsd_namespace: resolution.xsd_namespace,
          xsd_min_occurs: map_multiplicity_lower(uml_attr.multiplicity),
          xsd_max_occurs: map_multiplicity_upper(uml_attr.multiplicity),
          xsd_documentation: resolution.xsd_type.documentation,
          resolution_status: 'resolved',
          resolution_method: resolution.method
        )
      else
        Domain::Models::AttributeMapping.new(
          uml_attribute_name: uml_attr.name,
          uml_type: uml_attr.type,
          uml_multiplicity: uml_attr.multiplicity,
          uml_documentation: uml_attr.documentation,
          resolution_status: 'unresolved',
          resolution_error: resolution.error
        )
      end
    end

    def resolve_class_to_xsd_type(uml_class, xsd_namespace)
      # Try with Type suffix (ShapeChange convention)
      type_name = "#{xsd_namespace_prefix(xsd_namespace)}:#{uml_class.name}Type"
      result = @xsd_repo.resolve_type(type_name)

      if result.found?
        {
          element_name: "#{xsd_namespace_prefix(xsd_namespace)}:#{uml_class.name}",
          type_name: type_name,
          namespace: xsd_namespace,
          documentation: result.type.documentation,
          method: 'naming_convention',
          confidence: 0.95
        }
      else
        {
          element_name: nil,
          type_name: nil,
          namespace: xsd_namespace,
          documentation: nil,
          method: 'unresolved',
          confidence: 0.0
        }
      end
    end

    def determine_namespace(uml_package)
      # Look up in ShapeChange config
      package_info = @config.package_infos.find do |pi|
        pi.package_name == uml_package.name
      end

      package_info&.namespace || determine_namespace_by_convention(uml_package)
    end

    def determine_resolution_status(class_resolution, attribute_mappings)
      return 'unresolved' unless class_resolution[:type_name]

      unresolved_attrs = attribute_mappings.count { |am| am.resolution_status == 'unresolved' }
      return 'resolved' if unresolved_attrs == 0
      return 'partial' if unresolved_attrs < attribute_mappings.size
      'unresolved'
    end
  end
end
```

#### 2.2 Main Process Command (2-3h)

**File**: `lib/lutaml/klin/cli.rb`

```ruby
module Lutaml::Klin
  class Cli < Thor
    desc "process", "Process UML and XSD packages to generate mappings and outputs"
    option :lur, required: true, desc: "LUR package path"
    option :lxr, required: true, desc: "LXR package path"
    option :config, required: true, desc: "ShapeChange config XML path"
    option :packages, default: "**", desc: "Package filter pattern"
    option :output, required: true, desc: "Output directory"
    option :type_overrides, desc: "Type override YAML file"
    option :generate_mappings, type: :boolean, default: true
    option :generate_spa, type: :boolean, default: true
    option :validate, type: :boolean, default: true

    def process
      # Execute workflow
      workflow = Application::ProcessingWorkflow.new

      result = workflow.execute(
        lur_path: options[:lur],
        lxr_path: options[:lxr],
        config_path: options[:config],
        package_filter: options[:packages],
        output_path: options[:output],
        type_overrides_path: options[:type_overrides],
        generate_mappings: options[:generate_mappings],
        generate_spa: options[:generate_spa],
        validate: options[:validate]
      )

      display_summary(result)
    end

    private

    def display_summary(result)
      puts "\n" + "=" * 60
      puts "Processing Complete"
      puts "=" * 60

      puts "\nStatistics:"
      puts "  Total Packages: #{result.statistics[:total_packages]}"
      puts "  Total Classes: #{result.statistics[:total_classes]}"
      puts "  Total Attributes: #{result.statistics[:total_attributes]}"
      puts "  Resolved Classes: #{result.statistics[:resolved_classes]}"
      puts "  Resolved Attributes: #{result.statistics[:resolved_attributes]}"
      puts "  Resolution Rate: #{(result.statistics[:resolution_rate] * 100).round(1)}%"

      puts "\nOutputs:"
      result.outputs.each do |output|
        puts "  ✓ #{output}"
      end

      puts "\n" + "=" * 60
    end
  end
end
```

### Phase 3: SPA Generator (10-12 hours)

#### 3.1 SPA Generator Service (6-8h)

**File**: `lib/lutaml/klin/application/spa_workflow.rb`

```ruby
module Lutaml::Klin::Application
  class SpaWorkflow
    def generate(mappings:, output_path:)
      # Create output directories
      FileUtils.mkdir_p(File.join(output_path, 'data'))
      FileUtils.mkdir_p(File.join(output_path, 'assets', 'css'))
      FileUtils.mkdir_p(File.join(output_path, 'assets', 'js'))

      # Generate data files
      generate_mappings_json(mappings, output_path)
      generate_search_index(mappings, output_path)
      generate_statistics(mappings, output_path)

      # Generate HTML/CSS/JS
      generate_index_html(output_path)
      generate_css(output_path)
      generate_javascript(output_path)

      File.join(output_path, 'index.html')
    end

    private

    def generate_mappings_json(mappings, output_path)
      data = {
        version: "1.0",
        generated_at: Time.now.utc.iso8601,
        packages: mappings.map { |m| package_to_json(m) }
      }

      File.write(
        File.join(output_path, 'data', 'mappings.json'),
        JSON.pretty_generate(data)
      )
    end

    def package_to_json(package_mapping)
      {
        id: generate_id(package_mapping.uml_package_path),
        name: package_mapping.uml_package_path,
        namespace: package_mapping.xsd_namespace,
        classes: package_mapping.class_mappings.map { |cm| class_to_json(cm) }
      }
    end

    def class_to_json(class_mapping)
      {
        id: generate_id(class_mapping.uml_qualified_name),
        uml_name: class_mapping.uml_class_name,
        uml_qualified_name: class_mapping.uml_qualified_name,
        uml_stereotype: class_mapping.uml_stereotype,
        uml_documentation: class_mapping.uml_documentation,
        xsd_element: class_mapping.xsd_element_name,
        xsd_type: class_mapping.xsd_type_name,
        xsd_namespace: class_mapping.xsd_namespace,
        xsd_documentation: class_mapping.xsd_documentation,
        resolved: class_mapping.resolution_status == 'resolved',
        resolution_status: class_mapping.resolution_status,
        resolution_method: class_mapping.resolution_method,
        attributes: class_mapping.attribute_mappings.map { |am| attribute_to_json(am) }
      }
    end

    def generate_index_html(output_path)
      html = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>UML-XSD Mapping Browser</title>
          <link rel="stylesheet" href="assets/css/style.css">
        </head>
        <body>
          <div id="app">
            <header>
              <h1>UML-XSD Mapping Browser</h1>
              <div class="search-container">
                <input type="text" id="search" placeholder="Search classes, attributes..." />
              </div>
            </header>

            <div class="main-content">
              <aside class="sidebar">
                <h2>Packages</h2>
                <div id="package-tree"></div>

                <h2>Filters</h2>
                <div class="filters">
                  <label><input type="checkbox" id="filter-resolved" checked> Resolved</label>
                  <label><input type="checkbox" id="filter-partial" checked> Partial</label>
                  <label><input type="checkbox" id="filter-unresolved" checked> Unresolved</label>
                </div>

                <h2>Statistics</h2>
                <div id="statistics"></div>
              </aside>

              <main class="content">
                <div id="breadcrumb"></div>
                <div id="details"></div>
              </main>
            </div>
          </div>

          <script src="assets/js/app.js"></script>
        </body>
        </html>
      HTML

      File.write(File.join(output_path, 'index.html'), html)
    end
  end
end
```

### Phase 4: Validation & Reports (6-8 hours)

#### 4.1 Validation Workflow (4-5h)

**File**: `lib/lutaml/klin/application/validation_workflow.rb`

```ruby
module Lutaml::Klin::Application
  class ValidationWorkflow
    def generate_reports(mappings:, output_path:)
      validation_result = validate_mappings(mappings)

      # Generate JSON report
      json_path = File.join(output_path, 'validation_report.json')
      File.write(json_path, JSON.pretty_generate(validation_result))

      # Generate Markdown report
      md_path = File.join(output_path, 'validation_report.md')
      File.write(md_path, generate_markdown_report(validation_result))

      [json_path, md_path]
    end

    private

    def validate_mappings(mappings)
      total_classes = 0
      resolved_classes = 0
      total_attributes = 0
      resolved_attributes = 0
      unresolved_items = []

      mappings.each do |package_mapping|
        package_mapping.class_mappings.each do |class_mapping|
          total_classes += 1
          resolved_classes += 1 if class_mapping.fully_resolved?

          class_mapping.attribute_mappings.each do |attr_mapping|
            total_attributes += 1

            if attr_mapping.resolution_status == 'resolved'
              resolved_attributes += 1
            else
              unresolved_items << {
                type: 'attribute',
                package: package_mapping.uml_package_path,
                class: class_mapping.uml_class_name,
                attribute: attr_mapping.uml_attribute_name,
                uml_type: attr_mapping.uml_type,
                error: attr_mapping.resolution_error
              }
            end
          end
        end
      end

      {
        summary: {
          total_packages: mappings.size,
          total_classes: total_classes,
          resolved_classes: resolved_classes,
          total_attributes: total_attributes,
          resolved_attributes: resolved_attributes,
          resolution_rate: total_attributes > 0 ? resolved_attributes.to_f / total_attributes : 1.0
        },
        unresolved_items: unresolved_items,
        generated_at: Time.now.utc.iso8601
      }
    end

    def generate_markdown_report(validation_result)
      # Generate Markdown report (implementation details)
    end
  end
end
```

## Complete Workflow Example

```bash
# Step 1: Build LUR package (one-time, in lutaml-xmi)
cd ~/src/lutaml/lutaml
lutaml-xmi package build \
  ~/src/mn/mn-samples-plateau/sources/xmi/20251010-242.xmi \
  --output ~/packages/plateau_uml.lur \
  --name "PLATEAU UML Model" \
  --version "2024.1"

# Step 2: Build LXR package (one-time, in lutaml-xsd)
cd ~/src/lutaml/lutaml-xsd
lutaml-xsd package build config/plateau_schemas.yaml \
  --output ~/packages/plateau_xsd.lxr \
  --name "PLATEAU XSD Schemas" \
  --version "3.2"

# Step 3: Generate mappings and SPA (in lutaml-klin)
cd ~/src/lutaml/lutaml-klin
lutaml-klin process \
  --lur ~/packages/plateau_uml.lur \
  --lxr ~/packages/plateau_xsd.lxr \
  --config config/shapechange.xml \
  --packages "ModelRoot::i-UR::**" \
  --output output/ \
  --type-overrides config/type_overrides.yaml \
  --generate-mappings \
  --generate-spa \
  --validate

# Output structure:
# output/
# ├── mappings/
# │   ├── i-UR_urf.yaml
# │   └── i-UR_uro.yaml
# ├── validation/
# │   ├── validation_report.json
# │   └── validation_report.md
# └── spa/
#     ├── index.html
#     ├── data/
#     └── assets/
```

## Implementation Timeline

### Total: 30-40 hours

- **Phase 1**: Core Infrastructure (6-8h)
- **Phase 2**: Mapping Workflow (8-10h)
- **Phase 3**: SPA Generator (10-12h)
- **Phase 4**: Validation & Reports (6-8h)
- **Testing & Documentation**: (included in each phase)

## Success Criteria

✅ Load LUR package in <100ms
✅ Load LXR package in <100ms
✅ Map 1700+ classes with resolution tracking
✅ Generate YAML mappings per package
✅ Generate interactive SPA website
✅ Generate validation reports (JSON/Markdown)
✅ Achieve >90% type resolution rate
✅ Complete end-to-end process in <5 seconds

## Next Steps

1. Review and approve this implementation plan
2. Begin Phase 1: Core Infrastructure
3. Test with small XMI/XSD samples
4. Proceed through phases incrementally
5. Test with full PLATEAU packages
6. Document and release

This plan provides a complete, object-oriented implementation leveraging both LUR and LXR packages for optimal performance and clean architecture.