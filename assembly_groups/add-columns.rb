#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

File.open('clusters.txt', 'r').each_line do |line|
  if line.start_with?('Coverage')
    puts [%w[ReadLen GenCov Kmer], line.chomp.split].flatten.join(' ')
  else
    _, _, _, name, *rest = line.chomp.split

    puts [name.split('-'), line.chomp.split].flatten.join(' ')
  end
end
