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

sub validated_directory {
  my($self) = shift;
  my($dir)  = shift;

  ## $(...) could contain a drive letter and Windows can not
  ## make a directory that resembles a drive letter.  So, we have
  ## to exclude those directories with $(...).
  if ($dir =~ /\$\([^\)]+\)/) {
    return '.';
  }
  else {
    return $dir;
  }
}


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
