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

# ************************************************************
# Data Section
# ************************************************************

## This is the starting major and minor version
my($version) = '3.1';

## Here we determine the beta version.  The base variable
## is the negated number of existing ChangeLog entries at the
## time of the release of the major and minor version.  We then
## add the total number of ChangeLog entries to the base to
## get the beta version.
my($base) = -36;
if (open(CLH, ::getBasePath() . '/ChangeLog')) {
  while(<CLH>) {
    if (/^\w\w\w\s/) {
      ++$base;
    }
  }
  close(CLH);

  ## We then append the beta version number to the version string
  $version .= ".$base";
}
else {
  print "WARNING: Unable to determine the beta version number of MPC\n";
}


# ************************************************************
# Subroutine Section
# ************************************************************

sub get {
  return $version;
}


1;
