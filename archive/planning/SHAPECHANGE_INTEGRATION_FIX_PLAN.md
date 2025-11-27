# ShapeChange Integration Fix Plan

## Root Cause Analysis

### ❌ Current Problem

**Symptom**: 0% resolution rate - all attributes show `✗ none`

**Root Cause**: `ProcessingWorkflow.load_shapechange_config()` creates a **stub config object** instead of using the real `ConfigParser`:

```ruby
# Current STUB implementation (lines 250-266 in processing_workflow.rb)
def load_shapechange_config(config_path)
  Object.new.tap do |config|
    def config.namespace_for_package(package_path)
      "http://example.org/#{parts.last.downcase}"  # FAKE!
    end
  end
end
```

This stub has:
- ❌ No XsdMapEntry data (type mappings)
- ❌ No EncodingRule data
- ❌ No real namespace mappings
- ❌ No package info

**Result**: Resolution strategies can't find any mappings!

### ✅ What Actually Works

The `ConfigParser` DOES parse the XML correctly and extracts:
1. ✅ `xml_namespaces` - namespace prefix→URI mappings
2. ✅ `xsd_map_entries` - UML type→XSD type mappings
3. ✅ `package_infos` - package→namespace mappings

**But** this parsed data is thrown away because `ProcessingWorkflow` uses the stub!

## ShapeChange Config Structure

### Key Elements from PLATEAU Config

```xml
<ShapeChangeConfiguration>
  <input>
    <!-- Package mappings: UML package → XSD namespace -->
    <packages>
      <PackageInfo packageName="urf"
                   ns="https://www.geospatial.jp/iur/urf/3.2"
                   nsabr="urf"
                   xsdDocument="urbanFunction.xsd"/>
      <PackageInfo packageName="uro"
                   ns="https://www.geospatial.jp/iur/uro/3.2"
                   nsabr="uro"/>
    </packages>

    <!-- Type mappings: UML type → XSD type -->
    <xsdMapEntries>
      <XsdMapEntry type="xs::anyURI"
                   xsdEncodingRules="citygml"
                   xmlPropertyType="xs:anyURI"
                   xmlType="xs:anyURI"/>
      <XsdMapEntry type="gml::CodeType"
                   xsdEncodingRules="citygml"
                   xmlPropertyType="gml:CodeType"
                   xmlType="gml:CodeType"/>
      <XsdMapEntry type="CharacterString"
                   xsdEncodingRules="iso19136_2007"
                   xmlPropertyType="string"
                   xmlType="string"/>
    </xsdMapEntries>

    <!-- Namespace mappings: prefix → URI → schemaLocation -->
    <xmlNamespaces>
      <XmlNamespace nsabr="gml"
                    ns="http://www.opengis.net/gml"
                    location="http://schemas.opengis.net/gml/3.1.1/base/gml.xsd"/>
      <XmlNamespace nsabr="uro"
                    ns="https://www.geospatial.jp/iur/uro/3.2"
                    location="https://www.geospatial.jp/iur/schemas/uro/3.2/urbanObject.xsd"/>
    </xmlNamespaces>
  </input>

  <targets>
    <TargetXmlSchema>
      <!-- Encoding rules -->
      <rules>
        <EncodingRule name="citygml" extends="iso19136_2007">
          <rule name="rule-xsd-rel-association-classes"/>
          <rule name="rule-xsd-cls-basictype"/>
        </EncodingRule>
      </rules>
    </TargetXmlSchema>
  </targets>
</ShapeChangeConfiguration>
```

## Fix Strategy

### Step 1: Use Real ConfigParser ✅

**Replace stub with real parser**:

```ruby
# In ProcessingWorkflow
def load_shapechange_config(config_path)
  # Use the REAL parser, not a stub!
  parser = Shapechange::ConfigParser.new
  config = parser.parse_file(config_path)

  # Return the parsed ShapeChangeConfiguration object
  config
end
```

### Step 2: Extract Encoding Rules from Config

**Current parser doesn't extract encoding rules yet!** Need to add:

```ruby
# In ConfigParser
def extract_encoding_rules(doc)
  rules = []
  doc.xpath("//rules/EncodingRule").each do |node|
    rule_names = node.xpath("rule").map { |r| r["name"] }

    rules << EncodingRule.new(
      name: node["name"],
      extends: node["extends"],
      rules: rule_names
    )
  end
  rules
end
```

### Step 3: Update ShapeChangeConfiguration Model

**Add methods needed by resolution strategies**:

```ruby
class ShapeChangeConfiguration
  attribute :xml_namespaces, XmlNamespace, collection: true
  attribute :xsd_map_entries, XsdMapEntry, collection: true
  attribute :package_infos, PackageInfo, collection: true
  attribute :encoding_rules, EncodingRule, collection: true  # NEW!

  # Find namespace for a UML package
  def namespace_for_package(package_path)
    # Match by packageName (simple or with trimmed spaces)
    pkg_info = package_infos.find do |pi|
      pi.package_name&.strip == package_path ||
      pi.package_name&.strip == package_path.split('::').last
    end

    pkg_info&.ns&.strip
  end

  # Find prefix for a namespace
  def prefix_for_namespace(namespace_uri)
    namespace_uri = namespace_uri.strip

    # Try xml_namespaces first
    xml_ns = xml_namespaces.find { |ns| ns.ns&.strip == namespace_uri }
    return xml_ns.nsabr&.strip if xml_ns

    # Try package_infos
    pkg_info = package_infos.find { |pi| pi.ns&.strip == namespace_uri }
    pkg_info&.nsabr&.strip
  end

  # Find XsdMapEntry for a UML type
  def find_type_mapping(uml_type, encoding_rule: "citygml")
    xsd_map_entries.find do |entry|
      entry.type&.strip == uml_type &&
      entry.xsd_encoding_rules&.include?(encoding_rule)
    end
  end
end
```

### Step 4: Create EncodingRule Model

```ruby
# lib/lutaml/klin/shapechange/models/config/encoding_rule.rb
class EncodingRule < Lutaml::Model::Serializable
  attribute :name, :string
  attribute :extends, :string
  attribute :rules, :string, collection: true

  # Check if this encoding rule includes a specific rule
  # (considering inheritance)
  def has_rule?(rule_name, all_encoding_rules = [])
    # Direct match
    return true if rules.include?(rule_name)

    # Check parent encoding rule
    if extends
      parent = all_encoding_rules.find { |er| er.name == extends }
      return parent.has_rule?(rule_name, all_encoding_rules) if parent
    end

    false
  end
end
```

### Step 5: Update XsdMapEntry Model

**Add missing attributes**:

```ruby
class XsdMapEntry < Lutaml::Model::Serializable
  attribute :type, :string              # UML type name
  attribute :xsd_encoding_rules, :string # Space-separated rule names
  attribute :xml_type, :string          # XSD type name
  attribute :xml_property_type, :string # XSD property type name
  attribute :xml_element, :string       # XSD element name
  attribute :xml_type_type, :string     # "simple" or "complex"
  attribute :xml_type_content, :string  # "simple" or "complex"

  # Check if this mapping applies to an encoding rule
  def applies_to?(encoding_rule_name)
    return true unless xsd_encoding_rules

    rule_names = xsd_encoding_rules.split
    rule_names.include?(encoding_rule_name)
  end
end
```

## Expected Resolution Flow After Fix

```
1. UML Attribute: name, type=CharacterString
   ↓
2. ConfigParser extracts from ShapeChange XML:
   - XsdMapEntry: type="CharacterString" → xmlType="string"
   - PackageInfo: packageName="uro" → ns="https://..."
   - XmlNamespace: nsabr="uro" → ns="https://..."
   ↓
3. ResolutionContext uses parsed config:
   - type_mappings = config.xsd_map_entries (real data!)
   - namespace_map = config.xml_namespaces (real data!)
   ↓
4. ShapeChangeStrategy:
   - Looks up "CharacterString" in config.xsd_map_entries
   - Finds: xmlType="string"
   - Returns: xsd_type="string"
   ↓
5. LXR Validation:
   - Validates "string" type exists
   - Adds documentation
   ↓
6. Output:
   ✓ RESOLVED via shapechange_rule (100%)
   xsd_type: string
```

## Implementation Plan

### Task 1: Fix ProcessingWorkflow (HIGH PRIORITY)

**File**: `lib/lutaml/klin/application/processing_workflow.rb`

**Change**: Replace stub with real parser

```ruby
def load_shapechange_config(config_path)
  # Use real parser!
  parser = Shapechange::ConfigParser.new
  config = parser.parse_file(config_path)

  config
rescue StandardError => e
  raise "Failed to load ShapeChange configuration: #{e.message}"
end
```

### Task 2: Enhance ConfigParser

**File**: `lib/lutaml/klin/shapechange/config_parser.rb`

**Add**: Extract encoding rules from XML

```ruby
def parse_content(xml_content)
  doc = Nokogiri::XML(xml_content)
  doc.remove_namespaces!

  config = ShapeChangeConfiguration.new
  config.xml_namespaces = extract_xml_namespaces(doc)
  config.xsd_map_entries = extract_xsd_map_entries(doc)
  config.package_infos = extract_package_infos(doc)
  config.encoding_rules = extract_encoding_rules(doc)  # NEW!

  config
end

def extract_encoding_rules(doc)
  rules = []
  doc.xpath("//rules/EncodingRule").each do |node|
    rule_names = node.xpath("rule").map { |r| r["name"] }

    rules << EncodingRule.new(
      name: node["name"],
      extends: node["extends"],
      rules: rule_names
    )
  end
  rules
end
```

### Task 3: Update ShapeChangeConfiguration Model

**File**: `lib/lutaml/klin/shapechange/models/config/shape_change_configuration.rb`

**Add**: Methods for resolution strategies

```ruby
class ShapeChangeConfiguration < Lutaml::Model::Serializable
  attribute :xml_namespaces, XmlNamespace, collection: true
  attribute :xsd_map_entries, XsdMapEntry, collection: true
  attribute :package_infos, PackageInfo, collection: true
  attribute :encoding_rules, EncodingRule, collection: true

  def namespace_for_package(package_path)
    simple_name = package_path.split('::').last

    pkg_info = package_infos.find do |pi|
      pi.package_name&.strip == simple_name ||
      pi.package_name&.strip == package_path
    end

    pkg_info&.ns&.strip
  end

  def prefix_for_namespace(namespace_uri)
    namespace_uri = namespace_uri&.strip

    xml_ns = xml_namespaces.find { |ns| ns.ns&.strip == namespace_uri }
    return xml_ns.nsabr&.strip if xml_ns

    pkg_info = package_infos.find { |pi| pi.ns&.strip == namespace_uri }
    pkg_info&.nsabr&.strip
  end

  def find_type_mapping(uml_type, encoding_rule: "citygml")
    xsd_map_entries.find do |entry|
      entry.type&.strip == uml_type &&
      entry.applies_to?(encoding_rule)
    end
  end
end
```

### Task 4: Create EncodingRule Model

**File**: `lib/lutaml/klin/shapechange/models/config/encoding_rule.rb` (NEW!)

```ruby
# frozen_string_literal: true

require "lutaml/model"

module Lutaml
  module Klin
    module Shapechange
      class EncodingRule < Lutaml::Model::Serializable
        attribute :name, :string
        attribute :extends, :string
        attribute :rules, :string, collection: true

        def has_rule?(rule_name, all_rules = [])
          return true if rules.include?(rule_name)

          if extends
            parent = all_rules.find { |er| er.name == extends }
            return parent.has_rule?(rule_name, all_rules) if parent
          end

          false
        end
      end
    end
  end
end
```

### Task 5: Update XsdMapEntry Model

**File**: `lib/lutaml/klin/shapechange/models/config/xsd_map_entry.rb`

**Add**: Missing attributes and helper methods

```ruby
class XsdMapEntry < Lutaml::Model::Serializable
  attribute :type, :string
  attribute :xsd_encoding_rules, :string
  attribute :xml_type, :string
  attribute :xml_property_type, :string
  attribute :xml_element, :string
  attribute :xml_type_type, :string
  attribute :xml_type_content, :string

  def applies_to?(encoding_rule_name)
    return true unless xsd_encoding_rules

    xsd_encoding_rules.split.include?(encoding_rule_name)
  end
end
```

## Expected Results After Fix

### Resolution Output (Verbose)

```
[5/255] Class: BridgeFunctionalAttribute (DataType)

  [1/2] Attribute: directionType
    UML type: gml::CodeType

    ShapeChange lookup:
      ✓ Found XsdMapEntry: gml::CodeType → gml:CodeType
      Encoding rule: citygml
      xmlPropertyType: gml:CodeType

    LXR validation:
      ✓ Type found: gml:CodeType
      Namespace: http://www.opengis.net/gml/3.2
      Schema: basicTypes.xsd

    ✅ RESOLVED (shapechange_rule, 100%)

  [2/2] Attribute: userType
    UML type: gml::CodeType
    ✓ XsdMapEntry → gml:CodeType
    ✓ LXR validated
    ✅ RESOLVED (shapechange_rule, 100%)
```

### Resolution Statistics

```
Package: uro
  Classes: 255
  Attributes: 1,141

  Resolution:
    ✅ Resolved: 1,095+ (>95%)
    ✅ LXR validated: 1,095 (100% of resolved)
    ❌ Unresolved: <50 (<5%)

  By method:
    ✓ shapechange_rule: 1,050+ (92%) ← Primary!
    ✓ lxr_direct: 40 (3%)
    ✓ namespace_lookup: 5 (0.4%)
    ✗ unresolved: <50 (4%)
```

## Test Command After Fix

```bash
bundle exec exe/lutaml-klin process \
  --lur packages/plateau_all.lur \
  --lxr packages/plateau_schemas.lxr \
  --config ./reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml \
  --packages "uro" \
  --output _site \
  --verbose

# Expected:
# ✅ Config loaded with real XsdMapEntry data
# ✅ >95% resolution rate
# ✅ Detailed verbose output showing ShapeChange mappings
# ✅ Processing in <5 seconds
```

## Implementation Priority

### P0 - Critical (Blocking All Resolution)

1. ✅ Replace stub in `ProcessingWorkflow.load_shapechange_config()`
2. ✅ Add `namespace_for_package()` method to `ShapeChangeConfiguration`
3. ✅ Add `prefix_for_namespace()` method to `ShapeChangeConfiguration`
4. ✅ Add `find_type_mapping()` method to `ShapeChangeConfiguration`

### P1 - High (Needed for Full Functionality)

5. ✅ Extract encoding rules in `ConfigParser`
6. ✅ Create `EncodingRule` model
7. ✅ Update `XsdMapEntry` model with missing attributes
8. ✅ Add `applies_to?()` method to `XsdMapEntry`

### P2 - Medium (Enhancement)

9. ⏳ Add encoding rule inheritance resolution
10. ⏳ Implement rule registry for complex rule lookups
11. ⏳ Add validation of encoding rule references

## Summary

**Current State**:
- ✅ ConfigParser works correctly
- ✅ Package filtering works
- ✅ Verbose logging works
- ❌ **Resolution at 0% because stub config has no data**

**Fix**:
1. Use real ConfigParser (1 line change!)
2. Add helper methods to ShapeChangeConfiguration (3 methods)
3. Extract encoding rules (1 method)
4. Create EncodingRule model (1 new file)

**Expected Result**:
- ✅ >95% resolution rate
- ✅ ShapeChange type mappings working
- ✅ LXR validation enriching mappings
- ✅ Production-ready system

**The fix is straightforward - just stop using the stub and wire up the real config data!** 🚀