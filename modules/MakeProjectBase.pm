package MakeProjectBase;

# ************************************************************
# Description   : A Make Project base module
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

sub dollar_special {
  #my($self) = shift;
  return 1;
}


sub sort_files {
  #my($self) = shift;
  if (defined $ENV{MPC_ALWAYS_SORT}) {
    return 1;
  }
  else {
    return 0;
  }
}


sub project_file_name {
  my($self) = shift;
  my($name) = shift;

  if (!defined $name) {
    $name = $self->project_name();
  }

  return $self->get_modified_project_file_name(
                                     "Makefile.$name",
                                     $self->project_file_extension());
}

1;
