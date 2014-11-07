#!/usr/bin/env ruby

require 'parse_fasta'
require 'trollop'

Signal.trap("PIPE", "EXIT")

opts = Trollop::options do
  banner <<-EOS

  Options:
  EOS
  opt :fasta, 'Fasta file name', type: :string
  opt(:quality, 'Qual score you want.', type: :string,
      default: 'I')
end

if opts[:fasta].nil?
  Trollop.die :fasta, "You must enter a file name"
elsif !File.exist? opts[:fasta]
  Trollop.die :fasta, "The file must exist"
end

FastaFile.open(opts[:fasta], 'r').each_record do |header, sequence|
  puts "@#{header}"
  puts sequence
  puts "+"
  puts opts[:quality] * sequence.length
end
