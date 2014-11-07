#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

begin
  require 'trollop'
  require 'shell/executer.rb'
  require 'parse_fasta'
  require 'fileutils'
rescue LoadError => e
  bad_file = e.message.sub(/^cannot load such file -- /, '')
  abort("ERROR: #{e.message}\nTry running: gem install #{bad_file}")
end

opts = Trollop.options do
  banner <<-EOS

  The starting fasta file should have only one sequence in there.

  Options:
  EOS
  opt(:fasta, 'Fasta file with genome to start with', type: :string)
  opt(:coverage, 'The mean coverage you want.', type: :int,
      default: 50)
  opt(:read_len, 'The length of reads.', type: :int,
      default: 250)

  opt(:quality, 'Quality score you want (in letter form)',
      type: :string, default: 'I')

  opt(:threads, 'Threads to use for soap', type: :int,
      default: 1)
  opt(:kmer, 'Kmer size for soap', type: :int, default: 111)
  opt(:kmer_sweep, 'If you want to do a kmer parameter sweep, will nullify the option for --kmer',
      type: :boolean, default: true)
  

  opt(:outdir, 'Output directory', type: :string,
      default: '/Users/moorer/projects/cone_janws/test_output')
  opt(:bin, 'The directory contianing all the scripts',
      default: '/Users/moorer/projects/cone_janws/scripts')
end

if opts[:fasta].nil?
  Trollop.die :fasta, "You must enter a file name"
elsif !File.exist? opts[:fasta]
  Trollop.die :fasta, "The file must exist"
end

if !File.exist? opts[:outdir]
  Trollop.die :outdir, "The file must exist"
end

if !File.exist? opts[:bin]
  Trollop.die :bin, "The file must exist"
end

######################################################################
##### functions ######################################################
######################################################################

def run_it!(cmd)
  begin
    $stderr.puts "\nRunning: #{cmd}"
    cmd_outerr = Shell.execute!(cmd)
  rescue RuntimeError => e
    # print stderr if bad exit status
    abort(e.message)
  end
end

def parse_fname(fname)
  { dir: File.dirname(fname), 
    base: File.basename(fname, File.extname(fname)), 
    ext: File.extname(fname) }
end

######################################################################
##### make even reads ################################################
######################################################################

# file names
fasta_f = parse_fname(opts[:fasta])
out_fname = "#{fasta_f[:base]}.even_reads_#{opts[:coverage]}x_" +
  "#{opts[:read_len]}bp.fa"
even_reads_fname = File.join(opts[:outdir], out_fname)
make_even_reads = File.join(opts[:bin], 'make-even-reads.rb')

# CLI options
script = make_even_reads
in_fasta = opts[:fasta]
in_coverage = opts[:coverage]
in_read_len = opts[:read_len]
outf = even_reads_fname

# command
make_even_reads_cmd =
  "ruby #{script} " +
  "--fasta #{in_fasta} " +
  "--coverage #{in_coverage} " +
  "--read-len #{in_read_len} " +
  "> #{outf}"

# run it!
begin
  $stderr.puts "\nRunning: #{make_even_reads_cmd}"
  make_even_reads_outerr = Shell.execute!(make_even_reads_cmd)
rescue RuntimeError => e
  # print stderr if bad exit status
  abort(e.message)
end

######################################################################
##### fasta to fastq #################################################
######################################################################

# file names
fasta_to_fastq = File.join(opts[:bin], 'fasta_to_fastq.rb')
fname_parsed = parse_fname(even_reads_fname)
working_dir = fname_parsed[:dir]
even_reads_fastq_fname = File.join(working_dir,
                                   "#{fname_parsed[:base]}.fq")

# CLI options
script = fasta_to_fastq
in_fasta = even_reads_fname
in_quality = opts[:quality]
outf = even_reads_fastq_fname

# command
cmd =
  "ruby #{script} " +
  "--fasta #{in_fasta} " +
  "--quality #{in_quality} " +
  "> #{outf}"

# run it!
run_it!(cmd)

######################################################################
##### assemble #######################################################
######################################################################

# file names
assembly_dir = File.join(working_dir, 'assemblies')
unless File.exists?(assembly_dir)
  assembly_dir = FileUtils.mkdir(assembly_dir)
end

soap_config_fname =
  File.join(working_dir, "soap-config-for-#{fname_parsed[:base]}.fq")


# create the config file
config =
  "max_rd_len=#{opts[:read_len]+50}

[LIB]
asm_flags=3
rd_len_cutoff=#{opts[:read_len]+50}
rank=1
map_len=64
q=#{even_reads_fastq_fname}
"

f = File.open(soap_config_fname, 'w')
f.puts config
f.close

script = "/usr/local/bin/SOAPdenovo-127mer"

if opts[:kmer_sweep]
  (21..121).step(6).each do |kmer|
    # CLI options
    in_config = soap_config_fname
    in_outbase = File.join(assembly_dir, "#{fname_parsed[:base]}.kmer_#{kmer}")
    in_threads = opts[:threads]
    in_kmer = kmer

    # pregraph
    cmd =
      "#{script} pregraph " +
      "-s #{in_config} " +
      "-o #{in_outbase} " +
      "-K #{in_kmer} " +
      "-p #{in_threads} " +
      "-R" # extra info for resolving repeats in contig step
    #  "-d 1"  # KmerFreqCutoff = 1

    # run it!
    run_it!(cmd)

    # contig
    cmd =
      "#{script} contig " +
      "-g #{in_outbase} " +
      "-R"  

    # run it!
    run_it!(cmd)
  end
else
  # CLI options
  in_config = soap_config_fname
  in_outbase = File.join(assembly_dir, "#{fname_parsed[:base]}.kmer_#{opts[:kmer]}")
  in_threads = opts[:threads]
  in_kmer = opts[:kmer]

  # pregraph
  cmd =
    "#{script} pregraph " +
    "-s #{in_config} " +
    "-o #{in_outbase} " +
    "-K #{in_kmer} " +
    "-p #{in_threads} " +
    "-R" # extra info for resolving repeats in contig step
  #  "-d 1"  # KmerFreqCutoff = 1

  # run it!
  run_it!(cmd)

  # contig
  cmd =
    "#{script} contig " +
    "-g #{in_outbase} " +
    "-R"  

  # run it!
  run_it!(cmd)
end

