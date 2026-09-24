#!/usr/bin/env bash
set -euo pipefail
bash scripts/00_check_environment.sh
bash scripts/01_fastqc_raw.sh
bash scripts/02_trim_galore.sh
bash scripts/03_fastqc_trimmed.sh
bash scripts/04_hisat2_align.sh
bash scripts/05_featurecounts.sh

echo
echo "Pipeline complete."
echo "Final count matrix: results/05_featurecounts/airway_gene_counts_matrix.tsv"
echo "To download outputs: bash scripts/06_start_server.sh"
