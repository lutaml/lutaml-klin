# Encoding Rules Architecture: Configuration-Driven, Extensible Design

## Core Architectural Principles

### 1. Configuration Over Code (Open/Closed Principle)

**Problem**: Hardcoding rules makes them impossible to extend without modifying code

**Solution**: Rules are data, not code!

```
┌─────────────────────────────────────────┐
│  Rules Configuration (Data)              │
│  - Loaded from ShapeChange XML           │
│  - Loaded from Ruby DSL                  │
│  - Loaded from YAML                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  RuleRegistry (Mediator)                 │
│  - Stores all rule definitions           │
│  - Resolves rule inheritance             │
│  - Checks rule applicability             │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Rule Processors (Strategy)              │
│  - ClassRuleProcessor                    │
│  - PropertyRuleProcessor                 │
│  - NamingRuleProcessor                   │
└─────────────────────────────────────────┘
```

### 2. MECE Rule Organization

**Mutually Exclusive** (each rule has ONE purpose):
- `rule-xsd-cls-type` - Controls type generation
- `rule-xsd-cls-object-element` - Controls element generation
- `rule-xsd-cls-property-type` - Controls property type generation

**Collectively Exhaustive** (all aspects covered):
- Package rules (xsd-pkg-*)
- Class rules (xsd-cls-*)
- Property rules (xsd-prop-*)
- Naming rules (xsd-all-naming-*)

### 3. Single Responsibility Per Component

```
EncodingRule model      → Data structure only
RuleRegistry            → Rule storage and lookup only
RuleChecker             → Rule applicability only
RuleProcessor           → Rule application only
```

## Architecture Design

### Layer 1: Rule Models (Data)

**Pure data structures, no behavior**:

```ruby
# lib/lutaml/klin/shapechange/models/encoding_rule.rb
class EncodingRule < Lutaml::Model::Serializable
  attribute :name, :string              # e.g., "iso19136_2007"
  attribute :extends, :string           # Parent rule
  attribute :rules, :string, collection: true  # Individual rules

  # NO behavior here - pure data!
end

# lib/lutaml/klin/shapechange/models/rule_definition.rb
class RuleDefinition < Lutaml::Model::Serializable
  attribute :id, :string                # e.g., "rule-xsd-cls-type"
  attribute :scope, :string             # "class", "property", "package"
  attribute :category, :string          # "required", "optional"
  attribute :description, :string
  attribute :applies_to, :string, collection: true  # ["FeatureType", "DataType"]

  # NO behavior here - pure data!
end
```

### Layer 2: Rule Registry (Mediator Pattern)

**Single responsibility**: Manage rule relationships

```ruby
# lib/lutaml/klin/shapechange/rule_registry.rb
class RuleRegistry
  def initialize
    @encoding_rules = {}      # name => EncodingRule
    @rule_definitions = {}    # id => RuleDefinition
  end

  # Register an encoding rule
  def register_encoding_rule(encoding_rule)
    @encoding_rules[encoding_rule.name] = encoding_rule
  end

  # Register a rule definition
  def register_rule_definition(rule_def)
    @rule_definitions[rule_def.id] = rule_def
  end

  # Check if a rule applies to an encoding rule (with inheritance)
  def has_rule?(rule_id, encoding_rule_name)
    current = @encoding_rules[encoding_rule_name]
    return false unless current

    # Check current encoding rule
    return true if current.rules.include?(rule_id)

    # Check parent encoding rule
    if current.extends
      has_rule?(rule_id, current.extends)
    else
      false
    end
  end

  # Get all rules for an encoding rule (with inheritance)
  def all_rules_for(encoding_rule_name)
    rules = []
    current = @encoding_rules[encoding_rule_name]

    while current
      rules.concat(current.rules)
      current = current.extends ? @encoding_rules[current.extends] : nil
    end

    rules.uniq
  end
end
```

### Layer 3: Rule Checker (Strategy Pattern)

**Single responsibility**: Determine if a rule applies to an element

```ruby
# lib/lutaml/klin/shapechange/rule_checker.rb
class RuleChecker
  def initialize(rule_registry, encoding_rule_name)
    @registry = rule_registry
    @encoding_rule = encoding_rule_name
  end

  # Check if a rule applies to a UML element
  # @param rule_id [String] Rule identifier
  # @param element [Object] UML element (class, property, package)
  # @return [Boolean] true if rule applies
  def applies?(rule_id, element)
    # 1. Check if rule is in encoding rule set
    return false unless @registry.has_rule?(rule_id, @encoding_rule)

    # 2. Check if rule applies to element category
    rule_def = @registry.rule_definitions[rule_id]
    return false unless rule_def

    # 3. Check element-specific conditions
    applies_to_element?(rule_def, element)
  end

  private

  def applies_to_element?(rule_def, element)
    case rule_def.scope
    when 'class'
      applies_to_class?(rule_def, element)
    when 'property'
      applies_to_property?(rule_def, element)
    when 'package'
      applies_to_package?(rule_def, element)
    else
      true  # Universal rules
    end
  end

  def applies_to_class?(rule_def, uml_class)
    return true if rule_def.applies_to.empty?

    rule_def.applies_to.include?(uml_class.stereotype)
  end
end
```

### Layer 4: Rule Processors (Visitor Pattern)

**Single responsibility**: Apply ONE rule

**Base Class**:

```ruby
# lib/lutaml/klin/shapechange/rule_processors/base_processor.rb
module Lutaml::Klin::Shapechange::RuleProcessors
  class BaseProcessor
    def initialize(rule_checker, config)
      @checker = rule_checker
      @config = config
    end

    # Apply the rule if it's applicable
    # @param element [Object] UML element
    # @param context [Hash] Processing context
    # @return [Boolean] true if rule was applied
    def process(element, context)
      return false unless applicable?(element)

      apply_rule(element, context)
      true
    end

    protected

    def applicable?(element)
      raise NotImplementedError, "Subclasses must implement applicable?"
    end

    def apply_rule(element, context)
      raise NotImplementedError, "Subclasses must implement apply_rule"
    end
  end
end
```

**Concrete Processors** (one per rule):

```ruby
# lib/lutaml/klin/shapechange/rule_processors/object_element_processor.rb
class ObjectElementProcessor < BaseProcessor
  RULE_ID = 'rule-xsd-cls-object-element'

  protected

  def applicable?(element)
    @checker.applies?(RULE_ID, element)
  end

  def apply_rule(uml_class, context)
    # Create <xs:element name="Building" type="BuildingType"/>
    element = context[:xsd_document].create_element('element')
    element['name'] = uml_class.name
    element['type'] = "#{uml_class.name}Type"

    context[:schema].add_child(element)
  end
end

# lib/lutaml/klin/shapechange/rule_processors/complex_type_processor.rb
class ComplexTypeProcessor < BaseProcessor
  RULE_ID = 'rule-xsd-cls-type'

  protected

  def applicable?(element)
    @checker.applies?(RULE_ID, element)
  end

  def apply_rule(uml_class, context)
    # Create <xs:complexType name="BuildingType">
    type = context[:xsd_document].create_element('complexType')
    type['name'] = "#{uml_class.name}Type"

    if uml_class.abstract?
      type['abstract'] = 'true'
    end

    context[:schema].add_child(type)

    # Return type element for property processing
    context[:current_type] = type
  end
end
```

### Layer 5: Rule Processor Registry (Factory Pattern)

**Single responsibility**: Create and manage processors

```ruby
# lib/lutaml/klin/shapechange/rule_processor_registry.rb
class RuleProcessorRegistry
  def initialize(rule_checker, config)
    @checker = rule_checker
    @config = config
    @processors = {}
    register_standard_processors
  end

  # Register a processor for a rule
  def register(rule_id, processor_class)
    @processors[rule_id] = processor_class
  end

  # Get processor for a rule
  def processor_for(rule_id)
    processor_class = @processors[rule_id]
    return nil unless processor_class

    processor_class.new(@checker, @config)
  end

  # Get all applicable processors for an element
  def processors_for(element, scope:)
    @processors.select do |rule_id, processor_class|
      # Check if rule applies to this element
      @checker.applies?(rule_id, element) &&
        processor_class::SCOPE == scope
    end.map do |rule_id, processor_class|
      processor_class.new(@checker, @config)
    end
  end

  private

  def register_standard_processors
    # Class processors
    register('rule-xsd-cls-object-element', ObjectElementProcessor)
    register('rule-xsd-cls-type', ComplexTypeProcessor)
    register('rule-xsd-cls-property-type', PropertyTypeProcessor)
    register('rule-xsd-cls-sequence', SequenceProcessor)

    # Property processors
    register('rule-xsd-prop-nillable', NillablePropertyProcessor)
    register('rule-xsd-prop-initialValue', InitialValueProcessor)

    # Can easily add more without modifying this code!
  end
end
```

### Layer 6: Orchestration (Facade Pattern)

**Single responsibility**: Coordinate rule processing

```ruby
# lib/lutaml/klin/shapechange/class_generator.rb
class ClassGenerator
  def initialize(rule_processor_registry)
    @registry = rule_processor_registry
  end

  def generate_for(uml_class, xsd_document, schema_element)
    context = {
      xsd_document: xsd_document,
      schema: schema_element,
      uml_class: uml_class
    }

    # Get all applicable class processors
    processors = @registry.processors_for(uml_class, scope: 'class')

    # Apply each processor in order
    processors.each do |processor|
      processor.process(uml_class, context)
    end

    context
  end
end
```

## Complete Example: Adding a New Rule

### Step 1: Define Rule (Configuration)

**Option A**: In ShapeChange XML (already loaded)

```xml
<EncodingRule name="custom_rule" extends="iso19136_2007">
  <rule name="rule-xsd-cls-custom-annotation"/>
</EncodingRule>
```

**Option B**: In Ruby DSL (new capability)

```ruby
# config/custom_rules.rb
Lutaml::Klin::Shapechange.define_rules do
  encoding_rule 'custom_rule', extends: 'iso19136_2007' do
    rule 'rule-xsd-cls-custom-annotation'
  end

  rule_definition 'rule-xsd-cls-custom-annotation' do
    scope 'class'
    category 'optional'
    applies_to ['FeatureType', 'DataType']
    description 'Adds custom annotation to classes'
  end
end
```

### Step 2: Implement Processor

```ruby
# lib/lutaml/klin/shapechange/rule_processors/custom_annotation_processor.rb
class CustomAnnotationProcessor < BaseProcessor
  RULE_ID = 'rule-xsd-cls-custom-annotation'
  SCOPE = 'class'

  protected

  def applicable?(element)
    @checker.applies?(RULE_ID, element)
  end

  def apply_rule(uml_class, context)
    # Add custom annotation
    annotation = context[:xsd_document].create_element('annotation')
    appinfo = context[:xsd_document].create_element('appinfo')
    appinfo.content = "Custom: #{uml_class.name}"

    annotation.add_child(appinfo)
    context[:current_type]&.add_child(annotation)
  end
end
```

### Step 3: Register Processor

```ruby
# In RuleProcessorRegistry.register_standard_processors
register('rule-xsd-cls-custom-annotation', CustomAnnotationProcessor)
```

**That's it!** No changes to existing code needed. ✅ Open/Closed!

## Benefits of This Architecture

### ✅ Configuration-Driven

**Rules are data**:
- Can be loaded from XML
- Can be loaded from DSL
- Can be loaded from database
- Can be versioned separately

### ✅ Open/Closed Principle

**Add new rules without modifying**:
- Don't touch RuleRegistry
- Don't touch ClassGenerator
- Just add new Processor class
- Just register it

### ✅ MECE Organization

**Each component has distinct responsibility**:
- `EncodingRule` → Rule set definition
- `RuleDefinition` → Individual rule metadata
- `RuleRegistry` → Rule storage and lookup
- `RuleChecker` → Rule applicability
- `RuleProcessor` → Rule application
- `RuleProcessorRegistry` → Processor management

**No overlap, complete coverage**

### ✅ Single Responsibility

**Each class does ONE thing**:
- `RuleRegistry` → Stores rules
- `RuleChecker` → Checks applicability
- `ObjectElementProcessor` → Creates object elements
- `ComplexTypeProcessor` → Creates complex types

### ✅ Extensibility

**Easy to extend**:
1. New encoding rule → Add to XML/DSL
2. New rule processor → Implement BaseProcessor
3. Custom naming → Implement NamingStrategy
4. Custom type builder → Implement TypeBuilderStrategy

## Implementation Phases

### Phase 3.1: Rule Infrastructure (Week 1)

**Day 1**: Models
- ✅ EncodingRule model (already exists)
- ✅ RuleDefinition model (new)
- ✅ Test with existing ShapeChange config

**Day 2**: Registry
- ✅ RuleRegistry class
- ✅ Load from ShapeChange XML
- ✅ Rule inheritance resolution

**Day 3**: Checker
- ✅ RuleChecker class
- ✅ Applicability logic
- ✅ Element category checking

**Day 4**: Base Processor
- ✅ BaseProcessor abstract class
- ✅ Processor contract
- ✅ Context pattern

**Day 5**: Processor Registry
- ✅ RuleProcessorRegistry
- ✅ Factory pattern
- ✅ Registration mechanism

### Phase 3.2: Core Processors (Week 2)

**Implement processors for essential GML 3.2 rules**:

**Day 1**: Class processors
- ✅ ObjectElementProcessor
- ✅ ComplexTypeProcessor
- ✅ PropertyTypeProcessor

**Day 2**: Property processors
- ✅ PropertyElementProcessor
- ✅ PropertyAttributeProcessor
- ✅ MultiplicityProcessor

**Day 3**: Naming processors
- ✅ GmlNamingProcessor
- ✅ ISO19139NamingProcessor
- ✅ TypeSuffixProcessor

**Day 4**: Special processors
- ✅ CodeListProcessor
- ✅ EnumerationProcessor
- ✅ UnionProcessor

**Day 5**: Integration testing

### Phase 3.3: XSD Generation (Week 3)

**Implement actual XSD generation using processors**:

**Days 1-2**: XsdGenerator
- Use RuleProcessorRegistry
- Apply processors to UML classes
- Build XSD document

**Days 3-4**: Testing
- Generate PLATEAU URO schema
- Compare with ShapeChange output
- Fix discrepancies

**Day 5**: Documentation

## Example: Complete Flow

```ruby
# 1. Load configuration
config = ConfigParser.parse_file('config.xml')

# 2. Create rule registry
registry = RuleRegistry.new
config.encoding_rules.each { |er| registry.register_encoding_rule(er) }

# 3. Create rule checker for specific encoding rule
checker = RuleChecker.new(registry, 'iso19136_2007')

# 4. Create processor registry
proc_registry = RuleProcessorRegistry.new(checker, config)

# 5. Generate XSD
generator = XsdGenerator.new(proc_registry)
xsd_doc = generator.generate(uml_package)

# 6. Write file
XsdWriter.write(xsd_doc, 'output.xsd')
```

**All configurable, all extensible, all following OO principles!**

## Summary

This architecture ensures:
- ✅ **Configuration-driven**: Rules are data, loaded from config
- ✅ **Open/Closed**: Add rules without modifying code
- ✅ **MECE**: Clear separation of responsibilities
- ✅ **Single Responsibility**: Each class has one job
- ✅ **Extensibility**: Strategy/Factory patterns throughout
- ✅ **Testability**: Each component independently testable

Ready to implement in Phase 3.2!