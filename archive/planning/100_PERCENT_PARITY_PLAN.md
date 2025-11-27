# Plan for Achieving 100% ShapeChange Parity

## The Problem

**Current Situation**:
- We compare against XSD in `packages/plateau_schemas.lxr`
- These might have been manually edited after ShapeChange generation
- We can't be certain they represent pure ShapeChange output

**Solution**:
Generate fresh reference XSD using ShapeChange itself, use that as gold standard.

## Step-by-Step Plan

### Phase 1: Generate Reference XSD with ShapeChange (1 day)

#### Step 1.1: Locate ShapeChange Installation

```bash
# Check if ShapeChange is available
ls /Users/mulgogi/src/external/ShapeChange/
```

**Expected**: ShapeChange JAR file or build directory

#### Step 1.2: Prepare Input for ShapeChange

**Inputs needed**:
1. XMI file (not LUR!) - ShapeChange reads XMI from Enterprise Architect
2. ShapeChange configuration XML

**Problem**: We have LUR, but ShapeChange needs XMI!

**Solution Options**:

**Option A**: Use existing XMI if available
- Check if `packages/` contains `.xmi` or `.xml` files
- Look in `/Users/mulgogi/src/external/ShapeChange/shapechange-ea/src/main/resources/dataModelPatterns/`

**Option B**: Export XMI from LUR
- LUR is already parsed UML
- Need to export as XMI format ShapeChange can read

#### Step 1.3: Run ShapeChange

```bash
# Assuming ShapeChange JAR is available
java -jar ShapeChange.jar \
  -c reference/shapechange-configs/ShapeChangeConfig_Plateau_urf.xml \
  -x path/to/plateau.xmi
```

**Output**: Fresh XSD files in ShapeChange's output directory

#### Step 1.4: Save as Reference Fixtures

```bash
# Copy ShapeChange output to our fixtures
mkdir -p spec/fixtures/shapechange_reference/
cp shapechange_output/*.xsd spec/fixtures/shapechange_reference/
```

### Phase 2: Byte-for-Byte Comparison (2-3 days)

#### Step 2.1: Create Comprehensive Comparison Spec

**File**: `spec/integration/shapechange_exact_parity_spec.rb`

```ruby
RSpec.describe "ShapeChange Exact Parity" do
  describe "URO package" do
    it "generates XSD byte-for-byte identical to ShapeChange" do
      # Reference: Fresh from ShapeChange
      reference_xsd = File.read('spec/fixtures/shapechange_reference/urbanObject.xsd')

      # Generated: From our implementation
      results = generate_xsd(['uro'])
      generated_xsd = File.read(results.first[:file])

      # Parse both
      ref_doc = Nokogiri::XML(reference_xsd)
      gen_doc = Nokogiri::XML(generated_xsd)

      # Compare structure
      expect_matching_elements(gen_doc, ref_doc)
      expect_matching_types(gen_doc, ref_doc)
      expect_matching_imports(gen_doc, ref_doc)
      expect_matching_namespaces(gen_doc, ref_doc)
    end
  end
end
```

#### Step 2.2: Implement Detailed Comparison Helpers

```ruby
def expect_matching_elements(generated, reference)
  gen_els = extract_elements(generated)
  ref_els = extract_elements(reference)

  # Compare names
  expect(gen_els.map(&:name)).to match_array(ref_els.map(&:name))

  # Compare attributes
  gen_els.each do |gel|
    rel = ref_els.find { |e| e.name == gel.name }
    next unless rel

    expect(gel.type).to eq(rel.type), "Element #{gel.name} type mismatch"
    expect(gel.abstract).to eq(rel.abstract) if rel.abstract
    expect(gel.substitution_group).to eq(rel.substitution_group) if rel.substitution_group
  end
end

def expect_matching_types(generated, reference)
  gen_types = extract_types(generated)
  ref_types = extract_types(reference)

  # Compare counts
  expect(gen_types.size).to eq(ref_types.size),
    "Type count mismatch: generated #{gen_types.size}, reference #{ref_types.size}"

  # Compare each type structure
  gen_types.each do |gtype|
    rtype = ref_types.find { |t| t.name == gtype.name }
    expect(rtype).not_to be_nil, "Type #{gtype.name} not in reference"

    # Compare type content
    expect_matching_type_content(gtype, rtype)
  end
end
```

#### Step 2.3: Run Comparison and Document Discrepancies

```bash
bundle exec rspec spec/integration/shapechange_exact_parity_spec.rb -fd > parity_report.txt
```

**Analyze** `parity_report.txt`:
- List all differences
- Categorize: missing elements, wrong types, structural differences
- Prioritize fixes

### Phase 3: Iterate to 100% Match (1-2 weeks)

#### Step 3.1: Fix Element Discrepancies

For each missing/wrong element:
1. Find in ShapeChange XsdDocument.java
2. Understand the rule that generates it
3. Update our processor
4. Test
5. Commit

#### Step 3.2: Fix Type Discrepancies

For each type difference:
1. Compare type structure in detail
2. Identify missing logic (base types, sequences, properties)
3. Implement fix
4. Test
5. Commit

#### Step 3.3: Fix Formatting/Ordering

ShapeChange might:
- Order elements differently
- Format XML differently
- Use different whitespace

**Solution**: Normalize before comparison or update our formatting

### Phase 4: Validation and Documentation (1 day)

#### Step 4.1: Final Validation

```bash
# Generate with our tool
lutaml-klin xsd --lur model.lur --config config.xml --packages "uro" --output our_output/

# Generate with ShapeChange
java -jar ShapeChange.jar -c config.xml -x model.xmi

# Compare
diff our_output/urbanObject.xsd shapechange_output/urbanObject.xsd
```

**Goal**: No differences (or only trivial formatting)

#### Step 4.2: Document Results

**File**: `docs/SHAPECHANGE_PARITY_ACHIEVED.md`

- Comparison methodology
- Test results
- Known acceptable differences (if any)
- Certification that output is identical

## Critical Dependencies

### Dependency 1: XMI Input

**ShapeChange requires**: `.xmi` or `.xml` (Enterprise Architect export)
**We have**: `.lur` (lutaml parsed format)

**Solutions**:

**A. Find Existing XMI**:
```bash
# Search for XMI in packages
find packages/ -name "*.xmi" -o -name "*.xml" | grep -i plateau
```

**B. Export LUR to XMI**:
- Implement XMI export in lutaml/lutaml-xmi
- Generate XMI from LUR
- Use that XMI for ShapeChange

**C. Use Sample XMI**:
```bash
# ShapeChange provides samples
/Users/mulgogi/src/external/ShapeChange/shapechange-ea/src/main/resources/dataModelPatterns/*.xml
```

### Dependency 2: ShapeChange Execution

**Need**:
- Java Runtime (JRE)
- ShapeChange JAR or build
- Correct configuration

**Verify**:
```bash
# Check ShapeChange is buildable
cd /Users/mulgogi/src/external/ShapeChange
mvn clean package
```

## Timeline

**Phase 1**: Generate reference (1 day)
- Find or create XMI input
- Run ShapeChange
- Save fixtures

**Phase 2**: Comparison framework (2 days)
- Detailed comparison spec
- Helper methods
- Initial analysis

**Phase 3**: Iterative fixes (1-2 weeks)
- Fix discrepancies one by one
- Test each fix
- Document patterns

**Phase 4**: Validation (1 day)
- Final comparison
- Documentation
- Certification

**Total**: 2-3 weeks to guaranteed 100% parity

## Success Criteria

✅ Fresh reference XSD generated by ShapeChange from same inputs
✅ Our XSD generation uses same inputs (XMI + Config)
✅ Comprehensive comparison spec
✅ All element names match
✅ All type structures match
✅ All namespaces match
✅ Byte-for-byte identical (or only trivial formatting differences)
✅ Documentation proves 100% parity

This ensures we have TRUE ShapeChange parity, not just "looks similar"!