# Unified Object-Oriented Architecture for lutaml-klin

## Executive Summary

This architecture redesigns lutaml-klin following strict OO principles to create a model-driven, extensible system for UML-to-XSD mapping with integrated validation and presentation.

**Key Principles Applied**:
- Single Responsibility: Each class has exactly one reason to change
- Open/Closed: Extensible through composition and strategy patterns
- MECE: Components are mutually exclusive, collectively exhaustive
- Immutability: Core domain models are immutable value objects
- Separation of Concerns: Clear 4-layer architecture
- Model-Driven: Business logic operates on rich domain models, not data structures

## Recommended Data Flow & User Experience

### Optimal Workflow (Single Unified Command)

```bash
# ONE command to rule them all
lutaml-klin process \
  --xmi sources/xmi/20251010-242.xmi \
  --config config/shapechange.xml \
  --lxr pkg/plateau_schemas.lxr \
  --packages "i-UR::**" \
  --output output/ \
  --generate-mappings \
  --generate-spa \
  --validate

# Output automatically created:
# output/
# ├── mappings/          # YAML mappings per package
# ├── validation/        # Validation reports
# └── spa/               # Interactive website
```

**Why This is Better**:
1. **Single command**: Users don't need to remember multiple commands
2. **Atomic operation**: All outputs consistent (same resolution pass)
3. **Efficient**: Parse XMI and resolve types once
4. **Progressive enhancement**: Can disable parts with flags
5. **Incremental output**: Shows progress as it works
6. **Natural data flow**: Parse → Resolve → Validate → Present

### Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                     4-Layer Architecture                          │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  1. PRESENTATION (CLI, Web UI)                         │     │
│  │     - Thin adapters, no business logic                 │     │
│  └─────────────────────┬──────────────────────────────────┘     │
│                        │                                          │
│  ┌─────────────────────▼──────────────────────────────────┐     │
│  │  2. APPLICATION (Use Cases, Workflows)                 │     │
│  │     ProcessingWorkflow: orchestrates all operations    │     │
│  │     - MappingWorkflow                                  │     │
│  │     - ValidationWorkflow                               │     │
│  │     - PresentationWorkflow                             │     │
│  └─────────────────────┬──────────────────────────────────┘     │
│                        │                                          │
│  ┌─────────────────────▼──────────────────────────────────┐     │
│  │  3. DOMAIN (Business Logic, Models)                    │     │
│  │     Pure OO, no I/O, immutable models                  │     │
│  │     - ResolutionEngine (strategy pattern)              │     │
│  │     - ValidationEngine (rules engine)                  │     │
│  │     - MappingModel (rich domain model)                 │     │
│  │     - PresentationModel (view models)                  │     │
│  └─────────────────────┬──────────────────────────────────┘     │
│                        │                                          │
│  ┌─────────────────────▼──────────────────────────────────┐     │
│  │  4. INFRASTRUCTURE (External Systems)                  │     │
│  │     Repositories pattern for all I/O                   │     │
│  │     - SchemaRepository (wraps lutaml-xsd)              │     │
│  │     - UmlRepository (wraps lutaml-xmi)                 │     │
│  │     - ConfigRepository (ShapeChange config)            │     │
│  │     - OutputRepository (file system)                   │     │
│  └────────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────────┘
```

## Layer 1: Presentation (CLI)

```ruby
module Lutaml::Klin::Presentation
  # Single unified command (recommended UX)
  class ProcessCommand < Command
    option :xmi, required: true
    option :config, required: true
    option :lxr, required: true
    option :packages, default: "**"
    option :output, required: true
    option :generate_mappings, default: true
    option :generate_spa, default: true
    option :validate, default: true

    def execute
      # Delegate to application layer
      workflow = Application::ProcessingWorkflow.new(
        output_observer: ProgressObserver.new(output)
      )

      result = workflow.execute(
        xmi_path: options[:xmi],
        config_path: options[:config],
        lxr_path: options[:lxr],
        package_filter: options[:packages],
        output_path: options[:output],
        generate_mappings: options[:generate_mappings],
        generate_spa: options[:generate_spa],
        validate: options[:validate]
      )

      display_summary(result)
    end
  end
end
```

## Layer 2: Application (Workflows)

```ruby
module Lutaml::Klin::Application
  # Main workflow orchestrating all operations
  class ProcessingWorkflow
    def initialize(output_observer: NullObserver.new)
      @observer = output_observer
      @repositories = build_repositories
      @services = build_services
    end

    def execute(xmi_path:, config_path:, lxr_path:,
                package_filter:, output_path:, **options)

      # Step 1: Load all source data (I/O bound)
      @observer.progress(:loading, "Loading sources...")
      context = load_resolution_context(config_path, lxr_path)
      packages = load_uml_packages(xmi_path, package_filter)

      # Step 2: Build mappings (CPU bound, pure logic)
      @observer.progress(:mapping, "Building mappings...")
      mappings = build_mappings(packages, context)

      # Step 3: Generate outputs (I/O bound)
      outputs = []

      if options[:generate_mappings]
        @observer.progress(:output, "Generating YAML mappings...")
        outputs << generate_yaml_mappings(mappings, output_path)
      end

      if options[:validate]
        @observer.progress(:validation, "Validating mappings...")
        outputs << generate_validation_report(mappings, output_path)
      end

      if options[:generate_spa]
        @observer.progress(:spa, "Generating SPA website...")
        outputs << generate_spa_website(mappings, context, output_path)
      end

      # Return result summary
      ProcessingResult.new(
        mappings: mappings,
        outputs: outputs,
        statistics: calculate_statistics(mappings)
      )
    end

    private

    def build_mappings(packages, context)
      workflow = MappingWorkflow.new(
        resolution_engine: @services[:resolution_engine],
        mapping_service: @services[:mapping_service]
      )

      workflow.build_all_mappings(packages, context: context)
    end

    def generate_yaml_mappings(mappings, output_path)
      workflow = OutputWorkflow.new(
        serializer: Domain::Serializers::YamlSerializer.new
      )

      workflow.write_mappings(mappings, output_path: output_path)
    end

    def generate_validation_report(mappings, output_path)
      workflow = ValidationWorkflow.new(
        validation_engine: @services[:validation_engine],
        report_generators: [
          Domain::Reporters::JsonReporter.new,
          Domain::Reporters::MarkdownReporter.new
        ]
      )

      workflow.generate_reports(mappings, output_path: output_path)
    end

    def generate_spa_website(mappings, context, output_path)
      workflow = PresentationWorkflow.new(
        spa_generator: @services[:spa_generator]
      )

      workflow.generate_spa(
        mappings: mappings,
        context: context,
        output_path: output_path
      )
    end
  end
end
```

## Layer 3: Domain (Core Business Logic)

### Domain Models (Immutable Value Objects)

```ruby
module Lutaml::Klin::Domain::Models
  # Base for all domain models
  class DomainModel
    def initialize(attributes)
      attributes.each do |key, value|
        instance_variable_set("@#{key}", deep_freeze(value))
      end
      freeze
    end

    private

    def deep_freeze(value)
      case value
      when Array then value.map { |v| deep_freeze(v) }.freeze
      when Hash then value.transform_values { |v| deep_freeze(v) }.freeze
      else value.freeze
      end
    end
  end

  # Complete package mapping with metadata
  class PackageMapping < DomainModel
    attr_reader :package, :namespace, :classes, :metadata

    def resolution_rate
      return 1.0 if classes.empty?
      classes.count(&:fully_resolved?).to_f / classes.size
    end

    def statistics
      {
        total_classes: classes.size,
        resolved_classes: classes.count(&:fully_resolved?),
        total_attributes: classes.sum { |c| c.attributes.size },
        resolved_attributes: classes.sum { |c| c.resolved_attribute_count },
        resolution_rate: resolution_rate
      }
    end
  end

  # Class mapping with full resolution chain
  class ClassMapping < DomainModel
    attr_reader :uml_class, :xsd_type, :resolution_result,
                :attribute_mappings

    def fully_resolved?
      resolution_result.resolved? &&
        attribute_mappings.all? { |am| am.resolution_result.resolved? }
    end

    def resolved_attribute_count
      attribute_mappings.count { |am| am.resolution_result.resolved? }
    end

    def unresolved_attributes
      attribute_mappings.reject { |am| am.resolution_result.resolved? }
    end
  end

  # Resolution result (value object)
  class ResolutionResult < DomainModel
    attr_reader :status, :target, :method, :confidence,
                :metadata, :error

    def resolved?
      status == :resolved
    end

    def partial?
      status == :partial
    end

    def unresolved?
      status == :unresolved
    end

    # Factory methods for clarity
    def self.resolved(target:, method:, confidence: 1.0, metadata: {})
      new(
        status: :resolved,
        target: target,
        method: method,
        confidence: confidence,
        metadata: metadata,
        error: nil
      )
    end

    def self.unresolved(error:, metadata: {})
      new(
        status: :unresolved,
        target: nil,
        method: :none,
        confidence: 0.0,
        metadata: metadata,
        error: error
      )
    end
  end
end
```

### Domain Services (Pure Business Logic)

```ruby
module Lutaml::Klin::Domain::Services
  # Resolution engine using strategy pattern
  class ResolutionEngine
    def initialize(strategies:)
      @strategies = strategies
    end

    # Add new strategy at runtime (Open/Closed)
    def add_strategy(strategy)
      ResolutionEngine.new(strategies: @strategies + [strategy])
    end

    # Resolve using chain of responsibility
    def resolve(source, context:)
      @strategies.each do |strategy|
        next unless strategy.applicable?(source, context)

        result = strategy.resolve(source, context: context)
        return result if result.resolved?
      end

      ResolutionResult.unresolved(
        error: "No strategy could resolve #{source.name}",
        metadata: {
          attempted_strategies: @strategies.map(&:name),
          source_type: source.class.name
        }
      )
    end
  end

  # Strategy interface (Open/Closed Principle)
  class ResolutionStrategy
    def applicable?(source, context)
      raise NotImplementedError
    end

    def resolve(source, context:)
      raise NotImplementedError
    end

    def name
      self.class.name.split('::').last
    end
  end

  # Concrete strategies (easily extensible)
  class TypeOverrideStrategy < ResolutionStrategy
    def applicable?(source, context)
      context.type_overrides.key?(source.name)
    end

    def resolve(source, context:)
      target = context.type_overrides[source.name]

      ResolutionResult.resolved(
        target: target,
        method: :type_override,
        confidence: 1.0,
        metadata: {override_value: target}
      )
    end
  end

  class SchemaRepositoryStrategy < ResolutionStrategy
    def initialize(repository)
      @repository = repository
    end

    def applicable?(source, context)
      true # Always try as fallback
    end

    def resolve(source, context:)
      qualified_name = normalize_qualified_name(source.name)
      result = @repository.resolve_type(qualified_name: qualified_name)

      return ResolutionResult.un