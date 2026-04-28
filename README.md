# FASTQ to BAM Snakemake Workflow

Minimal Snakemake workflow for paired-end FASTQ alignment. The pipeline guesses adapter sequences with `guessadapt`, trims reads with `cutadapt`, aligns with `bwa-mem2`, and produces sorted, indexed BAM files with `samtools`. Template-length filtering and duplicate marking are configurable so the workflow can more closely match the cfWGS preprocessing described by Tao et al. while still using `hs1`.

This project was built with help from OpenAI Codex.

## Input

- `reads/<sample>_1.fastq.gz`
- `reads/<sample>_2.fastq.gz`

Samples are listed in `config/samples.yaml`.

## Reference Genome

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
- `results/qc/fastqc/*`
- `results/qc/samtools_stats/<sample>.txt`
- `results/qc/multiqc/multiqc_report.html`

## Notes

- Rule files are in `rules/`
- Main settings are in `config/config.yaml`
- The shared conda environment file is resolved from the workflow root so `--use-conda` works more reliably on cluster filesystems
- `guessadapt` runs before trimming for each sample
- Configured adapter sequences are kept as a fallback if `guessadapt` does not produce a usable adapter
- Raw-read FastQC is controlled by `fastqc`
- Template-length filtering is controlled by `template_length_filter`
- Duplicate marking is controlled by `duplicate_marking`
- Simple QC is included via `fastqc`, `samtools stats`, and `multiqc`

## Publication Reference

Tao Y. et al. Cell-free multi-omics analysis reveals potential biomarkers in gastrointestinal cancer patients' blood. *Cell Reports Medicine* 4(11):101281, 2023. https://doi.org/10.1016/j.xcrm.2023.101281
