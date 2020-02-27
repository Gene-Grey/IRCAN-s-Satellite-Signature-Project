#!/usr/bin/env perl -w

use strict;

use JSON;

sub processSatellitesDetection {
  my ($file) = @_;
  open (F, $file) or die("Can't open $file : $!");

  my $lineCounter = 0;

  my %satellites = ();

  foreach my $line (<F>){

    if($lineCounter == 0) {
      $lineCounter++;        
      next;
    }

    chomp $line;

    my @line_tab_split = split("\t", $line);
    my $motif = "\($line_tab_split[1]\)$line_tab_split[2]";

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
  open (F, $file) or die("Can't open $file : $!");

  my @hash_array = ();

  my %annotation_hash = ();

  foreach my $line (<F>){
    chomp $line;

    if ($line =~ /^(\w+)$/gs) { # Case 1 : an array title
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


#my %annotation_hash = processSatellitesDetection($computedReadsFile);
#my %satellites annotation_process($metadataFile);

#%annotation_hash = (%annotation_hash, %satellites);

my %annotation_hash = processSatellitesDetection($ARGV[0]);
my %satellites = annotation_process($ARGV[1]);

%annotation_hash = (%annotation_hash, %satellites);

my $json = JSON->new;
my $pretty_printed = $json->pretty->encode(\%annotation_hash);
print $pretty_printed;
