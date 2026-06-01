# HipSTR Pipeline

This repository contains a reproducible Nextflow workflow for the HipSTR STR calling pipeline.

## Structure

- `main.nf` - Nextflow workflow orchestrating each pipeline stage
- `nextflow.config` - default pipeline configuration and tool paths
- `hipstr_correction.py` - VCF correction script used after filtering
- `hipstr_vcf.py` - converts corrected HipSTR VCFs into STR matrices
- `download.sh`, `crai_check.sh`, `slurm_run_hipstr.sh`, `split_hipstr.sh`, `merge_slurm.sh`, `filter_slurm.sh`, `slurm_hip_corr.sh`, `slurm_hipstr_vcf.sh` - original shell scripts retained for reference

## How to run

1. Install Nextflow: https://www.nextflow.io/
2. Review `nextflow.config` and update file paths for your environment.
3. Run the pipeline:

```bash
nextflow run .
```

4. To run using SLURM, use the `slurm` profile:

```bash
nextflow run . -profile slurm
```

## Configuration

The workflow uses parameters from `nextflow.config`:

- `ref` - reference FASTA
- `regions` - HipSTR regions BED
- `segdup` - segmental duplication BED for filtering
- `cram_download_list` - list of CRAM URLs for download
- `cram_list` - CRAM file names to process with HipSTR
- `left_cram_list` - CRAM names to validate CRAI indexes
- `filtered_vcf_list` - filtered VCF names passed to correction
- `correct_vcf_list` - corrected VCF names passed to matrix conversion
- `chrs_list` - chromosome names used for merge/filter steps

## Output directories

- `data/` - downloaded CRAM and CRAI files
- `hipstr/raw/` - raw per-sample HipSTR VCF outputs
- `hipstr/split/` - chromosome-split VCFs
- `hipstr/merged/` - per-chromosome merged VCFs
- `hipstr/dumpstr/` - filtered VCF outputs
- `hipstr/correct/` - corrected VCFs
- `hipstr/df_str/` - final STR matrix CSV outputs

## Notes

- The workflow is intentionally parameterized so you can update paths without editing the pipeline logic.
- Existing shell scripts are retained in case you want to compare the Nextflow implementation with the original SLURM commands.
