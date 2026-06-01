#!/bin/bash

# Define variables
FILE_LIST="/cfs/earth/scratch/xiaf/hgdp/sgdp/sample/cram_download.txt"  # File containing CRAM URLs
OUTPUT_DIR="/cfs/earth/scratch/xiaf/hgdp/sgdp/data"          # Directory to save BAM files
LOG_FILE="/cfs/earth/scratch/xiaf/hgdp/sgdp/download.log"            # Log file to record download status
#SKIP_LIST="/cfs/earth/scratch/xiaf/hgdp/sample/cram_list.txt"
NUM_FILES=40                      # Number of files to download

# Create output directory and log file
# mkdir -p "$OUTPUT_DIR"
echo "Download started: $(date)" > "$LOG_FILE"

# Extract first NUM_FILES lines and download each file
count=0
head -n 40 "$FILE_LIST" | while read -r url; do

	# Stop after NUM_FILES downloads
	if [ "$count" -gt "$NUM_FILES" ]; then
		break
	fi

	filename=$(basename "$url")
	file_path="$OUTPUT_DIR/$filename"

	if [ -f "$file_path" ]; then
        	echo "[SKIPPED] File $count: $filename already exists, skipping." | tee -a "$LOG_FILE"
		continue
	fi

	#if grep -Fxq "$filename" "$SKIP_LIST"; then
	#	echo "[SKIPPED] File $count: $filename is listed in $SKIP_LIST, skipping." | tee -a "$LOG_FILE"
	#	continue
	#fi
        
        	
	echo "Downloading file $count: $url ..."
	wget -q -P "$OUTPUT_DIR" "$url"
	crai_url="${url}.crai"
	wget -q -P "$OUTPUT_DIR" "$crai_url"
        ((count++))
	# Check if the download was successful
	if [ $? -eq 0 ]; then
		echo "[SUCCESS] File $count: $(basename "$url") downloaded." | tee -a "$LOG_FILE"
	else
		echo "[ERROR] File $count: $(basename "$url") failed to download." | tee -a "$LOG_FILE"
	fi
done 

echo "Download completed: $(date)" | tee -a "$LOG_FILE"

