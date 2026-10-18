#!/bin/bash

# ===== SLURM directives =====
#SBATCH --job-name=fastqc_array
#SBATCH --account=short_term
#SBATCH --partition=interactive
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=2G
# Use master job ID (%A) and array index (%a) for per-task logs
#SBATCH --output=slurm_logs/%x_%A_%a.out
#SBATCH --error=slurm_logs/%x_%A_%a.err
#SBATCH --array=0-9

set -euo pipefail

# Always start in the submission directory for predictable paths
cd "$SLURM_SUBMIT_DIR"

OUTPUT_DIR=06_fastqc_slurm_array
APP_LOGS=app_logs

mkdir -p $APP_LOGS $OUTPUT_DIR

module purge
module load fastqc

# Build the file list. The array index selects which file this task processes.
FILES=(01_data/*.fastq.gz)
TARGET="${FILES[$SLURM_ARRAY_TASK_ID]}"

# Derive a clean basename for naming logs (e.g., bio_sample_01_R1)
sample_id=$(basename "$TARGET" .fastq.gz)

fastqc "$TARGET" -o $OUTPUT_DIR/ \
  > "$APP_LOGS/fastqc_slurm_array_${sample_id}.log" 2>&1
