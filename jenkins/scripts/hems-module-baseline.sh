#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# HEMS Module Baseline Processor for Jenkins
#
# Uses Git, Bash, awk, sed, grep, find, sha256sum, PowerShell Compress-Archive,
# and GitHub CLI. Python and loaded Groovy scripts are not required.
#
# Required environment variables:
#   MERGE_SHA       Merge commit on main to process
#
# Safety controls:
#   APPLY_CHANGES   false = preview only, true = modify workspace files
#   PUSH_CHANGES    false = no Git commit/push, true = commit/push to main
#   CREATE_TAG      false = no tag, true = create and push baseline tag
#
# Optional environment variables:
#   MAIN_BRANCH     Default: main
#   GH_REPO         Default: Km7654/Dimension_compatible_structure
#   GH_EXE          Git Bash path to gh.exe
#   POWERSHELL_EXE  Default: powershell.exe
#   OUTPUT_DIR      Default: jenkins-output/module-baseline
#
# Usage example in Git Bash:
#   MERGE_SHA=<sha> APPLY_CHANGES=false PUSH_CHANGES=false CREATE_TAG=false \
#     ./jenkins/scripts/hems-module-baseline.sh
# =============================================================================

MERGE_SHA="${MERGE_SHA:-${1:-}}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"
GH_REPO="${GH_REPO:-Km7654/Dimension_compatible_structure}"
GH_EXE="${GH_EXE:-/c/Users/kss932546/Tools/GitHubCLI/bin/gh.exe}"
POWERSHELL_EXE="${POWERSHELL_EXE:-powershell.exe}"
APPLY_CHANGES="${APPLY_CHANGES:-false}"
PUSH_CHANGES="${PUSH_CHANGES:-false}"
CREATE_TAG="${CREATE_TAG:-false}"
OUTPUT_DIR="${OUTPUT_DIR:-jenkins-output/module-baseline}"

CONTROLLED_AREAS=("CODE_HEMS" "MOD_HEMS" "SPEC_HEMS")
SPECIFICATION_AREAS=("CODE_HEMS" "SPEC_HEMS")

UPDATED_MANIFESTS_FILE="$OUTPUT_DIR/updated-manifests.txt"
BASELINE_FILES_FILE="$OUTPUT_DIR/baseline-files.txt"
AFFECTED_SPECIFICATIONS_FILE="$OUTPUT_DIR/affected-specifications.txt"
UPDATED_MODULES_FILE="$OUTPUT_DIR/updated-modules.txt"
VERSION_SUMMARY_FILE="$OUTPUT_DIR/version-summary.txt"
RESULT_FILE="$OUTPUT_DIR/result.env"
CHANGED_RECORDS_FILE="$OUTPUT_DIR/changed-records.tsv"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "$*"
}

separator() {
  echo "============================================================"
}

normalize_bool() {
  case "${1,,}" in
    true|yes|1|on) echo true ;;
    false|no|0|off|"") echo false ;;
    *) fail "Invalid Boolean value: $1" ;;
  esac
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || fail "Required tool is missing: $1"
}

is_controlled_area() {
  case "$1" in
    CODE_HEMS|MOD_HEMS|SPEC_HEMS) return 0 ;;
    *) return 1 ;;
  esac
}

is_specification_area() {
  case "$1" in
    CODE_HEMS|SPEC_HEMS) return 0 ;;
    *) return 1 ;;
  esac
}

is_generated_metadata() {
  case "$1" in
    code-manifest.yaml|module-manifest.yaml|spec-manifest.yaml|\
    specification-manifest.yaml|component-manifest.yaml|\
    baseline-manifest.yaml|checksums.sha256|tag-details.txt|\
    trace_links.csv|.keep)
      return 0
      ;;
    *) return 1 ;;
  esac
}

safe_name() {
  printf '%s' "$1" \
    | sed -E 's/[^A-Za-z0-9._-]+/-/g; s/-+/-/g; s/^[.-]+//; s/[.-]+$//'
}

yaml_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

read_manifest_version() {
  local manifest="$1"
  if [[ ! -f "$manifest" ]]; then
    echo 0
    return
  fi

  local version
  version="$(awk '
    /^[[:space:]]*version:[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]*version:[[:space:]]*/, "", line)
      gsub(/["'"'"'[:space:]]/, "", line)
      if (line ~ /^[0-9]+$/) { print line; exit }
    }
  ' "$manifest")"
  echo "${version:-0}"
}

manifest_has_merge() {
  local manifest="$1"
  [[ -f "$manifest" ]] || return 1
  grep -Fq "$MERGE_SHA" "$manifest"
}

extract_specification() {
  local area="$1" module="$2" package="$3"
  local value="$package"
  value="${value#a_${module}_}"
  if [[ "$area" == "SPEC_HEMS" ]]; then
    value="${value%_A}"
  else
    value="${value%_A_RI_16_0(1.0)}"
  fi
  printf '%s' "$value"
}

module_manifest_name() {
  case "$1" in
    CODE_HEMS) echo code-manifest.yaml ;;
    MOD_HEMS) echo module-manifest.yaml ;;
    SPEC_HEMS) echo spec-manifest.yaml ;;
    *) fail "Unsupported controlled area: $1" ;;
  esac
}

module_type() {
  case "$1" in
    CODE_HEMS) echo code ;;
    MOD_HEMS) echo module ;;
    SPEC_HEMS) echo specification ;;
    *) fail "Unsupported controlled area: $1" ;;
  esac
}

list_content_files() {
  local directory="$1"
  [[ -d "$directory" ]] || return 0
  find "$directory" -type f -print \
    | sed "s#^${directory}/##" \
    | while IFS= read -r relative; do
        if ! is_generated_metadata "$(basename "$relative")"; then
          printf '%s\n' "$relative"
        fi
      done \
    | sort
}

write_manifest() {
  local manifest="$1"
  local level="$2"
  local area="$3"
  local function_name="$4"
  local sub_function="$5"
  local module="$6"
  local package="$7"
  local specification="$8"
  local old_version="$9"
  local new_version="${10}"
  local logical_name="${11}"
  local item_type="${12}"
  local generated_utc="${13}"
  local temporary="$OUTPUT_DIR/manifest.$$.tmp"

  {
    echo "manifest_level: $(yaml_quote "$level")"
    if [[ "$level" == "specification" ]]; then
      echo "specification: $(yaml_quote "$specification")"
      echo "package: $(yaml_quote "$package")"
      if [[ "$area" == "SPEC_HEMS" ]]; then
        echo 'type: "source_specification"'
      else
        echo 'type: "generated_code_specification"'
      fi
    else
      echo "module: $(yaml_quote "$module")"
      echo "type: $(yaml_quote "$(module_type "$area")")"
    fi
    echo "area: $(yaml_quote "$area")"
    echo "function: $(yaml_quote "$function_name")"
    echo "sub_function: $(yaml_quote "$sub_function")"
    [[ "$level" == "specification" ]] && echo "module: $(yaml_quote "$module")"
    echo "version: $new_version"
    echo 'delivery_cycle: "not_released"'
    echo "version_label: $(yaml_quote "${logical_name}/v${new_version}")"
    echo "commit: $(yaml_quote "$MERGE_SHA")"
    echo "pull_request: $(yaml_quote "$PR_NUMBER")"
    echo "updated_utc: $(yaml_quote "$generated_utc")"
    echo "source_branch: $(yaml_quote "$SOURCE_BRANCH")"
    echo "target_branch: $(yaml_quote "$TARGET_BRANCH")"
    echo "pull_request_title: $(yaml_quote "$PR_TITLE")"
    echo 'generated_by: "Jenkins"'
    echo 'automation_owned: true'
    echo 'main_branch_only: true'
    echo 'files:'
    local content_found=false
    while IFS= read -r item; do
      [[ -z "$item" ]] && continue
      echo "  - $(yaml_quote "$item")"
      content_found=true
    done < <(list_content_files "$(dirname "$manifest")")
    [[ "$content_found" == false ]] && echo '  []'
    echo 'item_version:'
    echo "  version: $new_version"
    echo "  label: $(yaml_quote "${logical_name}/v${new_version}")"
    echo "  sha: $(yaml_quote "$MERGE_SHA")"
    echo "  pr: $(yaml_quote "$PR_NUMBER")"
    echo "  updated_utc: $(yaml_quote "$generated_utc")"
    echo 'item_version_history:'

    if [[ -f "$manifest" ]]; then
      awk '
        /^item_version_history:[[:space:]]*$/ { in_history=1; next }
        in_history { print }
      ' "$manifest" | sed '/^[[:space:]]*$/d' || true
    fi

    echo "  - version: $new_version"
    echo "    label: $(yaml_quote "${logical_name}/v${new_version}")"
    echo "    sha: $(yaml_quote "$MERGE_SHA")"
    echo "    pr: $(yaml_quote "$PR_NUMBER")"
    echo "    updated_utc: $(yaml_quote "$generated_utc")"
  } > "$temporary"

  mkdir -p "$(dirname "$manifest")"
  mv "$temporary" "$manifest"
  printf '%s\n' "$manifest" >> "$UPDATED_MANIFESTS_FILE"
  printf '%s | %s | %s -> %s | %s\n' \
    "$item_type" "$logical_name" "$old_version" "$new_version" "$manifest" \
    >> "$VERSION_SUMMARY_FILE"
}

preview_manifest_update() {
  local manifest="$1" item_type="$2" logical_name="$3"
  local old_version
  old_version="$(read_manifest_version "$manifest")"
  local new_version=$((old_version + 1))
  printf '%s | %s | %s -> %s | %s\n' \
    "$item_type" "$logical_name" "$old_version" "$new_version" "$manifest" \
    >> "$VERSION_SUMMARY_FILE"
  info "PREVIEW: $manifest version $old_version -> $new_version"
}

list_packages_at_commit() {
  local commit="$1" area="$2" function_name="$3" sub_function="$4" module="$5"
  local tree_path="HEMS/$area/$function_name/$sub_function/$module"
  git ls-tree -d --name-only "$commit:$tree_path" 2>/dev/null || true
}

add_unique_line() {
  local value="$1" file="$2"
  grep -Fxq "$value" "$file" 2>/dev/null || printf '%s\n' "$value" >> "$file"
}

create_zip_with_powershell() {
  local source_directory="$1"
  local destination_zip="$2"
  local win_source win_destination
  win_source="$(cygpath -w "$source_directory")"
  win_destination="$(cygpath -w "$destination_zip")"
  "$POWERSHELL_EXE" -NoProfile -NonInteractive -Command \
    "if (Test-Path -LiteralPath '$win_destination') { Remove-Item -Force -LiteralPath '$win_destination' }; Compress-Archive -Path '$win_source\\*' -DestinationPath '$win_destination' -CompressionLevel Optimal -Force"
}

resolve_pr_metadata() {
  PR_NUMBER="${PR_NUMBER:-}"
  PR_TITLE="${PR_TITLE:-}"
  SOURCE_BRANCH="${SOURCE_BRANCH:-}"
  TARGET_BRANCH="${TARGET_BRANCH:-$MAIN_BRANCH}"

  if [[ -x "$GH_EXE" || -f "$GH_EXE" ]]; then
    local pr_json
    pr_json="$("$GH_EXE" api "repos/$GH_REPO/commits/$MERGE_SHA/pulls" 2>/dev/null || true)"
    if [[ -n "$pr_json" && "$pr_json" != "[]" ]]; then
      PR_NUMBER="${PR_NUMBER:-$(printf '%s' "$pr_json" | sed -n 's/.*"number":[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -n1)}"
      PR_TITLE="${PR_TITLE:-$("$GH_EXE" pr view "$PR_NUMBER" --repo "$GH_REPO" --json title --jq '.title' 2>/dev/null || true)}"
      SOURCE_BRANCH="${SOURCE_BRANCH:-$("$GH_EXE" pr view "$PR_NUMBER" --repo "$GH_REPO" --json headRefName --jq '.headRefName' 2>/dev/null || true)}"
    fi
  fi

  PR_NUMBER="${PR_NUMBER:-unknown}"
  PR_TITLE="${PR_TITLE:-$(git log -1 --format=%s "$MERGE_SHA")}"
  SOURCE_BRANCH="${SOURCE_BRANCH:-unknown}"
}

main() {
  APPLY_CHANGES="$(normalize_bool "$APPLY_CHANGES")"
  PUSH_CHANGES="$(normalize_bool "$PUSH_CHANGES")"
  CREATE_TAG="$(normalize_bool "$CREATE_TAG")"

  [[ -n "$MERGE_SHA" ]] || fail "MERGE_SHA is required."
  [[ "$PUSH_CHANGES" == false || "$APPLY_CHANGES" == true ]] || fail "PUSH_CHANGES=true requires APPLY_CHANGES=true."
  [[ "$CREATE_TAG" == false || ( "$APPLY_CHANGES" == true && "$PUSH_CHANGES" == true ) ]] || fail "CREATE_TAG=true requires APPLY_CHANGES=true and PUSH_CHANGES=true."

  for tool in git awk sed grep find sha256sum sort basename dirname cygpath; do
    require_tool "$tool"
  done
  command -v "$POWERSHELL_EXE" >/dev/null 2>&1 || fail "PowerShell is unavailable: $POWERSHELL_EXE"
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Run the script from a Git repository workspace."
  [[ -d HEMS ]] || fail "HEMS directory is missing."

  mkdir -p "$OUTPUT_DIR"
  : > "$UPDATED_MANIFESTS_FILE"
  : > "$BASELINE_FILES_FILE"
  : > "$AFFECTED_SPECIFICATIONS_FILE"
  : > "$UPDATED_MODULES_FILE"
  : > "$VERSION_SUMMARY_FILE"
  : > "$CHANGED_RECORDS_FILE"

  git fetch --prune origin \
    "+refs/heads/$MAIN_BRANCH:refs/remotes/origin/$MAIN_BRANCH" \
    "+refs/tags/*:refs/tags/*"

  git cat-file -e "$MERGE_SHA^{commit}" 2>/dev/null || git fetch origin "$MERGE_SHA"
  git cat-file -e "$MERGE_SHA^{commit}" 2>/dev/null || fail "Merge commit is unavailable: $MERGE_SHA"

  local parent_line parent_count
  parent_line="$(git rev-list --parents -n 1 "$MERGE_SHA")"
  parent_count=$(wc -w <<< "$parent_line" | tr -d ' ')
  (( parent_count >= 2 )) || fail "The supplied commit has no first parent: $MERGE_SHA"

  PRE_MERGE_SHA="$(git rev-parse "$MERGE_SHA^1")"
  GENERATED_UTC="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  resolve_pr_metadata

  separator
  echo "HEMS Module Baseline Processor"
  separator
  echo "Main before merge: $PRE_MERGE_SHA"
  echo "Main after merge:  $MERGE_SHA"
  echo "Pull Request:      $PR_NUMBER"
  echo "Apply changes:     $APPLY_CHANGES"
  echo "Push changes:      $PUSH_CHANGES"
  echo "Create tag:        $CREATE_TAG"
  echo

  git diff --name-status --find-renames --find-copies \
    "$PRE_MERGE_SHA" "$MERGE_SHA" > "$CHANGED_RECORDS_FILE"

  echo "Files introduced by this merge:"
  cat "$CHANGED_RECORDS_FILE" || true
  echo

  declare -A changed_specs=()
  declare -A deleted_specs=()
  declare -A module_reasons=()
  declare -A specs_per_module=()
  declare -A package_candidates=()

  while IFS=$'\t' read -r status path1 path2; do
    [[ -z "$status" ]] && continue
    local paths=() sides=()
    if [[ "$status" == R* || "$status" == C* ]]; then
      paths=("$path1" "$path2")
      sides=(old new)
    elif [[ "$status" == D* ]]; then
      paths=("$path1")
      sides=(old)
    else
      paths=("$path1")
      sides=(new)
    fi

    local i
    for i in "${!paths[@]}"; do
      local file="${paths[$i]}" side="${sides[$i]}"
      IFS='/' read -r root area function_name sub_function module package remainder <<< "$file"
      [[ "$root" == HEMS ]] || continue
      is_controlled_area "$area" || continue
      is_generated_metadata "$(basename "$file")" && continue
      [[ -n "$module" ]] || continue

      local module_key="$area|$function_name|$sub_function|$module"
      local part_count
      part_count="$(awk -F/ '{print NF}' <<< "$file")"

      if [[ "$part_count" -eq 6 ]]; then
        module_reasons["$module_key"]="${module_reasons[$module_key]:-} module-level-file"
      fi
      if [[ "$area" == MOD_HEMS ]]; then
        module_reasons["$module_key"]="${module_reasons[$module_key]:-} MOD_HEMS-change"
      fi

      if is_specification_area "$area" && [[ "$part_count" -ge 7 ]]; then
        local spec_key="$area|$function_name|$sub_function|$module|$package"
        if [[ "$status" == D* && "$side" == old ]]; then
          deleted_specs["$spec_key"]=1
        else
          changed_specs["$spec_key"]=1
        fi
        specs_per_module["$module_key"]="${specs_per_module[$module_key]:-}|$package"
        package_candidates["$module_key"]=1
      fi
    done
  done < "$CHANGED_RECORDS_FILE"

  local module_key
  for module_key in "${!package_candidates[@]}"; do
    IFS='|' read -r area function_name sub_function module <<< "$module_key"
    local before_file="$OUTPUT_DIR/before.$$.txt"
    local after_file="$OUTPUT_DIR/after.$$.txt"
    list_packages_at_commit "$PRE_MERGE_SHA" "$area" "$function_name" "$sub_function" "$module" | sort > "$before_file"
    list_packages_at_commit "$MERGE_SHA" "$area" "$function_name" "$sub_function" "$module" | sort > "$after_file"
    if ! cmp -s "$before_file" "$after_file"; then
      module_reasons["$module_key"]="${module_reasons[$module_key]:-} package-added-or-removed"
    fi
    rm -f "$before_file" "$after_file"

    local unique_count
    unique_count="$(tr '|' '\n' <<< "${specs_per_module[$module_key]:-}" | sed '/^$/d' | sort -u | wc -l | tr -d ' ')"
    if (( unique_count > 1 )); then
      module_reasons["$module_key"]="${module_reasons[$module_key]:-} multiple-specifications"
    fi
  done

  local spec_key
  for spec_key in "${!changed_specs[@]}"; do
    IFS='|' read -r area function_name sub_function module package <<< "$spec_key"
    local package_dir="HEMS/$area/$function_name/$sub_function/$module/$package"
    [[ -d "$package_dir" ]] || continue
    local specification manifest logical old_version new_version
    specification="$(extract_specification "$area" "$module" "$package")"
    manifest="$package_dir/specification-manifest.yaml"
    logical="specification/$area/$function_name/$sub_function/$module/$specification"
    add_unique_line "$spec_key" "$AFFECTED_SPECIFICATIONS_FILE"

    if manifest_has_merge "$manifest"; then
      info "Already processed: $manifest"
      continue
    fi

    old_version="$(read_manifest_version "$manifest")"
    new_version=$((old_version + 1))
    if [[ "$APPLY_CHANGES" == true ]]; then
      write_manifest "$manifest" specification "$area" "$function_name" "$sub_function" "$module" "$package" "$specification" "$old_version" "$new_version" "$logical" specification "$GENERATED_UTC"
      info "Updated specification manifest: $manifest ($old_version -> $new_version)"
    else
      preview_manifest_update "$manifest" specification "$logical"
    fi
  done

  for module_key in "${!module_reasons[@]}"; do
    IFS='|' read -r area function_name sub_function module <<< "$module_key"
    local module_dir="HEMS/$area/$function_name/$sub_function/$module"
    [[ -d "$module_dir" ]] || continue
    local manifest_name manifest logical old_version new_version
    manifest_name="$(module_manifest_name "$area")"
    manifest="$module_dir/$manifest_name"
    logical="module/$area/$function_name/$sub_function/$module"
    add_unique_line "$module_key" "$UPDATED_MODULES_FILE"
    info "Module update reason [$module_key]:${module_reasons[$module_key]}"

    if manifest_has_merge "$manifest"; then
      info "Already processed: $manifest"
      continue
    fi

    old_version="$(read_manifest_version "$manifest")"
    new_version=$((old_version + 1))
    if [[ "$APPLY_CHANGES" == true ]]; then
      write_manifest "$manifest" module "$area" "$function_name" "$sub_function" "$module" "" "" "$old_version" "$new_version" "$logical" module "$GENERATED_UTC"
      info "Updated module manifest: $manifest ($old_version -> $new_version)"
    else
      preview_manifest_update "$manifest" module "$logical"
    fi
  done

  local baseline_created=false
  local tag_name
  tag_name="$(safe_name "hems-baseline-pr-${PR_NUMBER}-${MERGE_SHA:0:7}")"
  declare -A baseline_modules=()
  for module_key in "${!module_reasons[@]}"; do
    IFS='|' read -r area function_name sub_function module <<< "$module_key"
    if [[ -d "HEMS/$area/$function_name/$sub_function/$module" ]]; then
      baseline_modules["$function_name|$sub_function|$module"]=1
    fi
  done

  if (( ${#baseline_modules[@]} > 0 )); then
    baseline_created=true
  fi

  if [[ "$APPLY_CHANGES" == true && "$baseline_created" == true ]]; then
    local common_key
    for common_key in "${!baseline_modules[@]}"; do
      IFS='|' read -r function_name sub_function module <<< "$common_key"
      local baseline_dir="HEMS/BASELINES/$function_name/$sub_function/$module/$tag_name"
      local staging_dir="$OUTPUT_DIR/staging/$function_name/$sub_function/$module"
      rm -rf "$staging_dir"
      mkdir -p "$baseline_dir" "$staging_dir/HEMS"

      local included_file_list="$OUTPUT_DIR/included.$$.txt"
      : > "$included_file_list"
      local area
      for area in "${CONTROLLED_AREAS[@]}"; do
        local source="HEMS/$area/$function_name/$sub_function/$module"
        [[ -d "$source" ]] || continue
        local destination="$staging_dir/HEMS/$area/$function_name/$sub_function"
        mkdir -p "$destination"
        cp -R "$source" "$destination/"
        find "$source" -type f -print >> "$included_file_list"
      done
      sort -u -o "$included_file_list" "$included_file_list"

      local baseline_manifest="$baseline_dir/baseline-manifest.yaml"
      local checksum_file="$baseline_dir/checksums.sha256"
      local tag_details="$baseline_dir/tag-details.txt"
      local zip_file="$baseline_dir/${module}-${tag_name}.zip"

      {
        echo "baseline_tag: $(yaml_quote "$tag_name")"
        echo "repository: $(yaml_quote "$GH_REPO")"
        echo "pull_request: $(yaml_quote "$PR_NUMBER")"
        echo "pull_request_title: $(yaml_quote "$PR_TITLE")"
        echo "pre_merge_commit: $(yaml_quote "$PRE_MERGE_SHA")"
        echo "merge_commit: $(yaml_quote "$MERGE_SHA")"
        echo "generated_utc: $(yaml_quote "$GENERATED_UTC")"
        echo "function: $(yaml_quote "$function_name")"
        echo "sub_function: $(yaml_quote "$sub_function")"
        echo "module: $(yaml_quote "$module")"
        echo "included_files:"
        while IFS= read -r file; do
          [[ -n "$file" ]] && echo "  - $(yaml_quote "$file")"
        done < "$included_file_list"
      } > "$baseline_manifest"

      : > "$checksum_file"
      while IFS= read -r file; do
        [[ -n "$file" ]] || continue
        sha256sum "$file" >> "$checksum_file"
      done < "$included_file_list"

      {
        echo "HEMS module baseline"
        echo
        echo "Tag: $tag_name"
        echo "Repository: $GH_REPO"
        echo "Pull request: #$PR_NUMBER"
        echo "Pull request title: $PR_TITLE"
        echo "Main before merge: $PRE_MERGE_SHA"
        echo "Main after merge: $MERGE_SHA"
        echo "Function: $function_name"
        echo "Sub-function: $sub_function"
        echo "Module: $module"
        echo "ZIP: $zip_file"
      } > "$tag_details"

      cp "$baseline_manifest" "$checksum_file" "$tag_details" "$staging_dir/"
      create_zip_with_powershell "$staging_dir" "$zip_file"

      printf '%s\n' "$baseline_manifest" "$checksum_file" "$tag_details" "$zip_file" >> "$BASELINE_FILES_FILE"
      rm -f "$included_file_list"
    done
  elif [[ "$baseline_created" == true ]]; then
    info "PREVIEW: A baseline would be created with tag $tag_name"
  fi

  local changes_created=false
  if [[ -s "$UPDATED_MANIFESTS_FILE" || -s "$BASELINE_FILES_FILE" ]]; then
    changes_created=true
  fi
  if [[ "$APPLY_CHANGES" == false && -s "$VERSION_SUMMARY_FILE" ]]; then
    changes_created=true
  fi

  if [[ "$PUSH_CHANGES" == true && "$changes_created" == true ]]; then
    git config user.name "jenkins-hems-automation"
    git config user.email "jenkins-hems-automation@users.noreply.github.com"

    while IFS= read -r file; do [[ -n "$file" ]] && git add -- "$file"; done < "$UPDATED_MANIFESTS_FILE"
    while IFS= read -r file; do [[ -n "$file" ]] && git add -- "$file"; done < "$BASELINE_FILES_FILE"

    if ! git diff --cached --quiet; then
      local remote_main
      git fetch --no-tags origin "+refs/heads/$MAIN_BRANCH:refs/remotes/origin/$MAIN_BRANCH"
      remote_main="$(git rev-parse "refs/remotes/origin/$MAIN_BRANCH")"
      [[ "$remote_main" == "$MERGE_SHA" ]] || fail "main changed after the merge. Expected $MERGE_SHA, found $remote_main."
      git commit -m "Update HEMS manifests and baseline after PR #$PR_NUMBER"
      "$GH_EXE" auth setup-git
      git push origin "HEAD:$MAIN_BRANCH"
    fi
  fi

  if [[ "$CREATE_TAG" == true && "$baseline_created" == true ]]; then
    git show-ref --verify --quiet "refs/tags/$tag_name" && fail "Tag already exists: $tag_name"
    git tag -a "$tag_name" -m "HEMS baseline for PR #$PR_NUMBER and merge $MERGE_SHA"
    git push origin "refs/tags/$tag_name"
  fi

  {
    echo "MERGE_SHA=$MERGE_SHA"
    echo "PRE_MERGE_SHA=$PRE_MERGE_SHA"
    echo "PR_NUMBER=$PR_NUMBER"
    echo "APPLY_CHANGES=$APPLY_CHANGES"
    echo "PUSH_CHANGES=$PUSH_CHANGES"
    echo "CREATE_TAG=$CREATE_TAG"
    echo "CHANGES_CREATED=$changes_created"
    echo "BASELINE_CREATED=$baseline_created"
    echo "TAG_NAME=$tag_name"
  } > "$RESULT_FILE"

  echo
  separator
  echo "HEMS Module Baseline summary"
  separator
  cat "$RESULT_FILE"
  echo
  echo "Version summary:"
  if [[ -s "$VERSION_SUMMARY_FILE" ]]; then cat "$VERSION_SUMMARY_FILE"; else echo "No version changes detected."; fi
  separator
}

main "$@"
