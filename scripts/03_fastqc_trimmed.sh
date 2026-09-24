#!/usr/bin/env bash
set -euo pipefail
THREADS=2
mkdir -p results/03_fastqc_trimmed
fastqc -t "$THREADS" -o results/03_fastqc_trimmed data/trimmed/*_val_*.fq.gz
