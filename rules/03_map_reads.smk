# Align reads to the reference and write an unsorted BAM as an intermediate.
rule map_reads:
    input:
        ref=REFERENCE_READY,
        idx=rules.index_reference.output,
        r1=map_read1,
        r2=map_read2
    output:
        temp("results/tmp/{sample}.unsorted.bam")
    threads: threads_for("map", 8)
    resources:
        mem_mb=mem_for("map", 16000),
        runtime_minutes=runtime_for("map", 240)
    log:
        "results/logs/{sample}.bwa-mem2.log"
    params:
        rg=lambda wildcards: read_group(wildcards.sample)
    shell:
        """
        mkdir -p results/tmp results/logs
        bwa-mem2 mem \
            -t {threads} \
            -R '{params.rg}' \
            {input.ref} {input.r1} {input.r2} \
            2> {log} \
        | samtools view -@ {threads} -b -o {output} -
        """
