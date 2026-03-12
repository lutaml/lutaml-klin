# Continuation Prompt: Phase 2 Performance Optimization

**Date**: 2025-01-28 18:08 UTC+8
**Current Phase**: Task 1 Complete → Ready for Task 2
**Status**: All documentation created, baseline established

---

## 🎯 Quick Context

You are continuing development of **lutaml-klin**, a Ruby tool that generates XSD schemas from UML models with 100% ShapeChange parity. Phase 1.5B is complete with all features working. Phase 2 focuses on **performance optimization** to achieve 50% speed improvement through architectural improvements.

**Critical Bug Fixed** (2025-01-28): ComplexTypeProcessor was calling non-existent methods `get_metadata`/`set_metadata` - now fixed to use `metadata_hash`/`metadata_hash=`.

---

## 📚 Essential Reading (IN ORDER)

**MUST READ FIRST** (Memory Bank):
1. [`.kilocode/rules/memory-bank/brief.md`](.kilocode/rules/memory-bank/brief.md:1)
2. [`.kilocode/rules/memory-bank/context.md`](.kilocode/rules/memory-bank/context.md:1)
3. [`.kilocode/rules/memory-bank/architecture.md`](.kilocode/rules/memory-bank/architecture.md:1)

**Phase 2 Documentation**:
4. [`CONTINUATION_PLAN_2025-01-28_POST_BUGFIX.md`](CONTINUATION_PLAN_2025-01-28_POST_BUGFIX.md:1) - Complete Phase 2 plan
5. [`IMPLEMENTATION_STATUS_2025-01-28.md`](IMPLEMENTATION_STATUS_2025-01-28.md:1) - Progress tracker
6. [`PERFORMANCE_BASELINE.md`](PERFORMANCE_BASELINE.md:1) - Baseline measurements
7. [`BOTTLENECK_ANALYSIS.md`](BOTTLENECK_ANALYSIS.md:1) - Architecture analysis

**User Documentation**:
8. [`README.adoc`](README.adoc:1) - User-facing documentation

---

## ✅ Current Status Summary

### System Health
- ✅ **Tests**: 8/8 passing (100%) with zero error messages
- ✅ **RuboCop**: Clean (production code)
- ✅ **Bug Fixed**: ComplexTypeProcessor method names corrected
- ✅ **Status**: Production-ready

### Phase 2 Progress
- ✅ **Task 1**: Profiling and Benchmarking (COMPLETE)
- ⏳ **Task 2**: MappingCollector Optimization (NEXT)
- ⏳ **Task 3**: Type Lookup Caching
- ⏳ **Task 4**: Namespace Resolution Optimization
- ⏳ **Task 5**: Parallel Processing [OPTIONAL]

### Performance Baseline
- **URO**: 33.87s (255 classes) → Target: <16.93s (50% improvement)
- **URF**: 19.58s (208 classes) → Target: <9.79s (50% improvement)
- **Benchmark**: [`benchmark/xsd_generation_benchmark.rb`](benchmark/xsd_generation_benchmark.rb:1)

---

## 🎯 YOUR IMMEDIATE TASK: Task 2 - MappingCollector Optimization

### Objective
Optimize [`lib/lutaml/klin/shapechange/mapping_collector.rb`](lib/lutaml/klin/shapechange/mapping_collector.rb:1) to reduce 30% of processing time (~10 seconds) by 20-30%.

### Target Performance
- **Current**: ~10.2 seconds (30% of total)
- **Target**: ~7 seconds (20-30% improvement)
- **Savings**: ~3.2 seconds

### Why This Bottleneck?
MappingCollector is called for **every class and attribute**:
- URO: 255 classes + ~1500 attributes = ~1755 calls
- Creates TransformationInfo objects each time
- Serializes to YAML repeatedly
- Heavy hash operations

### Optimization Strategy

**Review Current Implementation**:
```bash
# Read the file (329 lines)
read_file lib/lutaml/klin/shapechange/mapping_collector.rb
```

**Key Optimizations to Implement**:

1. **Lazy Initialization** (High Impact)
   ```ruby
   # Before: Always create
   transformation_info = TransformationInfo.new(...)
   
   # After: Only create when needed
   def transformation_info
     @transformation_info ||= TransformationInfo.new(...)
   end
   ```

2. **Batch YAML Serialization** (High Impact)
   ```ruby
   # Before: Serialize per mapping
   mapping.to_yaml
   
   # After: Serialize once at end
   def finalize_mappings
     @mappings.map { |m| m.to_yaml }
   end
   ```

3. **Reuse Objects** (Medium Impact)
   ```ruby
   # Before: Create new hash every time
   metadata = {}
   
   # After: Reuse and clear
   @metadata_buffer ||= {}
   @metadata_buffer.clear
   ```

4. **Lighter Data Structures** (Medium Impact)
   - Use arrays instead of hashes where order matters
   - Avoid creating intermediate objects
   - Use symbols instead of strings for keys

### Files to Modify
**Primary**:
- [`lib/lutaml/klin/shapechange/mapping_collector.rb`](lib/lutaml/klin/shapechange/mapping_collector.rb:1) (329 lines)

**Secondary** (if needed):
- [`lib/lutaml/klin/models/mapping/transformation_info.rb`](lib/lutaml/klin/models/mapping/transformation_info.rb:1)

### Development Workflow

1. **Read current implementation**:
   ```bash
   read_file lib/lutaml/klin/shapechange/mapping_collector.rb
   read_file lib/lutaml/klin/models/mapping/transformation_info.rb
   ```

2. **Implement optimizations** (one at a time):
   - Start with lazy initialization
   - Then batch YAML
   - Then object reuse
   - Then lighter structures

3. **Test after each change**:
   ```bash
   bundle exec rspec spec/integration/complete_shapechange_parity_spec.rb \
     --format documentation 2>&1 | grep "Error"
   # Should output nothing
   ```

4. **Benchmark improvement**:
   ```bash
   ruby benchmark/xsd_generation_benchmark.rb
   # Compare with baseline: 33.87s URO, 19.58s URF
   ```

5. **Check RuboCop**:
   ```bash
   bundle exec rubocop
   ```

6. **Update documentation**:
   - Update `PERFORMANCE_BASELINE.md` with new metrics
   - Document optimization techniques used

---

## 🎓 Critical Principles (NON-NEGOTIABLE)

### Architecture
1. ✅ **Higher-level architecture first** - Don't hack, redesign
2. ✅ **Object-oriented** - Model-based, not functional
3. ✅ **Single source of truth** - Define once, use everywhere
4. ✅ **MECE principle** - Mutually exclusive, collectively exhaustive
5. ✅ **Open/Closed principle** - Open for extension, closed for modification

### Code Quality
1. ✅ **Zero regressions** - All tests must pass
2. ✅ **Check error messages** - Not just pass/fail
3. ✅ **RuboCop compliant** - Zero violations
4. ✅ **Separation of concerns** - Each layer does one thing
5. ✅ **DRY principle** - Don't repeat yourself

### Performance
1. ✅ **Architecture over hacks** - Better algorithms, not shortcuts
2. ✅ **Profile first** - Measure actual bottlenecks
3. ✅ **One optimization at a time** - Measure each impact
4. ✅ **Maintain architecture** - No compromises for speed

---

## ⚠️ Common Pitfalls to Avoid

1. **Don't use Struct or OpenStruct** - Create proper model classes
2. **Don't hardcode** - Use configuration
3. **Don't skip error checking** - Verify zero errors in tests
4. **Don't commit without RuboCop** - Code quality mandatory
5. **Don't optimize without measuring** - Profile first
6. **Don't break architecture for speed** - Use better algorithms
7. **Don't sacrifice maintainability** - Clean code is fast code

---

## 📋 Verification Checklist

Before marking Task 2 complete:

- [ ] MappingCollector optimized
- [ ] All 8 integration tests passing
- [ ] Zero error messages in test output
- [ ] RuboCop compliant (0 violations)
- [ ] Benchmark shows 20-30% improvement
- [ ] Performance documented in PERFORMANCE_BASELINE.md
- [ ] Code reviewed for maintainability
- [ ] No architectural compromises

---

## 🎯 Success Criteria for Task 2

### Performance Target
- ✅ URO: 33.87s → ~27s (20% improvement, 6.87s saved)
- ✅ URF: 19.58s → ~15.6s (20% improvement, 3.98s saved)

### Quality Targets
- ✅ All 8 tests passing
- ✅ Zero error messages
- ✅ RuboCop clean
- ✅ No regressions

### Deliverables
- ✅ Optimized mapping_collector.rb
- ✅ Updated PERFORMANCE_BASELINE.md
- ✅ Benchmark results documented

---

## 🚀 After Task 2 is Complete

Move on to **Task 3: Type Lookup Caching**:
1. Read [`lib/lutaml/klin/domain/resolution_engine.rb`](lib/lutaml/klin/domain/resolution_engine.rb:1)
2. Implement LRU cache for resolved types
3. Pre-compute common types (string, integer, etc.)
4. Memoize strategy results
5. Target: 15-25% improvement (~2-3s saved)

See [`CONTINUATION_PLAN_2025-01-28_POST_BUGFIX.md`](CONTINUATION_PLAN_2025-01-28_POST_BUGFIX.md:1) for complete details.

---

## 📊 Progress Tracking

### Current State
```
Task 1: ✅ Complete (Profiling/Benchmarking)
Task 2: ⏳ Starting (MappingCollector)
Task 3: ⏳ Pending (Type Caching)
Task 4: ⏳ Pending (Namespace Optimization)
Task 5: ⏳ Pending [OPTIONAL] (Parallel Processing)
```

### Performance Progress
```
Baseline:
  URO: 33.87s (100%)
  URF: 19.58s (100%)

After Task 2 (Target):
  URO: ~27s (80%, 20% improvement)
  URF: ~15.6s (80%, 20% improvement)

Final Target:
  URO: <16.93s (50%, 50% improvement)
  URF: <9.79s (50%, 50% improvement)
```

---

## 📁 Key Files Reference

### Hot Path Files (Optimization Targets)
- **Task 2**: [`lib/lutaml/klin/shapechange/mapping_collector.rb`](lib/lutaml/klin/shapechange/mapping_collector.rb:1)
- **Task 3**: [`lib/lutaml/klin/domain/resolution_engine.rb`](lib/lutaml/klin/domain/resolution_engine.rb:1)
- **Task 4**: [`lib/lutaml/klin/shapechange/config_parser.rb`](lib/lutaml/klin/shapechange/config_parser.rb:1)

### Test Files
- **Integration**: [`spec/integration/complete_shapechange_parity_spec.rb`](spec/integration/complete_shapechange_parity_spec.rb:1)
- **YAML Mapping**: [`spec/integration/yaml_mapping_generation_spec.rb`](spec/integration/yaml_mapping_generation_spec.rb:1)

### Benchmark Scripts
- **Main Benchmark**: [`benchmark/xsd_generation_benchmark.rb`](benchmark/xsd_generation_benchmark.rb:1)
- **Profiling**: `benchmark/profile_uro.rb`

---

## 🎓 Remember

**You are an expert software engineer** with principles:
- **Architecture over hacks** - Always think higher-level
- **Object-oriented** - Model-based, not functional
- **MECE** - Complete coverage, no overlaps
- **One responsibility** - Each class, each method
- **Zero regressions** - Tests must pass

**Performance optimization** is about:
- **Better algorithms** - Not shortcuts
- **Architectural solutions** - Not hacks
- **Measured improvements** - Profile before/after
- **Maintained quality** - Zero compromises

**The deadline is compressed** - Work efficiently but maintain quality.

---

**Last Updated**: 2025-01-28 18:08 UTC+8
**Next Action**: Start Task 2 - Optimize MappingCollector
**Estimated Time**: 8-12 hours
**Target**: 20-30% performance improvement