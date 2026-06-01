#!/bin/bash
#SBATCH --job-name=merge
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --array=1-22
#SBATCH --time=24:00:00
#SBATCH --partition=earth-3
#SBATCH --constraint=rhel8
#SBATCH --output=logs/merge_%A_%a.out
#SBATCH --error=logs/merge_%A_%a.err

# actvate environment
source /cfs/earth/scratch/xiaf/bin/mergeSTR/bin/activate

# Set input and output dir
INPUT_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/split
MERGE_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/merged

# Get chromosome name from file
CHR_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /cfs/earth/scratch/xiaf/hgdp/processed/chrs.txt)
vcfs=$(ls ${INPUT_DIR}/*_${CHR_NAME}.vcf.gz | paste -sd, -)

echo "Merging files for $CHR_NAME"
mergeSTR --vcfs "$vcfs" --vcftype hipstr --out ${MERGE_DIR}/merged_${CHR_NAME}


