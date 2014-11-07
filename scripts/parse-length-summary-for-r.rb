#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

last_shortname = ''
last_cutoff = ''
File.open('EColik12CompleteGenome.length_cutoff_summary.no-errors.no-zeros.txt', 'r').each_line do |line|
  if line.start_with?('basename')
    puts line
  else
    name, len, cov, kmer, shortname, num, cutoff, low, conf, high = line.chomp.split(' ')

    # sometimes the 0 length cutoff calculation line is doubled
    unless last_shortname == shortname && last_cutoff == 0 && cutoff == 0
      # add the confidence cutoff as a column

      # there is a weird thing where the confidence might not roudn to the proper cutoff, eg, in the file int might have 0.97, but the actual cutoff would be 0.95
      (confidence.to_f * 100).round
