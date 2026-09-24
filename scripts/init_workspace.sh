#!/usr/bin/env bash
set -euo pipefail

COURSE_ROOT="${COURSE_ROOT:-/opt/airway-rnaseq}"

mkdir -p data results logs metadata

if [[ ! -e data/raw ]]; then
  ln -s "$COURSE_ROOT/data/raw" data/raw
fi
if [[ ! -e reference ]]; then
  ln -s "$COURSE_ROOT/reference" reference
fi

cp -f "$COURSE_ROOT/metadata/airway_samples.tsv" metadata/airway_samples.tsv

mkdir -p \
  data/trimmed \
  results/01_fastqc_raw \
  results/02_trim_galore \
  results/03_fastqc_trimmed \
  results/04_alignment \
  results/05_featurecounts \
  logs

printf '\nWorkspace initialized.\n'
printf 'CPU cores: '; nproc
printf 'Memory: '; free -h | awk '/Mem:/ {print $2}'
printf 'Raw FASTQ files: '; find -L data/raw -maxdepth 1 -name '*.fastq.gz' | wc -l
printf 'Reference link: %s\n' "$(readlink -f reference)"
