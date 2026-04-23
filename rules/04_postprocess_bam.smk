# Name-sort the BAM so samtools fixmate can add mate-aware tags.
rule name_sort_bam:
    input:
        "results/tmp/{sample}.unsorted.bam"
    output:
        temp("results/tmp/{sample}.namesort.bam")
    threads: threads_for("name_sort", 4)
    resources:
        mem_mb=mem_for("name_sort", 8000),
        runtime=runtime_for("name_sort", 120)
    log:
        "results/logs/{sample}.namesort.log"
    conda:
        "envs/ngs.yaml"
    params:
        mem_per_thread=config.get("sort_memory_per_thread", "1G")
    shell:
        """
        mkdir -p results/tmp results/logs
        samtools sort \
            -n \
            -@ {threads} \
            -m {params.mem_per_thread} \
            -o {output} \
            {input} \
            > {log} 2>&1
        """


# Add mate tags needed for duplicate marking on coordinate-sorted BAMs.
rule fixmate_bam:
    input:
        "results/tmp/{sample}.namesort.bam"
    output:
        temp("results/tmp/{sample}.fixmate.bam")
    threads: threads_for("fixmate", 2)
    resources:
        mem_mb=mem_for("fixmate", 4000),
        runtime=runtime_for("fixmate", 60)
    log:
        "results/logs/{sample}.fixmate.log"
    conda:
        "envs/ngs.yaml"
    shell:
        """
        mkdir -p results/tmp results/logs
        samtools fixmate \
            -m \
            -@ {threads} \
            {input} {output} \
            > {log} 2>&1
        """


# Coordinate-sort the BAM for filtering, duplicate marking, and indexing.
rule sort_bam:
    input:
        "results/tmp/{sample}.fixmate.bam"
    output:
        temp("results/tmp/{sample}.sorted.bam")
    threads: threads_for("sort", 4)
    resources:
        mem_mb=mem_for("sort", 8000),
        runtime=runtime_for("sort", 120)
    log:
        "results/logs/{sample}.sort.log"
    conda:
        "envs/ngs.yaml"
    params:
        mem_per_thread=config.get("sort_memory_per_thread", "1G")
    shell:
        """
        mkdir -p results/tmp results/logs
        samtools sort \
            -@ {threads} \
            -m {params.mem_per_thread} \
            -o {output} \
            {input} \
            > {log} 2>&1
        """


# Optionally restrict the BAM to a template-length range.
rule filter_template_length:
    input:
        "results/tmp/{sample}.sorted.bam"
    output:
        temp("results/tmp/{sample}.filtered.bam")
    threads: threads_for("filter_template_length", 2)
    resources:
        mem_mb=mem_for("filter_template_length", 4000),
        runtime=runtime_for("filter_template_length", 60)
    log:
        "results/logs/{sample}.template_filter.log"
    conda:
        "envs/ngs.yaml"
    params:
        enabled=str(TEMPLATE_FILTER_ENABLED).lower(),
        min_bp=TEMPLATE_FILTER_MIN_BP,
        max_bp=TEMPLATE_FILTER_MAX_BP,
        proper_pair_flag="-f 2" if TEMPLATE_FILTER_REQUIRE_PROPER_PAIR else ""
    shell:
        """
        mkdir -p results/tmp results/logs
        if [ "{params.enabled}" = "true" ]; then
            samtools view -h {params.proper_pair_flag} {input} \
            | awk 'BEGIN {{ OFS="\\t" }} /^@/ {{ print; next }} {{ tlen=$9; if (tlen < 0) tlen=-tlen; if (tlen >= {params.min_bp} && tlen <= {params.max_bp}) print }}' \
            | samtools view -@ {threads} -b -o {output} - \
            > {log} 2>&1
        else
            samtools view -@ {threads} -b -o {output} {input} > {log} 2>&1
        fi
        """


# Optionally mark or remove duplicates on the filtered coordinate-sorted BAM.
rule mark_duplicates:
    input:
        "results/tmp/{sample}.filtered.bam"
    output:
        "results/bam/{sample}.bam"
    threads: threads_for("mark_duplicates", 4)
    resources:
        mem_mb=mem_for("mark_duplicates", 8000),
        runtime=runtime_for("mark_duplicates", 120)
    log:
        "results/logs/{sample}.markdup.log"
    conda:
        "envs/ngs.yaml"
    params:
        enabled=str(DUPLICATE_MARKING_ENABLED).lower(),
        remove_flag="-r" if DUPLICATE_REMOVE else ""
    shell:
        """
        mkdir -p results/bam results/logs
        if [ "{params.enabled}" = "true" ]; then
            samtools markdup \
                -@ {threads} \
                {params.remove_flag} \
                {input} {output} \
                > {log} 2>&1
        else
            samtools view -@ {threads} -b -o {output} {input} > {log} 2>&1
        fi
        """
