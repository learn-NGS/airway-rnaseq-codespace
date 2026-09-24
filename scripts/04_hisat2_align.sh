#!/usr/bin/env bash
set -euo pipefail
THREADS=2
INDEX="reference/hisat2/grch38/genome"
mkdir -p results/04_alignment logs

for r1 in data/trimmed/*_1_val_1.fq.gz; do
  sample=$(basename "$r1" _1_val_1.fq.gz)
  r2="data/trimmed/${sample}_2_val_2.fq.gz"
  bam="results/04_alignment/${sample}.GRCh38.sorted.bam"

  echo "[HISAT2] $sample"
  hisat2 -p "$THREADS" \
    -x "$INDEX" \
    -1 "$r1" \
    -2 "$r2" \
    2> "logs/${sample}.hisat2.log" \
  | samtools sort -@ 1 -m 256M -o "$bam" -

  samtools index -@ "$THREADS" "$bam"
  samtools flagstat -@ "$THREADS" "$bam" > "results/04_alignment/${sample}.flagstat.txt"
done
