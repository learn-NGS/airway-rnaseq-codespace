#!/usr/bin/env bash
set -euo pipefail
THREADS=2
mkdir -p data/trimmed results/02_trim_galore logs

for r1 in data/raw/*_1.fastq.gz; do
  sample=$(basename "$r1" _1.fastq.gz)
  r2="data/raw/${sample}_2.fastq.gz"
  echo "[Trim Galore] $sample"
  trim_galore \
    --paired \
    --quality 30 \
    --cores "$THREADS" \
    --gzip \
    --output_dir data/trimmed \
    "$r1" "$r2" \
    > "logs/${sample}.trim_galore.log" 2>&1
done
