#!/usr/bin/env bash
set -euo pipefail

# Creates the ATXX_OBMX_MGN module and the afsfdsa2 specification
# under MOD_HEMS, SPEC_HEMS, and CODE_HEMS.
#
# Usage:
#   chmod +x add_atxx_obmx_mgn_specification.sh
#   ./add_atxx_obmx_mgn_specification.sh [PROJECT_ROOT]
#
# Examples:
#   ./add_atxx_obmx_mgn_specification.sh
#   ./add_atxx_obmx_mgn_specification.sh /path/to/repository
#
# PROJECT_ROOT must be the directory containing the HEMS directory.

PROJECT_ROOT="${1:-.}"
HEMS_ROOT="${PROJECT_ROOT%/}/HEMS"

FUNCTION="ATXX"
SUBFUNCTION_PART="OBMX"
SUBFUNCTION="${FUNCTION}_${SUBFUNCTION_PART}"
MODULE_PART="MGN"
MODULE="${SUBFUNCTION}_${MODULE_PART}"

SPECIFICATION="afsfdsa2"
RELEASE_SUFFIX="RI_16_0(1.0)"

MOD_MODULE_DIR="$HEMS_ROOT/MOD_HEMS/$FUNCTION/$SUBFUNCTION/$MODULE"
SPEC_MODULE_DIR="$HEMS_ROOT/SPEC_HEMS/$FUNCTION/$SUBFUNCTION/$MODULE"
CODE_MODULE_DIR="$HEMS_ROOT/CODE_HEMS/$FUNCTION/$SUBFUNCTION/$MODULE"

MOD_PACKAGE="a_${MODULE}_T_A"
SPEC_PACKAGE="a_${MODULE}_${SPECIFICATION}_A"
CODE_PACKAGE="a_${MODULE}_${SPECIFICATION}_A_${RELEASE_SUFFIX}"

MOD_PACKAGE_DIR="$MOD_MODULE_DIR/$MOD_PACKAGE"
SPEC_PACKAGE_DIR="$SPEC_MODULE_DIR/$SPEC_PACKAGE"
CODE_PACKAGE_DIR="$CODE_MODULE_DIR/$CODE_PACKAGE"

CODE_BASE="${MODULE}_${SPECIFICATION}"

validate_required_areas() {
  local area

  for area in CODE_HEMS MOD_HEMS SPEC_HEMS; do
    if [[ ! -d "$HEMS_ROOT/$area" ]]; then
      echo "ERROR: Required controlled area is missing:"
      echo "  $HEMS_ROOT/$area"
      echo ""
      echo "Run this script from the repository root or provide"
      echo "the repository root as the first argument."
      exit 1
    fi
  done
}

validate_names() {
  local name
  local description

  while IFS="|" read -r description name; do
    if [[ -z "$name" ]]; then
      echo "ERROR: $description must not be empty."
      exit 1
    fi

    if [[ ! "$name" =~ ^[A-Za-z0-9_]+$ ]]; then
      echo "ERROR: $description may contain only letters,"
      echo "numbers, and underscores."
      echo "Received: $name"
      exit 1
    fi

    if [[ "$name" == *_ ]]; then
      echo "ERROR: $description must not end with an underscore."
      echo "Received: $name"
      exit 1
    fi
  done <<EOF
Function|$FUNCTION
Sub-function|$SUBFUNCTION
Module|$MODULE
Specification|$SPECIFICATION
EOF
}

create_file() {
  local file_path="$1"

  mkdir -p "$(dirname "$file_path")"

  if [[ -e "$file_path" ]]; then
    echo "Keeping existing file:"
    echo "  $file_path"
  else
    : > "$file_path"
    echo "Created file:"
    echo "  $file_path"
  fi
}

create_mod_package() {
  if [[ -d "$MOD_PACKAGE_DIR" ]]; then
    echo ""
    echo "MOD package already exists and will be reused:"
    echo "  $MOD_PACKAGE_DIR"
    return
  fi

  echo ""
  echo "Creating MOD package:"
  echo "  $MOD_PACKAGE_DIR"

  mkdir -p "$MOD_PACKAGE_DIR"

  create_file "$MOD_PACKAGE_DIR/${MOD_PACKAGE}.slx"
  create_file "$MOD_PACKAGE_DIR/${MOD_PACKAGE}_Variant.xlsx"
  create_file "$MOD_PACKAGE_DIR/${MODULE}_Module_Interface.xlsx"
  create_file "$MOD_PACKAGE_DIR/MXAM_Report_[4_selected_artifacts]_2026.xlsx"
}

create_spec_package() {
  if [[ -e "$SPEC_PACKAGE_DIR" ]]; then
    echo "ERROR: The specification package already exists:"
    echo "  $SPEC_PACKAGE_DIR"
    exit 1
  fi

  echo ""
  echo "Creating SPEC package:"
  echo "  $SPEC_PACKAGE_DIR"

  mkdir -p "$SPEC_PACKAGE_DIR"

  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}(10-0).pdf"
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}.slx"
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}.html"
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}_data.m"
  create_file "$SPEC_PACKAGE_DIR/${SPEC_PACKAGE}_DR_Report.xlsx"
  create_file "$SPEC_PACKAGE_DIR/ReportMR_${SPEC_PACKAGE}.pdf"
  create_file "$SPEC_PACKAGE_DIR/ReportMRDICO_${SPEC_PACKAGE}.xlsx"
}

create_code_package() {
  if [[ -e "$CODE_PACKAGE_DIR" ]]; then
    echo "ERROR: The code package already exists:"
    echo "  $CODE_PACKAGE_DIR"
    exit 1
  fi

  echo ""
  echo "Creating CODE package:"
  echo "  $CODE_PACKAGE_DIR"

  mkdir -p "$CODE_PACKAGE_DIR"

  create_file "$CODE_PACKAGE_DIR/${CODE_BASE}.c"
  create_file "$CODE_PACKAGE_DIR/${CODE_BASE}.h"
  create_file "$CODE_PACKAGE_DIR/${CODE_BASE}_Memmap.h"
}

print_summary() {
  echo ""
  echo "============================================================"
  echo "Specification creation completed successfully"
  echo "============================================================"
  echo ""
  echo "Function:"
  echo "  $FUNCTION"
  echo ""
  echo "Sub-function:"
  echo "  $SUBFUNCTION"
  echo ""
  echo "Module:"
  echo "  $MODULE"
  echo ""
  echo "Specification variant:"
  echo "  $SPECIFICATION"
  echo ""
  echo "Created or reused MOD package:"
  echo "  $MOD_PACKAGE_DIR"
  echo ""
  echo "Created SPEC package:"
  echo "  $SPEC_PACKAGE_DIR"
  echo ""
  echo "Created CODE package:"
  echo "  $CODE_PACKAGE_DIR"
  echo ""
  echo "Created placeholder content:"
  echo "  - 1 MOD package with 4 files, unless already present"
  echo "  - 1 SPEC package with 7 files"
  echo "  - 1 CODE package with 3 files"
  echo ""
  echo "Expected specification manifest after merge:"
  echo "  $SPEC_PACKAGE_DIR/specification-manifest.yaml"
  echo ""
  echo "Expected code specification manifest after merge:"
  echo "  $CODE_PACKAGE_DIR/specification-manifest.yaml"
  echo ""
  echo "The manifest files are not created by this script."
  echo "They will be generated by the post-merge manifest workflow."
  echo ""
  echo "Review the placeholder files, replace them with the actual"
  echo "delivery content, and commit the changes on a feature branch."
}

validate_required_areas
validate_names

echo "============================================================"
echo "Creating ATXX_OBMX_MGN specification"
echo "============================================================"
echo ""
echo "HEMS root:"
echo "  $HEMS_ROOT"
echo ""
echo "Specification package:"
echo "  $SPEC_PACKAGE"

create_mod_package
create_spec_package
create_code_package
print_summary
