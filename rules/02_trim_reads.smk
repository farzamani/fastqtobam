# Trim standard Illumina adapters before alignment.
rule trim_reads:
    input:
        r1="reads/{sample}_1.fastq.gz",
        r2="reads/{sample}_2.fastq.gz"
    output:
        r1="results/trimmed/{sample}_1.fastq.gz",
        r2="results/trimmed/{sample}_2.fastq.gz"
    threads: threads_for("trim", 4)
    resources:
        mem_mb=mem_for("trim", 4000),
        runtime_minutes=runtime_for("trim", 60)
    log:
        "results/logs/{sample}.cutadapt.log"
    params:
        adapter_r1=TRIM_READ1_ADAPTER,
        adapter_r2=TRIM_READ2_ADAPTER,
        quality_cutoff=TRIM_QUALITY_CUTOFF,
        minimum_length=MINIMUM_TRIMMED_LENGTH
    shell:
        """
        mkdir -p results/trimmed results/logs
        cutadapt \
            --cores {threads} \
            -a {params.adapter_r1} \
            -A {params.adapter_r2} \
            -q {params.quality_cutoff} \
            -m {params.minimum_length} \
            -o {output.r1} \
            -p {output.r2} \
            {input.r1} {input.r2} \
            > {log} 2>&1
        """
