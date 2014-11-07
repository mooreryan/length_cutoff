#!/usr/bin/env ruby

require 'parse_fasta'
require 'set'

# assumes they are sorted by genome

Signal.trap("PIPE", "EXIT")

infile= '/home/moorer/downloads/cone-jawns/reads/all_10_even_50x_250bp.fq'

gi_nums = Set.new
f = nil
FastqFile.open(infile, 'r').each_record do |header, sequence, comment, qual|
  gi = header.match(/gi|[0-9]+|/).to_s
  if gi_nums.include?(gi)
    f.puts [header, sequence, comment, qual].join("\n")
  elsif f && !gi_nums.include?(gi)
    f.close
    print "\nthe header is #{header}\ntype a name for the file for the reads: "
    STDOUT.flush
    fname = gets.chomp
    f = File.open(fname, 'w')
    f.puts [header, sequence, comment, qual].join("\n")
    gi_nums << gi
  else
    print "\nthe header is #{header}\ntype a name for the file for the reads: "
    STDOUT.flush
    fname = gets.chomp
    f = File.open(fname, 'w')
    f.puts [header, sequence, comment, qual].join("\n")
    gi_nums << gi
  end
end

f.close
