module purge
module load parallel
module load fastqc 

mkdir -p 05_fastqc_parallel

parallel -j10 \
  'fastqc {1} -o 05_fastqc_parallel/ > logs/04_fastqc_parallel_{1/.}.log 2>&1' \
  ::: 01_data/*.fastq.gz