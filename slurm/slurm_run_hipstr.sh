#!/bin/bash
#SBATCH --job-name=hipstr
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --array=1-3
#SBATCH --time=20:00:00
#SBATCH --partition=earth-3
#SBATCH --constraint=rhel8
#SBATCH --output=logs/hipstr_%A_%a.out
#SBATCH --error=logs/hipstr_%A_%a.err

# Load modules if needed

# Paths
CRAM_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/data
REF=/cfs/earth/scratch/xiaf/hgdp/ref/GRCh38_full_analysis_set_plus_decoy_hla.fa
REGIONS=/cfs/earth/scratch/xiaf/hgdp/ref/hg38.hipstr_reference.bed
OUTDIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/raw
SAMPLES=/cfs/earth/scratch/xiaf/hgdp/sgdp/sample/cram.txt

# Get sample name from array index
SAMPLE=$(sed -n "$((SLURM_ARRAY_TASK_ID))p" "$SAMPLES")
SAMPLE_BASENAME=$(basename "$SAMPLE" .cram)

# Check if input CRAM exists
if [ ! -f "$CRAM_DIR/${SAMPLE}" ]; then
	echo "ERROR: CRAM file $CRAM_DIR/${SAMPLE} not found! Skipping."
	        exit 1
	fi

# Check if output already exists
if [ -f "$OUTDIR/${SAMPLE_BASENAME}.hipstr.vcf.gz" ]; then
       	echo "INFO: Output for $SAMPLE_BASENAME already exists. Skipping."
		exit 0
	fi

# Run HipSTR
/cfs/earth/scratch/xiaf/hgdp/HipSTR/HipSTR \
	--bams $CRAM_DIR/${SAMPLE} \
	--fasta $REF \
	--regions $REGIONS \
	--str-vcf $OUTDIR/${SAMPLE_BASENAME}.hipstr.vcf.gz \
	--log $OUTDIR/${SAMPLE}.hipstr.log \
	--min-reads 5 \
	--max-reads 2000000

