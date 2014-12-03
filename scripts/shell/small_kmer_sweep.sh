#!/bin/bash

fasta=$1
outdir=/home/moorer/silly-jawn/output

length=250
coverage=25

working_dir=/home/moorer/projects/length_cutoff

for kmer in {41,81,141,201};
do time ruby $working_dir/scripts/pipeline-ray.rb -f \
    $fasta \
    -o $outdir \
    -b $working_dir/scripts/ \
    -t 20 -k $kmer --no-kmer-sweep \
    1> $outdir/pipeline-ray.$length.$coverage.$kmer.out.txt \
    2> $outdir/pipeline-ray.$length.$coverage.$kmer.err.txt;
done;

