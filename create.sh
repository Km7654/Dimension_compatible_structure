#!/usr/bin/env bash

set -euo pipefail

FUNCTION="ATXX"
SUB_FUNCTION="ATXX_DIAG"
MODULE="ATXX_DIAG_CTL"

VERSION="v1.0.0"
DELIVERY_CYCLE="MD31_01"

CODE_DIR="HEMS/CODE_HEMS/$FUNCTION/$SUB_FUNCTION/$MODULE"
MOD_DIR="HEMS/MOD_HEMS/$FUNCTION/$SUB_FUNCTION/$MODULE"
SPEC_DIR="HEMS/SPEC_HEMS/$FUNCTION/$SUB_FUNCTION/$MODULE"

echo "Fixing manifests and traceability files..."

############################################
# CODE_HEMS
############################################

cat > "$CODE_DIR/trace_links.csv" << EOF
source,target,link_type
${MODULE}.c,${MODULE}.h,includes
${MODULE}.c,${MODULE}_static_analysis_report.txt,validated_by
${MODULE}.c,${MODULE}_sil_results.txt,tested_by
EOF

cat > "$CODE_DIR/code-manifest.yaml" << EOF
module: $MODULE
type: code
area: CODE_HEMS
function: $FUNCTION
sub_function: $SUB_FUNCTION
version: $VERSION
delivery_cycle: $DELIVERY_CYCLE

files:
  - ${MODULE}.c
  - ${MODULE}.h
  - ${MODULE}_compiler_log.txt
  - ${MODULE}_static_analysis_report.txt
  - ${MODULE}_sil_results.txt
  - ${MODULE}_certification_report.txt
  - trace_links.csv
EOF

############################################
# MOD_HEMS
############################################

cat > "$MOD_DIR/trace_links.csv" << EOF
source,target,link_type
${MODULE}.slx,${MODULE}_dictionary.sldd,uses
${MODULE}.slx,${MODULE}_analysis_report.txt,validated_by
${MODULE}.slx,${MODULE}_east_report.pdf,reviewed_by
${MODULE}.slx,${MODULE}_mdt_reference.txt,linked_to_mdt
${MODULE}.slx,${MODULE}_sof_reference.txt,linked_to_sof
EOF

cat > "$MOD_DIR/module-manifest.yaml" << EOF
module: $MODULE
type: module
area: MOD_HEMS
function: $FUNCTION
sub_function: $SUB_FUNCTION
version: $VERSION
delivery_cycle: $DELIVERY_CYCLE

files:
  - ${MODULE}.slx
  - ${MODULE}_dictionary.sldd
  - ${MODULE}_interface.xlsx
  - ${MODULE}_variant.xlsx
  - ${MODULE}_stimuli.mat
  - ${MODULE}_calibration.html
  - ${MODULE}_analysis_report.txt
  - ${MODULE}_east_report.pdf
  - ${MODULE}_delivery_package.zip
  - ${MODULE}_sof_reference.txt
  - ${MODULE}_mdt_reference.txt
  - trace_links.csv
EOF

############################################
# SPEC_HEMS
############################################

cat > "$SPEC_DIR/trace_links.csv" << EOF
source,target,link_type
${MODULE}_spec_source.xml,${MODULE}_spec_document.pdf,documented_by
${MODULE}_crs_interface.xml,${MODULE}_spec_source.xml,defines
${MODULE}_technical_fact_reference.txt,${MODULE}_sdt_reference.txt,linked_to_sdt
EOF

cat > "$SPEC_DIR/spec-manifest.yaml" << EOF
module: $MODULE
type: specification
area: SPEC_HEMS
function: $FUNCTION
sub_function: $SUB_FUNCTION
version: $VERSION
delivery_cycle: $DELIVERY_CYCLE

files:
  - ${MODULE}_spec_source.xml
  - ${MODULE}_spec_document.pdf
  - ${MODULE}_comparison_report.txt
  - ${MODULE}_history_log.txt
  - ${MODULE}_crs_interface.xml
  - ${MODULE}_sdt_reference.txt
  - ${MODULE}_technical_fact_reference.txt
  - trace_links.csv
EOF

echo ""
echo "Repair completed successfully."
echo ""
echo "Updated files:"
echo "$CODE_DIR/code-manifest.yaml"
echo "$CODE_DIR/trace_links.csv"
echo "$MOD_DIR/module-manifest.yaml"
echo "$MOD_DIR/trace_links.csv"
echo "$SPEC_DIR/spec-manifest.yaml"
echo "$SPEC_DIR/trace_links.csv"