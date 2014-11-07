#!/bin/bash

#PBS -N fix-me_2014-11-3
#PBS -l walltime=8:00:00,nodes=biohen36:ppn=14,cput=160:00:00
#PBS -d /home/moorer/runt
#PBS -e /home/moorer/runt/oe
#PBS -o /home/moorer/runt/oe

## code to run here

hostname
date

time bash /home/moorer/downloads/cone-jawns/new_stuff/scripts/pipeline-ray-wrapper-short-fix.sh /home/moorer/downloads/cone-jawns/new_stuff/genomes/bacteria/EColik12CompleteGenome.fa /data/moorer/ecoli_length_cutoff_sweep

date
echo "done!" 
