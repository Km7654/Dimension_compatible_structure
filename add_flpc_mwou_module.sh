#!/usr/bin/env bash
set -euo pipefail

# Adds a new module under FLPC/FLPC_MWOU in MOD_HEMS, SPEC_HEMS, and CODE_HEMS.
#
# Usage:
#   chmod +x add_flpc_mwou_module.sh
#   ./add_flpc_mwou_module.sh <NEW_MODULE_NAME> [PROJECT_ROOT]
#
# Examples:
#   ./add_flpc_mwou_module.sh CTL
#   ./add_flpc_mwou_module.sh MON /path/to/repository
#
# PROJECT_ROOT must be the folder that contains the HEMS directory.

NEW_MODULE_PART="${1:-}"
PROJECT_ROOT="${2:-.}"
HEMS_ROOT="${PROJECT_ROOT%/}/HEMS"

FUNCTION="ATSL"
SUBFUNCTION_PART="MWOU"
SUBFUNCTION="${FUNCTION}_${SUBFUNCTION_PART}"
RELEASE_SUFFIX="RI_16_0(1.0)"

SPECIFICATIONS=(
  "adacxxx2xg"
  "adacxxx4xg"
  "obmxxxx1xg"
  "obmxxxx2xg"
)

if [[ -z "$NEW_MODULE_PART" ]]; then
  echo "ERROR: New module name is required."
  echo "Usage: $0 <NEW_MODULE_NAME> [PROJECT_ROOT]"
  echo "Example: $0 CTL"
  exit 1
fi

# Accept either CTL or the complete name FLPC_MWOU_CTL.
if [[ "$NEW_MODULE_PART" == "${SUBFUNCTION}_"* ]]; then
  MODULE="$NEW_MODULE_PART"
  NEW_MODULE_PART="${NEW_MODULE_PART#${SUBFUNCTION}_}"
else
  MODULE="${SUBFUNCTION}_${NEW_MODULE_PART}"
fi

if [[ ! "$NEW_MODULE_PART" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "ERROR: Module suffix may contain only letters, numbers, and underscores."
  echo "Received: $NEW_MODULE_PART"
  exit 1
fi

if [[ "$NEW_MODULE_PART" == *_ ]]; then
  echo "ERROR: Module suffix must not end with an underscore."
  exit 1
fi

if [[ "$MODULE" == "FLPC_MWOU_CSM" ]]; then
  echo "ERROR: FLPC_MWOU_CSM is the existing module. Provide a new module name."
  exit 1
fi

for area in CODE_HEMS MOD_HEMS SPEC_HEMS; do
  if [[ ! -d "$HEMS_ROOT/$area" ]]; then
    echo "ERROR: Required area is missing: $HEMS_ROOT/$area"
    echo "Run this script from the repository root or provide PROJECT_ROOT as argument 2."
    exit 1
  fi
done

MOD_MODULE_DIR="$HEMS_ROOT/MOD_HEMS/$FUNCTION/$SUBFUNCTION/$MODULE"
SPEC_MODULE_DIR="$HEMS_ROOT/SPEC_HEMS/$FUNCTION/$SUBFUNCTION/$MODULE"
CODE_MODULE_DIR="$HEMS_ROOT/CODE_HEMS/$FUNCTION/$SUBFUNCTION/$MODULE"

if [[ -e "$MOD_MODULE_DIR" || -e "$SPEC_MODULE_DIR" || -e "$CODE_MODULE_DIR" ]]; then
  echo "ERROR: The module already exists in at least one controlled area: $MODULE"
  [[ -e "$MOD_MODULE_DIR" ]] && echo "  - $MOD_MODULE_DIR"
  [[ -e "$SPEC_MODULE_DIR" ]] && echo "  - $SPEC_MODULE_DIR"
  [[ -e "$CODE_MODULE_DIR" ]] && echo "  - $CODE_MODULE_DIR"
  exit 1
fi

create_file() {
  local file_path="$1"
  mkdir -p "$(dirname "$file_path")"
  : > "$file_path"
}

echo "Creating new module: $MODULE"
echo "HEMS root: $HEMS_ROOT"

# -----------------------------------------------------------------------------
# MOD_HEMS
# HEMS/MOD_HEMS/FLPC/FLPC_MWOU/FLPC_MWOU_<MODULE>/
#   a_FLPC_MWOU_<MODULE>_T_A/
# -----------------------------------------------------------------------------
MOD_PACKAGE="a_${MODULE}_T_A"
MOD_PACKAGE_DIR="$MOD_MODULE_DIR/$MOD_PACKAGE"
mkdir -p "$MOD_PACKAGE_DIR"

create_file "$MOD_PACKAGE_DIR/${MOD_PACKAGE}.slx"
create_file "$MOD_PACKAGE_DIR/${MOD_PACKAGE}_Variant.xlsx"
create_file "$MOD_PACKAGE_DIR/${MODULE}_Module_Interface.xlsx"
create_file "$MOD_PACKAGE_DIR/MXAM_Report_[4_selected_artifacts]_2026.xlsx"

# -----------------------------------------------------------------------------
# SPEC_HEMS and CODE_HEMS
# Four specification variants are created for the new module.
# -----------------------------------------------------------------------------
for specification in "${SPECIFICATIONS[@]}"; do
  SPEC_PACKAGE="a_${MODULE}_${specification}_A"
  SPEC_PACKAGE_DIR="$SPEC_MODULE_DIR/$SPEC_PACKAGE"
  mkdir -p "$SPEC_PACKAGE_DIR"

  # Seven SPEC files.
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}(10-0).pdf"
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}.slx"
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}.html"
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}_data.m"
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}_DR_Report.xlsx"
  create_file "$SPEC_PACKAGE_DIR/ReportMR_${SPEC_PACKAGE}.pdf"
  create_file "$SPEC_PACKAGE_DIR/ReportMRDICO_${SPEC_PACKAGE}.xlsx"

  CODE_PACKAGE="a_${MODULE}_${specification}_A_${RELEASE_SUFFIX}"
  CODE_PACKAGE_DIR="$CODE_MODULE_DIR/$CODE_PACKAGE"
  CODE_BASE="${MODULE}_${specification}"
  mkdir -p "$CODE_PACKAGE_DIR"

  # Three CODE files.
  create_file "$CODE_PACKAGE_DIR/${CODE_BASE}.c"
  create_file "$CODE_PACKAGE_DIR/${CODE_BASE}.h"
  create_file "$CODE_PACKAGE_DIR/${CODE_BASE}_Memmap.h"
done

echo ""
echo "Module created successfully in all three controlled areas:"
echo "  - $MOD_MODULE_DIR"
echo "  - $SPEC_MODULE_DIR"
echo "  - $CODE_MODULE_DIR"
echo ""
echo "Created content:"
echo "  - 1 MOD package with 4 files"
echo "  - 4 SPEC packages with 7 files each"
echo "  - 4 CODE packages with 3 files each"
echo "  - Total placeholder files: 44"
echo ""
echo "Review the files, replace placeholders with real delivery files, then commit the new module on your feature branch."
