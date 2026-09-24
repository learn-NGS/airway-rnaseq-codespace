#!/usr/bin/env bash
set -euo pipefail

echo "=== Resources ==="
echo "nproc: $(nproc)"
free -h

echo
echo "=== Tools ==="
fastqc --version
trim_galore --version | head -n 2
hisat2 --version | head -n 1
samtools --version | head -n 1
featureCounts -v 2>&1 | head -n 1
python --version

echo
echo "=== Input files ==="
ls -lh data/raw/*.fastq.gz
ls -lh reference/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
ls -lh reference/Homo_sapiens.GRCh38.112.gtf.gz

echo
echo "=== HISAT2 index ==="
ls -lh reference/hisat2/grch38/genome.*.ht2* | head

echo
echo "=== Sample metadata ==="
column -t -s $'\t' metadata/airway_samples.tsv || cat metadata/airway_samples.tsv
