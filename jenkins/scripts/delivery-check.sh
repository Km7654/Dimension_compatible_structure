#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# HEMS Delivery Check
#
# Validates the complete repository structure and package naming conventions
# under:
#   HEMS/CODE_HEMS
#   HEMS/MOD_HEMS
#   HEMS/SPEC_HEMS
#
# This script must be executed from the repository root.
# =============================================================================

HEMS_ROOT="${HEMS_ROOT:-HEMS}"
RELEASE_SUFFIX="RI_16_0(1.0)"

CONTROLLED_AREAS=(
  "CODE_HEMS"
  "MOD_HEMS"
  "SPEC_HEMS"
)

SUPPORT_AREAS=(
  "BASELINES"
  "DELIVERY_REQUESTS"
  "INCOMING"
)

ALLOWED_VARIANTS=(
  "adacxxx2xg"
  "adacxxx4xg"
  "obmxxxx1xg"
  "obmxxxx2xg"
  "afsfdsa2"
)

fail=0
checked_areas=0
checked_functions=0
checked_subfunctions=0
checked_modules=0
checked_packages=0
skipped_support_areas=0

echo "============================================================"
echo "HEMS folder naming structure check"
echo "============================================================"
echo "Working directory: $(pwd)"
echo "HEMS root:        $HEMS_ROOT"
echo ""
echo "Expected hierarchy:"
echo "HEMS/<AREA>/<Function>/<Function_SubFunction>/<Function_SubFunction_Module>/<PackageFolder>"
echo ""
echo "MOD_HEMS package:  a_<Module>_T_A"
echo "SPEC_HEMS package: a_<Module>_<Variant>_A"
echo "CODE_HEMS package: a_<Module>_<Variant>_A_${RELEASE_SUFFIX}"
echo ""

report_error() {
  local path="$1"
  local message="$2"

  # Jenkins displays ordinary ERROR lines in the console.
  # The GitHub annotation format is retained for compatibility.
  echo "ERROR: $message"
  echo "Path: $path"
  echo "::error file=$path::$message"

  fail=1
}

array_contains() {
  local sought="$1"
  shift

  local value

  for value in "$@"; do
    if [[ "$value" == "$sought" ]]; then
      return 0
    fi
  done

  return 1
}

validate_simple_folder_name() {
  local folder_path="$1"
  local folder_name="$2"
  local folder_type="$3"

  if [[ -z "$folder_name" ]]; then
    report_error \
      "$folder_path" \
      "$folder_type folder name must not be empty."
    return
  fi

  if [[ "$folder_name" =~ [[:space:]] ]]; then
    report_error \
      "$folder_path" \
      "$folder_type folder name must not contain spaces. Found: '$folder_name'"
  fi

  if [[ ! "$folder_name" =~ ^[A-Za-z0-9_]+$ ]]; then
    report_error \
      "$folder_path" \
      "$folder_type folder name may contain only letters, numbers, and underscores. Found: '$folder_name'"
  fi

  if [[ "$folder_name" == *_ ]]; then
    report_error \
      "$folder_path" \
      "$folder_type folder name must not end with an underscore. Found: '$folder_name'"
  fi
}

validate_subfunction_name() {
  local path="$1"
  local function_name="$2"
  local subfunction_name="$3"

  validate_simple_folder_name \
    "$path" \
    "$subfunction_name" \
    "Sub-function"

  local prefix="${function_name}_"

  if [[ "$subfunction_name" != "${prefix}"* ]]; then
    report_error \
      "$path" \
      "Sub-function '$subfunction_name' must start with '$prefix'."
  elif [[ "$subfunction_name" == "$prefix" ]]; then
    report_error \
      "$path" \
      "Sub-function '$subfunction_name' must contain a name after '$prefix'."
  fi
}

validate_module_name() {
  local path="$1"
  local subfunction_name="$2"
  local module_name="$3"

  validate_simple_folder_name \
    "$path" \
    "$module_name" \
    "Module"

  local prefix="${subfunction_name}_"

  if [[ "$module_name" != "${prefix}"* ]]; then
    report_error \
      "$path" \
      "Module '$module_name' must start with '$prefix'."
  elif [[ "$module_name" == "$prefix" ]]; then
    report_error \
      "$path" \
      "Module '$module_name' must contain a name after '$prefix'."
  fi
}

validate_package_name() {
  local package_path="$1"
  local area_name="$2"
  local module_name="$3"
  local package_name="$4"

  local expected
  local variant

  case "$area_name" in
    MOD_HEMS)
      expected="a_${module_name}_T_A"

      if [[ "$package_name" != "$expected" ]]; then
        report_error \
          "$package_path" \
          "Invalid MOD_HEMS package '$package_name'. Expected '$expected'."
        return 1
      fi

      return 0
      ;;

    SPEC_HEMS)
      for variant in "${ALLOWED_VARIANTS[@]}"; do
        expected="a_${module_name}_${variant}_A"

        if [[ "$package_name" == "$expected" ]]; then
          return 0
        fi
      done

      report_error \
        "$package_path" \
        "Invalid SPEC_HEMS package '$package_name'. Expected a_${module_name}_<allowed-variant>_A."

      return 1
      ;;

    CODE_HEMS)
      for variant in "${ALLOWED_VARIANTS[@]}"; do
        expected="a_${module_name}_${variant}_A_${RELEASE_SUFFIX}"

        if [[ "$package_name" == "$expected" ]]; then
          return 0
        fi
      done

      report_error \
        "$package_path" \
        "Invalid CODE_HEMS package '$package_name'. Expected a_${module_name}_<allowed-variant>_A_${RELEASE_SUFFIX}."

      return 1
      ;;

    *)
      report_error \
        "$package_path" \
        "Unsupported controlled area '$area_name'."

      return 1
      ;;
  esac
}

check_top_level_hems_folders() {
  local area_path
  local area_name

  while IFS= read -r area_path; do
    [[ -z "$area_path" ]] && continue

    area_name="$(basename "$area_path")"

    if array_contains "$area_name" "${CONTROLLED_AREAS[@]}"; then
      echo "Controlled HEMS area found: $area_path"
    elif array_contains "$area_name" "${SUPPORT_AREAS[@]}"; then
      echo "Skipping allowed support area: $area_path"
      skipped_support_areas=$((skipped_support_areas + 1))
    else
      report_error \
        "$area_path" \
        "Unexpected folder '$area_name' directly under HEMS."
    fi
  done < <(
    find "$HEMS_ROOT" \
      -mindepth 1 \
      -maxdepth 1 \
      -type d \
      | sort
  )
}

validate_area_structure() {
  local area_name="$1"
  local area_path="${HEMS_ROOT}/${area_name}"

  echo ""
  echo "------------------------------------------------------------"
  echo "Checking area: $area_name"
  echo "------------------------------------------------------------"

  if [[ ! -d "$area_path" ]]; then
    report_error \
      "$area_path" \
      "Required HEMS area folder is missing."
    return
  fi

  checked_areas=$((checked_areas + 1))

  local function_count=0
  local function_path
  local function_name

  while IFS= read -r function_path; do
    [[ -z "$function_path" ]] && continue

    function_count=$((function_count + 1))
    checked_functions=$((checked_functions + 1))

    function_name="$(basename "$function_path")"

    validate_simple_folder_name \
      "$function_path" \
      "$function_name" \
      "Function"

    local subfunction_count=0
    local subfunction_path
    local subfunction_name

    while IFS= read -r subfunction_path; do
      [[ -z "$subfunction_path" ]] && continue

      subfunction_count=$((subfunction_count + 1))
      checked_subfunctions=$((checked_subfunctions + 1))

      subfunction_name="$(basename "$subfunction_path")"

      validate_subfunction_name \
        "$subfunction_path" \
        "$function_name" \
        "$subfunction_name"

      local module_count=0
      local module_path
      local module_name

      while IFS= read -r module_path; do
        [[ -z "$module_path" ]] && continue

        module_count=$((module_count + 1))
        checked_modules=$((checked_modules + 1))

        module_name="$(basename "$module_path")"

        validate_module_name \
          "$module_path" \
          "$subfunction_name" \
          "$module_name"

        local package_count=0
        local package_path
        local package_name

        while IFS= read -r package_path; do
          [[ -z "$package_path" ]] && continue

          package_count=$((package_count + 1))
          checked_packages=$((checked_packages + 1))

          package_name="$(basename "$package_path")"

          validate_package_name \
            "$package_path" \
            "$area_name" \
            "$module_name" \
            "$package_name" \
            || true
        done < <(
          find "$module_path" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            | sort
        )

        if [[ "$package_count" -eq 0 ]]; then
          report_error \
            "$module_path" \
            "Module '$module_name' does not contain any package folder."
        elif [[ "$area_name" == "MOD_HEMS" && "$package_count" -ne 1 ]]; then
          report_error \
            "$module_path" \
            "MOD_HEMS module '$module_name' must contain exactly one package folder. Found: $package_count"
        fi
      done < <(
        find "$subfunction_path" \
          -mindepth 1 \
          -maxdepth 1 \
          -type d \
          | sort
      )

      if [[ "$module_count" -eq 0 ]]; then
        report_error \
          "$subfunction_path" \
          "Sub-function '$subfunction_name' does not contain any module folders."
      fi
    done < <(
      find "$function_path" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        | sort
    )

    if [[ "$subfunction_count" -eq 0 ]]; then
      report_error \
        "$function_path" \
        "Function '$function_name' does not contain any sub-function folders."
    fi
  done < <(
    find "$area_path" \
      -mindepth 1 \
      -maxdepth 1 \
      -type d \
      | sort
  )

  if [[ "$function_count" -eq 0 ]]; then
    report_error \
      "$area_path" \
      "Area '$area_name' does not contain any function folders."
  fi
}

if [[ ! -d "$HEMS_ROOT" ]]; then
  echo "ERROR: HEMS root folder is missing: $HEMS_ROOT"
  echo ""
  echo "Run this script from the repository root."
  exit 1
fi

check_top_level_hems_folders

for area_name in "${CONTROLLED_AREAS[@]}"; do
  validate_area_structure "$area_name"
done

echo ""
echo "============================================================"
echo "Delivery check summary"
echo "============================================================"
echo "Controlled areas checked: $checked_areas"
echo "Support areas skipped:    $skipped_support_areas"
echo "Functions checked:        $checked_functions"
echo "Sub-functions checked:    $checked_subfunctions"
echo "Modules checked:          $checked_modules"
echo "Packages checked:         $checked_packages"
echo "============================================================"

if [[ "$fail" -ne 0 ]]; then
  echo "Delivery folder naming check failed."
  exit 1
fi

echo "Delivery folder naming check passed."
exit 0