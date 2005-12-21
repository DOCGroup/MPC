package BDSProjectCreator;

# ************************************************************
# Description   : The Borland Developer Studio Project Creator
# Author        : Johnny Willemsen
# Create Date   : 14/12/2005
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use ProjectCreator;
use WinProjectBase;

use vars qw(@ISA);
@ISA = qw(WinProjectBase ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub crlf {
  #my($self) = shift;
  return "\n";
}


sub project_file_extension {
  #my($self) = shift;
  return '.bdsproj';
}


sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'bdsexe';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'bdsdll';
}


1;
