#!/usr/bin/env ruby

require 'parse_fasta'

Signal.trap("PIPE", "EXIT")

outdir = ARGV[1]

FastaFile.open(ARGV.first, 'r').each_record do |header, sequence|
  f = File.open(File.join(outdir, "#{header.downcase.gsub(/[ |,.\/:]+/, '_')}.applepie.fa"), 'w')
  f.puts ">#{header}\n#{sequence}"
  f.close
end
