# Airway RNA-seq practical: FASTQ → FastQC → Trim Galore → HISAT2 → featureCounts

This repository is a **GitHub Codespaces-ready RNA-seq practical** designed for a machine with **2 vCPU and 8 GB RAM**.

The practical takes students from:

```text
FASTQ
  ↓
FastQC
  ↓
Trim Galore
  ↓
Post-trim FastQC
  ↓
HISAT2 alignment
  ↓
sorted + indexed BAM
  ↓
featureCounts
  ↓
gene count matrix
```

All command-line tools are installed through **mamba/Bioconda** inside the Docker image. The Docker build also preloads the Airway teaching FASTQs, the human reference FASTA, the gene annotation GTF, and a pre-built HISAT2 GRCh38 index.

---

## 1. Workflow reproduced from the supplied NGS report

The supplied report describes a reference-guided transcriptome workflow using:

- **FastQC** for raw-read quality assessment.
- **Trim Galore** for adapter removal and filtering low-quality bases/reads.
- **Q30** as the stated preprocessing quality threshold.
- **HISAT2** as the splice-aware aligner, using default alignment parameters.
- **featureCounts** for gene abundance estimation.
- **Homo sapiens GRCh38.p14 (GCA_000001405.29)** as the reference assembly from Ensembl.

The practical stops at the featureCounts count matrix, as requested.

### Reproducibility note

The report does not provide the literal Trim Galore or featureCounts shell commands. Therefore the missing command-line choices are made explicit here rather than presented as report-derived parameters:

- Trim Galore: paired-end mode with `--quality 30`.
- HISAT2: default alignment behavior; only `-p 2` is added for the Codespace CPU limit.
- featureCounts: paired-end fragment counting using `-p --countReadPairs`, exon features grouped by `gene_id`, and `-s 0` for the Airway teaching dataset.

FastQC is pinned to **v0.11.8**, the version named in the report.

---

## 2. Airway RNA-seq dataset

The practical uses the well-known **Airway** dexamethasone RNA-seq experiment:

- GEO: **GSE52778**
- SRA study: **SRP033351**

The canonical 8-sample untreated/dexamethasone subset is:

| Run | Cell line | Condition |
|---|---|---|
| SRR1039508 | N61311 | untreated |
| SRR1039509 | N61311 | dexamethasone |
| SRR1039512 | N052611 | untreated |
| SRR1039513 | N052611 | dexamethasone |
| SRR1039516 | N080611 | untreated |
| SRR1039517 | N080611 | dexamethasone |
| SRR1039520 | N061011 | untreated |
| SRR1039521 | N061011 | dexamethasone |

For a practical running on only 2 vCPU, the Docker image preloads **four small paired-end teaching FASTQ subsets**:

```text
SRR1039508
SRR1039509
SRR1039512
SRR1039513
```

These files are from the public `csoneson/rnaseqworkflow_exampledata` teaching dataset. They contain reads from the same Airway runs and were subsetted to reads mapping within the first 10 Mb of chromosome 1, making them suitable for a classroom Codespace while still allowing alignment to the full GRCh38 reference.

The full sample metadata is in:

```text
metadata/airway_samples.tsv
```

---

## 3. Reference genome and annotation

The Docker image contains:

```text
reference/
├── Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
├── Homo_sapiens.GRCh38.112.gtf.gz
└── hisat2/
    └── grch38/
        ├── genome.1.ht2
        ├── genome.2.ht2
        ├── ...
        └── genome.8.ht2
```

The practical uses:

- **Assembly:** GRCh38.p14
- **FASTA:** Ensembl release 112 primary assembly
- **GTF:** Ensembl release 112
- **HISAT2 index:** official pre-built GRCh38 index

Ensembl release 112 is used because it is a GRCh38.p14 release contemporaneous with the supplied May 2024 analysis report.

Using a pre-built HISAT2 index avoids asking students to build the entire human genome index in an 8 GB Codespace.

---

## 4. Repository structure

After Codespaces initializes, the workspace is organized as:

```text
.
├── .devcontainer/
│   └── devcontainer.json
├── data/
│   ├── raw/                         # preloaded Airway FASTQs
│   └── trimmed/                     # Trim Galore output
├── metadata/
│   └── airway_samples.tsv
├── reference/                       # symlink to preloaded reference resources
├── results/
│   ├── 01_fastqc_raw/
│   ├── 02_trim_galore/
│   ├── 03_fastqc_trimmed/
│   ├── 04_alignment/
│   └── 05_featurecounts/
├── logs/
├── docker/
│   └── preload_course_data.sh
├── scripts/
│   ├── 00_check_environment.sh
│   ├── 01_fastqc_raw.sh
│   ├── 02_trim_galore.sh
│   ├── 03_fastqc_trimmed.sh
│   ├── 04_hisat2_align.sh
│   ├── 05_featurecounts.sh
│   ├── 06_start_server.sh
│   ├── init_workspace.sh
│   ├── make_clean_count_matrix.py
│   └── run_all.sh
├── Dockerfile
├── environment.yml
└── README.md
```

The Codespace automatically runs:

```bash
bash scripts/init_workspace.sh
```

It is safe to run it again manually.

---

## 5. Start the Codespace

On GitHub:

```text
Code → Codespaces → Create codespace on main
```

The first build is the longest because the Docker image downloads the human reference resources and HISAT2 index.

When the terminal opens, verify the environment:

```bash
bash scripts/00_check_environment.sh
```

You should see:

```bash
nproc
# 2
```

and approximately 8 GB RAM.

---

# Student practical

## Step 1 — Raw FASTQ quality control

View the input files:

```bash
ls -lh data/raw/
```

Run FastQC:

```bash
fastqc \
  -t 2 \
  -o results/01_fastqc_raw \
  data/raw/*.fastq.gz
```

Or use the prepared script:

```bash
bash scripts/01_fastqc_raw.sh
```

Inspect the generated `*_fastqc.html` reports.

Focus on:

- per-base sequence quality
- adapter content
- sequence duplication
- overrepresented sequences

---

## Step 2 — Trim adapters and low-quality bases

The supplied report describes removal of adapters and low-quality bases using Trim Galore and a Q30 threshold.

Example for one sample:

```bash
trim_galore \
  --paired \
  --quality 30 \
  --cores 2 \
  --gzip \
  --output_dir data/trimmed \
  data/raw/SRR1039508_1.fastq.gz \
  data/raw/SRR1039508_2.fastq.gz
```

Run all four samples:

```bash
bash scripts/02_trim_galore.sh
```

Expected files include:

```text
data/trimmed/SRR1039508_1_val_1.fq.gz
data/trimmed/SRR1039508_2_val_2.fq.gz
```

---

## Step 3 — Post-trimming FastQC

Run FastQC again:

```bash
fastqc \
  -t 2 \
  -o results/03_fastqc_trimmed \
  data/trimmed/*_val_*.fq.gz
```

Or:

```bash
bash scripts/03_fastqc_trimmed.sh
```

Compare the raw and trimmed FastQC reports.

---

## Step 4 — Align reads with HISAT2

The source report specifies HISAT2 with default alignment parameters.

For this Codespace, only the thread setting is explicitly added:

```bash
hisat2 \
  -p 2 \
  -x reference/hisat2/grch38/genome \
  -1 data/trimmed/SRR1039508_1_val_1.fq.gz \
  -2 data/trimmed/SRR1039508_2_val_2.fq.gz \
  2> logs/SRR1039508.hisat2.log \
| samtools sort \
    -@ 1 \
    -m 256M \
    -o results/04_alignment/SRR1039508.GRCh38.sorted.bam -
```

Index the BAM:

```bash
samtools index -@ 2 \
  results/04_alignment/SRR1039508.GRCh38.sorted.bam
```

Create alignment statistics:

```bash
samtools flagstat -@ 2 \
  results/04_alignment/SRR1039508.GRCh38.sorted.bam \
  > results/04_alignment/SRR1039508.flagstat.txt
```

Run all samples:

```bash
bash scripts/04_hisat2_align.sh
```

HISAT2 alignment summaries are written to:

```text
logs/*.hisat2.log
```

---

## Step 5 — Gene quantification with featureCounts

Run featureCounts across all aligned BAM files:

```bash
featureCounts \
  -T 2 \
  -p \
  --countReadPairs \
  -s 0 \
  -t exon \
  -g gene_id \
  -a reference/Homo_sapiens.GRCh38.112.gtf.gz \
  -o results/05_featurecounts/airway_gene_counts.txt \
  results/04_alignment/*.GRCh38.sorted.bam
```

Or:

```bash
bash scripts/05_featurecounts.sh
```

Main outputs:

```text
results/05_featurecounts/airway_gene_counts.txt
results/05_featurecounts/airway_gene_counts.txt.summary
results/05_featurecounts/airway_gene_counts_matrix.tsv
```

The simplified matrix:

```text
airway_gene_counts_matrix.tsv
```

contains:

```text
Geneid    SRR1039508    SRR1039509    SRR1039512    SRR1039513
```

and can be used directly in a later DESeq2 practical.

---

## 6. Run the entire workflow

Instead of executing each stage manually:

```bash
bash scripts/run_all.sh
```

The pipeline executes:

```text
environment check
      ↓
raw FastQC
      ↓
Trim Galore
      ↓
post-trim FastQC
      ↓
HISAT2
      ↓
samtools sort/index/flagstat
      ↓
featureCounts
      ↓
clean gene count matrix
```

---

## 7. Download output files from Codespaces

Start the Python HTTP server:

```bash
bash scripts/06_start_server.sh
```

Equivalent command:

```bash
python -m http.server 8000 --directory results
```

In GitHub Codespaces:

```text
PORTS → port 8000 → Open in Browser
```

Students can then download their FastQC reports, alignment statistics and featureCounts output directly from the browser.

Stop the server with:

```text
Ctrl+C
```

---

## 8. Useful inspection commands

Check FASTQ statistics:

```bash
seqkit stats data/raw/*.fastq.gz
```

Inspect alignment statistics:

```bash
for f in results/04_alignment/*.flagstat.txt; do
  echo "===== $f ====="
  cat "$f"
done
```

Preview the count matrix:

```bash
column -t -s $'\t' \
  results/05_featurecounts/airway_gene_counts_matrix.tsv \
  | head -20
```

---

## 9. Minimal command sheet

Students can copy these commands one at a time:

```bash
bash scripts/00_check_environment.sh
bash scripts/01_fastqc_raw.sh
bash scripts/02_trim_galore.sh
bash scripts/03_fastqc_trimmed.sh
bash scripts/04_hisat2_align.sh
bash scripts/05_featurecounts.sh
bash scripts/06_start_server.sh
```

Or run everything except the download server:

```bash
bash scripts/run_all.sh
```

---

## 10. Data sources

Airway biological experiment:

```text
GEO GSE52778
SRA SRP033351
```

Teaching FASTQ subsets:

```text
https://github.com/csoneson/rnaseqworkflow_exampledata
```

Reference:

```text
Ensembl Homo sapiens GRCh38.p14
Ensembl release 112
```

HISAT2 index:

```text
https://daehwankimlab.github.io/hisat2/download/
```
