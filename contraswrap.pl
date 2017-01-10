#!/usr/bin/perl
#  contraswrap.pl
#
use contras;
use warnings;
use strict;

## When passing a Global to a file handle use *TRACE or \*TRACE
## http://stackoverflow.com/questions/16060919/alias-file-handle-to-stdout-in-perl
main_contra_generator(*TRACE);
print "$main::version done\n";
