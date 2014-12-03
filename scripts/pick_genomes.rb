#!/usr/bin/env ruby

# randomly sample the fasta file that has all the genomes

require 'parse_fasta'
require 'set'

Signal.trap("PIPE", "EXIT")

num_samples = ARGV.first.to_i
total_genomes = 2647
pick_these = Set.new((1..total_genomes).to_a.sample(num_samples))

in_f = '/data/moorer/repository/refseq/all_bacteria_complete_genomes.fna'

status = 1
FastaFile.open(in_f, 'r').each_record do |header, sequence|
  num = header.split("|").first.to_i

  if pick_these.include?(num)
    puts [header, sequence].join("\n")
    $stderr.print "#{status} "
    status += 1
  end
end
