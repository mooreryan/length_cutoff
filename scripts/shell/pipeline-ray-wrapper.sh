#!/bin/bash

fasta=$1
outdir=$2

working_dir=/home/moorer/downloads/cone-jawns/new_stuff/

for length in {150,250};
do for coverage in {2,4,7,10,25,50,100};
    do for kmer in {21..201..20};
	do time ruby $working_dir/scripts/pipeline-ray.rb -f \
	    $fasta \
	    -o $outdir \
	    -b $working_dir/scripts/ \
	    -c $coverage -r $length -t 20 -k $kmer --no-kmer-sweep \
	    1> $outdir/pipeline-ray.$length.$coverage.$kmer.out.txt \
	    2> $outdir/pipeline-ray.$length.$coverage.$kmer.err.txt;
	done;
    done;
done

