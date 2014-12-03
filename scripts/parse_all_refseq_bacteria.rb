#!/usr/bin/env ruby

# just take all sequences that have the name chromosome and number
# them. organisms with more than one chromosome are treated as
# separate organisms

require 'parse_fasta'

Signal.trap("PIPE", "EXIT")

num = 1

FastaFile.open(ARGV.first, 'r').each_record do |header, sequence|
  if header.match(/complete genome/)
    puts ">#{num}| #{header}"
    puts sequence
    num += 1
  end
end
