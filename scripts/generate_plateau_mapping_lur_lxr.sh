#!/usr/bin/env bash
# Production Script: Generate PLATEAU UML-XSD Mapping (LUR+LXR Method)
#
# This script uses pre-built LUR and LXR packages for optimal performance.
# Package building is a one-time operation, mapping generation is fast and repeatable.

set -e  # Exit on error

echo "================================================================================"
echo "PLATEAU UML-XSD Mapping Generation (LUR+LXR Method)"
echo "================================================================================"
echo ""

# Configuration
PLATEAU_BASE="/Users/mulgogi/src/mn/mn-samples-plateau"
LUTAML_XMI_DIR="/Users/mulgogi/src/lutaml/lutaml"
LUTAML_XSD_DIR="/Users/mulgogi/src/lutaml/lutaml-xsd"
LUTAML_KLIN_DIR="/Users/mulgogi/src/lutaml/lutaml-klin"

# Input files
XMI_FILE="$PLATEAU_BASE/sources/xmi/20251010-242.xmi"
SHAPECHANGE_CONFIG_URO="$PLATEAU_BASE/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/ShapeChangeConfig_Plateau_uro.xml"
SHAPECHANGE_CONFIG_URF="$PLATEAU_BASE/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/ShapeChangeConfig_Plateau_urf.xml"

# Output directories
PKG_DIR="$LUTAML_KLIN_DIR/packages"
OUTPUT_DIR="$LUTAML_KLIN_DIR/_site"

mkdir -p "$PKG_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Step 1: Build LUR Package from PLATEAU XMI"
echo "--------------------------------------------------------------------------------"
echo "Source: $XMI_FILE"
echo "Output: $PKG_DIR/plateau_all.lur"
echo ""

cd "$LUTAML_XMI_DIR"
bundle exec lutaml xmi package build \
  "$XMI_FILE" \
  --output "$PKG_DIR/plateau_all.lur" \
  --name "PLATEAU Complete Model" \
  --version "2024.1" \
  --description "Complete PLATEAU UML model with CityGML and i-UR packages" \
  --format marshal \
  --validate

echo "✓ LUR package created"
echo ""

echo "Step 2: Build LXR Package from XSD Schemas"
echo "--------------------------------------------------------------------------------"
echo "Schemas: PLATEAU i-UR URO and URF"
echo "Output: $PKG_DIR/plateau_schemas.lxr"
echo ""

# Create temporary config for LXR package
LXR_CONFIG="$PKG_DIR/plateau_schemas_config.yaml"
cat > "$LXR_CONFIG" <<EOF
files:
  - $PLATEAU_BASE/reference-docs/xsd/i-ur/urbanObject.xsd
  - $PLATEAU_BASE/reference-docs/xsd/i-ur/urbanFunction.xsd

schema_location_mappings:
  - from: !ruby/regexp /(?:\.\.\/)+gml\/(.+\.xsd)$/
    to: "$PLATEAU_BASE/schemas/gml/3.2.1/\\1"
  - from: "../../uro/3.2/urbanObject.xsd"
    to: "$PLATEAU_BASE/reference-docs/xsd/i-ur/urbanObject.xsd"

namespace_mappings:
  - prefix: "uro"
    uri: "https://www.geospatial.jp/iur/uro/3.2"
  - prefix: "urf"
    uri: "https://www.geospatial.jp/iur/urf/3.2"
  - prefix: "gml"
    uri: "http://www.opengis.net/gml/3.2"
  - prefix: "xlink"
    uri: "http://www.w3.org/1999/xlink"
EOF

cd "$LUTAML_XSD_DIR"
bundle exec lutaml-xsd package build \
  "$LXR_CONFIG" \
  --output "$PKG_DIR/plateau_schemas.lxr" \
  --name "PLATEAU XSD Schemas" \
  --version "3.2" \
  --description "PLATEAU i-UR schemas with GML dependencies" \
  --xsd-mode include_all \
  --resolution-mode resolved \
  --serialization-format marshal \
  --validate

echo "✓ LXR package created"
echo ""

echo "Step 3: Generate Complete Mapping with lutaml-klin"
echo "--------------------------------------------------------------------------------"
echo "Processing packages: CityGML and i-UR (all classes)"
echo "Output: $OUTPUT_DIR/"
echo ""

cd "$LUTAML_KLIN_DIR"

# Generate mapping for CityGML packages
bundle exec lutaml-klin process \
  --lur "$PKG_DIR/plateau_all.lur" \
  --lxr "$PKG_DIR/plateau_schemas.lxr" \
  --config "$SHAPECHANGE_CONFIG_URO" \
  --packages "::Conceptual Models::CityGML2.0::**" \
  --output "$OUTPUT_DIR" \
  --generate-mappings \
  --generate-spa \
  --spa-data-mode embedded \
  --validate \
  --verbose

echo "✓ CityGML mapping generated"
echo ""

# Generate mapping for i-UR URO package
bundle exec lutaml-klin process \
  --lur "$PKG_DIR/plateau_all.lur" \
  --lxr "$PKG_DIR/plateau_schemas.lxr" \
  --config "$SHAPECHANGE_CONFIG_URO" \
  --packages "::Conceptual Models::i-UR::Urban Planning ADE 3.2::uro" \
  --output "$OUTPUT_DIR" \
  --generate-mappings \
  --generate-spa \
  --spa-data-mode embedded \
  --validate \
  --verbose

echo "✓ i-UR URO mapping generated"
echo ""

# Generate mapping for i-UR URF package
bundle exec lutaml-klin process \
  --lur "$PKG_DIR/plateau_all.lur" \
  --lxr "$PKG_DIR/plateau_schemas.lxr" \
  --config "$SHAPECHANGE_CONFIG_URF" \
  --packages "::Conceptual Models::i-UR::Urban Planning ADE 3.2::urf" \
  --output "$OUTPUT_DIR" \
  --generate-mappings \
  --generate-spa \
  --spa-data-mode embedded \
  --validate \
  --verbose

echo "✓ i-UR URF mapping generated"
echo ""

echo "================================================================================"
echo "PLATEAU Mapping Generation Complete!"
echo "================================================================================"
echo ""
echo "Output Structure:"
echo "  $OUTPUT_DIR/"
echo "  ├── mappings/          # YAML files per package"
echo "  ├── validation/        # JSON and Markdown reports"
echo "  └── spa/               # Interactive website (with embedded data)"
echo ""
echo "Open SPA in browser:"
echo "  file://$OUTPUT_DIR/spa/index.html"
echo ""
echo "Or run:"
echo "  open $OUTPUT_DIR/spa/index.html"
echo ""