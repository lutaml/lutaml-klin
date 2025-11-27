#!/bin/bash
# Archive completed and obsolete documentation

# Planning documents (completed)
mv docs/LUTAML_KLIN_IMPLEMENTATION_PLAN.md archive/planning/
mv docs/FULL_MAPPING_CREATION_PLAN.md archive/planning/
mv docs/FULL_MAPPING_IMPLEMENTATION_ROADMAP.md archive/planning/
mv docs/XSD_GENERATION_IMPLEMENTATION_PLAN.md archive/planning/
mv docs/COMPLETE_RULE_IMPLEMENTATION_PLAN.md archive/planning/
mv docs/SYSTEMATIC_RULE_IMPLEMENTATION_PLAN.md archive/planning/
mv docs/FINAL_IMPLEMENTATION_PLAN.md archive/planning/
mv docs/FINAL_COMPREHENSIVE_ACTION_PLAN.md archive/planning/
mv docs/SHAPECHANGE_REPLICATION_PLAN.md archive/planning/
mv docs/SHAPECHANGE_INTEGRATION_FIX_PLAN.md archive/planning/
mv docs/100_PERCENT_PARITY_PLAN.md archive/planning/
mv docs/DUAL_PUBLICATION_STRATEGY.md archive/planning/
mv docs/SHAPECHANGE_100PERCENT_COMPATIBILITY_PLAN.md archive/planning/
mv docs/PLATEAU_CUSTOM_RULE_STRATEGY.md archive/planning/
mv docs/PHASE_3_3_VALIDATION_PLAN.md archive/planning/
mv docs/SCHEMA_REPOSITORY_INTEGRATION_PLAN.md archive/planning/

# Implementation summaries (completed phases)
mv PHASE-1.1-IMPLEMENTATION-SUMMARY.md archive/implementation/
mv PHASE-1.2-IMPLEMENTATION-SUMMARY.md archive/implementation/
mv PHASE-1.3-IMPLEMENTATION-SUMMARY.md archive/implementation/
mv PHASE-2-IMPLEMENTATION-SUMMARY.md archive/implementation/
mv PHASE_1B_COMPLETION_REPORT.md archive/implementation/
mv PHASE_1C_INTEGRATION_VERIFICATION.md archive/implementation/
mv docs/BATCH_6_IMPLEMENTATION_SUMMARY.md archive/implementation/
mv docs/BATCH_7_IMPLEMENTATION_SUMMARY.md archive/implementation/
mv docs/BATCH_8_IMPLEMENTATION_SUMMARY.md archive/implementation/
mv docs/BATCH_9_IMPLEMENTATION_SUMMARY.md archive/implementation/
mv docs/BATCH_10_IMPLEMENTATION_SUMMARY.md archive/implementation/
mv docs/BATCH_11_IMPLEMENTATION_SUMMARY.md archive/implementation/
mv docs/BATCH_12_FINAL_IMPLEMENTATION_SUMMARY.md archive/implementation/
mv docs/SPA-PHASE-1-IMPLEMENTATION-SUMMARY.md archive/implementation/
mv docs/SPA-PHASE-2-IMPLEMENTATION-SUMMARY.md archive/implementation/
mv docs/SPA-PHASE-3-IMPLEMENTATION-SUMMARY.md archive/implementation/
mv SHAPECHANGE_INTEGRATION_FIX_SUMMARY.md archive/implementation/

# Analysis documents (completed)
mv docs/ZERO_STATISTICS_ROOT_CAUSE_ANALYSIS.md archive/analysis/
mv docs/RESOLUTION_QUALITY_ANALYSIS.md archive/analysis/
mv docs/URF_XSD_COMPARISON_ANALYSIS.md archive/analysis/
mv docs/TRANSFORMATION_ALGORITHM_UNDERSTANDING.md archive/analysis/
mv docs/PROPERTY-SERIALIZATION-ROOT-CAUSE.md archive/analysis/
mv docs/VBA_MODIFICATIONS_ANALYSIS.md archive/analysis/
mv docs/PLATEAU_MANUAL_GENERATOR_ANALYSIS.md archive/analysis/
mv docs/SHAPECHANGE-COMPATIBILITY-DIAGNOSIS.md archive/analysis/
mv docs/SHAPECHANGE-COMPATIBILITY-VALIDATION.md archive/analysis/
mv docs/SHAPECHANGE-VALIDATION-SUMMARY.md archive/analysis/
mv docs/SHAPECHANGE_PARITY_FINDINGS.md archive/analysis/
mv docs/SHAPECHANGE_PARITY_SETUP.md archive/analysis/
mv docs/SHAPECHANGE_PARITY_STRATEGY.md archive/analysis/
mv docs/SHAPECHANGE_COMPATIBILITY_STATUS.md archive/analysis/
mv docs/PARITY_SETUP_SUMMARY.md archive/analysis/
mv docs/100_PERCENT_PARITY_ASSESSMENT.md archive/analysis/

echo "Documentation archived successfully"
ls -la archive/*/
