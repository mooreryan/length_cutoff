#!/usr/bin/env ruby

# DONT USE KMER SWEEPING, its broken

# updated 2014-10-29: add confidence interval step
# updated 2014-10-30: add kmer info to recruitment output fnames, add time stamps
# updated 2014-10-30: update call to confidence-intervals.r
# updated 2014-12-03: change defaults and kmer sweep values

# this version deletes some intermediate files to save space

# it doesn't ever keep the read files
# it deletes the sam, but keeps sorted bam and bam index, and orig bam

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



[moorer@biohen36 new_stuff]$ time ruby scripts/pipeline-ray.rb -f genomes/bacteria/EColik12CompleteGenome.fa -c 10 -r 250 -t 22 -k 101 --no-kmer-sweep -o test_output/ -b scripts/

Running: ruby scripts/make-even-reads.rb --fasta genomes/bacteria/EColik12CompleteGenome.fa --coverage 10 --read-len 250 > test_output/EColik12CompleteGenome.even_reads_10x_250bp.fa

Running: ruby scripts/fasta_to_fastq.rb --fasta test_output/EColik12CompleteGenome.even_reads_10x_250bp.fa --quality I > test_output/EColik12CompleteGenome.even_reads_10x_250bp.fq

Running: mpiexec -n 22 /home/moorer/ray-build/Ray  -s test_output/EColik12CompleteGenome.even_reads_10x_250bp.fq -o test_output/assemblies/EColik12CompleteGenome.even_reads_10x_250bp.kmer_101 -k 101 1> out 2> err

if you run it with -o test_output, outputs are

test_output/EColik12CompleteGenome.even_reads_10x_250bp.fa
test_output/EColik12CompleteGenome.even_reads_10x_250bp.fq
test_output/assemblies/EColik12CompleteGenome.even_reads_10x_250bp.kmer_101/[all of Ray's outputs]
test_output/assemblies/EColik12CompleteGenome.even_reads_10x_250bp.kmer_101/Contigs.fasta

And some more stuff too!

Notes:

1) Ray and SOAP both have trouble assembling some viruses.
2) Some viruses won't work well becuase Ray returns one genome sized contig!
3) So far this is really only working on K12
4) The kmer sweep option is not fully implemented -- anything after the assembly step will fail



  Options:
  EOS
  opt(:fasta, 'Fasta file with genome to start with', type: :string)
  opt(:coverage, 'The mean coverage you want.', type: :int,
      default: 25)
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

def elapsed_time(old_time)
  (Time.now - old_time).quo(60).round(2)
end

######################################################################
##### make even reads ################################################
######################################################################

t = Time.now

reads_dir = File.join(opts[:outdir], 'reads')
unless File.exists?(reads_dir)
  reads_dir = FileUtils.mkdir(reads_dir)
end

# file names
fasta_f = parse_fname(opts[:fasta])
rand_num = 10.times.map {rand(9)}.join
out_fname = "#{fasta_f[:base]}.even_reads_#{opts[:coverage]}x_" +
  "#{opts[:read_len]}bp.#{rand_num}.fa"
even_reads_fname = File.join(reads_dir, out_fname)
even_reads_fname_parsed = parse_fname(even_reads_fname)
even_reads_fastq_fname = File.join(reads_dir,
                                   "#{even_reads_fname_parsed[:base]}.fq")

make_even_reads = File.join(opts[:bin], 'make-even-reads.rb')
working_dir = opts[:outdir]


if true #!File.exists?(even_reads_fname)
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

  $stderr.puts "\nMade reads in #{elapsed_time(t)} minutes."

  ####################################################################
  ##### fasta to fastq ###############################################
  ####################################################################

  t = Time.now

  # file names
  fasta_to_fastq = File.join(opts[:bin], 'fasta_to_fastq.rb')

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

  run_it!(cmd)

  $stderr.puts "\nConverted fasta to fastq in #{elapsed_time(t)} minutes."

  else
  $stderr.puts "\nReads already exist with these settings for this genome, using them."
end

######################################################################
##### assemble #######################################################
######################################################################

t = Time.now

# file names
assembly_dir = File.join(working_dir, 'assemblies')
unless File.exists?(assembly_dir)
  assembly_dir = FileUtils.mkdir(assembly_dir)
end

script = "/home/moorer/ray-build/Ray"
in_sequences = even_reads_fastq_fname
in_threads = opts[:threads]


if opts[:kmer_sweep]
  # (21..201).step(10).each do |kmer|
  [41, 81, 141, 201].each do |kmer|
    # CLI options
    in_output =
      File.join(assembly_dir,
                "#{even_reads_fname_parsed[:base]}.kmer_#{kmer}")
    in_kmer = kmer

    # pregraph
    cmd =
      "mpiexec -n #{in_threads} #{script}  " +
      "-s #{in_sequences} " +
      "-o #{in_output} " + # if this already exists, will die
      "-k #{in_kmer}"

    run_it!(cmd)
  end
else
  # CLI options
  in_output = ray_assem_outdir =
    File.join(assembly_dir, # this is a directory
              "#{even_reads_fname_parsed[:base]}.kmer_#{opts[:kmer]}")
  in_kmer = opts[:kmer]

  cmd =
    "mpiexec -n #{in_threads} #{script}  " +
    "-s #{in_sequences} " +
    "-o #{in_output} " +
    "-k #{in_kmer}"

  run_it!(cmd)
end

$stderr.puts "\nAssembled reads in #{elapsed_time(t)} minutes."

######################################################################
##### recruit ########################################################
######################################################################

t = Time.now

## using bowtie2 ##

# for single kmer option

# file names
# will be directly down the working dir, level with assemblies dir
base = "BOWTIE_#{even_reads_fname_parsed[:base]}.kmer_#{opts[:kmer]}"
recruitment_dir = File.join(working_dir, 'recruitment', base)
unless File.exists?(recruitment_dir)
  recruitment_dir = FileUtils.mkdir_p(recruitment_dir)
end

# build index of contigs
index = '/home/wommacklab/software/bowtie2-2.1.0/bowtie2-build'
in_reference = ray_assem_contigs =
  File.join(ray_assem_outdir, 'Contigs.fasta')
in_basename = File.join(recruitment_dir,
                        base)
index_cmd = "#{index} -f #{in_reference} #{in_basename}"

# recruit them
local_or_global = '--local' # TODO set this as cmd line option
if local_or_global == '--local'
  stringency = '--very-fast-local'
elsif local_or_global == '--end-to-end'
  stringency = '--very-fast'
end

align = '/home/wommacklab/software/bowtie2-2.1.0/bowtie2-align'
in_reads = even_reads_fname
in_outsam = aligned_reads_sam =
  File.join(recruitment_dir,
            "#{even_reads_fname_parsed[:base]}.kmer_#{opts[:kmer]}.sam")

bowtie_cmd =
  "#{align} " +
  "#{local_or_global} " +
  "#{stringency} " +
  "--omit-sec-seq " +
  "-p #{opts[:threads]} " +
  "-x #{in_basename} " +
  "-f -U #{in_reads} " +
  "-S #{in_outsam}"

run_it!(index_cmd)
run_it!(bowtie_cmd)

# clean up
index_dir = File.join(recruitment_dir, 'indexes')
unless File.exists?(index_dir)
  index_dir = FileUtils.mkdir(index_dir)
end

# move index files into their own folder
FileUtils.mv(Dir.glob(File.join(recruitment_dir, "BOWTIE_*")),
             index_dir)

$stderr.puts "\nRecruited reads in #{elapsed_time(t)} minutes."

######################################################################
##### sam to bam #####################################################
######################################################################

t = Time.now

in_sam = aligned_reads_sam

converter = File.join(opts[:bin], 'samtools.sh')

cmd = "bash #{converter} #{in_sam}"

run_it!(cmd)

aligned_reads_sam_fname_parsed = parse_fname(aligned_reads_sam)
out_bam =
  File.join(aligned_reads_sam_fname_parsed[:dir],
            "#{aligned_reads_sam_fname_parsed[:base]}.sorted.bam")
out_bai = out_bam + '.bai'

$stderr.puts "\nMade bam and index in #{elapsed_time(t)} minutes."

######################################################################
##### simple info ####################################################
######################################################################

t = Time.now

simple_info = File.join(opts[:bin], 'recruitment_info_simple-0.0.1.jar')

simple_info_dir = File.join(recruitment_dir, 'coverage')
unless File.exists?(simple_info_dir)
  simple_info_dir = FileUtils.mkdir(simple_info_dir)
end

simple_recruitment_info_fname =
  File.join(simple_info_dir,
            parse_fname(out_bam)[:base] + '.bam.simple_info.txt')

cmd =
  "java -jar #{simple_info} " +
  "-b #{out_bam} " +
  "-i #{out_bai} " +
  "> #{simple_recruitment_info_fname}"

# errors for this command don't trigger error message
run_it!(cmd)

$stderr.puts "\nCalculated coverage in #{elapsed_time(t)} minutes."

######################################################################
##### stats ##########################################################
######################################################################

t = Time.now

confidence_intervals = File.join(opts[:bin], 'confidence-intervals.r')

simple_recruitment_info_fname_parsed =
  parse_fname(simple_recruitment_info_fname)
infile = simple_recruitment_info_fname
outbase=
  File.join(simple_recruitment_info_fname_parsed[:dir],
            "#{simple_recruitment_info_fname_parsed[:base]}" +
            ".length_cutoff")
outpdf = outbase + '.pdf'
ci_script_output = outbase + '.txt'
real_mean = opts[:coverage]

cmd =
  "Rscript #{confidence_intervals} " +
  "--infile=#{infile} " +
  "--outpdf=#{outpdf} " +
  "--realMean=#{real_mean} " +
  "--realMean=#{opts[:coverage]} " +
  "--readLen=#{opts[:read_len]} " +
  "--kmer=#{opts[:kmer]} " +
  "> #{ci_script_output}"

run_it!(cmd)

$stderr.puts "\nFound length cutoff in #{elapsed_time(t)} minutes."

######################################################################
##### clean up #######################################################
######################################################################

File.delete(even_reads_fname)
File.delete(even_reads_fastq_fname)
File.delete(aligned_reads_sam)
