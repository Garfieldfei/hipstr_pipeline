#!/bin/bash
#SBATCH --job-name=split_hipstr
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --array=1-4
#SBATCH --partition=earth-3
#SBATCH --constraint=rhel8
#SBATCH --output=logs/split.out
#SBATCH --error=logs/split.err

# actvate environment
source /cfs/earth/scratch/xiaf/bin/STRTools/strtools_venv/bin/activate

# Set input and output dir
INPUT_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/raw/left
OUTPUT_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/hipstr/split
# MERGE_DIR=/cfs/earth/scratch/xiaf/hgdp/filtered/merged

# Define chromosomes chr1-chr22
CHROMS=$(seq 1 22) 

# Step 1: Split each sample VCF by chromosome
echo "Step 1: Splitting VCFs per sample per chromosome..."
for vcf in $INPUT_DIR/*.vcf.gz; do
	sample=$(basename "$vcf" .hipstr.vcf.gz)
	tabix -p vcf "$vcf"  # index if needed
	for chr in $CHROMS; do
		chr_name="chr${chr}"  # adjust to just $chr if your VCF uses 1,2,... instead of chr1,chr2,...
		out_vcf="${OUTPUT_DIR}/${sample}_${chr_name}.vcf.gz"
		bcftools view -r $chr_name -Oz -o "$out_vcf" "$vcf"
		tabix -p vcf "$out_vcf"
	done
done
