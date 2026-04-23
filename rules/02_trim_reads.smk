# Trim adapters before alignment, using guessadapt output when available.
rule trim_reads:
    input:
        r1="reads/{sample}_1.fastq.gz",
        r2="reads/{sample}_2.fastq.gz",
        guessed_r1="results/adapters/{sample}.read1.txt",
        guessed_r2="results/adapters/{sample}.read2.txt"
    output:
        r1="results/trimmed/{sample}_1.fastq.gz",
        r2="results/trimmed/{sample}_2.fastq.gz"
    threads: threads_for("trim", 4)
    resources:
        mem_mb=mem_for("trim", 4000),
        runtime=runtime_for("trim", 60)
    log:
        "results/logs/{sample}.cutadapt.log"
    conda:
        "envs/ngs.yaml"
    params:
        fallback_args=fallback_cutadapt_args(),
        quality_cutoff=TRIM_QUALITY_CUTOFF,
        minimum_length=MINIMUM_TRIMMED_LENGTH
    shell:
        """
        mkdir -p results/trimmed results/logs
        if [ -s "{input.guessed_r1}" ] && [ -s "{input.guessed_r2}" ]; then
            adapter_r1=$(tr -d '\\r\\n' < "{input.guessed_r1}")
            adapter_r2=$(tr -d '\\r\\n' < "{input.guessed_r2}")
            cutadapt \
                --cores {threads} \
                -a "$adapter_r1" \
                -A "$adapter_r2" \
                -q {params.quality_cutoff} \
                -m {params.minimum_length} \
                -o {output.r1} \
                -p {output.r2} \
                {input.r1} {input.r2} \
                > {log} 2>&1
        else
            cutadapt \
                --cores {threads} \
                {params.fallback_args} \
                -q {params.quality_cutoff} \
                -m {params.minimum_length} \
                -o {output.r1} \
                -p {output.r2} \
                {input.r1} {input.r2} \
                > {log} 2>&1
        fi
        """
