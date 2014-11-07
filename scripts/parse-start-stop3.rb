#!/usr/bin/env ruby

require 'parse_fasta'

Signal.trap("PIPE", "EXIT")

counts = {}
FastaFile.open(ARGV.first, 'r').each_record do |header, sequence|
  start = header.match(/start=[0-9]+/)[0].sub(/start=/, '')
  stop = header.match(/end=[0-9]+/)[0].sub(/end=/, '')

  (start..stop).each do |posn|
    posn_sym = posn.to_sym
    if counts.has_key?(posn_sym)
      counts[posn_sym] += 1
    else
      counts[posn_sym] = 1
    end
  end
end

puts 'base,cov'

counts.each_pair do |posn, count|
  puts [posn, count].join(',')
end



