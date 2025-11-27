# 🚀 LutaML-Klin Development Continuation - Complete Project

**Copy this entire prompt to start the next session**

---

## 📋 Quick Context

**Project**: lutaml-klin - Ruby UML-to-XSD transformation orchestrator  
**Status**: Phase B2 (API Fixes) - ~15% Complete  
**Last Session**: 2025-01-22  
**Current Blocker**: 🔴 UML API compatibility (`uml_class.package` undefined)

---

## 🎯 Mission Statement

Complete ALL remaining work to production-ready release. This includes:
- ✅ Fix ALL API compatibility issues
- ✅ Write ALL missing tests (>85% coverage)
- ✅ Complete ALL documentation (README + technical docs)
- ✅ Achieve ALL quality standards (no shortcuts)
- ✅ Prepare for release (version 0.2.0 or 1.0.0)

**Estimated Time**: 31-46 hours (4-6 full days)

---

## 📚 Required Reading (IN ORDER)

Before starting ANY work, you MUST read these files:

1. **`.kilocode/rules/memory-bank/`** - All files (project context)
   - `brief.md` - Project overview
   - `product.md` - Why, what, how
   - `architecture.md` - System architecture
   - `tech.md` - Technologies used
   - `context.md` - Current state

2. **`ARCHITECTURE_REVIEW.md`** - Architecture analysis (5/5 rating)

3. **`CONTINUATION_PLAN_2025-01-22.md`** - Complete work plan (Phases B-F)

4. **`IMPLEMENTATION_STATUS_2025-01-22.md`** - Task-by-task tracker

---

## 🔥 IMMEDIATE NEXT TASK: Phase B2

### B2.1: Investigate lutaml API for Package Access

**Problem**:
```
NoMethodError: undefined method `package' for #<Lutaml::Uml::Class>
Location: lib/lutaml/klin/shapechange/xsd_generator.rb:211
Code: package_name: uml_class.package&.name,
```

**Required Actions**:

1. **Check lutaml gem source** for correct API:
   ```bash
   cd ../lutaml
   rg "class Class" lib/lutaml/uml/
   # Look for package-related methods
   ```

2. **Examine Lutaml::Uml::Class attributes**:
   - Check if package info is in a different property
   - Look for `parent_package`, `namespace`, `owner`, etc.
   - Review actual LUR data structure

3. **Review how Repository gets package info**:
   ```ruby
   # In lib/lutaml/klin/repositories/uml_repository_adapter.rb
   # How does find_package work?
   # Can we pass package context differently?
   ```

4. **Test with REPL**:
   ```ruby
   require 'lutaml'
   repo = Lutaml::UmlRepository::Repository.from_package('spec/fixtures/packages/plateau_uro.lur')
   klass = repo.classes.first
   # Inspect klass to see available methods
   klass.methods.grep(/package|parent|namespace/)
   ```

5. **Fix XsdGenerator** (line 211):
   ```ruby
   # WRONG (current):
   package_name: uml_class.package&.name,
   
   # RIGHT (find correct method):
   package_name: <use_correct_lutaml_api>,
   ```

6. **Search codebase for other `.package` uses**:
   ```bash
   rg "\.package(&|\.)|\bpackage\b" lib/ --type ruby
   ```

7. **Update ALL occurrences** to use correct API

8. **Test the fix**:
   ```bash
   bundle exec rspec spec/integration/xsd_generation_spec.rb
   ```

**Success Criteria**: No `NoMethodError` for package access

---

## 🏗️ Architecture Principles (NON-NEGOTIABLE)

### Object-Oriented Design
- ✅ Model-based architecture (NOT functional/serializer patterns)
- ✅ Single Responsibility Principle
- ✅ Open/Closed Principle (extend without modify)
- ✅ Dependency Inversion
- ✅ Interface Segregation
- ❌ NO OpenStruct in domain layer
- ❌ NO global state
- ❌ NO god objects

### MECE (Mutually Exclusive, Collectively Exhaustive)
- No overlap between components
- No gaps in functionality
- Clear boundaries
- Complete coverage

### Separation of Concerns (STRICT)
- **Domain Layer**: Pure business logic, ZERO I/O
- **Application Layer**: Orchestration + I/O handling
- **Infrastructure Layer**: External system access
- **Models**: Data structures with serialization only

### Extensibility Patterns
- Strategy pattern for algorithms (ResolutionEngine)
- Registry pattern for plugins (RuleRegistry)
- Adapter pattern for external systems (Repository adapters)
- Template method for workflows

---

## 🧪 Testing Standards (ABSOLUTE)

### Coverage Requirements
- **Every class** must have a spec file
- **Every public method** must be tested
- **>85% code coverage** (REAL, not lowered)
- **All edge cases** covered
- **All error conditions** tested

### Test Principles
- ✅ Test behavior, not implementation
- ✅ One spec file per class
- ✅ Use `let` for test data
- ✅ Real fixtures where possible
- ❌ NO mocks in domain layer (pure logic)
- ❌ Mock ONLY external systems in infrastructure
- ❌ NO lowering thresholds to make tests pass
- ❌ NO skipping tests without documented reason

### Test Structure
```ruby
RSpec.describe Lutaml::Klin::SomeClass do
  describe '#method_name' do
    context 'when condition A' do
      it 'produces expected result' do
        # Test happy path
      end
    end

    context 'when condition B' do
      it 'handles gracefully' do
        # Test edge case
      end
    end

    context 'when invalid input' do
      it 'raises appropriate error' do
        # Test error handling
      end
    end
  end
end
```

---

## 📝 Documentation Standards

### README.adoc Requirements
- **MECE structure**: No overlap, no gaps
- **All examples WORK**: Test every single one
- **Clear and complete**: Technical but accessible
- **Proper AsciiDoc format**:
  - Sentence-case headings
  - Code blocks with language tags
  - Tested examples
  - Cross-references
  - Diagrams for complex concepts

### Technical Docs (docs/*.adoc)
- One document per major feature
- Deep dive into architecture
- Design decisions explained
- Extension points documented
- Examples tested and working

---

## ⚠️ Quality Standards (ABSOLUTE - NO EXCEPTIONS)

### The Rules
1. ✋ **NEVER lower test thresholds** to make tests pass
2. ✋ **NEVER cut corners** on testing or documentation
3. ✋ **NEVER skip tests** without documented reason
4. ✋ **ALL examples must work** - test them before documenting
5. ✋ **ALL metrics must be REAL** - no fudging numbers
6. ✋ **HONEST assessment** - acknowledge gaps truthfully

### When Tests Fail
1. Understand WHY it's failing
2. Determine if:
   - **Code is wrong** → Fix the code
   - **Test is wrong** → Fix the test
   - **Expectation is wrong** → Update test with explanation
3. Fix the ROOT CAUSE, not the symptom
4. **NEVER** make tests pass by lowering thresholds

---

## 📁 File Organization

### Documentation Locations
- **Official docs**: README.adoc, docs/*.adoc
- **Reference docs**: ARCHITECTURE_REVIEW.md, CHANGELOG.adoc
- **Archived docs**: old-docs/ (temp/completed work docs)
- **Planning docs**: CONTINUATION_PLAN_2025-01-22.md, IMPLEMENTATION_STATUS_2025-01-22.md

### Code Organization (4 Layers)
```
lib/lutaml/klin/
├── application/      # Layer 2: Workflows (orchestration + I/O)
├── domain/           # Layer 3: Business Logic (pure, no I/O)
│   ├── services/     # Domain services
│   └── strategies/   # Resolution strategies
├── repositories/     # Layer 1: Data access adapters
├── models/           # Layer 4: Data structures
└── shapechange/      # ShapeChange integration
```

---

## 🔄 Complete Work Plan (Phases B-F)

### Phase B: API Fixes & Validation (6-10 hours)
- **B2**: Fix UML API compatibility 🔴 **CURRENT**
- **B3**: Fix additional API issues
- **B4**: Run complete test suite
- **B5**: Code quality cleanup (RuboCop)
- **B6**: Parity validation (≥90% target)

### Phase C: Complete Test Coverage (8-12 hours)
- **C1**: Identify missing tests
- **C2**: Write missing tests (domain → app → infra)
- **C3**: Fix failing tests (no shortcuts)

### Phase D: Comprehensive Documentation (10-14 hours)
- **D1**: Update README.adoc (complete rewrite)
- **D2**: Create technical docs (docs/*.adoc)
- **D3**: Archive old documentation (old-docs/)
- **D4**: Update CHANGELOG.adoc

### Phase E: Final Quality Check (4-6 hours)
- **E1**: Complete test run (>85% coverage)
- **E2**: Integration testing (real workflows)
- **E3**: Documentation review (test all examples)
- **E4**: Code quality final check

### Phase F: Release Preparation (3-4 hours)
- **F1**: Version bump & changelog
- **F2**: Gem build & test
- **F3**: Git cleanup & tagging
- **F4**: Release documentation

**Total**: 31-46 hours estimated

---

## 🚨 Current Blockers & Issues

### Critical (🔴)
1. **UML API compatibility**: `uml_class.package` undefined
   - Location: `lib/lutaml/klin/shapechange/xsd_generator.rb:211`
   - Fix: Use correct lutaml API method
   - Impact: Blocks ALL XSD generation tests

### High (🟡)
2. **Test infrastructure**: Tests execute but many fail
   - Cause: API compatibility issues
   - Fix: Complete Phase B
   - Impact: Cannot validate functionality

3. **RuboCop violations**: 3831 offenses
   - Severity: LOW (80% auto-fixable)
   - Fix: Phase B5
   - Impact: Code style only

### Medium (🟢)
4. **Missing test coverage**: ~24% of classes lack specs
   - Fix: Phase C
   - Impact: Unknown behavior coverage

---

## 🎯 Success Criteria (Complete Project)

### Code Quality ✅
- [ ] All 400+ tests passing (REAL passes, no lowered thresholds)
- [ ] 0 RuboCop violations (or all documented in .rubocop_todo.yml)
- [ ] >85% test coverage (REAL coverage)
- [ ] All classes have comprehensive specs
- [ ] All public methods tested with edge cases

### Architecture ✅
- [x] Clean 4-layer separation (verified)
- [x] No circular dependencies (verified)
- [x] Domain layer pure - no I/O (verified)
- [x] Strategy pattern correct (verified)
- [x] Repository pattern correct (verified)
- [x] Workflow pattern correct (verified)

### Documentation ✅
- [ ] README.adoc complete
- [ ] All features documented with working examples
- [ ] Technical docs created (docs/*.adoc)
- [ ] CHANGELOG.adoc up to date
- [ ] Old docs archived (old-docs/)

### Functionality ✅
- [ ] Repository adapters work correctly
- [ ] Resolution engine resolves types
- [ ] XSD generation produces valid schemas
- [ ] Mapping generation creates accurate mappings
- [ ] Validation reports show real metrics
- [ ] SPA generation creates working website
- [ ] Lookup queries work bidirectionally
- [ ] CLI commands all functional

---

## 🛠️ Useful Commands

### Testing
```bash
# Run all tests
bundle exec rake spec

# Run with coverage
COVERAGE=true bundle exec rake spec

# Run specific file
bundle exec rspec spec/path/to/file_spec.rb

# Run integration tests only
bundle exec rspec spec/integration/

# Verbose output
bundle exec rspec --format documentation
```

### Code Quality
```bash
# Auto-fix violations
bundle exec rubocop -A

# Check without fixing
bundle exec rubocop

# Check specific file
bundle exec rubocop lib/path/to/file.rb
```

### Investigation
```bash
# Find all uses of .package
rg "\.package(&|\.)|\bpackage\b" lib/ --type ruby

# Find classes without specs
comm -23 <(find lib -name "*.rb" | sort) <(find spec -name "*_spec.rb" | sed 's/_spec//' | sort)

# List all Ruby files
find lib -name "*.rb" | wc -l

# List all spec files
find spec -name "*_spec.rb" | wc -l
```

### Documentation
```bash
# Generate YARD docs
bundle exec yard doc

# Serve YARD docs locally
bundle exec yard server
```

---

## 💡 Tips & Patterns

### When Starting Work
1. Read memory bank files (`.kilocode/rules/memory-bank/`)
2. Review ARCHITECTURE_REVIEW.md
3. Check IMPLEMENTATION_STATUS_2025-01-22.md
4. Identify current blockers
5. Start with highest priority task

### When Fixing Code
1. Understand the architecture layer
2. Follow separation of concerns
3. Use correct design patterns
4. Write/update tests FIRST (TDD when possible)
5. Verify fix works
6. Update tracker

### When Writing Tests
1. One spec file per class
2. Test behavior, not implementation
3. Cover happy path + edge cases + errors
4. Use descriptive contexts
5. No mocks in domain layer
6. Real fixtures preferred

### When Writing Docs
1. Test ALL examples before documenting
2. Use AsciiDoc format properly
3. Include diagrams for complex topics
4. Cross-reference between docs
5. Keep MECE (no overlap, no gaps)

---

## 📊 Progress Tracking

Update `IMPLEMENTATION_STATUS_2025-01-22.md` after completing tasks:

```markdown
- ✅ B2.1: Investigate lutaml API  # Mark complete
- ✅ B2.2: Fix XsdGenerator        # Mark complete
```

Track overall progress:
- Phase B: Currently 20% (task B2.1 in progress)
- Total Project: ~15% complete

---

## 🎬 Session Start Checklist

Before writing ANY code:

- [ ] Read all memory bank files
- [ ] Review ARCHITECTURE_REVIEW.md
- [ ] Check CONTINUATION_PLAN_2025-01-22.md
- [ ] Review IMPLEMENTATION_STATUS_2025-01-22.md
- [ ] Understand current blocker (B2: UML API)
- [ ] Confirm first task (B2.1: Investigate API)
- [ ] Remember principles (OOP, MECE, separation, quality)

---

## 🏁 First Actions

1. **Investigate lutaml gem API** for package access
2. **Fix XsdGenerator line 211** with correct method  
3. **Search and update** all `.package` references
4. **Test the fix** with XSD generation tests
5. **Update status tracker** with progress
6. **Move to next task** (B2.2 or B3.1)

---

## 📞 Remember

- **Quality over speed** - Do it right the first time
- **No shortcuts** - Complete ALL work
- **Honest assessment** - Acknowledge gaps truthfully
- **Test thoroughly** - No lowering thresholds
- **Document completely** - All examples must work
- **Follow principles** - OOP, MECE, separation of concerns

---

**Good luck! 🚀 Let's build this the right way.**