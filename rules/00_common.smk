SAMPLES = config["samples"]
REFERENCE_SOURCE = config["reference_fasta"]
REFERENCE_READY = REFERENCE_SOURCE
BWA_INDEX_PREFIX = config.get("bwa_index", REFERENCE_READY)
USE_TRIMMING = config.get("trim", True)
THREADS = config.get("threads", {})
RESOURCES = config.get("resources", {})
READ_GROUP = config.get("read_group", {})
TRIM_ADAPTERS = config.get("trim_adapters", {})
TRIM_READ1_ADAPTER = TRIM_ADAPTERS.get(
    "read1", "AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"
)
TRIM_READ2_ADAPTER = TRIM_ADAPTERS.get(
    "read2", "AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT"
)
TRIM_QUALITY_CUTOFF = config.get("trim_quality_cutoff", 20)
MINIMUM_TRIMMED_LENGTH = config.get("minimum_trimmed_length", 30)

def threads_for(step, default):
    return THREADS.get(step, default)


def mem_for(step, default):
    return RESOURCES.get(step, {}).get("mem_mb", default)


def runtime_for(step, default):
    return RESOURCES.get(step, {}).get("runtime", default)


def map_read1(wildcards):
    if USE_TRIMMING:
        return f"results/trimmed/{wildcards.sample}_1.fastq.gz"
    return f"reads/{wildcards.sample}_1.fastq.gz"


def map_read2(wildcards):
    if USE_TRIMMING:
        return f"results/trimmed/{wildcards.sample}_2.fastq.gz"
    return f"reads/{wildcards.sample}_2.fastq.gz"


def read_group(sample):
    platform = READ_GROUP.get("platform", "ILLUMINA")
    library = READ_GROUP.get("library", "default_library")
    platform_unit = READ_GROUP.get("platform_unit", sample)
    return (
        f"@RG\\tID:{sample}\\tSM:{sample}\\tPL:{platform}"
        f"\\tLB:{library}\\tPU:{platform_unit}"
    )
