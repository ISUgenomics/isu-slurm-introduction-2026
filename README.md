# Introduction to SLURM

**Instructors:** Viswanathan <u>Satheesh</u>, Rick <u>Masonbrink</u>

**Affiliation:** Bioinformatics Facility, Iowa State University

**Contact:** bioinformatics@iastate.edu | satheesh@iastate.edu

- Focus: running commands on a compute node, turning commands into scripts, writing and submitting SLURM batch jobs, monitoring and debugging jobs, checking resource efficiency, and running job arrays

## Quick start to access the workshop environment

- Log in to [Nova OnDemand](https://nova-ondemand.its.iastate.edu/) in a browser.

- From the top menu bar, choose **Clusters → Nova Shell Access**.

- Create your working directory if it does not already exist:

  ```bash
  cd /work/short_term/
  mkdir -p "$USER"
  cd "$USER"
  ```

- Later in the workshop, scripts are edited with **VS Code Server** (Interactive Apps → VS Code Server):

  ```
  Account: short_term
  Partition: interactive
  Number of hour: 5
  Number of Tasks per node: 10
  Memory Required: 8G
  Working Directory: /work/short_term/<your username>
  ```

- Clone the Git repository (inside an interactive session on a compute node, as described in the workshop guide):

  ```bash
  git clone https://github.com/ISUgenomics/slurm-workshop-2026.git
  ```

## Layout

- `slurm_workshop.md` — step-by-step workshop guide
- `00_scripts/` — reference scripts used in the workshop
- `assets/` — screenshots used in the guide

## Scripts

1. `01_fastqc.sh` — run FastQC on one file
2. `02_fastqc_loop.sh` — loop over all files
3. `03_fastqc_loop_samplename.sh` — loop with per-sample log files
4. `04_fastqc.slurm` — submit the loop as a SLURM batch job
5. `05_fastqc_array.slurm` — run one task per file with a SLURM job array

## Workshop guide

[From Bash Scripts to SLURM Arrays](slurm_workshop.md)

1. Quick start
2. Part 1: Running commands and making a script of the commands run
3. Part 2: Building a SLURM script
4. Part 3: SLURM Job Arrays
