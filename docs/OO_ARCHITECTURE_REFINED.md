# Object-Oriented Architecture for lutaml-klin (Refined)

## Architectural Principles

This architecture follows strict OO principles:

1. **Single Responsibility Principle**: Each class has one clear purpose
2. **Open/Closed Principle**: Extensible without modification
3. **MECE**: Mutually Exclusive, Collectively Exhaustive components
4. **Separation of Concerns**: Clear boundaries between layers
5. **Model-Driven**: All business logic operates on immutable models
6. **Strategy Pattern**: Pluggable algorithms for resolution and presentation
7. **Repository Pattern**: Unified data access abstraction

## Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Presentation Layer                          │
│  (CLI, API, Web Interface)                                   │
│  - Thin adapters to application services                     │
│  - No business logic                                         │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                  Application Layer                           │
│  (Use Cases, Workflows)                                      │
│  - MappingWorkflow                                          │
│  - ValidationWorkflow                                        │
│  - PresentationWorkflow                                      │
│  - Orchestrates domain services                             │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   Domain Layer                               │
│  (Business Logic, Core Models)                               │
│  - ResolutionEngine (pure logic)                            │
│  - ValidationEngine (pure logic)                            │
│  - MappingModel (immutable)                                 │
│  - ResolutionStrategy (interface + implementations)         │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│              Infrastructure Layer                            │
│  (External Systems, I/O)                                     │
│  - SchemaRepository (lutaml-xsd wrapper)                    │
│  - XmiRepository (lutaml-xmi wrapper)                       │
│  - ConfigRepository (ShapeChange config)                    │
│  - FileSystemAdapter                                         │
└─────────────────────────────────────────────────────────────┘
```

## Core Domain Model (MECE)

### 1. Source Models (Immutable)

```ruby
module Lutaml::Klin::Domain::Source
  # Represents UML package from XMI (immutable)
  class UmlPackage
    attr_reader :id, :name, :namespace, :classes, :sub_packages

    def initialize(attributes)
      @id = attributes[:id]
      @name = attributes[:name]
      @namespace = attributes[:namespace]
      @classes = attributes[:classes].freeze
      @sub_packages = attributes[:sub_packages].freeze
      freeze
    end
  end

  # Represents UML class from XMI (immutable)
  class UmlClass
    attr_reader :id, :name, :stereotype, :attributes,
                :associations, :documentation

    def initialize(attributes)
      @id = attributes[:id]
      @name = attributes[:name]
      @stereotype = attributes[:stereotype]
      @attributes = attributes[:attributes].freeze
      @associations = attributes[:associations].freeze
      @documentation = attributes[:documentation]
      freeze
    end

    def feature_type?
      stereotype == 'featureType'
    end
  end

  # Represents XSD type from schema (immutable)
  class XsdType
    attr_reader :qualified_name, :namespace, :local_name,
                :category, :structure, :documentation

    def initialize(attributes)
      @qualified_name = attributes[:qualified_name]
      @namespace = attributes[:namespace]
      @local_name = attributes[:local_name]
      @category = attributes[:category]
      @structure = attributes[:structure].freeze
      @documentation = attributes[:documentation]
      freeze
    end

    def complex_type?
      category == :complex_type
    end
  end
end
```

### 2. Resolution Models (Immutable, Value Objects)

```ruby
module Lutaml::Klin::Domain::Resolution
  # Represents a resolution result (value object)
  class ResolutionResult
    attr_reader :source, :target, :status, :method,
                :confidence, :metadata

    def initialize(attributes)
      @source = attributes[:source]
      @target = attributes[:target]
      @status = attributes[:status] # :resolved, :partial, :unresolved
      @method = attributes[:method] # resolution method used
      @confidence = attributes[:confidence] # 0.0-1.0
      @metadata = attributes[:metadata].freeze
      freeze
    end

    def resolved?
      status == :resolved
    end

    def partial?
      status == :partial
    end
  end

  # Represents resolution context (immutable)
  class ResolutionContext
    attr_reader :shapechange_config, :namespace_mappings,
                :type_overrides, :encoding_rules

    def initialize(attributes)
      @shapechange_config = attributes[:shapechange_config]
      @namespace_mappings = attributes[:namespace_mappings].freeze
      @type_overrides = attributes[:type_overrides].freeze
      @encoding_rules = attributes[:encoding_rules].freeze
      freeze
    end
  end
end
```

### 3. Mapping Models (Immutable, Complete State)

```ruby
module Lutaml::Klin::Domain::Mapping
  # Represents complete mapping with resolution status
  class PackageMapping
    attr_reader :package, :classes, :resolution_summary

    def initialize(attributes)
      @package = attributes[:package] # UmlPackage
      @classes = attributes[:classes].freeze # Array<ClassMapping>
      @resolution_summary = attributes[:resolution_summary]
      freeze
    end

    def fully_resolved?
      classes.all?(&:fully_resolved?)
    end

    def resolution_rate
      return 1.0 if classes.empty?

      resolved = classes.count(&:fully_resolved?)
      resolved.to_f / classes.size
    end
  end

  # Represents class-level mapping (immutable)
  class ClassMapping
    attr_reader :uml_class, :xsd_type, :resolution_result,
                :attribute_mappings

    def initialize(attributes)
      @uml_class = attributes[:uml_class]
      @xsd_type = attributes[:xsd_type]
      @resolution_result = attributes[:resolution_result]
      @attribute_mappings = attributes[:attribute_mappings].freeze
      freeze
    end

    def fully_resolved?
      resolution_result.resolved? &&
        attribute_mappings.all?(&:resolved?)
    end
  end

  # Represents attribute-level mapping (immutable)
  class AttributeMapping
    attr_reader :uml_attribute, :xsd_element, :resolution_result

    def initialize(attributes)
      @uml_attribute = attributes[:uml_attribute]
      @xsd_element = attributes[:xsd_element]
      @resolution_result = attributes[:resolution_result]
      freeze
    end

    def resolved?
      resolution_result.resolved?
    end
  end
end
```

## Domain Services (Pure Business Logic)

### 1. Resolution Engine (Strategy Pattern)

```ruby
module Lutaml::Klin::Domain::Services
  # Pure resolution logic (no I/O)
  class ResolutionEngine
    def initialize(strategies:)
      @strategies = strategies # Array of ResolutionStrategy
    end

    # Resolve using chain of responsibility
    def resolve(source, context:)
      @strategies.each do |strategy|
        result = strategy.resolve(source, context: context)
        return result if result.resolved?
      end

      ResolutionResult.new(
        source: source,
        target: nil,
        status: :unresolved,
        method: :none,
        confidence: 0.0,
        metadata: {attempted_strategies: @strategies.map(&:name)}
      )
    end
  end

  # Strategy interface
  class ResolutionStrategy
    def resolve(source, context:)
      raise NotImplementedError
    end

    def name
      self.class.name.split('::').last
    end
  end

  # Concrete strategies (Open/Closed Principle)
  class TypeOverrideStrategy < ResolutionStrategy
    def resolve(source, context:)
      override = context.type_overrides[source.name]
      return unresolved unless override

      ResolutionResult.new(
        source: source,
        target: override,
        status: :resolved,
        method: :type_override,
        confidence: 1.0,
        metadata: {override_value: override}
      )
    end
  end

  class ShapeChangeStrategy < ResolutionStrategy
    def resolve(source, context:)
      mapping = context.shapechange_config.find_type_mapping(source.name)
      return unresolved unless mapping

      ResolutionResult.new(
        source: source,
        target: mapping.xml_type,
        status: :resolved,
        method: :shapechange_mapping,
        confidence: 0.95,
        metadata: {rule: mapping.encoding_rule}
      )
    end
  end

  class SchemaRepositoryStrategy < ResolutionStrategy
    def initialize(repository)
      @repository = repository
    end

    def resolve(source, context:)
      qualified_name = normalize_name(source.name)
      result = @repository.resolve_type(qualified_name: qualified_name)

      return unresolved unless result.found?

      ResolutionResult.new(
        source: source,
        target: result.type,
        status: :resolved,
        method: :schema_repository,
        confidence: 0.9,
        metadata: {
          namespace: result.namespace,
          schema_file: result.schema_file
        }
      )
    end

    private

    def normalize_name(name)
      name.gsub('::', ':') # EA fix
    end
  end
end
```

### 2. Mapping Service (Orchestration)

```ruby
module Lutaml::Klin::Domain::Services
  # Orchestrates resolution to build mappings
  class MappingService
    def initialize(resolution_engine:, observers: [])
      @resolution_engine = resolution_engine
      @observers = observers
    end

    # Build mapping for a package (pure function)
    def build_package_mapping(uml_package, context:)
      notify_progress(:package_start, uml_package)

      class_mappings = uml_package.classes.map do |uml_class|
        build_class_mapping(uml_class, context: context)
      end

      PackageMapping.new(
        package: uml_package,
        classes: class_mappings,
        resolution_summary: summarize_resolution(class_mappings)
      ).tap { |mapping| notify_progress(:package