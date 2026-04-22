# Coordinate-sort the BAM so downstream tools can index and query it efficiently.
rule sort_bam:
    input:
        "results/tmp/{sample}.unsorted.bam"
    output:
        "results/bam/{sample}.bam"
    threads: threads_for("sort", 4)
    resources:
        mem_mb=mem_for("sort", 8000),
        runtime_minutes=runtime_for("sort", 120)
    log:
        "results/logs/{sample}.sort.log"
    params:
        mem_per_thread=config.get("sort_memory_per_thread", "1G")
    shell:
        """
        mkdir -p results/bam results/logs
        samtools sort \
            -@ {threads} \
            -m {params.mem_per_thread} \
            -o {output} \
            {input} \
            > {log} 2>&1
        """
