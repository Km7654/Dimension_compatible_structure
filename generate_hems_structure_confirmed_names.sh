#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   chmod +x generate_hems_structure.sh
#   ./generate_hems_structure.sh [PROJECT_ROOT]
#
# Example:
#   ./generate_hems_structure.sh HEMS_PROJECT

ROOT="${1:-HEMS_PROJECT}"

# Only confirmed function, sub-function, and module names are used.
# Format: FUNCTION|SUBFUNCTION|MODULE
CONFIRMED_MODULES=(
    "ASXX|ADMX|CSM"
    "ASXX|ADMX|CTL"
    "ASXX|ADMX|MON"
    "ASXX|DGNX|CSM"
    "ASXX|DGNX|CTL"
    "ASXX|DGNX|MON"
    "FLPC|MWOU|CSM"
)

# Confirmed specification identifiers from the supplied screenshots.
SPECIFICATIONS=(
    "adacxxx2xg"
    "adacxxx4xg"
    "obmxxxx1xg"
    "obmxxxx2xg"
)

create_empty_file() {
    local file_path="$1"
    mkdir -p "$(dirname "$file_path")"
    : > "$file_path"
}

create_mod_hems() {
    local function="$1"
    local subfunction="$2"
    local module="$3"

    local subfunction_name="${function}_${subfunction}"
    local module_name="${function}_${subfunction}_${module}"
    local delivery_module_name="a_${module_name}_T_A"
    local target="${ROOT}/MOD_HEMS/${function}/${subfunction_name}/${module_name}/${delivery_module_name}"

    mkdir -p "$target"

    # Four MOD files shown in the supplied delivery-folder screenshot.
    create_empty_file "${target}/${delivery_module_name}.slx"
    create_empty_file "${target}/${delivery_module_name}_Variant.xlsx"
    create_empty_file "${target}/${module_name}_Module_Interface.xlsx"
    create_empty_file "${target}/MXAM_Report_[4_selected_artifacts]_2026.xlsx"
}

create_spec_hems() {
    local function="$1"
    local subfunction="$2"
    local module="$3"
    local specification="$4"

    local subfunction_name="${function}_${subfunction}"
    local module_name="${function}_${subfunction}_${module}"
    local specification_name="a_${module_name}_${specification}_A"
    local target="${ROOT}/SPEC_HEMS/${function}/${subfunction_name}/${module_name}/${specification_name}"

    mkdir -p "$target"

    # Seven specification files shown in the supplied SPEC_HEMS screenshot.
    create_empty_file "${target}/${specification_name}(10-0).pdf"
    create_empty_file "${target}/${specification_name}.slx"
    create_empty_file "${target}/${specification_name}.html"
    create_empty_file "${target}/${specification_name}_data.m"
    create_empty_file "${target}/${specification_name}_DR_Report.xlsx"
    create_empty_file "${target}/ReportMR_${specification_name}.pdf"
    create_empty_file "${target}/ReportMRDICO_${specification_name}.xlsx"
}

create_code_hems() {
    local function="$1"
    local subfunction="$2"
    local module="$3"
    local specification="$4"

    local subfunction_name="${function}_${subfunction}"
    local module_name="${function}_${subfunction}_${module}"
    local code_folder="a_${module_name}_${specification}_A_RI_16_0(1.0)"
    local code_base="${module_name}_${specification}"
    local target="${ROOT}/CODE_HEMS/${function}/${subfunction_name}/${module_name}/${code_folder}"

    mkdir -p "$target"

    # Three generated-code files shown in the supplied CODE_HEMS screenshot.
    create_empty_file "${target}/${code_base}.c"
    create_empty_file "${target}/${code_base}.h"
    create_empty_file "${target}/${code_base}_Memmap.h"
}

mkdir -p "${ROOT}/MOD_HEMS" "${ROOT}/SPEC_HEMS" "${ROOT}/CODE_HEMS"

for entry in "${CONFIRMED_MODULES[@]}"; do
    IFS='|' read -r function subfunction module <<< "$entry"

    # The same function, sub-function, and module names are used in all areas.
    create_mod_hems "$function" "$subfunction" "$module"

    for specification in "${SPECIFICATIONS[@]}"; do
        create_spec_hems "$function" "$subfunction" "$module" "$specification"
        create_code_hems "$function" "$subfunction" "$module" "$specification"
    done
done

echo "HEMS folder structure created successfully at: ${ROOT}"
echo "Confirmed functions: ASXX and FLPC"
echo "Confirmed modules created: ${#CONFIRMED_MODULES[@]}"
echo "Specification folders per module: ${#SPECIFICATIONS[@]}"
