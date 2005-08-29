package DirectoryManager;

# ************************************************************
# Description   : This module provides directory related methods
# Author        : Chad Elliott
# Create Date   : 5/13/2004
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use File::Basename;

if ($^O eq 'VMS') {
  require VMS::Filespec;
  import VMS::Filespec qw(unixify);
}

# ************************************************************
# Data Section
# ************************************************************

my($cwd) = Cwd::getcwd();
if ($^O eq 'cygwin' && $cwd !~ /[A-Za-z]:/) {
  my($cyg) = `cygpath -w $cwd`;
  if (defined $cyg) {
    $cyg =~ s/\\/\//g;
    chop($cwd = $cyg);
  }
}
my($start) = $cwd;

# ************************************************************
# Subroutine Section
# ************************************************************

sub cd {
  my($self)   = shift;
  my($dir)    = shift;
  my($status) = chdir($dir);

  if ($status && $dir ne '.') {
    ## First strip out any /./ or ./ or /.
    $dir =~ s/\/\.\//\//g;
    $dir =~ s/^\.\///;
    $dir =~ s/\/\.$//;

    ## If the new directory contains a relative directory
    ## then we just get the real working directory
    if ($dir =~ /\.\./) {
      $cwd = Cwd::getcwd();
      if ($^O eq 'cygwin' && $cwd !~ /[A-Za-z]:/) {
         my($cyg) = `cygpath -w $cwd`;
         if (defined $cyg) {
           $cyg =~ s/\\/\//g;
           chop($cwd = $cyg);
         }
       }
    }
    else {
      if ($dir =~ /^(\/|[a-z]:)/i) {
        $cwd = $dir;
      }
      else {
        $cwd .= "/$dir";
      }
    }
  }
  return $status;
}


sub getcwd {
  #my($self) = shift;
  return $cwd;
}


sub getstartdir {
  #my($self) = shift;
  return $start;
}

sub mpc_dirname {
  my($self) = shift;
  my($dir)  = shift;
  return ($^O ne 'VMS' ? File::Basename::dirname($dir) :
                         unixify(File::Basename::dirname($dir)));
}


# ************************************************************
# Virtual Methods To Be Overridden
# ************************************************************

sub convert_slashes {
  #my($self) = shift;
  return 1;
}


1;
