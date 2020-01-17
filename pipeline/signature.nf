#!/$HOME/nextflow

log.info """\
mode : $params.mode
inputs_dir : $params.inputs_dir
output_dir : $params.output_dir
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
//TO DO : Gerbil implementation

  else if( params.mode == "ssr" )
    """
    unpigz -cp16 $readsFile | paste - - - - | cut -f 1,2 | sed 's/^@/>/' | tr "\t" "\n" > ${SRRCode}.fasta
    kmer-ssr -d -p ${periodMin}-${periodMax} -r ${repeatMin} -R ${repeatMax} -l ${readLengthMin} -L ${readLengthMax} -t ${threads} -i ${SRRCode}.fasta -o ${SRRCode}.tsv
    """
}


process PrintSignatureFile {
  tag "Merging $SRRCode metadata and SSR signature files into json file"

  input:
  set SRRCode, file(metadataFile) from metadata
  file(computedReadsFile) from ComputedReadsChannel

  publishDir params.out

  output:
  file "${SRRCode}.json"

  script:
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

    my @hash_array = ();java

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
// <POSSIBLE IMPROVEMENT : Automatic hash dimension>


workflow.onComplete {

    sendMail(
      to: notification.to
      from: notification.from,
      subject: "Signature pipeline on ${SRRCode} complete",
      body: ${notification.template}.stripIndent(),
      attach: "${output_dir}/${SRRCode}.json"
      attach: 
    )
}