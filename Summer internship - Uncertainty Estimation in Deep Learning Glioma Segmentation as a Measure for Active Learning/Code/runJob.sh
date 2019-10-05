#!/bin/bash
#SBATCH --ntasks=6
#SBATCH --mem=14G
#SBATCH --gres=gpu:1
#SBATCH -t 36:00:00
#SBATCH -o out_runJob/out_%j.log
#SBATCH -e out_runJob/error_%j.log

# This is the temporary dir for your job on the SSD
# It will be deleted once your job finishes so don't forget to copy your files!
MY_TMP_DIR=/slurmtmp/${SLURM_JOB_USER}.${SLURM_JOB_ID}

# Move your data to the folder
mv </media/data/athabit/glassimaging> ${MY_TMP_DIR}

# Load the modules
module purge
module load python/3.6.6

echo "Job started"

python -m glassimaging.execution.jobs.joball v6 ./config/all_unet.json ./experiments/

echo "Job completed"
