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
elsif ($^O eq 'VMS') {
  $cwd = unixify($cwd);
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
      elsif ($^O eq 'VMS') {
        $cwd = unixify($cwd);
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

  if ($^O eq 'VMS') {
    if ($dir =~ /\//) {
      return unixify(dirname($dir));
    }
    else {
      return '.';
    }
  }
  else {
    return dirname($dir);
  }
}


sub mpc_glob {
  my($self)    = shift;
  my($pattern) = shift;
  my(@files)   = ();

  ## glob() provided by OpenVMS does not understand [] within
  ## the pattern.  So, we implement our own through recursive calls
  ## to mpc_glob().
  if ($^O eq 'VMS' && $pattern =~ /(.*)\[([^\]]+)\](.*)/) {
    my($pre)  = $1;
    my($mid)  = $2;
    my($post) = $3;
    for(my $i = 0; $i < length($mid); $i++) {
      my($p) = $pre . substr($mid, $i, 1) . $post;
      my(@new) = $self->mpc_glob($p);
      foreach my $new ($self->mpc_glob($p)) {
        my($found) = undef;
        foreach my $file (@files) {
          if ($file eq $new) {
            $found = 1;
            last;
          }
        }
        if (!$found) {
          push(@files, $new);
        }
      }
    }
  }
  else {
    push(@files, glob($pattern));
  }

  return @files;
}

# ************************************************************
# Virtual Methods To Be Overridden
# ************************************************************

sub convert_slashes {
  #my($self) = shift;
  return 1;
}


1;
