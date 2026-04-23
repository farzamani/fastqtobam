# FASTQ to BAM Snakemake Workflow

Minimal Snakemake workflow for paired-end FASTQ alignment. The pipeline guesses adapter sequences with `guessadapt`, trims reads with `cutadapt`, aligns with `bwa-mem2`, and produces sorted, indexed BAM files with `samtools`. Template-length filtering and duplicate marking are configurable so the workflow can more closely match published cfWGS pipelines while still using `hs1`.

## Input

- `reads/<sample>_1.fastq.gz`
- `reads/<sample>_2.fastq.gz`

Samples are listed in `config/samples.yaml`.

## Reference

- `reference/hs1.fa`

The workflow builds the `bwa-mem2` index automatically if it is missing.

## Run

Dry-run:

```bash
snakemake -n -p --use-conda
```

Run locally:

```bash
snakemake --cores 8 --use-conda
```

Run on SLURM:

```bash
snakemake --jobs 20 --executor slurm --use-conda
```

## Output

- `results/bam/<sample>.bam`
- `results/bam/<sample>.bam.bai`

## Notes

- Rule files are in `rules/`
- Main settings are in `config/config.yaml`
- `guessadapt` runs before trimming for each sample
- Configured adapter sequences are kept as a fallback if `guessadapt` does not produce a usable adapter
- Template-length filtering is controlled by `template_length_filter`
- Duplicate marking is controlled by `duplicate_marking`
