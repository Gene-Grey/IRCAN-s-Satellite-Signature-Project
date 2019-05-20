#!/bin/bash

function kmerSSRFromFastq {
  filename=${basename $1 .filt.fastq.gz}
  unpigz -cp16 $1 | paste - - - - | cut -f 1,2 | sed 's/^@/>/' | tr "\t" "\n" > $filename.fasta
  kmer-ssr -p 2-9 -r 3 -R 20 -t 10 -i $filename.fasta -o $filename.tsv
}
