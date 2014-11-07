#!/usr/bin/env ruby

require 'parse_fasta'
require 'trollop'

Signal.trap("PIPE", "EXIT")

opts = Trollop::options do
  banner <<-EOS

  Options:
  EOS
  opt :fasta, 'Fasta file name', type: :string
  opt(:coverage, 'The mean coverage you want.', type: :int,
      default: 50)
  opt(:read_len, 'The length of reads.', type: :int,
      default: 250)
end

if opts[:fasta].nil?
  Trollop.die :fasta, "You must enter a file name"
elsif !File.exist? opts[:fasta]
  Trollop.die :fasta, "The file must exist"
end

the_step = (opts[:read_len] / opts[:coverage].to_f).round
start_posns = (1..opts[:read_len]).step(the_step)
start_posns =
  start_posns.take(opts[:coverage])

def get_end_posn(read_len, start_posn)
  start_posn + read_len -1
end

frag_num = 1
FastaFile.open(opts[:fasta], 'r').each_record do |header, sequence|
  genome_len = sequence.length

  start_posns.each do |posn|
    number_to_take = ((genome_len - posn + 1) / opts[:read_len].to_f).floor

    these_start_posns = (posn..genome_len).step(opts[:read_len]).take(number_to_take).to_a

    these_start_posns.each do |start_posn|
      end_posn = get_end_posn(opts[:read_len], start_posn)
      this_fragment = sequence[start_posn..end_posn]
      puts ">#{header} frag=#{frag_num} start=#{start_posn} end=#{end_posn}"
      puts this_fragment
      frag_num += 1
    end
  end
end

