#!usr/bin/perl

# NAME k_seek.r4.pl
# Identifies repeats in every read, and counts them, version 4 (combines k_finder and k_counter).

# Modified script by Guillamaury Debras in order to obtain the count of dinstinct repetitive sequences 
# according to their intern repetitions.
# Cleaned, reviewed and optimised by Joris Argentin 

use strict;
use warnings;

use POSIX;
use Cwd qw(getcwd);

my $input1 = $ARGV[0];
my $input2 = $ARGV[1];

# The information associated to the fastq format:
my $seq_ID = "undeclared"; # Line 1 : Sequence identifier
my $seq = "undeclared"; # Line 2 : Sequence
my $seq_line3 = "undeclared"; # Sequence supplementary information
my $quality = "undeclared"; # Line 4 : Read quality values
my $line_counter = 0;

open (GENOME_DATA, $input1) or die("Can't open $input1 : $!");
open (OUTPUT, ">$input2.rep");
open (TOTAL, ">$input2.total");

my @prime = (1,2,3,5,7,11); 
# Array of prime numbers from 1 to 11

my %cutoff = (
  "1" => 0, "2" => 5, "3" => 53,
  "4" => 2, "5" => 2, "6" => 2,
  "7" => 1, "8" => 1, "9" => 1, 
  "10" => 1, "11" => 1, "12" => 1, 
  "13" => 1, "14" => 1, "15" => 1,
  "16" => 1, "17" => 1, "18" => 1,
  "19" => 1, "20" => 1
); # Cut-off for the minimium number of values for each kmer stored in hash
#Source for these numbers ? Already there in k_seek.pl
my %k_mer_total = ();

READS: while (<GENOME_DATA>) { 
# Reading the input fastq file
  s/[\r\n]+$//; 
  # Removes newlines and carriage returns so that they don't interfere with the line counter
  $line_counter ++; 
  # The four next conditional structures parse and attribute to the right variables
  # the values associated to the fastq format

  if ($line_counter == 1) {
    $seq_ID = $_ ;
  }
 
  elsif ($line_counter == 2) {
    $seq = $_ ;
  } 

  elsif ($line_counter == 3) {
    $seq_line3 = $_ ;
  }
 
  else {
    $quality = $_;
    $line_counter = 0; # Reaching the fourth line, we reset the counter to 0 so we can analyse a new fastq read
    my $hit_boolean = 0; # Boolean value checking if the the sequence contains repeat hit(s)
    
    if ((length $seq < 20) or (substr($seq, -5, 5) eq "NNNNN")) { 
    # Skipping the analysis if the sequence is 
    # less than 20nt long; or the last five nt of the read are 'NNNNN'
# print length($seq), "\n";
# print substr($seq, -5, 5), "\n";
# <STDIN>;
      next;
    }
# print "$seq_ID\n$seq\n$seq_line3\n$quality\n";
    my %lengthHoH = (); # Hash of Hashes ?
    my $href; # ?

    SEQ: foreach my $k (reverse(5..11)) { 
    # Checking for different values of k : 11, 10, 9, 8, 7, 6, 5
      $href = { rep_identify($seq, $k) };
      # See rep_identify function
####################
      
      if (keys %{$href} < 1 or keys %{$href} > 3) {
        next ;
      }

      foreach my $key (keys %{$href}) {
        print "$k mer: $key with ${$href}{$key} repeats\n";

        if ($k * ${$href}{$key} >= 10) {
          my ($sub1, $sub2) = internal($key, ${$href}{$key});

          if ($sub1) {
            delete ${$href}{$key};
            ${$href}{$sub1} = $sub2;
# print "internal: $sub1 = $sub2\n";
          }

          $lengthHoH{$k} = $href;
        }
      }
    } # put all quantified length into hoh

    if (keys %lengthHoH >= 1) {
# foreach my $k (sort { $a <=> $b} keys %lengthHoH) {
  # print scalar keys %{$lengthHoH{$k}}, ":\t";

  # foreach my $key ( keys %{$lengthHoH{$k}} ) {
    # print "$key = ${$lengthHoH{$k}}{$key}\t";
  # }

  # print "\n";
# }
      my %sizeHoH;

      foreach my $k (keys %lengthHoH) {

        foreach my $key (keys %{$lengthHoH{$k}}) {
# print "$k\t$key =", ${$lengthHoH{$k}}{$key} * length($key),"\n";
          if ($sizeHoH{$key}) {

            if ($sizeHoH{$key} < ${$lengthHoH{$k}}{$key} * length($key)) {
              $sizeHoH{$key} = ${$lengthHoH{$k}}{$key} * length($key);
            }
          } 

          else {
            $sizeHoH{$key} = ${$lengthHoH{$k}}{$key} * length($key);
          }
        }
      }

      my @sorted = sort {$sizeHoH{$b} <=> $sizeHoH{$a}} keys %sizeHoH;
# foreach my $k (@sorted) {
  # print "$k = $sizeHoH{$k}\n";
# }
      my $lensorted = scalar @sorted;
#print $lensorted;
      for (my $i = 0; $i <= $lensorted-1; $i++) {
        my $kmer = $sorted[$i];

        if (length($kmer)>4){
          my ($k_mer_new, %hash) = k_counter($kmer, $seq);
          $kmer = $k_mer_new;

          foreach my $k (keys(%hash)) {
            my $k2 = join "",$kmer,"x$k";
# print "$k2\n";
# print OUTPUT "$seq_ID\n$seq\n$seq_line3\n$quality\n";
            print OUTPUT "$k2=$hash{$k}\n";
            $k_mer_total{$k2}+= $hash{$k};
# $k2;
          }
        }
      }

      $hit_boolean += 1; #It's a hit !
    }
# print "$seq_ID\n$seq\n";
# print "$sorted[0]=",$sizeHoH{$sorted[0]}/length($sorted[0]),"\n\n";
# <STDIN>;
    unless ($hit_boolean) {
      my $k_mer;
      my %lengthHoH_long;
      my $href_long;

      foreach my $k (reverse(12..20)) {
        $href_long = { rep_identify($seq, $k) };

        if (keys %{$href_long} >= 1 or  %{$href_long} <= 2) {

          foreach my $key (keys %{$href_long}) {
# print "$k mer: $key with ${$href_long}{$key} repeats\n";
            if ($k * ${$href_long}{$key} >= 10) {
              my $double_key = "$key$key";

              if ($seq =~ /$double_key/) {
                my ($sub1, $sub2) = internal($key, ${$href_long}{$key});

                if ($sub1) {
# print "$key = ${$href_long}{$key} => $sub1 = $sub2\n";
                  delete ${$href_long}{$key};
                }

                else {  
                  $lengthHoH_long{$k} = $href_long;
                }
              }
            }
          }
        }
      }

      if (keys %lengthHoH_long == 1 or keys %lengthHoH_long == 2) {
        my %hash = ();

        foreach my $k (keys %lengthHoH_long) {

          if (keys %{$lengthHoH_long{$k}} == 1 or keys %{$lengthHoH_long{$k}} == 2) {

            foreach my $l (sort { $lengthHoH_long{$k}{$b} <=> $lengthHoH_long{$k}{$a} } keys %{$lengthHoH_long{$k}}) {
              $hash{$l} = $lengthHoH_long{$k}{$l} * $k;
            }
          }
        }

        my @sorted = (sort { $hash{$b} <=> $hash{$a} } keys %hash);
        my $lensorted = scalar @sorted;
# print $lensorted;
        for (my $i = 0; $i <= $lensorted-1; $i++) {
          $k_mer = $sorted[$i];

          if ($k_mer) {
            my ($k_mer_new, %hash) = k_counter($k_mer, $seq);
            $k_mer = $k_mer_new;

            foreach my $k (keys(%hash)) {
              my $k2 = join "",$k_mer,"x$k";
# print "$k2\n";
# print OUTPUT "$seq_ID\n$seq\n$seq_line3\n$quality\n";
              print OUTPUT "$k2=$hash{$k}\n";
              $k_mer_total{$k2}+= $hash{$k};
# $k2;
            }
          }
        }
      }
    }
  }
}
####################

foreach my $rep (sort keys %k_mer_total) { 
# Printing the results in the output file
  print TOTAL "$rep\t$k_mer_total{$rep}\n";
}


# Identifies all motifs of length 1 to k
# $sequence : a nucleotidic sequence
# $k_length : the tested k-mer length
sub rep_identify { 
  my $sequence = shift @_; 
  my $k_length = shift @_;
  
  my @rep_array = ($sequence =~ m/(.{1,$k_length})/gs); 
  # The array is filled with every motif with a length ranging from 1 to k
  
  my %rep_hash;

  foreach my $element (@rep_array) {
  # Setting up a hash of all elements and the number their occurences
# print "$_\t";
     $rep_hash{$element}++;
  }

  foreach my $k_mer (keys %rep_hash) {
  # Each k-mer is compared to the cutoff value : 
  # if there's not enough instances, the k-mer is removed
    delete $rep_hash{$k_mer} if ($rep_hash{$k_mer} <= $cutoff{$k_length});
  }
  
  if (keys %rep_hash == 1) { 
  # If there's only one element in the hash, then it is logged as a repeat,
  # as it means that all elements in the sequence are part of the repeat
    foreach my $k_mer (keys %rep_hash) {
      return %rep_hash; # Makes no sense  whatsoever
    }
  }

  elsif (keys %rep_hash > 1 && keys %rep_hash <= 3) { 
  # If more there's more than one element in the hash, but less than four 
  # then the subroutine checks for offsets for k-mers, in ascending number of instances
    my @k_mer_array = sort {$rep_hash{$a} <=> $rep_hash{$b}} keys %rep_hash;
    my $test = shift @k_mer_array;
# print "test: $test : $rep_hash{$test}\n";

    foreach my $k_mer (@k_mer_array) {
    # The k-mer with the lowest number of instances in %rep_hash is tested 
    # via the test_off subroutine against every other k-mer in the hash
    # If the k-mer is offset, it is removed

# print "multi: $kmer : $rep_hash{$kmer}\n";
      if (test_off($test, $k_mer)) { 
        $rep_hash{$test} += $rep_hash{$k_mer};
# print "delete: $kmer ($test): $rep_hash{$kmer}\n";
        delete $rep_hash{$k_mer};
      }
    }

#Useless loop?
    foreach my $k_mer (keys %rep_hash) {
# print "remaining: $kmer : $rep_hash{$kmer}\n";
    }

    return %rep_hash;

  } else {
    return %rep_hash;
  }
}



# Check for internal repetition in the identified repeat

#INPUT :
# [0] $tested_rep : repeats to be tested
# [1] $rep_count : number of occurences

#OUTPUT :

sub internal { 
  my $tested_rep = shift @_;
  my $rep_count = shift @_;
  
  my @mono_array = ($tested_rep =~ m/(.{1,1})/gs);
  # The array is filled with every motif of length 1

  my %mono_hash = ();
  my %return_hash = ($tested_rep => $rep_count,);

  foreach (@mono_array) {
  # Then every instance of every element in counted
    $mono_hash{$_} ++;
  }

  if (keys %mono_hash == 1) {
  # If there's only one key in the hash,
  # it means that is a repeated mononucleotide
    return($mono_array[0], $rep_count*length($tested_rep));
    #The subroutine then returns the nucleotide
  } 

  elsif (grep { $_ == length($tested_rep) } @prime) {
    return(0,0);
  } 

####################
  else {
    my @factors = grep { length($tested_rep) % $_ == 0 } 2 .. (floor(length($tested_rep))/2);
    INTER: foreach my $factor (@factors) {
      my @factor_array = ($tested_rep =~ m/(.{1,$factor})/gs); 
      my %factor_hash = ();

      foreach (@factor_array) {
        $factor_hash{$_} ++;
      }

      if ( keys %factor_hash == 1 ) {

        foreach my $key (keys %factor_hash) {
          $factor_hash{$key} = $rep_count*length($tested_rep)/$factor;
# print "$seq_ID\n$seq\n$seq_line3\n$quality\n";
# print "hit!\t $tested_rep = $rep_count\t$key = ", $rep_count*length($tested_rep)/$factor, "\n";
# <STDIN>;
          return($key, $rep_count*length($tested_rep)/$factor);          
        }
      }
    }
  }
####################
  return (0,0);
}



# FUNCTION  test_off
# Returns if the pattern 1 passed is either similar to the pattern 2 or similar to two instances of the pattern 2

# INPUTS
# [0] A repeeat sequence
# [1] Another repeeat sequence !

# OUTPUT
# Boolean value : 0 or 1

sub test_off
{

my $rep1 = shift @_;
my $rep2 = shift @_;

  if ($rep1 eq $rep2) {
    return(1);
  } else {
    my $double_rep2 = "$rep2.$rep2";

    if ($double_rep2 =~ /$rep1/) {
# print "$_[0]\t$_[1]\n";
      return(1);
    } else {
      return(0);
    }
  }
}



# FUNCTION degen
# Identifes single substitution/insertion/deletion within a kmer

# INPUTS
# [0] A target sequence
# [1] A k-mer sequence

# OUTPUT
# A boolean value

sub degen
{ 

  my $target_seq = shift @_;
  my $k_mer_seq = shift @_;
  my $diff = length($target_seq) - length($k_mer_seq);

  if ($diff == 0) { 
  # If there's no difference, the function tires to find substitutions anyway
    foreach (0 .. (1 - length($k_mer_seq))) {
      my $degen_k_mer = substr($k_mer_seq, $_, 1, "[ACTGN]");
          
      if ($target_seq =~ /$degen_k_mer/g) {
# print " C BON\n";
        return 1;
      }
    }

    return 0;
  }

  elsif ($diff > 0) { 
  # If there's a positive difference, the subroutine looks for insertions
    foreach (0..length($k_mer_seq)) {
      my $ins_k_mer_seq = substr($target_seq, 0, $_) . substr($target_seq, $_ + $diff);
      
      if ($ins_k_mer_seq eq $k_mer_seq) {
        return 1;
      }
    }

    return 0;
  } 

  elsif ($diff < 0 && length($target_seq) >= 3) { 
  # If there's a negative difference, the subroutine looks for deletions

    foreach (0..length($target_seq)) {
      my $del_k_mer_seq = substr($k_mer_seq, 0, $_) . substr($k_mer_seq, $_ - $diff);

      if ($target_seq eq $del_k_mer_seq) {
        return 1;
      }
    }

    return 0;
  }

  else {
    return 0;
  }
}



# FUNCTION degen
# Identifes single substitution/insertion/deletion within a kmer

# INPUTS
# [0] A target sequence
# [1] A k-mer sequence

# OUTPUT
# A boolean value

sub k_counter {
  my $k_mer = shift @_;
  my $seq_copy = shift @_;
  my $string_counter = 0;

  my @sub_seq = ();

  my %tmp_hash = ();

# 
  if (length($k_mer) <= 3) {
    $string_counter = index($seq_copy, "$k_mer.$k_mer"); 
    # For a pattern with a length k inferior or equal to 3, 
    # the function looks for two pattern instances i.e 'AATAAT' instead of 'AAT'
  } 

  else {
    $string_counter = index($seq_copy, "$k_mer");
  }

  if ($string_counter) { # check for the best offset of the kmer.

    foreach my $i (1..(length($k_mer)-1)) {

      if (substr($seq_copy, $string_counter - 1, 1) eq substr($k_mer, -1)) {
        $k_mer = substr($seq_copy, $string_counter - 1, length($k_mer));
        $string_counter -= 1;
      } 

      else {
        last;
      }
    }
  }
  
  while ($string_counter != -1) {

    if ($string_counter > 0) {
      push @sub_seq, substr($seq_copy, 0, $string_counter);
      $seq_copy = substr($seq_copy, $string_counter);
    } 

    elsif ($string_counter == 0) {
      push @sub_seq, substr($seq_copy, 0, length($k_mer));
      $seq_copy = substr($seq_copy, length($k_mer));
    }

    $string_counter = index($seq_copy, $k_mer);
  }

  if ($seq_copy) {
    push @sub_seq, $seq_copy;
  }

  unshift @sub_seq, "@@";
  push @sub_seq, "%%"; # adding random sequences at front and back of array
  my $degcounts = 0;

  foreach my $i (1..(scalar(@sub_seq)-2)) {
     
    if (length($sub_seq[$i]) > 4) {
# print "$sub_seq[$i]\n";
     
      if ($sub_seq[$i] eq $k_mer and $sub_seq[$i-1] ne $sub_seq[$i] and $sub_seq[$i] eq $sub_seq[$i+1]) { 
        my $ind1 = 1;
        my $ind2 = 2;
        my $cpt = 2;
          
        while ($sub_seq[$i+$ind1] eq $sub_seq[$i+$ind2]){
          $cpt++;
          $ind1++;
          $ind2++;
        }

      $tmp_hash{$cpt}+=1;
      }
    }

# 
    if ($sub_seq[$i] ne $k_mer) {
# print "$sub_seq[$i]\n";
      if ($sub_seq[$i-1] eq $sub_seq[$i+1]) {

        if (degen($sub_seq[$i], $k_mer)) {
# print "C OK\n";
        }
      }
    }
  }
# foreach my $k_mer (keys(%tmp_hash)) {
#   print "Clef=$k_mer Valeur=$tmp_hash{$k_mer}\n";
# }
  return($k_mer,%tmp_hash);
}


unlink("$input2.rep");
