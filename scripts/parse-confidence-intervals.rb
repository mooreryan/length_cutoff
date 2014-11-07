#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require 'trollop'
require 'fileutils'

opts = Trollop.options do
  banner <<-EOS

  Parse it like hot.

  Options:
  EOS
  opt(:basename, 'The base name of the jawn', type: :string,
      default: 'EColik12CompleteGenome')
  opt(:force, 'Force overwrite of output dir', type: :boolean,
      default: true)
  opt(:outdir, 'Output directory', type: :string,
      default: '/data/moorer/ecoli_length_cutoff_sweep/length_cutoff_summary')
  opt(:startdir, 'Starting directory', type: :string,
      default: '/data/moorer/ecoli_length_cutoff_sweep')
end

if opts[:force]
  outdir = opts[:outdir]
else
  if File.exist? opts[:outdir]
    Trollop.die :outdir, "The output directory already exists!"
  else
    outdir = FileUtils.mkdir(opts[:outdir])
  end
end

unless File.exist? opts[:startdir]
  Trollop.die :startdir, "The file must exist"
end

recruitment_dirs = Dir.glob(File.join(opts[:startdir], 'recruitment', "BOWTIE_#{opts[:basename]}.even_reads_*"))

epic_cutoff_file = ['basename read.len gen.cov assem.kmer short.name num.contigs.in.set len.cutoff low.ci confidence high.ci']
recruitment_dirs.each do |recruitment_dir|
  this_base = recruitment_dir.match(/#{opts[:basename]}.even_reads_.*kmer_[0-9]+/)[0]
  this_cutoff_file = File.join(recruitment_dir, 'coverage', this_base + '.sorted.bam.simple_info.length_cutoff.txt')

  coverage = this_base.match(/_[0-9]+x_/)[0].sub(/^_/, '').sub(/x_$/, '')
  length = this_base.match(/_[0-9]+bp./)[0].sub(/^_/, '').sub(/bp.$/, '')
  kmer = this_base.match(/.kmer_[0-9]+/)[0].sub(/^.kmer_/, '')

  f = File.open(this_cutoff_file, 'r').read
  if f.match(/ERROR/)
    $stderr.puts this_cutoff_file
  else
    f.split("\n").each do |line|
      number, cutoff, low, mean, high = line.chomp.split(' ')

      epic_cutoff_file << [opts[:basename], length, coverage, kmer, [opts[:basename], length, coverage, kmer].join('.'), line.chomp].join(' ')
    end
  end
end

outf = File.join(opts[:outdir], "#{opts[:basename]}.length_cutoff_summary.txt")
File.open(outf, 'w') do |f|
  f.puts epic_cutoff_file
end
