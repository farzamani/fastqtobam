configfile: "config/config.yaml"

# Minimal paired-end FASTQ -> sorted BAM workflow.
# Expected inputs:
#   reads/{sample}_1.fastq.gz
#   reads/{sample}_2.fastq.gz
# Tools:
#   cutadapt (optional), bwa-mem2, samtools

include: "rules/00_common.smk"

rule all:
    input:
        expand("results/bam/{sample}.bam", sample=SAMPLES),
        expand("results/bam/{sample}.bam.bai", sample=SAMPLES),


include: "rules/01_prepare_reference.smk"
include: "rules/02_guess_adapters.smk"
include: "rules/02_trim_reads.smk"
include: "rules/03_map_reads.smk"
include: "rules/04_sort_bam.smk"
include: "rules/05_index_bam.smk"
