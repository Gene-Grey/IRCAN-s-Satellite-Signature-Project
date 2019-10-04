#!/usr/bin/env perl -w

use strict;

sub satelliteCodeToSequence {
  my ($file) = @_;

  my $lineCounter = 1;

  my @resArray;
  open (F, $file)
    or die("Can't open $file : $!");

  foreach my $line (<F>){
    chomp $line;

    if ($line =~ /^\((\D+)\)(\d+)$/gs) {
      
      if($2+0 < 1) {
        push @resArray, "Error : satellite at line", $lineCounter, "repeat period inferior to 1";
      }

      else {
        push @resArray, $1 x $2;
      }
    }

    else {
      print "Error : satellite at line ", $lineCounter, " does not match format\n";
      $lineCounter++;
      next;
    }

    $lineCounter++;
  }
  return join("\n", @resArray);
}

print satelliteCodeToSequence($ARGV[0]), "\n";
