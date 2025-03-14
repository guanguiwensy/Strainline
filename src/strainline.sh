#!/usr/bin/env bash

set -e

#Prints a help message
function print_help() {
  echo "Usage: $0 [options] -i reads.fasta -o out/ -p sequencingPlatform"
  echo ""
  echo "Full-length De Novo Viral Haplotype Reconstruction from Noisy Long Reads"
  echo ""
  echo "Author: Xiao Luo"
  echo "Date:   Mar 2021"
  echo ""
  echo "	Input:"
  echo "	reads.fasta:                      fasta file of input long reads."
  echo "	out/:                             directory where to output the results."
  echo "	sequencingPlatform:               long read sequencing platform: PacBio (-p pb) or Oxford Nanopore (-p ont)"
  echo ""
  echo "	Options:"
  echo "	--minTrimmedLen INT:              Minimum trimmed read length. (default: 1000)"
  echo "	--topk INT, -k INT:               Choose top k seed reads. (default: 100)"
  echo "	--minOvlpLen INT:                 Minimum read overlap length. (default: 1000)"
  echo "	--minIdentity FLOAT:              Minimum identity of overlaps. (default: 0.99)"
  echo "	--minSeedLen INT:                 Minimum seed read length. (default: 3000)"
  echo "	--maxOH INT:                      Maximum overhang length allowed for overlaps. (default: 30)"
  echo "	--iter INT:                       Number of iterations for contig extension. (default: 2)"
  echo "	--maxGD FLOAT:                    Maximum global divergence allowed for merging haplotypes. (default: 0.01)"
  echo "	--maxLD FLOAT:                    Maximum local divergence allowed for merging haplotypes. (default: 0.001)"
  echo "	--maxCO INT:                      Maximum overhang length allowed for contig contains. (default: 5)"
#  echo "	--perIdentity INT:                Percent identity for haplotype abundacne computation. (default: 97)"
  echo "	--minAbun FLOAT:                  Minimum abundance for filtering haplotypes (default: 0.02)"
  echo "	--rmMisassembly BOOL:             Break contigs at potential misassembled positions (default: False)"
  echo "	--correctErr BOOL:                Perform error correction for input reads (default: True)"
  echo "	--dsim FLOAT:                     Look for alignments with this percent similarity in Daligner. (default: 0.85)"
  echo "	--threads INT, -t INT:            Number of processes to run in parallel (default: 8)."
  echo "	--help, -h:                       Print this help message."
  exit 1
}

#Set options to default values
input_fa=""
threads=8
outdir="out/"

min_trimmed_len=1000

topk=100
platform="pb"
min_ovlp_len=1000
min_identity=0.99
o=30
r=0.8
max_ovlps=1000
min_sread_len=3000

iter=2
max_global_divergence=0.01
max_local_divergence=0.001 
maxCO=5

percent_identity=97
min_abun=0.02 #
rm_misassembly="False"
correct_err="True"
dsim=0.85

#Print help if no argument specified
if [[ "$1" == "" ]]; then
  print_help
fi

#Options handling
while [[ "$1" != "" ]]; do
  case "$1" in
  "--help" | "-h")
    print_help
    ;;
  "-i")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      input_fa="$2"
      shift 2
      ;;
    esac
    ;;
  "-o")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      outdir="$2"
      shift 2
      ;;
    esac
    ;;
  "-p")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *) if [[ "$2" == "pb" ]]; then
      platform="pb"
      shift 2
    elif [[ "$2" == "ont" ]]; then
      platform="ont"
      shift 2
    else
      echo "Error: $1 must be either pb or ont"
      exit 1
    fi ;;
    esac
    ;;
  "--minTrimmedLen")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      min_trimmed_len="$2"
      shift 2
      ;;
    esac
    ;;
  "--topk" | "-k")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      topk="$2"
      shift 2
      ;;
    esac
    ;;
  "--minOvlpLen")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      min_ovlp_len="$2"
      shift 2
      ;;
    esac
    ;;
  "--minIdentity")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      min_identity="$2"
      shift 2
      ;;
    esac
    ;;
  "--minSeedLen")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      min_sread_len="$2"
      shift 2
      ;;
    esac
    ;;
  "--maxOH")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      o="$2"
      shift 2
      ;;
    esac
    ;;
  "--iter")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      iter="$2"
      shift 2
      ;;
    esac
    ;;
  "--maxGD")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      max_global_divergence="$2"
      shift 2
      ;;
    esac
    ;;
  "--maxLD")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      max_local_divergence="$2"
      shift 2
      ;;
    esac
    ;;
  "--maxCO")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      maxCO="$2"
      shift 2
      ;;
    esac
    ;;
  "--minAbun")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      min_abun="$2"
      shift 2
      ;;
    esac
    ;;
  "--rmMisassembly")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      rm_misassembly="$2"
      shift 2
      ;;
    esac
    ;;
  "--correctErr")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      correct_err="$2"
      shift 2
      ;;
    esac
    ;;
  "--dsim")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      dsim="$2"
      shift 2
      ;;
    esac
    ;;
  "--threads" | "-t")
    case "$2" in
    "")
      echo "Error: $1 expects an argument"
      exit 1
      ;;
    *)
      threads="$2"
      shift 2
      ;;
    esac
    ;;
#
  --)
    shift
    break
    ;;
  *)
    echo "Error: invalid option \"$1\""
    exit 1
    ;;
  esac
done

#Exit if no input or no output files have been specified
if [[ $input_fa == "" ]]; then
  echo "Error: -i must be specified"
  exit 1
fi

basepath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

##############################################
######## Step1: read error correction ########
##############################################
#if [ ! -d $outdir ]; then
#  mkdir $outdir
#else
#  echo Directory \'$outdir\' 'already exists, please use a new one, exiting...'
#  exit
#fi
mkdir -p $outdir

input_fa=$(readlink -f $input_fa)
cd $outdir || exit

# ln -fs $input_fa reads.fasta 

# convert input fasta into wrapped fasta (60 bases per line) 
# to avoid issue: 'Fasta line is too long'
perl -e ' $/=">";open A,$ARGV[0] or die $!; <A>; 
          while(<A>){chomp;my@a=split/\n/;print ">$a[0]\n";my$seq=join("",@a[1..$#a]);
          my$len=length($seq);my $L=int $len/60;$L+=1 if $L*60<$len;
          for(my$i=0;$i<$L;$i++){print substr($seq,$i*60,60);print "\n";}
          }close A;' $input_fa >reads.fasta 

if [[ $correct_err == "True" ]];then
  fasta2DAM reads.dam reads
  DBsplit -s256 -x$min_trimmed_len reads.dam # -x: Trimmed DB has reads >= this threshold.
  mkdir tmp || exit
  #HPC.daligner reads.dam -T$threads | bash #return core-dump error if using all cores
  HPC.daligner reads.dam -e$dsim -P./tmp -T$threads | bash #only conda installed version support '-P'
  # HPC.daligner reads.dam -e0.85 -T$threads | bash
  #  daccord -t$threads reads.las reads.dam >corrected.0.fa
  touch corrected.0.fa
  for las_file in reads.*las;
  do
    daccord -t$threads $las_file reads.dam >>corrected.0.fa
  done

  echo 'Step1: read error correction. Finished.'
else
  echo 'Skip Step1, do not perform error correction.'
fi

##############################################
########### Step2: read clustering ###########
##############################################

for ((i = 0; i < $iter; i++)); do
  let j=$i+1
  mkdir -p iter$j
  #reformat fasta
  python $basepath/reformat_fa.py corrected.$i.fa corrected.$i.reformat.fa
  python $basepath/clustering.py corrected.$i.reformat.fa ./iter$j/ $topk $platform $threads $min_ovlp_len $min_identity $o $r $max_ovlps $min_sread_len
  cat ./iter$j/contig.*.fa | perl -ne 'if (/^>/){print ">r$.\n";}else{print;}' >corrected.$j.fa
done

python $basepath/reformat_fa.py corrected.$j.fa contigs.fa

##############################################
#### Step3: redundant haplotypes removal #####
##############################################

ls ./iter$j/contig.*.fa >contig_list.txt

fa_list_file=contig_list.txt

#generate 'haplotypes.fa'
python $basepath/rm_redundant_genomes.py $fa_list_file $max_global_divergence . $threads $max_local_divergence $maxCO


#optional ,remove misassembly
if [[ $rm_misassembly == "True" ]]; then
  cat haplotypes.fa|perl -ne 'BEGIN{$head;$i=0;}if(/^>/){$head=">contig$i";}else{if (length($_) >1000){print "$head\n$_";$i+=1;} }' >tmp.fa
  num_contig=`cat tmp.fa |grep ">"|wc -l`
  fa_read=corrected.0.fa #corrected reads
  python $basepath/rm_misassembly.py $fa_read  tmp.fa rmMisassemly $threads  $num_contig
  cat rmMisassemly/contig.*.fa >haplotypes.rm_misassembly.redundant.fa

  #remove redundant contigs again because some non-redundant contigs may be caused by misassembly
  ls rmMisassemly/contig.*.fa >contig_list.txt2
  python $basepath/rm_redundant_genomes.py contig_list.txt2 $max_global_divergence . $threads $max_local_divergence $maxCO
  cp haplotypes.fa haplotypes.rm_misassembly.fa
elif [[ $rm_misassembly == "False" ]]; then
  cp haplotypes.fa haplotypes.rm_misassembly.fa
else
  echo "invalid value for --rmMisassembly, should be either True or False."
  exit 1
fi

##############################################
### Step4: low frequent haplotypes removal ###
##############################################
export min_abundance=$min_abun

mkdir -p filter_by_abun
cd filter_by_abun || exit
fa_read=../corrected.0.fa #corrected reads

for i in {1..2};
do
  if [[ $i == 1 ]];then
    cat ../haplotypes.rm_misassembly.fa | perl -ne 'BEGIN{$i=1;}if(/^>/){print ">contig_$i\n";$i+=1;}else{print;}' >haps.fa
  else
    cat haplotypes.final.fa | perl -ne 'BEGIN{$i=1;}if(/^>/){print ">contig_$i\n";$i+=1;}else{print;}' >haps.fa
  fi
  minimap2 -a --secondary=no -t $threads haps.fa $fa_read | samtools view -F 3584 -b -t $threads | samtools sort - >haps.bam

  jgi_summarize_bam_contig_depths haps.bam --percentIdentity $percent_identity --outputDepth haps.depth

  perl -e 'open A,"haps.depth";<A>;my$alldepth=0;while(<A>){my@a=split;$alldepth+=$a[2];}close A; \
  open A,"haps.depth";<A>;while(<A>){my@a=split;my$d=$a[2]/$alldepth;print "$a[0]\t$a[1]\t$a[2]\t$d\n";}close A; ' |
    sort -k4nr >haps.depth.sort

  perl -e ' my%id2seq;$/=">";open A,"haps.fa";<A>;while(<A>){chomp;my@a=split;$id2seq{$a[0]}=$a[1];}close A;
  $/="\n"; open A,"haps.depth.sort";my$k=0;while(<A>){chomp;my@a=split;next if $a[-1]<$ENV{"min_abundance"};
  my$abun=sprintf "%.3f",$a[-1];my$cov=sprintf "%.0f",$a[-2]; $k+=1;print ">hap$k $cov"."x freq=$abun\n$id2seq{$a[0]}\n";}close A; ' >haplotypes.final.fa
done
#TODO, after filtering, is it necessary to recompute the abundance of haplotypes ? yes, see for loop


## Done ##
cd ..
ln -fs ./filter_by_abun/haplotypes.final.fa .
echo 'All steps finished successfully.'
echo 'The final haplotypes and their relative abundances are saved here: '$outdir'/haplotypes.final.fa'
