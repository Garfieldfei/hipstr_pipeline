#!/bin/bash

CRAM_DIR=/cfs/earth/scratch/xiaf/hgdp/sgdp/data
SAMPLES=/cfs/earth/scratch/xiaf/hgdp/sgdp/sample/left_cram.txt

while read SAMPLE; do
	CRAM="$CRAM_DIR/${SAMPLE}"
	CRAI="${CRAM}.crai"
        
	# Check if CRAM exists
	if [[ ! -f "$CRAM" ]]; then
	     echo "MISSING: $CRAM"
	     continue
        fi

	# Check if CRAI exists, generate if missing
	#if [[ ! -f "$CRAI" ]]; then
	echo "Missing index, generating: $CRAI"
	samtools index "$CRAM" -o "$CRAI"
	#fi
done < "$SAMPLES"
												   
