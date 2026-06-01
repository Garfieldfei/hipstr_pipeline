#!/bin/bash
#SBATCH --job-name=filter
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --array=1-22
#SBATCH --time=24:00:00
#SBATCH --partition=earth-3
#SBATCH --constraint=rhel8
#SBATCH --output=logs/filter_%A_%a.out
#SBATCH --error=logs/filter_%A_%a.err

# actvate environment
source /cfs/earth/scratch/xiaf/bin/STRTools/strtools_venv/bin/activate

# Set input and output dir
INPUT_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/merged
OUTPUT_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/dumpstr
# Get chromosome name from file
CHR_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /cfs/earth/scratch/xiaf/hgdp/processed/chrs.txt)

vcfs=${INPUT_DIR}/merged_${CHR_NAME}.vcf
out=${OUTPUT_DIR}/${CHR_NAME}_filtered

echo "Filtering for $CHR_NAME"
dumpSTR --vcf $vcfs \
	--vcftype hipstr \
	--out $out \
    --min-locus-callrate 0.80 \
	--min-locus-hwep 0.000001 \
	--filter-regions /cfs/earth/scratch/xiaf/hgdp/sample/hg38_segdup.sorted.bed.gz \
	--filter-regions-names SEGDUP \
	--zip \
	--drop-filtered
