#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/opt/airway-rnaseq}"
RAW="$ROOT/data/raw"
REF="$ROOT/reference"
INDEX="$REF/hisat2"
META="$ROOT/metadata"

mkdir -p "$RAW" "$REF" "$INDEX" "$META"

cat > "$META/airway_samples.tsv" <<'TSV'
run	cell_line	dex_condition	selected_for_practical
SRR1039508	N61311	untreated	yes
SRR1039509	N61311	dexamethasone	yes
SRR1039512	N052611	untreated	yes
SRR1039513	N052611	dexamethasone	yes
SRR1039516	N080611	untreated	no
SRR1039517	N080611	dexamethasone	no
SRR1039520	N061011	untreated	no
SRR1039521	N061011	dexamethasone	no
TSV

FASTA_URL="https://ftp.ensembl.org/pub/release-112/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
GTF_URL="https://ftp.ensembl.org/pub/release-112/gtf/homo_sapiens/Homo_sapiens.GRCh38.112.gtf.gz"
HISAT2_INDEX_URL="https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz"
AIRWAY_FASTQ_BASE="https://raw.githubusercontent.com/csoneson/rnaseqworkflow_exampledata/master/FASTQ"

retry_curl() {
  local url="$1"
  local out="$2"
  curl -fL --retry 6 --retry-delay 5 --retry-all-errors "$url" -o "$out"
}

if [[ ! -s "$REF/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz" ]]; then
  echo "[preload] Downloading Ensembl GRCh38 primary assembly FASTA..."
  retry_curl "$FASTA_URL" "$REF/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"
fi

if [[ ! -s "$REF/Homo_sapiens.GRCh38.112.gtf.gz" ]]; then
  echo "[preload] Downloading Ensembl release 112 GTF..."
  retry_curl "$GTF_URL" "$REF/Homo_sapiens.GRCh38.112.gtf.gz"
fi

if [[ ! -e "$INDEX/grch38/genome.1.ht2" && ! -e "$INDEX/grch38/genome.1.ht2l" ]]; then
  echo "[preload] Downloading pre-built HISAT2 GRCh38 index..."
  retry_curl "$HISAT2_INDEX_URL" /tmp/grch38_genome.tar.gz
  tar -xzf /tmp/grch38_genome.tar.gz -C "$INDEX"
  rm -f /tmp/grch38_genome.tar.gz
fi

RUNS=(SRR1039508 SRR1039509 SRR1039512 SRR1039513)
for run in "${RUNS[@]}"; do
  for mate in 1 2; do
    src_mate="R${mate}"
    out="$RAW/${run}_${mate}.fastq.gz"
    if [[ -s "$out" ]]; then
      continue
    fi
    echo "[preload] Downloading Airway teaching FASTQ: ${run}_${src_mate}"
    retry_curl       "$AIRWAY_FASTQ_BASE/${run}_${src_mate}.fastq.gz"       "$out"
  done
done

cat > "$ROOT/RESOURCE_MANIFEST.txt" <<'EOF2'
Teaching resources preloaded in Docker image
Reference assembly: Homo sapiens GRCh38.p14
Reference FASTA: Ensembl release 112 primary assembly
Annotation GTF: Ensembl release 112
HISAT2 index: official pre-built GRCh38 genome index
Airway teaching FASTQs:
  SRR1039508
  SRR1039509
  SRR1039512
  SRR1039513
FASTQ source:
  csoneson/rnaseqworkflow_exampledata
  Files are small paired-end teaching subsets from GSE52778 / SRP033351.
EOF2

chmod -R a+rX "$ROOT"
