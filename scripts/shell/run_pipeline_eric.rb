#!/usr/bin/env ruby

def parse_fname(fname)
  { dir: File.dirname(fname), 
    base: File.basename(fname, File.extname(fname)), 
    ext: File.extname(fname) }
end

fasta = ARGV[0]
fasta_f = parse_fname(fasta)

kmer = ARGV[1]

outdir = '/home/prasanj/silly-jawn/output'

length = 250
coverage = 10

working_dir = '/home/moorer/projects/length_cutoff'

outbase = "#{outdir}/pipeline_ray.#{fasta_f[:base]}.#{length}_length.#{coverage}_coverage.#{kmer}_kmer"

`time ruby #{working_dir}/scripts/pipeline-ray-with-cleanup.rb -f #{fasta} -o #{outdir} -c #{coverage} -b #{working_dir}/scripts -t 4 -k #{kmer} --no-kmer-sweep 1> #{outbase}.out.txt 2> #{outbase}.err.txt`
