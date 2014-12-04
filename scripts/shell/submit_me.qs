#!/bin/bash

#PBS -N ray_len_cut_2014-12-04
#PBS -l walltime=4:00:00,nodes=1:ppn=20,cput=80:00:00
#PBS -d /home/moorer/silly-jawn/torque
#PBS -e /home/moorer/silly-jawn/torque
#PBS -o /home/moorer/silly-jawn/torque

## code to run here

hostname
date

module load mpi/mpich-x86_64

time ruby /home/moorer/projects/length_cutoff/scripts/shell/run_pipeline.rb TODO_fasta TODO_kmer

date
echo "done!" 
