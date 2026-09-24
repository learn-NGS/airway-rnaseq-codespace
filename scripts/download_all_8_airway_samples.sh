#!/usr/bin/env bash
set -euo pipefail

SPOTS="${1:-200000}"
RAW="data/raw_extra"
mkdir -p "$RAW"
RUNS=(SRR1039516 SRR1039517 SRR1039520 SRR1039521)

for run in "${RUNS[@]}"; do
  fastq-dump --outdir "$RAW" --gzip --skip-technical \
    --split-files -N 1 -X "$SPOTS" "$run"
done
