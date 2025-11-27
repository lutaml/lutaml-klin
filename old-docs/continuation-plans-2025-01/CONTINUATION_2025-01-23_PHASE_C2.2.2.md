# 🚀 Continue Development: Phase C2.2.2 - SchemaRepositoryAdapter Tests

**Session Date**: 2025-01-23
**Phase**: C2.2 Infrastructure Layer Tests  
**Task**: C2.2.2 - Test SchemaRepositoryAdapter
**Previous**: C2.2.1 Complete (UmlRepositoryAdapter - 37 tests passing)
**Progress**: 28/133 tasks (21%)

---

## ⚡ Quick Start

### What You Need to Do
Write comprehensive tests for [`SchemaRepositoryAdapter`](lib/lutaml/klin/repositories/schema_repository_adapter.rb:9)

### Expected Outcome
- **25-30 tests** covering 4-5 public methods
- **100% passing** rate
- **All edge cases** covered
- **~1-1.5 hours** to complete

### Run This First
```bash
# Read the implementation
cat lib/lutaml/klin/repositories/schema_repository_adapter.rb

# Check existing pattern
cat spec/lutaml/klin/repositories/uml_repository_adapter_spec.rb

# Create spec file
code spec/lutaml/klin/repositories/schema_repository_adapter_spec.rb
```

---

## 📊 Last Session Recap

### Completed: Phase C2.2.1 ✅
- **File Created**: `spec/lutaml/klin/repositories/uml_repository_adapter_spec.rb`
- **Tests Added**: 37 (all passing)
- **Coverage**: 100% of all 8 public methods
- **Time Taken**: ~1 hour
- **Quality**: No shortcuts, comprehensive edge cases

### Test Suite Status
- **Total**: 683 tests (was 646)
- **Passing**: 546 (80.0%)
- **Failing**: 137 (pre-existing, Phase C3 work)
- **New**: 114 tests total (77 domain + 37 infrastructure)

---

## 🎯 This Session: Phase C2.2.2

### Target File
[`lib/lutaml/klin/repositories/schema_repository_adapter.rb`](lib/lutaml/klin/repositories/schema_repository_adapter.rb:9)

### Methods to Test

```ruby
class SchemaRepositoryAdapter
  # 1. Initialize
  def initialize(lxr_path)
    # Load LXR package
    # Handle errors (file not found, invalid package)
  end
  
  # 2. Find Type
  def find_type(name, namespace: nil)
    # With namespace specified
    # Without namespace (search all)
    # Type not found (returns nil)
    # Error handling
  end
  
  # 3. Find Element
  def find_element(name, namespace: nil)
    # Similar to find_type
  end
  
  # 4. All Namespaces
  def all_namespaces
    # Returns array of namespace strings
    # Empty repository case
  end
  
  # 5. Types in Namespace
  def types_in_namespace(namespace)
    # Valid namespace
    # Invalid namespace
    # Empty namespace
  end
end
```

### Test Structure Template

```ruby
# frozen_string_literal: true

require "spec_helper"
require "lutaml/klin/repositories/schema_repository_adapter"

RSpec.describe Lutaml::Klin::Repositories::SchemaRepositoryAdapter do
  let(:valid_lxr_path) { "spec/fixtures/test.lxr" }
  let(:mock_repository) { double("Lutaml::Xsd::SchemaRepository") }

  describe "#initialize" do
    context "with valid LXR package" do
      it "successfully loads the repository" do
        allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
          .with(valid_lxr_path)
          .and_return(mock_repository)

        adapter = described_class.new(valid_lxr_path)
        expect(adapter.repository).to eq(mock_repository)
      end
    end

    context "with invalid inputs" do
      it "raises error when LXR file does not exist" do
        # Test file not found
      end
      
      it "raises error when LXR package is invalid" do
        # Test invalid package
      end
    end
  end

  describe "#find_type" do
    let(:adapter) do
      allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
        .and_return(mock_repository)
      described_class.new(valid_lxr_path)
    end

    context "when type exists" do
      it "returns type with namespace specified" do
        # Test happy path with namespace
      end
      
      it "returns type without namespace" do
        # Test search all namespaces
      end
    end

    context "when type does not exist" do
      it "returns nil" do
        # Test not found case
      end
    end

    context "when repository raises error" do
      it "re-raises with context" do
        # Test error handling
      end
    end
  end

  # Repeat for find_element, all_namespaces, types_in_namespace
end
```

---

## 📋 Execution Checklist

### Before You Start
- [ ] Read `.kilocode/rules/memory-bank/context.md`
- [ ] Review `lib/lutaml/klin/repositories/schema_repository_adapter.rb`
- [ ] Check `spec/lutaml/klin/repositories/uml_repository_adapter_spec.rb` for pattern
- [ ] Understand lutaml-xsd API (similar to lutaml)

### While Writing Tests
- [ ] Create spec file: `spec/lutaml/klin/repositories/schema_repository_adapter_spec.rb`
- [ ] Test `initialize` with valid/invalid inputs (4-5 tests)
- [ ] Test `find_type` with all scenarios (5-6 tests)
- [ ] Test `find_element` similarly (5-6 tests)
- [ ] Test `all_namespaces` (3-4 tests)
- [ ] Test `types_in_namespace` (4-5 tests)
- [ ] Run tests: `bundle exec rspec spec/lutaml/klin/repositories/schema_repository_adapter_spec.rb`
- [ ] Verify 100% passing

### After Tests Pass
- [ ] Run full suite: `bundle exec rspec`
- [ ] Check test count increased by ~25-30
- [ ] Update `.kilocode/rules/memory-bank/context.md`
- [ ] Mark C2.2.2 complete, set next to C2.3.1

---

## 🎯 Success Criteria

### Must Have ✅
- [ ] All 4-5 methods tested
- [ ] 25-30 tests minimum
- [ ] 100% passing rate
- [ ] Happy paths covered
- [ ] Edge cases tested
- [ ] Error conditions verified
- [ ] Clear test names

### Quality Standards ✅
- [ ] No shortcuts taken
- [ ] No skipped/pending tests
- [ ] Proper mocking of external dependencies
- [ ] Error messages verified
- [ ] Follows established patterns from UmlRepositoryAdapter

---

## 📚 Key Reference Points

### API Pattern (Critical!)
```ruby
# SchemaRepositoryAdapter wraps lutaml-xsd gem
# Similar to how UmlRepositoryAdapter wraps lutaml

# Load from LXR package
repository = Lutaml::Xsd::SchemaRepository.from_package("path.lxr")

# Find type (with optional namespace)
type = repository.find_type("BuildingType", namespace: "http://...")

# Find element
element = repository.find_element("Building", namespace: "http://...")
```

### Test Doubles Pattern
```ruby
let(:mock_repository) { double("SchemaRepository") }
let(:mock_type) { double("XsdType", name: "BuildingType") }

allow(Lutaml::Xsd::SchemaRepository).to receive(:from_package)
  .with(lxr_path)
  .and_return(mock_repository)

allow(mock_repository).to receive(:find_type)
  .with("BuildingType", namespace: "http://...")
  .and_return(mock_type)
```

### Edge Cases to Test
1. **Initialize**: file not found, invalid package, corrupt file
2. **find_type**: with namespace, without namespace, not found, nil name
3. **find_element**: same as find_type
4. **all_namespaces**: empty repo, populated repo, error
5. **types_in_namespace**: valid namespace, invalid, empty, nil

---

## 🚫 Critical Don'ts

1. ❌ Don't lower test thresholds
2. ❌ Don't skip edge cases
3. ❌ Don't use pending tests
4. ❌ Don't test implementation details
5. ❌ Don't mock domain logic (only external deps)
6. ❌ Don't forget error message verification

---

## 📈 After This Session

### Coverage Goals
- **Line**: ~67-70% (from ~64-67%)
- **Branch**: ~32-36% (from ~30-34%)
- **Files**: 90/156 (from 89/156)
- **Tests**: 708-713 (from 683)

### Next Task
**Phase C2.3.1**: Test ProcessingWorkflow
- File: `lib/lutaml/klin/application/processing_workflow.rb`
- Estimated: 2-3 hours
- Tests: ~40-50

### Milestone
✅ Infrastructure Layer **COMPLETE** after this session!

---

## 🎓 Lessons from C2.2.1 (Apply Here)

### What Worked ✅
1. Read implementation file first
2. Check existing spec for patterns
3. Write tests method by method
4. Test happy path, then edges, then errors
5. Run tests frequently during writing
6. Verify 100% passing before moving on

### Pro Tips 💡
1. Copy-paste UmlRepositoryAdapter spec structure
2. Adapt method names and expectations
3. Keep test names descriptive
4. Group related tests with context blocks
5. Use let/let! for test data setup
6. Mock external dependencies only

---

## 🏁 Ready to Start?

### Command Sequence
```bash
# 1. Create spec file
touch spec/lutaml/klin/repositories/schema_repository_adapter_spec.rb

# 2. Open in editor
code spec/lutaml/klin/repositories/schema_repository_adapter_spec.rb

# 3. Copy UmlRepositoryAdapter spec as template
cp spec/lutaml/klin/repositories/uml_repository_adapter_spec.rb \
   spec/lutaml/klin/repositories/schema_repository_adapter_spec.rb

# 4. Adapt for SchemaRepository

# 5. Run tests frequently
bundle exec rspec spec/lutaml/klin/repositories/schema_repository_adapter_spec.rb

# 6. When all pass, run full suite
bundle exec rspec
```

### Time Estimate
- Reading/preparation: 10-15 min
- Writing tests: 40-60 min
- Running/fixing: 10-15 min
- Documentation: 10 min
**Total**: 70-100 minutes

---

## 📞 Need Help?

### Reference Documents
1. `.kilocode/rules/memory-bank/context.md` - Current state
2. `ARCHITECTURE.md` - System architecture
3. `docs/lutaml-api-patterns.md` - API patterns
4. `spec/lutaml/klin/repositories/uml_repository_adapter_spec.rb` - Pattern template

### Memory Bank Files
- `brief.md` - Project overview
- `product.md` - The 4-step vision
- `architecture.md` - Architecture details
- `tech.md` - Technical specifics

---

**🚀 You've got this! The pattern is established. Just adapt and execute.**

**Quality over speed. Test thoroughly. Document clearly. Make it right.**

---

**Document Version**: 1.0  
**Created**: 2025-01-23 15:35 UTC  
**For Session**: Phase C2.2.2  
**Estimated Duration**: 1-1.5 hours