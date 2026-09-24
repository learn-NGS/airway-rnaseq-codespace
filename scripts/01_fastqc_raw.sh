#!/usr/bin/env bash
set -euo pipefail
THREADS=2
mkdir -p results/01_fastqc_raw
fastqc -t "$THREADS" -o results/01_fastqc_raw data/raw/*.fastq.gz
