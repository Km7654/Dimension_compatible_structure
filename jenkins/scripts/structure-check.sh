#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# HEMS Structure Check
#
# Validates only the HEMS files changed between two Git commits.
#
# Usage:
#   ./jenkins/scripts/structure-check.sh [BASE_SHA] [HEAD_SHA]
#
# Examples:
#   ./jenkins/scripts/structure-check.sh HEAD~1 HEAD
#   ./jenkins/scripts/structure-check.sh abc123 def456
#
# If BASE_SHA is not supplied, the script uses HEAD~1.
# If HEAD_SHA is not supplied, the script uses HEAD.
#
# This script must be executed from the repository root.
# =============================================================================

HEMS_ROOT="${HEMS_ROOT:-HEMS}"
RELEASE_SUFFIX="RI_16_0(1.0)"

BASE_SHA="${1:-}"
HEAD_SHA="${2:-HEAD}"

ALLOWED_AREAS=(
  "CODE_HEMS"
  "MOD_HEMS"
  "SPEC_HEMS"
)

ALLOWED_VARIANTS=(
  "adacxxx2xg"
  "adacxxx4xg"
  "obmxxxx1xg"
  "obmxxxx2xg"
  "afsfdsa2"
)

fail=0
checked_hems_files=0
checked_module_level_files=0
checked_package_level_files=0
skipped_files=0

CHANGED_FILES_FILE="${CHANGED_FILES_FILE:-changed_files.txt}"

report_error() {
  local file_path="$1"
  local message="$2"

  echo "ERROR: $message"
  echo "Path: $file_path"
  echo "::error file=$file_path::$message"

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

validate_simple_name() {
  local path="$1"
  local name="$2"
  local type="$3"

  if [[ -z "$name" ]]; then
    report_error \
      "$path" \
      "$type name must not be empty."
    return
  fi

  if [[ "$name" =~ [[:space:]] ]]; then
    report_error \
      "$path" \
      "$type name must not contain spaces. Found: '$name'"
  fi

  if [[ ! "$name" =~ ^[A-Za-z0-9_]+$ ]]; then
    report_error \
      "$path" \
      "$type name may contain only letters, numbers, and underscores. Found: '$name'"
  fi

  if [[ "$name" == *_ ]]; then
    report_error \
      "$path" \
      "$type name must not end with an underscore. Found: '$name'"
  fi
}

validate_hierarchy() {
  local path="$1"
  local function_name="$2"
  local subfunction_name="$3"
  local module_name="$4"

  validate_simple_name \
    "$path" \
    "$function_name" \
    "Function"

  validate_simple_name \
    "$path" \
    "$subfunction_name" \
    "Sub-function"

  validate_simple_name \
    "$path" \
    "$module_name" \
    "Module"

  if [[ "$subfunction_name" != "${function_name}_"* ]]; then
    report_error \
      "$path" \
      "Sub-function '$subfunction_name' must start with '${function_name}_'."
  elif [[ "$subfunction_name" == "${function_name}_" ]]; then
    report_error \
      "$path" \
      "Sub-function '$subfunction_name' must contain a name after '${function_name}_'."
  fi

  if [[ "$module_name" != "${subfunction_name}_"* ]]; then
    report_error \
      "$path" \
      "Module '$module_name' must start with '${subfunction_name}_'."
  elif [[ "$module_name" == "${subfunction_name}_" ]]; then
    report_error \
      "$path" \
      "Module '$module_name' must contain a name after '${subfunction_name}_'."
  fi
}

validate_package_name() {
  local path="$1"
  local area="$2"
  local module_name="$3"
  local package="$4"

  local expected
  local variant

  case "$area" in
    MOD_HEMS)
      expected="a_${module_name}_T_A"

      if [[ "$package" != "$expected" ]]; then
        report_error \
          "$path" \
          "Invalid MOD_HEMS package '$package'. Expected '$expected'."
        return 1
      fi

      return 0
      ;;

    SPEC_HEMS)
      for variant in "${ALLOWED_VARIANTS[@]}"; do
        expected="a_${module_name}_${variant}_A"

        if [[ "$package" == "$expected" ]]; then
          return 0
        fi
      done

      report_error \
        "$path" \
        "Invalid SPEC_HEMS package '$package'. Expected a_${module_name}_<allowed-variant>_A."

      return 1
      ;;

    CODE_HEMS)
      for variant in "${ALLOWED_VARIANTS[@]}"; do
        expected="a_${module_name}_${variant}_A_${RELEASE_SUFFIX}"

        if [[ "$package" == "$expected" ]]; then
          return 0
        fi
      done

      report_error \
        "$path" \
        "Invalid CODE_HEMS package '$package'. Expected a_${module_name}_<allowed-variant>_A_${RELEASE_SUFFIX}."

      return 1
      ;;

    *)
      report_error \
        "$path" \
        "Unsupported controlled area '$area'."

      return 1
      ;;
  esac
}

is_allowed_support_path() {
  local file="$1"
  local base_name

  base_name="$(basename "$file")"

  if [[ "$file" == "$HEMS_ROOT/BASELINES/"* ]]; then
    return 0
  fi

  if [[ "$file" == "$HEMS_ROOT/DELIVERY_REQUESTS/"* ]]; then
    return 0
  fi

  if [[ "$file" == "$HEMS_ROOT/INCOMING/"* ]]; then
    return 0
  fi

  if [[ "$file" == "$HEMS_ROOT/README.md" ]]; then
    return 0
  fi

  if [[ "$file" == "$HEMS_ROOT/CODEOWNERS" ]]; then
    return 0
  fi

  if [[ "$file" == "$HEMS_ROOT/.gitignore" ]]; then
    return 0
  fi

  if [[ "$file" == "$HEMS_ROOT/.gitattributes" ]]; then
    return 0
  fi

  if [[ "$base_name" == ".keep" ]]; then
    return 0
  fi

  return 1
}

resolve_comparison_commits() {
  if [[ -z "$BASE_SHA" ]]; then
    BASE_SHA="$(git rev-parse HEAD~1 2>/dev/null || true)"
  fi

  if [[ -z "$HEAD_SHA" ]]; then
    HEAD_SHA="HEAD"
  fi

  if [[ -z "$BASE_SHA" ]]; then
    echo "No previous commit is available."
    echo "All tracked repository files will be validated."

    git ls-files > "$CHANGED_FILES_FILE"
    return
  fi

  if [[ "$BASE_SHA" == "0000000000000000000000000000000000000000" ]]; then
    echo "The base SHA represents a new branch or initial push."
    echo "All tracked repository files will be validated."

    git ls-files > "$CHANGED_FILES_FILE"
    return
  fi

  if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
    echo "WARNING: Base commit is not available locally: $BASE_SHA"
    echo "All tracked repository files will be validated."

    git ls-files > "$CHANGED_FILES_FILE"
    return
  fi

  if ! git cat-file -e "${HEAD_SHA}^{commit}" 2>/dev/null; then
    echo "ERROR: Head commit is not available locally: $HEAD_SHA"
    exit 1
  fi

  git diff \
    --name-only \
    --diff-filter=ACMR \
    "$BASE_SHA" \
    "$HEAD_SHA" \
    > "$CHANGED_FILES_FILE"
}

validate_changed_file() {
  local file="$1"

  if [[ "$file" != "$HEMS_ROOT/"* ]]; then
    echo "Skipping non-HEMS file: $file"
    skipped_files=$((skipped_files + 1))
    return
  fi

  if is_allowed_support_path "$file"; then
    echo "Skipping allowed support path: $file"
    skipped_files=$((skipped_files + 1))
    return
  fi

  checked_hems_files=$((checked_hems_files + 1))

  local parts=()
  local part_count
  local area
  local function_name
  local subfunction_name
  local module_name
  local package_name

  IFS="/" read -r -a parts <<< "$file"
  part_count="${#parts[@]}"

  # Expected paths:
  #
  # Module-level:
  # HEMS/AREA/Function/Sub-function/Module/File
  #
  # Package-level:
  # HEMS/AREA/Function/Sub-function/Module/Package/File
  #
  # Deeper files inside a package are also accepted:
  # HEMS/AREA/Function/Sub-function/Module/Package/Subdirectory/File
  if (( part_count < 6 )); then
    report_error \
      "$file" \
      "Invalid path depth. Expected a module-level or package-level HEMS file path."
    return
  fi

  area="${parts[1]}"
  function_name="${parts[2]}"
  subfunction_name="${parts[3]}"
  module_name="${parts[4]}"

  if ! array_contains "$area" "${ALLOWED_AREAS[@]}"; then
    report_error \
      "$file" \
      "Invalid controlled area '$area'. Expected CODE_HEMS, MOD_HEMS, or SPEC_HEMS."
    return
  fi

  validate_hierarchy \
    "$file" \
    "$function_name" \
    "$subfunction_name" \
    "$module_name"

  if (( part_count == 6 )); then
    checked_module_level_files=$((checked_module_level_files + 1))

    echo "Validating module-level file: $file"
    return
  fi

  package_name="${parts[5]}"
  checked_package_level_files=$((checked_package_level_files + 1))

  validate_package_name \
    "$file" \
    "$area" \
    "$module_name" \
    "$package_name" \
    || true

  echo "Validating package-level file: $file"
}

if [[ ! -d "$HEMS_ROOT" ]]; then
  echo "ERROR: HEMS root folder is missing: $HEMS_ROOT"
  echo ""
  echo "Run this script from the repository root."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: Git is not installed or is not available in PATH."
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: The current directory is not a Git working tree."
  exit 1
fi

echo "============================================================"
echo "HEMS changed-path structure check"
echo "============================================================"
echo "Working directory: $(pwd)"
echo "HEMS root:        $HEMS_ROOT"
echo "Base commit:      ${BASE_SHA:-automatic}"
echo "Head commit:      ${HEAD_SHA:-HEAD}"
echo ""

resolve_comparison_commits

echo "Resolved base commit: ${BASE_SHA:-all tracked files}"
echo "Resolved head commit: $HEAD_SHA"
echo ""

echo "Changed files:"

if [[ -s "$CHANGED_FILES_FILE" ]]; then
  cat "$CHANGED_FILES_FILE"
else
  echo "No changed files were detected."
fi

echo ""
echo "------------------------------------------------------------"
echo "Validating changed paths"
echo "------------------------------------------------------------"

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  validate_changed_file "$file"
done < "$CHANGED_FILES_FILE"

echo ""
echo "============================================================"
echo "Structure check summary"
echo "============================================================"
echo "Changed HEMS files checked:  $checked_hems_files"
echo "Module-level files checked:  $checked_module_level_files"
echo "Package-level files checked: $checked_package_level_files"
echo "Files skipped:               $skipped_files"
echo "============================================================"

if [[ "$fail" -ne 0 ]]; then
  echo "Structure check failed."
  exit 1
fi

echo "Structure check passed."
exit 0