FROM condaforge/miniforge3:latest

ARG AIRWAY_SPOTS=200000
ENV COURSE_ROOT=/opt/airway-rnaseq \
    THREADS=2 \
    PYTHONUNBUFFERED=1

COPY environment.yml /tmp/environment.yml
RUN mamba env update -n base -f /tmp/environment.yml && \
    mamba clean --all --yes && \
    rm -f /tmp/environment.yml

COPY docker/preload_course_data.sh /usr/local/bin/preload_course_data.sh
RUN chmod +x /usr/local/bin/preload_course_data.sh && \
    /usr/local/bin/preload_course_data.sh "${COURSE_ROOT}" "${AIRWAY_SPOTS}"

RUN useradd -m -s /bin/bash vscode && \
    mkdir -p /workspace && \
    chown -R vscode:vscode /workspace

WORKDIR /workspace
USER vscode
CMD ["bash"]
