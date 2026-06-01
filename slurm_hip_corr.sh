#!/bin/bash
#SBATCH --job-name=tocsv
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --array=1-22
#SBATCH --time=10:00:00
#SBATCH --partition=earth-3
#SBATCH --constraint=rhel8
#SBATCH --output=logs/csv_%A_%a.out
#SBATCH --error=logs/csv_%A_%a.err

# actvate environment
source /cfs/earth/scratch/xiaf/bin/mergeSTR/bin/activate

# Set input and output dir
INPUT_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/dumpstr
OUTPUT_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/correct

# Get chromosome name from file
VCF_NAME=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/filtered_vcf.txt)
VCF_BASENAME=$(basename "$VCF_NAME" .gz)
vcf=${INPUT_DIR}/${VCF_NAME}

/cfs/earth/scratch/xiaf/hgdp/scripts/hipstr_correction.py $vcf ${OUTPUT_DIR}/${VCF_BASENAME}

