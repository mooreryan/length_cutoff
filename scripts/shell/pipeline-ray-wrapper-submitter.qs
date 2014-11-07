#!/bin/bash

#PBS -N cov-pipeline-ecoli_2014-10-31
#PBS -l walltime=96:00:00,nodes=biohen36:ppn=20,cput=1920:00:00
#PBS -d /home/moorer/runt
#PBS -e /home/moorer/runt/oe
#PBS -o /home/moorer/runt/oe

## code to run here

hostname
date

time bash /home/moorer/downloads/cone-jawns/new_stuff/scripts/pipeline-ray-wrapper.sh /home/moorer/downloads/cone-jawns/new_stuff/genomes/bacteria/EColik12CompleteGenome.fa /data/moorer/ecoli_length_cutoff_sweep

date
echo "done!" 
