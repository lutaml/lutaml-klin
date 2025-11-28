# Continuation Prompt: LutaML Klin - Next Phase

**Date Created**: 2025-01-28
**Purpose**: Resume development after Phase 1.5B completion
**Last Status**: YAML Mapping Output feature complete, all tests passing

---

## 🎯 Quick Context

You are continuing development of **lutaml-klin**, a Ruby-based tool that generates XSD schemas from UML models following ShapeChange encoding rules. The project has just completed Phase 1.5B: YAML Mapping Output feature.

**Current Achievement**:
- ✅ 100% ShapeChange XSD generation parity (37/37 rules)
- ✅ YAML mapping output for complete UML→XSD traceability
- ✅ 8/8 integration tests passing with zero regressions
- ✅ Production-ready for PLATEAU and ISO standards work

---

## 📚 Essential Reading

Before starting work, **READ THESE FILES** in order:

1. **[`CONTINUATION_PLAN_2025-01-28_NEXT_PHASE.md`](CONTINUATION_PLAN_2025-01-28_NEXT_PHASE.md)** 
   - Overall project direction and next phase options
   - Lessons learned from Phase 1.5B
   - Recommended path forward

2. **[`IMPLEMENTATION_STATUS_2025-01-28.md`](IMPLEMENTATION_STATUS_2025-01-28.md)**
   - Complete feature inventory
   - Test coverage details
   - Known limitations

3. **Memory Bank Files**:
   - [`.kilocode/rules/memory-bank/brief.md`](.kilocode/rules/memory-bank/brief.md)
   - [`.kilocode/rules/memory-bank/context.md`](.kilocode/rules/memory-bank/context.md)
   - [`.kilocode/rules/memory-bank/architecture.md`](.kilocode/rules/memory-bank/architecture.md)

4. **[`README.adoc`](README.adoc)**
   - User-facing documentation
   - Feature overview

---

## 🏗️ Architecture Quick Reference

### 4-Layer Clean Architecture

```
┌─ Input Layer ────────────────────────────────────────┐
│  • LUR Package (.lur) - UML models                    │
│  • LXR Package (.lxr) - XSD schemas                   │
│  • ShapeChange Config (XML)                           │
└───────────────────────────────────────────────────────┘
                         ↓
┌─ Application Layer ───────────────────────────────────┐
│  • ProcessingWorkflow - Main orchestrator             │
│  • MappingWorkflow - UML↔XSD mapping                  │
│  • ValidationWorkflow - Validation reports            │
│  • SpaWorkflow - Website generation                   │
└───────────────────────────────────────────────────────┘
                         ↓
┌─ Domain Layer ────────────────────────────────────────┐
│  • ResolutionEngine - Type resolution (Strategy)      │
│  • MappingService - Pure mapping logic                │
│  • XsdGenerator - XSD generation orchestrator         │
│  • MappingCollector - Transformation tracking (NEW)   │
└───────────────────────────────────────────────────────┘
                         ↓
┌─ Output Layer ────────────────────────────────────────┐
│  • YAML mappings (per package)                        │
│  • XSD schemas                                        │
│  • Validation reports (JSON/Markdown)                 │
│  • SPA website (HTML/JS/CSS)                          │
└───────────────────────────────────────────────────────┘
```

### Key Design Patterns
- **Strategy**: Type resolution (4 strategies in priority order)
- **Observer**: Mapping collection (passive, non-intrusive)
- **Repository**: Data access (UML & XSD)
- **Workflow**: Task orchestration
- **Value Object**: Immutable results

---

## 🚀 Quick Start Commands

### Verify Current State
```bash
# All tests should pass
bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb --format documentation

# Should output: 8 examples, 0 failures

# RuboCop should be clean
bundle exec rubocop
# Should output: 0 offenses detected
```

### Generate XSD with YAML Mapping
```bash
# URO package (255 classes)
bundle exec lutaml-klin xsd \
  --lur spec/fixtures/packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro.xml \
  --output examples/output \
  --packages uro

# Check outputs
ls -lh examples/output/
# Should see: urbanObject.xsd and urbanObject_mapping.yaml

# Inspect YAML mapping
cat examples/output/urbanObject_mapping.yaml | head -100
```

### Run Full Processing Workflow
```bash
# Complete workflow: mapping + validation + SPA
bundle exec lutaml-klin process \
  --lur spec/fixtures/packages/plateau_all.lur \
  --lxr spec/fixtures/packages/plateau_schemas.lxr \
  --config examples/ShapeChangeConfig_Plateau.xml \
  --packages "uro" \
  --output _site/
```

---

## 📋 Recommended Next Phase Options

Review [`CONTINUATION_PLAN_2025-01-28_NEXT_PHASE.md`] for full details. Summary:

### Option A: Performance Optimization (Recommended First)
**Effort**: 40-60 hours
**Value**: Quick wins for production readiness

**Why**: Currently ~10 seconds for 255 classes, target <5 seconds. Low risk, high value.

**Tasks**:
1. Profile XSD generation to find bottlenecks
2. Optimize MappingCollector memory usage
3. Implement parallel package processing
4. Add caching for type lookups
5. Optimize namespace resolution

### Option B: Schematron Generation
**Effort**: 150-200 hours
**Value**: Complete ShapeChange parity

**Why**: Last remaining major feature gap (1/2 package rules). High value for standards work.

**Tasks**:
1. Design Schematron rule architecture
2. Implement OCL-to-Schematron translator
3. Add constraint validation patterns
4. Integrate with XSD pipeline
5. Comprehensive testing

### Option C: Enhanced Mapping Features
**Effort**: 60-80 hours
**Value**: Better user experience

**Why**: Make YAML mappings more useful with diff, merge, validation tools.

---

## 🛠️ Development Workflow

### Before Making Changes

1. **Read Memory Bank** (always start here)
2. **Run tests** to establish baseline
3. **Check RuboCop** for code quality
4. **Review architecture docs** for patterns

### Making Changes

1. **Follow OOP/DRY/MECE principles religiously**
   - Single Responsibility: Each class does ONE thing
   - DRY: Define things in ONE place only
   - MECE: Mutually Exclusive, Collectively Exhaustive

2. **Use Model-Driven Architecture**
   - All data models inherit from `Lutaml::Model::Serializable`
   - This provides automatic YAML/JSON serialization

3. **Maintain Clean Separation**
   - Application layer = orchestration only
   - Domain layer = business logic only
   - No cross-layer violations

4. **Write Tests First** (or at least alongside)
   - Integration tests for workflows
   - Unit tests for business logic
   - Always verify zero regressions

### After Making Changes

1. **Run full test suite**
   ```bash
   bundle exec rake spec
   ```

2. **Run RuboCop with auto-correct**
   ```bash
   bundle exec rubocop -A
   ```

3. **Test manually with real data**
   ```bash
   # URO and URF packages
   ./examples/generate_plateau_final_xsd.sh
   ```

4. **Update documentation**
   - Update README.adoc if user-facing changes
   - Update memory bank if architectural changes
   - Create feature docs for new features

5. **Commit with semantic messages**
   ```
   feat(scope): brief description
   
   - Detailed change 1
   - Detailed change 2
   
   Tested with <test cases>.
   Zero regressions.
   ```

---

## 📁 Key Files to Know

### Core XSD Generation
- **[`XsdGenerator`](lib/lutaml/klin/shapechange/xsd_generator.rb)** - Main orchestrator (342 lines)
- **[`XsdDocument`](lib/lutaml/klin/shapechange/models/xsd_document.rb)** - XSD model building
- **[`RuleRegistry`](lib/lutaml/klin/shapechange/rule_registry.rb)** - Rule management
- **[`RuleChecker`](lib/lutaml/klin/shapechange/rule_checker.rb)** - Rule validation

### Rule Processors (all in `lib/lutaml/klin/shapechange/rule_processors/`)
- **[`ObjectElementProcessor`](lib/lutaml/klin/shapechange/rule_processors/object_element_processor.rb)** - Element generation
- **[`ComplexTypeProcessor`](lib/lutaml/klin/shapechange/rule_processors/complex_type_processor.rb)** - Type generation
- **[`PropertyElementProcessor`](lib/lutaml/klin/shapechange/rule_processors/property_element_processor.rb)** - Property encoding
- **[`EnumerationProcessor`](lib/lutaml/klin/shapechange/rule_processors/enumeration_processor.rb)** - Enum handling
- **[`BasicTypeProcessor`](lib/lutaml/klin/shapechange/rule_processors/class_rules/basic_type_processor.rb)** - Basic types

### YAML Mapping (NEW in Phase 1.5B)
- **[`MappingCollector`](lib/lutaml/klin/shapechange/mapping_collector.rb)** - Observer pattern (329 lines)
- **[`TransformationInfo`](lib/lutaml/klin/models/mapping/transformation_info.rb)** - Metadata model
- **[`ClassMapping`](lib/lutaml/klin/models/mapping/class_mapping.rb)** - Class-level mapping
- **[`AttributeMapping`](lib/lutaml/klin/models/mapping/attribute_mapping.rb)** - Attribute-level mapping

### Tests
- **[`complete_shapechange_parity_spec.rb`](spec/integration/complete_shapechange_parity_spec.rb)** - Main parity tests (8 tests)
- **[`yaml_mapping_generation_spec.rb`](spec/integration/yaml_mapping_generation_spec.rb)** - YAML tests (NEW)

---

## 🎯 Critical Principles (NON-NEGOTIABLE)

### Architecture
1. ✅ **Always think higher-level architecture** before hacking
2. ✅ **Model-based, not functional** - Use classes, not procedures
3. ✅ **Define things ONCE** - Single source of truth
4. ✅ **Explicitly declarative** - No magic, no auto-detection without clear rules
5. ✅ **Configuration over convention** - Externalize when possible

### Code Quality
1. ✅ **Zero regressions** - ALL tests must pass before commit
2. ✅ **RuboCop compliant** - Zero violations
3. ✅ **Separation of concerns** - Each layer, each class, each method = one thing
4. ✅ **DRY** - No repetition, ever
5. ✅ **MECE** - Complete coverage, no overlaps

### Process
1. ✅ **Read memory bank FIRST** - Always start here
2. ✅ **Verify baseline** - Run tests before changes
3. ✅ **Incremental changes** - One logical change per commit
4. ✅ **Test continuously** - Don't accumulate tech debt
5. ✅ **Document decisions** - Update memory bank for architectural changes

---

## ⚠️ Common Pitfalls to Avoid

1. **Don't use Struct or OpenStruct** - Create proper model classes
2. **Don't use functional approaches** - Use OOP (classes, inheritance, composition)
3. **Don't hardcode** - Use configuration, constants, or registries
4. **Don't parse twice** - Parse once, cache, reuse
5. **Don't assume file extensions** - Check content, not names
6. **Don't use Rails methods in plain Ruby** - e.g., `.present?` doesn't exist
7. **Don't skip tests** - Zero regressions is non-negotiable
8. **Don't commit without RuboCop** - Code quality is mandatory

---

## 🐛 Debugging Tips

### Tests Failing?
```bash
# Run with verbose output
bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb --format documentation

# Run single test
bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb:line_number

# Check for Ruby version issues
ruby --version  # Should be 2.7.0+
```

### XSD Generation Issues?
```bash
# Enable verbose mode
bundle exec lutaml-klin xsd ... --verbose

# Check rule registry
bundle exec ruby -Ilib -e "require 'lutaml/klin'; puts Lutaml::Klin::Shapechange::RuleRegistry.new.encoding_rules.map(&:name)"

# Inspect UML repository
bundle exec ruby -Ilib -e "
require 'lutaml/uml'
repo = Lutaml::Uml::UmlRepository.from_file('spec/fixtures/packages/plateau_all.lur')
puts repo.classes_in_package('uro').size
"
```

### Performance Issues?
```bash
# Profile execution
ruby -rprofile exe/lutaml-klin xsd ...

# Check memory usage
/usr/bin/time -l bundle exec lutaml-klin xsd ...
```

---

## 📞 Getting Help

### Documentation
- **Main README**: [`README.adoc`](README.adoc)
- **Architecture**: [`docs/architecture.adoc`](docs/architecture.adoc)
- **CLI Reference**: [`docs/cli.adoc`](docs/cli.adoc)
- **API Docs**: [`docs/ruby-api.adoc`](docs/ruby-api.adoc)

### Reference Implementations
- **ShapeChange Java**: `reference/shapechange-sources/`
- **PLATEAU XSD Examples**: `spec/fixtures/shapechange/`
- **ShapeChange Configs**: `reference/shapechange-configs/`

### Key Decisions Log
- See git history for rationale behind changes
- Check memory bank for architectural decisions
- Review planning docs for feature justification

---

## ✅ Pre-Flight Checklist

Before starting work, verify:

- [ ] Read memory bank files
- [ ] Read continuation plan
- [ ] Read implementation status
- [ ] Tests pass (8/8 = 100%)
- [ ] RuboCop clean (0 violations)
- [ ] Understand 4-layer architecture
- [ ] Understand design patterns used
- [ ] Know which phase/option working on

---

## 🎓 Success Criteria

For any work session to be considered complete:

1. ✅ All existing tests pass (8/8)
2. ✅ RuboCop compliant (0 violations)
3. ✅ New features have tests
4. ✅ Documentation updated
5. ✅ Memory bank updated if architectural changes
6. ✅ Semantic commit message
7. ✅ Zero regressions

---

**Good luck with the next phase! Remember: Architecture first, implementation second. Quality over speed. Zero regressions always.**

**Last Updated**: 2025-01-28 01:15 UTC+8