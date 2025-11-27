#!/bin/bash
# Generate fresh ShapeChange reference XSD for 100% parity validation
#
# This script runs ShapeChange with the official PLATEAU EA model
# to generate pure, unmodified XSD as our gold standard reference.

set -e

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SHAPECHANGE_JAR="/Users/mulgogi/src/mn/mn-samples-plateau/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/ShapeChange-3.1.0.jar"
CONFIG_FILE="$PROJECT_DIR/reference/shapechange-configs/ShapeChangeConfig_Reference.xml"
OUTPUT_DIR="$PROJECT_DIR/reference/output"
FIXTURES_DIR="$PROJECT_DIR/spec/fixtures/shapechange_reference"

echo "========================================="
echo "Generating ShapeChange Reference XSD"
echo "========================================="
echo ""
echo "Configuration: $CONFIG_FILE"
echo "Output: $OUTPUT_DIR"
echo ""

# Clean output directory
if [ -d "$OUTPUT_DIR" ]; then
  echo "Cleaning output directory..."
  rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

# Run ShapeChange
echo "Running ShapeChange..."
echo "Command: java -jar $SHAPECHANGE_JAR -c $CONFIG_FILE"
echo ""

cd "$PROJECT_DIR"
java -jar "$SHAPECHANGE_JAR" -c "$CONFIG_FILE"

echo ""
echo "ShapeChange completed!"
echo ""

# List generated files
echo "Generated files:"
find "$OUTPUT_DIR" -name "*.xsd" -exec basename {} \;
echo ""

# Copy to test fixtures
echo "Copying to test fixtures..."
mkdir -p "$FIXTURES_DIR"
cp -v "$OUTPUT_DIR"/*.xsd "$FIXTURES_DIR/" 2>/dev/null || true

# Create README
cat > "$FIXTURES_DIR/README.md" << 'EOF'
# ShapeChange Reference XSD

## Purpose

These XSD files are the **gold standard** for 100% parity validation.
They were generated directly by ShapeChange from the official PLATEAU EA model,
with no manual modifications.

## Generation

- **Tool**: ShapeChange 3.1.0
- **Input**: 202503_current_plateau_v5.0.qea (PLATEAU v5.0 EA model)
- **Config**: ShapeChangeConfig_Reference.xml
- **Package**: uro (urbanObject)
- **Date**: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Regeneration

To regenerate these reference files:

```bash
./scripts/generate_shapechange_reference.sh
```

## Usage in Tests

These files are used in `spec/integration/shapechange_100_percent_parity_spec.rb`
for byte-level comparison against lutaml-klin generated XSD.

## Validation

Our goal is 100% match with these files. Any discrepancy indicates a bug
or missing feature in lutaml-klin that must be fixed.
EOF

echo "Reference XSD saved to: $FIXTURES_DIR"
echo ""
echo "========================================="
echo "Reference Generation Complete!"
echo "========================================="