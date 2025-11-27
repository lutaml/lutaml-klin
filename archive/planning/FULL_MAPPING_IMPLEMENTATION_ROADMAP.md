# Full Mapping Implementation Roadmap
## Step-by-Step Guide to Creating Complete UML-to-XSD Mappings with LXR Integration

## Executive Summary

This roadmap provides a detailed, actionable plan for implementing complete UML-to-XSD mapping using lutaml-xsd's SchemaRepository and LXR packages. It breaks down the work into discrete, testable phases with clear success criteria.

**Goal**: Enable lutaml-klin to generate comprehensive, production-ready UML-to-XSD mappings using pre-built LXR packages for instant schema access and namespace-aware type resolution.

**Timeline**: 12-16 hours over 2-3 days

## Prerequisites

### What You Already Have

1. **lutaml-xsd** (`~/src/lutaml/lutaml-xsd`)
   - SchemaRepository implementation
   - LXR package format
   - Namespace-aware type resolution
   - CLI for building packages

2. **lutaml-klin** (current project)
   - XmiNavigator for UML parsing
   - ConfigParser for ShapeChange configs
   - MappingGenerator framework
   - Resolution strategy pattern

3. **Test Data**
   - PLATEAU XMI: `/Users/mulgogi/src/mn/mn-samples-plateau/sources/xmi/20251010-242.xmi`
   - PLATEAU XSD schemas in reference-docs/xsd/
   - ShapeChange configs for URO and URF

### What You Need to Build

1. **SchemaRepositoryAdapter** - Wrapper around lutaml-xsd SchemaRepository
2. **SchemaRepositoryStrategy** - Resolution strategy using the repository
3. **Integration in MappingGenerator** - Use new strategy in resolution chain
4. **CLI updates** - Support LXR packages
5. **Comprehensive tests** - Verify end-to-end workflow

## Phase 1: Create SchemaRepositoryAdapter (2-3 hours)

### 1.1: Design the Adapter Interface (30 min)

**Objective**: Define clean interface for wrapping lutaml-xsd SchemaRepository

**File**: `lib/lutaml/klin/repositories/schema_repository_adapter.rb`

**Key Methods**:
```ruby
class SchemaRepositoryAdapter
  # Factory methods
  def self.from_package(lxr_path, namespace_mappings: [])
  def self.from_schemas(schema_paths, ...)

  # Core resolution
  def resolve_type(qualified_name)
  def find_element(qualified_name)
  def find_attribute(qualified_name)

  # Metadata
  def statistics
  def validate
  def namespaces
end
```

**Success Criteria**:
- [ ] Interface matches lutaml-klin needs
- [ ] Wraps lutaml-xsd cleanly
- [ ] No lutaml-xsd types leak to callers

### 1.2: Implement from_package Method (30 min)

**Task**: Load LXR package and configure namespaces

```ruby
def self.from_package(lxr_path, namespace_mappings: [])
  # 1. Load package using lutaml-xsd
  repo = Lutaml::Xsd::SchemaRepository.from_package(lxr_path)

  # 2. Configure namespace mappings
  namespace_mappings.each do |mapping|
    repo.add_namespace_mapping(
      prefix: mapping[:prefix],
      uri: mapping[:uri]
    )
  end

  # 3. Return wrapped adapter
  new(repo)
end
```

**Test**:
```ruby
RSpec.describe SchemaRepositoryAdapter do
  describe '.from_package' do
    it 'loads LXR package' do
      adapter = described_class.from_package(
        'spec/fixtures/test.lxr',
        namespace_mappings: [
          { prefix: 'gml', uri: 'http://www.opengis.net/gml/3.2' }
        ]
      )

      expect(adapter).to be_a(described_class)
    end
  end
end
```

**Success Criteria**:
- [ ] Loads valid LXR packages
- [ ] Configures namespaces correctly
- [ ] Raises clear error on invalid package
- [ ] Test passes

### 1.3: Implement resolve_type Method (45 min)

**Task**: Resolve types and return standardized result

```ruby
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
```

**Tests**:
```ruby
describe '#resolve_type' do
  let(:adapter) { described_class.from_package('spec/fixtures/test.lxr') }

  it 'resolves prefixed names' do
    result = adapter.resolve_type('gml:CodeType')

    expect(result.status).to eq(:resolved)
    expect(result.qualified_name).to include('CodeType')
    expect(result.method).to eq(:schema_repository)
  end

  it 'resolves Clark notation' do
    result = adapter.resolve_type('{http://www.opengis.net/gml/3.2}CodeType')
    expect(result.status).to eq(:resolved)
  end

  it 'returns unresolved for missing types' do
    result = adapter.resolve_type('nonexistent:Type')
    expect(result.status).to eq(:unresolved)
  end
end
```

**Success Criteria**:
- [ ] Resolves all three name formats
- [ ] Returns standardized TypeResolutionResult
- [ ] Includes metadata for debugging
- [ ] All tests pass

### 1.4: Implement Helper Methods (30 min)

**Task**: Add find_element, statistics, validate methods

```ruby
def find_element(qualified_name)
  @repository.find_element(qualified_name)
end

def statistics
  @repository.statistics
end

def validate
  @repository.validate
end

def namespaces
  @repository.namespaces
end
```

**Tests**: One test per method verifying delegation

**Success Criteria**:
- [ ] All methods delegate correctly
- [ ] Tests pass
- [ ] RuboCop clean

**Phase 1 Deliverable**: Working SchemaRepositoryAdapter with comprehensive tests

---

## Phase 2: Create SchemaRepositoryStrategy (2-3 hours)

### 2.1: Implement Basic Strategy (1 hour)

**Objective**: Create resolution strategy using the adapter

**File**: `lib/lutaml/klin/domain/resolution/schema_repository_strategy.rb`

```ruby
class SchemaRepositoryStrategy < ResolutionStrategy
  def initialize(repository_adapter)
    @repository = repository_adapter
  end

  def name
    :schema_repository
  end

  def applicable?(source, context)
    true  # Always try as primary method
  end

  def resolve(source, context:)
    # Try resolving the type
    result = @repository.resolve_type(source.type)

    if result.resolved?
      ResolutionResult.resolved(
        target: result.definition,
        method: :schema_repository,
        confidence: 1.0,
        metadata: result.metadata
      )
    else
      ResolutionResult.unresolved(
        error: result.error,
        metadata: { attempted_name: source.type }
      )
    end
  end
end
```

**Tests**:
```ruby
RSpec.describe SchemaRepositoryStrategy do
  let(:mock_adapter) { instance_double(SchemaRepositoryAdapter) }
  let(:strategy) { described_class.new(mock_adapter) }

  describe '#resolve' do
    it 'resolves via repository' do
      source = double(type: 'gml:CodeType')
      allow(mock_adapter).to receive(:resolve_type)
        .and_return(TypeResolutionResult.new(status: :resolved, ...))

      result = strategy.resolve(source, context: {})

      expect(result.resolved?).to be true
      expect(result.method).to eq(:schema_repository)
    end
  end
end
```

**Success Criteria**:
- [ ] Implements strategy interface
- [ ] Delegates to repository adapter
- [ ] Returns proper ResolutionResult
- [ ] Tests pass

### 2.2: Add Name Candidate Generation (1 hour)

**Task**: Try multiple name formats for better resolution

```ruby
def resolve(source, context:)
  candidates = build_name_candidates(source, context)

  candidates.each do |candidate|
    result = @repository.resolve_type(candidate[:qualified_name])

    if result.resolved?
      return ResolutionResult.resolved(
        target: result.definition,
        method: :schema_repository,
        confidence: candidate[:confidence],
        metadata: {
          **result.metadata,
          candidate_format: candidate[:format]
        }
      )
    end
  end

  ResolutionResult.unresolved(
    error: "Type not found",
    metadata: { attempted_names: candidates.map { |c| c[:qualified_name] } }
  )
end

private

def build_name_candidates(source, context)
  [
    { qualified_name: source.type, format: :exact, confidence: 1.0 },
    { qualified_name: normalize_double_colon(source.type), format: :normalized, confidence: 0.95 },
    { qualified_name: with_default_namespace(source.type, context), format: :default_ns, confidence: 0.8 },
    { qualified_name: unprefixed(source.type), format: :unprefixed, confidence: 0.5 }
  ].compact
end
```

**Tests**: Test each candidate format

**Success Criteria**:
- [ ] Tries exact match first
- [ ] Falls back to alternatives
- [ ] Tracks which format succeeded
- [ ] All tests pass

**Phase 2 Deliverable**: Working SchemaRepositoryStrategy with candidate generation

---

## Phase 3: Integration with MappingGenerator (3-4 hours)

### 3.1: Update Constructor (30 min)

**Task**: Accept SchemaRepositoryAdapter in constructor

**File**: `lib/lutaml/klin/mapping_generator.rb`

```ruby
class MappingGenerator
  def initialize(config:, xmi_navigator:, schema_repository:)
    @config = config
    @xmi = xmi_navigator
    @schema_repo = schema_repository
    @resolution_engine = build_resolution_engine
  end

  private

  def build_resolution_engine
    Domain::Resolution::ResolutionEngine.new(
      strategies: [
        Domain::Resolution::TypeOverrideStrategy.new(@config.type_overrides),
        Domain::Resolution::SchemaRepositoryStrategy.new(@schema_repo),  # NEW!
        Domain::Resolution::ShapeChangeStrategy.new(@config.type_mappings),
        Domain::Resolution::NamespaceStrategy.new(@config.namespaces)
      ]
    )
  end
end
```

**Test Updates**: Update all tests to provide schema_repository parameter

**Success Criteria**:
- [ ] Constructor accepts schema_repository
- [ ] Strategy added to engine
- [ ] All existing tests updated
- [ ] All tests pass

### 3.2: Update Class Mapping (1 hour)

**Task**: Use resolution engine with SchemaRepository

```ruby
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
```

**Tests**: Verify SchemaRepository used for class resolution

**Success Criteria**:
- [ ] Classes resolve via SchemaRepository
- [ ] Resolution metadata tracked
- [ ] Tests verify correct strategy used

### 3.3: Update Attribute Mapping (1 hour)

**Task**: Find XSD elements using SchemaRepository

```ruby
def map_attribute(attribute, context:)
  # Resolve attribute type
  type_resolution = @resolution_engine.resolve(attribute, context: context)

  # Find corresponding XSD element
  element_name = determine_element_name(attribute, context)
  xsd_element = @schema_repo.find_element(element_name)

  Models::Mapping::AttributeMapping.new(
    uml_attribute: attribute,
    xsd_element: xsd_element,
    xsd_type: type_resolution.target,
    resolution_result: type_resolution
  )
end
```

**Tests**: Verify element finding works

**Success Criteria**:
- [ ] Attributes resolve via SchemaRepository
- [ ] XSD elements found correctly
- [ ] Tests pass

### 3.4: Add Statistics Tracking (30 min)

**Task**: Track resolution statistics using SchemaRepository

```ruby
def calculate_resolution_stats(class_mappings)
  {
    total_classes: class_mappings.size,
    resolved_classes: class_mappings.count(&:fully_resolved?),
    total_attributes: class_mappings.sum { |cm| cm.attributes.size },
    resolved_attributes: class_mappings.sum(&:resolved_attribute_count),
    schema_statistics: @schema_repo.statistics,
    resolution_methods: count_resolution_methods(class_mappings)
  }
end
```

**Success Criteria**:
- [ ] Statistics include schema repo data
- [ ] Resolution methods counted
- [ ] Tests verify stats

**Phase 3 Deliverable**: MappingGenerator fully integrated with SchemaRepository

---

## Phase 4: CLI Updates (2-3 hours)

### 4.1: Add LXR Option to Generate Command (1 hour)

**File**: `lib/lutaml/klin/cli.rb`

```ruby
desc "generate CONFIG XMI LXR OUTPUT", "Generate mapping using LXR package"
option :package, type: :string, required: true
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

  display_results(mapping)
end
```

**Tests**: CLI integration test

**Success Criteria**:
- [ ] Command accepts LXR path
- [ ] Loads LXR package correctly
- [ ] Generates mapping successfully
- [ ] Test passes

### 4.2: Create Process Command (1 hour)

**Task**: Unified command for complete workflow

```ruby
desc "process", "Complete UML-to-XSD mapping workflow"
option :lur, required: true, desc: "LUR package path"
option :lxr, required: true, desc: "LXR package path"
option :config, required: true, desc: "ShapeChange config"
option :packages, default: "**", desc: "Package filter"
option :output, required: true, desc: "Output directory"
option :generate_mappings, type: :boolean, default: true
option :generate_spa, type: :boolean, default: false
option :validate, type: :boolean, default: true

def process
  # Single command to do everything
  # See scripts/generate_plateau_mapping_lur_lxr.sh for reference
end
```

**Success Criteria**:
- [ ] Command works end-to-end
- [ ] Outputs to correct locations
- [ ] Progress displayed

### 4.3: Add Validation Output (30 min)

**Task**: Show resolution statistics

```ruby
def display_results(mapping)
  stats = mapping.statistics

  puts "\n" + "=" * 80
  puts "Mapping Generation Complete"
  puts "=" * 80
  puts "\nClasses:"
  puts "  Total: #{stats[:total_classes]}"
  puts "  Resolved: #{stats[:resolved_classes]} (#{resolution_percent(stats)}%)"

  puts "\nAttributes:"
  puts "  Total: #{stats[:total_attributes]}"
  puts "  Resolved: #{stats[:resolved_attributes]}"

  puts "\nResolution Methods:"
  stats[:resolution_methods].each do |method, count|
    puts "  #{method}: #{count}"
  end

  puts "\nSchema Repository:"
  puts "  Total types: #{stats[:schema_statistics][:total_types]}"
  puts "  Namespaces: #{stats[:schema_statistics][:total_namespaces]}"
end
```

**Success Criteria**:
- [ ] Clear statistics output
- [ ] Shows resolution methods
- [ ] Easy to understand

**Phase 4 Deliverable**: Updated CLI with LXR support and comprehensive output

---

## Phase 5: End-to-End Testing (3-4 hours)

### 5.1: Build Test LXR Package (1 hour)

**Task**: Create fixture LXR package for tests

```bash
# In lutaml-xsd directory
cd ~/src/lutaml/lutaml-xsd

cat > config/test_fixture.yaml <<EOF
files:
  - spec/fixtures/simple_schema.xsd
  - spec/fixtures/gml_subset.xsd

namespace_mappings:
  - prefix: "test"
    uri: "http://test.com/schema"
  - prefix: "gml"
    uri: "http://www.opengis.net/gml/3.2"
EOF

bundle exec lutaml-xsd package build \
  config/test_fixture.yaml \
  --output spec/fixtures/test.lxr \
  --xsd-mode include_all \
  --resolution-mode resolved \
  --serialization-format marshal
```

**Success Criteria**:
- [ ] LXR package builds successfully
- [ ] Contains test schemas
- [ ] Loads quickly (<100ms)

### 5.2: Integration Test (1 hour)

**File**: `spec/integration/lxr_mapping_spec.rb`

```ruby
RSpec.describe 'LXR-based mapping generation' do
  let(:lxr_path) { 'spec/fixtures/test.lxr' }
  let(:xmi_path) { 'spec/fixtures/test_model.xmi' }
  let(:config_path) { 'spec/fixtures/test_config.xml' }

  it 'generates complete mapping using LXR package' do
    # Initialize repositories
    schema_repo = SchemaRepositoryAdapter.from_package(lxr_path)
    uml_repo = UmlRepositoryAdapter.new(xmi_path)
    config = ConfigParser.parse(config_path)

    # Generate mapping
    generator = MappingGenerator.new(
      config: config,
      xmi_navigator: XmiNavigator.new(uml_repo),
      schema_repository: schema_repo
    )

    mapping = generator.generate_mapping('test_package')

    # Verify results
    expect(mapping.classes.size).to be > 0
    expect(mapping.statistics[:resolution_rate]).to be >= 0.9

    # Verify SchemaRepository was used
    methods = mapping.statistics[:resolution_methods]
    expect(methods[:schema_repository]).to be > 0
  end
end
```

**Success Criteria**:
- [ ] Test passes
- [ ] >90% resolution rate
- [ ] SchemaRepository strategy used

### 5.3: PLATEAU Integration Test (1-2 hours)

**Task**: Test with real PLATEAU data

```ruby
RSpec.describe 'PLATEAU mapping with LXR' do
  # Build PLATEAU LXR package first (one-time setup)
  before(:all) do
    build_plateau_lxr_package
  end

  it 'generates URO mapping with high accuracy' do
    mapping = generate_plateau_mapping('uro')

    expect(mapping.statistics[:resolution_rate]).to be >= 0.95
    expect(mapping.classes.size).to eq(expected_uro_class_count)
  end

  it 'resolves cross-schema references' do
    mapping = generate_plateau_mapping('urf')

    # Should resolve GML types from imported schemas
    gml_resolutions = mapping.statistics[:resolution_methods][:schema_repository]
    expect(gml_resolutions).to be > 0
  end
end
```

**Success Criteria**:
- [ ] PLATEAU URO mapping succeeds
- [ ] Resolution rate >95%
- [ ] Cross-schema references work
- [ ] Performance acceptable (<10s)

**Phase 5 Deliverable**: Comprehensive test suite proving end-to-end functionality

---

## Phase 6: Documentation (2-3 hours)

### 6.1: Update README (1 hour)

**Sections to Add**:

1. **LXR Package Support**
2. **Quick Start with LXR**
3. **Building LXR Packages**
4. **Performance Benefits**
5. **Troubleshooting**

**Success Criteria**:
- [ ] Clear examples
- [ ] Installation instructions
- [ ] Performance numbers

### 6.2: Create User Guide (1 hour)

**File**: `docs/LXR_USER_GUIDE.md`

**Contents**:
1. What are LXR packages
2. When to use them
3. How to build them
4. How to use with lutaml-klin
5. Common issues and solutions

**Success Criteria**:
- [ ] Beginner-friendly
- [ ] Step-by-step examples
- [ ] Covers common scenarios

### 6.3: Add Examples (30 min)

**Directory**: `examples/lxr_mapping/`

**Files**:
- `build_lxr_package.sh` - Script to build test package
- `generate_mapping.rb` - Ruby example
- `generate_mapping.sh` - CLI example
- `README.md` - Explains examples

**Success Criteria**:
- [ ] Examples work as documented
- [ ] Cover key use cases
- [ ] Easy to follow

**Phase 6 Deliverable**: Complete documentation for LXR integration

---

## Success Metrics

### Performance Targets

- **LXR loading**: <100ms for 100MB package
- **Type resolution**: <1ms per type
- **Complete mapping**: <10s for 500-class model
- **Memory**: <500MB for large models

### Accuracy Targets

- **Resolution rate**: >95% for PLATEAU
- **Cross-schema**: 100% of GML types resolved
- **Validation**: 0 schema errors

### Quality Targets

- **Test coverage**: >90%
- **RuboCop**: No offenses
- **Documentation**: All public APIs documented
- **Examples**: All examples work

## Risk Mitigation

### Technical Risks

1. **LXR format changes**
   - Mitigation: Pin lutaml-xsd version
   - Mitigation: Comprehensive tests

2. **Performance issues**
   - Mitigation: Benchmark early
   - Mitigation: Profile and optimize

3. **Namespace conflicts**
   - Mitigation: Clear error messages
   - Mitigation: Validation step

### Schedule Risks

1. **Unexpected complexity**
   - Mitigation: Build incrementally
   - Mitigation: Test each phase

2. **Integration issues**
   - Mitigation: Early integration tests
   - Mitigation: Mock adapters

## Final Deliverables

### Code
- [ ] SchemaRepositoryAdapter (fully tested)
- [ ] SchemaRepositoryStrategy (fully tested)
- [ ] Updated MappingGenerator (integration tested)
- [ ] Updated CLI (end-to-end tested)
- [ ] Comprehensive test suite

### Documentation
- [ ] Updated README
- [ ] LXR User Guide
- [ ] Architecture documentation
- [ ] Working examples
- [ ] API documentation

### Infrastructure
- [ ] CI/CD integration
- [ ] Performance benchmarks
- [ ] Example LXR packages

## Next Actions

### Immediate (Day 1)
1. Create SchemaRepositoryAdapter
2. Write comprehensive tests
3. Verify LXR loading works

### Short Term (Day 2)
1. Implement SchemaRepositoryStrategy
2. Integrate with MappingGenerator
3. Update CLI

### Medium Term (Day 3)
1. End-to-end testing
2. PLATEAU integration test
3. Documentation

### Long Term (Week 2+)
1. Performance optimization
2. Advanced features (caching, validation)
3. Production deployment

## Conclusion

This roadmap provides a clear path to integrating lutaml-xsd's SchemaRepository into lutaml-klin for complete, production-ready UML-to-XSD mapping. The phased approach ensures testability at each step and provides clear success criteria.

**Estimated Total Time**: 12-16 hours

**Expected Outcome**: Production-ready mapping generation with >95% accuracy, instant schema loading, and comprehensive namespace support.