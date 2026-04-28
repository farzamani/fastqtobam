# Reference

Place the reference FASTA in this directory. The default configuration uses:

- `hs1.fa`

The workflow will build the required `bwa-mem2` index files automatically if they are missing.

Other reference FASTA files can also be used. For example, to use `hg38`, place
the FASTA here as `hg38.fa` and set these values in `config/config.yaml`:

```yaml
reference_fasta: reference/hg38.fa
bwa_index: reference/hg38.fa
```
