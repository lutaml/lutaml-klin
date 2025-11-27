# LutaML API Usage Patterns

**Version**: 1.0  
**Date**: 2025-01-22  
**Status**: Validated against lutaml v1.0 API

---

## Overview

This document describes the correct patterns for using the lutaml gem API in lutaml-klin. These patterns were validated during Phase B3 API review and ensure compatibility with the lutaml gem's actual API.

---

## Critical API Facts

### UML Classes Have NO Direct Package Reference

**WRONG ❌**:
```ruby
# This does NOT exist in lutaml API
package_name = uml_class.package&.name
namespace = uml_class.package&.xmlns
```

**CORRECT ✅**:
```ruby
# Package context comes from Repository queries or qualified_name
package_path = if uml_class.respond_to?(:qualified_name)
                 uml_class.qualified_name  # e.g., "ModelRoot::i-UR::uro::Building"
               else
                 uml_class.name
               end

# Get package from Repository
package = repository.find_package("ModelRoot::i-UR::uro")
```

### Package Metadata Comes from ShapeChange Config

**Package-level information** (xmlns, namespace, version) is NOT stored in UML classes. It comes from ShapeChange configuration's PackageInfo entries.

**CORRECT ✅**:
```ruby
# From ShapeChange config
package_info = shapechange_config.find_package_info(package_path)
namespace = package_info&.xmlns
prefix = package_info&.xmlns_prefix
```

---

## Repository API Patterns

### UmlRepositoryAdapter (Infrastructure Layer)

```ruby
# Initialize from LUR package
adapter = UmlRepositoryAdapter.new("plateau.lur")
repository = adapter.repository

# Find package by path
package = adapter.find_package("ModelRoot::i-UR::uro")

# Find class by qualified name
uml_class = adapter.find_class("ModelRoot::i-UR::uro::Building")

# Get classes in package
classes = adapter.classes_in_package("ModelRoot::i-UR::uro", recursive: false)

# Get enums in package
enums = adapter.enums_in_package("ModelRoot::i-UR::uro", recursive: false)

# Find classes by stereotype
feature_types = adapter.find_classes_by_stereotype("FeatureType")

# Get all packages
all_packages = adapter.all_packages

# Get statistics
stats = adapter.statistics
```

### SchemaRepositoryAdapter (Infrastructure Layer)

```ruby
# Initialize from LXR package
adapter = SchemaRepositoryAdapter.new("schemas.lxr")

# Find XSD type
xsd_type = adapter.find_type("BuildingType", 
                              namespace: "https://www.geospatial.jp/iur/uro/3.2")

# Find XSD element
xsd_element = adapter.find_element("Building",
                                   namespace: "https://www.geospatial.jp/iur/uro/3.2")

# Get all namespaces
namespaces = adapter.all_namespaces

# Get types in namespace
types = adapter.types_in_namespace("https://www.geospatial.jp/iur/uro/3.2")
```

---

## UML Class Property Access Patterns

### Safe Property Access (Defensive Programming)

**ALWAYS use `respond_to?` checks** before accessing properties:

```ruby
# Check if property exists before accessing
qualified_name = if uml_class.respond_to?(:qualified_name)
                   uml_class.qualified_name
                 else
                   uml_class.name  # Fallback
                 end

# Check stereotype
stereotype = if uml_class.respond_to?(:stereotype)
               uml_class.stereotype
             else
               nil
             end

# Check for abstract
is_abstract = if uml_class.respond_to?(:is_abstract)
                uml_class.is_abstract
              else
                false
              end
```

### Common UML Class Properties

Properties that **DO exist** in lutaml UML classes:

```ruby
uml_class.name              # ✅ String: class name
uml_class.qualified_name    # ✅ String: full path (e.g., "ModelRoot::i-UR::uro::Building")
uml_class.stereotype        # ✅ String/Array: stereotype(s)
uml_class.attributes        # ✅ Array: UML attributes
uml_class.documentation     # ✅ String: documentation text
uml_class.is_abstract       # ✅ Boolean: abstract flag
uml_class.generalization    # ✅ Object: superclass relationship
uml_class.category          # ✅ Symbol: :featureType, :dataType, etc.
```

Properties that **DO NOT exist**:

```ruby
uml_class.package           # ❌ DOES NOT EXIST
uml_class.xmlns             # ❌ DOES NOT EXIST (comes from ShapeChange config)
uml_class.namespace         # ❌ DOES NOT EXIST (comes from ShapeChange config)
```

### Common UML Attribute Properties

```ruby
uml_attr.name               # ✅ String: attribute name
uml_attr.type               # ✅ String: type name
uml_attr.multiplicity       # ✅ String: "0..1", "1..*", etc.
uml_attr.documentation      # ✅ String: documentation text
```

---

## Domain Layer Patterns

### TransformationAnalyzer

```ruby
analyzer = TransformationAnalyzer.new(shapechange_config)

# Analyze class transformation
analysis = analyzer.analyze_class(uml_class)
# => {
#   element_name: "Building",
#   type_name: "BuildingType",
#   property_type_name: "BuildingPropertyType",
#   namespace: "https://www.geospatial.jp/iur/uro/3.2"
# }

# Analyze attribute transformation
attr_analysis = analyzer.analyze_attribute(uml_attr)
# => {
#   xml_name: "height",
#   xml_type: "gml:LengthType",
#   is_attribute: false
# }

# Get namespace from qualified name (not from uml_class.package)
namespace = analyzer.determine_namespace(uml_class)
```

### MappingService

```ruby
service = MappingService.new(resolution_engine, transformation_analyzer)

# Map class to XSD
class_mapping = service.map_class_to_xsd(uml_class, xsd_namespace, context)

# Map attribute to XSD
attr_mapping = service.map_attribute_to_xsd(uml_attr, context)
```

### DomainTypeStrategy

```ruby
strategy = DomainTypeStrategy.new

# Check if applicable
if strategy.applicable?(uml_element, context)
  result = strategy.resolve(uml_element, context: context)
  puts result.xsd_type  # => "BuildingType"
end
```

---

## XSD Generation Patterns

### XsdGenerator

**CORRECT ✅**: Pass package_name as parameter

```ruby
# In XsdGenerator#process_class
xsd_doc.add_element(
  name: uml_class.name,
  type: "#{prefix}:#{uml_class.name}Type",
  package_name: package_name  # ✅ Passed from context
)
```

**WRONG ❌**: Try to access uml_class.package

```ruby
# DON'T DO THIS - package property doesn't exist
xsd_doc.add_element(
  name: uml_class.name,
  package_name: uml_class.package&.name  # ❌ WRONG
)
```

### Rule Processors

All rule processors receive context with package information:

```ruby
class MyProcessor < BaseRuleProcessor
  def process(uml_class, xsd_doc, context)
    # Get package info from context, NOT from uml_class
    package_name = context[:package_name]
    namespace = context[:namespace]
    prefix = context[:prefix]
    
    # Use uml_class properties that DO exist
    element_name = uml_class.name
    stereotype = uml_class.stereotype
  end
end
```

---

## ShapeChange Configuration Access

### PackageInfo Lookup

```ruby
# Get package info from ShapeChange config
package_info = shapechange_config.find_package_info(package_path)

if package_info
  xmlns = package_info.xmlns
  prefix = package_info.xmlns_prefix
  version = package_info.version
end
```

### Type Mapping Lookup

```ruby
# Get type mapping from ShapeChange config
map_entry = shapechange_config.find_type_mapping("CharacterString",
                                                  encoding_rule: "citygml")

if map_entry
  xsd_type = map_entry.xml_type      # => "xs:string"
  target_type = map_entry.target     # => "string"
end
```

---

## Common Mistakes to Avoid

### ❌ Mistake 1: Accessing .package directly

```ruby
# WRONG - package property doesn't exist
namespace = uml_class.package&.xmlns
```

**Fix**:
```ruby
# CORRECT - get from ShapeChange config
package_path = uml_class.qualified_name
package_info = shapechange_config.find_package_info(package_path)
namespace = package_info&.xmlns
```

### ❌ Mistake 2: Assuming package metadata in UML

```ruby
# WRONG - xmlns is not in UML model
xmlns = uml_class.package&.xmlns
```

**Fix**:
```ruby
# CORRECT - xmlns comes from ShapeChange PackageInfo
xmlns = shapechange_config.namespace_for_package(package_path)
```

### ❌ Mistake 3: Not using respond_to? checks

```ruby
# RISKY - might not exist
value = uml_class.some_property
```

**Fix**:
```ruby
# SAFE - check before accessing
value = if uml_class.respond_to?(:some_property)
          uml_class.some_property
        else
          default_value
        end
```

---

## Testing Patterns

### Testing with UML Classes

```ruby
# In specs, create UML class doubles with correct properties
let(:uml_class) do
  double("UmlClass",
    name: "Building",
    qualified_name: "ModelRoot::i-UR::uro::Building",
    stereotype: "FeatureType",
    attributes: [],
    documentation: "A building feature",
    is_abstract: false
    # Note: NO .package property
  )
end
```

### Testing with Repositories

```ruby
# Mock repository adapter correctly
let(:uml_repository) do
  double("UmlRepository").tap do |repo|
    allow(repo).to receive(:find_class).with("Building").and_return(uml_class)
    allow(repo).to receive(:find_package).with("ModelRoot::i-UR::uro").and_return(package)
  end
end
```

---

## Summary of Key Patterns

1. **Never access `.package` on UML classes** - it doesn't exist
2. **Always use `respond_to?` checks** before accessing properties
3. **Get package metadata from ShapeChange config**, not from UML
4. **Use qualified_name to determine package context**
5. **Pass package_name as parameter** to methods that need it
6. **Use Repository API** for querying UML elements
7. **Use defensive programming** - assume properties might not exist

---

## References

- lutaml gem: https://github.com/lutaml/lutaml
- lutaml-xsd gem: https://github.com/lutaml/lutaml-xsd
- Phase B2 Fix: Fixed xsd_generator.rb to pass package_name as parameter
- ARCHITECTURE.md: Complete system architecture documentation

---

**Last Updated**: 2025-01-22  
**Validated By**: Phase B3 API Review