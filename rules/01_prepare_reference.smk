# Build the bwa-mem2 index once so mapping jobs can run independently on SLURM.
rule index_reference:
    input:
        REFERENCE_READY
    output:
        BWA_INDEX_PREFIX + ".0123",
        BWA_INDEX_PREFIX + ".amb",
        BWA_INDEX_PREFIX + ".ann",
        BWA_INDEX_PREFIX + ".bwt.2bit.64",
        BWA_INDEX_PREFIX + ".pac",
    threads: threads_for("index", 8)
    resources:
        mem_mb=mem_for("index", 32000),
        runtime=runtime_for("index", 240)
    log:
        "results/logs/reference.index.log"
    conda:
        "envs/ngs.yaml"
    shell:
        """
        mkdir -p results/logs
        bwa-mem2 index {input} > {log} 2>&1
        """
