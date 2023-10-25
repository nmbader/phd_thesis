#!/bin/bash
#
#SBATCH --job-name=fwiun_12b
#
#SBATCH --time=48:00:00
#SBATCH --ntasks=11
#SBATCH --nodes=11
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=64G
#SBATCH --partition=serc,normal
#SBATCH -o slurm/slurm-%j.out

echo "number of tasks " ${SLURM_NTASKS}
echo "number of cpus per node " ${SLURM_CPUS_ON_NODE}
OMP_NUM_THREADS=${SLURM_CPUS_ON_NODE} srun --mpi=pmi2 make ./dat/ch6un_fwi3d_12b.H
