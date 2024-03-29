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

my $onVMS = ($^O eq 'VMS');
my $case_insensitive = File::Spec->case_tolerant();
my $cwd = Cwd::getcwd();
if ($^O eq 'cygwin' && $cwd !~ /[A-Za-z]:/) {
  my $cyg = `cygpath -w $cwd`;
  if (defined $cyg) {
    $cyg =~ s/\\/\//g;
    chop($cwd = $cyg);
  }
  $case_insensitive = 1;
}
elsif ($^O eq 'msys' && $cwd !~ /[A-Za-z]:/) {
  my $mp = Win32::GetCwd();
  if (defined $mp) {
    $mp =~ s/\\/\//g;
    $cwd = $mp;
  }
}
elsif ($onVMS) {
  $cwd = VMS::Filespec::unixify($cwd);
  $cwd =~ s!/$!!g;
}
my $start = $cwd;

# ************************************************************
# Subroutine Section
# ************************************************************

sub cd {
  my($self, $dir) = @_;
  my $status = chdir($dir);

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
        ## We're using Cygwin perl, use cygpath to get the windows path
        ## and then fix up the slashes.
        my $cyg = `cygpath -w $cwd`;
        if (defined $cyg) {
          $cyg =~ s/\\/\//g;
          chop($cwd = $cyg);
        }
      }
      elsif ($^O eq 'msys' && $cwd !~ /[A-Za-z]:/) {
        ## We're using Mingw32 perl, use Win32::GetCwd() to get the windows
        ## path and then fix up the slashes.
        my $mp = Win32::GetCwd();
        if (defined $mp) {
          $mp =~ s/\\/\//g;
          $cwd = $mp;
        }
      }
      elsif ($onVMS) {
        ## On VMS, we need to get the UNIX style path and remove the
        ## trailing slash.
        $cwd = VMS::Filespec::unixify($cwd);
        $cwd =~ s!/$!!g;
      }
    }
    else {
      if ($dir =~ /^(\/|[a-z]:)/i) {
        ## It was a full path, just store it.
        $cwd = $dir;
      }
      else {
        ## This portion was relative, add it onto the current working
        ## directory.
        $cwd .= "/$dir";
      }
    }
  }
  return $status;
}


sub abs_path {
  my($self, $path) = @_;

  ## When needing a full path, it's usually because the build system requires
  ## it.  If that's the case, it is unlikely to understand cygwin or mingw32
  ## paths.  For these, we will return the full path for Win32 specifically.
  return Win32::GetFullPathName($path) if ($^O eq 'cygwin' || $^O eq 'msys');

  ## For all others, we will just use Cwd::abs_path
  return Cwd::abs_path($path);
}


sub getcwd {
  #my $self = shift;
  return $cwd;
}


sub getstartdir {
  #my $self = shift;
  return $start;
}


sub mpc_basename {
  #my $self = $_[0];
  #my $file = $_[1];
  return substr($_[1], rindex($_[1], '/') + 1);
}


sub mpc_dirname {
  my($self, $dir) = @_;

  ## The dirname() on VMS doesn't work as we expect it to.
  if ($onVMS) {
    ## If the directory contains multiple parts, we need to get the
    ## dirname in a UNIX style format and then remove the slash from the
    ## end.
    if (index($dir, '/') >= 0) {
      $dir = VMS::Filespec::unixify(dirname($dir));
      $dir =~ s!/$!!g;
      return $dir;
    }
    else {
      ## There's no directory portion, so just return '.'
      return '.';
    }
  }
  else {
    ## Get the directory portion of the original directory or file path.
    $dir = dirname($dir);

    ## If the result is just a drive specification, we need to append a
    ## slash to the end of the path so that cygwin perl can use this
    ## return value within a chdir() call.
    $dir .= '/' if ($dir =~ /^[a-z]:$/i);

    return $dir;
  }
}


sub mpc_glob {
  my($self, $pattern) = @_;

  ## glob() provided by OpenVMS does not understand [] within
  ## the pattern.  So, we implement our own through recursive calls
  ## to mpc_glob().
  if ($onVMS && $pattern =~ /(.*)\[([^\]]+)\](.*)/) {
    my @files;
    my($pre, $mid, $post) = ($1, $2, $3);
    for(my $i = 0; $i < length($mid); $i++) {
      StringProcessor::merge(\@files,
                             [$self->mpc_glob($pre . substr($mid, $i, 1)
                                              . $post)]);
    }
    return @files;
  }

  ## Otherwise, we just return the globbed pattern.
  return glob($pattern);
}


sub onVMS {
  return $onVMS;
}


sub path_is_relative {
  ## To determine if the path is relative, we just determine if it is not
  ## an absolute path.
  #my($self, $path) = @_;
  return (index($_[1], '/') != 0 && $_[1] !~ /^[A-Z]:[\/\\]/i && $_[1] !~ /^\$\(\w+\)/);
}

sub path_to_relative {
  my($self, $check, $path) = @_;

  ## See if it's already relative.  If it is, there's nothing to do.
  if ($path !~ s/^.[\/]+// && !$self->path_is_relative($path)) {
    ## See how many times we have to chop off a directory until we find that
    ## the provided path contains part of the current working directory.
    my $dircount = 0;
    while($check ne '.' && index($path, $check) != 0) {
      $dircount++;
      $check = $self->mpc_dirname($check);
    }

    ## If we didn't go all the way back up the current working directory, we
    ## can create a relative path from it based on the number of directories
    ## we removed above.
    if ($check ne '.') {
      $path = ('../' x $dircount) . substr($path, length($check) + 1);
    }
  }

  return $path;
}

# ************************************************************
# Virtual Methods To Be Overridden
# ************************************************************

sub translate_directory {
  my($self, $dir) = @_;

  ## Remove the current working directory from $dir (if it is contained)
  my $cwd = $self->getcwd();
  $cwd =~ s/\//\\/g if ($self->convert_slashes());
  if (index($dir, $cwd) == 0) {
    my $cwdl = length($cwd);
    return '.' if (length($dir) == $cwdl);
    $dir = substr($dir, $cwdl + 1);
  }

  ## Translate .. to $dd
  if (index($dir, '..') >= 0) {
    my $dd = 'dotdot';
    $dir =~ s/^\.\.([\/\\])/$dd$1/;
    $dir =~ s/([\/\\])\.\.$/$1$dd/;
    $dir =~ s/([\/\\])\.\.(?=[\/\\])/$1$dd$2/g;
    $dir =~ s/^\.\.$/$dd/;
  }

  return $dir;
}


sub convert_slashes {
  #my $self = shift;
  return 0;
}


sub case_insensitive {
  #my $self = shift;
  return $case_insensitive;
}

1;
