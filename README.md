# Airway RNA-seq practical: FASTQ → FastQC → HISAT2 → featureCounts

This repository is designed for a **GitHub Codespace with 2 vCPU and 8 GB RAM**.

The practical uses all 8 Airway samples:

- **4 untreated samples**
- **4 dexamethasone-treated samples**

The final featureCounts matrix is ready for a later **4 vs 4 differential gene expression analysis**.

The analysis used in this practical is:

```text
FASTQ
  ↓
FastQC
  ↓
HISAT2
  ↓
SAM → sorted BAM
  ↓
featureCounts
  ↓
gene count matrix
```

The supplied report describes FastQC for quality assessment, trimming when required, HISAT2 for splice-aware alignment, and featureCounts for gene abundance estimation. The reference assembly is Homo sapiens GRCh38.p14.

## Important design of this practical

The Docker image only installs the software environment automatically.

It installs:

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

The Docker build does **not** download the FASTQ files, reference genome, annotation, HISAT2 index, or start a web server.

Students create the folders, download the files, run the analysis commands, and start the output server themselves.

---

# Step 1 — Start Codespaces, create folders and start the output server

On GitHub:

```text
Code → Codespaces → Create codespace on main
```

Check that the required tools are installed:

```bash
mamba --version && fastqc --version && trim_galore --version | head -n 2 && hisat2 --version | head -n 1 && samtools --version | head -n 1 && featureCounts -v
```

Check the available resources:

```bash
echo "CPU=$(nproc)" && free -h
```

For this practical, use **2 threads**.

Create the complete directory structure with one command:

```bash
mkdir -p ~/input ~/results/{fastqc,reference,alignment,bam,featurecounts,logs}
```

The structure is:

```text
~
├── input/
└── results/
    ├── fastqc/
    ├── reference/
    ├── alignment/
    ├── bam/
    ├── featurecounts/
    └── logs/
```

Open a **second terminal** in Codespaces and start the results server by copying and pasting:

```bash
python -m http.server 8000 --directory ~/results
```

The Docker image does **not** automatically expose or open port 8000. The server starts only when the student runs the command above.

After running it, open the **PORTS** tab in Codespaces and open port **8000** in the browser.

Keep this second terminal running during the practical. New files written under `~/results` will become available through the browser automatically.

---

# Step 2 — Airway samples used

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

For a 2-core teaching Codespace, the command below downloads the **first 200,000 paired-end spots from each run** rather than the complete SRA runs. This keeps the 4 vs 4 biological design while reducing classroom runtime.

---

# Step 3 — Download all 8 paired-end FASTQ datasets

Run this single command:

```bash
(cd ~/input && for run in SRR1039508 SRR1039509 SRR1039512 SRR1039513 SRR1039516 SRR1039517 SRR1039520 SRR1039521; do fastq-dump --split-files --gzip --skip-technical -N 1 -X 200000 "$run"; done)
```

Check that 16 FASTQ files were created:

```bash
ls -lh ~/input/*.fastq.gz
```

Optional FASTQ summary:

```bash
seqkit stats ~/input/*.fastq.gz
```

---

# Step 4 — Create the 4 vs 4 metadata file

Run this single command:

```bash
printf "sample\tcell_line\tcondition\nSRR1039508\tN61311\tuntreated\nSRR1039509\tN61311\tdexamethasone\nSRR1039512\tN052611\tuntreated\nSRR1039513\tN052611\tdexamethasone\nSRR1039516\tN080611\tuntreated\nSRR1039517\tN080611\tdexamethasone\nSRR1039520\tN061011\tuntreated\nSRR1039521\tN061011\tdexamethasone\n" > ~/results/airway_metadata.tsv
```

View it:

```bash
column -t -s $'\t' ~/results/airway_metadata.tsv
```

---

# Step 5 — Download GRCh38.p14 reference, annotation and HISAT2 index

The supplied report specifies the human **GRCh38.p14** assembly from Ensembl.

This practical uses the Ensembl release 112 GRCh38 primary assembly and GTF, together with a pre-built HISAT2 GRCh38 index.

Run this single command:

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

# Step 6 — Raw-read quality control with FastQC

Run FastQC on all 16 FASTQ files with one command:

```bash
fastqc -t 2 ~/input/*.fastq.gz -o ~/results/fastqc
```

Output:

```text
~/results/fastqc/
```

For each read file, FastQC generates an HTML report and a ZIP archive.

Inspect the reports before continuing.

## Trimming decision

For the Airway teaching FASTQ files used in this practical, the raw FastQC reports can show satisfactory quality across the major checks. Therefore **no trimming command is included in the main workflow** and HISAT2 uses the downloaded raw FASTQ files directly.

If a future dataset shows poor FastQC results — for example substantial adapter contamination or poor-quality read ends — trimming should be performed before alignment, followed by another FastQC assessment.

Trim Galore remains installed in the Docker image for that situation, but it is not run in this practical.

---

# Step 7 — Align all 8 raw FASTQ samples with HISAT2

HISAT2 now reads directly from:

```text
~/input/
```

Run alignment for all 8 paired-end samples with one command:

```bash
for r1 in ~/input/*_1.fastq.gz; do sample=$(basename "$r1" _1.fastq.gz); hisat2 -p 2 -x ~/results/reference/grch38/genome -1 "$r1" -2 "$HOME/input/${sample}_2.fastq.gz" -S "$HOME/results/alignment/${sample}.sam" 2> "$HOME/results/logs/${sample}.hisat2.log"; done
```

SAM files:

```text
~/results/alignment/
```

HISAT2 alignment summaries:

```text
~/results/logs/
```

View the overall alignment rates for all 8 samples:

```bash
grep "overall alignment rate" ~/results/logs/*.hisat2.log
```

---

# Step 8 — Convert SAM to sorted and indexed BAM

Run SAMtools on all 8 SAM files with one command:

```bash
for sam in ~/results/alignment/*.sam; do sample=$(basename "$sam" .sam); samtools sort -@ 2 -m 512M -o "$HOME/results/bam/${sample}.sorted.bam" "$sam" && samtools index -@ 2 "$HOME/results/bam/${sample}.sorted.bam"; done
```

Create flagstat reports for all BAM files with one command:

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

# Step 9 — Gene quantification with featureCounts

Run featureCounts on all 8 BAM files with one command:

```bash
featureCounts -T 2 -p --countReadPairs -s 0 -t exon -g gene_id -a ~/results/reference/Homo_sapiens.GRCh38.112.gtf.gz -o ~/results/featurecounts/airway_gene_counts.txt ~/results/bam/*.sorted.bam
```

Main outputs:

```text
~/results/featurecounts/airway_gene_counts.txt
~/results/featurecounts/airway_gene_counts.txt.summary
```

Create a compact count matrix with one command:

```bash
grep -v '^#' ~/results/featurecounts/airway_gene_counts.txt | cut -f1,7- > ~/results/featurecounts/airway_gene_counts_matrix.tsv
```

The resulting matrix contains one gene column followed by counts for all 8 samples and can be used in the subsequent DESeq2 practical.

---

# Step 10 — Download the output files

If the server from Step 1 is still running, return to the Codespaces **PORTS** tab and open port **8000**.

The browser will show the contents of:

```text
~/results/
```

including:

```text
fastqc/
reference/
alignment/
bam/
featurecounts/
logs/
airway_metadata.tsv
```

If the server was stopped, restart it in the second terminal:

```bash
python -m http.server 8000 --directory ~/results
```

Stop the server with:

```text
Ctrl+C
```

---

# Complete student command sequence

### 1. Create folders

```bash
mkdir -p ~/input ~/results/{fastqc,reference,alignment,bam,featurecounts,logs}
```

### 2. In a second terminal, serve the results directory

```bash
python -m http.server 8000 --directory ~/results
```

### 3. Download all 8 paired-end Airway subsets

```bash
(cd ~/input && for run in SRR1039508 SRR1039509 SRR1039512 SRR1039513 SRR1039516 SRR1039517 SRR1039520 SRR1039521; do fastq-dump --split-files --gzip --skip-technical -N 1 -X 200000 "$run"; done)
```

### 4. Download reference + GTF + HISAT2 index

```bash
curl -L https://ftp.ensembl.org/pub/release-112/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz -o ~/results/reference/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz && curl -L https://ftp.ensembl.org/pub/release-112/gtf/homo_sapiens/Homo_sapiens.GRCh38.112.gtf.gz -o ~/results/reference/Homo_sapiens.GRCh38.112.gtf.gz && curl -L https://genome-idx.s3.amazonaws.com/hisat/grch38_genome.tar.gz -o ~/results/reference/grch38_genome.tar.gz && tar -xzf ~/results/reference/grch38_genome.tar.gz -C ~/results/reference && rm ~/results/reference/grch38_genome.tar.gz
```

### 5. Raw FastQC

```bash
fastqc -t 2 ~/input/*.fastq.gz -o ~/results/fastqc
```

If the FastQC reports are satisfactory, continue directly to HISAT2. If the reports show substantial adapter contamination or poor-quality ends, perform trimming and then repeat FastQC before alignment.

### 6. HISAT2 directly from raw FASTQ

```bash
for r1 in ~/input/*_1.fastq.gz; do sample=$(basename "$r1" _1.fastq.gz); hisat2 -p 2 -x ~/results/reference/grch38/genome -1 "$r1" -2 "$HOME/input/${sample}_2.fastq.gz" -S "$HOME/results/alignment/${sample}.sam" 2> "$HOME/results/logs/${sample}.hisat2.log"; done
```

### 7. SAM → sorted/indexed BAM

```bash
for sam in ~/results/alignment/*.sam; do sample=$(basename "$sam" .sam); samtools sort -@ 2 -m 512M -o "$HOME/results/bam/${sample}.sorted.bam" "$sam" && samtools index -@ 2 "$HOME/results/bam/${sample}.sorted.bam"; done
```

### 8. featureCounts

```bash
featureCounts -T 2 -p --countReadPairs -s 0 -t exon -g gene_id -a ~/results/reference/Homo_sapiens.GRCh38.112.gtf.gz -o ~/results/featurecounts/airway_gene_counts.txt ~/results/bam/*.sorted.bam
```

---

## Notes

- The 8 biological samples are preserved as four untreated and four dexamethasone-treated samples.
- The `-X 200000` option intentionally reduces read depth for a classroom demonstration on a 2-core Codespace.
- Trimming is not performed automatically or included as a required command. It is a quality-dependent preprocessing decision.
- The supplied report describes Trim Galore as the preprocessing tool when trimming is required.
- The report does not provide the literal featureCounts flags. The paired-end settings used here are explicit practical implementation choices for the Airway data.
