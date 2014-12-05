date = '2014_12_05_eric'
fastas = '/home/moorer/silly-jawn/fastas/all_fastas.txt'
kmers = [41,81,141,201]

fnames = []
File.open(fastas, 'r').each_line do |line|
  dir = '/home/moorer/silly-jawn/fastas'
  fnames << "#{dir}/#{line.chomp}"
end

outdir = '/home/moorer/silly-jawn/torque/eric'

fnames.each.with_index do |fname, idx|
  kmers.each do |kmer|
    File.open("#{idx}_#{kmer}_ray_submitter.qs", 'w') do |f|
      s = "#!/bin/bash

#PBS -N ray_len_cut_#{date}_#{idx}_#{kmer}_eric
#PBS -l walltime=8:00:00,nodes=1:ppn=5,cput=40:00:00
#PBS -d /home/moorer/silly-jawn/torque/eric
#PBS -e /home/moorer/silly-jawn/torque/eric/torque_output
#PBS -o /home/moorer/silly-jawn/torque/eric/torque_output

## code to run here

hostname
date

module load mpi/mpich-x86_64

time ruby /home/moorer/projects/length_cutoff/scripts/shell/run_pipeline_eric.rb #{fname} #{kmer}

date
echo 'done!'
"
    f.puts s
    end
  end
end
