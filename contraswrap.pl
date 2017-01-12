#!/usr/bin/perl
#  contraswrap.pl
#
use contras;
use warnings;
use strict;
use Getopt::Long qw(GetOptions);
use Data::Dumper qw(Dumper);

my $debug;
my $version = 0;
my $generate = 0;
my $OFFSET = 910200000;
my $seed = time;
my $list = "";
GetOptions(
    'generate=i' => \$generate,
    'version=i' => \$version,
    'dance=s' => \$list,
    'debug' => \$debug,
) or die "Usage: $0 --debug --generate dance-number --dance \"move-1,move-2,...move-n\" --version number\n";

# If you supply a specific dance, we don't bother to generate one.
# If you generate with a specific value, the same dance is generated every time this is run.
if ($list) {
  my @dance = split(',',$list);
  open(TRACE, q{>}, "contra_trace.log");
  if (dance_valid(@dance)) {
## When passing a Global to a file handle use *TRACE or \*TRACE
## http://stackoverflow.com/questions/16060919/alias-file-handle-to-stdout-in-perl
    print_dance_w_floorplans(*TRACE, @dance);
  } else {
    print "Dance Invalid. Possibly you have the wrong version of Possible Moves.\n";
  }
} elsif ($generate) {
  $seed = $generate + $OFFSET;
  main_contra_generator(*TRACE, $seed);
} else {
  main_contra_generator(*TRACE, $seed);
}

print "$main::version done\n";
