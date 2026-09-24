# Airway RNA-seq practical: FASTQ → FastQC → Trim Galore → HISAT2 → featureCounts

This repository is designed for a **GitHub Codespace with 2 vCPU and 8 GB RAM**.

The practical uses **all 8 Airway samples** so students have:

- **4 untreated samples**
- **4 dexamethasone-treated samples**

The final featureCounts matrix is therefore ready for a later **4 vs 4 differential gene expression analysis**.

The analysis follows the workflow used in the supplied NGS report:

```text
FASTQ
  ↓
FastQC
  ↓
Trim Galore
  ↓
Post-trim FastQC
  ↓
HISAT2
  ↓
SAM → sorted BAM
  ↓
featureCounts
  ↓
gene count matrix
```

The report uses FastQC for quality assessment, Trim Galore for adapter/low-quality removal with a Q30 threshold, HISAT2 for splice-aware alignment, and featureCounts for gene abundance estimation. The reference assembly is Homo sapiens GRCh38.p14.

## Important design of this practical

The Docker image does **only one job**:

> install mamba and all required RNA-seq tools automatically.

The Docker build does **not** download FASTQ files or the human reference genome. This keeps Codespace creation reliable and avoids the recovery-mode problem caused by doing large downloads during container creation.

Students create the folders, download the data/reference files, and run each analysis command themselves.

There are **no bash scripts to run for the analysis**. Each step below is one command that can be copied and pasted directly into the terminal.

---

# 1. Start the Codespace

On GitHub:

```text
Code → Codespaces → Create codespace on main
```

The Docker image automatically installs:

```text
mamba
FastQC
Trim Galore
HISAT2
SAMtools
featureCounts (Subread)
SRA Toolkit
SeqKit
pigz
Python
```

Check the installation with one command:

```bash
mamba --version && fastqc --version && trim_galore --version | head -n 2 && hisat2 --version | head -n 1 && samtools --version | head -n 1 && featureCounts -v
```

Check the available resources:

```bash
echo "CPU=$(nproc)" && free -h
```

For this practical, use **2 threads**.

---

# 2. Create the directory structure

Run this **single command**:

```bash
mkdir -p ~/input ~/results/{fastqc,trim,fastqc_trimmed,reference,alignment,bam,featurecounts,logs}
```

The resulting structure is:

```text
~
├── input/
└── results/
    ├── fastqc/
    ├── trim/
    ├── fastqc_trimmed/
    ├── reference/
    ├── alignment/
    ├── bam/
    ├── featurecounts/
    └── logs/
```

---

# 3. Airway samples used

| Sample | Cell line | Condition |
|---|---|---|
| SRR1039508 | N61311 | untreated |
| SRR1039509 | N61311 | dexamethasone |
| SRR1039512 | N052611 | untreated |
| SRR1039513 | N052611 | dexamethasone |
| SRR1039516 | N080611 | untreated |
| SRR1039517 | N080611 | dexamethasone |
| SRR1039520 | N061011 | untreated |
| SRR1039521 | N061011 | dexamethasone |

This gives four biological samples in each condition.

For a 2-core teaching Codespace, the command below downloads the **first 200,000 paired-end spots from each SRA run** rather than the complete runs. The biological sample design remains 4 untreated vs 4 dexamethasone, but the read depth is intentionally reduced for classroom runtime.

---

# 4. Download all 8 paired-end FASTQ datasets

Run this **single command**:

```bash
(cd ~/input && for run in SRR1039508 SRR1039509 SRR1039512 SRR1039513 SRR1039516 SRR1039517 SRR1039520 SRR1039521; do fastq-dump --split-files --gzip --skip-technical -N 1 -X 200000 "$run"; done)
```

Check that 16 FASTQ files were created:

```bash
ls -lh ~/input/*.fastq.gz
```

You should have R1 and R2 for each of the 8 samples.

Optional FASTQ summary:

```bash
seqkit stats ~/input/*.fastq.gz
```

---

# 5. Create the 4 vs 4 metadata file

Run this **single command**:

```bash
printf "sample\tcell_line\tcondition\nSRR1039508\tN61311\tuntreated\nSRR1039509\tN61311\tdexamethasone\nSRR1039512\tN052611\tuntreated\nSRR1039513\tN052611\tdexamethasone\nSRR1039516\tN080611\tuntreated\nSRR1039517\tN080611\tdexamethasone\nSRR1039520\tN061011\tuntreated\nSRR1039521\tN061011\tdexamethasone\n" > ~/results/airway_metadata.tsv
```

View it:

```bash
column -t -s $'\t' ~/results/airway_metadata.tsv
```

---

# 6. Download GRCh38.p14 reference, annotation and HISAT2 index

The supplied report specifies the human **GRCh38.p14** assembly from Ensembl.

This practical uses the Ensembl release 112 GRCh38 primary assembly and GTF, together with a pre-built HISAT2 GRCh38 index. A pre-built index is used because building the complete human HISAT2 index on a 2-core/8-GB teaching Codespace is unnecessarily slow and memory intensive.

Run this **single command**:

```bash
curl -L https://ftp.ensembl.org/pub/release-112/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz -o ~/results/reference/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz && curl -L https://ftp.ensembl.org/pub/release-112/gtf/homo_sapiens/Homo_sapiens.GRCh38.112.gtf.gz -o ~/results/reference/Homo_sapiens.GRCh38.112.gtf.gz && curl -L https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz -o ~/results/reference/grch38_genome.tar.gz && tar -xzf ~/results/reference/grch38_genome.tar.gz -C ~/results/reference && rm ~/results/reference/grch38_genome.tar.gz
```

Check the files:

```bash
ls -lh ~/results/reference
```

The HISAT2 index should be under:

```text
~/results/reference/grch38/genome.*
```

---

# 7. Raw-read quality control — FastQC

Run FastQC on **all 16 FASTQ files with one command**:

```bash
fastqc -t 2 ~/input/*.fastq.gz -o ~/results/fastqc
```

Output:

```text
~/results/fastqc/
```

For each read file, FastQC generates an HTML report and a ZIP archive.

---

# 8. Adapter and quality trimming — Trim Galore

The supplied report states that adapter sequences and low-quality bases were removed using Trim Galore and that reads/bases above **Q30** were retained for downstream analysis.

Run Trim Galore on all 8 paired-end samples with **one command**:

```bash
for r1 in ~/input/*_1.fastq.gz; do sample=$(basename "$r1" _1.fastq.gz); trim_galore --paired --quality 30 --cores 2 --gzip --output_dir ~/results/trim "$r1" "$HOME/input/${sample}_2.fastq.gz"; done
```

The paired outputs will look like:

```text
SRR1039508_1_val_1.fq.gz
SRR1039508_2_val_2.fq.gz
```

---

# 9. Post-trimming FastQC

Run FastQC on all trimmed reads with **one command**:

```bash
fastqc -t 2 ~/results/trim/*_val_*.fq.gz -o ~/results/fastqc_trimmed
```

Compare:

```text
~/results/fastqc/
~/results/fastqc_trimmed/
```

---

# 10. Align all 8 samples with HISAT2

The supplied report states that the processed reads were aligned to the human reference genome using HISAT2 with default alignment parameters.

The only explicit computational setting added here is `-p 2` because the Codespace has 2 CPUs.

Run alignment for all 8 samples with **one command**:

```bash
for r1 in ~/results/trim/*_1_val_1.fq.gz; do sample=$(basename "$r1" _1_val_1.fq.gz); hisat2 -p 2 -x ~/results/reference/grch38/genome -1 "$r1" -2 "$HOME/results/trim/${sample}_2_val_2.fq.gz" -S "$HOME/results/alignment/${sample}.sam" 2> "$HOME/results/logs/${sample}.hisat2.log"; done
```

SAM files:

```text
~/results/alignment/
```

HISAT2 alignment summaries:

```text
~/results/logs/
```

View all alignment percentages with one command:

```bash
grep "overall alignment rate" ~/results/logs/*.hisat2.log
```

---

# 11. Convert SAM to sorted/indexed BAM

Run SAMtools on all 8 SAM files with **one command**:

```bash
for sam in ~/results/alignment/*.sam; do sample=$(basename "$sam" .sam); samtools sort -@ 2 -m 512M -o "$HOME/results/bam/${sample}.sorted.bam" "$sam" && samtools index -@ 2 "$HOME/results/bam/${sample}.sorted.bam"; done
```

Create flagstat reports for all BAM files with **one command**:

```bash
for bam in ~/results/bam/*.sorted.bam; do sample=$(basename "$bam" .sorted.bam); samtools flagstat -@ 2 "$bam" > "$HOME/results/bam/${sample}.flagstat.txt"; done
```

Outputs:

```text
~/results/bam/*.sorted.bam
~/results/bam/*.sorted.bam.bai
~/results/bam/*.flagstat.txt
```

---

# 12. Gene quantification — featureCounts

The supplied report uses featureCounts to calculate gene abundance from genome-aligned reads.

Run featureCounts on all 8 BAM files with **one command**:

```bash
featureCounts -T 2 -p --countReadPairs -s 0 -t exon -g gene_id -a ~/results/reference/Homo_sapiens.GRCh38.112.gtf.gz -o ~/results/featurecounts/airway_gene_counts.txt ~/results/bam/*.sorted.bam
```

Main outputs:

```text
~/results/featurecounts/airway_gene_counts.txt
~/results/featurecounts/airway_gene_counts.txt.summary
```

Create a compact count matrix with **one command**:

```bash
grep -v '^#' ~/results/featurecounts/airway_gene_counts.txt | cut -f1,7- > ~/results/featurecounts/airway_gene_counts_matrix.tsv
```

The matrix contains one gene column followed by counts for all 8 samples and can be used for the next DESeq2 practical.

---

# 13. Download output files from Codespaces

Start a Python file server with **one command**:

```bash
python -m http.server 8000 --directory ~/results
```

In Codespaces:

```text
PORTS → 8000 → Open in Browser
```

Students can download FastQC reports, trimming outputs, HISAT2 logs, BAM files, featureCounts outputs and the metadata file.

Stop the server with:

```text
Ctrl+C
```

---

# Complete student command sequence

The practical intentionally keeps each analysis stage visible to the student.

### 1. Create folders

```bash
mkdir -p ~/input ~/results/{fastqc,trim,fastqc_trimmed,reference,alignment,bam,featurecounts,logs}
```

### 2. Download 8 paired-end Airway subsets

```bash
(cd ~/input && for run in SRR1039508 SRR1039509 SRR1039512 SRR1039513 SRR1039516 SRR1039517 SRR1039520 SRR1039521; do fastq-dump --split-files --gzip --skip-technical -N 1 -X 200000 "$run"; done)
```

### 3. Download reference + GTF + HISAT2 index

```bash
curl -L https://ftp.ensembl.org/pub/release-112/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz -o ~/results/reference/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz && curl -L https://ftp.ensembl.org/pub/release-112/gtf/homo_sapiens/Homo_sapiens.GRCh38.112.gtf.gz -o ~/results/reference/Homo_sapiens.GRCh38.112.gtf.gz && curl -L https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz -o ~/results/reference/grch38_genome.tar.gz && tar -xzf ~/results/reference/grch38_genome.tar.gz -C ~/results/reference && rm ~/results/reference/grch38_genome.tar.gz
```

### 4. Raw FastQC

```bash
fastqc -t 2 ~/input/*.fastq.gz -o ~/results/fastqc
```

### 5. Trim Galore

```bash
for r1 in ~/input/*_1.fastq.gz; do sample=$(basename "$r1" _1.fastq.gz); trim_galore --paired --quality 30 --cores 2 --gzip --output_dir ~/results/trim "$r1" "$HOME/input/${sample}_2.fastq.gz"; done
```

### 6. Post-trim FastQC

```bash
fastqc -t 2 ~/results/trim/*_val_*.fq.gz -o ~/results/fastqc_trimmed
```

### 7. HISAT2

```bash
for r1 in ~/results/trim/*_1_val_1.fq.gz; do sample=$(basename "$r1" _1_val_1.fq.gz); hisat2 -p 2 -x ~/results/reference/grch38/genome -1 "$r1" -2 "$HOME/results/trim/${sample}_2_val_2.fq.gz" -S "$HOME/results/alignment/${sample}.sam" 2> "$HOME/results/logs/${sample}.hisat2.log"; done
```

### 8. SAM → sorted/indexed BAM

```bash
for sam in ~/results/alignment/*.sam; do sample=$(basename "$sam" .sam); samtools sort -@ 2 -m 512M -o "$HOME/results/bam/${sample}.sorted.bam" "$sam" && samtools index -@ 2 "$HOME/results/bam/${sample}.sorted.bam"; done
```

### 9. featureCounts

```bash
featureCounts -T 2 -p --countReadPairs -s 0 -t exon -g gene_id -a ~/results/reference/Homo_sapiens.GRCh38.112.gtf.gz -o ~/results/featurecounts/airway_gene_counts.txt ~/results/bam/*.sorted.bam
```

### 10. Serve results

```bash
python -m http.server 8000 --directory ~/results
```

---

## Notes

- The full Airway experiment is much larger. The `-X 200000` setting intentionally subsets each run for a classroom demonstration on a 2-core Codespace.
- The 8 biological samples are still preserved as four untreated and four dexamethasone-treated samples.
- The supplied report identifies FastQC v0.11.8, but the Docker image installs the current compatible Bioconda FastQC package to keep the container build reliable.
- The report does not provide the literal featureCounts flags. The paired-end settings shown here are explicit practical implementation choices for the Airway data.
