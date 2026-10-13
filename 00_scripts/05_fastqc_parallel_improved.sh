#!/usr/bin/env bash

set -euo pipefail # error handling: 
                  # -e: exit immediately if any command returns a non-zero exit status (error) 
                  # -u: treat unset variables as an error and exit (useful for debugging)
                  # -o pipefail: exit if any command in a pipeline fails (useful for debugging)

# Directories
# Input directory
INPUT_DIR="01_data"

# Output directory
OUTPUT_DIR="06_fastqc_parallel_improved"

# Log directory
LOG_DIR="logs"

# Create required directories
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# make them visible to subshells that parallel spawns
export OUTPUT_DIR LOG_DIR INPUT_DIR

# Load required modules
module load parallel
module load fastqc

# Run FastQC
parallel -j10 \
  'fastqc "{1}" -o "$OUTPUT_DIR/" > "$LOG_DIR/05_fastqc_parallel_improved_{1/.}.log" 2>&1' \
  ::: $INPUT_DIR/*.fastq.gz
