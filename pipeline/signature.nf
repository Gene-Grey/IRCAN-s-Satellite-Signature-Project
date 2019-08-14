#! /$HOME/nextflow

params.mode = "ssr"
params.kmer_size = 9
params.inputs_dir = "/home/jargentin/Documents/projet_signature/inputs"
params.out = "home/jargentin/Documents/projet_signature/outputs/signatures"

log.info """\
mode : $params.mode
kmer_size : $params.kmer_size
inputs_dir : $params.inputs_dir
"""

reads = Channel.create()
metadata = Channel.create()

Channel.fromFilePairs("${params.inputs_dir}/SRR*{.metadata.txt,.filt.fastq.gz,.filt.fastq.zip}", size: 2, checkIfExists: 'true')
       .map { left, right ->
         def SRRCode = left
         def readsFile = right[0]
         def metadataFile = right[1]
         tuple(SRRCode, readsFile, metadataFile)
       }
       .into { reads; metadata }



process ComputeReadsFile {
  tag "Splitting $SRRCode reads files"

  input:
  set SRRCode, file(readsFile), file(metadataFile) from reads

  output:
  file(computedReadsFile) into ComputedReadsChannel

  script:
  if( params.mode == "k_mer" )
    """
ssr
    """

  else if( params.mode == "ssr" )
    """
    unpigz -cp16 $readsFile | paste - - - - | cut -f 1,2 | sed 's/^@/>/' | tr "\t" "\n" > ${SRRCode}.fasta
    kmer-ssr -d -p 3-25 -r 3 -R 25 -l 50 -L 300 -t 2 -i ${SRRCode}.fasta -o ${SRRCode}.tsv
    """
}


/*
process ParseComputedReadsFile {
  tag "Splitting $SRRCode reads files"

  input:
  file(computedReadsFile) from ComputedReadsChannel

  output:
  file(parsedReadsFile) into ParsedReadsChannel

  """
  #!/usr/bin/env perl -w

  use strict;

  use JSON;


    """
}
*/


process PrintSignatureFile {
  tag "Splitting $SRRCode metadata files into signature file"

  input:
  set SRRCode, file(metadataFile) from metadata
  file(computedReadsFile) from ComputedReadsChannel

  publishDir params.out

  output:
  file "${SRRCode}.json"

  """
  #!/usr/bin/env perl

  use strict;
  use warnings;

  use JSON;

  sub processSatellitesDetection {
    my ($file) = @_;
    open (F, $file) or die("Can't open $file : \$!");

    my $lineCounter = 0;

    my %satellites = ();

    foreach my $line (<F>){

      if($lineCounter == 0) {
        $lineCounter++;        
        next;
      }

      chomp $line;

      my @line_tab_split = split("\t", $line);
      my $motif = "\\($line_tab_split[1]\\)$line_tab_split[2]";

      if(exists $satellites{$motif}) {
        $satellites{$motif}++;
      }

      else {
        $satellites{$motif} = 1;
      }

      $lineCounter++;
    }

    close F;
    return %satellites;
  }


  sub annotation_process {
    my ($file) = @_;
    open (F, $file) or die("Can't open $file : \$!");

    my @hash_array = ();

    my %annotation_hash = ();

    foreach my $line (<F>){
      chomp $line;

      if ($line =~ /^(\\w+)\$/gs) { # Case 1 : an array title
        push @hash_array, \$1;
      }

      elsif ($line eq ("\n" or "\r")) {
        next;
      }

      else {
        my @line_tab_split = split("\t", $line);
        splice(@line_tab_split, 0, 1);

  # <POSSIBLE IMPROVEMENT : Automatic hash dimension>
        if ( scalar(@line_tab_split) == 2 ) {
          $annotation_hash{$hash_array[-1]}{$line_tab_split[0]} = $line_tab_split[1];
        }

        elsif ( scalar(@line_tab_split) == 3 ) {
          $annotation_hash{$hash_array[-1]}{$line_tab_split[0]}{$line_tab_split[1]} = $line_tab_split[2];
        } # The last value of the array is the hash value, every other one are hash keys

        else {
          next;
        }
      }
    }

    close F;
    return %annotation_hash;
  }


  my %annotation_hash = processSatellitesDetection($computedReadsFile);
  my %satellites = annotation_process($metadataFile);

  %annotation_hash = (%annotation_hash, %satellites);

  my $json = JSON->new;
  my $pretty_printed = $json->pretty->encode(\\%annotation_hash);
  print $pretty_printed;

  """
}