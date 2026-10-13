#!/usr/bin/env bash

# ===== SLURM directives (read by the scheduler) =====
#SBATCH --job-name=fastqc            # a short name for your job
#SBATCH --account=short_term              # account/allocation
#SBATCH --partition=interactive           # partition/queue
#SBATCH --time=00:05:00                   # max wall time (hh:mm:ss)
#SBATCH --nodes=1                         # number of nodes
#SBATCH --cpus-per-task=10                 # number of CPU cores
#SBATCH --mem=8G                          # memory per node
#SBATCH --output=logs/%x_%j.out           # STDOUT (%x=job-name, %j=jobid)
#SBATCH --error=logs/%x_%j.err            # STDERR
##SBATCH --mail-user=user@iastate.edu  # email address
##SBATCH --mail-type=ALL                   # send email on all events, BEGIN, END, FAIL

set -euo pipefail

00_scripts/05_fastqc_parallel_improved.sh
