# lutaml-klin Final Implementation Plan: LUR+LXR Integration

## Status: Ready to Implement

Both repository systems are now available:
- ✅ **LUR** (LutaML UML Repository) in `lutaml` gem - Load from `.lur` packages
- ✅ **LXR** (LutaML XSD Repository) in `lutaml-xsd` gem - Load from `.lxr` packages

lutaml-klin can now be a **pure orchestration layer** with no parsing logic.

## Architecture Summary

```
┌────────────────────────────────────────────────────────────┐
│  Input: Pre-built Packages (Built Once, Used Many Times)   │
│                                                             │
│  LUR Package (.lur)     LXR Package (.lxr)                 │
│  UML Model from XMI     XSD Schemas                        │
│  Built by: lutaml       Built by: lutaml-xsd               │
│  Load time: <100ms      Load time: <100ms                  │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────┐
│  lutaml-klin: Pure Orchestration (No Parsing!)             │
│                                                             │
│  1. Load LUR → UmlRepository API                           │
│  2. Load LXR → SchemaRepository API                        │
│  3. Load ShapeChange Config                                │
│  4. Execute Resolution (Strategy Pattern)                  │
│  5. Generate Outputs (YAML, Reports, SPA)                  │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────────┐
│  Output: Three Formats                                      │
│                                                             │
│  ├─ YAML Mappings (per package)                            │
│  ├─ Validation Reports (JSON/Markdown)                     │
│  └─ SPA Website (Interactive HTML/JS)                      │
└────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Repository Adapters (2-3 hours)

Create thin wrappers around `lutaml` and `lutaml-xsd` APIs.

**Files to create**:
1. `lib/lutaml/klin/repositories/uml_repository_adapter.rb`
2. `lib/lutaml/klin/repositories/schema_repository_adapter.rb`

**Purpose**: Isolate external dependencies, provide domain-specific interface

### Phase 2: Resolution Engine (4-6 hours)

Implement strategy pattern for type resolution.

**Files to create**:
1. `lib/lutaml/klin/domain/resolution_engine.rb`
2. `lib/lutaml/klin/domain/strategies/type_override_strategy.rb`
3. `lib/lutaml/klin/domain/strategies/shapechange_strategy.rb`
4. `lib/lutaml/klin/domain/strategies/schema_repository_strategy.rb`

**Purpose**: Pure business logic for UML type to XSD type resolution

### Phase 3: Enhanced Mapping Models (3-4 hours)

Update mapping models to track resolution status and metadata.

**Files to create/update**:
1. `lib/lutaml/klin/models/mapping/resolution_result.rb` (new)
2. Update `lib/lutaml/klin/models/mapping/class_mapping.rb`
3. Update `lib/lutaml/klin/models/mapping/attribute_mapping.rb`
4. Update `lib/lutaml/klin/models/mapping/package_mapping.rb`

**Purpose**: Rich domain models with resolution tracking

### Phase 4: Mapping Workflow (6-8 hours)

Core mapping generation using repositories and resolution strategies.

**Files to create**:
1. `lib/lutaml/klin/application/mapping_workflow.rb`
2. `lib/lutaml/klin/domain/services/mapping_service.rb`

**Purpose**: Orchestrate UML-to-XSD mapping with resolution tracking

### Phase 5: Validation Workflow (4-5 hours)

Generate validation reports showing resolution status.

**Files to create**:
1. `lib/lutaml/klin/application/validation_workflow.rb`
2. `lib/lutaml/klin/domain/reporters/json_reporter.rb`
3. `lib/lutaml/klin/domain/reporters/markdown_reporter.rb`

**Purpose**: Comprehensive validation and reporting

### Phase 6: SPA Generator (10-12 hours)

Generate interactive website for browsing mappings.

**Files to create**:
1. `lib/lutaml/klin/application/spa_workflow.rb`
2. `lib/lutaml/klin/templates/spa/index.html`
3. `lib/lutaml/klin/templates/spa/assets/css/style.css`
4. `lib/lutaml/klin/templates/spa/assets/js/app.js`
5. `lib/lutaml/klin/domain/presenters/spa_data_builder.rb`

**Purpose**: User-friendly web interface for mappings

### Phase 7: Main Process Command (3-4 hours)

Unified CLI command orchestrating all workflows.

**Files to create/update**:
1. Update `lib/lutaml/klin/cli.rb`
2. `lib/lutaml/klin/commands/process_command.rb`
3. `lib/lutaml/klin/application/processing_workflow.rb`

**Purpose**: Single command user experience

### Phase 8: Testing & Documentation (6-8 hours)

Comprehensive tests and documentation.

**Files to create**:
1. Update all spec files
2. Create integration test suite
3. Update `README.adoc`
4. Create usage examples

## Implementation Details

### Dependencies (Gemfile)

```ruby
gem 'lutaml', '~> 1.0'           # For LUR packages
gem 'lutaml-xsd', '~> 1.0'       # For LXR packages
gem 'lutaml-model', '~> 0.7'     # For YAML serialization
gem 'thor', '~> 1.3'             # For CLI
```

### Core API Flow

```ruby
# Load repositories
uml_repo = Lutaml::Xmi::UmlRepository.from_package("plateau.lur")
xsd_repo = Lutaml::Xsd::SchemaRepository.from_package("schemas.lxr")

# Find UML package
uml_pkg = uml_repo.find_package("ModelRoot::i-UR::urf")

# For each class
uml_pkg.classes.each do |uml_class|
  # Resolve to XSD type
  xsd_result = xsd_repo.resolve_type(qualified_name: "urf:#{uml_class.name}Type")

  if xsd_result.found?
    # Map attributes
    uml_class.attributes.each do |attr|
      # Resolve attribute type
      xsd_type_result = xsd_repo.resolve_type(qualified_name: attr.type)
      # Track resolution status
      # Create mapping
    end
  end
end
```

### Unified CLI Command

```bash
lutaml-klin process \
  --lur plateau_uml.lur \
  --lxr plateau_schemas.lxr \
  --config shapechange.xml \
  --packages "ModelRoot::i-UR::**" \
  --output output/ \
  --type-overrides overrides.yaml \
  --generate-mappings \
  --generate-spa \
  --validate
```

## Total Estimate

- **Phase 1**: Repository Adapters (2-3h)
- **Phase 2**: Resolution Engine (4-6h)
- **Phase 3**: Enhanced Models (3-4h)
- **Phase 4**: Mapping Workflow (6-8h)
- **Phase 5**: Validation Workflow (4-5h)
- **Phase 6**: SPA Generator (10-12h)
- **Phase 7**: Process Command (3-4h)
- **Phase 8**: Testing & Docs (6-8h)

**Total**: 38-50 hours for complete implementation

## Next Steps

1. ✅ Architecture plans complete
2. ✅ Both LUR and LXR systems available
3. → Begin Phase 1: Repository Adapters
4. → Proceed through phases sequentially
5. → Test with PLATEAU data
6. → Deploy complete system

Ready to begin implementation!