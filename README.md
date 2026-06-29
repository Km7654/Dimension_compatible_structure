# Dimension Compatible HEMS Repository

This repository is a GitHub-based proof of concept for managing HEMS engineering content in a controlled, traceable, and release-ready structure.

The repository is designed to simulate baseline and delivery behavior similar to legacy configuration management tools by using:

- GitHub repository structure
- GitHub Actions workflows
- Pull request validation
- Delivery metadata/manifests
- Baseline manifests
- Git tags
- GitHub Releases
- Module-level and custom-scope release packages

---

## 1. Repository Purpose

The purpose of this repository is to manage HEMS content in a structured way so that:

- code files are stored in the correct code area
- module/model files are stored in the correct module area
- specification files are stored in the correct specification area
- required delivery files are present before release
- manifest files are generated and maintained
- released content can be packaged with release metadata
- baselines can be created using Git tags and GitHub Releases
- selected module-level or custom-scope packages can be released without downloading unrelated content

---

## 2. Repository Structure

The main engineering content is stored under the `HEMS` folder.

```text
.
├── .github/
│   └── workflows/
│       ├── structure-check.yml
│       ├── delivery-check.yml
│       ├── traceability-check.yml
│       ├── matlab-validation.yml
│       └── release-baseline.yml
├── HEMS/
│   ├── CODE_HEMS/
│   ├── MOD_HEMS/
│   ├── SPEC_HEMS/
│   └── BASELINES/
├── CODEOWNERS
├── .gitignore
├── .gitattributes
├── create_full_hems_structure.sh
├── generate_basic_manifests.sh
└── README.md
```

---

## 3. HEMS Engineering Areas

The `HEMS` folder contains three main content areas.

### 3.1 CODE_HEMS

Used for code-related files.

```text
HEMS/CODE_HEMS/<Function>/<Sub-function>/<Module>/
├── source/
├── include/
├── static-analysis/
├── unit-sil-results/
├── certification/
├── traceability/
└── code-manifest.yaml
```

Example:

```text
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/main.c
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/include/main.h
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/certification/ASXX_ADMX_CTL_certification_report.txt
```

---

### 3.2 MOD_HEMS

Used for module/model-related files.

```text
HEMS/MOD_HEMS/<Function>/<Sub-function>/<Module>/
├── model/
├── model-interface/
├── variant/
├── dictionary/
├── stimuli/
├── calibration/
├── analysis/
├── reports/
├── delivery/
├── sof/
├── mdt/
├── traceability/
└── module-manifest.yaml
```

Example:

```text
HEMS/MOD_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/model/ASXX_ADMX_CTL.slx
HEMS/MOD_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/reports/ASXX_ADMX_CTL_east_report.pdf
```

---

### 3.3 SPEC_HEMS

Used for specification-related files.

```text
HEMS/SPEC_HEMS/<Function>/<Sub-function>/<Module>/
├── source/
├── pdf/
├── comparison/
├── history/
├── crs/
├── sdt/
├── technical-facts/
├── traceability/
└── spec-manifest.yaml
```

Example:

```text
HEMS/SPEC_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/pdf/ASXX_ADMX_CTL_spec_document.pdf
HEMS/SPEC_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/crs/ASXX_ADMX_CTL_interface_spec.xml
```

---

## 4. Required Path Pattern

All engineering files under `HEMS` must follow this structure:

```text
HEMS/<AREA>/<Function>/<Sub-function>/<Module>/<Item>
```

Example:

```text
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/main.c
```

Breakdown:

```text
HEMS              = root engineering folder
CODE_HEMS         = engineering area
ASXX              = function
ASXX_ADMX         = sub-function
ASXX_ADMX_CTL     = module
source/main.c     = item/file
```

---

## 5. GitHub Actions Workflows

Workflow files are stored here:

```text
.github/workflows/
```

Current workflows:

```text
structure-check.yml
 delivery-check.yml
traceability-check.yml
matlab-validation.yml
release-baseline.yml
```

---

## 6. Structure Check Workflow

Workflow file:

```text
.github/workflows/structure-check.yml
```

Purpose:

- validates only files under `HEMS/`
- skips non-HEMS files such as README, scripts, `.github` workflow files, `.gitignore`, `.gitattributes`, etc.
- checks that files are stored in `CODE_HEMS`, `MOD_HEMS`, or `SPEC_HEMS`
- checks that the path follows `HEMS/AREA/Function/Sub-function/Module/Item`
- checks common file placement rules

Examples of valid paths:

```text
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/main.c
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/include/main.h
HEMS/MOD_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/model/ASXX_ADMX_CTL.slx
HEMS/SPEC_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/pdf/ASXX_ADMX_CTL_spec_document.pdf
```

Examples of invalid paths:

```text
HEMS/WRONG_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/file.txt
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/pdf/file.c
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/header.h
```

Expected result:

```text
Valid structure      → Structure Check passes
Wrong structure      → Structure Check fails
Non-HEMS root files  → skipped
```

---

## 7. Delivery Check Workflow

Workflow file:

```text
.github/workflows/delivery-check.yml
```

Purpose:

- checks whether required delivery files are present
- checks required folders
- checks that evidence folders contain real files
- does not treat `.keep` as valid delivery evidence

Important behavior:

If a required file such as certification evidence is deleted:

```text
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/certification/ASXX_ADMX_CTL_certification_report.txt
```

Expected result:

```text
Structure Check = PASS
Delivery Check  = FAIL
```

This is correct because:

```text
Structure Check checks folder/path correctness.
Delivery Check checks required file completeness.
```

---

## 8. Traceability Check Workflow

Workflow file:

```text
.github/workflows/traceability-check.yml
```

Purpose:

- checks manifest files
- checks required manifest fields
- checks traceability CSV files

Required manifest fields normally include:

```yaml
module:
type:
area:
function:
sub_function:
version:
delivery_cycle:
```

Required traceability file:

```text
traceability/trace_links.csv
```

Expected CSV header:

```text
source,target,link_type
```

---

## 9. MATLAB Validation Evidence Check

Workflow file:

```text
.github/workflows/matlab-validation.yml
```

Purpose:

- checks whether MATLAB/Simulink validation evidence exists
- checks whether model files and validation reports are present

Example expected model file:

```text
HEMS/MOD_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/model/ASXX_ADMX_CTL.slx
```

Example expected evidence folders:

```text
HEMS/MOD_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/reports/
HEMS/MOD_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/analysis/
```

This workflow checks evidence presence. It does not execute MATLAB.

---

## 10. Manifest Files

Manifest files are metadata files that describe package content.

This repository uses four manifest levels:

```text
code-manifest.yaml
module-manifest.yaml
spec-manifest.yaml
baseline-manifest.yaml
```

---

### 10.1 Code Manifest

Location:

```text
HEMS/CODE_HEMS/<Function>/<Sub-function>/<Module>/code-manifest.yaml
```

Example:

```yaml
module: ASXX_ADMX_CTL
type: code
area: CODE_HEMS
function: ASXX
sub_function: ASXX_ADMX
version: v1.0.0
delivery_cycle: MD31_01
commit: abc123
generated_by: GitHub Actions
generated_on: 2026-06-29T10:00:00Z
files:
  - source/main.c
  - include/main.h
  - static-analysis/ASXX_ADMX_CTL_lint_report.txt
  - unit-sil-results/ASXX_ADMX_CTL_sil_results.txt
  - certification/ASXX_ADMX_CTL_certification_report.txt
  - traceability/trace_links.csv
```

---

### 10.2 Module Manifest

Location:

```text
HEMS/MOD_HEMS/<Function>/<Sub-function>/<Module>/module-manifest.yaml
```

Example:

```yaml
module: ASXX_ADMX_CTL
type: module
area: MOD_HEMS
function: ASXX
sub_function: ASXX_ADMX
version: v1.0.0
delivery_cycle: MD31_01
files:
  - model/ASXX_ADMX_CTL.slx
  - reports/ASXX_ADMX_CTL_east_report.pdf
  - analysis/ASXX_ADMX_CTL_analysis_report.txt
```

---

### 10.3 Specification Manifest

Location:

```text
HEMS/SPEC_HEMS/<Function>/<Sub-function>/<Module>/spec-manifest.yaml
```

Example:

```yaml
module: ASXX_ADMX_CTL
type: specification
area: SPEC_HEMS
function: ASXX
sub_function: ASXX_ADMX
version: v1.0.0
delivery_cycle: MD31_01
files:
  - source/ASXX_ADMX_CTL_spec_source.xml
  - pdf/ASXX_ADMX_CTL_spec_document.pdf
  - crs/ASXX_ADMX_CTL_interface_spec.xml
```

---

### 10.4 Baseline Manifest

Location:

```text
HEMS/BASELINES/<version>/baseline-manifest.yaml
```

Example:

```text
HEMS/BASELINES/v1.0.0/baseline-manifest.yaml
```

This manifest lists all released files and metadata.

Example:

```yaml
baseline: v1.0.0
delivery_cycle: MD31_01
release_scope: full_hems
release_commit: abc123
branch: main
generated_by: GitHub Actions
generated_on: 2026-06-29T10:00:00Z

released_files:
  - path: HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/main.c
    area: CODE_HEMS
    function: ASXX
    sub_function: ASXX_ADMX
    module: ASXX_ADMX_CTL
    release_version: v1.0.0
    release_commit: abc123
    last_changed_commit: def456
    sha256: xxxxx
```

---

## 11. How Manifests Are Created

### 11.1 During Test Data Creation

Script:

```text
create_full_hems_structure.sh
```

Run:

```bash
bash create_full_hems_structure.sh
```

This creates dummy HEMS folders, dummy files, and basic manifests.

---

### 11.2 During Manual Manifest Generation

Script:

```text
generate_basic_manifests.sh
```

Run:

```bash
bash generate_basic_manifests.sh v1.0.0 MD31_01
```

This creates or updates:

```text
HEMS/CODE_HEMS/.../code-manifest.yaml
HEMS/MOD_HEMS/.../module-manifest.yaml
HEMS/SPEC_HEMS/.../spec-manifest.yaml
HEMS/BASELINES/v1.0.0/baseline-manifest.yaml
HEMS/BASELINES/v1.0.0/checksums.sha256
```

---

### 11.3 During Release/Baseline Creation

Workflow:

```text
.github/workflows/release-baseline.yml
```

This workflow generates or updates:

```text
code-manifest.yaml
module-manifest.yaml
spec-manifest.yaml
baseline-manifest.yaml
checksums.sha256
```

It also creates:

```text
Git tag
GitHub Release
Release ZIP package
Release manifest asset
Checksum asset
```

---

## 12. Baseline and Release Concept

Recommended rule:

```text
One official baseline = One Git tag = One GitHub Release
```

Example:

```text
Tag: v1.0.0
Release: HEMS Baseline v1.0.0
```

Do not modify old baseline tags. If a correction is needed, create a new baseline version.

Example:

```text
v1.0.0 = original baseline
v1.0.1 = corrected baseline
```

---

## 13. Release Baseline Workflow

Workflow file:

```text
.github/workflows/release-baseline.yml
```

Purpose:

- create Git tag
- create GitHub Release
- generate package-level manifests
- generate baseline manifest
- generate checksum file
- create ZIP package
- support release scope selection

---

## 14. How to Run Release Baseline Workflow

Go to:

```text
GitHub → Actions → Release Baseline → Run workflow
```

Fill the required inputs.

---

### 14.1 Full HEMS Release

Use this when releasing all HEMS content.

```text
version: v1.0.0
delivery_cycle: MD31_01
release_scope: full_hems
selected_path: leave blank
approved_custom_paths: leave blank
```

This includes all files under:

```text
HEMS/CODE_HEMS
HEMS/MOD_HEMS
HEMS/SPEC_HEMS
```

Expected release assets:

```text
baseline-v1.0.0.zip
baseline-manifest-v1.0.0.yaml
checksums-v1.0.0.sha256
```

---

### 14.2 Code Module Release

Use this when releasing only one code module.

```text
version: v1.0.1
delivery_cycle: MD31_01
release_scope: code_module
selected_path: HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL
approved_custom_paths: leave blank
```

---

### 14.3 Model/Module Release

Use this when releasing only one model/module package.

```text
version: v1.0.2
delivery_cycle: MD31_01
release_scope: model_module
selected_path: HEMS/MOD_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL
approved_custom_paths: leave blank
```

---

### 14.4 Specification Release

Use this when releasing only one specification package.

```text
version: v1.0.3
delivery_cycle: MD31_01
release_scope: spec_module
selected_path: HEMS/SPEC_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL
approved_custom_paths: leave blank
```

---

### 14.5 Approved Custom Paths Release

Use this when releasing selected folders/files.

```text
version: v1.0.4
delivery_cycle: MD31_01
release_scope: approved_custom_paths
selected_path: leave blank
approved_custom_paths: HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source,HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/include
```

Rules:

- use comma-separated paths
- paths must be under `HEMS/`
- use forward slashes `/`
- folders and files are both allowed

Valid examples:

```text
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source
HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/main.c
HEMS/SPEC_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/pdf
```

Invalid examples:

```text
dummy.sh
README.md
.github/workflows/structure-check.yml
HEMS_WRONG/file.txt
```

---

## 15. What Full HEMS Release Includes

When `release_scope` is:

```text
full_hems
```

The release includes:

```text
HEMS/CODE_HEMS/
HEMS/MOD_HEMS/
HEMS/SPEC_HEMS/
```

It does not include:

```text
.github/
README.md
.gitignore
.gitattributes
scripts outside HEMS
```

The ZIP contains:

```text
baseline-selection-v1.0.0/
├── HEMS/
│   ├── CODE_HEMS/
│   ├── MOD_HEMS/
│   └── SPEC_HEMS/
├── baseline-manifest-v1.0.0.yaml
└── checksums-v1.0.0.sha256
```

---

## 16. How to Add Data

Data can be added in two ways.

---

### 16.1 Add Everything in One Go

Recommended for initial migration or testing.

```bash
bash create_full_hems_structure.sh
bash generate_basic_manifests.sh v1.0.0 MD31_01
git add -A
git commit -m "Add full HEMS data and manifests"
git push -u origin HEAD
```

Then check:

```text
GitHub → Actions
```

Expected:

```text
Structure Check = PASS
Delivery Check = PASS
Traceability Check = PASS
MATLAB Validation Evidence Check = PASS
```

---

### 16.2 Add Data One by One

Recommended for normal daily changes.

Example: adding one code file.

```bash
echo "int new_function(void) { return 1; }" > HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/new_file.c
bash generate_basic_manifests.sh v1.0.1 MD31_02
git add HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/new_file.c
git add HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/code-manifest.yaml
git commit -m "Add new code file for ASXX_ADMX_CTL"
git push -u origin HEAD
```

---

## 17. Testing Scenarios

### 17.1 Test Missing Required File

Delete certification evidence:

```bash
rm HEMS/CODE_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/certification/ASXX_ADMX_CTL_certification_report.txt
git add -A
git commit -m "Test missing certification evidence"
git push -u origin HEAD
```

Expected:

```text
Structure Check = PASS
Delivery Check = FAIL
```

---

### 17.2 Test Wrong Folder Structure

Create a wrong folder:

```bash
mkdir -p HEMS/WRONG_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source
echo "bad file" > HEMS/WRONG_HEMS/ASXX/ASXX_ADMX/ASXX_ADMX_CTL/source/bad.txt
git add -A
git commit -m "Test invalid HEMS structure"
git push -u origin HEAD
```

Expected:

```text
Structure Check = FAIL
```

---

## 18. Branch and Pull Request Flow

Recommended branch flow:

```bash
git checkout main
git pull origin main
git checkout -b feature/my-change
```

After changes:

```bash
git add -A
git commit -m "Describe change"
git push -u origin HEAD
```

Then create a Pull Request into:

```text
main
```

Before merge, the following should pass:

```text
Structure Check
Delivery Check
Traceability Check
MATLAB Validation Evidence Check
```

---

## 19. Branch Protection Recommendation

Recommended branch protection for `main`:

- require pull request review before merge
- require status checks to pass
- require Structure Check
- require Delivery Check
- require Traceability Check
- optionally require MATLAB Validation Evidence Check

This ensures important changes are reviewed and validated before merging.

---

## 20. Fix Branch From Baseline Tag

If a fix is needed from a released baseline:

```bash
git checkout -b fix/v1.0.0-issue v1.0.0
```

Make fix, then:

```bash
git add -A
git commit -m "Fix issue from baseline v1.0.0"
git push -u origin HEAD
```

After validation, create a new baseline:

```text
v1.0.1
```

---

## 21. Useful Git Commands

Check current branch:

```bash
git branch --show-current
```

Check status:

```bash
git status
```

Pull latest:

```bash
git pull origin main
```

Push current branch safely:

```bash
git push -u origin HEAD
```

Stage all changes:

```bash
git add -A
```

Commit:

```bash
git commit -m "Your message"
```

View recent commits:

```bash
git log --oneline -n 5
```

---

## 22. Troubleshooting

### 22.1 Workflow did not run

Check branch trigger.

If workflow supports:

```yaml

'test/**'
```

then branch must be like:

```text
test/my-branch
```

A branch named only `testing` does not match `test/**`.

---

### 22.2 Run Workflow button not visible

Check:

- workflow has `workflow_dispatch`
- workflow file exists on `main`
- YAML has no HTML symbols like `&gt;`, `&lt;`, `&amp;`
- user has write access

---

### 22.3 Structure Check passes after deleting required file

This is expected.

Missing required file should be caught by:

```text
Delivery Check
```

not by:

```text
Structure Check
```

---

### 22.4 Git push rejected as non-fast-forward

Run:

```bash
git pull origin main --rebase
git push origin main
```

If conflicts are difficult, create a backup branch before resolving.

---

## 23. Current Capability Summary

This repository currently supports:

- structured HEMS folder layout
- structure validation
- delivery completeness validation
- traceability validation
- MATLAB evidence validation
- manifest generation
- baseline manifest generation
- checksum generation
- Git tag creation
- GitHub Release creation
- full HEMS release package
- module-level release package
- specification-level release package
- approved custom-path release package
- baseline package download without unrelated content

---

## 24. Recommended First-Time Test Flow

Run this from repo root:

```bash
git checkout main
git pull origin main
git checkout -b test/full-hems-demo

bash create_full_hems_structure.sh
bash generate_basic_manifests.sh v1.0.0 MD31_01

git add -A
git commit -m "Add full HEMS demo structure"
git push -u origin HEAD
```

Then check:

```text
GitHub → Actions
```

After all checks pass, merge to `main`.

Then run:

```text
Actions → Release Baseline → Run workflow
```

Use:

```text
version: v1.0.0
delivery_cycle: MD31_01
release_scope: full_hems
selected_path: leave blank
approved_custom_paths: leave blank
```

Expected release assets:

```text
baseline-v1.0.0.zip
baseline-manifest-v1.0.0.yaml
checksums-v1.0.0.sha256
```

---

## 25. Important Notes

- `.keep` files are only folder placeholders and are not considered real evidence.
- All release paths must be under `HEMS/`.
- Do not reuse the same baseline version.
- Old baseline tags should remain unchanged.
- New changes should create a new baseline version.
- Manifest files should be generated or updated before release.
- Baseline manifest is the main audit file for released content.
