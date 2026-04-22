# FASTQ to BAM Snakemake Workflow

This repository contains a small, readable Snakemake workflow for paired-end FASTQ alignment. It takes gzipped reads from `reads/`, optionally trims standard Illumina adapters with `cutadapt`, aligns with `bwa-mem2`, then sorts and indexes BAM files with `samtools`.

## Expected input layout

Input FASTQ files should be named like:

- `reads/<sample>_1.fastq.gz`
- `reads/<sample>_2.fastq.gz`

The sample names are listed explicitly in `config/config.yaml`.

## Workflow layout

- `Snakefile`: top-level entry point and `rule all`
- `rules/00_common.smk`: shared config variables and helper functions
- `rules/01_prepare_reference.smk`: build the bwa-mem2 index from `hs1.fa`
- `rules/02_trim_reads.smk`: trim paired-end reads with cutadapt
- `rules/03_map_reads.smk`: align reads with bwa-mem2
- `rules/04_sort_bam.smk`: coordinate-sort BAM files
- `rules/05_index_bam.smk`: create BAM indexes

## Files to edit

- `config/config.yaml`: sample names, reference FASTA, tool environment, threads, memory, and trim settings
- `Snakefile`: workflow entry point
- `rules/*.smk`: rule logic
- `tool_env` in `config/config.yaml`: existing conda environment whose `bin/` directory is added to `PATH`

## Reference FASTA

The workflow is configured for your uncompressed reference:

```text
reference/hs1.fa
```

The workflow builds the `bwa-mem2` index files from that FASTA automatically if they are missing.

## Conda environment

The workflow now uses your existing environment at:

```text
/Users/au726678/miniforge3/envs/bioinfo
```

`rules/00_common.smk` prepends that environment's `bin/` directory to `PATH`, so you do not need `--use-conda`.

Dry-run:

```bash
snakemake -n -p
```

Run locally:

```bash
snakemake --cores 8
```

## SLURM notes

The workflow keeps `threads` and `resources.mem_mb` explicit per rule so it is straightforward to submit on a cluster.

If your Snakemake installation supports the SLURM executor, a typical pattern is:

```bash
snakemake --jobs 20 --executor slurm
```

If your site uses a Snakemake profile instead, point Snakemake at that profile and keep the resource values in `config/config.yaml` as the per-job defaults.

## Outputs

- `results/bam/<sample>.bam`
- `results/bam/<sample>.bam.bai`

Intermediate files are written under `results/tmp/` and trimmed FASTQs under `results/trimmed/`.

## Why these tools and parameters

`cutadapt` is used because it is widely available, robust for paired-end adapter trimming, and easy to read in a simple workflow. The chosen settings are intentionally conservative:

- `-a` / `-A`: trim guessed standard Illumina paired-end adapter sequences from read 1 and read 2
- `-q 20`: trim low-quality ends at Q20, a common balance between stringency and retention
- `-m 30`: discard reads shorter than 30 nt after trimming so very short fragments do not align as reliably
- `--cores`: uses Snakemake-managed threads directly, which is helpful both locally and on SLURM

Because you do not know the exact adapter sequences, the workflow currently guesses the common Illumina TruSeq-style pair:

- read 1: `AGATCGGAAGAGCACACGTCTGAACTCCAGTCA`
- read 2: `AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT`

That is a reasonable default for many short-read datasets, but it is still an inference. If trimming looks unexpectedly aggressive or ineffective, the adapter settings are the first thing to revisit.

`bwa-mem2` is used as the aligner because it is a standard choice for short-read DNA alignment and is faster than classic `bwa mem` while keeping the same overall behavior. The workflow uses:

- `bwa-mem2 index`: builds the reference index once before mapping
- `bwa-mem2 mem -t`: uses the rule's thread allocation directly
- `-R`: adds a read group so each BAM is immediately usable for downstream tools that expect sample metadata

`samtools sort` and `samtools index` are kept as separate rules because that is easier to reason about, easier to rerun after failures, and cleaner for cluster scheduling.
