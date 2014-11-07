#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require 'trollop'

opts = Trollop::options do
  banner <<-EOS

  Make the file for the cone jawns.

  Options:
  EOS
  opt :top_hits, "File name", type: :string
  opt :recruitment_info, "File name", type: :string
end

if opts[:top_hits].nil?
  Trollop.die :top_hits, "You must enter a file name"
elsif !File.exist? opts[:top_hits]
  Trollop.die :top_hits, "The file must exist"
end

if opts[:recruitment_info].nil?
  Trollop.die :recruitment_info, "You must enter a file name"
elsif !File.exist? opts[:recruitment_info]
  Trollop.die :recruitment_info, "The file must exist"
end

top_hits = {} # should be unique by construction
File.open(opts[:top_hits], 'r').each_line do |line|
  unless line.start_with?("query")
    query, tax_hit, *rest = line.chomp.split("\t")

    if top_hits.has_key?(query)
      abort("#{query} repeated in #{opts[:top_hits]}")
    else
      top_hits[query] = tax_hit
    end
  end
end

puts %w[org ref len reads cov proper.reads proper.cov].join("\t")
File.open(opts[:recruitment_info], 'r').each_line do |line|
  unless line.start_with?("#")
    ref, len, reads, cov, *rest = line.chomp.split("\t")
    
    # deals with the weird thing about the abun pipeline script
    ref = ref.split('_').first

    if top_hits.has_key?(ref)
      puts [top_hits[ref], ref, len, reads, cov, *rest].join("\t")
    else
      warn("#{ref} isn't present in the top_hits map...skipping it!")
    end
  end
end
