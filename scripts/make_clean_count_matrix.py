#!/usr/bin/env python3
import csv
import os
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: make_clean_count_matrix.py featureCounts.txt output.tsv")

src, dst = sys.argv[1:]
with open(src, newline="") as fin, open(dst, "w", newline="") as fout:
    rows = (line for line in fin if not line.startswith("#"))
    reader = csv.reader(rows, delimiter="\t")
    writer = csv.writer(fout, delimiter="\t", lineterminator="\n")
    header = next(reader)
    clean_names = []
    for p in header[6:]:
        name = os.path.basename(p).replace(".GRCh38.sorted.bam", "")
        clean_names.append(name)
    writer.writerow(["Geneid", *clean_names])
    for row in reader:
        writer.writerow([row[0], *row[6:]])
