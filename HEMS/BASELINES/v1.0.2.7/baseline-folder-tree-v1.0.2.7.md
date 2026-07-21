# Baseline Folder Structure - v1.0.2.7

This file shows the folder/file structure included in this baseline release.

```text
└── HEMS
    ├── CODE_HEMS
    │   ├── ASXX
    │   │   ├── ASXX_ADMX
    │   │   │   └── ASXX_ADMX_CTL
    │   │   │       ├── ASXX_ADMX_CTL.c
    │   │   │       ├── ASXX_ADMX_CTL.h
    │   │   │       ├── ASXX_ADMX_CTL_certification_report.txt
    │   │   │       ├── ASXX_ADMX_CTL_compiler_log.txt
    │   │   │       ├── ASXX_ADMX_CTL_sil_results.txt
    │   │   │       ├── ASXX_ADMX_CTL_static_analysis_report.txt
    │   │   │       ├── code-manifest.yaml
    │   │   │       └── trace_links.csv
    │   │   └── ASXX_DGNX
    │   │       └── ASXX_DGNX_CTL
    │   │           ├── ASXX_DGNX_CTL.c
    │   │           ├── ASXX_DGNX_CTL.h
    │   │           ├── ASXX_DGNX_CTL_certification_report.txt
    │   │           ├── ASXX_DGNX_CTL_compiler_log.txt
    │   │           ├── ASXX_DGNX_CTL_sil_results.txt
    │   │           ├── ASXX_DGNX_CTL_static_analysis_report.txt
    │   │           ├── code-manifest.yaml
    │   │           └── trace_links.csv
    │   └── ATXX
    │       ├── ATXX_DIAG
    │       │   └── ATXX_DIAG_CTL
    │       │       ├── ATXX_DIAG_CTL.c
    │       │       ├── ATXX_DIAG_CTL.h
    │       │       ├── ATXX_DIAG_CTL_certification_report.txt
    │       │       ├── ATXX_DIAG_CTL_compiler_log.txt
    │       │       ├── ATXX_DIAG_CTL_sil_results.txt
    │       │       ├── ATXX_DIAG_CTL_static_analysis_report.txt
    │       │       ├── code-manifest.yaml
    │       │       └── trace_links.csv
    │       └── ATXX_MAIN
    │           └── ATXX_MAIN_CTL
    │               ├── ATXX_MAIN_CTL.c
    │               ├── ATXX_MAIN_CTL.h
    │               ├── ATXX_MAIN_CTL_certification_report.txt
    │               ├── ATXX_MAIN_CTL_compiler_log.txt
    │               ├── ATXX_MAIN_CTL_sil_results.txt
    │               ├── ATXX_MAIN_CTL_static_analysis_report.txt
    │               ├── code-manifest.yaml
    │               └── trace_links.csv
    ├── MOD_HEMS
    │   ├── ASXX
    │   │   ├── ASXX_ADMX
    │   │   │   └── ASXX_ADMX_CTL
    │   │   │       ├── ASXX_ADMX_CTL.slx
    │   │   │       ├── ASXX_ADMX_CTL_analysis_report.txt
    │   │   │       ├── ASXX_ADMX_CTL_calibration.html
    │   │   │       ├── ASXX_ADMX_CTL_delivery_package.zip
    │   │   │       ├── ASXX_ADMX_CTL_dictionary.sldd
    │   │   │       ├── ASXX_ADMX_CTL_east_report.pdf
    │   │   │       ├── ASXX_ADMX_CTL_interface.xlsx
    │   │   │       ├── ASXX_ADMX_CTL_mdt_reference.txt
    │   │   │       ├── ASXX_ADMX_CTL_sof_reference.txt
    │   │   │       ├── ASXX_ADMX_CTL_stimuli.mat
    │   │   │       ├── ASXX_ADMX_CTL_variant.xlsx
    │   │   │       ├── module-manifest.yaml
    │   │   │       └── trace_links.csv
    │   │   └── ASXX_DGNX
    │   │       └── ASXX_DGNX_CTL
    │   │           ├── ASXX_DGNX_CTL.slx
    │   │           ├── ASXX_DGNX_CTL_analysis_report.txt
    │   │           ├── ASXX_DGNX_CTL_calibration.html
    │   │           ├── ASXX_DGNX_CTL_delivery_package.zip
    │   │           ├── ASXX_DGNX_CTL_dictionary.sldd
    │   │           ├── ASXX_DGNX_CTL_east_report.pdf
    │   │           ├── ASXX_DGNX_CTL_interface.xlsx
    │   │           ├── ASXX_DGNX_CTL_mdt_reference.txt
    │   │           ├── ASXX_DGNX_CTL_sof_reference.txt
    │   │           ├── ASXX_DGNX_CTL_stimuli.mat
    │   │           ├── ASXX_DGNX_CTL_variant.xlsx
    │   │           ├── module-manifest.yaml
    │   │           └── trace_links.csv
    │   └── ATXX
    │       ├── ATXX_DIAG
    │       │   └── ATXX_DIAG_CTL
    │       │       ├── ATXX_DIAG_CTL.slx
    │       │       ├── ATXX_DIAG_CTL_analysis_report.txt
    │       │       ├── ATXX_DIAG_CTL_calibration.html
    │       │       ├── ATXX_DIAG_CTL_delivery_package.zip
    │       │       ├── ATXX_DIAG_CTL_dictionary.sldd
    │       │       ├── ATXX_DIAG_CTL_east_report.pdf
    │       │       ├── ATXX_DIAG_CTL_interface.xlsx
    │       │       ├── ATXX_DIAG_CTL_mdt_reference.txt
    │       │       ├── ATXX_DIAG_CTL_sof_reference.txt
    │       │       ├── ATXX_DIAG_CTL_stimuli.mat
    │       │       ├── ATXX_DIAG_CTL_variant.xlsx
    │       │       ├── module-manifest.yaml
    │       │       └── trace_links.csv
    │       └── ATXX_MAIN
    │           └── ATXX_MAIN_CTL
    │               ├── ATXX_MAIN_CTL.slx
    │               ├── ATXX_MAIN_CTL_analysis_report.txt
    │               ├── ATXX_MAIN_CTL_calibration.html
    │               ├── ATXX_MAIN_CTL_delivery_package.zip
    │               ├── ATXX_MAIN_CTL_dictionary.sldd
    │               ├── ATXX_MAIN_CTL_east_report.pdf
    │               ├── ATXX_MAIN_CTL_interface.xlsx
    │               ├── ATXX_MAIN_CTL_mdt_reference.txt
    │               ├── ATXX_MAIN_CTL_sof_reference.txt
    │               ├── ATXX_MAIN_CTL_stimuli.mat
    │               ├── ATXX_MAIN_CTL_variant.xlsx
    │               ├── module-manifest.yaml
    │               └── trace_links.csv
    └── SPEC_HEMS
        ├── ASXX
        │   ├── ASXX_ADMX
        │   │   └── ASXX_ADMX_CTL
        │   │       ├── ASXX_ADMX_CTL_comparison_report.txt
        │   │       ├── ASXX_ADMX_CTL_crs_interface.xml
        │   │       ├── ASXX_ADMX_CTL_history_log.txt
        │   │       ├── ASXX_ADMX_CTL_sdt_reference.txt
        │   │       ├── ASXX_ADMX_CTL_spec_document.pdf
        │   │       ├── ASXX_ADMX_CTL_spec_source.xml
        │   │       ├── ASXX_ADMX_CTL_technical_fact_reference.txt
        │   │       ├── spec-manifest.yaml
        │   │       └── trace_links.csv
        │   └── ASXX_DGNX
        │       └── ASXX_DGNX_CTL
        │           ├── ASXX_DGNX_CTL_comparison_report.txt
        │           ├── ASXX_DGNX_CTL_crs_interface.xml
        │           ├── ASXX_DGNX_CTL_history_log.txt
        │           ├── ASXX_DGNX_CTL_sdt_reference.txt
        │           ├── ASXX_DGNX_CTL_spec_document.pdf
        │           ├── ASXX_DGNX_CTL_spec_source.xml
        │           ├── ASXX_DGNX_CTL_technical_fact_reference.txt
        │           ├── spec-manifest.yaml
        │           └── trace_links.csv
        └── ATXX
            ├── ATXX_DIAG
            │   └── ATXX_DIAG_CTL
            │       ├── ATXX_DIAG_CTL_comparison_report.txt
            │       ├── ATXX_DIAG_CTL_crs_interface.xml
            │       ├── ATXX_DIAG_CTL_history_log.txt
            │       ├── ATXX_DIAG_CTL_sdt_reference.txt
            │       ├── ATXX_DIAG_CTL_spec_document.pdf
            │       ├── ATXX_DIAG_CTL_spec_source.xml
            │       ├── ATXX_DIAG_CTL_technical_fact_reference.txt
            │       ├── spec-manifest.yaml
            │       └── trace_links.csv
            └── ATXX_MAIN
                └── ATXX_MAIN_CTL
                    ├── ATXX_MAIN_CTL_comparison_report.txt
                    ├── ATXX_MAIN_CTL_crs_interface.xml
                    ├── ATXX_MAIN_CTL_history_log.txt
                    ├── ATXX_MAIN_CTL_sdt_reference.txt
                    ├── ATXX_MAIN_CTL_spec_document.pdf
                    ├── ATXX_MAIN_CTL_spec_source.xml
                    ├── ATXX_MAIN_CTL_technical_fact_reference.txt
                    ├── spec-manifest.yaml
                    └── trace_links.csv
```

## Total Released Files

120