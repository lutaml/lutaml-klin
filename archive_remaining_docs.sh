#!/bin/bash
# Archive remaining obsolete documentation

echo "Moving superseded status files..."
mv STATUS.md archive/implementation/STATUS-old.md 2>/dev/null
mv PROGRESS.md archive/implementation/ 2>/dev/null

echo "Moving completed reports..."
mv docs/QUALITY_IMPROVEMENT_PLAN.md archive/planning/ 2>/dev/null
mv docs/SHAPECHANGE_PARITY_CERTIFICATION.md archive/analysis/ 2>/dev/null
mv docs/SHAPECHANGE_PARITY_FINAL_REPORT.md archive/analysis/ 2>/dev/null

echo "Archive complete. Remaining active documentation:"
echo ""
echo "=== Root Level (Current) ==="
ls -1 *.md 2>/dev/null | head -10

echo ""
echo "=== docs/ (Active) ==="  
ls -1 docs/*.md 2>/dev/null | wc -l
echo "files remaining in docs/"

echo ""
echo "=== Archived ==="
echo "Planning docs: $(ls -1 archive/planning/*.md 2>/dev/null | wc -l)"
echo "Implementation docs: $(ls -1 archive/implementation/*.md 2>/dev/null | wc -l)"
echo "Analysis docs: $(ls -1 archive/analysis/*.md 2>/dev/null | wc -l)"
