package WB26WRPROJECTProjectCreator;

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
  return '/.wrproject';
}

sub get_template {
  #my($self) = shift;
  return 'wb26wrproject';
}

sub requires_forward_slashes {
  return 1;
}

1;
