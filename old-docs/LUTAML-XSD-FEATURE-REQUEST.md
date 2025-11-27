# lutaml-xsd Feature Request: SchemaRepository for Namespace-Aware Type Resolution

## Overview

This document describes features needed in `lutaml-xsd` to support namespace-aware, multi-schema type resolution for UML-to-XSD mapping in `lutaml-klin`.

## Background

Currently, when mapping UML models to XSD schemas, we encounter type references like `gml:CodeType` that:
1. Use XML namespace prefixes (`gml:`)
2. Reference types defined in external schemas (e.g., `basicTypes.xsd`)
3. Require namespace-to-schema mapping to resolve

Without these features, 94.1% of type references remain unresolved.

## Core Concept: SchemaRepository

A **SchemaRepository** is a fully resolved, validated, searchable collection of XSD schemas that:
- Parses multiple XSD files and follows all imports/includes
- Builds a unified namespace registry
- Creates a cross-schema type index
- Provides namespace-aware type resolution
- Validates all references

## Required Features

### 1. SchemaRepository Class

```ruby
module Lutaml
  module Xsd
    class SchemaRepository
      # Build repository from XSD files
      def self.build(schema_files, schema_mappings: {})
        # Parse all XSD files
        # Follow all imports/includes recursively
        # Build namespace registry
        # Create type index
        # Validate references
        # Return repository instance
      end

      # Configure namespace prefix mappings
      def configure_namespaces(prefix_to_uri_map)
        # Example: { "gml" => "http://www.opengis.net/gml/3.2", ... }
      end

      # Resolve qualified type name
      def resolve_type(qname)
        # Input: "gml:CodeType" or "xs:string" or "{http://...}CodeType"
        # Output: TypeResolutionResult
      end

      # Query capabilities
      def elements_in_namespace(namespace_uri)
      def types_in_namespace(namespace_uri)
      def all_namespaces
      def statistics
    end
  end
end
```

### 2. TypeResolutionResult

```ruby
class TypeResolutionResult
  attr_reader :resolved       # Boolean
  attr_reader :qname          # Original qualified name
  attr_reader :namespace      # Resolved namespace URI
  attr_reader :local_name     # Local name without prefix
  attr_reader :definition     # The type definition object
  attr_reader :schema_file    # Source XSD file
  attr_reader :resolution_path # Array of resolution steps
  attr_reader :error_message  # If not resolved
end
```

### 3. Namespace Registry (Internal)

Should handle:
- Prefix → URI mapping (e.g., `gml` → `http://www.opengis.net/gml/3.2`)
- URI → Prefix mapping (reverse lookup)
- Schema → Namespace mapping
- Namespace → Schema mapping

### 4. Qualified Name Parsing

Support multiple notations:
- **Prefixed QName**: `gml:CodeType`
- **Clark Notation**: `{http://www.opengis.net/gml/3.2}CodeType`
- **Unprefixed**: `CodeType` (uses default namespace)

### 5. Import/Include Resolution

Must recursively resolve:
- `<xs:import>` declarations (cross-namespace)
- `<xs:include>` declarations (same namespace)
- `schemaLocation` attribute values
- Support schema_mappings for local file resolution

### 6. Type Index

Build searchable index of all types across all schemas:
```ruby
{
  "{http://www.opengis.net/gml/3.2}CodeType" => {
    type: :simpleType,
    definition: <SimpleType object>,
    schema_file: "basicTypes.xsd"
  },
  # ... thousands more
}
```

### 7. Validation

Validate during build:
- ✅ All imports resolve to accessible files
- ✅ All type references resolve (no dangling refs)
- ✅ Namespace declarations are consistent
- ✅ No circular imports
- ✅ Schema locations are accessible

Provide detailed error messages for validation failures.

## Usage Example

```ruby
# In lutaml-klin
require "lutaml/xsd"

# Step 1: Load namespace configuration (from ShapeChange)
namespace_config = {
  "gml" => "http://www.opengis.net/gml/3.2",
  "xs" => "http://www.w3.org/2001/XMLSchema",
  "xlink" => "http://www.w3.org/1999/xlink",
  # ... etc
}

# Step 2: Build schema repository
schema_files = [
  "/path/to/urbanFunction.xsd",
  "/path/to/urbanObject.xsd"
  # Additional schemas loaded automatically via imports
]

schema_mappings = [
  { from: %r{../../gml/(.+\.xsd)$},
    to: "/path/to/gml/3.2.1/\\1" }
  # ... etc
]

repository = Lutaml::Xsd::SchemaRepository.build(
  schema_files,
  schema_mappings: schema_mappings
)

# Step 3: Configure namespace prefixes
repository.configure_namespaces(namespace_config)

# Step 4: Resolve types
result = repository.resolve_type("gml:CodeType")

if result.resolved?
  puts "✓ Resolved: #{result.qname}"
  puts "  Namespace: #{result.namespace}"
  puts "  Schema: #{result.schema_file}"
  puts "  Type: #{result.definition.class}"
else
  puts "✗ Failed to resolve: #{result.qname}"
  puts "  Error: #{result.error_message}"
end

# Step 5: Query repository
puts "Loaded schemas: #{repository.statistics[:total_schemas]}"
puts "Total types: #{repository.statistics[:total_types]}"
puts "Namespaces: #{repository.all_namespaces.join(', ')}"
```

## Expected Output Format

### TypeResolutionResult (Successful)

```ruby
{
  resolved: true,
  qname: "gml:CodeType",
  namespace: "http://www.opengis.net/gml/3.2",
  local_name: "CodeType",
  definition: #<Lutaml::Xsd::SimpleType name="CodeType" ...>,
  schema_file: "basicTypes.xsd",
  resolution_path: [
    "gml:CodeType",
    "{http://www.opengis.net/gml/3.2}CodeType",
    "basicTypes.xsd#CodeType"
  ]
}
```

### TypeResolutionResult (Failed)

```ruby
{
  resolved: false,
  qname: "gml:InvalidType",
  namespace: "http://www.opengis.net/gml/3.2",
  local_name: "InvalidType",
  definition: nil,
  schema_file: nil,
  resolution_path: ["gml:InvalidType", "{http://...}InvalidType"],
  error_message: "Type 'InvalidType' not found in namespace 'http://www.opengis.net/gml/3.2'. Did you mean: CodeType, CodeListType?"
}
```

## Performance Considerations

### Lazy Loading
```ruby
repository = Lutaml::Xsd::SchemaRepository.build(
  primary_schemas: ["urbanFunction.xsd"],
  lazy_load: true  # Only load imported schemas when needed
)
```

### Caching
- Cache parsed schemas to avoid re-parsing
- Cache resolution results for frequently accessed types
- Support serialization for repository persistence

## Edge Cases to Handle

1. **Default Namespace**: Types without prefix in default namespace
2. **Multiple Prefixes**: Same namespace with different prefixes
3. **Namespace Conflicts**: Same prefix mapped to different namespaces
4. **Circular Imports**: Schema A imports B, B imports A
5. **Missing Schemas**: Import references non-existent file
6. **Type Inheritance**: ComplexType extends another ComplexType
7. **Substitution Groups**: Element substitution chains
8. **Anonymous Types**: Types defined inline without names

## Integration Points

### Input (from lutaml-klin)
- List of primary XSD files
- Schema location mappings (for local file resolution)
- Namespace prefix configuration

### Output (to lutaml-klin)
- TypeResolutionResult objects
- Repository statistics
- Validation errors/warnings

## Success Criteria

A successful implementation should:

1. ✅ Load and parse 40+ XSD schemas (GML, ISO, etc.)
2. ✅ Resolve 1000+ type definitions across schemas
3. ✅ Handle qualified names with namespace prefixes
4. ✅ Follow imports recursively without infinite loops
5. ✅ Validate all type references
6. ✅ Provide clear error messages
7. ✅ Complete repository build in < 5 seconds for typical schema sets
8. ✅ Increase lutaml-klin type resolution rate from 5.9% to > 90%

## Reference Materials

### Example Namespace Configuration
See: `reference/shapechange-configs/StandardNamespaces.xml`

Format:
```xml
<XmlNamespace
  nsabr="gml"
  ns="http://www.opengis.net/gml/3.2"
  location="http://schemas.opengis.net/gml/3.2.1/gml.xsd" />
```

### Example Usage in lutaml-xsd
See: `/Users/mulgogi/src/lutaml/lutaml-xsd/examples/parse_urban_function.rb`

Shows current approach to schema_mappings and parsing.

### Target Schema Collections
- **GML 3.2.1**: 29 schema files
- **ISO 19139**: 17 schema files for metadata
- **i-UR (PLATEAU)**: Urban object schemas
- **Total**: ~60 schema files, 1200+ types

## Questions for lutaml-xsd Maintainers

1. Should `SchemaRepository` be a singleton or support multiple instances?
2. Preferred API for configuring namespaces? (Constructor vs method call)
3. Should repository support incremental updates (add schemas later)?
4. Preferred serialization format for caching (Marshal, JSON, YAML)?
5. Should validation be strict (fail on error) or lenient (warn and continue)?

## Appendix: Current Problem

### Before (5.9% Resolution)

```ruby
# Simple name matching - no namespace awareness
attr.type = "gml:CodeType"
# Looks for exact match "gml:CodeType" in element names
# Fails because element is named "CodeType" without prefix
```

### After (>90% Resolution Expected)

```ruby
# Namespace-aware resolution
repository.resolve_type("gml:CodeType")
# 1. Parse "gml:CodeType" → prefix="gml", local="CodeType"
# 2. Resolve prefix → "http://www.opengis.net/gml/3.2"
# 3. Find schema for namespace → basicTypes.xsd
# 4. Search for "CodeType" in that schema → SUCCESS
```

---

**Contact**: lutaml-klin maintainers
**Priority**: High - Blocks UML-to-XSD mapping functionality
**Timeline**: Needed for PLATEAU project deliverables
