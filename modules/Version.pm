package Version;

# ************************************************************
# Description   : Central location for the MPC version.
# Author        : Chad Elliott
# Create Date   : 1/5/2003
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use File::Spec;

# ************************************************************
# Data Section
# ************************************************************

## This is the starting major and minor version
my $version = '5.0';
my $once    = 1;
my $cache   = 'modules/.version';

# ************************************************************
# Subroutine Section
# ************************************************************

sub get {
  if ($once) {
    ## We only need to do this once
    $once = 0;

    ## Attempt to dynamically determine the revision part of the version
    ## string every time the version number is requested.  This only happens
    ## if the --version option is used, an invalid option is used, and when
    ## the process starts up and the version hasn't been cached yet.
    my $rev = '?';
    my $cwd = Cwd::getcwd();
    if (chdir(::getBasePath())) {
      ## Get the git revision for the final part of the version string.
      my $nul = File::Spec->devnull();
      my $r = _readVersion("git rev-parse --short HEAD 2> $nul |");
      if (defined $r) {
        ## Store the version for later use, in the event that the git
        ## revision isn't available in the future.
        if (open(CLH, ">$cache")) {
          print CLH "$r\n";
          close(CLH);
        }
      }
      else {
        ## See if we can load in the previously stored version string.
        $r = _readVersion($cache);
      }

      ## Set the revision string if we were able to read one.
      $rev = $r if (defined $r);

      chdir($cwd);
    }

    ## We then append the revision to the version string.
    $version .= ".$rev";
  }

  return $version;
}

sub cache {
  ## Attempt to cache the revision if the cache file does not exist.
  ## This will allow the revision to be obtained in the event that git
  ## cannot return the revision information at a later time.
  get() if (!-e ::getBasePath() . '/' . $cache);
}

1;

sub _readVersion {
  my $file = shift;
  my $rev;
  if (open(CLH, $file)) {
    while(<CLH>) {
      if (/^(\w+)$/) {
        $rev = $1;
        last;
      }
    }
    close(CLH);
  }
  return $rev;
}

