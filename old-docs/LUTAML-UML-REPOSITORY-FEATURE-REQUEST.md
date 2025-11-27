# lutaml (lutaml-xmi) Feature Request: UML Repository with LUR Package Format

## Overview

This document specifies a comprehensive **UML Repository** system for the `lutaml` gem (lutaml-xmi) that provides:
- **LUR Package Format** (`.lur` files) - Portable, pre-indexed UML model packages
- **UmlRepository API** - Rich query interface for navigating and inspecting UML models
- **CLI Tools** - Interactive commands for exploring models, showing diagrams, and searching
- **Performance** - Instant loading via pre-serialization (vs. slow XMI parsing)

This creates perfect symmetry with `lutaml-xsd`'s LXR package system and enables tools like `lutaml-klin` to work purely with pre-built repositories instead of parsing raw files.

## Background & Motivation

### Current Problems

1. **Slow XMI Parsing**: 5-8 seconds to parse large EA XMI files on every run
2. **No Model Navigation**: Can't explore UML model structure without custom code
3. **Limited Queries**: No built-in support for path-based lookups, searches, or filtering
4. **No Caching**: Parse the same XMI repeatedly for different tools
5. **Poor Reusability**: Each tool must implement its own XMI parsing logic

### Solution: LUR Package System

**LUR (LutaML UML Repository)** packages solve these problems by:
- Parsing XMI once and creating an optimized, searchable repository
- Pre-building indexes for packages, classes, attributes, associations, diagrams
- Serializing the repository for instant loading (<100ms vs 5-8s)
- Providing rich CLI tools for exploring and querying the model
- Enabling repository sharing and distribution

## Core Concepts

### 1. UmlRepository

A fully indexed, queryable in-memory representation of a UML model with:
- **Package hierarchy** with path-based navigation
- **Class index** with qualified name lookups
- **Type resolution** for attribute data types
- **Association tracking** including ownership and navigability
- **Diagram metadata** for visualization
- **Search capabilities** across all model elements

### 2. LUR Package Format

A portable ZIP archive (`.lur` extension) containing:
- Pre-serialized UML model objects (marshal/json/yaml)
- Multi-level indexes (package paths, class names, stereotypes, etc.)
- Metadata (model statistics, creation info, source XMI)
- Optional: Original XMI file for reference
- Optional: Diagram images and layout data

### 3. UML Path Syntax

```
ModelRoot                           # Root package
ModelRoot::Conceptual Models        # Package "Conceptual Models"
ModelRoot::Conceptual Models::i-UR  # Nested package
ModelRoot::*                        # All direct children
ModelRoot::**                       # All descendants (recursive)
ModelRoot::*::urf                   # Any package ending with "urf"
```

## LUR Package Structure

```
plateau_uml.lur (ZIP archive, ~15-30 MB for PLATEAU model)

├── metadata.yaml
│   name: "PLATEAU UML Model"
│   version: "2024.1"
│   created_at: "2025-10-25T09:00:00Z"
│   created_by: "lutaml-xmi CLI v1.0.0"
│   lutaml_version: "1.0.0"
│
│   source:
│     xmi_file: "20251010-242.xmi"
│     xmi_version: "2.5.1"
│     tool: "Enterprise Architect"
│     tool_version: "15.2"
│
│   statistics:
│     total_packages: 127
│     total_classes: 1750
│     total_attributes: 12500
│     total_associations: 2300
│     total_diagrams: 45
│     max_depth: 5
│
│   configuration:
│     serialization_format: "marshal"  # or json, yaml
│     include_xmi: true
│     include_diagrams: true
│     compression_level: 6
│
├── xmi_source/  (optional - if include_xmi: true)
│   └── 20251010-242.xmi
│
├── models/  (pre-serialized UML objects)
│   ├── packages.marshal         # Package hierarchy
│   ├── classes.marshal          # All class definitions
│   ├── attributes.marshal       # All attribute definitions
│   ├── associations.marshal     # All associations
│   ├── diagrams.marshal         # Diagram metadata
│   └── generalizations.marshal  # Inheritance relationships
│
├── indexes/  (pre-built lookup tables)
│   ├── package_paths.marshal    # Path → Package
│   │   "ModelRoot::i-UR::urf" => Package{id: "pkg_123", ...}
│   │
│   ├── qualified_names.marshal  # QName → Class
│   │   "i-UR::urf::UrbanPlanningArea" => Class{id: "cls_456", ...}
│   │
│   ├── stereotypes.marshal      # Stereotype → Classes[]
│   │   "featureType" => [Class{}, Class{}, ...]
│   │
│   ├── diagrams_by_package.marshal  # Package → Diagrams[]
│   │   "pkg_123" => [Diagram{}, Diagram{}, ...]
│   │
│   └── search_index.marshal     # Text search index
│       "urban" => [Class{}, Attribute{}, ...]
│
├── diagrams/  (optional - if include_diagrams: true)
│   ├── diagram_001.png
│   ├── diagram_001.svg
│   ├── diagram_001_layout.json  # Positions, sizes, etc.
│   └── ...
│
└── statistics.yaml
    packages_by_depth:
      1: 3
      2: 15
      3: 45
      4: 52
      5: 12

    classes_by_stereotype:
      featureType: 234
      dataType: 156
      codeList: 89
      interface: 23
      enumeration: 45

    attribute_type_distribution:
      CharacterString: 2340
      Integer: 890
      Boolean: 456
      Date: 234
      ...

    most_complex_classes:
      - name: "Building"
        attributes: 45
        associations: 23
      ...
```

## UmlRepository API

### Core Repository Class

```ruby
module Lutaml
  module Xmi
    class UmlRepository
      # ============================================
      # CONSTRUCTION
      # ============================================

      # Build repository from XMI file
      def self.from_xmi(xmi_path, options = {})
        # Parse XMI using lutaml-xmi
        # Build model object graph
        # Create all indexes
        # Return repository instance
        #
        # Options:
        #   ea_extension: true     # Handle EA-specific extensions
        #   validate: true         # Validate model consistency
        #   include_diagrams: true # Extract diagram metadata
      end

      # Load repository from LUR package
      def self.from_package(lur_path)
        # Extract ZIP archive
        # Deserialize models
        # Rebuild indexes
        # Return repository instance (instant <100ms)
      end

      # Export repository to LUR package
      def export_to_package(output_path, options = {})
        # Serialize all models
        # Build indexes
        # Create ZIP archive
        #
        # Options:
        #   name: "Package Name"
        #   version: "1.0"
        #   description: "Description"
        #   include_xmi: true
        #   include_diagrams: true
        #   serialization_format: :marshal  # :json, :yaml
        #   compression_level: 6
      end

      # ============================================
      # PACKAGE NAVIGATION
      # ============================================

      # Find package by path
      def find_package(path)
        # path: "ModelRoot::Conceptual Models::i-UR"
        # Returns: Package or nil
      end

      # List packages at path level
      def list_packages(path = "ModelRoot", recursive: false)
        # path: "ModelRoot::Conceptual Models"
        # recursive: false → direct children only
        # recursive: true → all descendants
        # Returns: Array<Package>
      end

      # Get package tree (for CLI tree view)
      def package_tree(path = "ModelRoot", max_depth: nil)
        # Returns hierarchical structure for tree display
        # {
        #   name: "ModelRoot",
        #   path: "ModelRoot",
        #   children: [
        #     { name: "i-UR", path: "ModelRoot::i-UR", children: [...] }
        #   ]
        # }
      end

      # ============================================
      # CLASS QUERIES
      # ============================================

      # Find class by qualified name
      def find_class(qualified_name)
        # qualified_name: "i-UR::urf::UrbanPlanningArea"
        # Returns: Class or nil
      end

      # Find classes by stereotype
      def find_classes_by_stereotype(stereotype)
        # stereotype: "featureType"
        # Returns: Array<Class>
      end

      # Get all classes in package
      def classes_in_package(package_path, recursive: false)
        # package_path: "ModelRoot::i-UR::urf"
        # recursive: false → classes in this package only
        # recursive: true → classes in this package and descendants
        # Returns: Array<Class>
      end

      # ============================================
      # TYPE & INHERITANCE QUERIES
      # ============================================

      # Get supertype of a class
      def supertype_of(class_or_qualified_name)
        # Returns: Class or nil
      end

      # Get all subtypes of a class
      def subtypes_of(class_or_qualified_name, recursive: false)
        # recursive: false → direct children only
        # recursive: true → all descendants
        # Returns: Array<Class>
      end

      # Get inheritance hierarchy (ancestors)
      def ancestors_of(class_or_qualified_name)
        # Returns: Array<Class> from immediate parent to root
      end

      # Get inheritance hierarchy (descendants)
      def descendants_of(class_or_qualified_name, max_depth: nil)
        # Returns: Array<Class> all descendants
      end

      # ============================================
      # ASSOCIATION QUERIES
      # ============================================

      # Get all associations of a class
      def associations_of(class_or_qualified_name, options = {})
        # Options:
        #   owned_only: true      # Only associations where class owns end
        #   navigable_only: true  # Only navigable associations
        #   direction: :source    # :source, :target, :both
        # Returns: Array<Association>
      end

      # Get specific association by name
      def find_association(source_class, association_name)
        # Returns: Association or nil
      end

      # ============================================
      # DIAGRAM QUERIES
      # ============================================

      # Get diagrams in package
      def diagrams_in_package(package_path)
        # Returns: Array<Diagram>
      end

      # Find diagram by name
      def find_diagram(diagram_name)
        # Returns: Diagram or nil
      end

      # Get all diagrams
      def all_diagrams
        # Returns: Array<Diagram>
      end

      # ============================================
      # SEARCH & FILTER
      # ============================================

      # Search for elements by name (fuzzy)
      def search(query, types: [:class, :attribute, :association])
        # query: "urban plan"  (case-insensitive, partial match)
        # types: what to search in
        # Returns: SearchResults with matches grouped by type
      end

      # Find elements by pattern
      def find_by_pattern(pattern, type: :class)
        # pattern: /^Urban.*Area$/
        # type: :class, :attribute, :association, :package
        # Returns: Array of matching elements
      end

      # ============================================
      # STATISTICS & INTROSPECTION
      # ============================================

      # Get repository statistics
      def statistics
        # Returns comprehensive stats hash (see structure above)
      end

      # Get model metadata
      def metadata
        # Returns metadata hash from package
      end

      # Validate repository integrity
      def validate
        # Check for:
        # - Dangling references
        # - Missing types
        # - Circular inheritance
        # - Invalid multiplicities
        # Returns: ValidationResult
      end
    end
  end
end
```

### Domain Models

```ruby
module Lutaml::Xmi::Models
  # Base class for all UML elements
  class UmlElement
    attr_reader :id, :name, :documentation

    def to_h
      # Convert to hash for serialization
    end
  end

  # Package
  class Package < UmlElement
    attr_reader :path, :parent, :packages, :classes, :diagrams

    def qualified_name
      path
    end

    def depth
      path.split('::').size - 1
    end

    def children
      packages
    end
  end

  # Class
  class Class < UmlElement
    attr_reader :qualified_name, :package, :stereotype,
                :attributes, :operations, :generalizations,
                :documentation, :tagged_values

    def superclass
      generalizations.find(&:general)&.general
    end

    def subclasses
      # Reverse lookup from repository
    end

    def feature_type?
      stereotype == 'featureType'
    end

    def abstract?
      tagged_values['isAbstract'] == 'true'
    end
  end

  # Attribute
  class Attribute < UmlElement
    attr_reader :owner_class, :type, :multiplicity,
                :default_value, :is_derived, :is_readonly,
                :documentation

    def required?
      multiplicity.lower > 0
    end

    def collection?
      multiplicity.upper > 1 || multiplicity.upper == '*'
    end
  end

  # Association
  class Association < UmlElement
    attr_reader :source_end, :target_end, :association_class

    def navigable_from_source?
      target_end.navigable
    end

    def owned_by_source?
      source_end.owned
    end
  end

  # AssociationEnd
  class AssociationEnd < UmlElement
    attr_reader :class_ref, :multiplicity, :navigable,
                :owned, :aggregation  # none, shared, composite

    def composite?
      aggregation == 'composite'
    end
  end

  # Generalization (inheritance)
  class Generalization < UmlElement
    attr_reader :specific, :general  # specific → general (child → parent)
  end

  # Diagram
  class Diagram < UmlElement
    attr_reader :type, :package, :elements, :image_path,
                :layout_data

    def class_diagram?
      type == 'Class'
    end
  end
end
```

## CLI Commands

### Package & Structure Commands

```bash
# ============================================
# REPOSITORY MANAGEMENT
# ============================================

# Build LUR package from XMI
lutaml-xmi package build INPUT.xmi \
  --output plateau.lur \
  --name "PLATEAU UML Model" \
  --version "2024.1" \
  --description "Complete PLATEAU urban planning model" \
  --include-xmi \
  --include-diagrams \
  --format marshal \
  --validate

# Show package information
lutaml-xmi package info plateau.lur

# Validate package
lutaml-xmi package validate plateau.lur

# Extract XMI from package
lutaml-xmi package extract plateau.lur --output extracted.xmi

# ============================================
# PACKAGE NAVIGATION
# ============================================

# List root-level packages
lutaml-xmi list --from plateau.lur

# List packages at specific path
lutaml-xmi list "ModelRoot::Conceptual Models" \
  --from plateau.lur

# List packages recursively (tree view)
lutaml-xmi tree --from plateau.lur
lutaml-xmi tree "ModelRoot::i-UR" --from plateau.lur --max-depth 3

# Show package details
lutaml-xmi show package "ModelRoot::i-UR::urf" \
  --from plateau.lur \
  --format yaml

# ============================================
# CLASS INSPECTION
# ============================================

# Show class details (full)
lutaml-xmi show class "i-UR::urf::UrbanPlanningArea" \
  --from plateau.lur \
  --format yaml

# Show class with all attributes and associations
lutaml-xmi show class "i-UR::urf::UrbanPlanningArea" \
  --from plateau.lur \
  --include attributes \
  --include associations \
  --include documentation

# Show only attributes with types
lutaml-xmi show class "i-UR::urf::UrbanPlanningArea" \
  --from plateau.lur \
  --attributes-only \
  --show-types

# Show specific attribute
lutaml-xmi show attribute \
  "i-UR::urf::UrbanPlanningArea::areaClassificationType" \
  --from plateau.lur

# ============================================
# INHERITANCE QUERIES
# ============================================

# Show supertype
lutaml-xmi show supertype "i-UR::urf::UrbanPlanningArea" \
  --from plateau.lur

# Show subtypes (direct children)
lutaml-xmi show subtypes "CityGML::AbstractCityObject" \
  --from plateau.lur

# Show subtypes recursively (full hierarchy)
lutaml-xmi show subtypes "CityGML::AbstractCityObject" \
  --from plateau.lur \
  --recursive \
  --format tree

# Show ancestors (inheritance chain to root)
lutaml-xmi show ancestors "i-UR::urf::UrbanPlanningArea" \
  --from plateau.lur

# Show descendants (all children recursively)
lutaml-xmi show descendants "CityGML::AbstractCityObject" \
  --from plateau.lur \
  --format tree

# ============================================
# ASSOCIATION QUERIES
# ============================================

# Show all associations of a class
lutaml-xmi show associations "i-UR::urf::UrbanPlanningArea" \
  --from plateau.lur

# Show only owned associations
lutaml-xmi show associations "i-UR::urf::UrbanPlanningArea" \
  --from plateau.lur \
  --owned-only

# Show associations with types
lutaml-xmi show associations "i-UR::urf::UrbanPlanningArea" \
  --from plateau.lur \
  --show-types \
  --show-multiplicity

# ============================================
# DIAGRAM QUERIES
# ============================================

# List diagrams in package
lutaml-xmi list diagrams "ModelRoot::i-UR::urf" \
  --from plateau.lur

# Show diagram metadata
lutaml-xmi show diagram "URF Class Diagram" \
  --from plateau.lur

# Export diagram image
lutaml-xmi export diagram "URF Class Diagram" \
  --from plateau.lur \
  --output urf_diagram.svg

# List all diagrams
lutaml-xmi list diagrams --from plateau.lur --all

# ============================================
# SEARCH & FILTER
# ============================================

# Search for classes/attributes/associations
lutaml-xmi search "urban plan" \
  --from plateau.lur

# Search only classes
lutaml-xmi search "building" \
  --from plateau.lur \
  --type class

# Search with regex pattern
lutaml-xmi search --pattern "^Urban.*Area$" \
  --from plateau.lur \
  --type class

# Find by stereotype
lutaml-xmi find --stereotype featureType \
  --from plateau.lur

# Find classes in package (with filter)
lutaml-xmi find --package "i-UR::urf" \
  --stereotype featureType \
  --from plateau.lur

# ============================================
# STATISTICS & REPORTS
# ============================================

# Show repository statistics
lutaml-xmi stats --from plateau.lur

# Show detailed statistics
lutaml-xmi stats --from plateau.lur \
  --format yaml \
  --detailed

# Generate coverage report
lutaml-xmi report coverage \
  --from plateau.lur \
  --output coverage_report.md

# Generate class dependency graph
lutaml-xmi report dependencies \
  --from plateau.lur \
  --output deps.dot \
  --format graphviz

# ============================================
# EXPORT & TRANSFORM
# ============================================

# Export package to JSON
lutaml-xmi export package "ModelRoot::i-UR::urf" \
  --from plateau.lur \
  --output urf.json \
  --format json

# Export class hierarchy to YAML
lutaml-xmi export hierarchy "CityGML::AbstractCityObject" \
  --from plateau.lur \
  --output citygml_hierarchy.yaml \
  --recursive

# Export all classes to CSV
lutaml-xmi export classes \
  --from plateau.lur \
  --output classes.csv \
  --format csv \
  --fields name,stereotype,attributes_count,package
```

### CLI Output Examples

#### Tree View (package tree)

```
$ lutaml-xmi tree --from plateau.lur --max-depth 3

Model Root
├── Conceptual Models
│   ├── CityGML2.0
│   │   ├── appearance
│   │   ├── bridge
│   │   ├── building (45 classes, 12 diagrams)
│   │   ├── cityFurniture
│   │   ├── cityObjectGroup
│   │   ├── core
│   │   ├── generics
│   │   ├── landUse
│   │   ├── relief
│   │   ├── transportation
│   │   ├── tunnel
│   │   ├── vegetation
│   │   └── waterBody
│   └── i-UR
│       ├── Common
│       └── Urban Planning ADE 3.2
│           ├── urf (58 classes, 15 diagrams)
│           └── uro (116 classes, 30 diagrams)
└── ISO 19100 Series
    ├── ISO 19107
    ├── ISO 19108
    └── ISO 19115
```

#### Show Class (full details)

```
$ lutaml-xmi show class "i-UR::urf::UrbanPlanningArea" --from plateau.lur

Class: UrbanPlanningArea
Qualified Name: i-UR::urf::UrbanPlanningArea
Package: ModelRoot::Conceptual Models::i-UR::Urban Planning ADE 3.2::urf
Stereotype: featureType
Abstract: false
Supertype: CityGML::AbstractCityObject

Documentation:
  都市計画区域を表すフィーチャータイプ。
  Urban planning area feature type.

Attributes (12):
  ┌─────────────────────────┬──────────────────┬──────────────┬──────────┐
  │ Name                    │ Type             │ Multiplicity │ Derived  │
  ├─────────────────────────┼──────────────────┼──────────────┼──────────┤
  │ areaClassificationType  │ gml::CodeType    │ 0..1         │ false    │
  │ name                    │ gml::CodeType    │ 0..*         │ false    │
  │ nominalArea             │ Measure          │ 0..1         │ false    │
  │ validFrom               │ Date             │ 0..1         │ false    │
  │ validTo                 │ Date             │ 0..1         │ false    │
  └─────────────────────────┴──────────────────┴──────────────┴──────────┘

Associations (5):
  ┌────────────────┬─────────────────┬──────────────┬───────────┬──────────┐
  │ Name           │ Target Class    │ Multiplicity │ Navigable │ Owned    │
  ├────────────────┼─────────────────┼──────────────┼───────────┼──────────┤
  │ boundary       │ Curve           │ 0..*         │ true      │ true     │
  │ location       │ Point           │ 0..1         │ true      │ true     │
  │ relatedTo      │ CityObject      │ 0..*         │ true      │ false    │
  └────────────────┴─────────────────┴──────────────┴───────────┴──────────┘

Diagrams (2):
  - URF Class Diagram
  - URF Feature Types Overview
```

#### Search Results

```
$ lutaml-xmi search "urban plan" --from plateau.lur

Search Results for "urban plan" (23 matches):

Classes (5):
  ✓ i-UR::urf::UrbanPlanningArea
  ✓ i-UR::urf::UrbanPlanningDecision
  ✓ i-UR::urf::UrbanPlanningProject
  ✓ i-UR::urf::UrbanPlanType
  ✓ i-UR::urf::UrbanPlanningBoundary

Attributes (12):
  ✓ i-UR::urf::UrbanDevelopmentProject::urbanPlanningStatus
  ✓ i-UR::urf::ZoningDistrict::urbanPlanningType
  ...

Associations (6):
  ✓ i-UR::urf::City::urbanPlanningAreas
  ✓ i-UR::urf::Prefecture::urbanPlans
  ...
```

## Ruby API Usage Examples

```ruby
require 'lutaml/xmi'

# ============================================
# BUILD AND LOAD
# ============================================

# Build repository from XMI
repo = Lutaml::Xmi::UmlRepository.from_xmi(
  'sources/xmi/20251010-242.xmi',
  ea_extension: true,
  validate: true,
  include_diagrams: true
)

# Export to LUR package
repo.export_to_package(
  'pkg/plateau.lur',
  name: "PLATEAU UML Model",
  version: "2024.1",
  include_xmi: true,
  include_diagrams: true
)

# Load from LUR package (instant!)
repo = Lutaml::Xmi::UmlRepository.from_package('pkg/plateau.lur')

# ============================================
# PACKAGE NAVIGATION
# ============================================

# Find package
pkg = repo.find_package('ModelRoot::i-UR::urf')
puts "Package: #{pkg.name}"
puts "Classes: #{pkg.classes.size}"

# List packages
packages = repo.list_packages('ModelRoot::i-UR', recursive: true)
packages.each { |p| puts "  - #{p.path}" }

# Get package tree
tree = repo.package_tree('ModelRoot', max_depth: 3)
display_tree(tree)

# ============================================
# CLASS QUERIES
# ============================================

# Find class
cls = repo.find_class('i-UR::urf::UrbanPlanningArea')
puts "Class: #{cls.name}"
puts "Stereotype: #{cls.stereotype}"
puts "Attributes: #{cls.attributes.size}"

# Find by stereotype
feature_types = repo.find_classes_by_stereotype('featureType')
puts "Found #{feature_types.size} feature types"

# Get classes in package
classes = repo.classes_in_package('ModelRoot::i-UR::urf', recursive: false)
classes.each do |cls|
  puts "  #{cls.name} (#{cls.attributes.size} attrs)"
end

# ============================================
# INHERITANCE
# ============================================

# Get supertype
supertype = repo.supertype_of('i-UR::urf::UrbanPlanningArea')
puts "Extends: #{supertype.qualified_name}" if supertype

# Get subtypes
subtypes = repo.subtypes_of('CityGML::AbstractCityObject', recursive: true)
puts "#{subtypes.size} subtypes:"
subtypes.each { |st| puts "  - #{st.qualified_name}" }

# Get ancestors
ancestors = repo.ancestors_of('i-UR::urf::UrbanPlanningArea')
puts "Inheritance chain:"
ancestors.each { |a| puts "  ← #{a.qualified_name}" }

# ============================================
# ASSOCIATIONS
# ============================================

# Get all associations
assocs = repo.associations_of('i-UR::urf::UrbanPlanningArea')
assocs.each do |assoc|
  puts "#{assoc.source_end.name} → #{assoc.target_end.class_ref.name}"
end

# Get owned associations only
owned_assocs = repo.associations_of(
  'i-UR::urf::UrbanPlanningArea',
  owned_only: true
)

# ============================================
# DIAGRAMS
# ============================================

# Get diagrams in package
diagrams = repo.diagrams_in_package('ModelRoot::i-UR::urf')
diagrams.each do |diagram|
  puts "#{diagram.name} (#{diagram.type})"
  puts "  Elements: #{diagram.elements.size}"
end

# ============================================
# SEARCH
# ============================================

# Search for elements
results = repo.search('urban plan', types: [:class, :attribute])
puts "Found:"
puts "  Classes: #{results.classes.size}"
puts "  Attributes: #{results.attributes.size}"

# Pattern search
classes = repo.find_by_pattern(/^Urban.*Area$/, type: :class)
classes.each { |cls| puts "  - #{cls.qualified_name}" }

# ============================================
# STATISTICS
# ============================================

# Get statistics
stats = repo.statistics
puts "Total Packages: #{stats[:total_packages]}"
puts "Total Classes: #{stats[:total_classes]}"
puts "Total Attributes: #{stats[:total_attributes]}"
puts "\nClasses by Stereotype:"
stats[:classes_by_stereotype].each do |stereotype, count|
  puts "  #{stereotype}: #{count}"
end

# Validate
validation = repo.validate
if validation.valid?
  puts "✓ Repository is valid"
else
  puts "✗ Validation errors:"
  validation.errors.each { |err| puts "  - #{err}" }
end
```

## Integration with lutaml-klin

```ruby
# In lutaml-klin
require 'lutaml/xmi'
require 'lutaml/xsd'

# Load UML repository
uml_repo = Lutaml::Xmi::UmlRepository.from_package('pkg/plateau.lur')

# Load XSD repository
xsd_repo = Lutaml::Xsd::SchemaRepository.from_package('pkg/plateau_schemas.lxr')

# Find UML package
uml_pkg = uml_repo.find_package('ModelRoot::i-UR::urf')

# For each class
uml_pkg.classes.each do |uml_class|
  # Resolve to XSD type
  xsd_result = xsd_repo.resolve_type("urf:#{uml_class.name}Type")

  if xsd_result.resolved?
    puts "✓ #{uml_class.name} → #{xsd_result.qname}"

    # Map attributes
    uml_class.attributes.each do |attr|
      # Resolve attribute type
      xsd_type_result = xsd_repo.resolve_type(attr.type)
      # Create mapping...
    end
  else
    puts "✗ #{uml_class.name} (unresolved)"
  end
end
```

## Performance Targets

- **Build LUR package**: < 10 seconds for 20MB XMI file
- **Load LUR package**: < 100ms (vs 5-8 seconds parsing XMI)
- **Package size**: 15-30 MB for PLATEAU model (with diagrams)
- **Search query**: < 50ms for text search
- **Path lookup**: < 1ms for indexed lookups
- **Memory usage**: < 500MB for large models in memory

## Success Criteria

✅ Parse 20MB EA XMI files successfully
✅ Build LUR package in < 10 seconds
✅ Load LUR package in < 100ms
✅ Support UML path-based navigation
✅ Provide rich CLI for model exploration
✅ Index 1700+ classes with full relationships
✅ Search across all model elements
✅ Extract and preserve diagram metadata
✅ Validate model consistency
✅ Enable lutaml-klin to work with LUR packages

## Next Steps

1. Review and approve this specification
2. Implement UmlRepository core (from_xmi, package building)
3. Implement LUR package format (export/import)
4. Implement CLI commands
5. Test with PLATEAU XMI file
6. Integrate with lutaml-klin
7. Document and release

---

**Target**: lutaml gem (lutaml-xmi)
**Priority**: High - Enables symmetric LUR/LXR architecture
**Timeline**: Required for lutaml-klin full UML-XSD mapping
**Related**: LUTAML-XSD-FEATURE-REQUEST.md (LXR packages)