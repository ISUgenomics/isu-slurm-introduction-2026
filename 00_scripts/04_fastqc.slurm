#!/bin/bash

# ===== SLURM directives (read by the scheduler) =====
#SBATCH --job-name=fastqc                 # a short name for your job
#SBATCH --account=short_term              # account/allocation
#SBATCH --partition=interactive           # partition/queue
#SBATCH --time=00:05:00                   # max wall time (hh:mm:ss)
#SBATCH --nodes=1                         # number of nodes
#SBATCH --cpus-per-task=1                 # number of CPU cores
#SBATCH --mem=2G                          # memory per node
#SBATCH --output=logs/%x_%j.out           # STDOUT (%x=job-name, %j=jobid)
#SBATCH --error=logs/%x_%j.err            # STDERR
##SBATCH --mail-user=user@iastate.edu     # email address
##SBATCH --mail-type=END,FAIL             # send email when the job ends or fails

set -euo pipefail

# Always start in the submission directory for predictable paths
cd "$SLURM_SUBMIT_DIR"

./00_scripts/03_fastqc_loop_samplename.sh
