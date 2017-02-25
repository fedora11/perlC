#!/usr/bin/perl
#  contraswrap.pl
#
#use contras01;
use contras;
use warnings;
use strict;
use Getopt::Long qw(GetOptions);
use Data::Dumper qw(Dumper);

our $debug;
#our $OFFSET = 910200000;
our $OFFSET = 915200000;
our $fh2;
my $version = 0;
# This value prevents false error if --debug is not set
my $tr_log_opn = 1;
my $generate = 0;
my $seed = time;
my $list = "";
my $moves;
my $count = 1;
GetOptions(
    'generate=i' => \$generate,
    'count=i' => \$count,
    'version=i' => \$version,
    'dance=s' => \$list,
    'debug' => \$debug,
    'moves' => \$moves,
) or die "Usage: $0 --dance \"move-1,move-2,...move-n\" --debug --generate dance-number --moves --version number\n";

open(my $fh1, q{>}, "contra_$generate.txt");
open($fh2, q{>>}, "dances.txt");
# Only open the trace log if $debug set
$tr_log_opn = open(TRACE, q{>}, "contra_$generate.log") if $debug;
# If open fails for trace log, then don't try to write to it; turn debug off
if (!$tr_log_opn) {
  $debug = 0 ;
  print "Failed to open Trace Log. Continuing anyway.\n";
}

if ($moves) {
  print_out_moves($fh1);
# If you supply a specific dance, we don't bother to generate one.
# If you generate with a specific value, the same dance is generated every time this is run.
} elsif ($list) {
##If not comma separated list, try just spaces
  my @dance = split(',',$list);
  my $move_ct = scalar @dance;
  if ($move_ct < 2) {
    @dance = split(' ',$list);
  }
  if (dance_valid(@dance)) {
## When passing a Global to a file handle use *DATA or \*DATA
## http://stackoverflow.com/questions/16060919/alias-file-handle-to-stdout-in-perl
    print_dance($fh1, @dance);
    print $fh1 "<P><I>Dance moves ",
      " = $list (version $main::VERSION)</I>\n";
  } else {
    print "Dance Invalid. Possibly you have the wrong version of Possible Moves.\n";
  }
} elsif ($generate) {
  $seed = $generate + $OFFSET;
  for (my $repeats = 0; $repeats < $count; $repeats++) {
    main_contra_generator($fh1, $seed);
    $seed++;
  }
} else {
  main_contra_generator($fh1, $seed);
}

print "$main::VERSION done\n";
close($fh1);
close($fh2);