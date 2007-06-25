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
use File::Spec;
use File::Basename;

# ************************************************************
# Data Section
# ************************************************************

my($onVMS) = ($^O eq 'VMS');
my($case_insensitive) = File::Spec->case_tolerant();
my($cwd) = Cwd::getcwd();
if ($^O eq 'cygwin' && $cwd !~ /[A-Za-z]:/) {
  my($cyg) = `cygpath -w $cwd`;
  if (defined $cyg) {
    $cyg =~ s/\\/\//g;
    chop($cwd = $cyg);
  }
  $case_insensitive = 1;
}
elsif ($onVMS) {
  $cwd = VMS::Filespec::unixify($cwd);
  $cwd =~ s!/$!!g;
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
    if (index($dir, '..') >= 0) {
      $cwd = Cwd::getcwd();
      if ($^O eq 'cygwin' && $cwd !~ /[A-Za-z]:/) {
        my($cyg) = `cygpath -w $cwd`;
        if (defined $cyg) {
          $cyg =~ s/\\/\//g;
          chop($cwd = $cyg);
        }
      }
      elsif ($onVMS) {
        $cwd = VMS::Filespec::unixify($cwd);
        $cwd =~ s!/$!!g;
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


sub mpc_basename {
  #my($self) = $_[0];
  #my($file) = $_[1];
  return substr($_[1], rindex($_[1], '/') + 1);
}


sub mpc_dirname {
  my($self) = shift;
  my($dir)  = shift;

  if ($onVMS) {
    if (index($dir, '/') >= 0) {
      $dir = VMS::Filespec::unixify(dirname($dir));
      $dir =~ s!/$!!g;
      return $dir;
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
  if ($onVMS && $pattern =~ /(.*)\[([^\]]+)\](.*)/) {
    my($pre)  = $1;
    my($mid)  = $2;
    my($post) = $3;
    for(my $i = 0; $i < length($mid); $i++) {
      my($p) = $pre . substr($mid, $i, 1) . $post;
      foreach my $new (DirectoryManager::mpc_glob($self, $p)) {
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


sub onVMS {
  return $onVMS;
}


sub path_is_relative {
  my($self) = shift;
  my($path) = shift;
  return (index($path, '/') != 0 && $path !~ /^[A-Z]:\//i);
}

# ************************************************************
# Virtual Methods To Be Overridden
# ************************************************************

sub translate_directory {
  my($self) = shift;
  my($dir)  = shift;

  ## Remove the current working directory from $dir (if it is contained)
  my($cwd) = $self->getcwd();
  $cwd =~ s/\//\\/g if ($self->convert_slashes());
  if (index($dir, $cwd) == 0) {
    my($cwdl) = length($cwd);
    return '.' if (length($dir) == $cwdl);
    $dir = substr($dir, $cwdl + 1);
  }

  ## Translate .. to $dd
  if (index($dir, '..') >= 0) {
    my($dd) = 'dotdot';
    $dir =~ s/^\.\.([\/\\])/$dd$1/;
    $dir =~ s/([\/\\])\.\.$/$1$dd/;
    $dir =~ s/([\/\\])\.\.([\/\\])/$1$dd$2/g;
    $dir =~ s/^\.\.$/$dd/;
  }

  return $dir;
}


sub convert_slashes {
  #my($self) = shift;
  return 0;
}


sub case_insensitive {
  #my($self) = shift;
  return $case_insensitive;
}

1;
