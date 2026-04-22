# FASTQ to BAM Snakemake Workflow

Minimal Snakemake workflow for paired-end FASTQ alignment. The pipeline optionally trims Illumina adapters with `cutadapt`, aligns reads with `bwa-mem2`, and produces sorted, indexed BAM files with `samtools`.

## Input

- `reads/<sample>_1.fastq.gz`
- `reads/<sample>_2.fastq.gz`

Samples are listed in `config/config.yaml`.

## Reference

- `reference/hs1.fa`

The workflow builds the `bwa-mem2` index automatically if it is missing.

## Run

Dry-run:

```bash
snakemake -n -p
```

Run locally:

```bash
snakemake --cores 8
```

Run on SLURM:

```bash
snakemake --jobs 20 --executor slurm
```

## Output

- `results/bam/<sample>.bam`
- `results/bam/<sample>.bam.bai`

## Notes

- Rule files are in `rules/`
- Main settings are in `config/config.yaml`
- Adapter sequences are guessed Illumina defaults and may need adjustment for other library types
