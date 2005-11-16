package CBXProjectCreator;

# ************************************************************
# Description   : The Borland C++ BuilderX Project Creator
# Author        : Johnny Willemsen
# Create Date   : 10/12/2003
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
  return '.cbx';
}


sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'cbxexe';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'cbxdll';
}


1;
