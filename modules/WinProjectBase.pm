package WinProjectBase;

# ************************************************************
# Description   : A Windows base module for Project Creators
# Author        : Chad Elliott
# Create Date   : 1/4/2005
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


sub file_sorter {
  my($self)  = shift;
  my($left)  = shift;
  my($right) = shift;
  return lc($left) cmp lc($right);
}


1;
