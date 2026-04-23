# Guess adapter sequences before trimming.
rule guess_adapters:
    input:
        r1="reads/{sample}_1.fastq.gz",
        r2="reads/{sample}_2.fastq.gz"
    output:
        r1="results/adapters/{sample}.read1.txt",
        r2="results/adapters/{sample}.read2.txt"
    threads: threads_for("guess_adapters", 1)
    resources:
        mem_mb=mem_for("guess_adapters", 2000),
        runtime=runtime_for("guess_adapters", 15)
    log:
        "results/logs/{sample}.guessadapt.log"
    conda:
        NGS_ENV_FILE
    shell:
        """
        mkdir -p results/adapters results/logs
        guessadapt {input.r1} > {output.r1}.tmp 2> {log}
        guessadapt {input.r2} > {output.r2}.tmp 2>> {log}
        awk 'NF {{ print $1; exit }}' {output.r1}.tmp > {output.r1}
        awk 'NF {{ print $1; exit }}' {output.r2}.tmp > {output.r2}
        rm -f {output.r1}.tmp {output.r2}.tmp
        """
