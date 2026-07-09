#!/usr/bin/env bash

set -euo pipefail

VERSION="${1:-v1.0.0}"
DELIVERY_CYCLE="${2:-MD31_01}"

MODULES=(
  "ASXX/ASXX_ADMX/ASXX_ADMX_CTL"
  "ASXX/ASXX_DGNX/ASXX_DGNX_CTL"
  "ATXX/ATXX_MAIN/ATXX_MAIN_CTL"
)

mkdir -p HEMS/CODE_HEMS
mkdir -p HEMS/MOD_HEMS
mkdir -p HEMS/SPEC_HEMS
mkdir -p HEMS/BASELINES
mkdir -p HEMS/DELIVERY_REQUESTS
mkdir -p HEMS/INCOMING

create_trace_file() {
  local file="$1"

  cat > "$file" <<EOF
source,target,link_type
spec,module,satisfies
module,code,generates
code,baseline,released_in
EOF
}

create_code_package() {
  local function_name="$1"
  local sub_function="$2"
  local module="$3"
  local dir="HEMS/CODE_HEMS/$function_name/$sub_function/$module"

  mkdir -p "$dir"

  cat > "$dir/${module}.c" <<EOF
#include "${module}.h"

int ${module}_main(void)
{
    return 0;
}
EOF

  cat > "$dir/${module}.h" <<EOF
#ifndef ${module}_H
#define ${module}_H

int ${module}_main(void);

#endif
EOF

  cat > "$dir/${module}_compiler_log.txt" <<EOF
Compiler log for $module
Status: PASS
EOF

  cat > "$dir/${module}_static_analysis_report.txt" <<EOF
Static analysis report for $module
Status: PASS
EOF

  cat > "$dir/${module}_sil_results.txt" <<EOF
SIL/unit test result for $module
Status: PASS
EOF

  cat > "$dir/${module}_certification_report.txt" <<EOF
Certification evidence for $module
Status: AVAILABLE
EOF

  create_trace_file "$dir/trace_links.csv"

  cat > "$dir/code-manifest.yaml" <<EOF
module: $module
type: code
area: CODE_HEMS
function: $function_name
sub_function: $sub_function
version: $VERSION
delivery_cycle: $DELIVERY_CYCLE
files:
  - ${module}.c
  - ${module}.h
  - ${module}_compiler_log.txt
  - ${module}_static_analysis_report.txt
  - ${module}_sil_results.txt
  - ${module}_certification_report.txt
  - trace_links.csv
EOF
}

create_module_package() {
  local function_name="$1"
  local sub_function="$2"
  local module="$3"
  local dir="HEMS/MOD_HEMS/$function_name/$sub_function/$module"

  mkdir -p "$dir"

  cat > "$dir/${module}.slx" <<EOF
Dummy Simulink model placeholder for $module
EOF

  cat > "$dir/${module}_dictionary.sldd" <<EOF
Dummy Simulink data dictionary placeholder for $module
EOF

  cat > "$dir/${module}_interface.xlsx" <<EOF
Dummy interface file placeholder for $module
EOF

  cat > "$dir/${module}_variant.xlsx" <<EOF
Dummy variant file placeholder for $module
EOF

  cat > "$dir/${module}_stimuli.mat" <<EOF
Dummy stimuli file placeholder for $module
EOF

  cat > "$dir/${module}_calibration.html" <<EOF
<html><body>Calibration evidence for $module</body></html>
EOF

  cat > "$dir/${module}_analysis_report.txt" <<EOF
Analysis report for $module
Status: PASS
EOF

  cat > "$dir/${module}_east_report.pdf" <<EOF
Dummy EAST report placeholder for $module
EOF

  cat > "$dir/${module}_delivery_package.zip" <<EOF
Dummy delivery package placeholder for $module
EOF

  cat > "$dir/${module}_sof_reference.txt" <<EOF
SOF reference for $module
EOF

  cat > "$dir/${module}_mdt_reference.txt" <<EOF
MDT reference for $module
EOF

  create_trace_file "$dir/trace_links.csv"

  cat > "$dir/module-manifest.yaml" <<EOF
module: $module
type: module
area: MOD_HEMS
function: $function_name
sub_function: $sub_function
version: $VERSION
delivery_cycle: $DELIVERY_CYCLE
files:
  - ${module}.slx
  - ${module}_dictionary.sldd
  - ${module}_interface.xlsx
  - ${module}_variant.xlsx
  - ${module}_stimuli.mat
  - ${module}_calibration.html
  - ${module}_analysis_report.txt
  - ${module}_east_report.pdf
  - ${module}_delivery_package.zip
  - ${module}_sof_reference.txt
  - ${module}_mdt_reference.txt
  - trace_links.csv
EOF
}

create_spec_package() {
  local function_name="$1"
  local sub_function="$2"
  local module="$3"
  local dir="HEMS/SPEC_HEMS/$function_name/$sub_function/$module"

  mkdir -p "$dir"

  cat > "$dir/${module}_spec_source.xml" <<EOF
<specification module="$module">
  <status>draft</status>
</specification>
EOF

  cat > "$dir/${module}_spec_document.pdf" <<EOF
Dummy specification PDF placeholder for $module
EOF

  cat > "$dir/${module}_comparison_report.txt" <<EOF
Comparison report for $module
EOF

  cat > "$dir/${module}_history_log.txt" <<EOF
History log for $module
EOF

  cat > "$dir/${module}_crs_interface.xml" <<EOF
<crs module="$module">
  <interface>dummy</interface>
</crs>
EOF

  cat > "$dir/${module}_technical_fact_reference.txt" <<EOF
Technical Fact reference for $module
EOF

  cat > "$dir/${module}_sdt_reference.txt" <<EOF
SDT reference for $module
EOF

  create_trace_file "$dir/trace_links.csv"

  cat > "$dir/spec-manifest.yaml" <<EOF
module: $module
type: specification
area: SPEC_HEMS
function: $function_name
sub_function: $sub_function
version: $VERSION
delivery_cycle: $DELIVERY_CYCLE
files:
  - ${module}_spec_source.xml
  - ${module}_spec_document.pdf
  - ${module}_comparison_report.txt
  - ${module}_history_log.txt
  - ${module}_crs_interface.xml
  - ${module}_technical_fact_reference.txt
  - ${module}_sdt_reference.txt
  - trace_links.csv
EOF
}

for module_path in "${MODULES[@]}"; do
  IFS='/' read -r function_name sub_function module <<< "$module_path"

  create_code_package "$function_name" "$sub_function" "$module"
  create_module_package "$function_name" "$sub_function" "$module"
  create_spec_package "$function_name" "$sub_function" "$module"
done

echo "HEMS folder structure created successfully."
echo "Version: $VERSION"
echo "Delivery cycle: $DELIVERY_CYCLE"