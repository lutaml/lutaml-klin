# Performance Baseline: LutaML Klin XSD Generation

**Date Established**: 2025-01-28 16:42 UTC+8
**Benchmark Script**: `benchmark/xsd_generation_benchmark.rb`
**Ruby Version**: 2.7+ (via bundler)
**Hardware**: macOS (specific specs TBD)

---

## 🎯 Baseline Measurements

### URO Package (Urban Object)
**Characteristics**:
- 255 UML classes
- 324 XSD elements
- 487 XSD types
- Complex package with many dependencies

**Baseline Performance**:
```
Average: 33.87 seconds
Min:     33.75 seconds
Max:     34.05 seconds
Variance: ±0.30s (0.9%)
```

**50% Improvement Target**: <16.93 seconds

---

### URF Package (Urban Function)
**Characteristics**:
- 208 UML classes
- 208 XSD elements
- 416 XSD types
- Simpler package structure

**Baseline Performance**:
```
Average: 19.58 seconds
Min:     19.54 seconds
Max:     19.60 seconds
Variance: ±0.06s (0.3%)
```

**50% Improvement Target**: <9.79 seconds

---

## 📊 Analysis

### Key Observations

1. **Performance is slower than estimated**:
   - URO: 33.87s (was estimated at ~10s)
   - URF: 19.58s (was estimated at ~8s)
   - This indicates significant optimization potential

2. **Very consistent timing**:
   - URO variance: ±0.9%
   - URF variance: ±0.3%
   - Minimal system interference, reliable measurements

3. **Complexity correlation**:
   - URO (255 classes): 33.87s / 255 = 0.133s per class
   - URF (208 classes): 19.58s / 208 = 0.094s per class
   - URO classes are ~41% more complex per class

### Scaling Characteristics

**Per-Class Processing Time**:
- URO: 133ms per class (complex dependencies)
- URF: 94ms per class (simpler structure)
- Average: ~113ms per class

**Performance Targets**:
- URO: <66ms per class (50% improvement)
- URF: <47ms per class (50% improvement)

---

## 🔍 Next Steps: Profiling

### Hot Path Hypotheses

Based on architecture and timing, likely bottlenecks:

1. **MappingCollector** (329 lines):
   - Called for every class and attribute
   - YAML serialization overhead
   - TransformationInfo object creation

2. **Type Resolution**:
   - ResolutionEngine checks 4 strategies per type
   - No caching, repeated lookups
   - XSD repository searches

3. **XSD Document Generation**:
   - XML building per class
   - Namespace resolution per element
   - String concatenation overhead

4. **Configuration Parsing**:
   - XInclude resolution
   - XML parsing (though cached after first use)

### Profiling Plan

1. **Profile URO package** (larger, more representative):
   ```bash
   ruby-prof --printer=graph exe/lutaml-klin xsd \
     --lur spec/fixtures/packages/plateau_all.lur \
     --config examples/ShapeChangeConfig_Plateau_uro.xml \
     --output tmp/profile_output --packages uro > profile_uro.txt
   ```

2. **Analyze top methods**:
   - Look for methods taking >1% of total time
   - Identify repeated operations
   - Find memory allocation hotspots

3. **Memory profiling**:
   ```bash
   /usr/bin/time -l bundle exec lutaml-klin xsd \
     --lur spec/fixtures/packages/plateau_all.lur \
     --config examples/ShapeChangeConfig_Plateau_uro.xml \
     --output tmp/profile_output --packages uro
   ```

---

## 📈 Optimization Strategy

### Phase 1 Optimizations (Core)

Target combined improvement of 50% through:

1. **MappingCollector Optimization** (Target: 20% faster)
   - Lazy initialization
   - Reduce YAML overhead
   - Batch operations

2. **Type Lookup Caching** (Target: 15% faster)
   - LRU cache in ResolutionEngine
   - Memoize strategy results
   - Pre-compute common types

3. **Namespace Resolution** (Target: 10% faster)
   - Cache qualified names
   - Optimize XInclude once
   - Pre-compute namespace map

**Expected Combined**: 40-45% improvement
**Target**: 50% improvement

### Phase 2 Optimizations (If Needed)

If Phase 1 doesn't achieve 50%, add:

4. **Parallel Processing** (Target: 40% faster for multi-package)
   - Thread-safe collectors
   - Parallel package processing
   - Coordinated output

---

## 🎯 Success Criteria

### Performance Targets
- ✅ **Must Achieve**:
  - URO: <16.93s (50% improvement from 33.87s)
  - URF: <9.79s (50% improvement from 19.58s)

- 🎉 **Stretch Goals**:
  - URO: <13.55s (60% improvement)
  - URF: <7.83s (60% improvement)

### Quality Targets
- ✅ All 8 integration tests passing
- ✅ Zero error messages in test output
- ✅ RuboCop compliant (0 violations)
- ✅ No architectural compromises
- ✅ Memory usage reduced by 30%

---

## 📋 Benchmark Methodology

### Test Setup
```ruby
# Benchmark script: benchmark/xsd_generation_benchmark.rb
# - Warm-up run (not measured)
# - 3 measured runs
# - Clean output directory between runs
# - Average, min, max calculated
```

### Hardware Environment
- **OS**: macOS Sequoia
- **Ruby**: 2.7+
- **Bundler**: Latest
- **Test Data**: PLATEAU URO/URF packages

### Reproducibility
```bash
# Run benchmark
ruby benchmark/xsd_generation_benchmark.rb

# Expected variance: <1%
# If variance >2%, investigate system load
```

---

## 📝 Progress Tracking

### Baseline (Current)
```
URO: 33.87s (100% baseline)
URF: 19.58s (100% baseline)
```

### After Task 2: MappingCollector Optimization
```
URO: TBD (target: 27.10s, 20% improvement)
URF: TBD (target: 15.66s, 20% improvement)
```

### After Task 3: Type Lookup Caching
```
URO: TBD (target: 23.04s, 32% cumulative)
URF: TBD (target: 13.31s, 32% cumulative)
```

### After Task 4: Namespace Resolution
```
URO: TBD (target: 20.74s, 39% cumulative)
URF: TBD (target: 11.98s, 39% cumulative)
```

### Final Target
```
URO: <16.93s (50% improvement)
URF: <9.79s (50% improvement)
```

---

**Last Updated**: 2025-01-28 16:42 UTC+8
**Next Step**: Profile URO package to identify bottlenecks