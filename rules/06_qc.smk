# Optionally run FastQC on raw FASTQ files before trimming.
rule fastqc_raw:
    input:
        fq="reads/{sample}_{read}.fastq.gz"
    output:
        html="results/qc/fastqc/{sample}_{read}_fastqc.html",
        zip="results/qc/fastqc/{sample}_{read}_fastqc.zip"
    threads: threads_for("fastqc", 2)
    resources:
        mem_mb=mem_for("fastqc", 2000),
        runtime=runtime_for("fastqc", 30)
    log:
        "results/logs/{sample}_{read}.fastqc.log"
    conda:
        NGS_ENV_FILE
    shell:
        """
        mkdir -p results/qc/fastqc results/logs
        fastqc \
            --threads {threads} \
            --outdir results/qc/fastqc \
            {input.fq} \
            > {log} 2>&1
        """


# Generate lightweight per-sample alignment QC from the final BAM.
rule samtools_stats:
    input:
        bam="results/bam/{sample}.bam",
        bai="results/bam/{sample}.bam.bai"
    output:
        "results/qc/samtools_stats/{sample}.txt"
    threads: threads_for("samtools_stats", 2)
    resources:
        mem_mb=mem_for("samtools_stats", 2000),
        runtime=runtime_for("samtools_stats", 30)
    log:
        "results/logs/{sample}.samtools_stats.log"
    conda:
        NGS_ENV_FILE
    shell:
        """
        mkdir -p results/qc/samtools_stats results/logs
        samtools stats -@ {threads} {input.bam} > {output} 2> {log}
        """


# Aggregate logs and QC summaries into one report.
rule multiqc:
    input:
        expand("results/qc/samtools_stats/{sample}.txt", sample=SAMPLES),
        fastqc_outputs()
    output:
        "results/qc/multiqc/multiqc_report.html"
    threads: threads_for("multiqc", 1)
    resources:
        mem_mb=mem_for("multiqc", 2000),
        runtime=runtime_for("multiqc", 30)
    log:
        "results/logs/multiqc.log"
    conda:
        NGS_ENV_FILE
    shell:
        """
        mkdir -p results/qc/multiqc results/logs
        multiqc \
            --force \
            --outdir results/qc/multiqc \
            results/qc results/logs \
            > {log} 2>&1
        """
