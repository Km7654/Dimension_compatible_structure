#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Auto Codebeamer Pull Request and Merge
#
# Purpose:
#   1. Check the latest feature-branch commit for #TrackerID.
#   2. Identify exactly one changed CODE_HEMS .c file.
#   3. Read the current specification version from main.
#   4. Generate the Pull Request title and merge message.
#   5. Create or update a Pull Request to main.
#   6. Optionally merge the Pull Request.
#
# Requirements:
#   - Git
#   - Git Bash
#   - GitHub CLI
#   - GitHub CLI authenticated with repository write permission
#
# Usage:
#   ./jenkins/scripts/auto-codebeamer-pr-merge.sh [BRANCH_NAME]
#
# Safe test mode:
#   AUTO_MERGE=false ./jenkins/scripts/auto-codebeamer-pr-merge.sh feature/a
#
# Automatic merge mode:
#   AUTO_MERGE=true ./jenkins/scripts/auto-codebeamer-pr-merge.sh feature/a
#
# Jenkins environment variables supported:
#   BRANCH_TO_PROCESS
#   GH_REPO
#   GH_EXE
#   AUTO_MERGE
#   DELETE_BRANCH_AFTER_MERGE
# =============================================================================

MAIN_BRANCH="${MAIN_BRANCH:-main}"

GH_REPO="${GH_REPO:-Km7654/Dimension_compatible_structure}"

GH_EXE="${GH_EXE:-/c/Users/kss932546/Tools/GitHubCLI/bin/gh.exe}"

AUTO_MERGE="${AUTO_MERGE:-false}"

DELETE_BRANCH_AFTER_MERGE="${DELETE_BRANCH_AFTER_MERGE:-false}"

WAIT_FOR_MERGE_ATTEMPTS="${WAIT_FOR_MERGE_ATTEMPTS:-60}"

WAIT_FOR_MERGE_SECONDS="${WAIT_FOR_MERGE_SECONDS:-5}"

BRANCH_ARGUMENT="${1:-}"

BRANCH_NAME="${BRANCH_TO_PROCESS:-$BRANCH_ARGUMENT}"

OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:-jenkins-output/auto-codebeamer}"

PR_BODY_FILE="$OUTPUT_DIRECTORY/pr-body.md"

MERGE_BODY_FILE="$OUTPUT_DIRECTORY/merge-body.md"

RESULT_FILE="$OUTPUT_DIRECTORY/result.env"


print_separator() {
  echo "============================================================"
}


fail() {
  local message="$1"

  echo ""
  echo "ERROR: $message"
  exit 1
}


normalize_boolean() {
  local value="$1"

  case "${value,,}" in
    true|yes|1|on)
      echo "true"
      ;;

    false|no|0|off|"")
      echo "false"
      ;;

    *)
      fail "Invalid Boolean value: $value"
      ;;
  esac
}


verify_required_tools() {
  local tool

  for tool in git awk grep sed basename dirname tr; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      fail "Required tool is missing: $tool"
    fi
  done

  if [[ ! -x "$GH_EXE" ]] && [[ ! -f "$GH_EXE" ]]; then
    fail "GitHub CLI executable was not found: $GH_EXE"
  fi

  echo "Git version:"
  git --version

  echo ""
  echo "GitHub CLI version:"
  "$GH_EXE" --version
}


verify_repository() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    fail "The current directory is not a Git working tree."
  fi

  if [[ ! -d "HEMS" ]]; then
    fail "HEMS directory was not found. Run this script from the repository root."
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    fail "The Git remote named 'origin' is not configured."
  fi
}


resolve_branch_name() {
  if [[ -z "$BRANCH_NAME" ]]; then
    BRANCH_NAME="$(git branch --show-current)"
  fi

  if [[ -z "$BRANCH_NAME" ]]; then
    fail "Unable to determine the feature branch name."
  fi

  if [[ "$BRANCH_NAME" == "$MAIN_BRANCH" ]]; then
    fail "This script must not run against the '$MAIN_BRANCH' branch."
  fi

  if [[ "$BRANCH_NAME" == "HEAD" ]]; then
    fail "A detached HEAD was detected. Supply the feature branch name as argument 1."
  fi

  echo "Feature branch: $BRANCH_NAME"
  echo "Target branch:  $MAIN_BRANCH"
}


verify_github_access() {
  echo "Checking GitHub CLI authentication."

  if ! "$GH_EXE" auth status >/dev/null 2>&1; then
    fail "GitHub CLI is not authenticated for the Jenkins Windows account."
  fi

  echo "Checking repository permission."

  local repository_data
  repository_data="$(
    "$GH_EXE" repo view "$GH_REPO" \
      --json nameWithOwner,viewerPermission
  )"

  echo "$repository_data"

  local permission
  permission="$(
    "$GH_EXE" repo view "$GH_REPO" \
      --json viewerPermission \
      --jq '.viewerPermission'
  )"

  case "$permission" in
    ADMIN|MAINTAIN|WRITE)
      echo "Repository permission is sufficient: $permission"
      ;;

    *)
      fail "Repository write access is required. Current permission: $permission"
      ;;
  esac
}


fetch_required_branches() {
  echo ""
  echo "Fetching the latest branches from origin."

  git fetch \
    --no-tags \
    --prune \
    origin \
    "+refs/heads/${MAIN_BRANCH}:refs/remotes/origin/${MAIN_BRANCH}" \
    "+refs/heads/${BRANCH_NAME}:refs/remotes/origin/${BRANCH_NAME}"

  if ! git rev-parse \
    --verify \
    "refs/remotes/origin/${MAIN_BRANCH}^{commit}" \
    >/dev/null 2>&1
  then
    fail "Remote main branch was not found: origin/$MAIN_BRANCH"
  fi

  if ! git rev-parse \
    --verify \
    "refs/remotes/origin/${BRANCH_NAME}^{commit}" \
    >/dev/null 2>&1
  then
    fail "Remote feature branch was not found: origin/$BRANCH_NAME"
  fi

  local remote_branch_sha
  remote_branch_sha="$(
    git rev-parse "refs/remotes/origin/${BRANCH_NAME}"
  )"

  local local_head_sha
  local_head_sha="$(git rev-parse HEAD)"

  if [[ "$local_head_sha" != "$remote_branch_sha" ]]; then
    echo ""
    echo "Local HEAD:          $local_head_sha"
    echo "Remote branch HEAD: $remote_branch_sha"
    echo ""
    echo "Checking out the latest remote feature branch revision."

    git checkout \
      --force \
      -B "$BRANCH_NAME" \
      "refs/remotes/origin/${BRANCH_NAME}"
  fi
}


detect_tracker_id() {
  LATEST_COMMIT_MESSAGE="$(
    git log \
      -1 \
      --format=%B \
      "refs/remotes/origin/${BRANCH_NAME}"
  )"

  echo ""
  print_separator
  echo "Latest feature-branch commit message"
  print_separator
  echo "$LATEST_COMMIT_MESSAGE"
  print_separator

  TRACKER_ID="$(
    printf '%s\n' "$LATEST_COMMIT_MESSAGE" \
      | grep -oE '(^|[^A-Za-z0-9])#[0-9]{3,10}([^0-9]|$)' \
      | head -n 1 \
      | grep -oE '[0-9]{3,10}' \
      || true
  )"

  if [[ -z "$TRACKER_ID" ]]; then
    echo ""
    echo "No valid #TrackerID was found in the latest commit."
    echo "Expected format example: #12345"
    echo ""
    echo "Automatic Pull Request processing was skipped."

    mkdir -p "$OUTPUT_DIRECTORY"

    {
      echo "SHOULD_PROCESS=false"
      echo "SKIP_REASON=no_tracker_id"
      echo "BRANCH_NAME=$BRANCH_NAME"
    } > "$RESULT_FILE"

    exit 0
  fi

  echo "Detected Codebeamer Tracker ID: #$TRACKER_ID"
}


detect_changed_code_file() {
  CHANGED_FILES="$(
    git diff \
      --name-only \
      --diff-filter=ACMR \
      "refs/remotes/origin/${MAIN_BRANCH}...refs/remotes/origin/${BRANCH_NAME}"
  )"

  echo ""
  print_separator
  echo "Changed files against $MAIN_BRANCH"
  print_separator

  if [[ -z "$CHANGED_FILES" ]]; then
    echo "No changed files were detected."
    fail "The feature branch does not contain changes against $MAIN_BRANCH."
  fi

  printf '%s\n' "$CHANGED_FILES"

  mapfile -t CODE_FILES < <(
    printf '%s\n' "$CHANGED_FILES" \
      | awk '
          /^HEMS\/CODE_HEMS\// &&
          tolower($0) ~ /\.c$/ {
              print
          }
        ' \
      | sort -u
  )

  if [[ "${#CODE_FILES[@]}" -eq 0 ]]; then
    fail "A #TrackerID was found, but no changed CODE_HEMS .c file was found."
  fi

  if [[ "${#CODE_FILES[@]}" -ne 1 ]]; then
    echo ""
    echo "Changed CODE_HEMS .c files:"

    local code_file

    for code_file in "${CODE_FILES[@]}"; do
      echo "  - $code_file"
    done

    fail "Exactly one CODE_HEMS .c file is required per automatic merge."
  fi

  CODE_FILE_PATH="${CODE_FILES[0]}"

  if [[ ! -f "$CODE_FILE_PATH" ]]; then
    fail "The detected code file does not exist in the checked-out branch: $CODE_FILE_PATH"
  fi

  IFS="/" read -r \
    HEMS_DIRECTORY \
    AREA_NAME \
    FUNCTION_NAME \
    SUB_FUNCTION \
    MODULE_NAME \
    PACKAGE_NAME \
    REMAINING_PATH \
    <<< "$CODE_FILE_PATH"

  if [[ "$HEMS_DIRECTORY" != "HEMS" ]]; then
    fail "Invalid HEMS root in code path: $CODE_FILE_PATH"
  fi

  if [[ "$AREA_NAME" != "CODE_HEMS" ]]; then
    fail "Invalid controlled area in code path: $CODE_FILE_PATH"
  fi

  CODE_FILE_NAME="$(basename "$CODE_FILE_PATH")"

  PACKAGE_FOLDER="$(
    dirname "$CODE_FILE_PATH"
  )"

  SPECIFICATION_MANIFEST="$PACKAGE_FOLDER/specification-manifest.yaml"

  echo ""
  echo "Detected code file:"
  echo "  $CODE_FILE_PATH"

  echo ""
  echo "Function:"
  echo "  $FUNCTION_NAME"

  echo ""
  echo "Sub-function:"
  echo "  $SUB_FUNCTION"

  echo ""
  echo "Module:"
  echo "  $MODULE_NAME"

  echo ""
  echo "Package:"
  echo "  $PACKAGE_NAME"
}


read_manifest_version_from_main() {
  MANIFEST_TEXT=""

  if git cat-file \
    -e \
    "refs/remotes/origin/${MAIN_BRANCH}:${SPECIFICATION_MANIFEST}" \
    2>/dev/null
  then
    MANIFEST_TEXT="$(
      git show \
        "refs/remotes/origin/${MAIN_BRANCH}:${SPECIFICATION_MANIFEST}"
    )"
  else
    echo ""
    echo "The specification manifest does not exist on main yet:"
    echo "  $SPECIFICATION_MANIFEST"
    echo "The current version will be treated as 0."
  fi

  CURRENT_VERSION="$(
    printf '%s\n' "$MANIFEST_TEXT" \
      | awk '
          /^[[:space:]]*version:[[:space:]]*/ {
              value = $0
              sub(/^[[:space:]]*version:[[:space:]]*/, "", value)
              gsub(/["'\'']/, "", value)
              gsub(/[[:space:]]/, "", value)

              if (value ~ /^[0-9]+$/) {
                  print value
                  exit
              }
          }
        '
  )"

  CURRENT_VERSION="${CURRENT_VERSION:-0}"

  if [[ ! "$CURRENT_VERSION" =~ ^[0-9]+$ ]]; then
    fail "The current specification version is not a whole number: $CURRENT_VERSION"
  fi

  NEXT_VERSION=$((CURRENT_VERSION + 1))

  MERGE_SUBJECT="#${TRACKER_ID} ${CODE_FILE_NAME} ${NEXT_VERSION}"

  echo ""
  print_separator
  echo "Version and merge information"
  print_separator
  echo "Specification manifest:"
  echo "  $SPECIFICATION_MANIFEST"
  echo ""
  echo "Current version on main:"
  echo "  $CURRENT_VERSION"
  echo ""
  echo "Expected version after merge:"
  echo "  $NEXT_VERSION"
  echo ""
  echo "Pull Request title and merge subject:"
  echo "  $MERGE_SUBJECT"
}


prepare_output_files() {
  mkdir -p "$OUTPUT_DIRECTORY"

  cat > "$PR_BODY_FILE" <<EOF
Automatic Pull Request created from a feature-branch commit containing a Codebeamer Tracker ID.

## Traceability

- Tracker: #${TRACKER_ID}
- Code file: ${CODE_FILE_NAME}
- Code file path: ${CODE_FILE_PATH}
- Function: ${FUNCTION_NAME}
- Sub-function: ${SUB_FUNCTION}
- Module: ${MODULE_NAME}
- Package: ${PACKAGE_NAME}

## Version information

- Main-only specification manifest: ${SPECIFICATION_MANIFEST}
- Current specification version on main: ${CURRENT_VERSION}
- Expected specification version after merge: ${NEXT_VERSION}

## Generated merge subject

${MERGE_SUBJECT}

The feature branch does not modify automation-managed manifest files.

The separate post-merge baseline process updates the applicable manifests after this Pull Request is merged.
EOF

  cat > "$MERGE_BODY_FILE" <<EOF
Codebeamer tracker: #${TRACKER_ID}

Code file: ${CODE_FILE_NAME}
Code file path: ${CODE_FILE_PATH}
Function: ${FUNCTION_NAME}
Sub-function: ${SUB_FUNCTION}
Module: ${MODULE_NAME}
Package: ${PACKAGE_NAME}
Specification manifest: ${SPECIFICATION_MANIFEST}
Previous specification version: ${CURRENT_VERSION}
Expected specification version after merge: ${NEXT_VERSION}

Automatic merge initiated because the latest feature-branch commit contains #${TRACKER_ID}.

The specification manifest is updated separately by the post-merge baseline process.
EOF
}


create_or_update_pull_request() {
  EXISTING_PR_NUMBER="$(
    "$GH_EXE" pr list \
      --repo "$GH_REPO" \
      --base "$MAIN_BRANCH" \
      --head "$BRANCH_NAME" \
      --state open \
      --json number \
      --jq '.[0].number // empty'
  )"

  if [[ -n "$EXISTING_PR_NUMBER" ]]; then
    PR_NUMBER="$EXISTING_PR_NUMBER"

    echo ""
    echo "Updating existing Pull Request #$PR_NUMBER."

    "$GH_EXE" pr edit "$PR_NUMBER" \
      --repo "$GH_REPO" \
      --title "$MERGE_SUBJECT" \
      --body-file "$PR_BODY_FILE"
  else
    echo ""
    echo "Creating Pull Request from $BRANCH_NAME to $MAIN_BRANCH."

    "$GH_EXE" pr create \
      --repo "$GH_REPO" \
      --base "$MAIN_BRANCH" \
      --head "$BRANCH_NAME" \
      --title "$MERGE_SUBJECT" \
      --body-file "$PR_BODY_FILE"

    PR_NUMBER="$(
      "$GH_EXE" pr list \
        --repo "$GH_REPO" \
        --base "$MAIN_BRANCH" \
        --head "$BRANCH_NAME" \
        --state open \
        --json number \
        --jq '.[0].number // empty'
    )"
  fi

  if [[ -z "$PR_NUMBER" ]]; then
    fail "Unable to determine the Pull Request number."
  fi

  echo "Using Pull Request #$PR_NUMBER."
}


merge_pull_request_if_enabled() {
  AUTO_MERGE="$(
    normalize_boolean "$AUTO_MERGE"
  )"

  DELETE_BRANCH_AFTER_MERGE="$(
    normalize_boolean "$DELETE_BRANCH_AFTER_MERGE"
  )"

  if [[ "$AUTO_MERGE" != "true" ]]; then
    echo ""
    print_separator
    echo "Safe test mode"
    print_separator
    echo "The Pull Request was created or updated successfully."
    echo "Automatic merge is disabled."
    echo ""
    echo "To enable automatic merge, set:"
    echo "  AUTO_MERGE=true"
    return
  fi

  local branch_sha

  branch_sha="$(
    git rev-parse \
      "refs/remotes/origin/${BRANCH_NAME}"
  )"

  echo ""
  echo "Submitting merge for Pull Request #$PR_NUMBER."
  echo "Expected feature-branch commit: $branch_sha"

  local merge_arguments=(
    pr
    merge
    "$PR_NUMBER"
    --repo
    "$GH_REPO"
    --merge
    --subject
    "$MERGE_SUBJECT"
    --body-file
    "$MERGE_BODY_FILE"
    --match-head-commit
    "$branch_sha"
  )

  if [[ "$DELETE_BRANCH_AFTER_MERGE" == "true" ]]; then
    merge_arguments+=(--delete-branch)
  fi

  "$GH_EXE" "${merge_arguments[@]}"

  echo "The merge command was submitted."
}


confirm_merge_if_enabled() {
  if [[ "$AUTO_MERGE" != "true" ]]; then
    MERGE_COMMIT_SHA=""
    return
  fi

  echo ""
  echo "Waiting for Pull Request #$PR_NUMBER to reach merged state."

  local attempt
  local pr_state
  local merged_at

  MERGE_COMMIT_SHA=""

  for attempt in $(
    seq 1 "$WAIT_FOR_MERGE_ATTEMPTS"
  ); do
    pr_state="$(
      "$GH_EXE" pr view "$PR_NUMBER" \
        --repo "$GH_REPO" \
        --json state \
        --jq '.state'
    )"

    merged_at="$(
      "$GH_EXE" pr view "$PR_NUMBER" \
        --repo "$GH_REPO" \
        --json mergedAt \
        --jq '.mergedAt // empty'
    )"

    MERGE_COMMIT_SHA="$(
      "$GH_EXE" pr view "$PR_NUMBER" \
        --repo "$GH_REPO" \
        --json mergeCommit \
        --jq '.mergeCommit.oid // empty'
    )"

    echo "Attempt $attempt/$WAIT_FOR_MERGE_ATTEMPTS: state=$pr_state"

    if [[ "$pr_state" == "MERGED" ]] \
      && [[ -n "$merged_at" ]] \
      && [[ -n "$MERGE_COMMIT_SHA" ]]
    then
      echo "Pull Request #$PR_NUMBER was merged successfully."
      echo "Merge commit: $MERGE_COMMIT_SHA"
      return
    fi

    if [[ "$pr_state" == "CLOSED" ]] \
      && [[ -z "$merged_at" ]]
    then
      fail "Pull Request #$PR_NUMBER was closed without merging."
    fi

    if [[ "$attempt" -lt "$WAIT_FOR_MERGE_ATTEMPTS" ]]; then
      sleep "$WAIT_FOR_MERGE_SECONDS"
    fi
  done

  fail "Pull Request #$PR_NUMBER was not confirmed as merged within the configured wait period."
}


write_result_file() {
  {
    echo "SHOULD_PROCESS=true"
    echo "TRACKER_ID=$TRACKER_ID"
    echo "BRANCH_NAME=$BRANCH_NAME"
    echo "PR_NUMBER=$PR_NUMBER"
    echo "CODE_FILE_PATH=$CODE_FILE_PATH"
    echo "CODE_FILE_NAME=$CODE_FILE_NAME"
    echo "FUNCTION_NAME=$FUNCTION_NAME"
    echo "SUB_FUNCTION=$SUB_FUNCTION"
    echo "MODULE_NAME=$MODULE_NAME"
    echo "PACKAGE_NAME=$PACKAGE_NAME"
    echo "SPECIFICATION_MANIFEST=$SPECIFICATION_MANIFEST"
    echo "CURRENT_VERSION=$CURRENT_VERSION"
    echo "NEXT_VERSION=$NEXT_VERSION"
    echo "MERGE_SUBJECT=$MERGE_SUBJECT"
    echo "AUTO_MERGE=$AUTO_MERGE"
    echo "MERGE_COMMIT_SHA=$MERGE_COMMIT_SHA"
  } > "$RESULT_FILE"
}


print_summary() {
  echo ""
  print_separator
  echo "Auto Codebeamer PR and Merge summary"
  print_separator
  echo "Tracker ID:             #$TRACKER_ID"
  echo "Feature branch:         $BRANCH_NAME"
  echo "Target branch:          $MAIN_BRANCH"
  echo "Code file:              $CODE_FILE_PATH"
  echo "Specification manifest: $SPECIFICATION_MANIFEST"
  echo "Version:                $CURRENT_VERSION -> $NEXT_VERSION"
  echo "Pull Request:           #$PR_NUMBER"
  echo "Automatic merge:        $AUTO_MERGE"

  if [[ -n "$MERGE_COMMIT_SHA" ]]; then
    echo "Merge commit:           $MERGE_COMMIT_SHA"
  else
    echo "Merge commit:           not created"
  fi

  echo "Result file:            $RESULT_FILE"
  print_separator
}


main() {
  print_separator
  echo "Auto Codebeamer Pull Request and Merge"
  print_separator
  echo "Working directory: $(pwd)"
  echo ""

  verify_required_tools
  verify_repository
  resolve_branch_name
  verify_github_access
  fetch_required_branches
  detect_tracker_id
  detect_changed_code_file
  read_manifest_version_from_main
  prepare_output_files
  create_or_update_pull_request
  merge_pull_request_if_enabled
  confirm_merge_if_enabled
  write_result_file
  print_summary
}


main "$@"
