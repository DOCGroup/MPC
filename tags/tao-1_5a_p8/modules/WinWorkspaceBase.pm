package WinWorkspaceBase;

# ************************************************************
# Description   : A Windows base module for Workspace Creators
# Author        : Chad Elliott
# Create Date   : 2/26/2007
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

# ************************************************************
# Subroutine Section
# ************************************************************

sub crlf {
  my($self) = shift;
  return $self->windows_crlf();
}


sub convert_slashes {
  #my($self) = shift;
  return 1;
}

sub case_insensitive {
  #my($self) = shift;
  return 1;
}


1;
