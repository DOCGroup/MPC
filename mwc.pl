#! /usr/bin/perl
eval '(exit $?0)' && eval 'exec perl -w -S $0 ${1+"$@"}'
    & eval 'exec perl -w -S $0 $argv:q'
    if 0;

# ******************************************************************
#      Author: Chad Elliott
#        Date: 6/17/2002
#         $Id$
# ******************************************************************

# ******************************************************************
# Pragma Section
# ******************************************************************

require 5.006;

use strict;
use FindBin;
use File::Spec;
use File::Basename;

## Sometimes $FindBin::RealBin will end up undefined.  If it is, we need
## to use the directory of the built-in script name.  And, for VMS, we
## have to convert that into a UNIX path so that Perl can use it
## internally.
my $basePath = (defined $FindBin::RealBin && $FindBin::RealBin ne '' ?
                  $FindBin::RealBin : File::Spec->rel2abs(dirname($0)));
$basePath = VMS::Filespec::unixify($basePath) if ($^O eq 'VMS');
unshift(@INC, $basePath . '/modules');

require Driver;

# ************************************************************
# Subroutine Section
# ************************************************************

sub getBasePath {
  return $basePath;
}

# ************************************************************
# Main Section
# ************************************************************

my $driver = new Driver($basePath, Driver::workspaces());
exit($driver->run(@ARGV));
