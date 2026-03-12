# Feature Request: Fix LUR Package Build Command

**Project**: lutaml
**Priority**: P0 (Critical - Blocks Testing)
**Date**: 2025-12-02
**Status**: Proposal

---

## Problem Statement

The `lutaml` CLI command for building LUR packages from Sparx EA (.qea) files is not working correctly. Multiple syntax attempts fail with different errors.

### Source File
```
/Users/mulgogi/src/lutaml/lutaml/examples/qea/20251010_current_plateau_v5.1.qea
```

### Desired Output
```
spec/fixtures/packages/plateau_all.lur
```

---

## Attempted Commands & Errors

### Attempt 1: Using `xmi package build`
```bash
lutaml xmi package build \
  /path/to/file.qea \
  -o output.lur
```

**Error**:
```
File does not exist: xmi
```

**Analysis**: Commands `xmi` and `package` interpreted as arguments, not subcommands

---

### Attempt 2: Using formatter flag
```bash
lutaml -i sparx_ea -f lur \
  /path/to/file.qea \
  -o output.lur
```

**Error**:
```
undefined method `type=' for "lur":String (NoMethodError)

      @formatter.type = @type
                ^^^^^^^
```

**Analysis**: Formatter string "lur" doesn't respond to `type=` method

---

### Attempt 3: Directory output
```bash
lutaml xmi package build \
  /path/to/file.qea \
  -o output_directory/
```

**Error**:
```
Output path must be a directory if multiple input files are given
```

**Analysis**: Even with directory, still fails

---

## Root Cause Analysis

### Issue 0: Version Mismatch 🚨

**Observation**: README documents `lutaml uml build` but installed version doesn't support it

**Installed Version**: `lutaml (0.9.43)`

**Command in README**:
```bash
lutaml uml build model.qea -o model.lur
```

**Actual Error**:
```
File does not exist: uml
```

**Analysis**: The `uml` subcommand doesn't exist in version 0.9.43. The README is for a newer version.

**Impact**: Users with older lutaml versions cannot build LUR packages.

---

### Issue 1: Formatter/Type Confusion

**File**: `lib/lutaml/command_line.rb:83`

```ruby
@formatter.type = @type
^^^^^^^
```

**Problem**: When `-f lur` is passed, `@formatter` is set to string `"lur"`, not a formatter object.

**Expected**: `@formatter` should be a formatter object with `type=` method

---

### Issue 2: Unclear Command Structure

**Current Help**:
```
Usage: lutaml [options] PATHS

Options:
    -f, --formatter VALUE            The output formatter (Default: 'graphviz')
    -t, --type VALUE                 The output format type
    -o, --output VALUE               The output path
    -i, --input-format VALUE         The input format
```

**Problem**: No clear documentation for:
- How to specify LUR package output
- Difference between formatter and type
- Whether `xmi package build` is a valid subcommand

---

### Issue 3: Missing LUR Package Builder

**Observed**: No clear command path for `sparx_ea → LUR package`

**Needed**: Either:
- Fix existing `-f lur` formatter
- Add `lutaml package build` subcommand
- Document correct command syntax

---

## Proposed Solution

### Option A: Fix Formatter System (Recommended)

**Changes Required**: `lib/lutaml/command_line.rb`

```ruby
def run
  # ... existing code ...
  
  # Fix formatter initialization
  @formatter = case @formatter_name
               when 'lur'
                 Lutaml::Formatters::LurFormatter.new
               when 'graphviz'
                 Lutaml::Formatters::GraphvizFormatter.new
               else
                 raise "Unknown formatter: #{@formatter_name}"
               end
  
  # Set type if formatter supports it
  @formatter.type = @type if @formatter.respond_to?(:type=)
  
  # ... rest of code ...
end
```

**New Class**: `lib/lutaml/formatters/lur_formatter.rb`

```ruby
module Lutaml
  module Formatters
    class LurFormatter
      attr_accessor :type
      
      def format(document, output_path)
        # Build LUR package from UML repository
        repository = extract_repository(document)
        
        # Serialize to LUR format
        File.open(output_path, 'wb') do |f|
          f.write(Marshal.dump(repository))
        end
      end
      
      private
      
      def extract_repository(document)
        # Extract UML repository from parsed document
        # Return Lutaml::Uml::Model::Repository object
      end
    end
  end
end
```

**Usage After Fix**:
```bash
lutaml -i sparx_ea -f lur \
  /path/to/file.qea \
  -o output.lur
```

---

### Option B: Add Package Subcommand

**New Command**: `lutaml package build`

**Implementation**: `lib/lutaml/cli/package_command.rb`

```ruby
module Lutaml
  module Cli
    class PackageCommand < Thor
      desc "build INPUT OUTPUT", "Build LUR package from UML file"
      method_option :input_format, 
        type: :string, 
        default: "sparx_ea",
        enum: ["sparx_ea", "xmi", "rml"],
        desc: "Input format"
      
      def build(input_path, output_path)
        unless File.exist?(input_path)
          raise ArgumentError, "Input file not found: #{input_path}"
        end
        
        puts "Building LUR package..."
        puts "  Input: #{input_path}"
        puts "  Output: #{output_path}"
        puts "  Format: #{options[:input_format]}"
        
        # Parse input file
        document = Lutaml::Parser.parse(
          File.read(input_path),
          flavor: options[:input_format].to_sym
        )
        
        # Build repository
        repository = build_repository(document)
        
        # Write LUR package
        write_lur_package(repository, output_path)
        
        puts "\n✅ LUR package created successfully!"
        puts "   #{output_path}"
      end
      
      private
      
      def build_repository(document)
        # Extract UML repository from document
        # Return Lutaml::Uml::Model::Repository
      end
      
      def write_lur_package(repository, output_path)
        File.open(output_path, 'wb') do |f|
          f.write(Marshal.dump(repository))
        end
      end
    end
  end
end
```

**Usage After Implementation**:
```bash
lutaml package build \
  --input-format sparx_ea \
  /path/to/file.qea \
  output.lur
```

---

### Option C: Document Working Command (Quick Fix)

If a working command exists but is undocumented:

**Update**: `README.md` or `docs/PACKAGE_BUILDING.md`

```markdown
## Building LUR Packages

### From Sparx EA (.qea) Files

To build a LUR package from a Sparx EA file:

`​``bash
lutaml [CORRECT_COMMAND_HERE] \
  input.qea \
  -o output.lur
`​``

### From XMI Files

`​``bash
lutaml [CORRECT_COMMAND_HERE] \
  input.xmi \
  -o output.lur
`​``
```

---

## Current Workaround

Until lutaml is fixed, users must manually load LUR packages that were previously built, or:

### Ruby API Workaround

```ruby
#!/usr/bin/env ruby
require 'lutaml'

input_path = '/path/to/file.qea'
output_path = 'output.lur'

puts "Building LUR package..."

# Parse Sparx EA file
document = Lutaml::Parser.parse(
  File.read(input_path),
  flavor: :sparx_ea
)

# Get repository from document
repository = document.to_uml_model  # or appropriate method

# Serialize to LUR format
File.open(output_path, 'wb') do |f|
  # Use appropriate serialization method
  # May need to access internal repository structure
end

puts "✅ Complete!"
```

---

## Testing Requirements

### Unit Tests

```ruby
RSpec.describe Lutaml::Formatters::LurFormatter do
  describe '#format' do
    it 'builds valid LUR package from Sparx EA'
    it 'builds valid LUR package from XMI'
    it 'raises error for invalid input'
    it 'creates loadable LUR file'
  end
end
```

### Integration Tests

```bash
# Build LUR from test fixture
lutaml -i sparx_ea -f lur \
  spec/fixtures/test_model.qea \
  -o tmp/test.lur

# Verify it loads
ruby -e "
require 'lutaml'
repo = Lutaml::Uml::Model::Repository.load('tmp/test.lur')
puts \"Packages: #{repo.packages.size}\"
puts \"✅ LUR package valid\"
"
```

---

## Documentation Requirements

### README.md

Add section:

```markdown
## Building LUR Packages

LUR (LutaML UML Repository) packages are pre-built, optimized repositories
that load in <100ms vs seconds for XML parsing.

### From Sparx EA Files

`​``bash
lutaml -i sparx_ea -f lur input.qea -o output.lur
`​``

### From XMI Files

`​``bash
lutaml -i xmi -f lur input.xmi -o output.lur
`​``

### Using Ruby API

`​``ruby
document = Lutaml::Parser.parse(File.read('input.qea'), flavor: :sparx_ea)
repository = document.to_uml_model
repository.save_as_lur('output.lur')
`​``
```

### CLI Help Text

Update `lutaml --help` to include:

```
Formatters:
  graphviz     - Generate GraphViz dot files
  lur          - Generate LUR package (binary repository)
  yaml         - Generate YAML representation
  json         - Generate JSON representation

Input Formats:
  sparx_ea     - Sparx Enterprise Architect (.qea)
  xmi          - XMI 2.x files
  rml          - Relaton Modelling Language

Examples:
  # Build LUR package from Sparx EA
  lutaml -i sparx_ea -f lur model.qea -o model.lur

  # Generate diagram from XMI
  lutaml -i xmi -f graphviz model.xmi -o diagram.dot
```

---

## Priority Justification

**P0 (Critical)** because:
1. Blocks all testing of lutaml-klin Process 3 implementation
2. No documented workaround
3. LUR packages are core feature of lutaml ecosystem
4. Prevents PLATEAU workflow from working

---

## Impact Assessment

### Current Impact
- ❌ Cannot build LUR packages from new/updated models
- ❌ Cannot test lutaml-klin features
- ❌ Cannot verify PLATEAU workflows
- ❌ Users blocked on corrupted packages

### After Fix
- ✅ Users can build LUR packages from QEA/XMI
- ✅ Full PLATEAU workflow testable
- ✅ lutaml-klin Process 3 verifiable
- ✅ Self-service package building

---

## Estimated Effort

### Option A (Fix Formatter)
- Design: 2 hours
- Implementation: 8 hours
- Testing: 4 hours
- Documentation: 2 hours
- **Total**: 16 hours (2 days)

### Option B (Add Subcommand)
- Design: 4 hours
- Implementation: 16 hours
- Testing: 6 hours
- Documentation: 4 hours
- **Total**: 30 hours (4 days)

### Option C (Document Existing)
- Research: 2 hours
- Documentation: 2 hours
- **Total**: 4 hours (if command already exists)

---

## Recommended Approach

1. **Immediate** (Option C): Check if working command exists, document it
2. **Short-term** (Option A): Fix formatter system for `-f lur`
3. **Long-term** (Option B): Add proper `package build` subcommand with Thor

---

## Additional Context

### Current lutaml Version
```bash
$ gem list lutaml
lutaml (0.9.43, ...)
```

### Error Location
```
/Users/mulgogi/.rbenv/versions/3.1.1/lib/ruby/gems/3.1.0/gems/lutaml-0.9.43/lib/lutaml/command_line.rb:83
```

### Related Files
- `lib/lutaml/command_line.rb` - CLI entry point
- `lib/lutaml/formatters/` - Formatter classes
- `lib/lutaml/uml/model/repository.rb` - Repository model

---

## Success Criteria

Fix is complete when:

- [ ] Can build LUR from Sparx EA (.qea) files
- [ ] Can build LUR from XMI files
- [ ] Command has clear syntax
- [ ] Help text documents the command
- [ ] Integration tests pass
- [ ] Example in README
- [ ] lutaml-klin can use rebuilt packages

---

## References

- lutaml gem: https://github.com/lutaml/lutaml
- LUR package format: Binary Marshal serialization of `Lutaml::Uml::Model::Repository`
- Sparx EA: .qea files are SQLite databases
- XMI: XML Metadata Interchange format

---

**Submitted By**: lutaml-klin development team
**Blocking**: Process 3 testing and verification
**Urgency**: High - needed for production PLATEAU workflows