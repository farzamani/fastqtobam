import os
import yaml

# Load sample IDs from a separate YAML file so cohorts can be swapped without
# editing the rest of the workflow configuration.
with open(config["samples_file"]) as handle:
    sample_config = yaml.safe_load(handle)

SAMPLES = sample_config["samples"]
NGS_ENV_FILE = os.path.join(workflow.basedir, "envs", "ngs.yaml")

# Reference configuration:
# `reference_fasta` is the actual FASTA used for bwa-mem2 alignment.
# `bwa_index` allows the user to store the index under a different prefix if
# needed, but in the default case it is the same as the FASTA path.
REFERENCE_SOURCE = config["reference_fasta"]
REFERENCE_READY = REFERENCE_SOURCE
BWA_INDEX_PREFIX = config.get("bwa_index", REFERENCE_READY)

# Core workflow switches and shared config blocks:
# - trimming can be turned on/off globally
# - threads/resources tune local or cluster execution
# - read_group controls BAM header metadata
# - trim_adapters provides fallback adapters if guessadapt returns nothing
# - template_length_filter and duplicate_marking make the workflow closer to
#   published cfWGS processing while staying adjustable.
USE_TRIMMING = config.get("trim", True)
THREADS = config.get("threads", {})
RESOURCES = config.get("resources", {})
READ_GROUP = config.get("read_group", {})
TRIM_ADAPTERS = config.get(
    "trim_adapters", ["CTGTCTCTTATA", "AGATCGGAAGAGC", "TGGAATTCTCGG"]
)
TEMPLATE_LENGTH_FILTER = config.get("template_length_filter", {})
DUPLICATE_MARKING = config.get("duplicate_marking", {})
FASTQC_CONFIG = config.get("fastqc", {})

# Fallback adapter sequences:
# These are used only if guessadapt does not provide a usable adapter sequence
# for a sample. The config treats them as a shared list of candidate motifs
# that cutadapt should try on both mates.
FALLBACK_ADAPTERS = TRIM_ADAPTERS
TRIM_QUALITY_CUTOFF = config.get("trim_quality_cutoff", 20)
MINIMUM_TRIMMED_LENGTH = config.get("minimum_trimmed_length", 30)

# Template-length filter defaults:
# Tao et al. used a 20-1000 bp cfWGS window. These settings let the user keep
# that behavior, widen the range, or disable it completely.
TEMPLATE_FILTER_ENABLED = TEMPLATE_LENGTH_FILTER.get("enabled", True)
TEMPLATE_FILTER_MIN_BP = TEMPLATE_LENGTH_FILTER.get("min_bp", 20)
TEMPLATE_FILTER_MAX_BP = TEMPLATE_LENGTH_FILTER.get("max_bp", 1000)
TEMPLATE_FILTER_REQUIRE_PROPER_PAIR = TEMPLATE_LENGTH_FILTER.get(
    "require_proper_pair", True
)

# Duplicate-marking defaults:
# Enabled by default to keep the workflow closer to cfWGS-style processing.
# `remove_duplicates` can be switched on if the user wants duplicate removal
# rather than only duplicate tagging.
DUPLICATE_MARKING_ENABLED = DUPLICATE_MARKING.get("enabled", True)
DUPLICATE_REMOVE = DUPLICATE_MARKING.get("remove_duplicates", False)
FASTQC_ENABLED = FASTQC_CONFIG.get("enabled", True)


# Helper accessors centralize thread/memory/runtime lookups. This keeps the
# rule files simple and makes config-driven tuning consistent across the DAG.
def threads_for(step, default):
    return THREADS.get(step, default)


def mem_for(step, default):
    return RESOURCES.get(step, {}).get("mem_mb", default)


def runtime_for(step, default):
    return RESOURCES.get(step, {}).get("runtime", default)


def fallback_cutadapt_args():
    return " ".join(
        f"-a {adapter} -A {adapter}" for adapter in FALLBACK_ADAPTERS
    )


def fastqc_outputs():
    if not FASTQC_ENABLED:
        return []
    outputs = []
    for sample in SAMPLES:
        outputs.extend(
            [
                f"results/qc/fastqc/{sample}_1_fastqc.zip",
                f"results/qc/fastqc/{sample}_2_fastqc.zip",
            ]
        )
    return outputs


# These functions define whether mapping should consume trimmed FASTQs or the
# original reads directly when trimming is disabled.
def map_read1(wildcards):
    if USE_TRIMMING:
        return f"results/trimmed/{wildcards.sample}_1.fastq.gz"
    return f"reads/{wildcards.sample}_1.fastq.gz"


def map_read2(wildcards):
    if USE_TRIMMING:
        return f"results/trimmed/{wildcards.sample}_2.fastq.gz"
    return f"reads/{wildcards.sample}_2.fastq.gz"


# Build a standard `@RG` line for bwa-mem2 so downstream tools can identify the
# sample and library in the BAM header. Users should adjust library/platform
# fields here when they have more precise metadata.
def read_group(sample):
    platform = READ_GROUP.get("platform", "ILLUMINA")
    library = READ_GROUP.get("library", "default_library")
    platform_unit = READ_GROUP.get("platform_unit", sample)
    return (
        f"@RG\\tID:{sample}\\tSM:{sample}\\tPL:{platform}"
        f"\\tLB:{library}\\tPU:{platform_unit}"
    )
