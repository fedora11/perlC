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
my $seed = time;
my $list = "";
GetOptions(
    'generate=i' => \$generate,
    'version=i' => \$version,
    'dance=s' => \$list,
    'debug' => \$debug,
) or die "Usage: $0 --debug --generate dance-number --dance \"move-1,move-2,...move-n\" --version number\n";

if ($list) {
  my @dance = split(',',$list);

} elsif ($generate) {
  $seed = $generate+910200000;
} else {

}

## When passing a Global to a file handle use *TRACE or \*TRACE
## http://stackoverflow.com/questions/16060919/alias-file-handle-to-stdout-in-perl
main_contra_generator(*TRACE, $seed);
print "$main::version done\n";
