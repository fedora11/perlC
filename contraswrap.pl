#!/usr/bin/perl
#  contraswrap.pl
#
use contras;
use warnings;
use strict;
use Getopt::Long qw(GetOptions);
use Data::Dumper qw(Dumper);

our $debug;
our $OFFSET = 910200000;
my $version = 0;
# This value prevents false error if --debug is not set
my $tr_log_opn = 1;
my $generate = 0;
my $seed = time;
my $list = "";
GetOptions(
    'generate=i' => \$generate,
    'version=i' => \$version,
    'dance=s' => \$list,
    'debug' => \$debug,
) or die "Usage: $0 --debug --generate dance-number --dance \"move-1,move-2,...move-n\" --version number\n";

open(DATA, q{>}, "contra_$generate.txt");
# Only open the trace log if $debug set
$tr_log_opn = open(TRACE, q{>}, "contra_$generate.log") if $debug;
# If open fails for trace log, then don't try to write to it; turn debug off
if (!$tr_log_opn) {
  $debug = 0 ;
  print "Failed to open Trace Log. Continuing anyway.\n";
}

# If you supply a specific dance, we don't bother to generate one.
# If you generate with a specific value, the same dance is generated every time this is run.
if ($list) {
##If not comma separated list, try just spaces
  my @dance = split(',',$list);
  my $move_ct = scalar @dance;
  if ($move_ct < 2) {
    @dance = split(' ',$list);
  }
  if (dance_valid(@dance)) {
## When passing a Global to a file handle use *DATA or \*DATA
## http://stackoverflow.com/questions/16060919/alias-file-handle-to-stdout-in-perl
    print_dance(*DATA, @dance);
  } else {
    print "Dance Invalid. Possibly you have the wrong version of Possible Moves.\n";
  }
} elsif ($generate) {
  $seed = $generate + $OFFSET;
  main_contra_generator(*DATA, $seed);
} else {
  main_contra_generator(*DATA, $seed);
}

print "$main::version done\n";
