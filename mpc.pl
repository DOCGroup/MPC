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
use File::Basename;

my($basePath) = getExecutePath($0);
unshift(@INC, $basePath . '/modules');

require MPC;

# ************************************************************
# Subroutine Section
# ************************************************************

sub getBasePath {
  return $basePath;
}


sub which {
  my($prog) = shift;
  my($exec) = $prog;

  if (defined $ENV{'PATH'}) {
    my($part)   = '';
    my($envSep) = $Config{'path_sep'};
    foreach $part (split(/$envSep/, $ENV{'PATH'})) {
      $part .= "/$prog";
      if ( -x $part ) {
        $exec = $part;
        last;
      }
    }
  }

  return $exec;
}


sub getExecutePath {
  my($prog) = shift;
  my($loc)  = '';

  if ($prog ne basename($prog)) {
    if ($prog =~ /^[\/\\]/ ||
        $prog =~ /^[A-Za-z]:[\/\\]?/) {
      $loc = dirname($prog);
    }
    else {
      $loc = getcwd() . '/' . dirname($prog);
    }
  }
  else {
    $loc = dirname(which($prog));
  }

  if ($loc eq '.') {
    $loc = getcwd();
  }

  if ($loc ne '') {
    $loc .= '/';
  }

  return $loc;
}


# ************************************************************
# Main Section
# ************************************************************

my($driver) = new MPC();
exit($driver->execute($basePath, basename($0), \@ARGV));
