#!/usr/bin/env bash
# Production Script: Generate PLATEAU UML-XSD Mapping (Direct XMI/XSD Method)
#
# This script uses direct XMI and XSD file parsing without pre-built packages.
# Slower but doesn't require LUR/LXR package building step.

set -e  # Exit on error

echo "================================================================================"
echo "PLATEAU UML-XSD Mapping Generation (Direct XMI/XSD Method)"
echo "================================================================================"
echo ""

# Configuration
PLATEAU_BASE="/Users/mulgogi/src/mn/mn-samples-plateau"
LUTAML_KLIN_DIR="/Users/mulgogi/src/lutaml/lutaml-klin"

# Input files
XMI_FILE="$PLATEAU_BASE/sources/xmi/20251010-242.xmi"
XSD_DIR_URO="$PLATEAU_BASE/reference-docs/xsd/i-ur"
XSD_DIR_URF="$PLATEAU_BASE/reference-docs/xsd/i-ur"
SHAPECHANGE_CONFIG_URO="$PLATEAU_BASE/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/ShapeChangeConfig_Plateau_uro.xml"
SHAPECHANGE_CONFIG_URF="$PLATEAU_BASE/PLATEAU-Manual-Generator/src/ShapeChange-3.1.0/ShapeChangeConfig_Plateau_urf.xml"

# Output directory
OUTPUT_DIR="$LUTAML_KLIN_DIR/_site"

mkdir -p "$OUTPUT_DIR/mappings"

echo "Input Files:"
echo "  XMI: $XMI_FILE"
echo "  Config URO: $SHAPECHANGE_CONFIG_URO"
echo "  Config URF: $SHAPECHANGE_CONFIG_URF"
echo "  XSD Dir: $XSD_DIR_URO"
echo ""
echo "Output: $OUTPUT_DIR/"
echo ""

cd "$LUTAML_KLIN_DIR"

echo "================================================================================"
echo "Step 1: Generate i-UR URO Package Mapping"
echo "================================================================================"
echo ""

bundle exec exe/lutaml-klin generate \
  "$SHAPECHANGE_CONFIG_URO" \
  "$XMI_FILE" \
  "$XSD_DIR_URO" \
  "$OUTPUT_DIR/mappings/uro_mapping.yaml" \
  --package "uro" \
  --verbose

echo ""
echo "✓ URO mapping generated: $OUTPUT_DIR/mappings/uro_mapping.yaml"
echo ""

echo "================================================================================"
echo "Step 2: Generate i-UR URF Package Mapping"
echo "================================================================================"
echo ""

bundle exec exe/lutaml-klin generate \
  "$SHAPECHANGE_CONFIG_URF" \
  "$XMI_FILE" \
  "$XSD_DIR_URF" \
  "$OUTPUT_DIR/mappings/urf_mapping.yaml" \
  --package "urf" \
  --verbose

echo ""
echo "✓ URF mapping generated: $OUTPUT_DIR/mappings/urf_mapping.yaml"
echo ""

echo "================================================================================"
echo "Step 3: Generate CityGML Package Mappings"
echo "================================================================================"
echo ""
echo "Note: CityGML mappings require CityGML-specific ShapeChange config"
echo "      Skipping for now - add config files as needed"
echo ""

# Uncomment when CityGML configs are available:
# for pkg in bldg tran veg wtr; do
#   echo "Generating CityGML::$pkg mapping..."
#   bundle exec exe/lutaml-klin generate \
#     "$PLATEAU_BASE/configs/ShapeChangeConfig_CityGML_$pkg.xml" \
#     "$XMI_FILE" \
#     "$PLATEAU_BASE/schemas/citygml/$pkg" \
#     "$OUTPUT_DIR/mappings/citygml_${pkg}_mapping.yaml" \
#     --package "$pkg"
# done

echo "================================================================================"
echo "Step 4: Generate SPA Website from Mappings"
echo "================================================================================"
echo ""

# Note: This step would use the new SPA generator to create interactive website
# from the generated YAML mappings. Since generate command creates legacy format,
# we would need to:
# 1. Load the YAML mappings
# 2. Convert to enhanced format with resolution tracking
# 3. Generate SPA with embedded data

echo "SPA generation requires enhanced mapping format."
echo "Use the process command (LUR+LXR method) for automatic SPA generation."
echo ""

echo "================================================================================"
echo "PLATEAU Mapping Generation Complete!"
echo "================================================================================"
echo ""
echo "Generated Files:"
ls -lh "$OUTPUT_DIR/mappings/"
echo ""
echo "Next Steps:"
echo "  1. Review generated YAML mappings"
echo "  2. For interactive SPA, use LUR+LXR method (Option A script)"
echo "  3. Mappings are in: $OUTPUT_DIR/mappings/"
echo ""