#!/usr/bin/env bash
set -euo pipefail
THREADS=2
GTF="reference/Homo_sapiens.GRCh38.112.gtf.gz"
OUT="results/05_featurecounts/airway_gene_counts.txt"
mkdir -p results/05_featurecounts

mapfile -t BAMS < <(find results/04_alignment -maxdepth 1 -name '*.GRCh38.sorted.bam' | sort)
if [[ ${#BAMS[@]} -eq 0 ]]; then
  echo "No BAM files found. Run scripts/04_hisat2_align.sh first." >&2
  exit 1
fi

featureCounts \
  -T "$THREADS" \
  -p --countReadPairs \
  -s 0 \
  -t exon \
  -g gene_id \
  -a "$GTF" \
  -o "$OUT" \
  "${BAMS[@]}"

python scripts/make_clean_count_matrix.py "$OUT" \
  "results/05_featurecounts/airway_gene_counts_matrix.tsv"
