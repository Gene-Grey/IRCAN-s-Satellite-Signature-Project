#!/usr/bin/env perl -w

use strict;

use JSON;

sub annotation_process {
  my ($file) = @_;
  open (F, $file)
    or die("Can't open $file : $!");

  my @hash_array = ();

  my %annotation_hash = ();

  foreach my $line (<F>){
    chomp $line;

    if ($line =~ /^(\w+)$/gs) { # Case 1 : an array title
      push @hash_array, $1;
    }

    elsif ($line eq ("\n" or "\r")) {
      next;
    }

    else {
      my @line_tab_split = split("\t", $line);
      splice(@line_tab_split, 0, 1);
# print join("\n", @line_tab_split), "\n";

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
  my $json = JSON->new;
  my $pretty_printed = $json->pretty->encode(\%annotation_hash);
  return $pretty_printed;
}

print annotation_process($ARGV[0]);
