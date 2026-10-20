# Comprehensive Guide: From Bash Scripts to SLURM Arrays

---

## Quick start

1. Log in to Nova OnDemand through a browser: [https://nova-ondemand.its.iastate.edu/](https://nova-ondemand.its.iastate.edu/)

2. From the top menu bar, choose **Clusters → Nova Shell Access**.

   <img src="assets/01_shell_access.png" alt="Nova OnDemand Clusters menu showing Nova Shell Access option" width="700"/>

3. In the shell that opens, do the following:

```bash
pwd
# /home/$USER

cd /work/short_term
mkdir -p $USER
cd $USER
```

4. Later in the workshop we will edit scripts with VS Code Server. Open it from Nova OnDemand when needed:

   - Interactive Apps → **VS Code Server**

     <img src="assets/02_vscode_server.png" alt="Nova OnDemand Interactive Apps menu showing VS Code Server option" width="700"/>

   - Suggested settings:

     ```
     Account: short_term
     Partition: interactive
     Number of hour: 5
     Number of Tasks per node: 10
     Memory Required: 8G
     Working Directory: `/work/short_term/$USER`
     ```

   The form should look similar to this before you click **Launch**:

   <img src="assets/03_vscode_server_form.png" alt="VS Code Server launch form with account, partition, time, CPUs, memory, and working directory fields" width="700"/>

## Part 1: Running commands and making a script of the commands run

### What is a job?

- A job is a command or a script that is run on the command line.

### What is a head node?

- A head node is a node that is used to control the cluster.
- It is the node that will be used to submit your jobs to the cluster.
- Remember, we DO NOT run intensive jobs on this node. 

**Head node etiquette**: editing files, `ls`, `git`, submitting jobs, and quick tests are fine. Anything that runs more than a minute or uses significant CPU/memory belongs on a compute node — via `srun --pty bash` for interactive work or `sbatch` for batch. Heavy processes on the login node may be stopped by admins, and they slow things down for everyone sharing it.

### What is a compute node?

- A compute node is a node that is used to run your intensive jobs.

---

## Interactive jobs (quick testing)

If you want a short interactive session on a compute node:

**srun**

```bash
srun --account=short_term --partition=interactive \
     --time=00:15:00 --cpus-per-task=2 --mem=2G \
     --pty bash

nproc
# 2
```

You’ll get a shell on a compute node where you can run commands interactively. When you run `nproc`, you should see `2` as the output. That is the number of CPUs requested on this compute node (via `--cpus-per-task=2`). 

> Note: Exit with `exit` or Ctrl-D.

### Copy the data folder

This is a good first task to run on the compute node. Inside your interactive session, copy the workshop data and scripts into your working directory:

```bash
time cp -r /work/short_term/workshop_materials/satheesh_bash/01_data .
```

```
real    0m3.518s
user    0m0.001s
sys     0m0.584s
```

- `real`: wall-clock time — how long the copy took from start to finish.
- `user`: CPU time spent by the program itself (almost nothing for `cp`, since most work is I/O).
- `sys`: CPU time spent by the kernel moving data between disk and memory.

For file copies, `real` is what you care about; `user` is tiny because `cp` spends most of its time waiting on the disk.

### Clone the workshop repository

```bash
git clone https://github.com/ISUgenomics/slurm-workshop-2026.git
```

This repository contains the scripts that we are going to use. We will use these scripts in case we run into issues with the ones we create. 

### What are the files in the data folder?

```bash
ls 01_data/
```

<details>
<summary>Output</summary>
<pre>
bio_sample_01_R1.fastq.gz  bio_sample_02_R1.fastq.gz  bio_sample_03_R1.fastq.gz  bio_sample_04_R1.fastq.gz  bio_sample_05_R1.fastq.gz
bio_sample_01_R2.fastq.gz  bio_sample_02_R2.fastq.gz  bio_sample_03_R2.fastq.gz  bio_sample_04_R2.fastq.gz  bio_sample_05_R2.fastq.gz
</pre>
</details>

### Running a program on data files

#### One file

```bash
module avail fastqc 
```

- `module avail fastqc` lists the versions of FastQC installed on the cluster.

```bash
module load fastqc
```

- `module load fastqc` makes the FastQC program available in your current session (the default version is loaded if you don't specify one).

```bash
mkdir -p 02_fastqc
fastqc 01_data/bio_sample_01_R1.fastq.gz -o 02_fastqc/
```

- `fastqc 01_data/bio_sample_01_R1.fastq.gz` runs FastQC on one file. With no `-o` option, the results are written next to the input file.

```bash
ls 02_fastqc/
```

<details>
<summary>Output</summary>
<pre>
bio_sample_01_R1_fastqc.html  bio_sample_01_R1_fastqc.zip
</pre>
</details>

Remove the folders created

```bash
rm -r 02_fastqc
```

Let's write scripts. 

```bash
mkdir -p 00_scripts
```

Now, let's write a script to run FastQC on one file.
Let's create the file with `touch`. 

```bash
touch 00_scripts/01_fastqc.sh
```

Now, let's write the script. 

```bash
#!/usr/bin/env bash

module purge
module load fastqc
mkdir -p 02_fastqc logs
fastqc 01_data/bio_sample_01_R1.fastq.gz -o 02_fastqc/ > logs/01_fastqc.log 2>&1
```

- Explanation of the command in the script:
  - `#!/usr/bin/env bash` - This is the shebang line that tells the system to use the Bash shell to execute the script. Using `env` finds `bash` on your `PATH`, which is more portable than hardcoding `/bin/bash`.
  - `module purge` - This unloads any currently loaded modules.
  - `module load fastqc` - This loads the FastQC module.
  - `mkdir -p 02_fastqc logs` - This creates the `02_fastqc/` and `logs/` directories if they don't already exist.
  - `fastqc 01_data/bio_sample_01_R1.fastq.gz -o 02_fastqc/` runs FastQC on the input file and writes the results to the `02_fastqc/` directory.
  - `> logs/01_fastqc.log` redirects standard output (stdout, file descriptor 1) to the log file, overwriting it if it exists.
  - `2>&1` redirects standard error (stderr, file descriptor 2) to the same destination as stdout, so both stdout and stderr end up in `logs/01_fastqc.log`.
  - This pattern is useful to capture all program messages for troubleshooting and record-keeping. Ensure `logs/` exists (we created it with `mkdir -p logs`).

**Make the script an executable file**

```bash
chmod +x 00_scripts/01_fastqc.sh
```

**Run the script**

```bash
time ./00_scripts/01_fastqc.sh 
```

#### Multiple files (looping through files)

A simple example:

```bash
# A simple loop example: list files in 01_data/
for file in 01_data/*.fastq.gz 
do
  echo "Found file: $file"
done
```

- The `for ... in ... do ... done` construct repeats the commands between `do` and `done` for each matched file.
- `01_data/*.fastq.gz` expands (globs) to all FASTQ files in the `01_data/` directory.
- `$file` is a shell variable that holds the current filename; `echo` prints text to the terminal.

**Run `FastQC` on all files in `01_data/`**

Create the script file:

```bash
touch 00_scripts/02_fastqc_loop.sh
```

Now, let's write the script:

```bash
#!/usr/bin/env bash

module purge
module load fastqc

mkdir -p 03_fastqc_loop logs

for file in 01_data/*.fastq.gz
do
  echo "Running FastQC on: $file"
  fastqc $file -o 03_fastqc_loop/ > logs/02_fastqc_loop.log 2>&1
done
```

Save this script as `02_fastqc_loop.sh` in `00_scripts` directory.

Make it executable:

```bash
chmod +x 00_scripts/02_fastqc_loop.sh
```

**Run the script**

```bash
time ./00_scripts/02_fastqc_loop.sh
```

<details>
<summary>Output</summary>
<pre>
Running FastQC on: 01_data/bio_sample_01_R1.fastq.gz
Running FastQC on: 01_data/bio_sample_01_R2.fastq.gz
Running FastQC on: 01_data/bio_sample_02_R1.fastq.gz
Running FastQC on: 01_data/bio_sample_02_R2.fastq.gz
Running FastQC on: 01_data/bio_sample_03_R1.fastq.gz
Running FastQC on: 01_data/bio_sample_03_R2.fastq.gz
Running FastQC on: 01_data/bio_sample_04_R1.fastq.gz
Running FastQC on: 01_data/bio_sample_04_R2.fastq.gz
Running FastQC on: 01_data/bio_sample_05_R1.fastq.gz
Running FastQC on: 01_data/bio_sample_05_R2.fastq.gz

real    1m12.560s
user    1m37.585s
sys     0m2.792s
</pre>
</details>

Check the log file:

```bash
cat logs/02_fastqc_loop.log
```

<details>
<summary>Output</summary>
<pre>
Started analysis of bio_sample_05_R2.fastq.gz
Approx 5% complete for bio_sample_05_R2.fastq.gz
Approx 10% complete for bio_sample_05_R2.fastq.gz
Approx 15% complete for bio_sample_05_R2.fastq.gz
Approx 20% complete for bio_sample_05_R2.fastq.gz
Approx 25% complete for bio_sample_05_R2.fastq.gz
Approx 30% complete for bio_sample_05_R2.fastq.gz
Approx 35% complete for bio_sample_05_R2.fastq.gz
Approx 40% complete for bio_sample_05_R2.fastq.gz
Approx 45% complete for bio_sample_05_R2.fastq.gz
Approx 50% complete for bio_sample_05_R2.fastq.gz
Approx 55% complete for bio_sample_05_R2.fastq.gz
Approx 60% complete for bio_sample_05_R2.fastq.gz
Approx 65% complete for bio_sample_05_R2.fastq.gz
Approx 70% complete for bio_sample_05_R2.fastq.gz
Approx 75% complete for bio_sample_05_R2.fastq.gz
Approx 80% complete for bio_sample_05_R2.fastq.gz
Approx 85% complete for bio_sample_05_R2.fastq.gz
Approx 90% complete for bio_sample_05_R2.fastq.gz
Approx 95% complete for bio_sample_05_R2.fastq.gz
Approx 100% complete for bio_sample_05_R2.fastq.gz
Analysis complete for bio_sample_05_R2.fastq.gz
</pre>
</details>

The log file shows the progress of the FastQC analysis for just the last file.

Let us now make sure that we have a log file for each file. 

```bash
#!/usr/bin/env bash

module purge
module load fastqc

INPUT_DIR=01_data
OUTPUT_DIR=04_fastqc_loop_samplename
LOG_DIR=logs

mkdir -p $OUTPUT_DIR $LOG_DIR

for file in $INPUT_DIR/*.fastq.gz 
do  
  sample_id=$(basename "$file" .fastq.gz)
  echo "Running FastQC on: $sample_id"
  fastqc $file -o $OUTPUT_DIR/ > $LOG_DIR/03_fastqc_loop_$sample_id.log 2>&1
done
```

A **shell variable** is a named container that holds a value (like a path or a filename) so you can reuse it. You set it with `NAME=value` (no spaces around `=`) and read it back with `$NAME`. For example, `INPUT_DIR=01_data` lets you write `$INPUT_DIR/*.fastq.gz` instead of repeating `01_data` everywhere.

Using shell variables in the loop helps to make the script more readable, maintainable, and reusable.

Save this script as `03_fastqc_loop_samplename.sh` in `00_scripts` directory.

Make it executable:

```bash
chmod +x 00_scripts/03_fastqc_loop_samplename.sh
```

**Run the script:**

```bash
time ./00_scripts/03_fastqc_loop_samplename.sh
```

<details>
<summary>Output</summary>
<pre>
Running FastQC on: bio_sample_01_R1
Running FastQC on: bio_sample_01_R2
Running FastQC on: bio_sample_02_R1
Running FastQC on: bio_sample_02_R2
Running FastQC on: bio_sample_03_R1
Running FastQC on: bio_sample_03_R2
Running FastQC on: bio_sample_04_R1
Running FastQC on: bio_sample_04_R2
Running FastQC on: bio_sample_05_R1
Running FastQC on: bio_sample_05_R2

real    1m11.971s
user    1m31.266s
sys     0m3.074s
</pre>
</details>

Check the log files:

```bash
less logs/*bio_sample*log
```

Using `less` we can view the contents of the log files. To move from one file to the next, use the `:n` command within `less`. To move to the previous file, use the `:p` command.

To check if all files have been processed, we can use the `grep` command.

```bash
grep "Analysis complete" logs/*bio_sample*log
```

<details>
<summary>Output</summary>
<pre>
logs/03_fastqc_loop_bio_sample_01_R1.log:Analysis complete for bio_sample_01_R1.fastq.gz
logs/03_fastqc_loop_bio_sample_01_R2.log:Analysis complete for bio_sample_01_R2.fastq.gz
logs/03_fastqc_loop_bio_sample_02_R1.log:Analysis complete for bio_sample_02_R1.fastq.gz
logs/03_fastqc_loop_bio_sample_02_R2.log:Analysis complete for bio_sample_02_R2.fastq.gz
logs/03_fastqc_loop_bio_sample_03_R1.log:Analysis complete for bio_sample_03_R1.fastq.gz
logs/03_fastqc_loop_bio_sample_03_R2.log:Analysis complete for bio_sample_03_R2.fastq.gz
logs/03_fastqc_loop_bio_sample_04_R1.log:Analysis complete for bio_sample_04_R1.fastq.gz
logs/03_fastqc_loop_bio_sample_04_R2.log:Analysis complete for bio_sample_04_R2.fastq.gz
logs/03_fastqc_loop_bio_sample_05_R1.log:Analysis complete for bio_sample_05_R1.fastq.gz
logs/03_fastqc_loop_bio_sample_05_R2.log:Analysis complete for bio_sample_05_R2.fastq.gz
</pre>
</details>

---

## Part 2: Building a SLURM script

SLURM (Simple Linux Utility for Resource Management) is the job scheduler that manages who gets to use the cluster’s compute nodes and for how long. You will log in to a head/login node to prepare your work, and then ask SLURM to run your jobs on compute nodes with the resources you request.

If you remember just one thing: you don’t run heavy work directly on the head node. You ask SLURM to run it for you on a compute node.

---

## Why do we use SLURM?

- It shares the cluster fairly among many users.
- It finds and reserves the resources you need (CPUs, memory, time).
- It tracks your job, captures logs, and reports status.

---

## Key words

- **Cluster**: Many connected computers that can work in parallel.
- **Job ID**: Every job you submit gets a numeric ID, used to monitor or cancel it.
- **Partition (queue)**: A grouping of nodes with certain limits (e.g., time, size). You submit jobs to a partition.
- **Account**: The project or allocation that pays for/authorizes compute usage.
- **Resources**: CPUs/cores, memory (RAM), time limit.
- **Job states**: PENDING (PD, waiting), RUNNING (R), COMPLETING (CG), COMPLETED (CD), FAILED (F), CANCELLED (CA).

---

## Two ways to use SLURM

- **Interactive job (srun)**: You request a shell on a compute node for hands-on work or quick testing.
- **Batch job (sbatch)**: You submit a script and SLURM runs it in the background on a compute node. Best for pipelines and long running jobs.

---

## Essential commands

```bash
# What is running right now for me?
squeue -u $USER

# What partitions exist? (short summary)
sinfo

# What partitions exist? (detailed summary)
sinfo -p <partition_name>

# Submit a batch job
sbatch <script_name.slurm>

# Cancel a job by its Job ID
scancel <JOBID>

# Show info about a job
scontrol show job <JOBID>
```

Tip: Use `history | grep sbatch` to find previous submissions.

---

## Running a SLURM job

We will submit the `03_fastqc_loop_samplename.sh` script from Part 1 as a batch job. Create the SLURM script:

```bash
touch 00_scripts/04_fastqc.slurm
```

Add the following contents:

```bash
#!/usr/bin/env bash

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

# Always start in the submission directory for predictable paths
cd "$SLURM_SUBMIT_DIR"

./00_scripts/03_fastqc_loop_samplename.sh
```

**Explanation of the directives above**

- `#SBATCH --job-name=fastqc`
  - Short, human-friendly job name. Appears in `squeue`, logs, and emails.

- `#SBATCH --account=short_term`
  - Allocation/account to charge; required to authorize the job.

- `#SBATCH --partition=interactive`
  - Which queue/partition to use. Partitions differ in limits and availability.

- `#SBATCH --time=00:05:00`
  - Maximum wall-clock time. SLURM will stop the job if it exceeds 5 minutes.

- `#SBATCH --nodes=1`
  - Number of compute nodes requested. Most single-node tools/pipelines use 1.

- `#SBATCH --cpus-per-task=10`
  - CPU cores available to your task. Match this to what your program can use (e.g., a tool’s `--threads 4`). Our loop runs one FastQC at a time, so 1 core is enough.

- `#SBATCH --mem=8G`
  - Total memory on the node reserved for your job. Ensure it covers the peak usage of your program.

- `#SBATCH --output=logs/%x_%j.out`
  - File for standard output (STDOUT). `%x` = job name, `%j` = job ID (e.g., `logs/fastqc_8249780.out`).

- `#SBATCH --error=logs/%x_%j.err`
  - File for standard error (STDERR). Check here for module load messages and errors.

- `#SBATCH --mail-user=user@iastate.edu`
  - Email address to receive job notifications. These two lines start with `##` (disabled); remove one `#` and use your own address to enable them.

- `#SBATCH --mail-type=END,FAIL`
  - When to send emails. Options include `BEGIN`, `END`, `FAIL`, or `ALL`. `END,FAIL` is a good default that avoids "job started" noise.

- **Log directory gotcha**: SLURM opens `--output`/`--error` files *before* your script runs, so the directory must exist at submit time. If `logs/` does not exist when you run `sbatch`, the job fails immediately. Create it first (`mkdir -p logs`) — `mkdir -p` inside the script is too late for these directives.

Note: `cd "$SLURM_SUBMIT_DIR"` makes the job start in the directory where you ran `sbatch`, so relative paths like `01_data/` work.

**How to submit and check:**

```bash
sbatch 00_scripts/04_fastqc.slurm
```

**Check the status of the job:**

```bash
squeue -u $USER
```

<details>
<summary>Output</summary>
<pre>
JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
8249780 interacti   fastqc satheesh  R       0:01      1 nova21-1
</pre>
</details>

**Check logs**

```bash
ls -lh logs/
cat logs/fastqc_*.out
cat logs/fastqc_*.err
```

In this case, the `.out` file contains the `Running FastQC on: ...` lines echoed by the script. The FastQC output itself goes to the per-sample files in `logs/`, and the `.err` file holds any module or error messages.

**Check efficiency**

```bash
seff 16996341
```

`seff` is a useful tool to check the efficiency of a job. It shows the actual time the job spent using the CPU and the percentage of the requested CPU time that was actually used.

<pre>
Job ID: 16996341
Cluster: nova
User/Group: satheesh/domain users
State: COMPLETED (exit code 0)
Nodes: 1
Cores per node: 2
CPU Utilized: 00:01:55
CPU Efficiency: 60.53% of 00:03:10 core-walltime
Job Wall-clock time: 00:01:35
Memory Utilized: 332.67 MB
Memory Efficiency: 16.24% of 2.00 GB (2.00 GB/node)
</pre>

**Explanation of efficiency metrics**

- **CPU Utilized**: The actual time the job spent using the CPU. In this case, the job used the CPU for 1 minute and 55 seconds.
- **CPU Efficiency**: The percentage of the requested CPU time that was actually used. Here, the job used 60.53% of the 3 minutes and 10 seconds of CPU time it requested (2 cores x 1 minute 35 seconds).
- **Job Wall-clock time**: The total time the job ran, from start to finish (it does not include time spent waiting in the queue).
- **Memory Utilized**: The amount of memory the job actually used. In this case, the job used 332.67 MB of memory.
- **Memory Efficiency**: The percentage of the requested memory that was actually used. Here, the job used 16.24% of the 2 GB of memory it requested.

Now, let's check the job history using `sacct`:

```bash
sacct -j 16996341 --format=JobID,JobName%20,State,Elapsed,MaxRSS,AllocCPUS,CPUTime,ExitCode
```

```
JobID                     JobName      State    Elapsed     MaxRSS  AllocCPUS    CPUTime ExitCode 
------------ -------------------- ---------- ---------- ---------- ---------- ---------- -------- 
16996341                   fastqc  COMPLETED   00:01:35                     2   00:03:10      0:0 
16996341.ba+                batch  COMPLETED   00:01:35    340652K          2   00:03:10      0:0 
16996341.ex+               extern  COMPLETED   00:01:35                     2   00:03:10      0:0 
```

**Explanation of the output**

- `sacct` shows the job's accounting record. The `--format` option picks the columns, and `JobName%20` makes that column 20 characters wide.
- The output has **three rows** for one job:
  - `16996341` is the job itself. It shows the overall state, elapsed time and CPUs.
  - `16996341.ba+` (`batch`) is the step where your script actually ran. This is the row to read for memory, because only it has a `MaxRSS` value.
  - `16996341.ex+` (`extern`) tracks the resources reserved for the job as a whole. It has no `MaxRSS` and is usually not needed. The `+` means the name was shortened to fit the column.
- Columns:
  - `State`: `COMPLETED` means the script exited with code 0.
  - `Elapsed`: wall-clock time, 1 minute 35 seconds.
  - `MaxRSS`: peak memory used, `340652K` (about 333 MB). This matches the `Memory Utilized` value from `seff`.
  - `AllocCPUS`: CPUs allocated to the job, here 2.
  - `CPUTime`: `Elapsed` x `AllocCPUS`, so 1:35 x 2 = 3:10. This is the CPU time you reserved, not what you used.
  - `ExitCode`: `0:0` is the script's exit code followed by the signal that stopped it. `0:0` means a clean finish.
- Use `seff` for a quick efficiency summary and `sacct` when you need per-step details, failed states, or exit codes.

---

### The Efficiency Mindset: What happens if your estimates are off?

When writing a SLURM script, you request Time, Memory, and CPUs.
1. **Request too little**: SLURM stops the job (OOM - Out Of Memory, or Time Limit).
2. **Request too much**: 
   - You wait longer in the queue.
   - You consume resources that others could use.

---

### Activity: Debugging a Failed Job

In reality, jobs will fail frequently due to typos or missing paths. Let's look at how to identify why.

1. **Check the `.err` file**: Slurm separates standard output (`.out`) from standard error (`.err`). Error modules (like missing bash commands or python tracebacks) land here.
   
```bash
cat logs/fastqc_8249780.err
```
If you see `command not found`, a module likely wasn't loaded. If you see `No such file or directory`, check the path to `01_data`.

2. **Check the state and exit code**:

```bash
sacct -j <JOBID> --format=JobID,JobName%20,State,Elapsed,ExitCode
```

`FAILED` with a non-zero `ExitCode` (e.g., `1:0`) means a command in your script returned an error; `TIMEOUT` means it hit `--time`; `OUT_OF_MEMORY` means it hit `--mem`.

### Try it: break a job on purpose

Make a copy of `04_fastqc.slurm` called `04_fastqc_broken.slurm`, change the job name to `fastqc_broken`, and replace the last line with a command that uses a wrong data path:

```bash
#SBATCH --job-name=fastqc_broken
# (same directives as before)

module load fastqc
mkdir -p 02_fastqc
fastqc 01_data/DOES_NOT_EXIST.fastq.gz -o 02_fastqc/
```

1. Submit it: `sbatch 00_scripts/04_fastqc_broken.slurm`
2. Check the state: `sacct -j <JOBID> --format=JobID,State,ExitCode`

```
$ sacct -j 16996341 --format=JobID,State,ExitCode
JobID             State ExitCode 
------------ ---------- -------- 
16996341      COMPLETED      0:0 
16996341.ba+  COMPLETED      0:0 
16996341.ex+  COMPLETED      0:0 
```

The job reports `COMPLETED` with `ExitCode 0:0`, even though nothing was analyzed. FastQC prints `Skipping '01_data/DOES_NOT_EXIST.fastq.gz' which didn't exist, or couldn't be read` and exits normally, so SLURM has no way to know something went wrong.

3. Look at the log: `cat logs/fastqc_broken_*.err` (or `.out`) to see the message.

**Lesson**: `COMPLETED` means the script exited with code 0, not that the analysis worked. Always check the logs and the expected output files too.

Now make a job that SLURM *can* detect as failed. Replace the last line with a command that returns an error code:

```bash
ls 01_data/DOES_NOT_EXIST.fastq.gz
```

4. Submit it and check the state: `sacct -j <JOBID> --format=JobID,State,ExitCode` → `FAILED`, `ExitCode 2:0`

```
$ sacct -j 16999903 --format=JobID,State,ExitCode
JobID             State ExitCode 
------------ ---------- -------- 
16999903         FAILED      2:0 
16999903.ba+     FAILED      2:0 
16999903.ex+  COMPLETED      0:0 
```

5. Find the error: `cat logs/fastqc_broken_*.err` → `No such file or directory`
6. Fix the path and resubmit — verify it goes to `COMPLETED`.

This is the loop you will use for every real job failure: `sacct` for *what* happened, `.err` for *why*.

---

## Watching pending jobs

`squeue` shows more than running jobs. A `PD` (pending) job tells you *why* it is waiting in the `NODELIST(REASON)` column:

```bash
squeue -u $USER
```

```
JOBID PARTITION  NAME    USER     ST  TIME  NODES NODELIST(REASON)
8251  batch      align   satheesh PD  0:00  1     (Priority)
```

Common reasons:

| Reason | Meaning |
| :--- | :--- |
| `(Priority)` | Other users' jobs outrank yours — just wait |
| `(Resources)` | Your job is next in line but nodes aren't free yet |
| `(ReqNodeNotAvail)` | You asked for something unavailable (e.g., too much memory for any node) |

---

## Part 3: SLURM Job Arrays

**Goal**: The "Correct" way to handle independent tasks at scale.

### What is a Job Array?
A Job Array is a single job submission that spawns multiple "tasks".
- **One Job ID** (Master ID), but many **Array Indices** (e.g., `8250375_0`, `8250375_1`).

**Why use Arrays?**
- **Independent**: If Task 5 fails, Task 6 still runs.
- **Throttle**: You can limit how many run at once (`%10`).
- **Logs**: Each task gets its own output file (`%A_%a.out`).
- **Retry**: You can re-submit *only* the failed indices.

---

Array jobs let you run the same command over many inputs (e.g., all FASTQ files) by indexing them with `SLURM_ARRAY_TASK_ID`. SLURM schedules each index as its own task.

### Example: FastQC over all files in 01_data/ using an array

Create `00_scripts/05_fastqc_array.slurm`:

```bash
#!/usr/bin/env bash

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

# Always start in the submission directory for predictable paths
cd "$SLURM_SUBMIT_DIR"

# Output directory 
OUTPUT_DIR=05_fastqc_slurm_array
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
```

### How it works

- `--array=0-9` launches 10 tasks with `SLURM_ARRAY_TASK_ID` set to 0..9.
- Inside the script, `FILES=(01_data/*.fastq.gz)` builds the list of inputs; each task picks `FILES[$SLURM_ARRAY_TASK_ID]`.
- `--cpus-per-task=2` and `--mem=2G` are per-task requests. With arrays, concurrency comes from many tasks; keep per-task CPU/memory modest.
- Log patterns `%A` (master job ID) and `%a` (array index) help separate per-task stdout/stderr.

Tips:
- If your files can be very large, increase `--time` and `--mem` per task accordingly.

Submit for all files in `01_data/`. 

```bash
sbatch 00_scripts/05_fastqc_array.slurm
```

**Check the status of the job:**

```bash
squeue -u $USER
```

<details>
<summary>Output</summary>
<pre>
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
         8250375_1 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_2 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_3 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_4 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_5 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_6 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_7 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_8 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_9 interacti fastqc_a satheesh  R       0:01      1 nova21-1
         8250375_0 interacti fastqc_a satheesh  R       0:02      1 nova21-1
</pre>
</details>

**Explanation of the output**

JOBID: 8250375_0, 8250375_2, …, 8250375_9
8250375 is the master job ID; the suffix _ is the array task index (0–9). Each line is one array task.

**Alternative: count files and submit a matching array**

```bash
N=$(ls 01_data/*.fastq.gz | wc -l)
sbatch --array=0-$((N-1)) 00_scripts/05_fastqc_array.slurm
```

**seff the job**

```bash
seff 8250375_0
```

<details>
<summary>Output</summary>
<pre>
Job ID: 8250376
Array Job ID: 8250375_0
Cluster: nova
User/Group: satheesh/domain users
State: COMPLETED (exit code 0)
Nodes: 1
Cores per node: 2
CPU Utilized: 00:00:10
CPU Efficiency: 50.00% of 00:00:20 core-walltime
Job Wall-clock time: 00:00:10
Memory Utilized: 302.76 MB
Memory Efficiency: 14.78% of 2.00 GB (2.00 GB/node)
</pre>
</details>

**sacct the job**

```bash
sacct -j 8250375 --format=JobID,JobName%20,State,Elapsed,MaxRSS,AllocCPUS,CPUTime,ExitCode
```

- `sacct`: SLURM's accounting command. It reports job and step history (finished and, depending on site config, running jobs) with detailed fields like state, elapsed wall time, peak memory (MaxRSS), allocated CPUs, and CPUTime. For arrays, pass the parent ID (e.g., `8250375`) to see all indices, or a specific one like `8250375_0`.
- `--format`: Format the output to show only the fields we care about. `%20` means 20 characters wide.
- `JobID`: The job ID.
- `JobName`: The job name.
- `State`: The state of the job. `COMPLETED` means the job finished successfully.
- `Elapsed`: The elapsed wall time.
- `MaxRSS`: The peak memory usage.
- `AllocCPUS`: The number of allocated CPUs.
- `CPUTime`: The CPU time used.
- `ExitCode`: The exit code of the job.

<details>
<summary>Output</summary>
<pre>
JobID                     JobName      State    Elapsed     MaxRSS  AllocCPUS    CPUTime ExitCode
------------ -------------------- ---------- ---------- ---------- ---------- ---------- --------
8250375_0            fastqc_array  COMPLETED   00:00:10                     2   00:00:20      0:0
8250375_0.b+                batch  COMPLETED   00:00:10    310024K          2   00:00:20      0:0
8250375_0.e+               extern  COMPLETED   00:00:10                     2   00:00:20      0:0
8250375_1            fastqc_array  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_1.b+                batch  COMPLETED   00:00:09    320032K          2   00:00:18      0:0
8250375_1.e+               extern  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_2            fastqc_array  COMPLETED   00:00:17                     2   00:00:34      0:0
8250375_2.b+                batch  COMPLETED   00:00:17    302488K          2   00:00:34      0:0
8250375_2.e+               extern  COMPLETED   00:00:17                     2   00:00:34      0:0
8250375_3            fastqc_array  COMPLETED   00:00:17                     2   00:00:34      0:0
8250375_3.b+                batch  COMPLETED   00:00:17    290540K          2   00:00:34      0:0
8250375_3.e+               extern  COMPLETED   00:00:17                     2   00:00:34      0:0
8250375_4            fastqc_array  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_4.b+                batch  COMPLETED   00:00:09    292888K          2   00:00:18      0:0
8250375_4.e+               extern  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_5            fastqc_array  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_5.b+                batch  COMPLETED   00:00:09    285000K          2   00:00:18      0:0
8250375_5.e+               extern  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_6            fastqc_array  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_6.b+                batch  COMPLETED   00:00:09    335176K          2   00:00:18      0:0
8250375_6.e+               extern  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_7            fastqc_array  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_7.b+                batch  COMPLETED   00:00:09    333360K          2   00:00:18      0:0
8250375_7.e+               extern  COMPLETED   00:00:09                     2   00:00:18      0:0
8250375_8            fastqc_array  COMPLETED   00:00:08                     2   00:00:16      0:0
8250375_8.b+                batch  COMPLETED   00:00:08    308852K          2   00:00:16      0:0
8250375_8.e+               extern  COMPLETED   00:00:08                     2   00:00:16      0:0
8250375_9            fastqc_array  COMPLETED   00:00:13                     2   00:00:26      0:0
8250375_9.b+                batch  COMPLETED   00:00:13    294728K          2   00:00:26      0:0
8250375_9.e+               extern  COMPLETED   00:00:13                     2   00:00:26      0:0
</pre>
</details>

- `8250375_0` → your array task with index 0.
- `8250375_0.bat+` (batch) → the batch step where your commands ran.
- `8250375_0.ext+` (extern) → the extern step, which tracks resource usage tied to the allocation itself (not your script directly).
- `8250375_1` → the array task with index 1, and so on.

So each array task has a main job entry, plus `.batch` and `.extern` sub-entries.

### Throttling an array with `%`

When you have hundreds of tasks, you usually don't want them all running at once — they would compete for disk I/O and use up your fair share quickly. `%N` caps how many tasks run concurrently:

```bash
# Run tasks 0-9, but at most 3 at a time
sbatch --array=0-9%3 00_scripts/05_fastqc_array.slurm
```

```bash
squeue -u $USER
```

```
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
  17001093_[3-9%3] interacti fastqc_a satheesh PD       0:00      1 (JobArrayTaskLimit)
        17001093_0 interacti fastqc_a satheesh  R       0:08      1 nova19-biocrunch-10
        17001093_1 interacti fastqc_a satheesh  R       0:08      1 nova19-biocrunch-10
        17001093_2 interacti fastqc_a satheesh  R       0:08      1 nova19-biocrunch-10
```

Only 3 tasks run; the rest stay `PENDING` until a slot frees. Try it: submit `--array=0-9%3` and watch `squeue` — you'll see 3 running, 7 pending.

### Handling Failures: The "Swiss Cheese" Array

Imagine you ran 100 jobs.
- Tasks 0-45: Success
- Task 46: FAILED
- Tasks 47-88: Success
- Task 89: FAILED

You don't want to re-run everything. Check which IDs failed (look at logs or `sacct`).
Then submit only the failed jobs:

```bash
sbatch --array=46,89 00_scripts/05_fastqc_array.slurm
```
Slurm allows comma-separated lists and ranges!

---

### SLURM Quick Reference Cheat Sheet

| Command | Action |
| :--- | :--- |
| `sinfo` | View cluster and partition status |
| `squeue -u $USER` | View your currently running and pending jobs |
| `squeue -j <JOBID> --start` | Estimate when a pending job will start |
| `scancel <JOBID>` | Cancel a specific job (or array task `JOBID_INDEX`) |
| `sbatch script.sh` | Submit a batch job script |
| `sbatch --array=0-99%10` | Array of 100 tasks, max 10 concurrent |
| `scontrol show job <JOBID>` | Detailed info about a queued or running job |
| `srun ... --pty bash` | Start an interactive terminal session on a compute node |
| `seff <JOBID>` | View CPU and Memory efficiency of a completed job |
| `sacct -j <JOBID>` | View detailed accounting history of a job (or array) |
