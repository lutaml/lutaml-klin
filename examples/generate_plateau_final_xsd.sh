#!/bin/bash
# Generate final PLATEAU XSD with all ADE hooks (single step)

set -e

echo "======================================================================="
echo "  PLATEAU XSD Generation with ADE Hooks"
echo "======================================================================="
echo ""

echo "Generating URO with PLATEAU custom rule..."
bundle exec exe/lutaml-klin xsd \
  --lur packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_uro_for_plateau.xml \
  --packages "uro" \
  --output final_schemas/

echo ""
echo "Generating URF with PLATEAU custom rule..."
bundle exec exe/lutaml-klin xsd \
  --lur packages/plateau_all.lur \
  --config examples/ShapeChangeConfig_Plateau_urf_for_plateau.xml \
  --packages "urf" \
  --output final_schemas/

echo ""
echo "======================================================================="
echo "  GENERATION COMPLETE"
echo "======================================================================="
echo ""
echo "Final PLATEAU XSD with ADE hooks generated in final_schemas/"
echo ""
echo "✓ URO schema: final_schemas/urbanObject.xsd"
echo "✓ URF schema: final_schemas/urbanFunction.xsd"
echo ""