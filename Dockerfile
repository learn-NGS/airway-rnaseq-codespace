FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates bzip2 && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L \
    https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
    -o /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm -f /tmp/miniforge.sh

ENV PATH="/opt/conda/bin:${PATH}"

RUN mamba install -y -n base \
    -c conda-forge \
    -c bioconda \
    python=3.12 \
    fastqc \
    trim-galore \
    hisat2 \
    samtools \
    subread \
    sra-tools \
    seqkit \
    pigz \
    wget && \
    mamba clean --all --yes && \
    chmod -R a+rX /opt/conda

USER vscode
