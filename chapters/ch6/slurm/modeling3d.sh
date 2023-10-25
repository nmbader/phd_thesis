#!/bin/bash
#
#SBATCH --job-name=modeling3d
#
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=12
#SBATCH --partition=serc,normal
#SBATCH -o slurm/slurm-%j.out

echo "number of tasks " ${SLURM_NTASKS}
echo "number of cpus per node " ${SLURM_CPUS_ON_NODE}
cd ../
OMP_NUM_THREADS=${SLURM_CPUS_ON_NODE} srun --mpi=pmi2 make ./dat/ch6_elasticModelVTI0.H