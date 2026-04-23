# Index the final BAM so random access works in IGV and downstream workflows.
rule index_bam:
    input:
        "results/bam/{sample}.bam"
    output:
        "results/bam/{sample}.bam.bai"
    threads: threads_for("index_bam", 2)
    resources:
        mem_mb=mem_for("index_bam", 2000),
        runtime=runtime_for("index_bam", 30)
    log:
        "results/logs/{sample}.index.log"
    conda:
        NGS_ENV_FILE
    shell:
        """
        mkdir -p results/logs
        samtools index -@ {threads} {input} {output} > {log} 2>&1
        """
