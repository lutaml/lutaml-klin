# XSD Generation Implementation Plan: lutaml-klin generate

## Goal

Implement `lutaml-klin generate` command that generates XSD files from LUR packages, being 100% compatible with ShapeChange's XmlSchema target.

## Architecture

### Module Organization

```
lib/lutaml/klin/shapechange/
├── xsd_generator.rb           # Main generator orchestrator
├── xsd_document_builder.rb    # Builds XSD document structure
├── class_processor.rb          # Processes UML classes
├── property_processor.rb       # Processes UML attributes
├── type_builder.rb             # Builds XSD types (complex, simple)
├── element_builder.rb          # Builds XSD elements
├── naming_rules.rb             # GML/ISO naming conventions
├── encoding_rules_engine.rb    # Applies encoding rules
└── xsd_writer.rb               # Writes XSD to files
```

### Data Flow

```
lutaml-klin generate \
  --lur model.lur \
  --config shapechange.xml \
  --packages "uro,urf" \
  --output schemas/

    ↓

┌─────────────────────┐
│ GenerateCommand     │ ← CLI interface
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│ XsdGenerator        │ ← Main orchestrator
└──────────┬──────────┘
           │
           ├─ Load LUR package
           ├─ Load ShapeChange config
           ├─ For each package:
           │   ├─ Create XsdDocumentBuilder
           │   ├─ Process all classes
           │   └─ Write XSD file
           │
           ↓
Output: schemas/
├── urbanFunction.xsd
├── urbanObject.xsd
└── building.xsd
```

## Phase 3A: Core Implementation (Week 1-2)

### Step 1: Create XsdGenerator Service

**File**: `lib/lutaml/klin/shapechange/xsd_generator.rb`

```ruby
module Lutaml::Klin::Shapechange
  # Main XSD generation orchestrator
  # Coordinates UML loading, transformation, and XSD writing
  class XsdGenerator
    attr_reader :uml_repository, :config

    def initialize(uml_repository, config)
      @uml_repository = uml_repository
      @config = config
    end

    # Generate XSD schemas for specified packages
    # @param package_names [Array<String>] Package names to process
    # @param output_dir [String] Output directory for XSD files
    # @return [Array<Hash>] Generated files info
    def generate_schemas(package_names, output_dir)
      results = []

      package_names.each do |pkg_name|
        # Find UML package
        package = uml_repository.find_package(pkg_name)
        raise "Package not found: #{pkg_name}" unless package

        # Get package info from config
        package_info = config.package_infos.find do |pi|
          pi.package_name&.strip == pkg_name
        end

        # Build XSD document
        builder = XsdDocumentBuilder.new(package, package_info, config)
        xsd_document = builder.build

        # Write to file
        filename = package_info&.xsd_document || "#{pkg_name}.xsd"
        filepath = File.join(output_dir, filename)

        writer = XsdWriter.new
        writer.write(xsd_document, filepath)

        results << {
          package: pkg_name,
          file: filepath,
          namespace: package_info&.ns
        }
      end

      results
    end
  end
end
```

### Step 2: Create XsdDocumentBuilder

**File**: `lib/lutaml/klin/shapechange/xsd_document_builder.rb`

```ruby
module Lutaml::Klin::Shapechange
  # Builds complete XSD document from UML package
  # Implements ShapeChange's XsdDocument.java logic
  class XsdDocumentBuilder
    def initialize(uml_package, package_info, config)
      @package = uml_package
      @package_info = package_info
      @config = config
      @encoding_rules = EncodingRulesEngine.new(config)
      @naming = NamingRules.new(config)
    end

    def build
      # Create XML document
      doc = Nokogiri::XML::Document.new

      # Create schema root element
      schema = create_schema_element(doc)
      doc.add_child(schema)

      # Add namespace declarations
      add_namespaces(schema)

      # Add imports
      add_imports(schema)

      # Process all classes in package
      @package.classes.each do |uml_class|
        process_class(uml_class, schema)
      end

      doc
    end

    private

    def create_schema_element(doc)
      schema = Nokogiri::XML::Node.new('schema', doc)
      schema.namespace = doc.create_internal_subset(
        'xs',
        'http://www.w3.org/2001/XMLSchema'
      )

      # Set attributes
      schema['targetNamespace'] = @package_info.ns
      schema['xmlns:' + @package_info.nsabr] = @package_info.ns
      schema['elementFormDefault'] = 'qualified'
      schema['version'] = @package_info.version

      schema
    end

    def process_class(uml_class, schema)
      processor = ClassProcessor.new(
        @config,
        @encoding_rules,
        @naming
      )

      processor.process(uml_class, schema)
    end
  end
end
```

### Step 3: Create ClassProcessor

**File**: `lib/lutaml/klin/shapechange/class_processor.rb`

```ruby
module Lutaml::Klin::Shapechange
  # Processes UML classes and generates XSD constructs
  # Implements ShapeChange's XmlSchema.process() logic
  class ClassProcessor
    def initialize(config, encoding_rules, naming)
      @config = config
      @rules = encoding_rules
      @naming = naming
    end

    def process(uml_class, schema_element)
      case uml_class.stereotype
      when 'FeatureType'
        process_feature_type(uml_class, schema_element)
      when 'DataType'
        process_data_type(uml_class, schema_element)
      when 'CodeList'
        process_code_list(uml_class, schema_element)
      when 'Enumeration'
        process_enumeration(uml_class, schema_element)
      when 'Union'
        process_union(uml_class, schema_element)
      end
    end

    private

    def process_feature_type(uml_class, schema)
      # 1. Create object element
      if @rules.applies?('rule-xsd-cls-object-element')
        create_object_element(uml_class, schema)
      end

      # 2. Create complex type
      if @rules.applies?('rule-xsd-cls-type')
        type_element = create_complex_type(uml_class, schema)

        # 3. Add properties
        if @rules.applies?('rule-xsd-cls-local-properties')
          add_properties(uml_class, type_element)
        end
      end

      # 4. Create property type
      if @rules.applies?('rule-xsd-cls-property-type')
        create_property_type(uml_class, schema)
      end
    end
  end
end
```

### Step 4: Create CLI Command

**File**: `lib/lutaml/klin/commands/generate_command.rb`

```ruby
module Lutaml::Klin::Commands
  class GenerateCommand
    def initialize(options)
      @options = options
    end

    def run
      # Load LUR
      lur_adapter = Repositories::UmlRepositoryAdapter.new(@options[:lur])

      # Load config
      parser = Shapechange::ConfigParser.new
      config = parser.parse_file(@options[:config])

      # Generate XSD
      generator = Shapechange::XsdGenerator.new(
        lur_adapter.repository,
        config
      )

      packages = (@options[:packages] || '**').split(',')

      results = generator.generate_schemas(
        packages,
        @options[:output]
      )

      # Display results
      puts "Generated #{results.size} XSD file(s):"
      results.each do |r|
        puts "  - #{r[:file]} (#{r[:namespace]})"
      end
    end
  end
end
```

**Add to CLI**:

```ruby
# lib/lutaml/klin/cli.rb
desc "generate LUR CONFIG", "Generate XSD schemas from UML"
option :lur, required: true, desc: "Path to LUR package"
option :config, required: true, desc: "Path to ShapeChange config"
option :packages, desc: "Package names (comma-separated)"
option :output, default: "schemas", desc: "Output directory"
option :verbose, type: :boolean, default: false

def generate
  require_relative "commands/generate_command"
  cmd = Commands::GenerateCommand.new(options)
  cmd.run
end
```

## Implementation Roadmap

### Week 1: Foundation

**Days 1-2**: Core structure
- ✅ Create XsdGenerator
- ✅ Create XsdDocumentBuilder
- ✅ Create basic ClassProcessor

**Days 3-4**: Type builders
- ✅ TypeBuilder for complexType/simpleType
- ✅ ElementBuilder for elements
- ✅ Basic property processing

**Day 5**: CLI integration
- ✅ GenerateCommand
- ✅ CLI wiring
- ✅ Basic testing

### Week 2: Encoding Rules

**Days 1-3**: GML 3.2 rules
- ✅ rule-xsd-all-naming-gml
- ✅ rule-xsd-cls-standard-gml-property-types
- ✅ rule-xsd-prop-inlineOrByReference

**Days 4-5**: Special cases
- ✅ CodeList handling
- ✅ Enumeration handling
- ✅ Union handling

### Week 3: Property Processing

**Days 1-2**: Property types
- ✅ PropertyType generation
- ✅ PropertyByValueType
- ✅ Multiplicity handling

**Days 3-4**: Advanced features
- ✅ nilReason support
- ✅ Initial values
- ✅ Constraints/facets

**Day 5**: Testing
- ✅ Unit tests
- ✅ Integration tests

### Week 4: Validation & Polish

**Days 1-3**: Comparison with ShapeChange
- ✅ Generate same XSD for test cases
- ✅ Byte-for-byte comparison
- ✅ Fix discrepancies

**Days 4-5**: Documentation
- ✅ Update README
- ✅ Usage examples
- ✅ Architecture docs

## Success Criteria

✅ `lutaml-klin generate` command works
✅ Generates valid XSD files
✅ 100% compatible with ShapeChange for PLATEAU test cases
✅ All GML 3.2 encoding rules implemented
✅ Comprehensive test coverage
✅ Documentation complete

## Next Immediate Steps

This is too large for a single task. I should create it as a series of focused tasks:

**Phase 3.1**: Design and create module structure (this planning)
**Phase 3.2**: Implement core XsdGenerator (Code Mode - 2-3 days)
**Phase 3.3**: Implement class processors (Code Mode - 3-4 days)
**Phase 3.4**: Implement property processors (Code Mode - 2-3 days)
**Phase 3.5**: Testing and validation (Code Mode - 1 week)

Let me start with Phase 3.1 planning...