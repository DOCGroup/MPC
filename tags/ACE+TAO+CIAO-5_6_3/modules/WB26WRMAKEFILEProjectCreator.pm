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

use vars qw(@ISA);
@ISA = qw(ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub crlf {
  #my($self) = shift;
  return "\n";
}

sub project_file_name {
  my($self) = shift;
  return $self->get_modified_project_file_name($self->project_name(), '/.wrmakefile');
}

sub get_template {
  #my($self) = shift;
  return 'wb26wrmakefile';
}

sub requires_forward_slashes {
  return 1;
}

1;
