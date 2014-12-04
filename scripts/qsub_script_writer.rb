date = '2014_12_04'
fastas = '/home/moorer/silly-jawn/fastas/all_fastas.txt'
kmers = [41,81,141,201]

fnames = []
File.open(fastas, 'r').each_line do |line|
  dir = '/home/moorer/silly-jawn/fastas'
  fnames << "#{dir}/#{line.chomp}"
end

outdir = '/home/moorer/silly-jawn/torque'

fnames.each.with_index do |fname, idx|
  kmers.each do |kmer|
    File.open("#{idx}_#{kmer}_ray_submitter.qs", 'w') do |f|
      s = "#!/bin/bash

#PBS -N ray_len_cut_#{date}_#{idx}_#{kmer}
#PBS -l walltime=8:00:00,nodes=1:ppn=10,cput=80:00:00
#PBS -d /home/moorer/silly-jawn/torque
#PBS -e /home/moorer/silly-jawn/torque
#PBS -o /home/moorer/silly-jawn/torque

## code to run here

hostname
date

module load mpi/mpich-x86_64

time ruby /home/moorer/projects/length_cutoff/scripts/shell/run_pipeline.rb #{fname} #{kmer}

date
echo 'done!'
"
    f.puts s
    end
  end
end
