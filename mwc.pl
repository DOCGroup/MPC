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

use strict;
use Cwd;
use Config;
use FindBin;
use File::Basename;

my($basePath) = $FindBin::Bin;
unshift(@INC, $basePath . '/modules');

require MWC;

# ************************************************************
# Subroutine Section
# ************************************************************

sub getBasePath {
  return $basePath;
}

# ************************************************************
# Main Section
# ************************************************************

my($driver) = new MWC();
exit($driver->execute($basePath, basename($0), \@ARGV));
