package WB26WRMAKEFILEProjectCreator;

# ************************************************************
# Description   : Workbench 2.6 / VxWorks 6.4 generator
# Author        : Johnny Willemsen
# Create Date   : 07/01/2008
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use ProjectCreator;
use WinProjectBase;
use XMLProjectBase;

use vars qw(@ISA);
@ISA = qw(XMLProjectBase ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub crlf {
  #my($self) = shift;
  return "\n";
}

sub project_file_extension {
  #my($self) = shift;
  return '/.wrmakefile';
}

sub get_template {
  #my($self) = shift;
  return 'wb26wrmakefile';
}

1;
