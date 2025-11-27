# Achieving 100% ShapeChange Compatibility: Domain Type Resolution

## Current Gap: 76.1% vs 100%

### What We Have (76.1%) ✅

**ShapeChangeMappingStrategy resolves**:
- Standard GML types: `gml:CodeType`, `gml:LengthType`, etc.
- XSD primitives: `xs:string`, `xs:integer`, etc.
- **Source**: XsdMapEntry from ShapeChange config

### What We're Missing (23.9%) ❌

**Custom Domain Types**:
- `FacilityAttribute` → `?`
- `ConstructionEvent` → `?`
- `DmAttribute` → `?`
- `IfcAttribute` → `?`

**How ShapeChange Handles These** (from XsdDocument.java):

```java
// Line 2849-2858: Look up UML class
ClassInfo ci = model.classById(ti.id);
if (ci == null) {
    ci = model.classByName(ti.name);
}

// Then use class category to generate type
// Line 2997-3025: For classes with object elements
if (classHasObjectElement(ci)) {
    if (ci.matches("rule-xsd-cls-standard-19139-property-types")) {
        String type = propertyTypeName(ci, true);  // ci.qname() + "PropertyType"
        addAttribute(e, "type", type);
    }
}

// Line 642-667: Property type naming
private String propertyTypeName(ClassInfo ci, boolean qualified) {
    if (ci.matches("rule-xsd-all-naming-gml")) {
        return (qualified ? ci.qname() : ci.name()) + "PropertyType";
    }
}

// Line 620-640: Element naming
private String typeName(ClassInfo ci, boolean qualified) {
    if (ci.matches("rule-xsd-all-naming-gml")) {
        return (qualified ? ci.qname() : ci.name()) + "Type";
    }
}
```

## The Missing Strategy: DomainTypeResolution

### Implementation Plan

**New Strategy**: `DomainTypeStrategy` that mimics ShapeChange's class lookup logic

```ruby
# lib/lutaml/klin/domain/strategies/domain_type_strategy.rb
class DomainTypeStrategy < BaseStrategy
  def applicable?(element, context:)
    # Check if the type name refers to a UML class in the model
    uml_class = find_uml_class(element.type, context)
    !uml_class.nil?
  end

  def resolve(element, context:)
    uml_class = find_uml_class(element.type, context)
    return ResolutionResult.unresolved unless uml_class

    # Apply ShapeChange naming rules
    type_name = apply_type_naming(uml_class)
    property_type_name = apply_property_type_naming(uml_class)
    namespace = determine_namespace(uml_class, context)

    # This matches what ShapeChange WOULD generate
    ResolutionResult.resolved(
      xsd_type: type_name,
      xsd_property_type: property_type_name,
      xsd_namespace: namespace,
      method: :domain_type_inference,
      confidence: 0.90,  # High confidence - it's in the UML model!
      metadata: {
        uml_class_found: true,
        class_category: uml_class.stereotype,
        naming_rule: 'rule-xsd-all-naming-gml'
      }
    )
  end

  private

  def find_uml_class(type_name, context)
    # Normalize type name
    normalized = type_name.to_s.gsub('::', ':').strip

    # Remove namespace prefix if present
    local_name = normalized.include?(':') ? normalized.split(':', 2).last : normalized

    # Try to find in UML repository
    context.uml_repository.find_class(local_name)
  end

  def apply_type_naming(uml_class)
    # GML rule: ClassName + "Type"
    "#{uml_class.name}Type"
  end

  def apply_property_type_naming(uml_class)
    # GML rule: ClassName + "PropertyType"
    base_name = uml_class.name
    suffix = base_name.end_with?('Property') ? '_' : ''
    "#{base_name}#{suffix}PropertyType"
  end

  def determine_namespace(uml_class, context)
    # Get namespace for the package this class belongs to
    package = uml_class.package || uml_class.owner_package
    return nil unless package

    context.shapechange_config.namespace_for_package(package.name)
  end
end
```

### Integration

**Add to Resolution Engine** (in order of priority):

```ruby
# In MappingWorkflow.build_resolution_engine
strategies = [
  TypeOverrideStrategy.new,           # 1. User overrides
  ShapeChangeMappingStrategy.new,     # 2. XsdMapEntry (standard types)
  DomainTypeStrategy.new,             # 3. UML class references (NEW!)
  SchemaRepositoryStrategy.new        # 4. LXR direct lookup
]
```

### Expected Results After Implementation

**Resolution Breakdown**:
```
Total: 1,396 resolutions (100%)

By Method:
  ✅ ShapeChangeMappingStrategy: 1,063 (76.1%)
     - Standard types from XsdMapEntry
     - Confidence: 0.95

  ✅ DomainTypeStrategy: 333 (23.9%)  ← NEW!
     - Custom UML class references
     - Confidence: 0.90
     - Examples: FacilityAttribute → FacilityAttributeType

  ✅ Overall: 100% resolved (0% fallback to analyzer)
  ✅ Average confidence: 0.93
```

**Sample Improved Output**:

```yaml
- uml_name: consFacilityAttribute
  uml_type: FacilityAttribute
  xsd_type: FacilityAttributeType  # From DomainTypeStrategy!
  xsd_namespace: https://www.geospatial.jp/iur/uro/3.2
  resolution_method: domain_type_inference
  resolution_status: resolved  # Not "inferred"!
  resolution_confidence: 0.90
  metadata:
    uml_class_found: true
    class_category: DataType
    naming_rule: rule-xsd-all-naming-gml
```

## Implementation Tasks

### Task 1: Create DomainTypeStrategy

**File**: `lib/lutaml/klin/domain/strategies/domain_type_strategy.rb` (NEW)

**Components**:
- UML class lookup by name
- GML naming rule application
- Namespace determination
- Confidence scoring (0.9 for found classes)

### Task 2: Update Resolution Engine

**File**: `lib/lutaml/klin/application/mapping_workflow.rb`

**Add** DomainTypeStrategy to strategy chain (before SchemaRepositoryStrategy)

### Task 3: Add UML Repository to ResolutionContext

**File**: `lib/lutaml/klin/domain/resolution_context.rb`

**Add**:
```ruby
attr_reader :uml_repository

def initialize(..., uml_repository:)
  @uml_repository = uml_repository
  # ...
end
```

### Task 4: Test and Verify

**Expected**:
```
Resolution Quality:
  ShapeChangeMappingStrategy: 76.1% (standard types)
  DomainTypeStrategy: 23.9% (domain types)
  Total: 100% resolved
  Average confidence: 0.93
```

## Why This Achieves 100% Compatibility

**ShapeChange's approach**:
1. Check XsdMapEntry for standard types
2. Look up UML class for custom types
3. Apply naming rules to predict XSD type

**Our improved approach**:
1. ✅ Check XsdMapEntry (ShapeChangeMappingStrategy)
2. ✅ Look up UML class (DomainTypeStrategy) ← NEW!
3. ✅ Apply naming rules (already in TransformationAnalyzer)

**Result**: Exactly matches ShapeChange's mapping logic!

## Effort Estimate

**Implementation**: 4-6 hours
- DomainTypeStrategy: 2 hours
- Integration: 1 hour
- Testing: 2-3 hours

**Benefit**: 100% ShapeChange compatibility for mapping documentation (without XSD generation)

## Summary

**Current**: 76.1% (only standard types)
**After DomainTypeStrategy**: 100% (standard + domain types)

This achieves full ShapeChange compatibility for **mapping documentation** by replicating ShapeChange's type resolution logic, without needing to implement full XSD generation!