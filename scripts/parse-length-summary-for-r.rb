#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

# 'EColik12CompleteGenome.length_cutoff_summary.no-errors.no-zeros.txt'
fname = ARGV[0]

last_shortname = ''
last_cutoff = ''
conf_levels = []
File.open(fname, 'r').each_line do |line|
  if line.start_with?('basename')
    puts line.chomp.split(' ').insert(5, ['new.short.name', 'confidence.level']).flatten.join(' ')
  else
    name, len, cov, kmer, shortname, num, cutoff, low, conf, high = line.chomp.split(' ')

    # add the confidence cutoff as a column

    # because of the way these cufoffs are set up gotta do this weird thing here....
    if last_shortname != shortname # ie starting a new set
      # make a list of the confidence levels for this particular set
      # gotta do this each time cos the lower bound could change
      conf_levels = ((conf[2] + '0').to_i .. 95).step(5).to_a
    end

    this_conf_level = conf_levels.shift
    new_short_name = [name, len, cov, kmer, this_conf_level].join('.')
    puts line.chomp.split(' ').insert(5, [new_short_name, this_conf_level]).flatten.join(' ')
    
    last_shortname = shortname
  end
end
